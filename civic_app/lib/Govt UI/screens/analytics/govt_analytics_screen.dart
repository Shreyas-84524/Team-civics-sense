import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../models/analytics_model.dart';
import '../../services/analytics_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/analytics/govt_analytics_card.dart';
import '../../widgets/analytics/govt_analytics_filter_bar.dart';
import '../../widgets/analytics/govt_department_analytics_table.dart';
import '../../widgets/analytics/govt_resolution_performance_widget.dart';
import '../../widgets/analytics/govt_time_trend_chart.dart';
import '../../widgets/dashboard/stat_card.dart';

/// Operational & SLA Compliance Analytics Screen for Government Administrators.
class GovtAnalyticsScreen extends StatefulWidget {
  final AnalyticsRepository? repository;

  const GovtAnalyticsScreen({
    super.key,
    this.repository,
  });

  @override
  State<GovtAnalyticsScreen> createState() => _GovtAnalyticsScreenState();
}

class _GovtAnalyticsScreenState extends State<GovtAnalyticsScreen> {
  late final AnalyticsRepository _repository;

  AnalyticsData? _data;
  bool _isLoading = true;
  String? _errorMessage;
  AnalyticsFilter _activeFilter = const AnalyticsFilter();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockAnalyticsRepository();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getAnalytics(filter: _activeFilter);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load municipal analytics data. Please retry.';
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(AnalyticsFilter filter) {
    setState(() {
      _activeFilter = filter;
    });
    _loadAnalytics();
  }

