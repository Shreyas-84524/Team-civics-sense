import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/map/spatial_data_service.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/models/hazard_model.dart';
import '../../../core/repositories/hazard_repository.dart';
import '../../../core/repositories/repository_locator.dart';
import '../../../core/services/government_hierarchy_repository.dart';
import '../../models/govt_user_model.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import '../common/govt_filter_chip.dart';
import '../common/govt_search_field.dart';
import 'govt_hazard_info_card.dart';
import 'govt_map_canvas.dart';
import 'govt_map_legend.dart';

/// Supported Administrative GIS Map Scopes for Government Operations.
enum GovtMapScope {
  city,
  zone,
  ward,
  department,
  unit, // Ward + Department
  crew, // Assigned Crew Worker
}

/// Consolidated, Jurisdiction-Enforcing GIS Map Component for Municipal Operations.
class GovernmentScopedMap extends StatefulWidget {
  final GovtUserModel? user;
  final GovtMapScope? scopeOverride;
  final String? scopeId;
  final List<HazardModel>? initialHazards;
  final HazardRepository? hazardRepository;
  final GovtComplaintRepository? complaintRepository;
  final GovernmentHierarchyRepository? hierarchyRepo;
  final double? height;
  final bool isEmbedded;
  final VoidCallback? onOpenFullscreen;

  const GovernmentScopedMap({
    super.key,
    this.user,
    this.scopeOverride,
    this.scopeId,
    this.initialHazards,
    this.hazardRepository,
    this.complaintRepository,
    this.hierarchyRepo,
    this.height,
    this.isEmbedded = false,
    this.onOpenFullscreen,
  });

  @override
  State<GovernmentScopedMap> createState() => _GovernmentScopedMapState();
}

class _GovernmentScopedMapState extends State<GovernmentScopedMap> {
  late final HazardRepository _hazardRepository;
  late final GovtComplaintRepository _complaintRepository;
  late final GovernmentHierarchyRepository _hierarchyRepo;

  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformationController = TransformationController();
  Timer? _searchDebounce;

  List<HazardModel> _allScopedHazards = [];
  List<HazardModel> _filteredHazards = [];
  HazardModel? _selectedHazard;
  bool _isLoading = true;
  String? _errorMessage;

  // Active filters
  ComplaintStatus? _selectedStatus;
  String _selectedCategory = 'all';
  HazardSeverity? _selectedSeverity;
  SpatialTimeFilter? _selectedTimeFilter;
  String? _selectedWardFilter;
  bool _showLegend = false;
  bool _showHeatmap = true;
  final bool _enableClustering = true;

  // Scope Resolution
  late GovtMapScope _effectiveScope;
  String? _fixedZoneId;
  String? _fixedWardId;
  String? _fixedDeptId;
  String? _fixedCrewId;

