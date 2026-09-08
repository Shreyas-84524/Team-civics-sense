import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/mock_auth_service.dart';
import '../widgets/complaint_card.dart';
import '../widgets/complaints/complaint_filter_bottom_sheet.dart';

/// Complete Citizen My Complaints Screen.
class MyComplaintsScreen extends StatefulWidget {
  final ComplaintRepository? repository;
  final AuthService? authService;
  final ConnectivityService? connectivityService;

  const MyComplaintsScreen({
    super.key,
    this.repository,
    this.authService,
    this.connectivityService,
  });

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  late final ComplaintRepository _repository;
  late final AuthService _authService;
  late final ConnectivityService _connectivityService;

  List<ComplaintModel> _allComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  ComplaintFilterCriteria _filterCriteria = const ComplaintFilterCriteria();

  final List<ComplaintStatus> _quickStatuses = [
    ComplaintStatus.reported,
    ComplaintStatus.verified,
    ComplaintStatus.assigned,
    ComplaintStatus.inProgress,
    ComplaintStatus.resolved,
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockComplaintRepository();
    _authService = widget.authService ?? MockAuthService();
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _loadComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final citizenId = _authService.currentUser?.id ?? 'user_citizen_001';
      final complaints = await _repository.getCitizenComplaints(citizenId);
      if (mounted) {
        setState(() {
          _allComplaints = List.from(complaints);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Couldn't load your complaints.";
          _isLoading = false;
        });
      }
    }
  }

  List<ComplaintModel> _getFilteredComplaints() {
    final query = _searchController.text.trim().toLowerCase();

    return _allComplaints.where((complaint) {
      // 1. Status Filter
      if (_filterCriteria.status != null && complaint.status != _filterCriteria.status) {
        return false;
      }

      // 2. Category Filter
      if (_filterCriteria.category != null && complaint.category.id != _filterCriteria.category!.id) {
        return false;
      }

      // 3. Search Query (Ticket ID, Title, Category, Location)
      if (query.isNotEmpty) {
        final matchesTicket = complaint.ticketNumber.toLowerCase().contains(query);
        final matchesTitle = complaint.title.toLowerCase().contains(query);
        final matchesCategory = complaint.category.name.toLowerCase().contains(query);
        final matchesAddress = complaint.location.fullDisplayAddress.toLowerCase().contains(query) ||
            complaint.location.shortDisplayAddress.toLowerCase().contains(query) ||
            (complaint.location.landmark?.toLowerCase().contains(query) ?? false) ||
            (complaint.location.ward?.toLowerCase().contains(query) ?? false);

        if (!matchesTicket && !matchesTitle && !matchesCategory && !matchesAddress) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_filterCriteria.sortOption) {
          case ComplaintSortOption.newestFirst:
            return b.createdAt.compareTo(a.createdAt);
          case ComplaintSortOption.oldestFirst:
            return a.createdAt.compareTo(b.createdAt);
          case ComplaintSortOption.recentlyUpdated:
            return b.updatedAt.compareTo(a.updatedAt);
        }
      });
  }

  void _clearFiltersAndSearch() {
    setState(() {
      _searchController.clear();
      _filterCriteria = const ComplaintFilterCriteria();
    });
  }

  void _openFilterBottomSheet() {
    ComplaintFilterBottomSheet.show(
      context: context,
      initialCriteria: _filterCriteria,
      onApply: (updated) {
        setState(() {
          _filterCriteria = updated;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredComplaints = _getFilteredComplaints();
    final hasActiveFilterOrSearch =
        _searchController.text.trim().isNotEmpty || _filterCriteria.hasActiveFilters;

    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'My Complaints',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: EdgeInsets.zero,
          child: RefreshIndicator(
            onRefresh: () => _loadComplaints(forceRefresh: true),
            color: CivicFixColors.primary,
            child: _buildContent(filteredComplaints, hasActiveFilterOrSearch),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<ComplaintModel> filteredComplaints, bool isFiltered) {
    if (_isLoading) {
      return const Center(
        child: LoadingState(message: 'Loading your complaints...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: ErrorState(
            title: 'Something went wrong',
            message: _errorMessage!,
            onRetry: () => _loadComplaints(forceRefresh: true),
          ),
        ),
      );
    }

    // No complaints reported yet at all
    if (_allComplaints.isEmpty) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: EmptyState(
            title: 'No complaints yet',
            description: 'Report a civic issue and track its progress here.',
            actionText: 'Report an Issue',
            icon: Icons.assignment_outlined,
            onActionPressed: () {
              Navigator.pushNamed(context, AppRoutes.reportIssue);
            },
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // 1. Subtitle & Search Bar Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CivicFixSpacing.lg,
              CivicFixSpacing.sm,
              CivicFixSpacing.lg,
              CivicFixSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_connectivityService.isOnline)
                  OfflineCacheBanner(
                    onRefresh: () => _loadComplaints(forceRefresh: true),
                  ),
                Text(
                  "Track the civic issues you've reported.",
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,

                // Search input field
                _buildSearchField(),
                CivicFixSpacing.vSpaceSm,

                // Status Filter Chips Row + Filter Button
                _buildQuickFiltersRow(),
                CivicFixSpacing.vSpaceMd,

                // Complaint count summary
                _buildSummaryCount(filteredComplaints.length, isFiltered),
              ],
            ),
          ),
        ),

        // 2. Complaint Cards List or Filtered Empty State
        if (filteredComplaints.isEmpty && isFiltered)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: CivicFixSpacing.pagePadding,
                child: EmptyState(
                  title: 'No complaints found',
                  description: 'Try a different search or filter.',
                  actionText: 'Clear Filters',
                  icon: Icons.search_off_rounded,
                  onActionPressed: _clearFiltersAndSearch,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              CivicFixSpacing.lg,
              CivicFixSpacing.xs,
              CivicFixSpacing.lg,
              CivicFixSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final complaint = filteredComplaints[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: CivicFixSpacing.md),
                    child: ComplaintCard(
                      complaint: complaint,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.complaintDetails,
                          arguments: complaint,
                        );
                      },
                    ),
                  );
                },
                childCount: filteredComplaints.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Semantics(
      label: 'Search complaints by ID, title, category, or location',
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search complaints...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: CivicFixColors.secondaryText,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: CivicFixColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: CivicFixRadius.buttonRadius,
            borderSide: const BorderSide(color: CivicFixColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: CivicFixRadius.buttonRadius,
            borderSide: const BorderSide(color: CivicFixColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: CivicFixRadius.buttonRadius,
            borderSide: const BorderSide(color: CivicFixColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFiltersRow() {
    final hasAdvancedFilters =
        _filterCriteria.category != null || _filterCriteria.sortOption != ComplaintSortOption.recentlyUpdated;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Filter Bottom Sheet Button
          OutlinedButton.icon(
            onPressed: _openFilterBottomSheet,
            icon: Badge(
              isLabelVisible: hasAdvancedFilters,
              smallSize: 8,
              backgroundColor: CivicFixColors.alertDark,
              child: const Icon(Icons.tune_rounded, size: 16),
            ),
            label: Text(
              _filterCriteria.category != null ? _filterCriteria.category!.name : 'Filter',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.md,
                vertical: CivicFixSpacing.sm + 2,
              ),
              foregroundColor:
                  hasAdvancedFilters ? CivicFixColors.primary : CivicFixColors.primaryText,
              side: BorderSide(
                color: hasAdvancedFilters ? CivicFixColors.primary : CivicFixColors.border,
                width: hasAdvancedFilters ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: CivicFixRadius.chipRadius,
              ),
            ),
          ),
          CivicFixSpacing.hSpaceSm,

          // All Statuses Chip
          _buildStatusChip(
            label: 'All',
            isSelected: _filterCriteria.status == null,
            onTap: () {
              setState(() {
                _filterCriteria = _filterCriteria.copyWith(clearStatus: true);
              });
            },
          ),
          CivicFixSpacing.hSpaceSm,

          // Specific Status Chips
          ..._quickStatuses.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
              child: _buildStatusChip(
                label: status.label,
                isSelected: _filterCriteria.status == status,
                onTap: () {
                  setState(() {
                    _filterCriteria = _filterCriteria.copyWith(
                      status: _filterCriteria.status == status ? null : status,
                      clearStatus: _filterCriteria.status == status,
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: CivicFixRadius.chipRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md,
          vertical: CivicFixSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? CivicFixColors.primary : CivicFixColors.surface,
          borderRadius: CivicFixRadius.chipRadius,
          border: Border.all(
            color: isSelected ? CivicFixColors.primary : CivicFixColors.border,
          ),
        ),
        child: Text(
          label,
          style: CivicFixTypography.captionMedium.copyWith(
            color: isSelected ? Colors.white : CivicFixColors.primaryText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCount(int count, bool isFiltered) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isFiltered
              ? '$count ${count == 1 ? "complaint" : "complaints"} found'
              : '$count ${count == 1 ? "complaint" : "complaints"}',
          style: CivicFixTypography.captionMedium.copyWith(
            color: CivicFixColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isFiltered)
          InkWell(
            onTap: _clearFiltersAndSearch,
            child: Text(
              'Clear all',
              style: CivicFixTypography.captionMedium.copyWith(
                color: CivicFixColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
