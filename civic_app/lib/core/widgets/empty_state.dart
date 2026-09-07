import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'civic_fix_button.dart';

/// Clean empty state with icon, headline, subtitle, and action button.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.description,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.xxl,
          vertical: CivicFixSpacing.xxxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              decoration: BoxDecoration(
                color: CivicFixColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: CivicFixColors.secondaryText,
              ),
            ),
            CivicFixSpacing.vSpaceLg,
            Text(
              title,
              textAlign: TextAlign.center,
              style: CivicFixTypography.h3,
            ),
            CivicFixSpacing.vSpaceSm,
            Text(
              description,
              textAlign: TextAlign.center,
              style: CivicFixTypography.bodySmall,
            ),
            if (actionText != null && onActionPressed != null) ...[
              CivicFixSpacing.vSpaceXl,
              CivicFixButton(
                text: actionText!,
                onPressed: onActionPressed,
                width: 220,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
