import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/government_kpi_card.dart';

/// Top-level KPI metric grid for Assistant Commissioner / Ward Officer Command Center.
class WardKpiSection extends StatelessWidget {
  final WardKpiMetrics? metrics;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenComplaintsTap;
  final VoidCallback? onCriticalComplaintsTap;
  final VoidCallback? onSlaBreachedTap;
  final VoidCallback? onRoutingRequestsTap;
  final VoidCallback? onEscalationsTap;

  const WardKpiSection({
    super.key,
    this.metrics,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onOpenComplaintsTap,
    this.onCriticalComplaintsTap,
    this.onSlaBreachedTap,
    this.onRoutingRequestsTap,
    this.onEscalationsTap,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Text(
                errorMessage!,
                style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.error),
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    final m = metrics;

    final cards = [
      // 1. Open Complaints
      GovernmentKpiCard(
        title: 'Open Complaints',
        metric: isLoading ? '...' : '${m?.openComplaints ?? 0}',
        icon: Icons.pending_actions_rounded,
        iconColor: GovtThemeTokens.primary,
        supportingText: 'Across all 18 departments',
        onTap: onOpenComplaintsTap,
      ),

      // 2. Critical Complaints
      GovernmentKpiCard(
        title: 'Critical Complaints',
        metric: isLoading ? '...' : '${m?.criticalComplaints ?? 0}',
        icon: Icons.emergency_rounded,
        iconColor: (m?.criticalComplaints ?? 0) > 0 ? GovtThemeTokens.error : GovtThemeTokens.success,
        supportingText: (m?.criticalComplaints ?? 0) > 0 ? 'High & Emergency priority' : 'Zero active emergencies',
        onTap: onCriticalComplaintsTap,
      ),

      // 3. Resolved Today
      GovernmentKpiCard(
        title: 'Resolved Today',
        metric: isLoading ? '...' : '${m?.resolvedToday ?? 0}',
        icon: Icons.task_alt_rounded,
        iconColor: GovtThemeTokens.success,
        supportingText: '${m?.resolvedTotal ?? 0} total resolved in ward',
      ),

      // 4. SLA Compliance
      GovernmentKpiCard(
        title: 'SLA Compliance',
        metric: isLoading
            ? '...'
            : (m?.slaComplianceRate != null ? '${m!.slaComplianceRate!.toStringAsFixed(1)}%' : 'N/A'),
        icon: Icons.verified_user_outlined,
        iconColor: (m?.slaComplianceRate ?? 100) >= 85
            ? GovtThemeTokens.success
            : ((m?.slaComplianceRate ?? 100) >= 70 ? GovtThemeTokens.warning : GovtThemeTokens.error),
        supportingText: 'Statutory 48h SLA Target',
      ),

      // 5. SLA Breached
      GovernmentKpiCard(
        title: 'SLA Breached',
        metric: isLoading ? '...' : '${m?.slaBreachedCount ?? 0}',
        icon: Icons.timer_off_outlined,
        iconColor: (m?.slaBreachedCount ?? 0) > 0 ? GovtThemeTokens.error : GovtThemeTokens.success,
        supportingText: (m?.slaBreachedCount ?? 0) > 0 ? 'Overdue beyond 48 hours' : 'Zero overdue items',
        onTap: onSlaBreachedTap,
      ),

      // 6. Pending Routing Requests
      GovernmentKpiCard(
        title: 'Pending Routing Requests',
        metric: isLoading ? '...' : '${m?.pendingRoutingRequests ?? 0}',
        icon: Icons.alt_route_rounded,
        iconColor: (m?.pendingRoutingRequests ?? 0) > 0 ? GovtThemeTokens.info : GovtThemeTokens.textMuted,
        supportingText: 'Reassignment tickets pending',
        onTap: onRoutingRequestsTap,
      ),

      // 7. Active Escalations
      GovernmentKpiCard(
        title: 'Active Escalations',
        metric: isLoading ? '...' : '${m?.activeEscalationsCount ?? 0}',
        icon: Icons.warning_amber_rounded,
        iconColor: (m?.activeEscalationsCount ?? 0) > 0 ? GovtThemeTokens.warning : GovtThemeTokens.textMuted,
        supportingText: 'Level 1 & Level 2 escalations',
        onTap: onEscalationsTap,
      ),

      // 8. Average Resolution Time
      GovernmentKpiCard(
        title: 'Avg Resolution Time',
        metric: isLoading
            ? '...'
            : (m?.avgResolutionHours != null ? '${m!.avgResolutionHours!.toStringAsFixed(1)} hrs' : 'N/A'),
        icon: Icons.hourglass_bottom_rounded,
        iconColor: GovtThemeTokens.secondary,
        supportingText: 'Ward-level resolution average',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, color: GovtThemeTokens.primary, size: 20),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Text(
                'WARD KEY PERFORMANCE INDICATORS',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceMd,
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int count = 4;
            if (width >= 1280) {
              count = 4;
            } else if (width >= 900) {
              count = 3;
            } else if (width >= 600) {
              count = 2;
            } else {
              count = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: CivicFixSpacing.md,
                mainAxisSpacing: CivicFixSpacing.md,
                mainAxisExtent: 140,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
            );
          },
        ),
      ],
    );
  }
}
