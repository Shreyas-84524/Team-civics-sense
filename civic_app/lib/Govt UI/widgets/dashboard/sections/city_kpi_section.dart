import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../services/government_city_dashboard_service.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../common/government_kpi_card.dart';

/// Citywide Top KPI Metrics Section for Municipal Commissioner Command Center.
class CityKpiSection extends StatelessWidget {
  final CitywideKpiMetrics? metrics;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenComplaintsTap;
  final VoidCallback? onCriticalComplaintsTap;
  final VoidCallback? onTotalWardsTap;
  final VoidCallback? onSlaBreachedTap;
  final VoidCallback? onRoutingRequestsTap;
  final VoidCallback? onPersonnelTap;

  const CityKpiSection({
    super.key,
    this.metrics,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onOpenComplaintsTap,
    this.onCriticalComplaintsTap,
    this.onTotalWardsTap,
    this.onSlaBreachedTap,
    this.onRoutingRequestsTap,
    this.onPersonnelTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildGrid(
        context,
        List.generate(
          7,
          (index) => const GovernmentKpiCard(
            title: 'Loading metric...',
            metric: '—',
            icon: Icons.hourglass_top_rounded,
            isLoading: true,
          ),
        ),
      );
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: GovtThemeTokens.errorLight),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 28),
              CivicFixSpacing.vSpaceSm,
              Text(
                'Unable to calculate Citywide KPIs',
                style: TextStyle(fontWeight: FontWeight.w700, color: GovtThemeTokens.textPrimary),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 12, color: GovtThemeTokens.textSecondary),
              ),
              if (onRetry != null) ...[
                CivicFixSpacing.vSpaceMd,
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry KPIs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final m = metrics ??
        const CitywideKpiMetrics(
          totalComplaints: 0,
          openComplaints: 0,
          criticalComplaints: 0,
          resolvedToday: 0,
          resolvedTotal: 0,
          slaBreachedCount: 0,
          pendingRoutingRequests: 0,
          activePersonnelCount: 2642,
          totalWards: 24,
        );

    final avgTimeText = m.avgResolutionHours != null
        ? '${m.avgResolutionHours!.toStringAsFixed(1)} hrs'
        : 'Unavailable';

    final cards = [
      GovernmentKpiCard(
        title: 'Open Complaints',
        metric: '${m.openComplaints}',
        icon: Icons.assignment_outlined,
        iconColor: GovtThemeTokens.primary,
        iconBackgroundColor: GovtThemeTokens.primary.withValues(alpha: 0.1),
        supportingText: 'Active citywide backlog',
        onTap: onOpenComplaintsTap,
      ),
      GovernmentKpiCard(
        title: 'Critical Complaints',
        metric: '${m.criticalComplaints}',
        icon: Icons.warning_amber_rounded,
        iconColor: GovtThemeTokens.critical,
        iconBackgroundColor: GovtThemeTokens.critical.withValues(alpha: 0.12),
        status: m.criticalComplaints > 0 ? 'Urgent Action' : 'Stable',
        statusColor: m.criticalComplaints > 0 ? GovtThemeTokens.critical : GovtThemeTokens.success,
        onTap: onCriticalComplaintsTap,
      ),
      GovernmentKpiCard(
        title: 'Resolved Today',
        metric: '${m.resolvedToday}',
        icon: Icons.task_alt_rounded,
        iconColor: GovtThemeTokens.secondary,
        iconBackgroundColor: GovtThemeTokens.secondary.withValues(alpha: 0.1),
        supportingText: 'Cumulative resolved: ${m.resolvedTotal}',
      ),
      GovernmentKpiCard(
        title: 'Total Wards',
        metric: '${m.totalWards}',
        icon: Icons.location_city_rounded,
        iconColor: GovtThemeTokens.primary,
        iconBackgroundColor: GovtThemeTokens.primary.withValues(alpha: 0.1),
        supportingText: 'All Administrative Wards',
        onTap: onTotalWardsTap,
      ),
      GovernmentKpiCard(
        title: 'Pending Routing Requests',
        metric: '${m.pendingRoutingRequests}',
        icon: Icons.swap_horiz_rounded,
        iconColor: const Color(0xFFD97706),
        iconBackgroundColor: const Color(0xFFFEF8EC),
        supportingText: 'Cross-department transfers',
        onTap: onRoutingRequestsTap,
      ),
      GovernmentKpiCard(
        title: 'Active Personnel',
        metric: '${m.activePersonnelCount}',
        icon: Icons.badge_outlined,
        iconColor: GovtThemeTokens.primary,
        iconBackgroundColor: GovtThemeTokens.primary.withValues(alpha: 0.08),
        supportingText: '432 Ward-Dept Units',
        onTap: onPersonnelTap,
      ),
      GovernmentKpiCard(
        title: 'Avg Resolution Time',
        metric: avgTimeText,
        icon: Icons.hourglass_bottom_rounded,
        iconColor: GovtThemeTokens.info,
        iconBackgroundColor: GovtThemeTokens.info.withValues(alpha: 0.1),
        supportingText: 'Statutory 48h SLA Target',
      ),
    ];

    return _buildGrid(context, cards);
  }

  Widget _buildGrid(BuildContext context, List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 4;
        if (width >= 1280) {
          crossAxisCount = 4;
        } else if (width >= 900) {
          crossAxisCount = 3;
        } else if (width >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: CivicFixSpacing.md,
            mainAxisSpacing: CivicFixSpacing.md,
            mainAxisExtent: 140,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}
