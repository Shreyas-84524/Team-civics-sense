import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_data_table.dart';
import '../../widgets/common/govt_filter_chip.dart';
import '../../widgets/common/govt_search_field.dart';
import '../../widgets/complaints/govt_complaint_card.dart';

/// Complete screen for Government Complaint & Grievance Management.
class GovtComplaintListScreen extends StatefulWidget {
  const GovtComplaintListScreen({super.key});

  @override
  State<GovtComplaintListScreen> createState() => _GovtComplaintListScreenState();
}

class _GovtComplaintListScreenState extends State<GovtComplaintListScreen> {
  final GovtComplaintRepository _repository = MockGovtComplaintRepository();
  final TextEditingController _searchController = TextEditingController();

  ComplaintStatus? _selectedStatus;
  String? _selectedCategoryId;
  ComplaintPriority? _selectedPriority;
  bool? _selectedAssignment; // null = all, true = assigned, false = unassigned
  GovtComplaintSort _selectedSort = GovtComplaintSort.newest;

  List<ComplaintModel> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _hasActiveFilters =>
      _selectedStatus != null ||
      _selectedCategoryId != null ||
      _selectedPriority != null ||
      _selectedAssignment != null ||
      _selectedSort != GovtComplaintSort.newest ||
      _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getComplaints(
        categoryId: _selectedCategoryId,
        status: _selectedStatus,
        priority: _selectedPriority,
        isAssigned: _selectedAssignment,
        searchQuery: _searchController.text,
        sortBy: _selectedSort,
      );
      if (mounted) {
        setState(() {
          _complaints = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load complaints: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedCategoryId = null;
      _selectedPriority = null;
      _selectedAssignment = null;
      _selectedSort = GovtComplaintSort.newest;
      _searchController.clear();
    });
    _loadComplaints();
  }

