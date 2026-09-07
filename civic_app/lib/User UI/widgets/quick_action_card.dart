import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/civic_fix_card.dart';

/// Quick Action tile for citizen dashboard (e.g. Report Issue, Ask Assistant, Rewards).
class QuickActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconBackgroundColor = CivicFixColors.accentLight,
    this.iconColor = CivicFixColors.secondaryDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      onTap: onTap,
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: CivicFixRadius.chipRadius,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    subtitle!,
                    style: CivicFixTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: CivicFixColors.secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }
}
