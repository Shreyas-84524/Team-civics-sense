import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/assistant/civic_assistant_fab.dart';
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
  StreamSubscription<List<ComplaintModel>>? _complaintsSubscription;

  List<ComplaintModel> _allComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _upvotesInFlight = {};
  final Set<String> _supportedComplaintIds = {};

  final TextEditingController _searchController = TextEditingController();
  ComplaintFilterCriteria _filterCriteria = const ComplaintFilterCriteria();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? RepositoryLocator.complaintRepository;
    _authService = widget.authService ?? AuthServiceLocator.citizenAuth;
    _connectivityService =
        widget.connectivityService ?? AppConnectivityService();
    _loadComplaints();
    _subscribeToLiveComplaints();
  }

  void _subscribeToLiveComplaints() {
    final citizenId =
        _authService.currentUser?.id ?? _authService.currentUid ?? '';
    _complaintsSubscription?.cancel();
    _complaintsSubscription = _repository
        .watchCitizenComplaints(citizenId)
        .listen(
          (list) {
            if (mounted) {
              setState(() {
                _allComplaints = List.from(list);
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            debugPrint('[MyComplaintsScreen] Real-time stream error: $e');
          },
        );
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final citizenId =
          _authService.currentUser?.id ?? _authService.currentUid ?? '';
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
      if (_filterCriteria.status != null &&
          complaint.status != _filterCriteria.status) {
        return false;
      }

      // 2. Category Filter
      if (_filterCriteria.category != null &&
          complaint.category.id != _filterCriteria.category!.id) {
        return false;
      }

      // 3. Search Query (Ticket ID, Title, Category, Location)
      if (query.isNotEmpty) {
        final matchesTicket = complaint.ticketNumber.toLowerCase().contains(
          query,
        );
        final matchesTitle = complaint.title.toLowerCase().contains(query);
        final matchesCategory = complaint.category.name.toLowerCase().contains(
          query,
        );
        final matchesAddress =
            complaint.location.fullDisplayAddress.toLowerCase().contains(
              query,
            ) ||
            complaint.location.shortDisplayAddress.toLowerCase().contains(
              query,
            ) ||
            (complaint.location.landmark?.toLowerCase().contains(query) ??
                false) ||
            (complaint.location.ward?.toLowerCase().contains(query) ?? false);

        if (!matchesTicket &&
            !matchesTitle &&
            !matchesCategory &&
            !matchesAddress) {
          return false;
        }
      }

      return true;
    }).toList()..sort((a, b) {
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
        _searchController.text.trim().isNotEmpty ||
        _filterCriteria.hasActiveFilters;

    return Scaffold(
      backgroundColor: CivicFixColors.background,
      floatingActionButton: const CivicChatbotFab(heroTag: 'complaints_assistant_fab'),
      appBar: CivicFixAppBar(
        title: context.l10nOrNull?.myComplaintsTitle ?? 'My Complaints',
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

  Widget _buildContent(
    List<ComplaintModel> filteredComplaints,
    bool isFiltered,
  ) {
    if (_isLoading) {
      return Center(
        child: LoadingState(
          message: context.l10nOrNull?.loadingComplaints ?? 'Loading your complaints...',
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: ErrorState(
            title: context.l10nOrNull?.somethingWentWrong ?? 'Something went wrong',
            message: _errorMessage == "Couldn't load your complaints."
                ? (context.l10nOrNull?.failedToLoadComplaints ?? _errorMessage!)
                : _errorMessage!,
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
            title: context.l10nOrNull?.noComplaintsYet ?? 'No complaints yet',
            description: context.l10nOrNull?.reportCivicIssueTrackProgress ??
                'Report a civic issue and track its progress here.',
            actionText: context.l10nOrNull?.reportAnIssue ?? 'Report an Issue',
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
                  context.l10nOrNull?.trackCivicIssuesReported ??
                      "Track the civic issues you've reported.",
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,

                // Search input field + Filter Button (matched height)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSearchField(),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      _buildFilterButton(),
                    ],
                  ),
                ),
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
                  title: context.l10nOrNull?.noComplaintsFound ?? 'No complaints found',
                  description: context.l10nOrNull?.tryChangingFiltersOrSearch ??
                      'Try a different search or filter.',
                  actionText: context.l10nOrNull?.clearFilters ?? 'Clear Filters',
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
              delegate: SliverChildBuilderDelegate((context, index) {
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
                    onUpvote:
                        _upvotesInFlight.contains(complaint.id) ||
                            _supportedComplaintIds.contains(complaint.id)
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final l10n = context.l10nOrNull;
                            final supportedText =
                                l10n?.supportedComplaintSuccess ??
                                'Supported complaint!';
                            final alreadySupportedText =
                                l10n?.alreadySupportedComplaint ??
                                'You already supported this complaint.';
                            final errorPrefix =
                                l10n?.somethingWentWrong ?? 'Failed to upvote';

                            setState(() => _upvotesInFlight.add(complaint.id));
                            try {
                              final result = await _repository.upvoteComplaint(
                                complaint.id,
                              );
                              if (!mounted) return;
                              setState(() {
                                _upvotesInFlight.remove(complaint.id);
                                _supportedComplaintIds.add(complaint.id);
                                final idx = _allComplaints.indexWhere(
                                  (c) => c.id == complaint.id,
                                );
                                if (idx != -1) {
                                  _allComplaints[idx] = _allComplaints[idx]
                                      .copyWith(upvotes: result.upvotes);
                                }
                              });
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.added
                                        ? supportedText
                                        : alreadySupportedText,
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(
                                () => _upvotesInFlight.remove(complaint.id),
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('$errorPrefix: $e'),
                                ),
                              );
                            }
                          },
                  ),
                );
              }, childCount: filteredComplaints.length),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Semantics(
      label: context.l10nOrNull?.searchComplaintsHint ??
          'Search complaints by ID, title, category, or location',
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText:
              context.l10nOrNull?.searchComplaintsHint ?? 'Search complaints...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: CivicFixColors.secondaryText,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  tooltip: context.l10nOrNull?.clearSearch ?? 'Clear search',
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
            borderSide: const BorderSide(
              color: CivicFixColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasActiveFilters = _filterCriteria.hasActiveFilters;

    return Semantics(
      button: true,
      label: context.l10nOrNull?.filter ?? 'Filter',
      child: OutlinedButton.icon(
        onPressed: _openFilterBottomSheet,
        icon: Badge(
          isLabelVisible: hasActiveFilters,
          smallSize: 8,
          backgroundColor: CivicFixColors.alertDark,
          child: const Icon(Icons.tune_rounded, size: 20),
        ),
        label: Text(
          _filterCriteria.category != null
              ? _filterCriteria.category!.name
              : (context.l10nOrNull?.filter ?? 'Filter'),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
          ),
          foregroundColor: hasActiveFilters
              ? CivicFixColors.primary
              : CivicFixColors.primaryText,
          side: BorderSide(
            color: hasActiveFilters
                ? CivicFixColors.primary
                : CivicFixColors.border,
            width: hasActiveFilters ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCount(int count, bool isFiltered) {
    final countText = isFiltered
        ? (context.l10nOrNull != null
            ? context.l10n.complaintsFound(count)
            : '$count ${count == 1 ? "complaint" : "complaints"} found')
        : (context.l10nOrNull != null
            ? context.l10n.complaintCount(count)
            : '$count ${count == 1 ? "complaint" : "complaints"}');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            countText,
            style: CivicFixTypography.captionMedium.copyWith(
              color: CivicFixColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isFiltered)
          InkWell(
            onTap: _clearFiltersAndSearch,
            child: Text(
              context.l10nOrNull?.clearAll ?? 'Clear all',
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
