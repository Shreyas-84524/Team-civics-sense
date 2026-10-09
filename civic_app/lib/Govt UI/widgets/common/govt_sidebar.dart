import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../models/govt_user_model.dart';
import '../../navigation/govt_nav_item.dart';
import '../../navigation/govt_navigation_config.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

// Re-export GovtNavItem for compatibility
export '../../navigation/govt_nav_item.dart';

/// Responsive Government Sidebar for Desktop, Tablet, and Mobile Drawer views.
class GovtSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isCollapsed;
  final GovtUserModel? user;
  final VoidCallback? onLogout;
  final List<GovtNavItem>? items;
  final VoidCallback? onToggleCollapse;

  const GovtSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isCollapsed = false,
    this.user,
    this.onLogout,
    this.items,
    this.onToggleCollapse,
  });

  /// Canonical default navigation items for backward compatibility
  static List<GovtNavItem> get navItems => GovtNavigationConfig.defaultNavItems;

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed
        ? GovtThemeTokens.sidebarCollapsedWidth
        : GovtThemeTokens.sidebarWidth;

    final navList = items ?? GovtNavigationConfig.getItemsForUser(user);

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
            child: _buildNavList(context, navList),
          ),

          const Divider(color: Color(0x1FFFFFFF), height: 1),

          // Collapse/Expand toggle & Sign Out
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
              child: InkWell(
                onTap: onToggleCollapse,
                borderRadius: BorderRadius.circular(8),
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
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.govPortalTitle.toUpperCase() ?? 'GOVERNMENT PORTAL',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.accent,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
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
                    user?.departmentName.isNotEmpty == true
                        ? user!.departmentName
                        : 'Municipal Administration',
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

  Widget _buildNavList(BuildContext context, List<GovtNavItem> navList) {
    if (isCollapsed) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: CivicFixSpacing.md,
          horizontal: CivicFixSpacing.xs,
        ),
        itemCount: navList.length,
        itemBuilder: (context, index) => _buildNavItem(context, navList[index]),
      );
    }

    final grouped = GovtNavigationConfig.groupItems(navList);
    final hasMultipleGroups = grouped.keys.length > 1;

    return ListView(
      padding: const EdgeInsets.symmetric(
        vertical: CivicFixSpacing.md,
        horizontal: CivicFixSpacing.sm,
      ),
      children: [
        for (final entry in grouped.entries) ...[
          if (hasMultipleGroups) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: CivicFixSpacing.md,
                top: CivicFixSpacing.sm,
                bottom: CivicFixSpacing.xs,
              ),
              child: Text(
                entry.key.toUpperCase(),
                style: GovtTypography.caption.copyWith(
                  color: const Color(0xFF78909C),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          for (final item in entry.value) _buildNavItem(context, item),
          if (hasMultipleGroups) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, GovtNavItem item) {
    final isSelected = selectedIndex == item.index;
    final displayTitle = localizedGovtNavTitle(item.title, context: context);

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.xs),
        child: Tooltip(
          message: displayTitle,
          preferBelow: false,
          child: InkWell(
            onTap: item.isDisabled ? null : () => onDestinationSelected(item.index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x2EFFFFFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                  color: item.isDisabled
                      ? const Color(0xFF546E7A)
                      : (isSelected ? GovtThemeTokens.accent : const Color(0xFFB0BEC5)),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.isDisabled ? null : () => onDestinationSelected(item.index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0x18FFFFFF),
          splashColor: const Color(0x24FFFFFF),
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
                  isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                  color: item.isDisabled
                      ? const Color(0xFF546E7A)
                      : (isSelected ? GovtThemeTokens.accent : const Color(0xFFB0BEC5)),
                  size: 20,
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Text(
                    displayTitle,
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      color: item.isDisabled
                          ? const Color(0xFF78909C)
                          : (isSelected ? Colors.white : const Color(0xFFCFD8DC)),
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
                if (item.badgeLabel != null && (item.badgeCount == null || item.badgeCount == 0))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.badgeLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (onToggleCollapse == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    if (isCollapsed) {
      return Tooltip(
        message: l10n?.govExpandSidebar ?? 'Expand Sidebar',
        child: IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0BEC5), size: 20),
          onPressed: onToggleCollapse,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(CivicFixSpacing.sm),
      child: InkWell(
        onTap: onToggleCollapse,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.sm + 2,
          ),
          child: Row(
            children: [
              const Icon(Icons.chevron_left_rounded, color: Color(0xFFB0BEC5), size: 18),
              CivicFixSpacing.hSpaceMd,
              Text(
                l10n?.govCollapseSidebar ?? 'Collapse',
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  color: const Color(0xFFB0BEC5),
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
