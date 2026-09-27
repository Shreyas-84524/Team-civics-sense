import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Supported alert severity levels.
enum GovernmentAlertType {
  info,
  success,
  warning,
  critical;

  Color get color {
    switch (this) {
      case GovernmentAlertType.info:
        return GovtThemeTokens.info;
      case GovernmentAlertType.success:
        return GovtThemeTokens.success;
      case GovernmentAlertType.warning:
        return const Color(0xFFD97706);
      case GovernmentAlertType.critical:
        return GovtThemeTokens.critical;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case GovernmentAlertType.info:
        return const Color(0xFFEFF6FF);
      case GovernmentAlertType.success:
        return const Color(0xFFECFDF5);
      case GovernmentAlertType.warning:
        return const Color(0xFFFEF9EE);
      case GovernmentAlertType.critical:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get borderColor {
    switch (this) {
      case GovernmentAlertType.info:
        return const Color(0xFFBFDBFE);
      case GovernmentAlertType.success:
        return const Color(0xFFA7F3D0);
      case GovernmentAlertType.warning:
        return const Color(0xFFFDE68A);
      case GovernmentAlertType.critical:
        return const Color(0xFFFECACA);
    }
  }

  IconData get icon {
    switch (this) {
      case GovernmentAlertType.info:
        return Icons.info_outline_rounded;
      case GovernmentAlertType.success:
        return Icons.check_circle_outline_rounded;
      case GovernmentAlertType.warning:
        return Icons.warning_amber_rounded;
      case GovernmentAlertType.critical:
        return Icons.error_outline_rounded;
    }
  }
}

/// Compact, authoritative operational banner for alerts, notifications, and SLA warnings.
class GovernmentAlert extends StatelessWidget {
  final String message;
  final String? title;
  final GovernmentAlertType type;
  final Widget? action;
  final VoidCallback? onDismiss;
  final bool isDense;

  const GovernmentAlert({
    super.key,
    required this.message,
    this.title,
    this.type = GovernmentAlertType.info,
    this.action,
    this.onDismiss,
    this.isDense = false,
  });

  factory GovernmentAlert.info({
    required String message,
    String? title,
    Widget? action,
    VoidCallback? onDismiss,
  }) =>
      GovernmentAlert(
        title: title,
        message: message,
        type: GovernmentAlertType.info,
        action: action,
        onDismiss: onDismiss,
      );

  factory GovernmentAlert.success({
    required String message,
    String? title,
    Widget? action,
    VoidCallback? onDismiss,
  }) =>
      GovernmentAlert(
        title: title,
        message: message,
        type: GovernmentAlertType.success,
        action: action,
        onDismiss: onDismiss,
      );

  factory GovernmentAlert.warning({
    required String message,
    String? title,
    Widget? action,
    VoidCallback? onDismiss,
  }) =>
      GovernmentAlert(
        title: title,
        message: message,
        type: GovernmentAlertType.warning,
        action: action,
        onDismiss: onDismiss,
      );

  factory GovernmentAlert.critical({
    required String message,
    String? title,
    Widget? action,
    VoidCallback? onDismiss,
  }) =>
      GovernmentAlert(
        title: title,
        message: message,
        type: GovernmentAlertType.critical,
        action: action,
        onDismiss: onDismiss,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.md,
        vertical: isDense ? CivicFixSpacing.xs + 2 : CivicFixSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: type.backgroundColor,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: type.borderColor),
      ),
      child: Row(
        crossAxisAlignment:
            title != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            type.icon,
            size: 18,
            color: type.color,
          ),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: GovtTypography.cardTitle.copyWith(
                      fontSize: 13,
                      color: type.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: GovtTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            CivicFixSpacing.hSpaceSm,
            action!,
          ],
          if (onDismiss != null) ...[
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: GovtThemeTokens.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: onDismiss,
              tooltip: 'Dismiss alert',
            ),
          ],
        ],
      ),
    );
  }
}
