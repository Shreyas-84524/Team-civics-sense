import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'civic_fix_button.dart';

/// Clean error display state with retry mechanism.
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Unable to load civic information. Please check your connection and try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CivicFixSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              decoration: BoxDecoration(
                color: CivicFixColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: CivicFixColors.error,
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
              message,
              textAlign: TextAlign.center,
              style: CivicFixTypography.bodySmall,
            ),
            if (onRetry != null) ...[
              CivicFixSpacing.vSpaceXl,
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
