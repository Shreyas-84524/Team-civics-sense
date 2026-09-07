import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/location/location_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/hazard_model.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/hazard_repository.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/civic_fix_outlined_button.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/location_service.dart';
import '../widgets/hazard_map/hazard_info_card.dart';
import '../widgets/hazard_map/hazard_marker.dart';
import '../widgets/hazard_map/map_filter_sheet.dart';

/// Full interactive Citizen Hazard Map screen.
class HazardMapScreen extends StatefulWidget {
  final HazardRepository? hazardRepository;
  final ComplaintRepository? complaintRepository;
  final LocationService? locationService;

  const HazardMapScreen({
    super.key,
    this.hazardRepository,
    this.complaintRepository,
    this.locationService,
  });

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  late final HazardRepository _hazardRepository;
  late final ComplaintRepository _complaintRepository;
  late final LocationService _locationService;

  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformController = TransformationController();

  List<HazardModel> _allHazards = [];
  List<HazardModel> _filteredHazards = [];
  HazardModel? _selectedHazard;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocatingGps = false;
  String? _locationWarningMessage;

  // Active filters
  String? _selectedCategoryId;
  ComplaintStatus? _selectedStatus;
  bool _showLegend = false;

  // Center user GPS coordinate for relative marker offset
  static const double _centerLat = 12.9730;
  static const double _centerLng = 77.5960;

