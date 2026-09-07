import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../models/notification_model.dart';

/// In-app banner and notification presenter for Phase 1.
class MockNotificationService {
  MockNotificationService._();

  static void showInAppAlert(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.statusUpdate,
    VoidCallback? onTap,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(CivicFixSpacing.lg),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: CivicFixColors.primary,
            borderRadius: CivicFixRadius.cardRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CivicFixSpacing.sm),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.2),
                  borderRadius: CivicFixRadius.chipRadius,
                ),
                child: Icon(
                  type.icon,
                  color: Colors.white,
                  size: 20,
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
                        color: Colors.white,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      message,
                      style: CivicFixTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                TextButton(
                  onPressed: () {
                    scaffoldMessenger.hideCurrentSnackBar();
                    onTap();
                  },
                  child: Text(
                    'VIEW',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: CivicFixColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
