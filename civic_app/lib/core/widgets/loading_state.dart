import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Standardized loading state indicator.
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({
    super.key,
    this.message,
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
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(CivicFixColors.primary),
              strokeWidth: 3,
            ),
            if (message != null) ...[
              CivicFixSpacing.vSpaceLg,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: CivicFixTypography.bodySmall.copyWith(
                  color: CivicFixColors.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
