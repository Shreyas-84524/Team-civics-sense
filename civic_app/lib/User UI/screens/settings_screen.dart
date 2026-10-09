import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';
import '../widgets/settings/language_selector_sheet.dart';

/// Citizen Settings and Preferences Screen.
class SettingsScreen extends StatefulWidget {
  final UserRepository? userRepository;
  final AuthService? authService;

  const SettingsScreen({
    super.key,
    this.userRepository,
    this.authService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final UserRepository _userRepository;
  late final AuthService _authService;
  String _selectedTheme = 'System Default';

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? RepositoryLocator.userRepository;
    _authService = widget.authService ?? AuthServiceLocator.citizenAuth;
  }

  void _showLogoutConfirmation() {
    final l10n = context.l10nOrNull;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.cardRadius),
        title: Text(
          l10n?.logoutConfirmationTitle ?? 'Log out?',
          style: CivicFixTypography.h3.copyWith(
            color: CivicFixColors.primaryText,
          ),
        ),
        content: Text(
          l10n?.logoutConfirmationMessage ?? 'Are you sure you want to log out?',
          style: CivicFixTypography.bodySmall.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.commonCancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await _authService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CivicFixColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n?.logout ?? 'Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: CivicFixAppBar(
        title: l10n?.settingsTitle ?? 'Settings',
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: ValueListenableBuilder<UserModel>(
            valueListenable: _userRepository.getUserListenable(),
            builder: (context, user, _) {
              return SingleChildScrollView(
                padding: CivicFixSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Section
                    SectionHeader(title: l10n?.accountAndPreferences ?? 'Account & Preferences'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.language_rounded,
                            title: l10n?.preferredLanguage ?? 'Preferred Language',
                            subtitle: user.languageName,
                            onTap: () async {
                              await LanguageSelectorSheet.show(
                                context,
                                currentCode: user.languageCode,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.notifications_outlined,
                            title: l10n?.notificationPreferences ?? 'Notification Preferences',
                            subtitle: l10n?.notificationPreferencesSubtitle ?? 'Status alerts, hazard warnings & sound',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.notificationSettings),
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: l10n?.privacyAndSafety ?? 'Privacy & Safety',
                            subtitle: l10n?.privacyAndSafetySubtitle ?? 'Confidentiality and public map policy',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // Appearance Section
                    SectionHeader(title: l10n?.appearance ?? 'Appearance'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.palette_outlined, color: CivicFixColors.primary),
                        title: Text(
                          l10n?.themeMode ?? 'Theme Mode',
                          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          _selectedTheme,
                          style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTheme,
                            items: [
                              DropdownMenuItem(value: 'System Default', child: Text(l10n?.systemDefault ?? 'System Default')),
                              DropdownMenuItem(value: 'Light Theme', child: Text(l10n?.lightTheme ?? 'Light Theme')),
                              DropdownMenuItem(value: 'Dark Theme', child: Text(l10n?.darkTheme ?? 'Dark Theme')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTheme = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // About Section
                    SectionHeader(title: l10n?.aboutCivicFix ?? 'About'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: l10n?.aboutCivicFix ?? 'About CivicFix',
                            subtitle: l10n?.aboutCivicFixSubtitle ?? 'Mission, governance model, and technology',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.verified_outlined, color: CivicFixColors.primary),
                            title: Text(
                              l10n?.appVersion ?? 'App Version',
                              style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            trailing: Text(
                              '1.0.0 (Phase 1 Citizen UI)',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: CivicFixColors.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // Actions / Logout Section
                    SectionHeader(title: l10n?.actions ?? 'Actions'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.logout_rounded, color: CivicFixColors.error),
                        title: Text(
                          l10n?.logout ?? 'Log Out',
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CivicFixColors.error,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: CivicFixColors.secondaryText),
                        onTap: _showLogoutConfirmation,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXxl,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: CivicFixColors.primary),
      title: Text(
        title,
        style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: CivicFixColors.secondaryText),
      onTap: onTap,
    );
  }
}
