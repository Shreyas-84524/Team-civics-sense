import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_radius.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../repositories/repository_locator.dart';
import '../app_localizations.dart';
import '../locale_controller.dart';

/// Reusable Language Selector Component for CivicFix.
///
/// Supports:
/// - English (`en`)
/// - हिन्दी (`hi`)
/// - मराठी (`mr`)
///
/// Can be rendered inline (e.g. inside settings/profile screens) or within modal sheets/dialogs.
class LanguageSelectorWidget extends StatelessWidget {
  /// Optional [LocaleController] to control (defaults to [LocaleController.instance]).
  final LocaleController? localeController;

  /// The currently selected [AppLocale] or ISO 639-1 code.
  final String? currentLanguageCode;

  /// Callback invoked when a new language is selected.
  final ValueChanged<AppLocale>? onLanguageSelected;

  /// Whether to show the header title and description.
  final bool showHeader;

  /// Optional custom padding.
  final EdgeInsetsGeometry? padding;

  const LanguageSelectorWidget({
    super.key,
    this.localeController,
    this.currentLanguageCode,
    this.onLanguageSelected,
    this.showHeader = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final controller = localeController ?? LocaleController.instance;
    final activeCode = (currentLanguageCode ?? controller.currentLanguageCode).toLowerCase().trim();
    final l10n = context.l10nOrNull;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              l10n?.selectLanguage ?? 'Select Language',
              style: CivicFixTypography.h3.copyWith(
                color: CivicFixColors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            CivicFixSpacing.vSpaceXs,
            Text(
              'Choose your preferred language for reports, interface, and assistant.',
              style: CivicFixTypography.caption.copyWith(
                color: CivicFixColors.secondaryText,
              ),
            ),
            CivicFixSpacing.vSpaceMd,
          ],
          ...AppLocale.values.map((locale) {
            final isSelected = locale.languageCode == activeCode;

            return Padding(
              padding: const EdgeInsets.only(bottom: CivicFixSpacing.sm),
              child: Semantics(
                label: '${locale.englishName} (${locale.nativeName}), ${isSelected ? "selected" : "not selected"}',
                selected: isSelected,
                button: true,
                child: InkWell(
                  onTap: () async {
                    // 1. Immediately switch runtime locale without app restart
                    await controller.setAppLocale(locale);

                    // 2. Asynchronously sync to citizen profile if repository is initialized
                    try {
                      RepositoryLocator.userRepository.updateUserProfile(languageCode: locale.languageCode);
                    } catch (_) {}

                    // 3. Trigger consumer callback
                    onLanguageSelected?.call(locale);
                  },
                  borderRadius: CivicFixRadius.cardRadius,
                  child: Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CivicFixColors.accentLight.withValues(alpha: 0.5)
                          : CivicFixColors.surfaceMuted,
                      borderRadius: CivicFixRadius.cardRadius,
                      border: Border.all(
                        color: isSelected
                            ? CivicFixColors.secondary
                            : CivicFixColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? CivicFixColors.secondary
                              : CivicFixColors.disabledText,
                          size: 20,
                        ),
                        CivicFixSpacing.hSpaceMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.nativeName,
                                style: CivicFixTypography.bodySmallMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: CivicFixColors.primaryText,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                locale.englishName,
                                style: CivicFixTypography.caption.copyWith(
                                  color: CivicFixColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            color: CivicFixColors.secondary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
