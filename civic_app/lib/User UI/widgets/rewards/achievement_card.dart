import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/reward_model.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Card displaying an individual Civic Achievement with unlocked/locked state and detail modal.
class AchievementCard extends StatelessWidget {
  final CivicAchievement achievement;

  const AchievementCard({
    super.key,
    required this.achievement,
  });

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.cardRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? CivicFixColors.accentLight
                    : CivicFixColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.icon,
                color: achievement.isUnlocked
                    ? CivicFixColors.secondary
                    : CivicFixColors.disabledText,
                size: 24,
              ),
            ),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Text(
                achievement.title,
                style: CivicFixTypography.h3.copyWith(
                  color: CivicFixColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? CivicFixColors.statusResolvedBg
                    : CivicFixColors.surfaceMuted,
                borderRadius: CivicFixRadius.chipRadius,
                border: Border.all(
                  color: achievement.isUnlocked
                      ? CivicFixColors.secondary.withValues(alpha: 0.3)
                      : CivicFixColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    achievement.isUnlocked
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    size: 14,
                    color: achievement.isUnlocked
                        ? CivicFixColors.secondary
                        : CivicFixColors.disabledText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    achievement.isUnlocked ? 'Unlocked' : 'Locked',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: achievement.isUnlocked
                          ? CivicFixColors.secondaryDark
                          : CivicFixColors.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            CivicFixSpacing.vSpaceMd,

            // Description
            Text(
              achievement.description,
              style: CivicFixTypography.bodySmall.copyWith(
                color: CivicFixColors.primaryText,
                height: 1.4,
              ),
            ),
            CivicFixSpacing.vSpaceMd,

            // How to unlock
            Text(
              'How to Unlock',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: CivicFixColors.secondaryText,
              ),
            ),
            CivicFixSpacing.vSpaceXs,
            Text(
              achievement.howToUnlock,
              style: CivicFixTypography.caption.copyWith(
                color: CivicFixColors.secondaryText,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${achievement.title}. ${achievement.description}. ${achievement.isUnlocked ? "Unlocked" : "Locked"}. Tap for details.',
      button: true,
      child: InkWell(
        onTap: () => _showDetailsDialog(context),
        borderRadius: CivicFixRadius.cardRadius,
        child: CivicFixCard(
          backgroundColor: achievement.isUnlocked
              ? CivicFixColors.surface
              : CivicFixColors.surfaceMuted,
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: achievement.isUnlocked
                          ? CivicFixColors.accentLight
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement.icon,
                      color: achievement.isUnlocked
                          ? CivicFixColors.secondary
                          : CivicFixColors.disabledText,
                      size: 22,
                    ),
                  ),
                  Icon(
                    achievement.isUnlocked
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                    color: achievement.isUnlocked
                        ? CivicFixColors.secondary
                        : CivicFixColors.disabledText,
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceSm,
              Text(
                achievement.title,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: achievement.isUnlocked
                      ? CivicFixColors.primaryText
                      : CivicFixColors.secondaryText,
                ),
              ),
              CivicFixSpacing.vSpaceXs,
              Expanded(
                child: Text(
                  achievement.description,
                  style: CivicFixTypography.caption.copyWith(
                    color: achievement.isUnlocked
                        ? CivicFixColors.secondaryText
                        : CivicFixColors.disabledText,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
