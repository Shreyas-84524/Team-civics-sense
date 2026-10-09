import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../models/govt_user_model.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'govt_notification_panel.dart';
import 'govt_profile_menu.dart';

/// Top Application Bar for Government Web, Desktop, Tablet, and Mobile Views.
class GovtAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final GovtUserModel? user;
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onHelpTap;
  final int unreadNotificationsCount;

  const GovtAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.user,
    this.onMenuPressed,
    this.showMenuButton = false,
    this.onSearchTap,
    this.onNotificationTap,
    this.onHelpTap,
    this.unreadNotificationsCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(GovtThemeTokens.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = GovtResponsive.isMobile(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isNarrow = availableWidth < 600;
        final showHelp = availableWidth >= 750;
        final isCompactProfile = availableWidth < 950;

        return Container(
          height: GovtThemeTokens.topBarHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? CivicFixSpacing.sm : CivicFixSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: GovtThemeTokens.surface,
            border: GovtThemeTokens.bottomBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mobile Menu Drawer Button
              if (showMenuButton) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: GovtThemeTokens.textPrimary),
                  onPressed: onMenuPressed,
                  visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
                  tooltip: 'Toggle Navigation Drawer',
                ),
                CivicFixSpacing.hSpaceXs,
              ],

              // Title & Operational Hierarchy
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GovtTypography.pageTitle.copyWith(
                        fontSize: (isMobileScreen || isNarrow) ? 16 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Custom Actions
              ...?actions,

              // Notification Bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: GovtThemeTokens.textSecondary),
                    visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
                    onPressed: onNotificationTap ??
                        () {
                          GovtNotificationPanel.show(context);
                        },
                    tooltip: 'Notifications',
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: GovtThemeTokens.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              // Optional Help Button
              if (showHelp) ...[
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded,
                      color: GovtThemeTokens.textSecondary),
                  onPressed: onHelpTap ?? () {},
                  tooltip: 'Municipal Help & SOP Documentation',
                ),
              ],

              // User Profile Menu
              CivicFixSpacing.hSpaceXs,
              GovtProfileMenu(
                user: user,
                isCompact: isCompactProfile,
              ),

              // Custom Actions if supplied
              if (actions != null && actions!.isNotEmpty) ...[
                CivicFixSpacing.hSpaceXs,
                ...actions!,
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Backwards compatibility typedef
typedef GovernmentAppBar = GovtAppBar;
