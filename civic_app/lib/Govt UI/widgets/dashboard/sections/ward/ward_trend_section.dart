import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../models/analytics_model.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../analytics/govt_time_trend_chart.dart';

/// Ward Trend Section for Assistant Commissioner / Ward Officer Command Center.
/// Shows temporal grievance trends (incoming vs resolved) strictly within the assigned Ward.
class WardTrendSection extends StatefulWidget {
  final List<TimeTrendPoint> timeTrends;
  final bool isLoading;
  final ValueChanged<int>? onRangeDaysChanged;

  const WardTrendSection({
    super.key,
    required this.timeTrends,
    this.isLoading = false,
    this.onRangeDaysChanged,
  });

  @override
  State<WardTrendSection> createState() => _WardTrendSectionState();
}

class _WardTrendSectionState extends State<WardTrendSection> {
  DateRangeOption _currentRange = DateRangeOption.last7Days;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.timeTrends.isNotEmpty &&
        widget.timeTrends.any((p) => p.reportedCount > 0 || p.resolvedCount > 0);

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.show_chart, color: GovtThemeTokens.primary, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WARD GRIEVANCE VOLUME TRENDS',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Temporal progression of reported vs resolved complaints within this ward',
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildRangeChip(DateRangeOption.last7Days, '7 Days', 7),
                  _buildRangeChip(DateRangeOption.last30Days, '30 Days', 30),
                  _buildRangeChip(DateRangeOption.last90Days, '90 Days', 90),
                ],
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.timeline, size: 40, color: GovtThemeTokens.textMuted),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No chronological data points available for selected range.',
                      style: CivicFixTypography.bodyMedium.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            GovtTimeTrendChart(
              points: widget.timeTrends,
              dateRange: _currentRange,
              onDateRangeChanged: (range) {
                setState(() => _currentRange = range);
                if (widget.onRangeDaysChanged != null) {
                  int days = 7;
                  if (range == DateRangeOption.last30Days) days = 30;
                  if (range == DateRangeOption.last90Days) days = 90;
                  widget.onRangeDaysChanged!(days);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(DateRangeOption option, String label, int days) {
    final isSelected = _currentRange == option;
    return InkWell(
      onTap: () {
        setState(() => _currentRange = option);
        if (widget.onRangeDaysChanged != null) {
          widget.onRangeDaysChanged!(days);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.border,
          ),
        ),
        child: Text(
          label,
          style: CivicFixTypography.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : GovtThemeTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}
