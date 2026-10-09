import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/certificate_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/reward_model.dart';
import '../../core/models/user_model.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/repositories/certificate_repository.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/hive_user_repository.dart';
import '../../core/repositories/offline_first_user_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/repositories/rewards_repository.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/services/achievement_evaluator.dart';
import '../../core/services/reward_evaluation_service.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';
import '../widgets/rewards/achievement_card.dart';
import '../widgets/rewards/civic_impact_card.dart';
import '../widgets/rewards/my_certificates_section.dart';
import '../widgets/rewards/points_progress_card.dart';
import '../widgets/rewards/recent_reward_activity_card.dart';

/// Screen for Civic Points, Civic Levels, Real-world Impact, Milestone Progress,
/// Recent Reward Activity, MVP Achievements, and My Certificates.
class RewardsScreen extends StatefulWidget {
  final RewardsRepository? rewardsRepository;
  final UserRepository? userRepository;
  final ComplaintRepository? complaintRepository;
  final CertificateRepository? certificateRepository;
  final ConnectivityService? connectivityService;

  const RewardsScreen({
    super.key,
    this.rewardsRepository,
    this.userRepository,
    this.complaintRepository,
    this.certificateRepository,
    this.connectivityService,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final RewardsRepository _rewardsRepository;
  late final UserRepository _userRepository;
  late final ComplaintRepository _complaintRepository;
  late final CertificateRepository _certificateRepository;
  late final ConnectivityService _connectivityService;

  bool _isLoading = true;
  String? _errorMessage;
  RewardDataModel? _rewardData;
  List<CivicCertificate> _certificates = const [];

  @override
  void initState() {
    super.initState();
    _rewardsRepository = widget.rewardsRepository ?? RepositoryLocator.rewardsRepository;
    _userRepository = widget.userRepository ?? RepositoryLocator.userRepository;
    _complaintRepository = widget.complaintRepository ?? RepositoryLocator.complaintRepository;
    _certificateRepository = widget.certificateRepository ?? RepositoryLocator.certificateRepository;
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
      
      // Load real canonical reward history
      List<RewardEvent> recentEvents = await _rewardsRepository.getRewardEvents(user.id);
      if (recentEvents.isEmpty) {
        recentEvents = await RewardEvaluationService.instance.getRewardHistory(user.id);
      }
      if (recentEvents.isEmpty && data.recentActivity.isNotEmpty) {
        recentEvents = data.recentActivity;
      }

      // Synchronize profile points with server reward points if needed
      final authoritativePoints = data.currentPoints > 0 ? data.currentPoints : user.civicPoints;
      if (user.civicPoints != authoritativePoints) {
        final updatedUser = user.copyWith(civicPoints: authoritativePoints);
        final userRepo = _userRepository;
        if (userRepo is HiveUserRepository) {
          await userRepo.cacheUser(updatedUser);
        } else if (userRepo is OfflineFirstUserRepository) {
          await userRepo.cacheUser(updatedUser);
        }
      }

      // Derive real-world impact metrics from canonical complaint data without duplicate counters
      int submittedCount = user.reportsSubmitted;
      int verifiedCount = data.reportsVerified;
      int resolvedCount = user.reportsResolved;
      int upvotesCount = data.communityUpvotes;

      List<ComplaintModel> citizenComplaints = [];
      try {
        citizenComplaints = await _complaintRepository.getCitizenComplaints(user.id);
        if (citizenComplaints.isNotEmpty) {
          submittedCount = citizenComplaints.length;
          verifiedCount = citizenComplaints.where((c) =>
              c.isEvidenceVerified ||
              c.departmentVerificationStatus == 'passed' ||
              c.status == ComplaintStatus.verified ||
              c.status == ComplaintStatus.assigned ||
              c.status == ComplaintStatus.inProgress ||
              c.status == ComplaintStatus.resolved ||
              c.status == ComplaintStatus.closed).length;
          resolvedCount = citizenComplaints.where((c) =>
              c.status == ComplaintStatus.resolved ||
              c.status == ComplaintStatus.closed).length;
          upvotesCount = citizenComplaints.fold<int>(0, (sum, c) => sum + c.upvotes);
        }
      } catch (_) {}

      // Evaluates the 5 canonical achievement badges with live progress and server metrics
      final evaluatedAchievements = AchievementEvaluator.evaluateAchievements(
        user: user,
        complaints: citizenComplaints,
        existingAchievements: data.achievements,
        supportedComplaintsCount: data.supportedComplaints,
      );

      // Load issued certificates for this citizen
      List<CivicCertificate> userCertificates = [];
      try {
        userCertificates = await _certificateRepository.getCertificatesForUser(user.id);
      } catch (_) {}

      final enrichedData = data.copyWith(
        currentPoints: authoritativePoints,
        reportsSubmitted: submittedCount,
        reportsVerified: verifiedCount,
        reportsResolved: resolvedCount,
        communityUpvotes: upvotesCount,
        supportedComplaints: data.supportedComplaints,
        achievements: evaluatedAchievements,
        recentActivity: recentEvents,
      );

      if (mounted) {
        setState(() {
          _rewardData = enrichedData;
          _certificates = userCertificates;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[RewardsScreen] _loadData error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Couldn't load rewards. Please retry.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: CivicFixAppBar(
        title: l10n?.civicRewardsAndAchievements ?? 'Civic Rewards & Badges',
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
    final l10n = context.l10nOrNull;
    if (_isLoading) {
      return Center(child: LoadingState(message: l10n?.loadingRewards ?? 'Loading your civic milestones...'));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: ErrorState(
            title: l10n?.couldNotLoadComplaint ?? "Couldn't load rewards",
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
        final effectivePoints = user.civicPoints;
        final levelInfo = CivicLevelInfo.calculate(effectivePoints);

        final impactSummary = _rewardData?.impactSummary ??
            CivicImpactSummary(
              complaintsSubmitted: user.reportsSubmitted,
              complaintsVerified: _rewardData?.reportsVerified ?? 0,
              complaintsResolved: user.reportsResolved,
              communityUpvotes: _rewardData?.communityUpvotes ?? 0,
              achievementsUnlocked: achievements.where((a) => a.isUnlocked).length,
            );

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

                // 1. Level & Points Hero Card with Progress
                PointsProgressCard(
                  points: effectivePoints,
                  levelInfoOverride: levelInfo,
                ),
                CivicFixSpacing.vSpaceLg,

                // 2. Civic Impact Summary Card
                CivicImpactCard(impact: impactSummary),
                CivicFixSpacing.vSpaceLg,

                // 3. Recent Reward Activity Card
                RecentRewardActivityCard(
                  events: _rewardData?.recentActivity ?? [],
                ),
                CivicFixSpacing.vSpaceXl,

                // 4. MVP Achievements Section
                SectionHeader(
                  title: l10n?.achievements ?? 'Achievements',
                  subtitle: l10n?.achievementsSubtitle ?? 'Earn badges for active neighborhood participation',
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

                // 5. My Certificates Section
                MyCertificatesSection(
                  certificates: _certificates,
                  user: user,
                  onCertificateGenerated: _loadData,
                ),
                CivicFixSpacing.vSpaceXxl,
              ],
            ),
          ),
        );
      },
    );
  }
}
