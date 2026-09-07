import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Hero points and level progress card for Rewards screen.
class PointsProgressCard extends StatelessWidget {
  final int points;
  final int nextMilestone;

  const PointsProgressCard({
    super.key,
    required this.points,
    this.nextMilestone = 1000,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (nextMilestone - points).clamp(0, nextMilestone);
    final progress = nextMilestone > 0 ? (points / nextMilestone).clamp(0.0, 1.0) : 1.0;

    return CivicFixCard(
      backgroundColor: CivicFixColors.primary,
      borderColor: CivicFixColors.primaryDark,
      padding: const EdgeInsets.all(CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      'Civic Points',
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
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(CivicFixColors.accent),
            ),
          ),
          CivicFixSpacing.vSpaceSm,

          // Milestone target subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                remaining > 0
                    ? '$remaining points to next milestone'
                    : 'Milestone achieved!',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: CivicFixColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$points / $nextMilestone',
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
