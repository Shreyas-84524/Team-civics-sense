import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/localization/widgets/civic_fix_translated_text.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Chronological timeline widget displaying all status updates for a complaint (latest first).
class StatusHistoryTimeline extends StatelessWidget {
  final List<TimelineEvent> timeline;

  const StatusHistoryTimeline({
    super.key,
    required this.timeline,
  });

  IconData _getEventIcon(TimelineEvent event) {
    final titleLower = event.title.toLowerCase();
    final descLower = event.description.toLowerCase();
    if (titleLower.contains('reopen') || descLower.contains('reopen') || titleLower.contains('rework') || descLower.contains('rework')) {
      return Icons.replay_circle_filled_rounded;
    }
    if (titleLower.contains('block') || descLower.contains('block') || titleLower.contains('hold') || descLower.contains('hold')) {
      return Icons.pause_circle_outline_rounded;
    }
    if (titleLower.contains('field officer') || descLower.contains('field officer')) {
      return Icons.build_circle_outlined;
    }
    if (titleLower.contains('junior engineer') || descLower.contains('junior engineer') || titleLower.contains('crew')) {
      return Icons.shield_outlined;
    }
    if (titleLower.contains('started') || titleLower.contains('progress') || descLower.contains('progress')) {
      return Icons.engineering_rounded;
    }
    if (titleLower.contains('resolved') || descLower.contains('resolved')) {
      return Icons.check_circle_rounded;
    }
    return event.status.icon;
  }

  Color _getEventColor(TimelineEvent event) {
    final titleLower = event.title.toLowerCase();
    final descLower = event.description.toLowerCase();
    if (titleLower.contains('reopen') || descLower.contains('reopen') || titleLower.contains('rework') || descLower.contains('rework')) {
      return CivicFixColors.alertDark;
    }
    if (titleLower.contains('block') || descLower.contains('block') || titleLower.contains('hold') || descLower.contains('hold')) {
      return CivicFixColors.error;
    }
    if (titleLower.contains('field officer') || descLower.contains('field officer')) {
      return CivicFixColors.info;
    }
    if (titleLower.contains('junior engineer') || descLower.contains('junior engineer')) {
      return CivicFixColors.primary;
    }
    return event.status.color;
  }

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
              final eventIcon = _getEventIcon(event);
              final eventColor = _getEventColor(event);

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
                            color: eventColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: eventColor,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            eventIcon,
                            size: 13,
                            color: eventColor,
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
                            CivicFixTranslatedText(
                              originalText: event.description,
                              contentCategory: 'timeline_event_description',
                              dense: true,
                              style: CivicFixTypography.bodySmall.copyWith(
                                color: CivicFixColors.secondaryText,
                                height: 1.35,
                              ),
                            ),
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
