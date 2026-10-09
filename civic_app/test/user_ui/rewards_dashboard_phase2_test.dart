import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/User UI/screens/rewards_screen.dart';
import 'package:civic_app/User UI/widgets/rewards/civic_impact_card.dart';
import 'package:civic_app/User UI/widgets/rewards/points_progress_card.dart';
import 'package:civic_app/User UI/widgets/rewards/recent_reward_activity_card.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/repositories/rewards_repository.dart';
import 'package:civic_app/core/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';

class FakeTestUserRepository implements UserRepository {
  UserModel _user;
  final ValueNotifier<UserModel> _userNotifier;

  FakeTestUserRepository(this._user) : _userNotifier = ValueNotifier<UserModel>(_user);

  @override
  Future<UserModel> getCurrentUser() async => _user;

  @override
  ValueListenable<UserModel> getUserListenable() => _userNotifier;

  void updateUserPoints(int newPoints) {
    _user = _user.copyWith(civicPoints: newPoints);
    _userNotifier.value = _user;
  }

  @override
  Future<UserModel> updateUserProfile({
    String? fullName,
    String? email,
    String? phone,
    String? wardNumber,
    String? languageCode,
    String? avatarUrl,
  }) async {
    _user = _user.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      wardNumber: wardNumber,
      languageCode: languageCode,
      avatarUrl: avatarUrl,
    );
    _userNotifier.value = _user;
    return _user;
  }

  @override
  Future<void> clearUserCache() async {}

  @override
  Future<List<CivicAchievement>> getUserBadges() async => [];

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async => [];

  @override
  Future<bool> redeemReward(String rewardId) async => true;
}

class FakeTestRewardsRepository implements RewardsRepository {
  final List<RewardEvent> _events;

