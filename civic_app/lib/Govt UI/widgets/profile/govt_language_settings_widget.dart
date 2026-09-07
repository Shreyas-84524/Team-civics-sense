import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/govt_settings_model.dart';
import '../../services/govt_user_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Language and Regional Settings Selector for Government Portal.
class GovtLanguageSettingsWidget extends StatefulWidget {
  final GovernmentUserRepository? userRepository;

  const GovtLanguageSettingsWidget({
    super.key,
    this.userRepository,
  });

  @override
  State<GovtLanguageSettingsWidget> createState() => _GovtLanguageSettingsWidgetState();
}

class _GovtLanguageSettingsWidgetState extends State<GovtLanguageSettingsWidget> {
  late final GovernmentUserRepository _userRepo;

  @override
  void initState() {
    super.initState();
    _userRepo = widget.userRepository ?? MockGovernmentUserRepository();
  }

  void _selectLanguage(GovtLanguage language) {
    _userRepo.updateLanguage(language);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Portal language changed to ${language.label} (${language.localizedDisplay}).'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GovtSettingsModel>(
      valueListenable: _userRepo.settingsListenable,
      builder: (context, settings, _) {
        final currentLang = settings.language;

        return DashboardCard(
          title: 'Language & Regional Localization',
          subtitle: 'Select your preferred official working language for dashboards and reports',
          child: Column(
            children: GovtLanguage.values.map((lang) {
              final isSelected = lang == currentLang;

              return InkWell(
                onTap: () => _selectLanguage(lang),
                borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicFixSpacing.md,
                    vertical: CivicFixSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? GovtThemeTokens.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                    border: Border.all(
                      color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ignore: deprecated_member_use
                      Radio<GovtLanguage>(
                        value: lang,
                        // ignore: deprecated_member_use
                        groupValue: currentLang,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          if (val != null) _selectLanguage(val);
                        },
                        activeColor: GovtThemeTokens.primary,
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.localizedDisplay,
                              style: CivicFixTypography.bodySmallMedium.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Language Code: [${lang.code.toUpperCase()}] • Official Municipal Script',
                              style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: GovtThemeTokens.primary, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
