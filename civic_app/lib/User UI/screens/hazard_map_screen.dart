import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/location/location_model.dart';
import '../../core/map/basemap_mode.dart';
import '../../core/map/civic_map_canvas.dart';
import '../../core/map/heatmap_legend.dart';
import '../../core/map/map_chunk_manager.dart';
import '../../core/map/map_constants.dart';
import '../../core/map/spatial_data_service.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/hazard_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/hazard_repository.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/civic_fix_outlined_button.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/location_service.dart';
import '../widgets/hazard_map/hazard_info_card.dart';
import '../widgets/hazard_map/hazard_marker.dart';
import '../widgets/hazard_map/map_filter_sheet.dart';
import '../widgets/map/basemap_selector_sheet.dart';

/// Full interactive Citizen Hazard Map screen powered by MapTiler and MapLibre.
class HazardMapScreen extends StatefulWidget {
  final HazardRepository? hazardRepository;
  final ComplaintRepository? complaintRepository;
  final LocationService? locationService;
  final ConnectivityService? connectivityService;

  const HazardMapScreen({
    super.key,
    this.hazardRepository,
    this.complaintRepository,
    this.locationService,
    this.connectivityService,
  });

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  late final HazardRepository _hazardRepository;
  late final ComplaintRepository _complaintRepository;
  late final LocationService _locationService;
  late final ConnectivityService _connectivityService;

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<CivicMapCanvasState> _mapCanvasKey = GlobalKey<CivicMapCanvasState>();

  List<HazardModel> _allHazards = [];
  List<HazardModel> _filteredHazards = [];
  HazardModel? _selectedHazard;
  CivicLocation? _userLocation;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocatingGps = false;
  String? _locationWarningMessage;

  // Active filters & Basemap configuration
  BasemapMode _basemapMode = BasemapMode.streets;
  String? _selectedCategoryId;
  ComplaintStatus? _selectedStatus;
  SpatialTimeFilter? _selectedTimeFilter;
  bool _showLegend = false;
  bool _showHeatmap = true;