  FakeTestRewardsRepository({List<RewardEvent>? events})
      : _events = events ?? [
          RewardEvent(
            id: 'ev_01',
            citizenId: 'user_001',
            complaintId: 'cmp_001',
            complaintTitle: 'Pothole on MG Road',
            rewardType: 'resolved',
            points: 35,
            description: 'Complaint resolved',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          RewardEvent(
            id: 'ev_02',
            citizenId: 'user_001',
            complaintId: 'cmp_001',
            complaintTitle: 'Pothole on MG Road',
            rewardType: 'verified',
            points: 20,
            description: 'Complaint verified',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          RewardEvent(
            id: 'ev_03',
            citizenId: 'user_001',
            complaintId: 'cmp_001',
            complaintTitle: 'Pothole on MG Road',
            rewardType: 'assigned',
            points: 15,
            description: 'Complaint assigned',
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ];

  @override
  Future<RewardDataModel> getRewardData(String userId) async {
    return RewardDataModel(
      userId: userId,
      currentPoints: 70,
      reportsSubmitted: 5,
      reportsResolved: 3,
      reportsVerified: 4,
      communityUpvotes: 18,
      achievements: CivicAchievement.defaultAchievements(),
      perks: const [
        CivicRewardItem(
          id: 'perk_coffee',
          title: 'Cafe Coffee Day Discount',
          partner: 'Cafe Coffee Day',
          description: '20% off on all beverages',
          pointsCost: 100,
          expiryDate: '31 Dec 2026',
          icon: Icons.local_cafe_outlined,
        ),
      ],
      recentActivity: _events,
    );
  }

  @override
  Future<List<CivicAchievement>> getAchievements() async => CivicAchievement.defaultAchievements();

  @override
  Future<CivicAchievement?> getAchievementById(String id) async => null;

  @override
  Future<List<CivicRewardItem>> getRewardsCatalog() async => const [];

  @override
  Future<bool> redeemReward(String rewardId) async => true;

  @override
  Future<List<RewardEvent>> getRewardEvents(String userId) async => _events;
}

class FakeTestConnectivityService implements ConnectivityService {
  bool _online = true;

  @override
  bool get isOnline => _online;

  @override
  bool get isOffline => !_online;

  @override
  void setOnline(bool online) {
    _online = online;
  }

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(_online);
}

void main() {
  testWidgets('RewardsScreen renders Level 1 Civic Starter correctly with progress and points remaining', (tester) async {
    final fakeUser = FakeTestUserRepository(
      const UserModel(
        id: 'user_001',
        fullName: 'Aarav Mehta',
        email: 'aarav@example.com',
        phone: '+919876543210',
        civicPoints: 70,
        reportsSubmitted: 5,
        reportsResolved: 3,
      ),
    );

    final fakeRewards = FakeTestRewardsRepository();
    final fakeConnectivity = FakeTestConnectivityService();
    final fakeComplaintRepo = MockComplaintRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RewardsScreen(
          userRepository: fakeUser,
          rewardsRepository: fakeRewards,
          complaintRepository: fakeComplaintRepo,
          connectivityService: fakeConnectivity,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify PointsProgressCard
    expect(find.byType(PointsProgressCard), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.textContaining('Level 1 • Civic Starter'), findsOneWidget);
    expect(find.textContaining('30 pts to Level 2: Civic Contributor'), findsOneWidget);

    // Verify CivicImpactCard
    expect(find.byType(CivicImpactCard), findsOneWidget);
    expect(find.text('Civic Impact'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Community Upvotes'), findsOneWidget);

    // Verify RecentRewardActivityCard
    expect(find.byType(RecentRewardActivityCard), findsOneWidget);
    expect(find.text('Recent Reward Activity'), findsOneWidget);
    expect(find.text('+35'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('Complaint resolved'), findsOneWidget);
    expect(find.text('Complaint verified'), findsOneWidget);
    expect(find.text('Complaint assigned'), findsOneWidget);
  });

  testWidgets('RewardsScreen renders Level 5 Civic Hero correctly without fake next level', (tester) async {
    final fakeUser = FakeTestUserRepository(
      const UserModel(
        id: 'user_001',
        fullName: 'Aarav Mehta',
        email: 'aarav@example.com',
        phone: '+919876543210',
        civicPoints: 1250,
        reportsSubmitted: 15,
        reportsResolved: 12,
      ),
    );

    final fakeRewards = FakeTestRewardsRepository();
    final fakeConnectivity = FakeTestConnectivityService();
    final fakeComplaintRepo = MockComplaintRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RewardsScreen(
          userRepository: fakeUser,
          rewardsRepository: fakeRewards,
          complaintRepository: fakeComplaintRepo,
          connectivityService: fakeConnectivity,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Level 5 Civic Hero
    expect(find.textContaining('Level 5 • Civic Hero'), findsOneWidget);
    expect(find.text('MAX LEVEL'), findsOneWidget);
    expect(find.textContaining('Hero Tier Achieved'), findsOneWidget);
    expect(find.textContaining('Level 6'), findsNothing);
  });

  testWidgets('RewardsScreen updates live when user points increase dynamically', (tester) async {
    final fakeUser = FakeTestUserRepository(
      const UserModel(
        id: 'user_001',
        fullName: 'Aarav Mehta',
        email: 'aarav@example.com',
        phone: '+919876543210',
        civicPoints: 90,
        reportsSubmitted: 5,
        reportsResolved: 3,
      ),
    );

    final fakeRewards = FakeTestRewardsRepository();
    final fakeConnectivity = FakeTestConnectivityService();
    final fakeComplaintRepo = MockComplaintRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RewardsScreen(
          userRepository: fakeUser,
          rewardsRepository: fakeRewards,
          complaintRepository: fakeComplaintRepo,
          connectivityService: fakeConnectivity,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially Level 1 (90 points)
    expect(find.textContaining('Level 1 • Civic Starter'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);

    // Live update points: 90 -> 260 (crosses into Level 3: Civic Champion)
    fakeUser.updateUserPoints(260);
    await tester.pumpAndSettle();

    // Now Level 3 (260 points)
    expect(find.textContaining('Level 3 • Civic Champion'), findsOneWidget);
    expect(find.text('260'), findsOneWidget);
    expect(find.textContaining('240 pts to Level 4: Civic Leader'), findsOneWidget);
  });
}
