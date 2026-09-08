import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/offline_cache_banner.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_data_table.dart';
import '../../widgets/dashboard/attention_required_card.dart';
import '../../widgets/dashboard/category_breakdown_widget.dart';
import '../../widgets/dashboard/dashboard_card.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/status_distribution_widget.dart';
import '../../widgets/map/govt_map_panel.dart';

/// Government Executive Operations Dashboard.
///
/// Gives municipal nodal officers an immediate operational overview of civic complaints:
/// - 6 Key Performance Indicator (KPI) metrics
/// - Attention Required priority list
/// - Lifecycle status overview & proportion bar
/// - Municipal category breakdown (9 categories)
/// - Recent complaints datatable with quick actions
/// - Hazard map preview & quick workflow shortcuts
class GovtDashboardScreen extends StatefulWidget {
  final GovtComplaintRepository? repository;
  final ConnectivityService? connectivityService;
  final VoidCallback? onNavigateToComplaints;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToAnalytics;

  const GovtDashboardScreen({
    super.key,
    this.repository,
    this.connectivityService,
    this.onNavigateToComplaints,
    this.onNavigateToMap,
    this.onNavigateToAnalytics,
  });

  @override
  State<GovtDashboardScreen> createState() => _GovtDashboardScreenState();
}

class _GovtDashboardScreenState extends State<GovtDashboardScreen> {
  late final GovtComplaintRepository _repository;
  late final ConnectivityService _connectivityService;
  GovtDashboardMetrics? _metrics;
  List<CategoryDistributionItem> _categoryDistribution = [];
  List<StatusDistributionItem> _statusDistribution = [];
  List<ComplaintModel> _attentionComplaints = [];
  List<ComplaintModel> _recentComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockGovtComplaintRepository();
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getDashboardMetrics(),
        _repository.getCategoryDistribution(),
        _repository.getStatusDistribution(),
        _repository.getAttentionRequiredComplaints(limit: 5),
        _repository.getComplaints(),
      ]);

      if (mounted) {
        setState(() {
          _metrics = results[0] as GovtDashboardMetrics;
          _categoryDistribution = results[1] as List<CategoryDistributionItem>;
          _statusDistribution = results[2] as List<StatusDistributionItem>;
          _attentionComplaints = results[3] as List<ComplaintModel>;
          final allComplaints = results[4] as List<ComplaintModel>;
          _recentComplaints = allComplaints.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dashboard metrics: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetails(ComplaintModel complaint) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtComplaintDetails,
      arguments: complaint,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Material(
      color: GovtThemeTokens.background,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: GovtThemeTokens.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_connectivityService.isOnline)
                OfflineCacheBanner(
                  customMessage: 'Offline — Showing cached municipal operational data. Real-time updates paused.',
                  onRefresh: _loadDashboardData,
                ),
              // Section 1: Dashboard Header & Overview Title
              _buildDashboardHeader(),
              CivicFixSpacing.vSpaceLg,

              // Section 2: 6 KPI Metric Cards Grid
              _buildKpiMetricsGrid(),
              CivicFixSpacing.vSpaceXl,

              // Section 3: Attention Required & Distribution Highlights
              _buildOperationalHighlightsSection(),
              CivicFixSpacing.vSpaceXl,

              // Section 4: Recent Complaints Data Table
              _buildRecentComplaintsSection(),
              CivicFixSpacing.vSpaceXl,

              // Section 5: Hazard Map Preview & Quick Actions Row
              _buildHazardMapAndQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(CivicFixSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
            ),
            CivicFixSpacing.vSpaceMd,
            Text(
              'Aggregating municipal telemetry...',
              style: TextStyle(
                color: GovtThemeTokens.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(CivicFixSpacing.xl),
        margin: const EdgeInsets.all(CivicFixSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: GovtThemeTokens.error,
            ),
            CivicFixSpacing.vSpaceMd,
            Text(
              'Unable to Load Dashboard',
              style: CivicFixTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textPrimary,
              ),
            ),
            CivicFixSpacing.vSpaceSm,
            Text(
              _errorMessage ?? 'An unexpected error occurred while loading data.',
              textAlign: TextAlign.center,
              style: CivicFixTypography.bodySmall.copyWith(
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            CivicFixSpacing.vSpaceLg,
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GovtThemeTokens.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Municipal Operations Overview',
                    style: (isMobile ? CivicFixTypography.h3 : CivicFixTypography.h2).copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time grievance telemetry & nodal department workload',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh Dashboard',
              onPressed: _loadDashboardData,
              icon: const Icon(
                Icons.refresh_rounded,
                color: GovtThemeTokens.textSecondary,
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 6;
        double childAspectRatio = 1.35;

        if (width < 640) {
          crossAxisCount = 2;
          childAspectRatio = 1.15;
        } else if (width < 960) {
          crossAxisCount = 3;
          childAspectRatio = 1.35;
        } else if (width < 1200) {
          crossAxisCount = 3;
          childAspectRatio = 1.5;
        }

        final cards = [
          StatCard(
            title: 'Total Grievances',
            value: '${_metrics?.totalComplaints ?? 0}',
            icon: Icons.folder_open_rounded,
            accentColor: GovtThemeTokens.textPrimary,
            trendText: 'All time',
            subtitle: 'Logged complaints',
            onTap: widget.onNavigateToComplaints,
          ),
          StatCard(
            title: 'Reported / New',
            value: '${_metrics?.reportedCount ?? 0}',
            icon: Icons.assignment_outlined,
            accentColor: GovtThemeTokens.primary,
            trendText: 'Unassigned',
            subtitle: 'Awaiting triage',
            onTap: widget.onNavigateToComplaints,
          ),
          StatCard(
            title: 'Verified',
            value: '${_metrics?.verifiedCount ?? 0}',
            icon: Icons.verified_outlined,
            accentColor: GovtThemeTokens.info,
            trendText: 'Inspected',
            subtitle: 'Field inspection done',
            onTap: widget.onNavigateToComplaints,
          ),
          StatCard(
            title: 'Assigned',
            value: '${_metrics?.assignedCount ?? 0}',
            icon: Icons.person_add_alt_1_outlined,
            accentColor: GovtThemeTokens.secondary,
            trendText: 'Allocated',
            subtitle: 'Department crew set',
            onTap: widget.onNavigateToComplaints,
          ),
          StatCard(
            title: 'In Progress',
            value: '${_metrics?.inProgressCount ?? 0}',
            icon: Icons.engineering_rounded,
            accentColor: GovtThemeTokens.alert,
            trendText: 'Active',
            subtitle: 'Work underway',
            onTap: widget.onNavigateToComplaints,
          ),
          StatCard(
            title: 'Resolved',
            value: '${_metrics?.resolvedCount ?? 0}',
            icon: Icons.check_circle_outline_rounded,
            accentColor: GovtThemeTokens.secondary,
            trendText: 'Completed',
            subtitle: 'Closed & verified',
            onTap: widget.onNavigateToComplaints,
          ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: CivicFixSpacing.md,
          mainAxisSpacing: CivicFixSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: cards,
        );
      },
    );
  }

  Widget _buildOperationalHighlightsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: AttentionRequiredCard(
                  complaints: _attentionComplaints,
                  onInspect: _navigateToDetails,
                  onViewAll: widget.onNavigateToComplaints,
                ),
              ),
              CivicFixSpacing.hSpaceLg,
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    StatusDistributionWidget(
                      items: _statusDistribution,
                      onStatusSelected: (_) => widget.onNavigateToComplaints?.call(),
                    ),
                    CivicFixSpacing.vSpaceLg,
                    CategoryBreakdownWidget(
                      items: _categoryDistribution,
                      onCategorySelected: (_) => widget.onNavigateToComplaints?.call(),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            AttentionRequiredCard(
              complaints: _attentionComplaints,
              onInspect: _navigateToDetails,
              onViewAll: widget.onNavigateToComplaints,
            ),
            CivicFixSpacing.vSpaceLg,
            StatusDistributionWidget(
              items: _statusDistribution,
              onStatusSelected: (_) => widget.onNavigateToComplaints?.call(),
            ),
            CivicFixSpacing.vSpaceLg,
            CategoryBreakdownWidget(
              items: _categoryDistribution,
              onCategorySelected: (_) => widget.onNavigateToComplaints?.call(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentComplaintsSection() {
    final columns = [
      const GovtDataColumn(label: 'Ticket #', width: 130),
      const GovtDataColumn(label: 'Issue & Category', width: 220),
      const GovtDataColumn(label: 'Location / Ward', width: 180),
      const GovtDataColumn(label: 'Priority', width: 120),
      const GovtDataColumn(label: 'Status', width: 140),
      const GovtDataColumn(label: 'Reported', width: 110),
      const GovtDataColumn(label: 'Action', width: 90),
    ];

    final rows = _recentComplaints.map((c) {
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
          '${c.location.address}\n${c.location.ward ?? "Central"}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.caption,
        ),
        PriorityBadge(priority: c.priority, isCompact: true),
        StatusBadge(status: c.status, isCompact: true),
        Text(
          DateFormatter.formatRelative(c.createdAt),
          style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _navigateToDetails(c),
          child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ];
    }).toList();

    return GovtDataTable(
      title: 'Recent Civic Grievances',
      headerAction: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: widget.onNavigateToComplaints,
        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
        label: const Text('View All Complaints', style: TextStyle(fontSize: 12)),
      ),
      columns: columns,
      rows: rows,
      isLoading: _isLoading,
      totalCount: _recentComplaints.length,
      currentPage: 1,
    );
  }

  Widget _buildHazardMapAndQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: GovtMapPanel(
                  activeHazardsCount: _metrics?.criticalHazardsCount ?? 4,
                  onOpenFullMap: widget.onNavigateToMap,
                ),
              ),
              CivicFixSpacing.hSpaceLg,
              Expanded(
                flex: 2,
                child: _buildQuickActionsPanel(),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              GovtMapPanel(
                activeHazardsCount: _metrics?.criticalHazardsCount ?? 4,
                onOpenFullMap: widget.onNavigateToMap,
              ),
              CivicFixSpacing.vSpaceLg,
              _buildQuickActionsPanel(),
            ],
          );
        }
      },
    );
  }

  Widget _buildQuickActionsPanel() {
    return DashboardCard(
      title: 'Quick Operations',
      subtitle: 'Frequent nodal administrative workflows',
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.assignment_outlined,
            title: 'Manage Grievances',
            subtitle: 'Assign, verify, and update tickets',
            color: GovtThemeTokens.primary,
            onTap: widget.onNavigateToComplaints,
          ),
          CivicFixSpacing.vSpaceSm,
          _buildActionTile(
            icon: Icons.map_outlined,
            title: 'Live Hazard Map',
            subtitle: 'Inspect emergency geographic hazards',
            color: GovtThemeTokens.info,
            onTap: widget.onNavigateToMap,
          ),
          CivicFixSpacing.vSpaceSm,
          _buildActionTile(
            icon: Icons.bar_chart_rounded,
            title: 'Resolution Analytics',
            subtitle: 'View SLA compliance & departmental stats',
            color: GovtThemeTokens.secondary,
            onTap: widget.onNavigateToAnalytics,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(CivicFixSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: GovtThemeTokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

