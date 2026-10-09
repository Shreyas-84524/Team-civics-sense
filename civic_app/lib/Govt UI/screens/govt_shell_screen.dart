import 'package:flutter/material.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/localization/app_localizations.dart';
import '../models/govt_user_model.dart';
import '../models/government_session.dart';
import '../navigation/govt_navigation_config.dart';
import '../services/govt_auth_service.dart';
import '../theme/govt_theme_tokens.dart';
import '../widgets/common/govt_app_bar.dart';
import '../widgets/common/govt_sidebar.dart';
import 'analytics/govt_analytics_screen.dart';
import 'complaints/govt_complaint_list_screen.dart';
import 'dashboard/govt_dashboard_screen.dart';
import 'map/govt_hazard_map_screen.dart';
import 'profile/govt_profile_screen.dart';

/// Responsive Layout Shell Container for all CivicFix Government Portal views.
class GovtShellScreen extends StatefulWidget {
  final int initialIndex;
  final GovtAuthService? authService;

  const GovtShellScreen({
    super.key,
    this.initialIndex = 0,
    this.authService,
  });

  @override
  State<GovtShellScreen> createState() => _GovtShellScreenState();
}

class _GovtShellScreenState extends State<GovtShellScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final GovtAuthService _authService;
  bool _isManuallyCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _authService = widget.authService ?? AuthServiceLocator.govtAuth;
  }

  void _toggleSidebarCollapse() {
    setState(() {
      _isManuallyCollapsed = !_isManuallyCollapsed;
    });
  }

  String _getCurrentTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (_currentIndex) {
      case 0:
        return l10n?.govExecutiveDashboard ?? 'Executive Dashboard';
      case 1:
        return l10n?.govGrievanceManagement ?? 'Grievance Management';
      case 2:
        return l10n?.govLiveHazardGisMap ?? 'Live Hazard GIS Map';
      case 3:
        return l10n?.govOperationalAnalytics ?? 'Operational Analytics';
      case 4:
        return l10n?.govOfficerProfileSettings ?? 'Officer Profile & Settings';
      default:
        return l10n?.govPortalTitle ?? 'Government Portal';
    }
  }

  void _onNavSelected(int index) {
    // Close drawer on small screens
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    final user = _authService.currentUser;
    final destination = GovtNavigationConfig.getItemsForUser(user)
        .where((item) => item.index == index)
        .firstOrNull;
    if (destination == null) return;
    final route = index == 0 && user != null
        ? GovernmentSession.fromUser(user).landingRoute
        : destination.routeName;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GovtUserModel?>(
      valueListenable: _authService.userListenable,
      builder: (context, user, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= GovtThemeTokens.desktopBreakpoint;
        final isTablet = screenWidth >= GovtThemeTokens.tabletBreakpoint && !isDesktop;
        final isMobile = screenWidth < GovtThemeTokens.tabletBreakpoint;

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
                  ),
                )
              : null,
          body: Row(
            children: [
              // Desktop: Expandable / Collapsible Sidebar
              if (isDesktop)
                GovtSidebar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onNavSelected,
                  isCollapsed: isSidebarCollapsed,
                  user: user,
                  onToggleCollapse: _toggleSidebarCollapse,
                ),

              // Tablet: Collapsed Sidebar / Rail
              if (isTablet)
                GovtSidebar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onNavSelected,
                  isCollapsed: true,
                  user: user,
                  onToggleCollapse: _toggleSidebarCollapse,
                ),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    GovtAppBar(
                      title: _getCurrentTitle(context),
                      user: user,
                      showMenuButton: isMobile,
                      onMenuPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    Expanded(
                      child: <Widget>[
                          GovtDashboardScreen(
                            onNavigateToComplaints: () => _onNavSelected(1),
                            onNavigateToMap: () => _onNavSelected(2),
                            onNavigateToAnalytics: () => _onNavSelected(3),
                          ),
                          const GovtComplaintListScreen(),
                          const GovtHazardMapScreen(),
                          const GovtAnalyticsScreen(),
                          GovtProfileScreen(authService: _authService),
                        ][_currentIndex],
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
