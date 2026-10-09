import 'package:flutter/material.dart';
import '../../../core/auth/auth_service_locator.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/repositories/repository_locator.dart';
import '../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/govt_auth_service.dart';
import '../../services/govt_user_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_confirmation_dialog.dart';
import '../../widgets/dashboard/dashboard_card.dart';
import '../../widgets/profile/govt_language_settings_widget.dart';
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
    _authService = widget.authService ?? AuthServiceLocator.govtAuth;
    _userRepo = widget.userRepository ?? RepositoryLocator.govtUserRepository;
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
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              AppRoutes.govtLogin,
              (route) => false,
            );
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

                  // Authorized Role & System Permissions
                  _buildPermissionsCard(user),
                  CivicFixSpacing.vSpaceLg,

                  // Language & Regional Localization
                  GovtLanguageSettingsWidget(userRepository: _userRepo),
                  CivicFixSpacing.vSpaceLg,

                  // Privacy Principles
                  const GovtPrivacyPrinciplesWidget(),
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
                                localizedGovernmentRole(user.role, context: context).toUpperCase(),
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
                      '${user.designation} • ${localizedDepartment(user.departmentName, context: context)}',
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
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Wrap(
                spacing: CivicFixSpacing.lg,
                runSpacing: CivicFixSpacing.sm,
                children: [
                  _buildMetaTile(Icons.email_outlined, l10n?.govOfficialEmail ?? 'Email', user.email),
                  _buildMetaTile(Icons.phone_outlined, l10n?.mobileNumber ?? 'Phone', user.phone),
                  _buildMetaTile(Icons.badge_outlined, l10n?.govEmployeeId ?? 'Employee ID', user.employeeId),
                  _buildMetaTile(Icons.location_on_outlined, l10n?.govJurisdiction ?? 'Assigned Ward', user.assignedWard),
                ],
              );
            },
          ),
          CivicFixSpacing.vSpaceMd,

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
