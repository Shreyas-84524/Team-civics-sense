import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Chronological timeline widget displaying all status updates for a complaint (latest first).
class StatusHistoryTimeline extends StatelessWidget {
  final List<TimelineEvent> timeline;

  const StatusHistoryTimeline({
    super.key,
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return CivicFixCard(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Updates',
              style: CivicFixTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: CivicFixColors.primaryText,
              ),
            ),
            CivicFixSpacing.vSpaceMd,
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.md),
                child: Text(
                  'No updates yet.',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: CivicFixColors.secondaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Sort descending by timestamp (newest update first)
    final sortedTimeline = List<TimelineEvent>.from(timeline)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updates',
                style: CivicFixTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CivicFixColors.primaryText,
                ),
              ),
              Text(
                '${sortedTimeline.length} ${sortedTimeline.length == 1 ? "entry" : "entries"}',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: CivicFixColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Updates List (Newest First)
          Column(
            children: List.generate(sortedTimeline.length, (index) {
              final event = sortedTimeline[index];
              final isLast = index == sortedTimeline.length - 1;
              final formattedTime = DateFormatter.formatTimelineDate(event.timestamp);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Node & Vertical Spine
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: event.status.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: event.status.color,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            event.status.icon,
                            size: 13,
                            color: event.status.color,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: CivicFixColors.border,
                            ),
                          ),
                      ],
                    ),
                    CivicFixSpacing.hSpaceMd,

                    // Event Content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: isLast ? 0 : CivicFixSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Title + Time Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: CivicFixTypography.bodySmallMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: CivicFixColors.primaryText,
                                    ),
                                  ),
                                ),
                                CivicFixSpacing.hSpaceSm,
                                Text(
                                  formattedTime,
                                  style: CivicFixTypography.caption.copyWith(
                                    color: CivicFixColors.secondaryText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            CivicFixSpacing.vSpaceXs,

                            // Status Description / Message
                            Text(
                              event.description,
                              style: CivicFixTypography.bodySmall.copyWith(
                                color: CivicFixColors.secondaryText,
                                height: 1.35,
                              ),
                            ),

                            // Optional Updated By Tag
                            if (event.updatedBy != null && event.updatedBy!.isNotEmpty) ...[
                              CivicFixSpacing.vSpaceXs,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CivicFixColors.surfaceMuted,
                                  borderRadius: CivicFixRadius.chipRadius,
                                ),
                                child: Text(
                                  event.updatedBy!,
                                  style: CivicFixTypography.caption.copyWith(
                                    fontSize: 10,
                                    color: CivicFixColors.secondaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
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
          ),
        ],
      ),
    );
  }
}
