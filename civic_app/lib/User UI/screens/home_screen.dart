import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';
import '../models/home_data_model.dart';
import '../services/mock_home_service.dart';
import '../widgets/civic_progress_card.dart';
import '../widgets/complaint_preview_card.dart';
import '../widgets/home_header.dart';
import '../widgets/nearby_hazard_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/report_issue_cta.dart';

/// Main Citizen Home Screen (Dashboard).
class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  final ConnectivityService? connectivityService;

  const HomeScreen({
    super.key,
    this.onTabChange,
    this.connectivityService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = MockHomeService();
  late final ConnectivityService _connectivityService;
  HomeDataModel? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _homeService.getHomeData(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load civic updates. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToTabOrRoute(int tabIndex, String routeName) {
    if (widget.onTabChange != null) {
      widget.onTabChange!(tabIndex);
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: CivicFixSpacing.pagePadding,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingState(
          message: 'Loading civic dashboard...',
        ),
      );
    }

    if (_errorMessage != null || _data == null) {
      return Center(
        child: ErrorState(
          title: 'Something went wrong',
          message: _errorMessage ?? 'Please check your connection and try again.',
          onRetry: () => _loadData(forceRefresh: true),
        ),
      );
    }

    final data = _data!;

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: CivicFixColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_connectivityService.isOnline)
              OfflineCacheBanner(
                onRefresh: () => _loadData(forceRefresh: true),
              ),
            CivicFixSpacing.vSpaceSm,

            // 1. Personalized Greeting & Notification Indicator
            HomeHeader(
              greeting: data.greeting,
              welcomeMessage: data.welcomeMessage,
              unreadNotificationsCount: data.unreadNotificationsCount,
              onNotificationTap: () => _navigateToTabOrRoute(3, AppRoutes.notifications),
            ),
            CivicFixSpacing.vSpaceXl,

            // 2. Primary Action: + Report an Issue
            ReportIssueCta(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.reportIssue);
              },
            ),
            CivicFixSpacing.vSpaceXxl,

            // 3. Recent Complaints Section
            SectionHeader(
              title: 'Recent Complaints',
              actionTitle: data.recentComplaints.isNotEmpty ? 'View all complaints →' : null,
              onActionTap: () => _navigateToTabOrRoute(1, AppRoutes.myComplaints),
            ),
            CivicFixSpacing.vSpaceSm,
            _buildRecentComplaintsSection(data),
            CivicFixSpacing.vSpaceXxl,

            // 4. Nearby Civic Issues Preview Section
            SectionHeader(
              title: 'Nearby Civic Issues',
              actionTitle: 'View hazard map →',
              onActionTap: () => _navigateToTabOrRoute(2, AppRoutes.hazardMap),
            ),
            CivicFixSpacing.vSpaceSm,
            _buildNearbyHazardsSection(data),
            CivicFixSpacing.vSpaceXxl,

            // 5. Your Civic Progress Section
            const SectionHeader(
              title: 'Your Civic Progress',
            ),
            CivicFixSpacing.vSpaceSm,
            CivicProgressCard(
              progress: data.progress,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.rewards);
              },
            ),
            CivicFixSpacing.vSpaceXxl,

            // 6. Quick Actions Section
            const SectionHeader(
              title: 'Quick Actions',
            ),
            CivicFixSpacing.vSpaceSm,
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    title: 'Assistant',
                    subtitle: 'Get help with CivicFix',
                    icon: Icons.smart_toy_outlined,
                    iconBackgroundColor: CivicFixColors.infoLight,
                    iconColor: CivicFixColors.info,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.assistant);
                    },
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: QuickActionCard(
                    title: 'Rewards',
                    subtitle: 'View your civic progress',
                    icon: Icons.card_giftcard_rounded,
                    iconBackgroundColor: CivicFixColors.alertLight,
                    iconColor: CivicFixColors.alertDark,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.rewards);
                    },
                  ),
                ),
              ],
            ),
            CivicFixSpacing.vSpaceXxxl,
          ],
        ),
      ),
    );
  }

  Widget _buildRecentComplaintsSection(HomeDataModel data) {
    if (data.recentComplaints.isEmpty) {
      return CivicFixCard(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.lg,
          vertical: CivicFixSpacing.xl,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CivicFixColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: CivicFixColors.secondary,
                  size: 28,
                ),
              ),
              CivicFixSpacing.vSpaceMd,
              Text(
                'No complaints yet',
                style: CivicFixTypography.h3.copyWith(fontSize: 18),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                'Report a civic issue to get started.',
                textAlign: TextAlign.center,
                style: CivicFixTypography.bodySmall.copyWith(
                  color: CivicFixColors.secondaryText,
                ),
              ),
              CivicFixSpacing.vSpaceLg,
              CivicFixButton(
                text: 'Report an Issue',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.reportIssue);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: data.recentComplaints.take(3).map((complaint) {
        return Padding(
          padding: const EdgeInsets.only(bottom: CivicFixSpacing.md),
          child: ComplaintPreviewCard(
            complaint: complaint,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.complaintDetails,
                arguments: complaint,
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNearbyHazardsSection(HomeDataModel data) {
    if (data.nearbyHazards.isEmpty) {
      return CivicFixCard(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: CivicFixColors.secondary, size: 22),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Text(
                'No immediate hazards reported in your immediate vicinity.',
                style: CivicFixTypography.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: data.nearbyHazards.take(3).map((hazard) {
        return Padding(
          padding: const EdgeInsets.only(bottom: CivicFixSpacing.sm),
          child: NearbyHazardCard(
            hazard: hazard,
            onTap: () {
              _navigateToTabOrRoute(2, AppRoutes.hazardMap);
            },
          ),
        );
      }).toList(),
    );
  }
}
