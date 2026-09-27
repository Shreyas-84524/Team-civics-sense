import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_lead_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Top KPI grid for Ward Department Lead Operations Center.
/// Displays 8 strictly unit-scoped metrics:
/// 1. Unassigned Complaints
/// 2. Assigned Complaints
/// 3. In Progress
/// 4. Critical
/// 5. SLA At Risk
/// 6. SLA Breached
/// 7. Awaiting Verification
/// 8. Resolved Today
class DepartmentLeadKpiSection extends StatelessWidget {
  final DepartmentLeadKpiMetrics metrics;
  final bool isLoading;
  final ValueChanged<String>? onKpiTapped;

  const DepartmentLeadKpiSection({
    super.key,
    required this.metrics,
    this.isLoading = false,
    this.onKpiTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);
    final isTablet = GovtResponsive.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.analytics_outlined, color: GovtThemeTokens.primary, size: 18),
            ),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Text(
                'DEPARTMENT OPERATIONS KPI GRID',
                style: CivicFixTypography.h3.copyWith(
                  color: GovtThemeTokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (metrics.hasSlaData && !isMobile) ...[
              CivicFixSpacing.hSpaceSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (metrics.slaComplianceRate ?? 100) >= 90
                      ? GovtThemeTokens.success.withValues(alpha: 0.1)
                      : GovtThemeTokens.alert.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (metrics.slaComplianceRate ?? 100) >= 90
                        ? GovtThemeTokens.success.withValues(alpha: 0.3)
                        : GovtThemeTokens.alert.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (metrics.slaComplianceRate ?? 100) >= 90
                          ? Icons.check_circle_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: (metrics.slaComplianceRate ?? 100) >= 90
                          ? GovtThemeTokens.success
                          : GovtThemeTokens.alert,
                    ),
                    CivicFixSpacing.hSpaceXs,
                    Text(
                      'SLA: ${metrics.slaComplianceRate!.toStringAsFixed(1)}%',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: (metrics.slaComplianceRate ?? 100) >= 90
                            ? GovtThemeTokens.success
                            : GovtThemeTokens.alert,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        CivicFixSpacing.vSpaceMd,
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 4;
            if (isMobile) {
              crossAxisCount = 2;
            } else if (isTablet) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth < 1100) {
              crossAxisCount = 4;
            } else {
              crossAxisCount = 4;
            }

            final kpiCards = [
              _buildKpiCard(
                title: 'Unassigned',
                value: metrics.unassignedComplaints.toString(),
                subtitle: 'Needs Crew Dispatch',
                icon: Icons.assignment_late_outlined,
                color: const Color(0xFFF59E0B),
                kpiKey: 'unassigned',
              ),
              _buildKpiCard(
                title: 'Assigned',
                value: metrics.assignedComplaints.toString(),
                subtitle: 'Crew Mobilized',
                icon: Icons.assignment_ind_outlined,
                color: const Color(0xFF3B82F6),
                kpiKey: 'assigned',
              ),
              _buildKpiCard(
                title: 'In Progress',
                value: metrics.inProgressComplaints.toString(),
                subtitle: 'Active Field Work',
                icon: Icons.engineering_outlined,
                color: const Color(0xFF6366F1),
                kpiKey: 'in_progress',
              ),
              _buildKpiCard(
                title: 'Critical',
                value: metrics.criticalComplaints.toString(),
                subtitle: 'Emergency Grievances',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEF4444),
                kpiKey: 'critical',
              ),
              _buildKpiCard(
                title: 'SLA At Risk',
                value: metrics.slaAtRiskComplaints.toString(),
                subtitle: '< 12h Remaining',
                icon: Icons.timer_outlined,
                color: const Color(0xFFF97316),
                kpiKey: 'sla_at_risk',
              ),
              _buildKpiCard(
                title: 'SLA Breached',
                value: metrics.slaBreachedComplaints.toString(),
                subtitle: '> 48h Overdue',
                icon: Icons.alarm_off_rounded,
                color: const Color(0xFFDC2626),
                kpiKey: 'sla_breached',
              ),
              _buildKpiCard(
                title: 'Awaiting Verification',
                value: metrics.awaitingVerificationComplaints.toString(),
                subtitle: 'Ready for Review',
                icon: Icons.fact_check_outlined,
                color: const Color(0xFF8B5CF6),
                kpiKey: 'awaiting_verification',
              ),
              _buildKpiCard(
                title: 'Resolved Today',
                value: metrics.resolvedTodayComplaints.toString(),
                subtitle: 'Successfully Closed',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF10B981),
                kpiKey: 'resolved_today',
              ),
            ];

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: CivicFixSpacing.sm,
              crossAxisSpacing: CivicFixSpacing.sm,
              childAspectRatio: isMobile ? 1.35 : (isTablet ? 1.25 : 1.55),
              children: kpiCards,
            );
          },
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String kpiKey,
  }) {
    return InkWell(
      onTap: onKpiTapped != null ? () => onKpiTapped!(kpiKey) : null,
      borderRadius: GovtThemeTokens.cardRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.sm,
          vertical: CivicFixSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: GovtThemeTokens.border),
          boxShadow: GovtThemeTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Text(
                  value,
                  style: CivicFixTypography.h2.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
