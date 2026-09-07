import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/govt_settings_model.dart';
import '../../services/govt_user_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Appearance and Workspace Density Preferences for Government Portal.
class GovtAppearanceSettingsWidget extends StatefulWidget {
  final GovernmentUserRepository? userRepository;

  const GovtAppearanceSettingsWidget({
    super.key,
    this.userRepository,
  });

  @override
  State<GovtAppearanceSettingsWidget> createState() => _GovtAppearanceSettingsWidgetState();
}

class _GovtAppearanceSettingsWidgetState extends State<GovtAppearanceSettingsWidget> {
  late final GovernmentUserRepository _userRepo;

  @override
  void initState() {
    super.initState();
    _userRepo = widget.userRepository ?? MockGovernmentUserRepository();
  }

  void _updateThemeMode(GovtPortalThemeMode mode) {
    _userRepo.updateAppearance(themeMode: mode);
  }

  void _updateDensity(GovtLayoutDensity density) {
    _userRepo.updateAppearance(density: density);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GovtSettingsModel>(
      valueListenable: _userRepo.settingsListenable,
      builder: (context, settings, _) {
        return DashboardCard(
          title: 'Display & Workspace Density',
          subtitle: 'Customize interface contrast and visual density for operational efficiency',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Theme Mode', style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
              CivicFixSpacing.vSpaceSm,
              Row(
                children: GovtPortalThemeMode.values.map((mode) {
                  final isSelected = mode == settings.themeMode;
                  IconData icon;
                  switch (mode) {
                    case GovtPortalThemeMode.system:
                      icon = Icons.settings_brightness_rounded;
                      break;
                    case GovtPortalThemeMode.light:
                      icon = Icons.light_mode_rounded;
                      break;
                    case GovtPortalThemeMode.dark:
                      icon = Icons.dark_mode_rounded;
                      break;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => _updateThemeMode(mode),
                        borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: CivicFixSpacing.md,
                            horizontal: CivicFixSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? GovtThemeTokens.primary.withValues(alpha: 0.08) : GovtThemeTokens.surfaceVariant,
                            borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                            border: Border.all(
                              color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.textSecondary,
                                size: 22,
                              ),
                              CivicFixSpacing.vSpaceXs,
                              Text(
                                mode.title,
                                textAlign: TextAlign.center,
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              CivicFixSpacing.vSpaceLg,

              Text('Table & Card Density', style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
              CivicFixSpacing.vSpaceSm,
              Row(
                children: GovtLayoutDensity.values.map((density) {
                  final isSelected = density == settings.density;
                  final icon = density == GovtLayoutDensity.comfortable
                      ? Icons.view_comfortable_rounded
                      : Icons.view_compact_rounded;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => _updateDensity(density),
                        borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: CivicFixSpacing.md,
                            horizontal: CivicFixSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? GovtThemeTokens.primary.withValues(alpha: 0.08) : GovtThemeTokens.surfaceVariant,
                            borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                            border: Border.all(
                              color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.textSecondary,
                                size: 22,
                              ),
                              CivicFixSpacing.vSpaceXs,
                              Text(
                                density.title,
                                textAlign: TextAlign.center,
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: isSelected ? GovtThemeTokens.primary : GovtThemeTokens.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
