import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/reward_model.dart';
import '../../core/models/user_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/rewards_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';
import '../widgets/rewards/achievement_card.dart';
import '../widgets/rewards/points_progress_card.dart';

/// Screen for Civic Points, Level Milestones, MVP Achievements, and Community Perks.
class RewardsScreen extends StatefulWidget {
  final RewardsRepository? rewardsRepository;
  final UserRepository? userRepository;
  final ConnectivityService? connectivityService;

  const RewardsScreen({
    super.key,
    this.rewardsRepository,
    this.userRepository,
    this.connectivityService,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final RewardsRepository _rewardsRepository;
  late final UserRepository _userRepository;
  late final ConnectivityService _connectivityService;

  bool _isLoading = true;
  String? _errorMessage;
  RewardDataModel? _rewardData;

  @override
  void initState() {
    super.initState();
    _rewardsRepository = widget.rewardsRepository ?? MockRewardsRepository();
    _userRepository = widget.userRepository ?? MockUserRepository();
    _connectivityService = widget.connectivityService ?? AppConnectivityService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _userRepository.getCurrentUser();
      final data = await _rewardsRepository.getRewardData(user.id);
      if (mounted) {
        setState(() {
          _rewardData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = "Couldn't load rewards. Please retry.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _claimPerk(CivicRewardItem perk) async {
    final user = await _userRepository.getCurrentUser();
    if (user.civicPoints < perk.pointsCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You need ${perk.pointsCost - user.civicPoints} more points to claim this perk.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final success = await _rewardsRepository.redeemReward(perk.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CivicFixColors.secondary,
          content: Text('Voucher Claimed: ${perk.title}. Check registered email!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'Civic Rewards & Badges',
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingState(message: 'Loading your civic milestones...'));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: ErrorState(
            title: "Couldn't load rewards",
            message: _errorMessage!,
            onRetry: _loadData,
          ),
        ),
      );
    }

    return ValueListenableBuilder<UserModel>(
      valueListenable: _userRepository.getUserListenable(),
      builder: (context, user, _) {
        final achievements = _rewardData?.achievements ?? [];

        return RefreshIndicator(
          onRefresh: _loadData,
          color: CivicFixColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: CivicFixSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_connectivityService.isOnline)
                  OfflineCacheBanner(
                    onRefresh: _loadData,
                  ),
                // 1. Points Hero Card with Milestone Progress
                PointsProgressCard(
                  points: user.civicPoints,
                  nextMilestone: 1000,
                ),
                CivicFixSpacing.vSpaceLg,

                // 2. Contribution Summary Card
                CivicFixCard(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Contribution',
                        style: CivicFixTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: CivicFixColors.primaryText,
                        ),
                      ),
                      CivicFixSpacing.vSpaceMd,
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryMetric(
                              label: 'Total Reports',
                              value: '${user.reportsSubmitted}',
                              icon: Icons.send_rounded,
                              color: CivicFixColors.info,
                            ),
                          ),
                          Container(width: 1, height: 40, color: CivicFixColors.border),
                          Expanded(
                            child: _buildSummaryMetric(
                              label: 'Resolved Reports',
                              value: '${user.reportsResolved}',
                              icon: Icons.check_circle_rounded,
                              color: CivicFixColors.secondary,
                            ),
                          ),
                          Container(width: 1, height: 40, color: CivicFixColors.border),
                          Expanded(
                            child: _buildSummaryMetric(
                              label: 'Points Earned',
                              value: '${user.civicPoints}',
                              icon: Icons.stars_rounded,
                              color: CivicFixColors.alertDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceXl,

                // 3. MVP Achievements Section
                const SectionHeader(
                  title: 'Achievements',
                  subtitle: 'Earn badges for active neighborhood participation',
                ),
                CivicFixSpacing.vSpaceSm,

                if (achievements.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.xl),
                    child: EmptyState(
                      title: 'No achievements yet.',
                      description: 'Start contributing to your community to earn achievements.',
                      icon: Icons.emoji_events_outlined,
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: achievements.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: CivicFixSpacing.md,
                      mainAxisSpacing: CivicFixSpacing.md,
                      childAspectRatio: 1.25,
                    ),
                    itemBuilder: (context, index) {
                      return AchievementCard(achievement: achievements[index]);
                    },
                  ),
                CivicFixSpacing.vSpaceXl,

                // 4. Community Perks Catalog
                const SectionHeader(
                  title: 'Community Perks',
                  subtitle: 'Redeem your points for local government & partner benefits',
                ),
                CivicFixSpacing.vSpaceSm,

                ...(_rewardData?.perks ?? []).map((perk) {
                  final canAfford = user.civicPoints >= perk.pointsCost;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: CivicFixSpacing.md),
                    child: CivicFixCard(
                      padding: const EdgeInsets.all(CivicFixSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(CivicFixSpacing.md),
                            decoration: BoxDecoration(
                              color: CivicFixColors.accentLight,
                              borderRadius: CivicFixRadius.chipRadius,
                            ),
                            child: Icon(perk.icon, color: CivicFixColors.secondaryDark, size: 26),
                          ),
                          CivicFixSpacing.hSpaceMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  perk.title,
                                  style: CivicFixTypography.bodySmallMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                CivicFixSpacing.vSpaceXs,
                                Text(
                                  'Partner: ${perk.partner}',
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    color: CivicFixColors.secondary,
                                    fontSize: 11,
                                  ),
                                ),
                                CivicFixSpacing.vSpaceXs,
                                Text(
                                  perk.description,
                                  style: CivicFixTypography.caption.copyWith(
                                    color: CivicFixColors.secondaryText,
                                  ),
                                ),
                                CivicFixSpacing.vSpaceSm,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${perk.pointsCost} Points',
                                      style: CivicFixTypography.bodySmallMedium.copyWith(
                                        color: CivicFixColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: canAfford ? () => _claimPerk(perk) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: CivicFixColors.secondary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        minimumSize: const Size(70, 32),
                                      ),
                                      child: const Text('Claim', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                CivicFixSpacing.vSpaceXxl,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: CivicFixTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: CivicFixColors.primaryText,
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          label,
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
