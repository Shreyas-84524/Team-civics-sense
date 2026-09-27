import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../models/analytics_model.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../analytics/govt_time_trend_chart.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_empty_state.dart';

/// Interactive section presenting citywide time-series complaint trends (Created vs Resolved).
class CityComplaintTrendSection extends StatefulWidget {
  final List<TimeTrendPoint> timeTrends;
  final bool isLoading;
  final ValueChanged<int>? onRangeDaysChanged;

  const CityComplaintTrendSection({
    super.key,
    required this.timeTrends,
    this.isLoading = false,
    this.onRangeDaysChanged,
  });

  @override
  State<CityComplaintTrendSection> createState() => _CityComplaintTrendSectionState();
}

class _CityComplaintTrendSectionState extends State<CityComplaintTrendSection> {
  DateRangeOption _currentRange = DateRangeOption.last7Days;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.timeTrends.isNotEmpty &&
        widget.timeTrends.any((p) => p.reportedCount > 0 || p.resolvedCount > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'Citywide Complaint Trend',
          subtitle: 'Temporal progression of reported vs resolved municipal grievances',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRangeChip(DateRangeOption.last7Days, '7 Days', 7),
              CivicFixSpacing.hSpaceXs,
              _buildRangeChip(DateRangeOption.last30Days, '30 Days', 30),
              CivicFixSpacing.hSpaceXs,
              _buildRangeChip(DateRangeOption.last90Days, '90 Days', 90),
            ],
          ),
        ),
        CivicFixSpacing.vSpaceSm,
        if (!hasData && !widget.isLoading)
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xxl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: const GovtEmptyState(
              title: 'Historical trend data unavailable',
              message: 'No chronological complaints recorded within the selected period.',
              icon: Icons.show_chart_rounded,
              isCompact: true,
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
          color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.border,
          ),
        ),
        child: Text(
          label,
          style: GovtTypography.caption.copyWith(
            color: isSelected ? Colors.white : GovtThemeTokens.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
