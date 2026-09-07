import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../models/govt_user_model.dart';
import '../../services/govt_auth_service.dart';
import '../../theme/govt_theme_tokens.dart';
import 'govt_confirmation_dialog.dart';

/// Navigation item definition for Government Sidebar.
class GovtNavItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final int index;
  final String routeName;
  final int? badgeCount;

  const GovtNavItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.index,
    required this.routeName,
    this.badgeCount,
  });
}

/// Responsive Government Sidebar for Desktop and Tablet Navigation.
class GovtSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isCollapsed;
  final GovtUserModel? user;
  final VoidCallback? onLogout;

  const GovtSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isCollapsed = false,
    this.user,
    this.onLogout,
  });

  static const List<GovtNavItem> navItems = [
    GovtNavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      index: 0,
      routeName: '/govt/dashboard',
    ),
    GovtNavItem(
      title: 'Complaints',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      index: 1,
      routeName: '/govt/complaints',
      badgeCount: 24,
    ),
    GovtNavItem(
      title: 'Hazard Map',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      index: 2,
      routeName: '/govt/hazard-map',
    ),
    GovtNavItem(
      title: 'Analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      index: 3,
      routeName: '/govt/analytics',
    ),
    GovtNavItem(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      index: 4,
      routeName: '/govt/profile',
    ),
  ];

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => GovtConfirmationDialog(
        title: 'Sign Out Officer Session',
        message: 'Are you sure you want to log out of the CivicFix Municipal Administration portal?',
        confirmLabel: 'Sign Out',
        isDestructive: true,
        onConfirm: () async {
          final auth = MockGovtAuthService();
          await auth.logout();
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pushReplacementNamed('/govt/login');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed
        ? GovtThemeTokens.sidebarCollapsedWidth
        : GovtThemeTokens.sidebarWidth;

    return AnimatedContainer(
      duration: AppConstants.fastAnimation,
      width: width,
      decoration: BoxDecoration(
        color: GovtThemeTokens.primaryDark,
        border: GovtThemeTokens.sideBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Brand
          _buildHeader(context),

          const Divider(color: Color(0x1FFFFFFF), height: 1),

          // User info tile
          if (!isCollapsed && user != null) _buildUserTile(context),

          if (!isCollapsed && user != null)
            const Divider(color: Color(0x1FFFFFFF), height: 1),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: CivicFixSpacing.md,
                horizontal: CivicFixSpacing.sm,
              ),
              children: navItems.map((item) => _buildNavItem(context, item)).toList(),
            ),
          ),

          const Divider(color: Color(0x1FFFFFFF), height: 1),

          // Footer / Sign Out
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: GovtThemeTokens.topBarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? CivicFixSpacing.sm : CivicFixSpacing.lg,
      ),
      alignment: Alignment.centerLeft,
      child: isCollapsed
          ? Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: GovtThemeTokens.primary,
                  size: 22,
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: GovtThemeTokens.primary,
                    size: 20,
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: CivicFixTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'GOVERNMENT PORTAL',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.accent,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(CivicFixSpacing.sm + 2),
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          borderRadius: GovtThemeTokens.cardRadius,
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: GovtThemeTokens.accent,
              child: Text(
                user?.initials ?? 'GO',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'Officer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user?.departmentName ?? 'Municipal Admin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CivicFixTypography.caption.copyWith(
                      color: const Color(0xFFB0BEC5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, GovtNavItem item) {
    final isSelected = selectedIndex == item.index;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.xs),
        child: Tooltip(
          message: item.title,
          preferBelow: false,
          child: InkWell(
            onTap: () => onDestinationSelected(item.index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x2EFFFFFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? GovtThemeTokens.accent : const Color(0xFFB0BEC5),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => onDestinationSelected(item.index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: AppConstants.fastAnimation,
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0x28FFFFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(
                    left: BorderSide(
                      color: GovtThemeTokens.accent,
                      width: 3.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? GovtThemeTokens.accent : const Color(0xFFB0BEC5),
                size: 20,
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Text(
                  item.title,
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    color: isSelected ? Colors.white : const Color(0xFFCFD8DC),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (item.badgeCount != null && item.badgeCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? GovtThemeTokens.secondary : const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (isCollapsed) {
      return Tooltip(
        message: 'Sign Out',
        child: IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF9A9A), size: 20),
          onPressed: () => _confirmLogout(context),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(CivicFixSpacing.sm),
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.sm + 2,
          ),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFEF9A9A), size: 18),
              CivicFixSpacing.hSpaceMd,
              Text(
                'Sign Out',
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  color: const Color(0xFFEF9A9A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