  @override
  void initState() {
    super.initState();
    _hazardRepository = widget.hazardRepository ?? MockHazardRepository();
    _complaintRepository = widget.complaintRepository ?? MockComplaintRepository();
    _locationService = widget.locationService ?? MockLocationService();
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

    // 3. Search query
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
      onApply: (categoryId, status) {
        setState(() {
          _selectedCategoryId = categoryId;
          _selectedStatus = status;
        });
        _applyCurrentFilters();
      },
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedStatus = null;
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

      // Animate/reset map transform to center
      _transformController.value = Matrix4.identity();

      setState(() {
        _isLocatingGps = false;
        _locationWarningMessage = null;
      });

      if (pos != null) {
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
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 3.0) {
      _transformController.value = _transformController.value.clone()..scaleByDouble(1.25, 1.25, 1.0, 1.0);
    }
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 0.8) {
      _transformController.value = _transformController.value.clone()..scaleByDouble(0.8, 0.8, 1.0, 1.0);
    }
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCategoryId != null && _selectedCategoryId != 'all') count++;
    if (_selectedStatus != null) count++;
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
              _showLegend ? Icons.info_rounded : Icons.info_outline_rounded,
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
            // 1. Interactive Vector Map Canvas & Markers
            Positioned.fill(
              child: _buildInteractiveMapCanvas(constraints.biggest),
            ),

            // 2. Non-blocking Location Warning Banner (if permission/service issue)
            if (_locationWarningMessage != null)
              Positioned(
                top: 72,
                left: CivicFixSpacing.md,
                right: CivicFixSpacing.md,
                child: Material(
                  elevation: 3,
                  borderRadius: CivicFixRadius.cardRadius,
                  color: CivicFixColors.alertLight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          color: CivicFixColors.alertDark,
                          size: 20,
                        ),
                        CivicFixSpacing.hSpaceSm,
                        Expanded(
                          child: Text(
                            _locationWarningMessage!,
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: CivicFixColors.primaryText,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: CivicFixColors.secondaryText,
                          onPressed: () {
                            setState(() {
                              _locationWarningMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
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
                                          fontWeight: FontWeight.bold,
                                          color: CivicFixColors.primary,
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

                  // Active Filter Summary Chips Row
                  if (_activeFiltersCount > 0) ...[
                    CivicFixSpacing.vSpaceXs,
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: CivicFixColors.primary.withValues(alpha: 0.9),
                              borderRadius: CivicFixRadius.chipRadius,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_activeFiltersCount active',
                                  style: CivicFixTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                CivicFixSpacing.hSpaceXs,
                                GestureDetector(
                                  onTap: _clearAllFilters,
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedCategoryId != null) ...[
                            CivicFixSpacing.hSpaceXs,
                            Chip(
                              backgroundColor: Colors.white,
                              label: Text(_selectedCategoryId!.replaceAll('cat_', '').toUpperCase()),
                              labelStyle: CivicFixTypography.caption.copyWith(fontWeight: FontWeight.w600),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              deleteIcon: const Icon(Icons.close_rounded, size: 14),
                              onDeleted: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                });
                                _applyCurrentFilters();
                              },
                            ),
                          ],
                          if (_selectedStatus != null) ...[
                            CivicFixSpacing.hSpaceXs,
                            Chip(
                              backgroundColor: Colors.white,
                              label: Text(_selectedStatus!.label),
                              labelStyle: CivicFixTypography.caption.copyWith(fontWeight: FontWeight.w600),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              deleteIcon: const Icon(Icons.close_rounded, size: 14),
                              onDeleted: () {
                                setState(() {
                                  _selectedStatus = null;
                                });
                                _applyCurrentFilters();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. "Nearby Issues" Pill (Top center under search)
            Positioned(
              top: _activeFiltersCount > 0 ? 115 : 74,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: CivicFixRadius.largeContainerRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CivicFixColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Text(
                        '${_filteredHazards.length} civic ${_filteredHazards.length == 1 ? "issue" : "issues"} near you',
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: CivicFixColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Map Legend Overlay (if toggled)
            if (_showLegend)
              Positioned(
                top: 110,
                right: CivicFixSpacing.md,
                child: Material(
                  elevation: 4,
                  borderRadius: CivicFixRadius.cardRadius,
                  color: Colors.white,
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(CivicFixSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Status Legend',
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        CivicFixSpacing.vSpaceSm,
                        ...ComplaintStatus.values.map((status) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
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
                                  style: CivicFixTypography.caption.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. Floating Controls: Zoom In, Zoom Out, Use My Location
            Positioned(
              right: CivicFixSpacing.md,
              bottom: _selectedHazard != null ? 240 : CivicFixSpacing.xl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_in_btn',
                    backgroundColor: Colors.white,
                    foregroundColor: CivicFixColors.primary,
                    elevation: 2,
                    tooltip: 'Zoom In',
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add_rounded),
                  ),
                  CivicFixSpacing.vSpaceSm,

                  // Zoom Out
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_out_btn',
                    backgroundColor: Colors.white,
                    foregroundColor: CivicFixColors.primary,
                    elevation: 2,
                    tooltip: 'Zoom Out',
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove_rounded),
                  ),
                  CivicFixSpacing.vSpaceSm,

                  // Center on GPS Location
                  FloatingActionButton.small(
                    heroTag: 'map_my_location_btn',
                    backgroundColor: Colors.white,
                    foregroundColor: CivicFixColors.secondaryDark,
                    elevation: 3,
                    tooltip: 'Use My Location',
                    onPressed: _isLocatingGps ? null : _centerOnMyLocation,
                    child: _isLocatingGps
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
            ),

            // 7. Empty State Overlay (When search/filters return 0 hazards)
            if (_filteredHazards.isEmpty)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.88),
                  child: Center(
                    child: Padding(
                      padding: CivicFixSpacing.pagePadding,
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

  Widget _buildInteractiveMapCanvas(Size size) {
    return Container(
      color: const Color(0xFFE8ECE9),
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.6,
        maxScale: 3.5,
        boundaryMargin: const EdgeInsets.all(500),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vector Map Surface (Parks, Waterways, Roads)
              CustomPaint(
                size: size,
                painter: _HazardMapCanvasPainter(),
              ),

              // User Current Location Marker (Center)
              Positioned(
                left: (size.width / 2) - 16,
                top: (size.height / 2) - 16,
                child: Semantics(
                  label: 'Your Current GPS Location',
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CivicFixColors.info.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: CivicFixColors.info,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Geotagged Hazard Markers
              ..._filteredHazards.map((hazard) {
                // Calculate relative position based on lat/lng offset
                final latDiff = hazard.latitude - _centerLat;
                final lngDiff = hazard.longitude - _centerLng;

                // Scale factor for map representation
                final double markerX = (size.width / 2) + (lngDiff * 18000);
                final double markerY = (size.height / 2) - (latDiff * 18000);

                // Clamp within bounds
                final clampedX = markerX.clamp(20.0, size.width - 60.0);
                final clampedY = markerY.clamp(60.0, size.height - 100.0);

                final isSelected = _selectedHazard?.id == hazard.id;

                return Positioned(
                  left: clampedX,
                  top: clampedY,
                  child: HazardMarker(
                    hazard: hazard,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedHazard = hazard;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Vector Painter to render a realistic map texture with roads, parks, and waterways.
class _HazardMapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Parks / Greenery Zones
    final parkPaint = Paint()
      ..color = const Color(0xFFD4E8D8)
      ..style = PaintingStyle.fill;

    final parkPath1 = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.15, size.width * 0.28, size.height * 0.22),
        const Radius.circular(20),
      ));
    canvas.drawPath(parkPath1, parkPaint);

    final parkPath2 = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.55, size.width * 0.3, size.height * 0.3),
        const Radius.circular(24),
      ));
    canvas.drawPath(parkPath2, parkPaint);

    // 2. Waterways / Lakes
    final waterPaint = Paint()
      ..color = const Color(0xFFCCE2EE)
      ..style = PaintingStyle.fill;

    final waterPath = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.82, size.width * 0.5, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.58, size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // 3. Primary Highways & Arterials
    final arterialRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    final arterialBorderPaint = Paint()
      ..color = const Color(0xFFD0D7D2)
      ..strokeWidth = 11.0
      ..strokeCap = StrokeCap.round;

    // Draw main arterial roads
    final mainRoad1 = Path()
      ..moveTo(0, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.42);

    final mainRoad2 = Path()
      ..moveTo(size.width * 0.45, 0)
      ..lineTo(size.width * 0.48, size.height);

    canvas.drawPath(mainRoad1, arterialBorderPaint);
    canvas.drawPath(mainRoad1, arterialRoadPaint);

    canvas.drawPath(mainRoad2, arterialBorderPaint);
    canvas.drawPath(mainRoad2, arterialRoadPaint);

    // 4. Secondary Urban Streets
    final secondaryRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.22), secondaryRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.58), Offset(size.width, size.height * 0.54), secondaryRoadPaint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.22, size.height), secondaryRoadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.72, size.height), secondaryRoadPaint);
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.6), Offset(size.width * 0.9, size.height * 0.3), secondaryRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
