import 'package:flutter/material.dart';
import '../../../User UI/services/location_service.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/location/location_model.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/models/hazard_model.dart';
import '../../../core/repositories/hazard_repository.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_filter_chip.dart';
import '../../widgets/common/govt_search_field.dart';
import '../../widgets/map/govt_hazard_info_card.dart';
import '../../widgets/map/govt_map_canvas.dart';
import '../../widgets/map/govt_map_legend.dart';

/// Government Live Hazard GIS Monitoring & Spatial Triage Screen.
class GovtHazardMapScreen extends StatefulWidget {
  final HazardRepository? hazardRepository;
  final GovtComplaintRepository? complaintRepository;
  final LocationService? locationService;

  const GovtHazardMapScreen({
    super.key,
    this.hazardRepository,
    this.complaintRepository,
    this.locationService,
  });

  @override
  State<GovtHazardMapScreen> createState() => _GovtHazardMapScreenState();
}

class _GovtHazardMapScreenState extends State<GovtHazardMapScreen> {
  late final HazardRepository _hazardRepository;
  late final GovtComplaintRepository _complaintRepository;
  late final LocationService _locationService;

  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformationController = TransformationController();

  List<HazardModel> _allHazards = [];
  List<HazardModel> _filteredHazards = [];
  HazardModel? _selectedHazard;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocatingGps = false;
  String? _locationNotice;

  // Active filters
  ComplaintStatus? _selectedStatus;
  String _selectedCategory = 'all';
  HazardSeverity? _selectedSeverity;
  bool _showLegend = false;

  CivicLocation? _currentUserLocation;