  void _openDetails(ComplaintModel complaint) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtComplaintDetails,
      arguments: complaint,
    ).then((_) => _loadComplaints());
  }

  void _openAssignment(ComplaintModel complaint) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtComplaintAssignment,
      arguments: complaint,
    ).then((_) => _loadComplaints());
  }

  void _openStatusUpdate(ComplaintModel complaint) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtStatusUpdate,
      arguments: complaint,
    ).then((_) => _loadComplaints());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= GovtThemeTokens.desktopBreakpoint;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter & Search Toolbar
            _buildToolbar(),
            CivicFixSpacing.vSpaceMd,

            // Main Grievance List / Table / Error / Empty
            Expanded(
              child: _buildBody(isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(CivicFixSpacing.xl),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: GovtThemeTokens.cardRadius,
            border: Border.all(color: GovtThemeTokens.alert.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: GovtThemeTokens.alert),
              CivicFixSpacing.vSpaceMd,
              Text(
                _errorMessage!,
                style: CivicFixTypography.body.copyWith(color: GovtThemeTokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              CivicFixSpacing.vSpaceLg,
              ElevatedButton.icon(
                onPressed: _loadComplaints,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopTable();
    } else {
      return _buildResponsiveCardsList();
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search Field + Clear Filters + Refresh Action
          Row(
            children: [
              Expanded(
                child: GovtSearchField(
                  controller: _searchController,
                  hintText: 'Search by Ticket #, title, ward, address, citizen ID...',
                  onChanged: (_) => _loadComplaints(),
                  onClear: () => _loadComplaints(),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              if (_hasActiveFilters) ...[
                OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GovtThemeTokens.textSecondary,
                    side: const BorderSide(color: GovtThemeTokens.border),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
              ],
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh List',
                onPressed: _loadComplaints,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          // Row 2: Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GovtFilterChip(
                  label: 'All Grievances',
                  isSelected: _selectedStatus == null,
                  onSelected: (_) {
                    setState(() => _selectedStatus = null);
                    _loadComplaints();
                  },
                ),
                CivicFixSpacing.hSpaceSm,
                GovtFilterChip(
                  label: 'Reported',
                  icon: Icons.assignment_outlined,
                  isSelected: _selectedStatus == ComplaintStatus.reported,
                  onSelected: (sel) {
                    setState(() => _selectedStatus = sel ? ComplaintStatus.reported : null);
                    _loadComplaints();
                  },
                ),
                CivicFixSpacing.hSpaceSm,
                GovtFilterChip(
                  label: 'Verified',
                  icon: Icons.verified_outlined,
                  isSelected: _selectedStatus == ComplaintStatus.verified,
                  onSelected: (sel) {
                    setState(() => _selectedStatus = sel ? ComplaintStatus.verified : null);
                    _loadComplaints();
                  },
                ),
                CivicFixSpacing.hSpaceSm,
                GovtFilterChip(
                  label: 'Assigned',
                  icon: Icons.person_pin_circle_outlined,
                  isSelected: _selectedStatus == ComplaintStatus.assigned,
                  onSelected: (sel) {
                    setState(() => _selectedStatus = sel ? ComplaintStatus.assigned : null);
                    _loadComplaints();
                  },
                ),
                CivicFixSpacing.hSpaceSm,
                GovtFilterChip(
                  label: 'In Progress',
                  icon: Icons.engineering_rounded,
                  isSelected: _selectedStatus == ComplaintStatus.inProgress,
                  onSelected: (sel) {
                    setState(() => _selectedStatus = sel ? ComplaintStatus.inProgress : null);
                    _loadComplaints();
                  },
                ),
                CivicFixSpacing.hSpaceSm,
                GovtFilterChip(
                  label: 'Resolved',
                  icon: Icons.check_circle_outline_rounded,
                  isSelected: _selectedStatus == ComplaintStatus.resolved,
                  onSelected: (sel) {
                    setState(() => _selectedStatus = sel ? ComplaintStatus.resolved : null);
                    _loadComplaints();
                  },
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceSm,

          // Row 3: Category, Priority, Assignment & Sort Dropdowns
          Wrap(
            spacing: CivicFixSpacing.md,
            runSpacing: CivicFixSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Category Dropdown
              _buildDropdownContainer(
                icon: Icons.category_outlined,
                child: DropdownButton<String?>(
                  value: _selectedCategoryId,
                  hint: Text('All Categories', style: CivicFixTypography.captionMedium),
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories', style: CivicFixTypography.captionMedium),
                    ),
                    ...CivicCategory.defaultCategories.map((cat) {
                      return DropdownMenuItem<String?>(
                        value: cat.id,
                        child: Text(cat.name, style: CivicFixTypography.captionMedium),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCategoryId = val);
                    _loadComplaints();
                  },
                ),
              ),

              // Priority Dropdown
              _buildDropdownContainer(
                icon: Icons.flag_outlined,
                child: DropdownButton<ComplaintPriority?>(
                  value: _selectedPriority,
                  hint: Text('All Priorities', style: CivicFixTypography.captionMedium),
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  items: [
                    DropdownMenuItem<ComplaintPriority?>(
                      value: null,
                      child: Text('All Priorities', style: CivicFixTypography.captionMedium),
                    ),
                    DropdownMenuItem<ComplaintPriority?>(
                      value: ComplaintPriority.emergency,
                      child: Text('Emergency', style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.alert)),
                    ),
                    DropdownMenuItem<ComplaintPriority?>(
                      value: ComplaintPriority.high,
                      child: Text('High Priority', style: CivicFixTypography.captionMedium.copyWith(color: const Color(0xFFD97706))),
                    ),
                    DropdownMenuItem<ComplaintPriority?>(
                      value: ComplaintPriority.medium,
                      child: Text('Medium Priority', style: CivicFixTypography.captionMedium),
                    ),
                    DropdownMenuItem<ComplaintPriority?>(
                      value: ComplaintPriority.low,
                      child: Text('Low Priority', style: CivicFixTypography.captionMedium),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedPriority = val);
                    _loadComplaints();
                  },
                ),
              ),

              // Assignment Dropdown
              _buildDropdownContainer(
                icon: Icons.assignment_ind_outlined,
                child: DropdownButton<bool?>(
                  value: _selectedAssignment,
                  hint: Text('All Assignments', style: CivicFixTypography.captionMedium),
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  items: [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('All Assignments', style: CivicFixTypography.captionMedium),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('Assigned', style: CivicFixTypography.captionMedium),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('Unassigned', style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.alert)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedAssignment = val);
                    _loadComplaints();
                  },
                ),
              ),

              // Sort Dropdown
              _buildDropdownContainer(
                icon: Icons.sort_rounded,
                child: DropdownButton<GovtComplaintSort>(
                  value: _selectedSort,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  items: GovtComplaintSort.values.map((s) {
                    return DropdownMenuItem<GovtComplaintSort>(
                      value: s,
                      child: Text(s.label, style: CivicFixTypography.captionMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSort = val);
                      _loadComplaints();
                    }
                  },
                ),
              ),

              // Matching Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_complaints.length} records',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GovtThemeTokens.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GovtThemeTokens.textSecondary),
          const SizedBox(width: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    if (!_isLoading && _complaints.isEmpty) {
      return _buildEmptyState();
    }

    final columns = [
      const GovtDataColumn(label: 'Ticket #', width: 130),
      const GovtDataColumn(label: 'Subject / Category', width: 220),
      const GovtDataColumn(label: 'Location / Ward', width: 180),
      const GovtDataColumn(label: 'Priority', width: 120),
      const GovtDataColumn(label: 'Status', width: 140),
      const GovtDataColumn(label: 'Assigned To', width: 160),
      const GovtDataColumn(label: 'Reported', width: 110),
      const GovtDataColumn(label: 'Actions', width: 180),
    ];

    final rows = _complaints.map((c) {
      return [
        Text(
          c.ticketNumber,
          style: CivicFixTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.primary,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CivicFixTypography.bodySmallMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              c.category.name,
              style: CivicFixTypography.caption.copyWith(
                color: GovtThemeTokens.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Text(
          '${c.location.address}\n${c.location.ward ?? "Central Zone"}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.caption,
        ),
        PriorityBadge(priority: c.priority, isCompact: true),
        StatusBadge(status: c.status, isCompact: true),
        Text(
          c.assignedTo != null ? '${c.assignedTo}\n(${c.effectiveDepartment})' : 'Unassigned',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.caption.copyWith(
            color: c.assignedTo != null ? GovtThemeTokens.textPrimary : GovtThemeTokens.alert,
            fontStyle: c.assignedTo == null ? FontStyle.italic : FontStyle.normal,
            fontWeight: c.assignedTo == null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          DateFormatter.formatRelative(c.createdAt),
          style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              tooltip: 'View Details',
              onPressed: () => _openDetails(c),
              splashRadius: 16,
            ),
            CivicFixSpacing.hSpaceXs,
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              tooltip: 'Assign Officer',
              onPressed: () => _openAssignment(c),
              splashRadius: 16,
            ),
            CivicFixSpacing.hSpaceXs,
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.sync_rounded, size: 18),
              tooltip: 'Update Status',
              onPressed: () => _openStatusUpdate(c),
              splashRadius: 16,
            ),
          ],
        ),
      ];
    }).toList();

    return GovtDataTable(
      columns: columns,
      rows: rows,
      isLoading: _isLoading,
      totalCount: _complaints.length,
      currentPage: 1,
    );
  }

  Widget _buildResponsiveCardsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
        ),
      );
    }

    if (_complaints.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: _complaints.length,
      separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
      itemBuilder: (context, index) {
        final c = _complaints[index];
        return GovtComplaintCard(
          complaint: c,
          onTap: () => _openDetails(c),
          onAssign: () => _openAssignment(c),
          onUpdateStatus: () => _openStatusUpdate(c),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(CivicFixSpacing.xxl),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: GovtThemeTokens.textDisabled,
            ),
            CivicFixSpacing.vSpaceMd,
            Text(
              'No complaints found',
              style: CivicFixTypography.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            CivicFixSpacing.vSpaceXs,
            Text(
              'No civic grievances match the active search and filter criteria.',
              style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters) ...[
              CivicFixSpacing.vSpaceLg,
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Clear All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
