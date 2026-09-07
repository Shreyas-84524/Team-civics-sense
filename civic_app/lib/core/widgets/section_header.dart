import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Section header with optional action button ("View All", "See More").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionTitle;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionTitle,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: CivicFixTypography.h3,
                ),
                if (subtitle != null) ...[
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    subtitle!,
                    style: CivicFixTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (actionTitle != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: CivicFixSpacing.xs,
                  horizontal: CivicFixSpacing.xs,
                ),
                child: Text(
                  actionTitle!,
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    color: CivicFixColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
