import 'package:flutter/material.dart';
import '../../../core/auth/auth_service_locator.dart';
import '../../models/govt_user_model.dart';
import '../../services/govt_auth_service.dart';
import '../../theme/govt_theme_tokens.dart';
import 'govt_app_bar.dart';
import 'govt_breadcrumbs.dart';
import 'govt_sidebar.dart';

/// Reusable responsive municipal app shell for all Government Portal views.
///
/// Provides:
/// - Persistent/Collapsible Sidebar on Desktop & Tablet
/// - Drawer Navigation on Mobile
/// - Top App Bar with operational context, notifications, and profile menu
/// - Breadcrumbs
/// - Maximum content width containment
class GovernmentAppShell extends StatefulWidget {
  final Widget? body;
  final String title;
  final String? subtitle;
  final List<GovtBreadcrumbItem>? breadcrumbs;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<GovtNavItem>? navItems;
  final List<Widget>? actions;
  final GovtAuthService? authService;
  final Widget? jurisdictionBadge;
  final Widget? statusWidget;
  final bool showHeader;
  final bool showBreadcrumbs;

  const GovernmentAppShell({
    super.key,
    this.body,
    this.title = 'Government Portal',
    this.subtitle,
    this.breadcrumbs,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.navItems,
    this.actions,
    this.authService,
    this.jurisdictionBadge,
    this.statusWidget,
    this.showHeader = true,
    this.showBreadcrumbs = true,
  });

  @override
  State<GovernmentAppShell> createState() => _GovernmentAppShellState();
}

class _GovernmentAppShellState extends State<GovernmentAppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final GovtAuthService _authService;
  late int _currentIndex;
  bool _isManuallyCollapsed = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthServiceLocator.govtAuth;
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant GovernmentAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
    }
  }

  void _onNavSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }

    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(index);
    }
  }

  void _toggleSidebarCollapse() {
    setState(() {
      _isManuallyCollapsed = !_isManuallyCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GovtUserModel?>(
      valueListenable: _authService.userListenable,
      builder: (context, user, _) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isDesktop = screenWidth >= GovtThemeTokens.desktopBreakpoint;
        final isTablet = screenWidth >= GovtThemeTokens.tabletBreakpoint && !isDesktop;
        final isMobile = screenWidth < GovtThemeTokens.tabletBreakpoint;

        // Auto collapse on tablet or when toggled
        final isSidebarCollapsed = isTablet || _isManuallyCollapsed;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: GovtThemeTokens.background,
          drawer: isMobile
              ? Drawer(
                  child: GovtSidebar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onNavSelected,
                    isCollapsed: false,
                    user: user,
                    items: widget.navItems,
                  ),
                )
              : null,
          body: Row(
            children: [
              // Desktop Persistent Sidebar (Expandable / Collapsible)
              if (isDesktop)
                GovtSidebar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onNavSelected,
                  isCollapsed: isSidebarCollapsed,
                  user: user,
                  items: widget.navItems,
                  onToggleCollapse: _toggleSidebarCollapse,
                ),

              // Tablet Collapsible Rail
              if (isTablet)
                GovtSidebar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onNavSelected,
                  isCollapsed: true,
                  user: user,
                  items: widget.navItems,
                  onToggleCollapse: _toggleSidebarCollapse,
                ),

              // Main Application Viewport
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar
                    if (widget.showHeader)
                      GovtAppBar(
                        title: widget.title,
                        subtitle: widget.subtitle,
                        user: user,
                        showMenuButton: isMobile,
                        onMenuPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        actions: widget.actions,
                      ),

                    // Breadcrumb Strip (if breadcrumbs supplied and showBreadcrumbs is true)
                    if (widget.showBreadcrumbs &&
                        widget.breadcrumbs != null &&
                        widget.breadcrumbs!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0,
                        ),
                        decoration: const BoxDecoration(
                          color: GovtThemeTokens.surface,
                          border: Border(
                            bottom: BorderSide(
                              color: GovtThemeTokens.borderLight,
                              width: 1,
                            ),
                          ),
                        ),
                        child: GovtBreadcrumbs(items: widget.breadcrumbs!),
                      ),

                    // Page Body Container
                    Expanded(
                      child: widget.body ?? const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Backwards compatibility typedef
typedef GovtAppShell = GovernmentAppShell;
