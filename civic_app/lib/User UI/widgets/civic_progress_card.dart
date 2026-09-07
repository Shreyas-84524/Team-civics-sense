import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../models/home_data_model.dart';

/// Professional, non-gamified Civic Progress card for the Home screen.
class CivicProgressCard extends StatelessWidget {
  final CivicProgressSummary progress;
  final VoidCallback? onTap;

  const CivicProgressCard({
    super.key,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentInt = (progress.progressPercent * 100).toInt();

    return CivicFixCard(
      onTap: onTap ??
          () {
            Navigator.pushNamed(context, AppRoutes.rewards);
          },
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Level / Tier & Points Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: CivicFixColors.secondary.withValues(alpha: 0.12),
                      borderRadius: CivicFixRadius.chipRadius,
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: CivicFixColors.secondary,
                      size: 20,
                    ),
                  ),
                  CivicFixSpacing.hSpaceSm,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.levelName,
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: CivicFixColors.primaryText,
                        ),
                      ),
                      Text(
                        'Civic Standing',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CivicFixSpacing.md,
                  vertical: CivicFixSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: CivicFixColors.accentLight,
                  borderRadius: CivicFixRadius.fullRadius,
                  border: Border.all(
                    color: CivicFixColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: CivicFixColors.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.points} Points',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: CivicFixColors.secondaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contribution Tier Progress',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$percentInt%',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: CivicFixColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceXs,
              ClipRRect(
                borderRadius: CivicFixRadius.fullRadius,
                child: LinearProgressIndicator(
                  value: progress.progressPercent,
                  backgroundColor: CivicFixColors.surfaceMuted,
                  valueColor: const AlwaysStoppedAnimation<Color>(CivicFixColors.secondary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // 3-Column Stats Row: Points | Reports | Resolved
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: CivicFixSpacing.md,
              horizontal: CivicFixSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: CivicFixColors.surfaceMuted,
              borderRadius: CivicFixRadius.cardRadius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Total Points',
                    value: '${progress.points}',
                    icon: Icons.toll_rounded,
                    iconColor: CivicFixColors.secondary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: CivicFixColors.border,
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'Reports Filed',
                    value: '${progress.reportsSubmitted}',
                    icon: Icons.edit_document,
                    iconColor: CivicFixColors.info,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: CivicFixColors.border,
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'Resolved Fixes',
                    value: '${progress.reportsResolved}',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: CivicFixColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: CivicFixTypography.h3.copyWith(
            fontWeight: FontWeight.w700,
            color: CivicFixColors.primaryText,
          ),
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          label,
          textAlign: TextAlign.center,
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