  void _onResetFilters() {
    setState(() {
      _activeFilter = const AnalyticsFilter();
    });
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GovtThemeTokens.background,
      child: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: GovtThemeTokens.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Multi-Criteria Filter Bar
              GovtAnalyticsFilterBar(
                activeFilter: _activeFilter,
                totalCount: _data?.summary.totalComplaints ?? 0,
                onFilterChanged: _onFilterChanged,
                onResetFilters: _onResetFilters,
              ),
              CivicFixSpacing.vSpaceLg,

              // Section 2: Main Body State Handler
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_data != null)
                _buildAnalyticsContent(_data!)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
          ),
          CivicFixSpacing.vSpaceMd,
          Text(
            'Aggregating municipal analytics & operational metrics...',
            style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 40),
          CivicFixSpacing.vSpaceMd,
          Text(_errorMessage!, style: CivicFixTypography.bodySmall),
          CivicFixSpacing.vSpaceMd,
          ElevatedButton.icon(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovtThemeTokens.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(AnalyticsData data) {
    final summary = data.summary;

    if (summary.totalComplaints == 0) {
      return Container(
        padding: const EdgeInsets.all(CivicFixSpacing.xxl),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.lg),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF3F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined, size: 48, color: GovtThemeTokens.textSecondary),
            ),
            CivicFixSpacing.vSpaceMd,
            Text(
              'No complaints match the selected filter criteria',
              style: CivicFixTypography.h3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textPrimary,
              ),
            ),
            CivicFixSpacing.vSpaceSm,
            Text(
              'Try changing your time range, department, category, or status filters to view metrics.',
              style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            CivicFixSpacing.vSpaceLg,
            ElevatedButton.icon(
              onPressed: _onResetFilters,
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GovtThemeTokens.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 7 KPI Stat Cards Grid
        _buildKpiMetricsGrid(summary),
        CivicFixSpacing.vSpaceXl,

        // 2. Operational Performance & Time Trend Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: GovtTimeTrendChart(
                      points: data.timeTrends,
                      dateRange: _activeFilter.dateRange,
                    ),
                  ),
                  CivicFixSpacing.hSpaceLg,
                  Expanded(
                    flex: 2,
                    child: GovtResolutionPerformanceWidget(summary: summary),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  GovtTimeTrendChart(
                    points: data.timeTrends,
                    dateRange: _activeFilter.dateRange,
                  ),
                  CivicFixSpacing.vSpaceLg,
                  GovtResolutionPerformanceWidget(summary: summary),
                ],
              );
            }
          },
        ),
        CivicFixSpacing.vSpaceXl,

        // 3. Category & Status Distribution Breakdown Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            final categoryItems = data.categoryBreakdowns.map((cat) {
              return AnalyticsBreakdownItem(
                label: cat.category.name,
                count: cat.count,
                percentage: cat.percentage,
                color: cat.color,
              );
            }).toList();

            final statusItems = data.statusBreakdowns.map((st) {
              return AnalyticsBreakdownItem(
                label: st.status.label,
                count: st.count,
                percentage: st.percentage,
                color: st.color,
              );
            }).toList();

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GovtAnalyticsCard(
                      title: 'Workload by Civic Category',
                      subtitle: 'Distribution of complaints across 9 municipal categories',
                      primaryMetric: '${summary.totalComplaints}',
                      primaryMetricLabel: 'Grievances in scope',
                      items: categoryItems,
                    ),
                  ),
                  CivicFixSpacing.hSpaceLg,
                  Expanded(
                    child: GovtAnalyticsCard(
                      title: 'Lifecycle Status Distribution',
                      subtitle: 'Progress breakdown across 5 canonical stages',
                      primaryMetric: summary.formattedResolutionPercentage,
                      primaryMetricLabel: 'Resolution index',
                      items: statusItems,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  GovtAnalyticsCard(
                    title: 'Workload by Civic Category',
                    subtitle: 'Distribution of complaints across 9 municipal categories',
                    primaryMetric: '${summary.totalComplaints}',
                    primaryMetricLabel: 'Grievances in scope',
                    items: categoryItems,
                  ),
                  CivicFixSpacing.vSpaceLg,
                  GovtAnalyticsCard(
                    title: 'Lifecycle Status Distribution',
                    subtitle: 'Progress breakdown across 5 canonical stages',
                    primaryMetric: summary.formattedResolutionPercentage,
                    primaryMetricLabel: 'Resolution index',
                    items: statusItems,
                  ),
                ],
              );
            }
          },
        ),
        CivicFixSpacing.vSpaceXl,

        // 4. Department Performance & Workload Table
        GovtDepartmentAnalyticsTable(departments: data.departmentBreakdowns),
      ],
    );
  }

  Widget _buildKpiMetricsGrid(AnalyticsSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int cols = 4;
        if (width < 600) {
          cols = 1;
        } else if (width < 960) {
          cols = 2;
        } else if (width < 1280) {
          cols = 3;
        }

        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: CivicFixSpacing.md,
          mainAxisSpacing: CivicFixSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: width < 600 ? 2.8 : 2.2,
          children: [
            StatCard(
              title: 'Total Complaints',
              value: '${summary.totalComplaints}',
              icon: Icons.assessment_outlined,
              accentColor: GovtThemeTokens.primary,
              subtitle: 'Filtered grievance volume',
            ),
            StatCard(
              title: 'Resolved Complaints',
              value: '${summary.resolvedComplaints}',
              icon: Icons.check_circle_outline_rounded,
              accentColor: GovtThemeTokens.secondary,
              subtitle: '${summary.formattedResolutionPercentage} resolution index',
            ),
            StatCard(
              title: 'Pending Triage',
              value: '${summary.pendingComplaints}',
              icon: Icons.pending_actions_rounded,
              accentColor: GovtThemeTokens.alert,
              subtitle: 'Reported & verified stage',
            ),
            StatCard(
              title: 'In Progress',
              value: '${summary.inProgressComplaints}',
              icon: Icons.build_circle_outlined,
              accentColor: GovtThemeTokens.info,
              subtitle: 'Active field operations',
            ),
            StatCard(
              title: 'Avg Resolution Time',
              value: summary.formattedAvgResolutionTime,
              icon: Icons.timer_outlined,
              accentColor: GovtThemeTokens.primary,
              subtitle: 'Municipal target: 48.0 hrs',
            ),
            StatCard(
              title: 'High-Priority Tickets',
              value: '${summary.highPriorityComplaints}',
              icon: Icons.priority_high_rounded,
              accentColor: GovtThemeTokens.error,
              subtitle: 'Critical & high severity',
            ),
            StatCard(
              title: 'Unassigned Queue',
              value: '${summary.unassignedComplaints}',
              icon: Icons.assignment_late_outlined,
              accentColor: GovtThemeTokens.accent,
              subtitle: 'Awaiting squad dispatch',
            ),
          ],
        );
      },
    );
  }
}
