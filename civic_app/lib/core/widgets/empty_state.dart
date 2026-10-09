import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';
import 'civic_fix_button.dart';

/// Clean institutional empty state with icon, headline, subtitle, and action button.
///
/// Follows Design.md:
/// - Muted surface container icon backing
/// - Plus Jakarta Sans headline
/// - Inter descriptive body
/// - Deep slate or gold primary CTA
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Widget? customAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.description,
    this.actionText,
    this.onActionPressed,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceLg,
          vertical: CivicFixSpacing.spaceXl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.spaceMd),
              decoration: BoxDecoration(
                color: CivicFixColors.surfaceContainer,
                borderRadius: CivicFixRadius.cardRadius,
                border: Border.all(
                  color: CivicFixColors.border,
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: CivicFixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CivicFixSpacing.spaceMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CivicFixTypographyTokens.headlineSm.copyWith(
                color: CivicFixColors.textPrimary,
              ),
            ),
            const SizedBox(height: CivicFixSpacing.spaceXs + 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: CivicFixTypographyTokens.bodySm.copyWith(
                color: CivicFixColors.textSecondary,
              ),
            ),
            if (customAction != null) ...[
              const SizedBox(height: CivicFixSpacing.spaceLg),
              customAction!,
            ] else if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: CivicFixSpacing.spaceLg),
              CivicFixButton(
                text: actionText!,
                onPressed: onActionPressed,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard alias conforming to the CivicFix naming convention.
typedef CivicFixEmptyState = EmptyState;