  static const List<String> _categoryOptions = [
    'all',
    'Road Damage',
    'Waterlogging',
    'Open Manhole',
    'Garbage',
    'Drainage',
    'Street Light',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _hazardRepository = widget.hazardRepository ?? MockHazardRepository();
    _complaintRepository = widget.complaintRepository ?? MockGovtComplaintRepository();
    _locationService = widget.locationService ?? MockLocationService();

    _resetMapTransform();
    _loadHazards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetMapTransform() {
    _transformationController.value = Matrix4.identity();
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
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load GIS hazard data. Please retry.';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var results = List<HazardModel>.from(_allHazards);

    // 1. Status Filter
    if (_selectedStatus != null) {
      results = results.where((h) => h.status == _selectedStatus).toList();
    }

    // 2. Category Filter
    if (_selectedCategory != 'all') {
      final catQuery = _selectedCategory.toLowerCase();
      results = results.where((h) {
        final catName = h.category.name.toLowerCase();
        final title = h.title.toLowerCase();

        if (catQuery.contains('road')) {
          return catName.contains('road') || catName.contains('infrastructure') || title.contains('road');
        } else if (catQuery.contains('waterlog') || catQuery.contains('water')) {
          return catName.contains('water') || title.contains('water');
        } else if (catQuery.contains('manhole')) {
          return title.contains('manhole') || catName.contains('infrastructure');
        } else if (catQuery.contains('garbage')) {
          return catName.contains('waste') || catName.contains('sanitation') || title.contains('garbage');
        } else if (catQuery.contains('drainage')) {
          return catName.contains('drainage') || title.contains('drain');
        } else if (catQuery.contains('light')) {
          return catName.contains('light') || catName.contains('electr') || title.contains('light');
        } else if (catQuery.contains('other')) {
          return catName.contains('other') || catName.contains('general') || title.contains('hoarding');
        }
        return catName.contains(catQuery);
      }).toList();
    }

    // 3. Severity Filter
    if (_selectedSeverity != null) {
      results = results.where((h) => h.severity == _selectedSeverity).toList();
    }

    // 4. Search Filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      results = results.where((h) {
        final matchesTicket = (h.ticketNumber ?? '').toLowerCase().contains(query);
        final matchesTitle = h.title.toLowerCase().contains(query);
        final matchesCat = h.category.name.toLowerCase().contains(query);
        final matchesAddr = h.address.toLowerCase().contains(query);
        final matchesWard = (h.ward ?? '').toLowerCase().contains(query);
        return matchesTicket || matchesTitle || matchesCat || matchesAddr || matchesWard;
      }).toList();
    }

    setState(() {
      _filteredHazards = results;
      if (_selectedHazard != null && !results.any((h) => h.id == _selectedHazard!.id)) {
        _selectedHazard = null;
      }
    });
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedStatus = null;
      _selectedCategory = 'all';
      _selectedSeverity = null;
      _selectedHazard = null;
    });
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      _selectedStatus != null ||
      _selectedCategory != 'all' ||
      _selectedSeverity != null ||
      _searchController.text.trim().isNotEmpty;

  void _onHazardSelected(HazardModel hazard) {
    setState(() {
      _selectedHazard = hazard;
    });
  }

  Future<void> _handleGpsLocation() async {
    setState(() {
      _isLocatingGps = true;
      _locationNotice = null;
    });

    try {
      final loc = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (loc != null) {
        setState(() {
          _currentUserLocation = loc;
          _isLocatingGps = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Centered map at your inspection location (${loc.ward ?? "Central Ward"}).'),
            backgroundColor: GovtThemeTokens.secondary,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _isLocatingGps = false;
          _locationNotice = 'GPS signal unavailable. Showing default ward center.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocatingGps = false;
        _locationNotice = 'Location permissions disabled. Browsing central ward coordinates.';
      });
    }
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.25).clamp(0.5, 3.0);
    _transformationController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.25).clamp(0.5, 3.0);
    _transformationController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GovtThemeTokens.background,
      child: Column(
        children: [
          // 1. Top Search & Filter Bar
          _buildTopFilterToolbar(),

        // 2. Main Map Workspace with Overlay Controls
        Expanded(
          child: Stack(
            children: [
              // Interactive Canvas
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.xl),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.surface,
                      borderRadius: GovtThemeTokens.cardRadius,
                      border: Border.all(color: GovtThemeTokens.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 36),
                        CivicFixSpacing.vSpaceMd,
                        Text(_errorMessage!, style: CivicFixTypography.bodySmall),
                        CivicFixSpacing.vSpaceMd,
                        ElevatedButton(
                          onPressed: _loadHazards,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GovtThemeTokens.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Retry GIS Connection'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GovtMapCanvas(
                  hazards: _filteredHazards,
                  selectedHazard: _selectedHazard,
                  onHazardSelected: _onHazardSelected,
                  transformationController: _transformationController,
                  userLocation: _currentUserLocation,
                  onMapTap: () {
                    if (_selectedHazard != null) {
                      setState(() => _selectedHazard = null);
                    }
                  },
                ),

              // Non-blocking location notice banner
              if (_locationNotice != null)
                Positioned(
                  top: CivicFixSpacing.md,
                  left: CivicFixSpacing.lg,
                  right: CivicFixSpacing.lg,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: GovtThemeTokens.chipRadius,
                        border: Border.all(color: const Color(0xFFFFB74D)),
                        boxShadow: GovtThemeTokens.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 18),
                          CivicFixSpacing.hSpaceSm,
                          Text(
                            _locationNotice!,
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: const Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          CivicFixSpacing.hSpaceSm,
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFE65100)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            onPressed: () => setState(() => _locationNotice = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Empty Search / Filter Results Banner
              if (!_isLoading && _errorMessage == null && _filteredHazards.isEmpty)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(CivicFixSpacing.lg),
                      margin: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.xl),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surface,
                        borderRadius: GovtThemeTokens.cardRadius,
                        border: Border.all(color: GovtThemeTokens.border),
                        boxShadow: GovtThemeTokens.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_off_rounded, size: 32, color: GovtThemeTokens.textSecondary),
                          CivicFixSpacing.vSpaceSm,
                          Text(
                            'No hazards match your filter criteria',
                            style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Try adjusting search terms, category, or status filters.',
                            style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                          ),
                          CivicFixSpacing.vSpaceMd,
                          OutlinedButton(
                            onPressed: _clearAllFilters,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Floating Controls (Right Side)
              Positioned(
                right: CivicFixSpacing.lg,
                bottom: CivicFixSpacing.lg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle Legend
                    _buildFloatingButton(
                      icon: Icons.layers_outlined,
                      tooltip: 'Toggle GIS Legend',
                      isActive: _showLegend,
                      onPressed: () => setState(() => _showLegend = !_showLegend),
                    ),
                    CivicFixSpacing.vSpaceSm,

                    // Locate My GPS
                    _buildFloatingButton(
                      icon: _isLocatingGps ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
                      tooltip: 'Center on My GPS Location',
                      onPressed: _handleGpsLocation,
                    ),
                    CivicFixSpacing.vSpaceSm,

                    // Center on Ward
                    _buildFloatingButton(
                      icon: Icons.center_focus_strong_rounded,
                      tooltip: 'Reset to Ward Center',
                      onPressed: _resetMapTransform,
                    ),
                    CivicFixSpacing.vSpaceSm,

                    // Zoom In
                    _buildFloatingButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Zoom In',
                      onPressed: _zoomIn,
                    ),
                    CivicFixSpacing.vSpaceXs,

                    // Zoom Out
                    _buildFloatingButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Zoom Out',
                      onPressed: _zoomOut,
                    ),
                  ],
                ),
              ),

              // GIS Map Legend Overlay (Top-Right)
              if (_showLegend)
                Positioned(
                  top: CivicFixSpacing.md,
                  right: CivicFixSpacing.lg,
                  child: GovtMapLegend(
                    onClose: () => setState(() => _showLegend = false),
                  ),
                ),

              // Selected Hazard Info Card (Bottom-Left on Desktop, Bottom Center on Mobile)
              if (_selectedHazard != null)
                Positioned(
                  bottom: CivicFixSpacing.lg,
                  left: CivicFixSpacing.lg,
                  child: GovtHazardInfoCard(
                    hazard: _selectedHazard!,
                    complaintRepository: _complaintRepository,
                    onClose: () => setState(() => _selectedHazard = null),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTopFilterToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.lg,
            vertical: CivicFixSpacing.md,
          ),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            border: const Border(bottom: BorderSide(color: GovtThemeTokens.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                GovtSearchField(
                  controller: _searchController,
                  hintText: 'Search by ticket ID, category, title, or locality...',
                  onChanged: (_) => _applyFilters(),
                ),
                CivicFixSpacing.vSpaceSm,
                Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(child: _buildSeverityDropdown()),
                    if (_hasActiveFilters) ...[
                      CivicFixSpacing.hSpaceSm,
                      _buildClearButton(),
                    ],
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GovtSearchField(
                        controller: _searchController,
                        hintText: 'Search by ticket ID, category, title, or locality...',
                        onChanged: (_) => _applyFilters(),
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      flex: 2,
                      child: _buildCategoryDropdown(),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      flex: 2,
                      child: _buildSeverityDropdown(),
                    ),
                    if (_hasActiveFilters) ...[
                      CivicFixSpacing.hSpaceMd,
                      _buildClearButton(),
                    ],
                  ],
                ),
              ],
              CivicFixSpacing.vSpaceSm,

              // Status Filter Chips Row & Results Count
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          GovtFilterChip(
                            label: 'All Hazards',
                            isSelected: _selectedStatus == null,
                            onSelected: (_) {
                              setState(() => _selectedStatus = null);
                              _applyFilters();
                            },
                          ),
                          CivicFixSpacing.hSpaceSm,
                          ...ComplaintStatus.values.where((s) => s != ComplaintStatus.rejected).map((status) {
                            return Padding(
                              padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
                              child: GovtFilterChip(
                                label: status.label,
                                isSelected: _selectedStatus == status,
                                onSelected: (_) {
                                  setState(() => _selectedStatus = status);
                                  _applyFilters();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: GovtThemeTokens.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        CivicFixSpacing.hSpaceXs,
                        Text(
                          '${_filteredHazards.length} Active Hazards',
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: GovtThemeTokens.primary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          style: CivicFixTypography.bodySmall,
          items: _categoryOptions.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(
                cat == 'all' ? 'All Hazard Categories' : cat,
                overflow: TextOverflow.ellipsis,
                style: CivicFixTypography.bodySmall,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCategory = val);
              _applyFilters();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSeverityDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HazardSeverity?>(
          value: _selectedSeverity,
          isExpanded: true,
          style: CivicFixTypography.bodySmall,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('All Severity Levels', style: CivicFixTypography.bodySmall),
            ),
            ...HazardSeverity.values.map((sev) {
              return DropdownMenuItem(
                value: sev,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: sev.color, shape: BoxShape.circle),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text('${sev.label} Severity', style: CivicFixTypography.bodySmall),
                  ],
                ),
              );
            }),
          ],
          onChanged: (val) {
            setState(() => _selectedSeverity = val);
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return TextButton.icon(
      icon: const Icon(Icons.clear_all_rounded, size: 16),
      label: const Text('Clear'),
      style: TextButton.styleFrom(
        foregroundColor: GovtThemeTokens.alert,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: _clearAllFilters,
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? GovtThemeTokens.primary : GovtThemeTokens.surface,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : GovtThemeTokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
