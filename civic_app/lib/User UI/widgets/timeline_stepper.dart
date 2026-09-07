import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/utils/date_formatter.dart';

/// Clean timeline stepper for complaint resolution progress.
class TimelineStepper extends StatelessWidget {
  final List<TimelineEvent> timeline;
  final ComplaintStatus currentStatus;

  const TimelineStepper({
    super.key,
    required this.timeline,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(timeline.length, (index) {
        final event = timeline[index];
        final isLast = index == timeline.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column for icon and connector line
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: event.status.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: event.status.color,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      event.status.icon,
                      size: 14,
                      color: event.status.color,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: CivicFixColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              CivicFixSpacing.hSpaceMd,

              // Event details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : CivicFixSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: CivicFixTypography.bodySmallMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            DateFormatter.formatTimeOnly(event.timestamp),
                            style: CivicFixTypography.caption,
                          ),
                        ],
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        event.description,
                        style: CivicFixTypography.bodySmall.copyWith(
                          color: CivicFixColors.secondaryText,
                        ),
                      ),
                      if (event.updatedBy != null) ...[
                        CivicFixSpacing.vSpaceXs,
                        Text(
                          'Updated by: ${event.updatedBy}',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
