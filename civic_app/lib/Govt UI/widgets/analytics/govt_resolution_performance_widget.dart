import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../models/analytics_model.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Resolution performance and municipal SLA compliance indicator card.
class GovtResolutionPerformanceWidget extends StatelessWidget {
  final AnalyticsSummary summary;

  const GovtResolutionPerformanceWidget({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Resolution SLA & Performance',
      subtitle: 'Operational efficiency and resolution velocity indicators',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Progress Meter & Core Rate
          Row(
            children: [
              // Radial / Circular SLA Indicator
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: summary.resolutionRate.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFE5ECE8),
                      valueColor: const AlwaysStoppedAnimation<Color>(GovtThemeTokens.secondary),
                    ),
                    Center(
                      child: Text(
                        summary.formattedResolutionPercentage,
                        style: CivicFixTypography.bodyLargeMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: GovtThemeTokens.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.hSpaceLg,

              // Rate Summary Metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resolution Index',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${summary.resolvedComplaints} of ${summary.totalComplaints} Resolved',
                      style: CivicFixTypography.h3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primary,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      '${(summary.slaComplianceRate * 100).toStringAsFixed(1)}% complaints resolved within 48-hour municipal SLA target.',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.border, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Section 2: Metric Tiles Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Average Duration',
                  value: summary.formattedAvgResolutionTime,
                  icon: Icons.timer_outlined,
                  color: GovtThemeTokens.primary,
                  subtext: 'Target: 48.0 hrs',
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: _buildMetricTile(
                  label: 'Active Pipeline',
                  value: '${summary.pendingComplaints + summary.inProgressComplaints}',
                  icon: Icons.pending_actions_rounded,
                  color: GovtThemeTokens.alert,
                  subtext: '${summary.pendingComplaints} unassigned/new',
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // Section 3: SLA Compliance Pill Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: GovtThemeTokens.secondary),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Text(
                    'Operational benchmark: 91.2% first-time field triage resolution.',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  label,
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            value,
            style: CivicFixTypography.bodyLargeMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            subtext,
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
