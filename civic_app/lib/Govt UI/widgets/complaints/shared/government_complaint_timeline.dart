import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../theme/govt_theme_tokens.dart';

/// Standardized, reusable complaint lifecycle timeline for all government roles.
class GovernmentComplaintTimeline extends StatelessWidget {
  final List<TimelineEvent> timeline;
  final bool isCompact;

  const GovernmentComplaintTimeline({
    super.key,
    required this.timeline,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        alignment: Alignment.center,
        child: Text(
          'No timeline events recorded.',
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final event = timeline[index];
        final isFirst = index == 0;
        final isLast = index == timeline.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + Node Icon
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: 8,
                    color: isFirst ? Colors.transparent : GovtThemeTokens.border,
                  ),
                  Container(
                    width: isFirst ? 14 : 10,
                    height: isFirst ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getEventColor(event.title, isFirst),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        if (isFirst)
                          BoxShadow(
                            color: _getEventColor(event.title, isFirst)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: isCompact ? 40 : 54,
                      color: GovtThemeTokens.border,
                    ),
                ],
              ),
            ),
            CivicFixSpacing.hSpaceSm,

            // Event Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : CivicFixSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: CivicFixTypography.captionMedium.copyWith(
                              fontWeight: isFirst ? FontWeight.w700 : FontWeight.w600,
                              color: isFirst
                                  ? GovtThemeTokens.textPrimary
                                  : GovtThemeTokens.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '${event.timestamp.day}/${event.timestamp.month} ${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      event.description,
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    if (event.updatedBy != null && event.updatedBy!.isNotEmpty) ...[
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'By: ${event.updatedBy}',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getEventColor(String title, bool isFirst) {
    final t = title.toLowerCase();
    if (t.contains('resolved') || t.contains('verified') || t.contains('approved')) {
      return GovtThemeTokens.success;
    }
    if (t.contains('reject') || t.contains('rework') || t.contains('closed')) {
      return GovtThemeTokens.error;
    }
    if (t.contains('routing') || t.contains('reassign') || t.contains('issue')) {
      return const Color(0xFFF97316);
    }
    if (t.contains('started') || t.contains('progress')) {
      return const Color(0xFFD97706);
    }
    if (t.contains('assigned') || t.contains('crew')) {
      return const Color(0xFF3B82F6);
    }
    return isFirst ? GovtThemeTokens.primary : GovtThemeTokens.textMuted;
  }
}
