import 'package:flutter/material.dart';
import '../../../core/auth/auth_service_locator.dart';
import '../../../core/constants/app_spacing.dart';
import '../../models/govt_user_model.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'government_confirmation_dialog.dart';
import 'govt_jurisdiction_badge.dart';

/// Reusable user profile dropdown menu for top app bars and headers.
class GovtProfileMenu extends StatelessWidget {
  final GovtUserModel? user;
  final VoidCallback? onProfileSelected;
  final VoidCallback? onSettingsSelected;
  final VoidCallback? onLogout;
  final bool isCompact;

  const GovtProfileMenu({
    super.key,
    this.user,
    this.onProfileSelected,
    this.onSettingsSelected,
    this.onLogout,
    this.isCompact = false,
  });

  void _handleLogout(BuildContext context) {
    if (onLogout != null) {
      onLogout!();
      return;
    }

    GovernmentConfirmationDialog.show(
      context,
      title: 'Sign Out Officer Session',
      message:
          'Are you sure you want to end your active session on the CivicFix Government Portal?',
      confirmLabel: 'Sign Out',
      type: GovtDialogType.destructive,
      onConfirm: () async {
        final auth = AuthServiceLocator.govtAuth;
        await auth.logout();
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            '/govt/login',
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName ?? 'Officer Session';
    final designation = user?.displayDesignation ?? 'Municipal Personnel';
    final roleName = user?.govtRole.displayName ?? 'Government Officer';
    final jurisdiction = user?.wardId != null && user!.wardId!.isNotEmpty
        ? user!.wardId!
        : (user?.zoneId != null ? 'Zone ${user!.zoneId}' : 'Citywide');

    return PopupMenuButton<String>(
      tooltip: 'Officer Profile & Options',
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: GovtThemeTokens.cardRadius,
        side: const BorderSide(color: GovtThemeTokens.border),
      ),
      elevation: 6,
      color: GovtThemeTokens.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.sm + 2,
          vertical: CivicFixSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: GovtThemeTokens.primary,
              child: Text(
                user?.initials ?? 'GO',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!isCompact) ...[
              CivicFixSpacing.hSpaceSm,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GovtTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    Text(
                      designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GovtTypography.caption.copyWith(
                        fontSize: 10,
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: GovtThemeTokens.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
      onSelected: (val) {
        switch (val) {
          case 'profile':
            if (onProfileSelected != null) {
              onProfileSelected!();
            } else {
              Navigator.of(context).pushNamed('/govt/profile');
            }
            break;
          case 'settings':
            if (onSettingsSelected != null) {
              onSettingsSelected!();
            } else {
              Navigator.of(context).pushNamed('/govt/profile');
            }
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
      itemBuilder: (ctx) => [
        // Header tile with role and jurisdiction
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: GovtTypography.cardTitle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                roleName,
                style: GovtTypography.caption.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              GovtJurisdictionBadge(
                label: jurisdiction,
                type: user?.wardId != null
                    ? GovtJurisdictionType.ward
                    : GovtJurisdictionType.zone,
                isCompact: true,
              ),
              CivicFixSpacing.vSpaceSm,
              const Divider(color: GovtThemeTokens.borderLight, height: 1),
            ],
          ),
        ),

        // Profile Item
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: GovtThemeTokens.textPrimary),
              SizedBox(width: 12),
              Text('Officer Profile'),
            ],
          ),
        ),

        // Settings Item
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18, color: GovtThemeTokens.textPrimary),
              SizedBox(width: 12),
              Text('Operational Settings'),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // Sign Out Item
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: GovtThemeTokens.error),
              SizedBox(width: 12),
              Text(
                'Sign Out Session',
                style: TextStyle(color: GovtThemeTokens.error, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
