import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/location/location_model.dart';
import '../../core/map/civic_map_canvas.dart';
import '../../core/map/heatmap_legend.dart';
import '../../core/map/map_constants.dart';
import '../../core/map/spatial_data_service.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/hazard_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/hazard_repository.dart';
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
  final TransformationController _transformController = TransformationController();
  final GlobalKey<CivicMapCanvasState> _mapCanvasKey = GlobalKey<CivicMapCanvasState>();

  List<HazardModel> _allHazards = [];
  List<HazardModel> _filteredHazards = [];
  HazardModel? _selectedHazard;
  CivicLocation? _userLocation;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocatingGps = false;
  String? _locationWarningMessage;

  // Active filters
  String? _selectedCategoryId;
  ComplaintStatus? _selectedStatus;
  SpatialTimeFilter? _selectedTimeFilter;
  bool _showLegend = false;
  bool _showHeatmap = true;

  @override
  void initState() {
    super.initState();
    _hazardRepository = widget.hazardRepository ?? RepositoryLocator.hazardRepository;
    _complaintRepository = widget.complaintRepository ?? RepositoryLocator.complaintRepository;
    _locationService = widget.locationService ?? RepositoryLocator.locationService;
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _loadHazards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadHazards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _hazardRepository.getHazards();
      if (!mounted) return;
      setState(() {
        _allHazards = list;
        _isLoading = false;
      });
      _applyCurrentFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Couldn't load civic issues.";
        _isLoading = false;
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
      if (_selectedHazard != null && !list.any((h) => h.id == _selectedHazard!.id)) {
        _selectedHazard = null;
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
          _locationWarningMessage = 'Location services are disabled.';
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
            _locationWarningMessage = 'Location access is turned off. Enable location access to see issues near you.';
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
        });
        await _mapCanvasKey.currentState?.animateTo(
          latitude: pos.latitude,
          longitude: pos.longitude,
          zoom: MapConstants.focusedZoom,
        );
      }

      // Reset map transform to center
      _transformController.value = Matrix4.identity();

      setState(() {
        _isLocatingGps = false;
        _locationWarningMessage = null;
      });

      if (pos != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Centered on your location in ${pos.ward ?? "Ward 14"}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationWarningMessage = 'Location access is turned off.';
        _isLocatingGps = false;
      });
    }
  }

  void _zoomIn() {
    _mapCanvasKey.currentState?.zoomIn();
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 3.0) {
      _transformController.value = _transformController.value.clone()..scaleByDouble(1.25, 1.25, 1.0, 1.0);
    }
  }

  void _zoomOut() {
    _mapCanvasKey.currentState?.zoomOut();
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 0.8) {
      _transformController.value = _transformController.value.clone()..scaleByDouble(0.8, 0.8, 1.0, 1.0);
    }
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
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: CivicFixAppBar(
        title: 'Hazard Map',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _showHeatmap ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
              color: _showHeatmap ? const Color(0xFFEF4444) : CivicFixColors.secondaryText,
            ),
            tooltip: _showHeatmap ? 'Hide Heatmap Layer' : 'Show Heatmap Layer',
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
            tooltip: 'Toggle Map Legend',
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
            ? const Center(
                child: LoadingState(message: 'Loading civic hazard map...'),
              )
            : _errorMessage != null
                ? Center(
                    child: ErrorState(
                       title: "Couldn't load civic issues.",
                      message: 'Please check your connection and try again.',
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
              showHeatmap: _showHeatmap,
              timeFilter: _selectedTimeFilter,
              onHazardSelected: (hazard) {
                setState(() {
                  _selectedHazard = hazard;
                });
              },
              userLocation: _userLocation,
              onMapTap: () {
                if (_selectedHazard != null) {
                  setState(() {
                    _selectedHazard = null;
                  });
                }
              },
              transformationController: _transformController,
              markerBuilder: (hazard, isSelected, onTap) {
                return HazardMarker(
                  hazard: hazard,
                  isSelected: isSelected,
                  onTap: onTap,
                );
              },
            ),

            // 2. Offline Mode Banner (if offline)
            if (!_connectivityService.isOnline)
              const Positioned(
                top: CivicFixSpacing.sm,
                left: CivicFixSpacing.md,
                right: CivicFixSpacing.md,
                child: OfflineCacheBanner(
                  customMessage: 'Offline — Showing cached hazards. Basemap tiles require network.',
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
                                  decoration: const InputDecoration(
                                    hintText: 'Search issue, ID or locality...',
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
                              'Status Legend',
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
                                      status.label,
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
                        '${_filteredHazards.length} ${_filteredHazards.length == 1 ? "civic issue" : "civic issues"} near you',
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
                            'No civic issues found.',
                            style: CivicFixTypography.h3,
                          ),
                          CivicFixSpacing.vSpaceSm,
                          Text(
                            'Try changing your filters or search.',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.secondaryText,
                            ),
                          ),
                          CivicFixSpacing.vSpaceLg,
                          CivicFixOutlinedButton(
                            text: 'Clear Filters',
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
                    onClose: () {
                      setState(() {
                        _selectedHazard = null;
                      });
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
