import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Confirmation dialog when citizen attempts to leave a report with unsaved entered data.
class DiscardReportDialog extends StatelessWidget {
  const DiscardReportDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const DiscardReportDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: CivicFixRadius.largeContainerRadius,
      ),
      backgroundColor: CivicFixColors.surface,
      title: Text(
        l10n?.discardReportTitle ?? 'Discard this report?',
        style: CivicFixTypography.h3,
      ),
      content: Text(
        l10n?.discardReportMessage ?? 'Your entered information will be lost.',
        style: CivicFixTypography.bodySmall.copyWith(
          color: CivicFixColors.secondaryText,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        CivicFixSpacing.lg,
        0,
        CivicFixSpacing.lg,
        CivicFixSpacing.lg,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: CivicFixColors.primaryText,
          ),
          child: Text(l10n?.keepEditing ?? 'Keep Editing'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: CivicFixColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: CivicFixRadius.buttonRadius,
            ),
          ),
          child: Text(l10n?.discard ?? 'Discard'),
        ),
      ],
    );
  }
}
