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
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_stat_card.dart';
import '../widgets/settings/language_selector_sheet.dart';

/// Citizen Profile Screen with real-time reactive user state, civic contribution stats, and settings navigation.
class ProfileScreen extends StatefulWidget {
  final UserRepository? repository;
  final AuthService? authService;

  const ProfileScreen({
    super.key,
    this.repository,
    this.authService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepository;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.repository ?? MockUserRepository();
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
              Navigator.pop(ctx);
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
        title: 'Citizen Profile',
        automaticallyImplyLeading: false,
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
                    // 1. Profile Header Card (Avatar + Details + Edit Button)
                    ProfileHeader(
                      user: user,
                      onEditPressed: () async {
                        await Navigator.pushNamed(context, AppRoutes.editProfile);
                      },
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // 2. Civic Contribution 3-Column Metrics Card
                    ProfileStatCard(
                      reportsSubmitted: user.reportsSubmitted,
                      reportsResolved: user.reportsResolved,
                      civicPoints: user.civicPoints,
                      onRewardsTap: () => Navigator.pushNamed(context, AppRoutes.rewards),
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // 3. Civic Engagement & Services
                    const SectionHeader(title: 'Civic Engagement'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.stars_rounded,
                            title: 'Civic Rewards & Achievements',
                            subtitle: '${user.civicPoints} points • View Milestones',
                            iconColor: CivicFixColors.alertDark,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.rewards),
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.smart_toy_outlined,
                            title: 'Civic Assistant',
                            subtitle: 'FAQ, complaint rules & category help',
                            iconColor: CivicFixColors.primary,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.assistant),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // 4. Account Settings & Preferences
                    const SectionHeader(title: 'Settings & Privacy'),
                    CivicFixSpacing.vSpaceSm,
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.language_rounded,
                            title: 'Language',
                            subtitle: user.languageName,
                            onTap: () async {
                              await LanguageSelectorSheet.show(
                                context,
                                currentCode: user.languageCode,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notification Preferences',
                            subtitle: 'Status alerts, hazard warnings & sound',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.notificationSettings),
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy & Safety',
                            subtitle: 'Confidentiality and public map policy',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About CivicFix',
                            subtitle: 'Mission, governance & technology',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // 5. Logout Button
                    CivicFixCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.logout_rounded, color: CivicFixColors.error),
                        title: Text(
                          'Log Out',
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            color: CivicFixColors.error,
                            fontWeight: FontWeight.w700,
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? CivicFixColors.primary, size: 22),
      title: Text(
        title,
        style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: CivicFixColors.secondaryText, size: 20),
      onTap: onTap,
    );
  }
}
