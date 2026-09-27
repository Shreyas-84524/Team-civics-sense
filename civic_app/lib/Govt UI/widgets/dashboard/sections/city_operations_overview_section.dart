import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../services/government_city_dashboard_service.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_section_header.dart';

/// Comprehensive operational state breakdown across Mumbai's municipal administrative apparatus.
class CityOperationsOverviewSection extends StatelessWidget {
  final CityOperationsOverviewData? data;
  final bool isLoading;

  const CityOperationsOverviewSection({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = data ??
        const CityOperationsOverviewData(
          totalActiveComplaints: 0,
          createdTodayCount: 0,
          resolvedTodayCount: 0,
          assignedCount: 0,
          awaitingVerificationCount: 0,
          criticalUnresolvedCount: 0,
          slaBreachesCount: 0,
          pendingEscalationsCount: 0,
          pendingRoutingTicketsCount: 0,
        );

    final indicators = [
      _IndicatorItem(
        label: 'Active Backlog',
        value: '${d.totalActiveComplaints}',
        icon: Icons.pending_actions_rounded,
        color: GovtThemeTokens.primary,
        subtitle: 'All in-flight complaints',
      ),
      _IndicatorItem(
        label: 'Created Today',
        value: '${d.createdTodayCount}',
        icon: Icons.add_task_rounded,
        color: GovtThemeTokens.info,
        subtitle: 'New intake since 00:00',
      ),
      _IndicatorItem(
        label: 'Resolved Today',
        value: '${d.resolvedTodayCount}',
        icon: Icons.verified_rounded,
        color: GovtThemeTokens.secondary,
        subtitle: 'Inspected and closed today',
      ),
      _IndicatorItem(
        label: 'Currently Assigned',
        value: '${d.assignedCount}',
        icon: Icons.engineering_rounded,
        color: const Color(0xFFD97706),
        subtitle: 'With department crew',
      ),
      _IndicatorItem(
        label: 'Awaiting Verification',
        value: '${d.awaitingVerificationCount}',
        icon: Icons.hourglass_empty_rounded,
        color: const Color(0xFF7C3AED),
        subtitle: 'Pending nodal triage',
      ),
      _IndicatorItem(
        label: 'Critical Unresolved',
        value: '${d.criticalUnresolvedCount}',
        icon: Icons.warning_rounded,
        color: GovtThemeTokens.critical,
        subtitle: 'Emergency / high severity',
      ),
      _IndicatorItem(
        label: 'SLA Breaches',
        value: '${d.slaBreachesCount}',
        icon: Icons.alarm_off_rounded,
        color: GovtThemeTokens.slaBreached,
        subtitle: 'Over 48h resolution time',
      ),
      _IndicatorItem(
        label: 'Pending Routing Tickets',
        value: '${d.pendingRoutingTicketsCount}',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF2563EB),
        subtitle: 'Reassignment requests',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GovernmentSectionHeader(
            title: 'City Operations Overview',
            subtitle: 'Real-time operational distribution across 7 zones, 24 wards, and 18 departments',
          ),
          CivicFixSpacing.vSpaceMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int cols = 4;
              if (width >= 1100) {
                cols = 4;
              } else if (width >= 720) {
                cols = 2;
              } else {
                cols = 1;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: CivicFixSpacing.md,
                  mainAxisSpacing: CivicFixSpacing.md,
                  mainAxisExtent: 80,
                ),
                itemCount: indicators.length,
                itemBuilder: (context, index) {
                  final item = indicators[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GovtThemeTokens.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, size: 20, color: item.color),
                        ),
                        CivicFixSpacing.hSpaceMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.value,
                                style: GovtTypography.cardTitle.copyWith(
                                  color: item.color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: GovtThemeTokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IndicatorItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _IndicatorItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}
