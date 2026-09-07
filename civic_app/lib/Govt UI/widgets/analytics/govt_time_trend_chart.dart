import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../models/analytics_model.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Interactive dual-metric trend chart comparing Reported vs Resolved complaint volumes.
class GovtTimeTrendChart extends StatefulWidget {
  final List<TimeTrendPoint> points;
  final DateRangeOption dateRange;
  final ValueChanged<DateRangeOption>? onDateRangeChanged;

  const GovtTimeTrendChart({
    super.key,
    required this.points,
    required this.dateRange,
    this.onDateRangeChanged,
  });

  @override
  State<GovtTimeTrendChart> createState() => _GovtTimeTrendChartState();
}

class _GovtTimeTrendChartState extends State<GovtTimeTrendChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    // Determine maximum scale
    int maxVal = 1;
    for (final p in widget.points) {
      maxVal = max(maxVal, max(p.reportedCount, p.resolvedCount));
    }
    // Round maxVal to a neat ceiling
    final yMax = ((maxVal + 4) ~/ 5) * 5;

    return DashboardCard(
      title: 'Complaint Volume & Resolution Trend',
      subtitle: 'Chronological comparison of logged vs resolved grievances',
      headerTrailing: _buildLegend(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CivicFixSpacing.vSpaceMd,

          // Main Chart Canvas with Y-Axis & Bars
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis Labels
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$yMax', style: CivicFixTypography.caption.copyWith(fontSize: 10, color: GovtThemeTokens.textSecondary)),
                      Text('${(yMax * 0.75).toInt()}', style: CivicFixTypography.caption.copyWith(fontSize: 10, color: GovtThemeTokens.textSecondary)),
                      Text('${(yMax * 0.5).toInt()}', style: CivicFixTypography.caption.copyWith(fontSize: 10, color: GovtThemeTokens.textSecondary)),
                      Text('${(yMax * 0.25).toInt()}', style: CivicFixTypography.caption.copyWith(fontSize: 10, color: GovtThemeTokens.textSecondary)),
                      Text('0', style: CivicFixTypography.caption.copyWith(fontSize: 10, color: GovtThemeTokens.textSecondary)),
                    ],
                  ),
                ),
                CivicFixSpacing.hSpaceSm,

                // Grid and Bar Columns
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final minItemWidth = 48.0;
                      final totalNeededWidth = widget.points.length * minItemWidth;
                      final needsScroll = totalNeededWidth > availableWidth;

                      final content = SizedBox(
                        width: needsScroll ? totalNeededWidth : availableWidth,
                        child: Stack(
                          children: [
                            // Background horizontal grid lines
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  5,
                                  (_) => const Divider(color: Color(0xFFE5ECE8), height: 1),
                                ),
                              ),
                            ),

                            // Dual Bar Columns
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: widget.points.asMap().entries.map((entry) {
                                final index = entry.key;
                                final point = entry.value;
                                final isHovered = _hoveredIndex == index;

                                final repHeight = (point.reportedCount / yMax * 160).clamp(4.0, 160.0);
                                final resHeight = (point.resolvedCount / yMax * 160).clamp(4.0, 160.0);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _hoveredIndex = _hoveredIndex == index ? null : index;
                                    });
                                  },
                                  child: Semantics(
                                    label: '${point.label}: ${point.reportedCount} reported, ${point.resolvedCount} resolved',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: isHovered ? GovtThemeTokens.primary.withValues(alpha: 0.05) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // Tooltip pill if active
                                          if (isHovered)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(bottom: 4),
                                              decoration: BoxDecoration(
                                                color: GovtThemeTokens.textPrimary,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Rep: ${point.reportedCount} | Res: ${point.resolvedCount}',
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                              ),
                                            ),

                                          // Bars side-by-side
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              // Reported Bar
                                              Tooltip(
                                                message: 'Reported: ${point.reportedCount}',
                                                child: Container(
                                                  width: 14,
                                                  height: repHeight,
                                                  decoration: BoxDecoration(
                                                    color: GovtThemeTokens.primary,
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                                    boxShadow: isHovered
                                                        ? [
                                                            BoxShadow(
                                                              color: GovtThemeTokens.primary.withValues(alpha: 0.4),
                                                              blurRadius: 4,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),

                                              // Resolved Bar
                                              Tooltip(
                                                message: 'Resolved: ${point.resolvedCount}',
                                                child: Container(
                                                  width: 14,
                                                  height: resHeight,
                                                  decoration: BoxDecoration(
                                                    color: GovtThemeTokens.secondary,
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                                    boxShadow: isHovered
                                                        ? [
                                                            BoxShadow(
                                                              color: GovtThemeTokens.secondary.withValues(alpha: 0.4),
                                                              blurRadius: 4,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          CivicFixSpacing.vSpaceXs,

                                          // X-Axis Date Label
                                          Text(
                                            point.label,
                                            style: CivicFixTypography.caption.copyWith(
                                              fontSize: 10,
                                              fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                                              color: isHovered ? GovtThemeTokens.primary : GovtThemeTokens.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );

                      if (needsScroll) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: content,
                        );
                      }
                      return content;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: GovtThemeTokens.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CivicFixSpacing.hSpaceXs,
            Text('Reported', style: CivicFixTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        CivicFixSpacing.hSpaceMd,
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: GovtThemeTokens.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CivicFixSpacing.hSpaceXs,
            Text('Resolved', style: CivicFixTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