  static const List<String> _categories = [
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
    _hazardRepository = widget.hazardRepository ?? RepositoryLocator.hazardRepository;
    _complaintRepository = widget.complaintRepository ?? RepositoryLocator.govtComplaintRepository;
    _hierarchyRepo = widget.hierarchyRepo ?? LocalGovernmentHierarchyRepository();

    _resolveScope();
    _loadHazards();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resolveScope() {
    final user = widget.user;
    if (widget.scopeOverride != null) {
      _effectiveScope = widget.scopeOverride!;
      return;
    }

    if (user == null || user.isSuperAdmin) {
      _effectiveScope = GovtMapScope.city;
    } else if (user.isZonalDmc) {
      _effectiveScope = GovtMapScope.zone;
      _fixedZoneId = user.zoneId;
    } else if (user.isCentralHod) {
      _effectiveScope = GovtMapScope.department;
      _fixedDeptId = user.departmentId;
    } else if (user.isWardLead) {
      _effectiveScope = GovtMapScope.unit;
      _fixedWardId = user.wardId;
      _fixedDeptId = user.departmentId;
    } else if (user.isCrew) {
      _effectiveScope = GovtMapScope.crew;
      _fixedCrewId = user.employeeId;
      _fixedWardId = user.wardId;
      _fixedDeptId = user.departmentId;
    } else {
      // Default to Ward Officer
      _effectiveScope = GovtMapScope.ward;
      _fixedWardId = user.wardId;
    }
  }

  Future<void> _loadHazards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<HazardModel> raw;
      if (widget.initialHazards != null) {
        raw = widget.initialHazards!;
      } else {
        raw = await _hazardRepository.getHazards();
        if (raw.isEmpty) {
          // Attempt synthesizing markers from complaints
          final complaints = await _complaintRepository.getComplaints();
          raw = complaints.map((c) => HazardModel.fromComplaint(c)).toList();
        }
      }

      // Filter raw hazards strictly by jurisdiction scope
      final scoped = await _filterByJurisdictionScope(raw);

      if (mounted) {
        setState(() {
          _allScopedHazards = scoped;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load GIS hazard data: $e';
        });
      }
    }
  }

  Future<List<HazardModel>> _filterByJurisdictionScope(List<HazardModel> items) async {
    if (_effectiveScope == GovtMapScope.city) {
      return items;
    }

    final List<HazardModel> result = [];
    for (final h in items) {
      bool isAllowed = false;

      switch (_effectiveScope) {
        case GovtMapScope.city:
          isAllowed = true;
          break;
        case GovtMapScope.zone:
          // Check if ward belongs to fixedZoneId
          if (_fixedZoneId != null && h.ward != null) {
            final ward = await _hierarchyRepo.getWardById(h.ward!);
            if (ward?.zoneId == _fixedZoneId) {
              isAllowed = true;
            }
          }
          break;
        case GovtMapScope.ward:
          if (_fixedWardId != null) {
            if (h.ward == _fixedWardId) {
              isAllowed = true;
            }
          }
          break;
        case GovtMapScope.department:
          if (_fixedDeptId != null) {
            if (_matchesDeptCategory(h.category.name, _fixedDeptId!)) {
              isAllowed = true;
            }
          }
          break;
        case GovtMapScope.unit:
          if (_fixedWardId != null && _fixedDeptId != null) {
            final wardMatch = h.ward == _fixedWardId;
            final deptMatch = _matchesDeptCategory(h.category.name, _fixedDeptId!);
            if (wardMatch && deptMatch) {
              isAllowed = true;
            }
          }
          break;
        case GovtMapScope.crew:
          // Check crew assignment
          if (_fixedCrewId != null) {
            // If synthesized from complaint, complaintId or id check
            if (h.complaintId != null) {
              final complaint = await _complaintRepository.getComplaintById(h.complaintId!);
              if (complaint?.assignedCrewMemberId == _fixedCrewId || complaint?.assignedTo == _fixedCrewId) {
                isAllowed = true;
              }
            }
          }
          break;
      }

      if (isAllowed) {
        result.add(h);
      }
    }
    return result;
  }

  bool _matchesDeptCategory(String catName, String deptId) {
    final cat = catName.toLowerCase();
    final d = deptId.toLowerCase();
    if (d.contains('solid') || d.contains('waste')) return cat.contains('garbage');
    if (d.contains('road') || d.contains('maintenance')) return cat.contains('road') || cat.contains('manhole');
    if (d.contains('water') || d.contains('drainage')) return cat.contains('water') || cat.contains('drain');
    if (d.contains('light') || d.contains('electrical')) return cat.contains('light');
    return false;
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allScopedHazards.where((hazard) {
      // 1. Search Query
      if (query.isNotEmpty) {
        final title = hazard.title.toLowerCase();
        final cat = hazard.category.name.toLowerCase();
        final tkt = (hazard.ticketNumber ?? '').toLowerCase();
        final addr = (hazard.address).toLowerCase();
        final ward = (hazard.ward ?? '').toLowerCase();

        if (!title.contains(query) &&
            !cat.contains(query) &&
            !tkt.contains(query) &&
            !addr.contains(query) &&
            !ward.contains(query)) {
          return false;
        }
      }

      // 2. Status
      if (_selectedStatus != null && hazard.status != _selectedStatus) {
        return false;
      }

      // 3. Category
      if (_selectedCategory != 'all' &&
          !hazard.category.name.toLowerCase().contains(_selectedCategory.toLowerCase())) {
        return false;
      }

      // 4. Severity / Priority
      if (_selectedSeverity != null && hazard.severity != _selectedSeverity) {
        return false;
      }

      // 5. Ward Filter (if enabled for scope)
      if (_selectedWardFilter != null && _selectedWardFilter != 'all') {
        if (hazard.ward != _selectedWardFilter) {
          return false;
        }
      }

      // 6. Time Filter
      if (_selectedTimeFilter != null) {
        final now = DateTime.now();
        final reported = hazard.createdAt;
        switch (_selectedTimeFilter!) {
          case SpatialTimeFilter.last24Hours:
            if (now.difference(reported).inHours > 24) return false;
            break;
          case SpatialTimeFilter.last7Days:
            if (now.difference(reported).inDays > 7) return false;
            break;
          case SpatialTimeFilter.last30Days:
            if (now.difference(reported).inDays > 30) return false;
            break;
          case SpatialTimeFilter.allTime:
            break;
        }
      }

      return true;
    }).toList();

    setState(() {
      _filteredHazards = filtered;
      if (_selectedHazard != null && !filtered.contains(_selectedHazard)) {
        _selectedHazard = null;
      }
    });
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedCategory = 'all';
      _selectedSeverity = null;
      _selectedTimeFilter = null;
      _selectedWardFilter = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    Widget mapContent = Stack(
      children: [
        // 1. Basemap Canvas
        GovtMapCanvas(
          hazards: _filteredHazards,
          selectedHazard: _selectedHazard,
          transformationController: _transformationController,
          showHeatmap: _showHeatmap,
          enableClustering: _enableClustering,
          timeFilter: _selectedTimeFilter,
          onHazardSelected: (hazard) {
            setState(() => _selectedHazard = hazard);
          },
          onMapTap: () {
            if (_selectedHazard != null) {
              setState(() => _selectedHazard = null);
            }
          },
        ),

        // 2. Top Filter & Search Bar
        Positioned(
          top: CivicFixSpacing.md,
          left: CivicFixSpacing.md,
          right: CivicFixSpacing.md,
          child: _buildTopControlBar(isMobile),
        ),

        // 3. Floating Zoom & Layer Controls
        Positioned(
          bottom: _selectedHazard != null ? 220 : CivicFixSpacing.lg,
          right: CivicFixSpacing.md,
          child: _buildLayerControls(),
        ),

        // 4. Map Legend Overlay
        if (_showLegend)
          Positioned(
            bottom: CivicFixSpacing.lg,
            left: CivicFixSpacing.md,
            child: GovtMapLegend(onClose: () => setState(() => _showLegend = false)),
          ),

        // 5. Selected Hazard Info Card (Docked / Popover)
        if (_selectedHazard != null)
          Positioned(
            bottom: CivicFixSpacing.md,
            left: CivicFixSpacing.md,
            right: isMobile ? CivicFixSpacing.md : null,
            child: GovtHazardInfoCard(
              hazard: _selectedHazard!,
              onClose: () => setState(() => _selectedHazard = null),
              complaintRepository: _complaintRepository,
            ),
          ),

        // 6. Loading Indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: GovtThemeTokens.primary),
          ),

        // 7. Error Banner
        if (_errorMessage != null)
          Positioned(
            bottom: CivicFixSpacing.md,
            left: CivicFixSpacing.md,
            right: CivicFixSpacing.md,
            child: Container(
              padding: const EdgeInsets.all(CivicFixSpacing.md),
              decoration: BoxDecoration(
                color: GovtThemeTokens.error.withValues(alpha: 0.9),
                borderRadius: GovtThemeTokens.cardRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  CivicFixSpacing.hSpaceSm,
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadHazards,
                    child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (widget.isEmbedded) {
      return Container(
        height: widget.height ?? 400,
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: GovtThemeTokens.border),
          boxShadow: GovtThemeTokens.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: mapContent,
      );
    }

    return mapContent;
  }

  Widget _buildTopControlBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.md,
        vertical: CivicFixSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface.withValues(alpha: 0.95),
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GovtSearchField(
                  hintText: 'Search GIS hazards, wards, categories...',
                  onChanged: _onSearchChanged,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              // Scope Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: GovtThemeTokens.chipRadius,
                  border: Border.all(color: GovtThemeTokens.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: GovtThemeTokens.primary),
                    const SizedBox(width: 4),
                    Text(
                      _scopeLabel,
                      style: GovtTypography.caption.copyWith(
                        color: GovtThemeTokens.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onOpenFullscreen != null) ...[
                CivicFixSpacing.hSpaceSm,
                IconButton(
                  tooltip: 'Full Screen GIS Map',
                  icon: const Icon(Icons.fullscreen_rounded, color: GovtThemeTokens.primary),
                  onPressed: widget.onOpenFullscreen,
                ),
              ],
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          // Horizontal Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: CivicFixSpacing.xs),
                    child: GovtFilterChip(
                      label: cat == 'all' ? 'All Types' : cat,
                      isSelected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        _applyFilters();
                      },
                    ),
                  );
                }),
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: GovtThemeTokens.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heatmap Toggle
        _buildFabButton(
          icon: _showHeatmap ? Icons.layers_rounded : Icons.layers_outlined,
          tooltip: 'Toggle Heatmap',
          isActive: _showHeatmap,
          onTap: () => setState(() => _showHeatmap = !_showHeatmap),
        ),
        CivicFixSpacing.vSpaceXs,
        // Legend Toggle
        _buildFabButton(
          icon: Icons.info_outline_rounded,
          tooltip: 'Map Legend',
          isActive: _showLegend,
          onTap: () => setState(() => _showLegend = !_showLegend),
        ),
        CivicFixSpacing.vSpaceXs,
        // Zoom In
        _buildFabButton(
          icon: Icons.add_rounded,
          tooltip: 'Zoom In',
          onTap: () {
            _transformationController.value = _transformationController.value.clone()
              ..multiply(Matrix4.diagonal3Values(1.25, 1.25, 1.0));
          },
        ),
        CivicFixSpacing.vSpaceXs,
        // Zoom Out
        _buildFabButton(
          icon: Icons.remove_rounded,
          tooltip: 'Zoom Out',
          onTap: () {
            _transformationController.value = _transformationController.value.clone()
              ..multiply(Matrix4.diagonal3Values(0.8, 0.8, 1.0));
          },
        ),
      ],
    );
  }

  Widget _buildFabButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? GovtThemeTokens.primary : GovtThemeTokens.surface,
        shape: BoxShape.circle,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: isActive ? Colors.white : GovtThemeTokens.textPrimary),
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedStatus != null ||
      _selectedCategory != 'all' ||
      _selectedSeverity != null ||
      _selectedTimeFilter != null ||
      _selectedWardFilter != null;

  String get _scopeLabel {
    switch (_effectiveScope) {
      case GovtMapScope.city:
        return 'City Scope';
      case GovtMapScope.zone:
        return 'Zone Scope (${_fixedZoneId ?? "Active"})';
      case GovtMapScope.ward:
        return 'Ward Scope (${_fixedWardId ?? "Active"})';
      case GovtMapScope.department:
        return 'Dept Scope';
      case GovtMapScope.unit:
        return 'Unit Scope (${_fixedWardId ?? ""})';
      case GovtMapScope.crew:
        return 'Crew Scope';
    }
  }
}
