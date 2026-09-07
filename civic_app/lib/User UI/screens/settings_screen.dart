import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';
import '../services/mock_auth_service.dart';
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
    _userRepository = widget.userRepository ?? MockUserRepository();
    _authService = widget.authService ?? MockAuthService();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.cardRadius),
        title: Text(
          'Log out?',
          style: CivicFixTypography.h3.copyWith(
            color: CivicFixColors.primaryText,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: CivicFixTypography.bodySmall.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'Settings',
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
                    const SectionHeader(title: 'Account & Preferences'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.language_rounded,
                            title: 'Preferred Language',
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
                            title: 'Notification Preferences',
                            subtitle: 'Status alerts, hazard warnings & sound',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.notificationSettings),
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy & Safety',
                            subtitle: 'Confidentiality and public map policy',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // Appearance Section
                    const SectionHeader(title: 'Appearance'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.palette_outlined, color: CivicFixColors.primary),
                        title: Text(
                          'Theme Mode',
                          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          _selectedTheme,
                          style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTheme,
                            items: const [
                              DropdownMenuItem(value: 'System Default', child: Text('System Default')),
                              DropdownMenuItem(value: 'Light Theme', child: Text('Light Theme')),
                              DropdownMenuItem(value: 'Dark Theme', child: Text('Dark Theme')),
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
                    const SectionHeader(title: 'About'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About CivicFix',
                            subtitle: 'Mission, governance model, and technology',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.verified_outlined, color: CivicFixColors.primary),
                            title: Text(
                              'App Version',
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
                    const SectionHeader(title: 'Actions'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.logout_rounded, color: CivicFixColors.error),
                        title: Text(
                          'Log Out',
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
