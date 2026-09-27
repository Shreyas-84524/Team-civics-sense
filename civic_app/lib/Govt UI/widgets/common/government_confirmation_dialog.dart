import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Semantic confirmation modal dialog type.
enum GovtDialogType {
  neutral,
  warning,
  destructive,
  confirmation;

  Color get color {
    switch (this) {
      case GovtDialogType.neutral:
        return GovtThemeTokens.primary;
      case GovtDialogType.warning:
        return const Color(0xFFD97706);
      case GovtDialogType.destructive:
        return GovtThemeTokens.error;
      case GovtDialogType.confirmation:
        return GovtThemeTokens.secondary;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case GovtDialogType.neutral:
        return const Color(0xFFE8F2F8);
      case GovtDialogType.warning:
        return const Color(0xFFFEF8EC);
      case GovtDialogType.destructive:
        return const Color(0xFFFDE8E8);
      case GovtDialogType.confirmation:
        return const Color(0xFFE8F8F0);
    }
  }

  IconData get icon {
    switch (this) {
      case GovtDialogType.neutral:
        return Icons.info_outline_rounded;
      case GovtDialogType.warning:
        return Icons.warning_amber_rounded;
      case GovtDialogType.destructive:
        return Icons.delete_outline_rounded;
      case GovtDialogType.confirmation:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Professional confirmation dialog for municipal administrative actions.
class GovernmentConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final GovtDialogType type;
  final Widget? content;

  const GovernmentConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.type = GovtDialogType.confirmation,
    this.content,
  });

  /// Factory for destructive actions (e.g. Reject, Cancel, Delete, Sign Out).
  factory GovernmentConfirmationDialog.destructive({
    required String title,
    required String message,
    String confirmLabel = 'Proceed',
    String cancelLabel = 'Cancel',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    Widget? content,
  }) {
    return GovernmentConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      type: GovtDialogType.destructive,
      content: content,
    );
  }

  /// Factory for warning actions (e.g. Reassign, Escalate).
  factory GovernmentConfirmationDialog.warning({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    Widget? content,
  }) {
    return GovernmentConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      type: GovtDialogType.warning,
      content: content,
    );
  }

  /// Shows this dialog conveniently with standard sizing.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    required VoidCallback onConfirm,
    GovtDialogType type = GovtDialogType.confirmation,
    Widget? content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => GovernmentConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        type: type,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: GovtThemeTokens.cardRadius,
      ),
      backgroundColor: GovtThemeTokens.surface,
      elevation: 6,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: type.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      type.icon,
                      color: type.color,
                      size: 20,
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GovtTypography.sectionTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        CivicFixSpacing.vSpaceSm,
                        Text(
                          message,
                          style: GovtTypography.bodySmall.copyWith(
                            color: GovtThemeTokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (content != null) ...[
                CivicFixSpacing.vSpaceMd,
                content!,
              ],
              CivicFixSpacing.vSpaceXl,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      if (onCancel != null) onCancel!();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GovtThemeTokens.textSecondary,
                      side: const BorderSide(color: GovtThemeTokens.border),
                      minimumSize: const Size(80, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: GovtThemeTokens.buttonRadius,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: CivicFixSpacing.lg,
                        vertical: CivicFixSpacing.sm,
                      ),
                    ),
                    child: Text(cancelLabel),
                  ),
                  CivicFixSpacing.hSpaceSm,
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: type.color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(90, 38),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: GovtThemeTokens.buttonRadius,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: CivicFixSpacing.xl,
                        vertical: CivicFixSpacing.sm,
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
