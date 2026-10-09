import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/theme/civicfix_design_tokens.dart';
import '../../core/widgets/civic_fix_card.dart';

/// Complaint Status Summary card displaying real-time metrics for citizen grievances.
///
/// Follows Design.md:
/// - Pure white surface with 1px hairline border
/// - 8px radius
/// - Plus Jakarta Sans numeric metrics
/// - Semantic status indicator dots
class HomeComplaintSummaryCard extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final VoidCallback? onTap;

  const HomeComplaintSummaryCard({
    super.key,
    required this.complaints,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int activeCount = 0;
    int inProgressCount = 0;
    int resolvedCount = 0;

    for (final c in complaints) {
      if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.closed) {
        resolvedCount++;
      } else if (c.status == ComplaintStatus.inProgress || c.status == ComplaintStatus.assigned) {
        inProgressCount++;
      } else {
        activeCount++;
      }
    }

    return CivicFixCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.spaceMd,
        vertical: CivicFixSpacing.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grievance Overview',
                style: CivicFixTypographyTokens.labelMd.copyWith(
                  color: CivicFixColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Track All',
                    style: CivicFixTypographyTokens.labelSm.copyWith(
                      color: CivicFixColors.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: CivicFixColors.primaryAccent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: CivicFixSpacing.spaceMd),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricColumn(
                  count: activeCount,
                  label: 'Under Review',
                  dotColor: CivicFixColors.info,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: CivicFixColors.border,
              ),
              Expanded(
                child: _SummaryMetricColumn(
                  count: inProgressCount,
                  label: 'In Progress',
                  dotColor: CivicFixColors.warning,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: CivicFixColors.border,
              ),
              Expanded(
                child: _SummaryMetricColumn(
                  count: resolvedCount,
                  label: 'Resolved Fixes',
                  dotColor: CivicFixColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricColumn extends StatelessWidget {
  final int count;
  final String label;
  final Color dotColor;

  const _SummaryMetricColumn({
    required this.count,
    required this.label,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: CivicFixTypographyTokens.headlineSm.copyWith(
                color: CivicFixColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypographyTokens.labelSm.copyWith(
            color: CivicFixColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
