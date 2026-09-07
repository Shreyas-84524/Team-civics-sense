import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Segment item for bar / breakdown analytics visualization.
class AnalyticsBreakdownItem {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const AnalyticsBreakdownItem({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

/// Reusable Analytics Card for departmental resolution rates and workload summaries.
class GovtAnalyticsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String primaryMetric;
  final String primaryMetricLabel;
  final List<AnalyticsBreakdownItem> items;
  final Widget? trailing;

  const GovtAnalyticsCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.primaryMetric,
    required this.primaryMetricLabel,
    required this.items,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final activeItems = items.where((it) => it.count > 0).toList();
    final totalCount = items.fold<int>(0, (sum, it) => sum + it.count);

    return DashboardCard(
      title: title,
      subtitle: subtitle,
      headerTrailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Metric Highlight
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                primaryMetric,
                style: CivicFixTypography.display.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.primary,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Text(
                primaryMetricLabel,
                style: CivicFixTypography.bodySmall.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Multi-segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: totalCount == 0
                  ? Container(color: const Color(0xFFE5ECE8))
                  : Row(
                      children: activeItems.map((item) {
                        final flexVal = (item.percentage * 1000).toInt().clamp(1, 1000);
                        return Expanded(
                          flex: flexVal,
                          child: Container(color: item.color),
                        );
                      }).toList(),
                    ),
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Breakdown Legend Rows
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: Text(
                        item.label,
                        style: CivicFixTypography.bodySmall.copyWith(
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${item.count}',
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      '(${(item.percentage * 100).toStringAsFixed(0)}%)',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
