import 'package:flutter/material.dart';
import '../models/govt_user_model.dart';
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

  const GovtShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<GovtShellScreen> createState() => _GovtShellScreenState();
}

class _GovtShellScreenState extends State<GovtShellScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GovtAuthService _authService = MockGovtAuthService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  String get _currentTitle {
    switch (_currentIndex) {
      case 0:
        return 'Executive Dashboard';
      case 1:
        return 'Grievance Management';
      case 2:
        return 'Live Hazard GIS Map';
      case 3:
        return 'Operational Analytics';
      case 4:
        return 'Officer Profile & Settings';
      default:
        return 'Government Portal';
    }
  }

  void _onNavSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Close drawer on small screens
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
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
              // Desktop: Full Sidebar
              if (isDesktop)
                GovtSidebar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onNavSelected,
                  isCollapsed: false,
                  user: user,
                ),

              // Tablet: Collapsed Sidebar / Rail
              if (isTablet)
                GovtSidebar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onNavSelected,
                  isCollapsed: true,
                  user: user,
                ),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    GovtAppBar(
                      title: _currentTitle,
                      user: user,
                      showMenuButton: isMobile,
                      onMenuPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: [
                          GovtDashboardScreen(
                            onNavigateToComplaints: () => _onNavSelected(1),
                            onNavigateToMap: () => _onNavSelected(2),
                            onNavigateToAnalytics: () => _onNavSelected(3),
                          ),
                          const GovtComplaintListScreen(),
                          const GovtHazardMapScreen(),
                          const GovtAnalyticsScreen(),
                          const GovtProfileScreen(),
                        ],
                      ),
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
