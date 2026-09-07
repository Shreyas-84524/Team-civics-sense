import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Reusable accessible authentication error banner.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: CivicFixSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.md,
        vertical: CivicFixSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: CivicFixColors.errorLight,
        borderRadius: CivicFixRadius.cardRadius,
        border: Border.all(
          color: CivicFixColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: CivicFixColors.error,
            size: 20,
          ),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Text(
              message,
              style: CivicFixTypography.bodySmallMedium.copyWith(
                color: CivicFixColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: CivicFixColors.error),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Dismiss message',
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
