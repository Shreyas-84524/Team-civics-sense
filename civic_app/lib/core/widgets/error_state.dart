import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';
import 'civic_fix_button.dart';

/// Clean institutional error state with retry mechanism.
///
/// Follows Design.md:
/// - Error container icon backing with hairline border
/// - Plus Jakarta Sans headline
/// - Inter message body
/// - Deep slate retry button
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final Widget? customAction;

  const ErrorState({
    super.key,
    this.title = 'Unable to Load Data',
    this.message = 'A problem occurred while loading civic information. Please check your connection and try again.',
    this.onRetry,
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
                color: CivicFixColors.errorContainer,
                borderRadius: CivicFixRadius.cardRadius,
                border: Border.all(
                  color: CivicFixColors.error.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: CivicFixColors.error,
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
              message,
              textAlign: TextAlign.center,
              style: CivicFixTypographyTokens.bodySm.copyWith(
                color: CivicFixColors.textSecondary,
              ),
            ),
            if (customAction != null) ...[
              const SizedBox(height: CivicFixSpacing.spaceLg),
              customAction!,
            ] else if (onRetry != null) ...[
              const SizedBox(height: CivicFixSpacing.spaceLg),
              CivicFixButton(
                text: 'Try Again',
                onPressed: onRetry,
                width: 160,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard alias conforming to the CivicFix naming convention.
typedef CivicFixErrorState = ErrorState;