  late final MapChunkManager _chunkManager;
  StreamSubscription<ComplaintModel?>? _selectedComplaintSubscription;
  StreamSubscription<HazardModel?>? _selectedHazardSubscription;
  LatLngBounds? _lastBounds;
  int _selectionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _hazardRepository = widget.hazardRepository ?? RepositoryLocator.hazardRepository;
    _complaintRepository = widget.complaintRepository ?? RepositoryLocator.complaintRepository;
    _locationService = widget.locationService ?? RepositoryLocator.locationService;
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _chunkManager = MapChunkManager();
    _chunkManager.addListener(_onChunkManagerChanged);
    _initInitialChunks();
  }

  void _initInitialChunks() {
    final initialBounds = LatLngBounds(
      southwest: const LatLng(MapConstants.mumbaiLatitude - 0.05, MapConstants.mumbaiLongitude - 0.05),
      northeast: const LatLng(MapConstants.mumbaiLatitude + 0.05, MapConstants.mumbaiLongitude + 0.05),
    );
    _lastBounds = initialBounds;
    _chunkManager.onCameraIdle(
      bounds: initialBounds,
      repository: _hazardRepository,
      categoryId: _selectedCategoryId,
      status: _selectedStatus,
      debounce: Duration.zero,
    );
  }

  void _onChunkManagerChanged() {
    if (!mounted) return;
    setState(() {
      _allHazards = _chunkManager.allCachedHazards;
      _isLoading = _chunkManager.isLoading && _allHazards.isEmpty;
      _errorMessage = _chunkManager.errorMessage;
    });
    _applyCurrentFilters();
  }

  @override
  void dispose() {
    _chunkManager.removeListener(_onChunkManagerChanged);
    _chunkManager.dispose();
    _selectedComplaintSubscription?.cancel();
    _selectedHazardSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onVisibleBoundsChanged(LatLngBounds bounds) {
    _lastBounds = bounds;
    _chunkManager.onCameraIdle(
      bounds: bounds,
      repository: _hazardRepository,
      categoryId: _selectedCategoryId,
      status: _selectedStatus,
    );
  }

  Future<void> _loadHazards() async {
    final bounds = _lastBounds ??
        LatLngBounds(
          southwest: const LatLng(MapConstants.mumbaiLatitude - 0.05, MapConstants.mumbaiLongitude - 0.05),
          northeast: const LatLng(MapConstants.mumbaiLatitude + 0.05, MapConstants.mumbaiLongitude + 0.05),
        );
    await _chunkManager.onCameraIdle(
      bounds: bounds,
      repository: _hazardRepository,
      categoryId: _selectedCategoryId,
      status: _selectedStatus,
      debounce: Duration.zero,
    );
  }

  void _onHazardSelected(HazardModel hazard) {
    setState(() {
      _selectedHazard = hazard;
    });
    _subscribeSelectedHazard(hazard);
    if (kDebugMode) debugPrint('[HazardMapScreen] selected=${hazard.id} complaintId=${hazard.complaintId}');
  }

  void _subscribeSelectedHazard(HazardModel hazard) {
    final generation = ++_selectionGeneration;
    _selectedComplaintSubscription?.cancel();
    _selectedHazardSubscription?.cancel();

    final complaintId = hazard.complaintId ?? hazard.id;
    try {
      _selectedComplaintSubscription = _complaintRepository.watchComplaint(complaintId).listen(
        (updatedComplaint) {
          if (!mounted || _selectedHazard == null || generation != _selectionGeneration) return;
          if (updatedComplaint != null) {
            final updatedHazard = HazardModel.fromComplaint(updatedComplaint);
            setState(() {
              _selectedHazard = updatedHazard;
              _chunkManager.updateHazard(updatedHazard);
            });
          }
        },
        onError: (e) {
          debugPrint('[HazardMapScreen] Selected complaint subscription notice: $e');
        },
      );
    } catch (_) {}

    try {
      _selectedHazardSubscription = _hazardRepository.watchHazardById(hazard.id).listen(
        (updatedHazard) {
          if (!mounted || _selectedHazard == null || generation != _selectionGeneration) return;
          if (updatedHazard != null) {
            setState(() {
              _selectedHazard = updatedHazard;
              _chunkManager.updateHazard(updatedHazard);
            });
          }
        },
        onError: (e) {
          debugPrint('[HazardMapScreen] Selected hazard subscription notice: $e');
        },
      );
    } catch (_) {}
  }

  void _onMapTap() {
    _selectionGeneration++;
    if (_selectedHazard != null) {
      _selectedComplaintSubscription?.cancel();
      _selectedHazardSubscription?.cancel();
      _selectedComplaintSubscription = null;
      _selectedHazardSubscription = null;
      setState(() {
        _selectedHazard = null;
      });
    }
  }

  void _applyCurrentFilters() {
    var list = _allHazards.toList();

    // 1. Filter Category
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty && _selectedCategoryId != 'all') {
      final catQuery = _selectedCategoryId!.toLowerCase();
      list = list.where((h) {
        return h.category.id.toLowerCase() == catQuery ||
            h.category.name.toLowerCase().contains(catQuery.replaceFirst('cat_', ''));
      }).toList();
    }

    // 2. Filter Status
    if (_selectedStatus != null) {
      list = list.where((h) => h.status == _selectedStatus).toList();
    }

    // 3. Filter Time Horizon
    if (_selectedTimeFilter != null && _selectedTimeFilter != SpatialTimeFilter.allTime) {
      list = list.where((h) => _selectedTimeFilter!.isWithin(h.createdAt)).toList();
    }

    // 4. Search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((h) {
        final matchesTitle = h.title.toLowerCase().contains(query);
        final matchesTicket = (h.ticketNumber ?? '').toLowerCase().contains(query);
        final matchesCategory = h.category.name.toLowerCase().contains(query);
        final matchesAddress = h.address.toLowerCase().contains(query);
        final matchesLandmark = (h.landmark ?? '').toLowerCase().contains(query);
        final matchesWard = (h.ward ?? '').toLowerCase().contains(query);

        return matchesTitle || matchesTicket || matchesCategory || matchesAddress || matchesLandmark || matchesWard;
      }).toList();
    }

    setState(() {
      _filteredHazards = list;
      if (_selectedHazard != null) {
        try {
          final updatedSelected = list.firstWhere(
            (h) => h.id == _selectedHazard!.id || (h.complaintId != null && h.complaintId == _selectedHazard!.complaintId),
          );
          _selectedHazard = updatedSelected;
        } catch (_) {
          _selectedHazard = null;
          _selectionGeneration++;
          _selectedComplaintSubscription?.cancel();
          _selectedHazardSubscription?.cancel();
        }
      }
    });
  }

  void _onSearchChanged(String value) {
    _applyCurrentFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    _applyCurrentFilters();
  }

  void _openFilterSheet() {
    MapFilterSheet.show(
      context,
      selectedCategoryId: _selectedCategoryId,
      selectedStatus: _selectedStatus,
      selectedTimeFilter: _selectedTimeFilter,
      onApply: (categoryId, status, [timeFilter]) {
        setState(() {
          _selectedCategoryId = categoryId;
          _selectedStatus = status;
          if (timeFilter is SpatialTimeFilter?) {
            _selectedTimeFilter = timeFilter;
          }
        });
        _applyCurrentFilters();
        if (_lastBounds != null) {
          _chunkManager.onCameraIdle(
            bounds: _lastBounds!,
            repository: _hazardRepository,
            categoryId: _selectedCategoryId,
            status: _selectedStatus,
            debounce: Duration.zero,
          );
        }
      },
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedStatus = null;
      _selectedTimeFilter = null;
      _searchController.clear();
    });
    _applyCurrentFilters();
    if (_lastBounds != null) {
      _chunkManager.onCameraIdle(
        bounds: _lastBounds!,
        repository: _hazardRepository,
        debounce: Duration.zero,
      );
    }
  }

  Future<void> _centerOnMyLocation() async {
    setState(() {
      _isLocatingGps = true;
      _locationWarningMessage = null;
    });

    try {
      final isServiceEnabled = await _locationService.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationWarningMessage = 'Location services are disabled on your device.';
          _isLocatingGps = false;
        });
        return;
      }

      final permission = await _locationService.checkPermission();
      if (permission == CivicPermissionStatus.denied || permission == CivicPermissionStatus.permanentlyDenied) {
        final requested = await _locationService.requestPermission();
        if (requested == CivicPermissionStatus.denied || requested == CivicPermissionStatus.permanentlyDenied) {
          if (!mounted) return;
          setState(() {
            _locationWarningMessage = 'Location permission is required to center the map.';
            _isLocatingGps = false;
          });
          return;
        }
      }

      final pos = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (pos != null) {
        setState(() {
          _userLocation = pos;
          _isLocatingGps = false;
          _locationWarningMessage = null;
        });
        await _mapCanvasKey.currentState?.animateTo(
          latitude: pos.latitude,
          longitude: pos.longitude,
          zoom: MapConstants.focusedZoom,
        );

        if (mounted) {
          final wardText = (pos.ward != null && pos.ward!.isNotEmpty) ? ' in ${pos.ward}' : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Centered on your location$wardText'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _locationWarningMessage = 'Unable to determine your location. Please try again.';
          _isLocatingGps = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _locationWarningMessage = 'GPS acquisition timed out. Please retry.';
        _isLocatingGps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationWarningMessage = 'Unable to determine your location.';
        _isLocatingGps = false;
      });
    }
  }

  void _zoomIn() {
    _mapCanvasKey.currentState?.zoomIn();
  }

  void _zoomOut() {
    _mapCanvasKey.currentState?.zoomOut();
  }

  void _openBasemapSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: CivicFixRadius.sheetRadius,
      ),
      builder: (context) => BasemapSelectorSheet(
        currentMode: _basemapMode,
        onModeSelected: (mode) {
          setState(() {
            _basemapMode = mode;
          });
        },
      ),
    );
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCategoryId != null && _selectedCategoryId != 'all') count++;
    if (_selectedStatus != null) count++;
    if (_selectedTimeFilter != null && _selectedTimeFilter != SpatialTimeFilter.allTime) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;

    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: CivicFixAppBar(
        title: l10n?.hazardMapTitle ?? 'Hazard Map',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _showHeatmap ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
              color: _showHeatmap ? const Color(0xFFEF4444) : CivicFixColors.secondaryText,
            ),
            tooltip: _showHeatmap ? (l10n?.hideHeatmapLayer ?? 'Hide Heatmap Layer') : (l10n?.showHeatmapLayer ?? 'Show Heatmap Layer'),
            onPressed: () {
              setState(() {
                _showHeatmap = !_showHeatmap;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _showLegend ? Icons.layers_rounded : Icons.layers_outlined,
              color: _showLegend ? CivicFixColors.primary : CivicFixColors.secondaryText,
            ),
            tooltip: l10n?.toggleMapLegend ?? 'Toggle Map Legend',
            onPressed: () {
              setState(() {
                _showLegend = !_showLegend;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: LoadingState(message: l10n?.loadingHazardMap ?? 'Loading civic hazard map...'),
              )
            : _errorMessage != null
                ? Center(
                    child: ErrorState(
                      title: l10n?.couldNotLoadCivicIssues ?? "Couldn't load civic issues.",
                      message: l10n?.checkConnectionAndRetry ?? 'Please check your connection and try again.',
                      onRetry: _loadHazards,
                    ),
                  )
                : _buildMapInterface(),
      ),
    );
  }

  Widget _buildMapInterface() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 1. Base Real MapLibre + MapTiler Canvas
            CivicMapCanvas(
              key: _mapCanvasKey,
              hazards: _filteredHazards,
              selectedHazard: _selectedHazard,
              basemapMode: _basemapMode,
              showHeatmap: _showHeatmap,
              timeFilter: _selectedTimeFilter,
              onVisibleBoundsChanged: _onVisibleBoundsChanged,
              onHazardSelected: _onHazardSelected,
              userLocation: _userLocation,
              onMapTap: _onMapTap,
              markerBuilder: (hazard, isSelected, onTap) {
                return HazardMarker(
                  hazard: hazard,
                  isSelected: isSelected,
                  onTap: onTap,
                );
              },
            ),

            // Subtle progressive loading indicator
            if (_chunkManager.isLoading && _allHazards.isNotEmpty)
              Positioned(
                top: 76,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Updating visible area...',
                          style: CivicFixTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. Offline Mode Banner (if offline)
            if (!_connectivityService.isOnline)
              Positioned(
                top: CivicFixSpacing.sm,
                left: CivicFixSpacing.md,
                right: CivicFixSpacing.md,
                child: OfflineCacheBanner(
                  customMessage: context.l10nOrNull?.offlineCachedHazardsBanner ??
                      'Offline — Showing cached hazards. Basemap tiles require network.',
                  isCompact: true,
                ),
              ),

            // 3. Top Search & Filter Bar
            Positioned(
              top: CivicFixSpacing.md,
              left: CivicFixSpacing.md,
              right: CivicFixSpacing.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Search Input Box
                      Expanded(
                        child: CivicFixCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.md,
                            vertical: CivicFixSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: CivicFixColors.secondaryText,
                                size: 20,
                              ),
                              CivicFixSpacing.hSpaceSm,
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: CivicFixTypography.bodySmall,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: context.l10nOrNull?.searchHazardsHint ??
                                        'Search hazards or complaints...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    filled: false,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  color: CivicFixColors.secondaryText,
                                  onPressed: _clearSearch,
                                ),
                            ],
                          ),
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,

                      // Filter Button with Badge
                      Material(
                        color: _activeFiltersCount > 0 ? CivicFixColors.primary : Colors.white,
                        borderRadius: CivicFixRadius.cardRadius,
                        elevation: 2,
                        child: InkWell(
                          onTap: _openFilterSheet,
                          borderRadius: CivicFixRadius.cardRadius,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: _activeFiltersCount > 0 ? Colors.white : CivicFixColors.primary,
                                  size: 22,
                                ),
                                if (_activeFiltersCount > 0)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: CivicFixColors.alert,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$_activeFiltersCount',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Location warning banner if permission denied
                  if (_locationWarningMessage != null) ...[
                    CivicFixSpacing.vSpaceSm,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.sm),
                      decoration: BoxDecoration(
                        color: CivicFixColors.alertLight,
                        borderRadius: CivicFixRadius.cardRadius,
                        border: Border.all(color: CivicFixColors.alertDark.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off_rounded, color: CivicFixColors.alertDark, size: 18),
                          CivicFixSpacing.hSpaceSm,
                          Expanded(
                            child: Text(
                              _locationWarningMessage!,
                              style: CivicFixTypography.caption.copyWith(color: CivicFixColors.alertDark),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            color: CivicFixColors.alertDark,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _locationWarningMessage = null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. Map Legends Floating Sheet (Heatmap Density + Hazard Status)
            if (_showLegend)
              Positioned(
                top: 80,
                right: CivicFixSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showHeatmap) ...[
                      HeatmapLegend(
                        onClose: () => setState(() => _showLegend = false),
                      ),
                      CivicFixSpacing.vSpaceSm,
                    ],
                    Semantics(
                      label: 'Hazard Status Legend',
                      child: CivicFixCard(
                        padding: const EdgeInsets.all(CivicFixSpacing.md),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10nOrNull?.statusLegend ?? 'Status Legend',
                              style: CivicFixTypography.captionMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: CivicFixColors.primaryText,
                              ),
                            ),
                            CivicFixSpacing.vSpaceSm,
                            ...ComplaintStatus.values.where((s) => s != ComplaintStatus.rejected).map((status) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: status.badgeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    CivicFixSpacing.hSpaceSm,
                                    Text(
                                      localizedComplaintStatus(status, context: context),
                                      style: CivicFixTypography.caption,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Floating Quick Location Re-center Button
            Positioned(
              right: CivicFixSpacing.md,
              bottom: _selectedHazard != null ? 220 : 130,
              child: FloatingActionButton.small(
                heroTag: 'my_location_btn',
                tooltip: 'Use My Location',
                backgroundColor: Colors.white,
                foregroundColor: CivicFixColors.primary,
                elevation: 3,
                onPressed: _isLocatingGps ? null : _centerOnMyLocation,
                child: _isLocatingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
              ),
            ),

            // 6. Floating Zoom In / Zoom Out Controls
            Positioned(
              right: CivicFixSpacing.md,
              bottom: _selectedHazard != null ? 275 : 185,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    elevation: 3,
                    child: InkWell(
                      onTap: _zoomIn,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Tooltip(
                        message: 'Zoom In',
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.add_rounded, size: 20, color: CivicFixColors.primaryText),
                        ),
                      ),
                    ),
                  ),
                  Container(height: 1, width: 40, color: CivicFixColors.border),
                  Material(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    elevation: 3,
                    child: InkWell(
                      onTap: _zoomOut,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                      child: Tooltip(
                        message: 'Zoom Out',
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.remove_rounded, size: 20, color: CivicFixColors.primaryText),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 7. Floating Basemap Style Switcher Button (Streets, Satellite, Hybrid)
            Positioned(
              right: CivicFixSpacing.md,
              bottom: _selectedHazard != null ? 365 : 275,
              child: FloatingActionButton.small(
                heroTag: 'basemap_selector_btn',
                tooltip: '${context.l10nOrNull?.basemapStyle ?? "Basemap Style"} (${localizedBasemapMode(_basemapMode, context: context)})',
                backgroundColor: Colors.white,
                foregroundColor: CivicFixColors.primaryDark,
                elevation: 3,
                onPressed: _openBasemapSelector,
                child: Icon(_basemapMode.icon, size: 20),
              ),
            ),

            // 7. Results Count Pill
            if (_filteredHazards.isNotEmpty && _selectedHazard == null)
              Positioned(
                left: CivicFixSpacing.md,
                bottom: CivicFixSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.xs),
                  decoration: BoxDecoration(
                    color: CivicFixColors.primaryDark.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CivicFixColors.alert,
                          shape: BoxShape.circle,
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Text(
                        '${_filteredHazards.length} ${context.l10nOrNull?.civicIssuesNearYou ?? "civic issues near you"}',
                        style: CivicFixTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty Search State Overlay
            if (_filteredHazards.isEmpty)
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(CivicFixSpacing.lg),
                    child: CivicFixCard(
                      padding: const EdgeInsets.all(CivicFixSpacing.lg),
                      elevation: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_searching_rounded,
                            size: 48,
                            color: CivicFixColors.disabledText,
                          ),
                          CivicFixSpacing.vSpaceMd,
                          Text(
                            context.l10nOrNull?.noCivicIssuesFound ?? 'No civic issues found.',
                            style: CivicFixTypography.h3,
                          ),
                          CivicFixSpacing.vSpaceSm,
                          Text(
                            context.l10nOrNull?.tryChangingFiltersOrSearch ??
                                'Try changing your filters or search.',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.secondaryText,
                            ),
                          ),
                          CivicFixSpacing.vSpaceLg,
                          CivicFixOutlinedButton(
                            text: context.l10nOrNull?.clearFilters ?? 'Clear Filters',
                            onPressed: _clearAllFilters,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 8. Bottom Floating Hazard Info Card (when marker is selected)
            if (_selectedHazard != null)
              Positioned(
                left: CivicFixSpacing.md,
                right: CivicFixSpacing.md,
                bottom: CivicFixSpacing.md,
                child: ResponsiveContainer(
                  maxWidth: 500,
                  child: HazardInfoCard(
                    hazard: _selectedHazard!,
                    complaintRepository: _complaintRepository,
                    onClose: _onMapTap,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
