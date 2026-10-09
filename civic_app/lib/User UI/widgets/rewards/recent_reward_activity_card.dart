import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/reward_model.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Card rendering recent canonical RewardEvents earned from complaint lifecycle milestones.
class RecentRewardActivityCard extends StatelessWidget {
  final List<RewardEvent> events;

  const RecentRewardActivityCard({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CivicFixColors.secondary.withValues(alpha: 0.1),
                  borderRadius: CivicFixRadius.chipRadius,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: CivicFixColors.secondary,
                  size: 18,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Text(
                  'Recent Reward Activity',
                  style: CivicFixTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: CivicFixColors.primaryText,
                  ),
                ),
              ),
              if (events.isNotEmpty)
                Text(
                  '${events.length} events',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.lg),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_outlined,
                      size: 32,
                      color: CivicFixColors.secondaryText.withValues(alpha: 0.5),
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No reward activity yet.',
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        color: CivicFixColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      'Report civic issues and track them to resolution to earn Civic Points.',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length > 5 ? 5 : events.length,
              separatorBuilder: (context, index) => Divider(
                height: 16,
                thickness: 0.8,
                color: CivicFixColors.border.withValues(alpha: 0.7),
              ),
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventTile(event);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventTile(RewardEvent event) {
    final ticketNum = event.metadata['ticketNumber'] as String?;
    final subtitle = [
      if (ticketNum != null && ticketNum.isNotEmpty) ticketNum,
      if (event.complaintTitle.isNotEmpty && event.complaintTitle != 'Civic complaint')
        event.complaintTitle,
    ].join(' • ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Points Badge
        Container(
          width: 44,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CivicFixColors.secondaryLight.withValues(alpha: 0.15),
            borderRadius: CivicFixRadius.chipRadius,
            border: Border.all(
              color: CivicFixColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '+${event.points}',
            style: CivicFixTypography.bodySmallMedium.copyWith(
              color: CivicFixColors.secondaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        CivicFixSpacing.hSpaceMd,

        // Description and Complaint Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.description,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CivicFixColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                CivicFixSpacing.vSpaceXs,
                Text(
                  subtitle,
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Relative / Short Timestamp
        Text(
          _formatTimestamp(event.createdAt),
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}
