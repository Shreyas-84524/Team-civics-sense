import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/reward_model.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Hero points and level progress card for Rewards screen.
///
/// Implements Phase 2 Gamification:
/// - Level 1: 0–99 pts   -> Civic Starter
/// - Level 2: 100–249 pts -> Civic Contributor
/// - Level 3: 250–499 pts -> Civic Champion
/// - Level 4: 500–999 pts -> Civic Leader
/// - Level 5: 1000+ pts   -> Civic Hero (Max level, complete progress, no fake next level)
class PointsProgressCard extends StatelessWidget {
  final int points;
  final int nextMilestone;
  final CivicLevelInfo? levelInfoOverride;

  const PointsProgressCard({
    super.key,
    required this.points,
    this.nextMilestone = 1000,
    this.levelInfoOverride,
  });

  @override
  Widget build(BuildContext context) {
    final levelInfo = levelInfoOverride ?? CivicLevelInfo.calculate(points);
    final isMax = levelInfo.isMaxLevel;

    return CivicFixCard(
      backgroundColor: CivicFixColors.primary,
      borderColor: CivicFixColors.primaryDark,
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Chip Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: CivicFixRadius.chipRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      levelInfo.symbol,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Level ${levelInfo.level} • ${levelInfo.title}',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMax)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CivicFixColors.accent.withValues(alpha: 0.25),
                    borderRadius: CivicFixRadius.chipRadius,
                    border: Border.all(color: CivicFixColors.accent),
                  ),
                  child: Text(
                    'MAX LEVEL',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Points Counter
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: CivicFixColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: CivicFixColors.secondary,
                  size: 28,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$points',
                      style: CivicFixTypography.h1.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      context.l10nOrNull?.civicPoints ?? 'Civic Points',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Progress Bar
          ClipRRect(
            borderRadius: CivicFixRadius.chipRadius,
            child: LinearProgressIndicator(
              value: levelInfo.progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isMax ? CivicFixColors.secondaryLight : CivicFixColors.accent,
              ),
            ),
          ),
          CivicFixSpacing.vSpaceSm,

          // Milestone target subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  isMax
                      ? 'Hero Tier Achieved — Top civic milestone unlocked!'
                      : '${levelInfo.pointsRemaining} pts to Level ${levelInfo.nextLevelNumber}: ${levelInfo.nextLevelTitle}',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: isMax ? CivicFixColors.secondaryLight : CivicFixColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isMax
                    ? '$points pts'
                    : '$points / ${levelInfo.nextLevelMinPoints} pts',
                style: CivicFixTypography.caption.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          Text(
            'Points are participation indicators for responsible civic contributions.',
            style: CivicFixTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
