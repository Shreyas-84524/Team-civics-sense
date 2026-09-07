import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/repositories/user_repository.dart';

class LanguageOption {
  final String code;
  final String englishName;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });
}

/// Modal bottom sheet for choosing application display language.
class LanguageSelectorSheet extends StatelessWidget {
  final String currentLanguageCode;
  final ValueChanged<String>? onLanguageSelected;

  const LanguageSelectorSheet({
    super.key,
    required this.currentLanguageCode,
    this.onLanguageSelected,
  });

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', englishName: 'English', nativeName: 'English'),
    LanguageOption(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
    LanguageOption(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
  ];

  static Future<String?> show(BuildContext context, {required String currentCode}) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: CivicFixRadius.sheetRadius,
      ),
      builder: (_) => LanguageSelectorSheet(currentLanguageCode: currentCode),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Select Language',
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

            // Language Options List
            ...supportedLanguages.map((option) {
              final isSelected = option.code == currentLanguageCode;

              return Padding(
                padding: const EdgeInsets.only(bottom: CivicFixSpacing.sm),
                child: Semantics(
                  label: '${option.englishName} (${option.nativeName}), ${isSelected ? "selected" : "not selected"}',
                  selected: isSelected,
                  button: true,
                  child: InkWell(
                    onTap: () {
                      MockUserRepository().updateUserProfile(languageCode: option.code);
                      onLanguageSelected?.call(option.code);
                      Navigator.pop(context, option.code);
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
                          width: isSelected ? 1.5 : 1,
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
                                  option.nativeName,
                                  style: CivicFixTypography.bodySmallMedium.copyWith(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? CivicFixColors.primaryText
                                        : CivicFixColors.primaryText,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  option.englishName,
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
            CivicFixSpacing.vSpaceMd,
          ],
        ),
      ),
    );
  }
}
