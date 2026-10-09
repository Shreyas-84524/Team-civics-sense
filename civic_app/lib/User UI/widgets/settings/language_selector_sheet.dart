import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';

/// Legacy alias for [AppLocale] for backwards compatibility with existing UI tests.
class LanguageOption {
  final String code;
  final String englishName;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  factory LanguageOption.fromAppLocale(AppLocale locale) => LanguageOption(
        code: locale.languageCode,
        englishName: locale.englishName,
        nativeName: locale.nativeName,
      );
}

/// Modal bottom sheet for choosing application display language.
class LanguageSelectorSheet extends StatelessWidget {
  final LocaleController? localeController;
  final String currentLanguageCode;
  final ValueChanged<String>? onLanguageSelected;

  const LanguageSelectorSheet({
    super.key,
    this.localeController,
    required this.currentLanguageCode,
    this.onLanguageSelected,
  });

  static List<LanguageOption> get supportedLanguages =>
      AppLocale.values.map(LanguageOption.fromAppLocale).toList();

  static Future<String?> show(
    BuildContext context, {
    required String currentCode,
    LocaleController? localeController,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: CivicFixRadius.sheetRadius,
      ),
      builder: (_) => LanguageSelectorSheet(
        localeController: localeController,
        currentLanguageCode: currentCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.lg,
          vertical: CivicFixSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar with Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CivicFixColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            CivicFixSpacing.vSpaceMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.selectLanguage ?? 'Select Language',
                  style: CivicFixTypography.h3.copyWith(
                    color: CivicFixColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Choose your preferred language for reports and assistant.',
              style: CivicFixTypography.caption.copyWith(
                color: CivicFixColors.secondaryText,
              ),
            ),
            CivicFixSpacing.vSpaceMd,

            // Reusable Language Options List
            LanguageSelectorWidget(
              localeController: localeController,
              currentLanguageCode: currentLanguageCode,
              showHeader: false,
              onLanguageSelected: (selectedLocale) {
                onLanguageSelected?.call(selectedLocale.languageCode);
                Navigator.pop(context, selectedLocale.languageCode);
              },
            ),
            CivicFixSpacing.vSpaceSm,
          ],
        ),
      ),
    );
  }
}
