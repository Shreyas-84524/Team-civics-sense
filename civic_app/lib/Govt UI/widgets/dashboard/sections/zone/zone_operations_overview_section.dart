import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Zonal operations overview pipeline card displaying active grievance stages.
class ZoneOperationsOverviewSection extends StatelessWidget {
  final ZoneOperationsOverviewData? data;
  final bool isLoading;

  const ZoneOperationsOverviewSection({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = data;
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL OPERATIONS OVERVIEW',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Active grievance workflow pipeline across all zone wards',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${isLoading ? '...' : (d?.totalActiveComplaints ?? 0)} Active in Zone',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          // Responsive Metrics Funnel
          if (isMobile)
            Column(
              children: [
                _buildMetricRow(
                  label: 'Created Today',
                  value: d?.createdTodayCount ?? 0,
                  icon: Icons.add_circle_outline_rounded,
                  color: GovtThemeTokens.info,
                ),
                _buildMetricRow(
                  label: 'Assigned to Crew',
                  value: d?.assignedCount ?? 0,
                  icon: Icons.assignment_ind_outlined,
                  color: GovtThemeTokens.primary,
                ),
                _buildMetricRow(
                  label: 'In Progress Work',
                  value: d?.inProgressCount ?? 0,
                  icon: Icons.engineering_outlined,
                  color: const Color(0xFF0D9488),
                ),
                _buildMetricRow(
                  label: 'Awaiting Verification',
                  value: d?.awaitingVerificationCount ?? 0,
                  icon: Icons.fact_check_outlined,
                  color: GovtThemeTokens.warning,
                ),
                _buildMetricRow(
                  label: 'Resolved Today',
                  value: d?.resolvedTodayCount ?? 0,
                  icon: Icons.check_circle_outline_rounded,
                  color: GovtThemeTokens.success,
                ),
                _buildMetricRow(
                  label: 'Critical Unresolved',
                  value: d?.criticalUnresolvedCount ?? 0,
                  icon: Icons.warning_rounded,
                  color: GovtThemeTokens.error,
                ),
                _buildMetricRow(
                  label: 'SLA Breaches',
                  value: d?.slaBreachesCount ?? 0,
                  icon: Icons.timer_off_outlined,
                  color: GovtThemeTokens.error,
                ),
                _buildMetricRow(
                  label: 'Pending Routing',
                  value: d?.pendingRoutingTicketsCount ?? 0,
                  icon: Icons.alt_route_rounded,
                  color: GovtThemeTokens.info,
                ),
              ],
            )
          else
            Wrap(
              spacing: CivicFixSpacing.md,
              runSpacing: CivicFixSpacing.md,
              children: [
                _buildMetricChip(
                  label: 'Created Today',
                  value: d?.createdTodayCount ?? 0,
                  icon: Icons.add_circle_outline_rounded,
                  color: GovtThemeTokens.info,
                ),
                _buildMetricChip(
                  label: 'Assigned to Crew',
                  value: d?.assignedCount ?? 0,
                  icon: Icons.assignment_ind_outlined,
                  color: GovtThemeTokens.primary,
                ),
                _buildMetricChip(
                  label: 'In Progress',
                  value: d?.inProgressCount ?? 0,
                  icon: Icons.engineering_outlined,
                  color: const Color(0xFF0D9488),
                ),
                _buildMetricChip(
                  label: 'Awaiting Verification',
                  value: d?.awaitingVerificationCount ?? 0,
                  icon: Icons.fact_check_outlined,
                  color: GovtThemeTokens.warning,
                ),
                _buildMetricChip(
                  label: 'Resolved Today',
                  value: d?.resolvedTodayCount ?? 0,
                  icon: Icons.check_circle_outline_rounded,
                  color: GovtThemeTokens.success,
                ),
                _buildMetricChip(
                  label: 'Critical Unresolved',
                  value: d?.criticalUnresolvedCount ?? 0,
                  icon: Icons.warning_rounded,
                  color: GovtThemeTokens.error,
                ),
                _buildMetricChip(
                  label: 'SLA Breaches',
                  value: d?.slaBreachesCount ?? 0,
                  icon: Icons.timer_off_outlined,
                  color: GovtThemeTokens.error,
                ),
                _buildMetricChip(
                  label: 'Pending Routing',
                  value: d?.pendingRoutingTicketsCount ?? 0,
                  icon: Icons.alt_route_rounded,
                  color: GovtThemeTokens.info,
                ),
                _buildMetricChip(
                  label: 'Active Escalations',
                  value: d?.pendingEscalationsCount ?? 0,
                  icon: Icons.trending_up_rounded,
                  color: GovtThemeTokens.warning,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Text(
              label,
              style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textSecondary),
            ),
          ),
          Text(
            isLoading ? '...' : '$value',
            style: CivicFixTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
                Text(
                  isLoading ? '...' : '$value',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
