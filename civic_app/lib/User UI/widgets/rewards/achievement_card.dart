import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/mappers/canonical_display_mappers.dart';
import '../../../core/models/reward_model.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Card displaying an individual Civic Achievement with unlocked/locked state,
/// progress bar, unlock timestamp, and detail modal.
class AchievementCard extends StatelessWidget {
  final CivicAchievement achievement;

  const AchievementCard({
    super.key,
    required this.achievement,
  });

  void _showDetailsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = localizedAchievementTitle(achievement, context: context);
    final desc = localizedAchievementDescription(achievement, context: context);

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
                title,
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
            // Status Chip & Unlock Date
            Row(
              children: [
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
                        achievement.isUnlocked
                            ? (l10n?.unlocked ?? 'Unlocked')
                            : (l10n?.locked ?? 'Locked'),
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
                if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
                  const Spacer(),
                  Text(
                    'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            CivicFixSpacing.vSpaceMd,

            // Description
            Text(
              desc,
              style: CivicFixTypography.bodySmall.copyWith(
                color: CivicFixColors.primaryText,
                height: 1.4,
              ),
            ),
            CivicFixSpacing.vSpaceMd,

            // Requirement / How to unlock
            Text(
              l10n?.howToUnlock ?? 'Requirement',
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

            if (!achievement.isUnlocked && achievement.targetProgress > 0) ...[
              CivicFixSpacing.vSpaceMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CivicFixColors.secondaryText,
                    ),
                  ),
                  Text(
                    '${achievement.currentProgress} / ${achievement.targetProgress} (${(achievement.progressRatio * 100).toInt()}%)',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceXs,
              ClipRRect(
                borderRadius: CivicFixRadius.chipRadius,
                child: LinearProgressIndicator(
                  value: achievement.progressRatio,
                  minHeight: 6,
                  backgroundColor: CivicFixColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(CivicFixColors.primary),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = localizedAchievementTitle(achievement, context: context);
    final desc = localizedAchievementDescription(achievement, context: context);
    final isUnlocked = achievement.isUnlocked;

    return Semantics(
      label: '$title. $desc. ${isUnlocked ? 'Unlocked' : 'Locked'}. Tap for details.',
      button: true,
      child: InkWell(
        onTap: () => _showDetailsDialog(context),
        borderRadius: CivicFixRadius.cardRadius,
        child: CivicFixCard(
          backgroundColor: isUnlocked
              ? CivicFixColors.surface
              : CivicFixColors.surfaceMuted,
          borderColor: isUnlocked
              ? CivicFixColors.secondary.withValues(alpha: 0.25)
              : CivicFixColors.border,
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
                      color: isUnlocked
                          ? CivicFixColors.accentLight
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement.icon,
                      color: isUnlocked
                          ? CivicFixColors.secondary
                          : CivicFixColors.disabledText,
                      size: 22,
                    ),
                  ),
                  Icon(
                    isUnlocked
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                    color: isUnlocked
                        ? CivicFixColors.secondary
                        : CivicFixColors.disabledText,
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceSm,
              Text(
                title,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUnlocked
                      ? CivicFixColors.primaryText
                      : CivicFixColors.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              CivicFixSpacing.vSpaceXs,
              Expanded(
                child: Text(
                  isUnlocked ? desc : achievement.howToUnlock,
                  style: CivicFixTypography.caption.copyWith(
                    color: isUnlocked
                        ? CivicFixColors.secondaryText
                        : CivicFixColors.disabledText,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Progress bar for locked badges, or unlock date for unlocked
              if (!isUnlocked && achievement.targetProgress > 0) ...[
                CivicFixSpacing.vSpaceXs,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${achievement.currentProgress}/${achievement.targetProgress}',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(achievement.progressRatio * 100).toInt()}%',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                ClipRRect(
                  borderRadius: CivicFixRadius.chipRadius,
                  child: LinearProgressIndicator(
                    value: achievement.progressRatio,
                    minHeight: 4,
                    backgroundColor: CivicFixColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(CivicFixColors.primary),
                  ),
                ),
              ] else if (isUnlocked && achievement.unlockedAt != null) ...[
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryDark,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
