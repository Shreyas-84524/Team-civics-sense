import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/app_routes.dart';
import '../../models/department_model.dart';
import '../../models/govt_user_model.dart';
import '../../services/govt_auth_service.dart';
import '../../services/govt_user_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_confirmation_dialog.dart';
import '../../widgets/dashboard/dashboard_card.dart';
import '../../widgets/profile/govt_about_widget.dart';
import '../../widgets/profile/govt_appearance_settings_widget.dart';
import '../../widgets/profile/govt_edit_profile_dialog.dart';
import '../../widgets/profile/govt_language_settings_widget.dart';
import '../../widgets/profile/govt_notification_settings_widget.dart';
import '../../widgets/profile/govt_privacy_principles_widget.dart';

/// Government Officer Profile, Edit Profile, and Settings Screen.
class GovtProfileScreen extends StatefulWidget {
  final GovtAuthService? authService;
  final GovernmentUserRepository? userRepository;

  const GovtProfileScreen({
    super.key,
    this.authService,
    this.userRepository,
  });

  @override
  State<GovtProfileScreen> createState() => _GovtProfileScreenState();
}

class _GovtProfileScreenState extends State<GovtProfileScreen> {
  late final GovtAuthService _authService;
  late final GovernmentUserRepository _userRepo;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? MockGovtAuthService();
    _userRepo = widget.userRepository ?? MockGovernmentUserRepository();
  }

  void _openEditProfileDialog(GovtUserModel user) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => GovtEditProfileDialog(
        user: user,
        userRepository: _userRepo,
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => GovtConfirmationDialog(
        title: 'Sign Out Officer Session',
        message: 'Are you sure you want to end your active administrative session?',
        confirmLabel: 'Sign Out',
        isDestructive: true,
        onConfirm: () async {
          await _authService.logout();
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pushReplacementNamed(AppRoutes.govtLogin);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GovtUserModel?>(
      valueListenable: _authService.userListenable,
      builder: (context, user, _) {
        if (user == null) {
          return const Center(child: Text('No active government session.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Officer Identity Card
                  _buildOfficerHeaderCard(user),
                  CivicFixSpacing.vSpaceLg,

                  // Active Department & Jurisdiction Switcher
                  _buildJurisdictionSwitcherCard(user),
                  CivicFixSpacing.vSpaceLg,

                  // Authorized Role & System Permissions
                  _buildPermissionsCard(user),
                  CivicFixSpacing.vSpaceLg,

                  // Notification Preferences
                  GovtNotificationSettingsWidget(userRepository: _userRepo),
                  CivicFixSpacing.vSpaceLg,

                  // Language & Regional Localization
                  GovtLanguageSettingsWidget(userRepository: _userRepo),
                  CivicFixSpacing.vSpaceLg,

                  // Appearance & Layout Density
                  GovtAppearanceSettingsWidget(userRepository: _userRepo),
                  CivicFixSpacing.vSpaceLg,

                  // Privacy Principles
                  const GovtPrivacyPrinciplesWidget(),
                  CivicFixSpacing.vSpaceLg,

                  // About & Version
                  const GovtAboutWidget(),
                  CivicFixSpacing.vSpaceXl,

                  // End Officer Session
                  _buildSignOutSection(),
                  CivicFixSpacing.vSpaceLg,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfficerHeaderCard(GovtUserModel user) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: GovtThemeTokens.primary,
                child: Text(
                  user.initials,
                  style: CivicFixTypography.h2.copyWith(color: Colors.white),
                ),
              ),
              CivicFixSpacing.hSpaceLg,
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: CivicFixTypography.h2.copyWith(fontSize: 22),
                          ),
                        ),
                        // Role Badge (strictly non-editable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GovtThemeTokens.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                            border: Border.all(color: GovtThemeTokens.secondary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, size: 14, color: GovtThemeTokens.secondary),
                              CivicFixSpacing.hSpaceXs,
                              Text(
                                'OFFICER ROLE',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: GovtThemeTokens.secondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      '${user.designation} • ${user.departmentName}',
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      'Organization: ${user.organization}',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.border),
          CivicFixSpacing.vSpaceSm,

          // Metadata Grid
          Wrap(
            spacing: CivicFixSpacing.lg,
            runSpacing: CivicFixSpacing.sm,
            children: [
              _buildMetaTile(Icons.email_outlined, 'Email', user.email),
              _buildMetaTile(Icons.phone_outlined, 'Phone', user.phone),
              _buildMetaTile(Icons.badge_outlined, 'Employee ID', user.employeeId),
              _buildMetaTile(Icons.location_on_outlined, 'Assigned Ward', user.assignedWard),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // Edit Profile Action
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _openEditProfileDialog(user),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GovtThemeTokens.primary,
                side: const BorderSide(color: GovtThemeTokens.primary),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTile(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: GovtThemeTokens.textSecondary),
        CivicFixSpacing.hSpaceXs,
        Text('$label: ', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary)),
        Text(value, style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildJurisdictionSwitcherCard(GovtUserModel user) {
    return DashboardCard(
      title: 'Active Municipal Jurisdiction & Department',
      subtitle: 'Switch assigned department to filter grievances and hazard maps',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department:', style: CivicFixTypography.captionMedium),
          CivicFixSpacing.vSpaceXs,
          DropdownButtonFormField<String>(
            initialValue: user.departmentId,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: GovtThemeTokens.surface,
              border: OutlineInputBorder(
                borderRadius: GovtThemeTokens.chipRadius,
                borderSide: const BorderSide(color: GovtThemeTokens.border),
              ),
            ),
            items: GovtDepartmentModel.defaultDepartments.map((dept) {
              return DropdownMenuItem<String>(
                value: dept.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(dept.icon, size: 18, color: GovtThemeTokens.primary),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      dept.name,
                      style: CivicFixTypography.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final found = GovtDepartmentModel.defaultDepartments.firstWhere((d) => d.id == val);
                _authService.switchDepartment(found.id, found.name);
              }
            },
          ),
          CivicFixSpacing.vSpaceMd,
          Text('Assigned Zone: ${user.assignedWard}', style: CivicFixTypography.bodySmallMedium),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(GovtUserModel user) {
    return DashboardCard(
      title: 'Role-Based Access & Permissions',
      subtitle: 'Verified operational permissions associated with municipal account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: user.permissions.map((perm) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: GovtThemeTokens.secondary, size: 16),
                CivicFixSpacing.hSpaceSm,
                Text(
                  perm.replaceAll('_', ' ').toUpperCase(),
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignOutSection() {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(GovtThemeTokens.radiusMd),
        border: Border.all(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GovtThemeTokens.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
            ),
            child: const Icon(Icons.logout_rounded, color: GovtThemeTokens.error, size: 24),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('End Administrative Session', style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700)),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Safely terminate session on this device. Citizen UI session remains unaffected.',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ],
            ),
          ),
          CivicFixSpacing.hSpaceMd,
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovtThemeTokens.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.xl,
                vertical: CivicFixSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
