import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Clean confirmation modal for critical government actions (status updates, assignments, logout).
class GovtConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final Widget? content;

  const GovtConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.isDestructive = false,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: GovtThemeTokens.cardRadius,
      ),
      backgroundColor: GovtThemeTokens.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? const Color(0xFFFDE8E8)
                          : const Color(0xFFE8F8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDestructive ? Icons.warning_rounded : Icons.info_outline_rounded,
                      color: isDestructive ? GovtThemeTokens.error : GovtThemeTokens.secondary,
                      size: 20,
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  Expanded(
                    child: Text(
                      title,
                      style: CivicFixTypography.h3.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceMd,
              Text(
                message,
                style: CivicFixTypography.bodySmall.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  height: 1.45,
                ),
              ),
              if (content != null) ...[
                CivicFixSpacing.vSpaceMd,
                content!,
              ],
              CivicFixSpacing.vSpaceXl,
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CivicFixSpacing.md,
                runSpacing: CivicFixSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GovtThemeTokens.textSecondary,
                      side: const BorderSide(color: GovtThemeTokens.border),
                      minimumSize: const Size(0, 38),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CivicFixSpacing.md,
                        vertical: CivicFixSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: GovtThemeTokens.buttonRadius,
                      ),
                    ),
                    child: Text(cancelLabel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? GovtThemeTokens.error : GovtThemeTokens.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 38),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CivicFixSpacing.lg,
                        vertical: CivicFixSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: GovtThemeTokens.buttonRadius,
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
