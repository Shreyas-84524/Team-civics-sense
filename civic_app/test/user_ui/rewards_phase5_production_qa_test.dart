import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/repositories/rewards_repository.dart';
import 'package:civic_app/core/repositories/user_repository.dart';
import 'package:civic_app/core/services/reward_evaluation_service.dart';
import 'package:civic_app/User UI/screens/rewards_screen.dart';
import 'package:civic_app/User UI/widgets/rewards/achievement_card.dart';

class MockConnectivityService implements ConnectivityService {
  final bool online;
  MockConnectivityService({this.online = true});

  @override
  bool get isOnline => online;

  @override
  bool get isOffline => !online;

  @override
  void setOnline(bool online) {}

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(online);
}

class MockUserRepository implements UserRepository {
  UserModel _user;
  final ValueNotifier<UserModel> _notifier;

  MockUserRepository(this._user) : _notifier = ValueNotifier<UserModel>(_user);

  @override
  Future<UserModel> getCurrentUser() async => _user;

  @override
  ValueNotifier<UserModel> getUserListenable() => _notifier;

  void updateUser(UserModel updated) {
    _user = updated;
    _notifier.value = updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRewardsRepository implements RewardsRepository {
  final List<RewardEvent> _events = [];

  @override
  Future<RewardDataModel> getRewardData(String userId) async {
    return RewardDataModel(
      userId: userId,
      currentPoints: 0,
      reportsSubmitted: 0,
      reportsResolved: 0,
      reportsVerified: 0,
      communityUpvotes: 0,
      achievements: CivicAchievement.defaultAchievements(),
      recentActivity: _events,
    );
  }

  @override
  Future<List<RewardEvent>> getRewardEvents(String userId) async => _events;

  void addEvents(List<RewardEvent> events) {
    _events.addAll(events);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockComplaintRepository implements ComplaintRepository {
  final List<ComplaintModel> _complaints = [];

  void setComplaints(List<ComplaintModel> complaints) {
    _complaints.clear();
    _complaints.addAll(complaints);
  }

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async => _complaints;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CIVICFIX REWARDS & GAMIFICATION — PHASE 5 PRODUCTION QA', () {
    late RewardEvaluationService rewardEngine;

    setUp(() {
      rewardEngine = RewardEvaluationService();
      rewardEngine.resetState();
    });

    ComplaintModel buildTestComplaint({
      required String id,
      String citizenId = 'citizen_qa_001',
      ComplaintStatus status = ComplaintStatus.resolved,
      bool isVerified = true,
      List<String> images = const ['https://example.com/p1.jpg'],
    }) {
      return ComplaintModel(
        id: id,
        citizenId: citizenId,
        ticketNumber: 'CF-2026-QA-$id',
        title: 'Road Damage $id',
        description: 'Pothole needing repair',
        category: CivicCategory.defaultCategories.first,
        status: status,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Dadar, Mumbai',
          ward: 'G/North',
        ),
        imageUrls: images,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now(),
        evidenceVerificationStatus: isVerified ? 'passed' : 'pending',
        departmentVerificationStatus: isVerified ? 'passed' : 'pending',
        assignedCrewMemberId: 'JE_G_NORTH_01',
        workStartedAt: DateTime.now().subtract(const Duration(hours: 2)),
        resolvedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
    }

    test('FULL LIFECYCLE TEST: One valid complaint produces exactly 100 Civic Points across 5 stages', () async {
      final complaint = buildTestComplaint(id: 'cmp_lifecycle_100');

      final results = await rewardEngine.evaluateAllEligibleStages(complaint: complaint);

      expect(results.length, equals(5));
      expect(results.every((r) => r.granted), isTrue);

      final stagePoints = results.map((r) => r.pointsAwarded).toList();
      expect(stagePoints, equals([10, 20, 15, 20, 35]));

      final totalComplaintPoints = await rewardEngine.getComplaintAwardedPoints('cmp_lifecycle_100');
      expect(totalComplaintPoints, equals(100));

      final history = await rewardEngine.getRewardHistory('citizen_qa_001');
      expect(history.length, equals(5));

      // Traceability: verify each point maps to a valid deterministic event
      final types = history.map((e) => e.rewardType).toSet();
      expect(types, containsAll(['submitted', 'verified', 'assigned', 'in_progress', 'resolved']));
    });

    test('FINAL ANTI-ABUSE QA: Repeated stage evaluation produces zero duplicate points', () async {
      final complaint = buildTestComplaint(id: 'cmp_idempotent');

      // First run: 100 points
      await rewardEngine.evaluateAllEligibleStages(complaint: complaint);
      expect(await rewardEngine.getComplaintAwardedPoints('cmp_idempotent'), equals(100));

      // Second run: 0 new points granted
      final repeatedResults = await rewardEngine.evaluateAllEligibleStages(complaint: complaint);
      expect(repeatedResults.every((r) => !r.granted), isTrue);
      expect(repeatedResults.fold<int>(0, (sum, r) => sum + r.pointsAwarded), equals(0));
      expect(await rewardEngine.getComplaintAwardedPoints('cmp_idempotent'), equals(100));
    });

    test('FINAL ANTI-ABUSE QA: Reopened and reworked complaints do not re-grant stage rewards', () async {
      final complaint = buildTestComplaint(id: 'cmp_reopen_test');
      await rewardEngine.evaluateAllEligibleStages(complaint: complaint);
      expect(await rewardEngine.getComplaintAwardedPoints('cmp_reopen_test'), equals(100));

      // Reopen to inProgress
      final reworked = complaint.copyWith(status: ComplaintStatus.inProgress, reopenCount: 1);
      final reworkResult = await rewardEngine.evaluateStage(
        complaint: reworked,
        stage: RewardLifecycleStage.inProgress,
      );
      expect(reworkResult.granted, isFalse);
      expect(reworkResult.pointsAwarded, equals(0));

      // Close to resolved again
      final reResolved = reworked.copyWith(status: ComplaintStatus.resolved);
      final reResolvedResult = await rewardEngine.evaluateStage(
        complaint: reResolved,
        stage: RewardLifecycleStage.resolved,
      );
      expect(reResolvedResult.granted, isFalse);
      expect(reResolvedResult.pointsAwarded, equals(0));
      expect(await rewardEngine.getComplaintAwardedPoints('cmp_reopen_test'), equals(100));
    });

    testWidgets('RewardsScreen contains exactly the 4 required sections (Level, Progress, History, Achievements)', (tester) async {
      const testUser = UserModel(
        id: 'citizen_ui_qa',
        fullName: 'Aarav Patel',
        email: 'aarav@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
        civicPoints: 260, // Level 3 Civic Champion
        reportsSubmitted: 3,
        reportsResolved: 2,
      );

      final mockUserRepo = MockUserRepository(testUser);
      final mockRewardsRepo = MockRewardsRepository();
      final mockComplaintRepo = MockComplaintRepository();
      final mockConn = MockConnectivityService(online: true);

      // Add real sample reward events
      mockRewardsRepo.addEvents([
        RewardEvent(
          id: 'ev_1',
          citizenId: 'citizen_ui_qa',
          complaintId: 'c1',
          rewardType: 'resolved',
          description: 'Civic issue verified and successfully resolved',
          points: 35,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        RewardEvent(
          id: 'ev_2',
          citizenId: 'citizen_ui_qa',
          complaintId: 'c1',
          rewardType: 'in_progress',
          description: 'Field crew commenced on-ground resolution',
          points: 20,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: RewardsScreen(
            userRepository: mockUserRepo,
            rewardsRepository: mockRewardsRepo,
            complaintRepository: mockComplaintRepo,
            connectivityService: mockConn,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Current Level
      expect(find.text('Level 3 • Civic Champion'), findsOneWidget);
      expect(find.text('260'), findsOneWidget);
      expect(find.text('240 pts to Level 4: Civic Leader'), findsOneWidget);

      // 2. Civic Progress / Impact
      expect(find.text('Civic Impact'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      // 3. Reward History
      expect(find.text('Recent Reward Activity'), findsOneWidget);
      expect(find.text('+35'), findsOneWidget);
      expect(find.text('+20'), findsOneWidget);

      // 4. Achievement Badges
      expect(find.byType(AchievementCard), findsNWidgets(5));
      expect(find.text('Evidence Expert'), findsOneWidget);
      expect(find.text('Ground Reporter'), findsOneWidget);
      expect(find.text('Community Voice'), findsOneWidget);
      expect(find.text('Community Helper'), findsOneWidget);
      expect(find.text('Resolution Champion'), findsOneWidget);
    });

    testWidgets('RewardsScreen renders offline state banner when connectivity is lost', (tester) async {
      const testUser = UserModel(
        id: 'citizen_offline_qa',
        fullName: 'Meera Rao',
        email: 'meera@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
        civicPoints: 120, // Level 2 Civic Contributor
      );

      final mockUserRepo = MockUserRepository(testUser);
      final mockRewardsRepo = MockRewardsRepository();
      final mockComplaintRepo = MockComplaintRepository();
      final mockOfflineConn = MockConnectivityService(online: false);

      await tester.pumpWidget(
        MaterialApp(
          home: RewardsScreen(
            userRepository: mockUserRepo,
            rewardsRepository: mockRewardsRepo,
            complaintRepository: mockComplaintRepo,
            connectivityService: mockOfflineConn,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Offline banner is displayed
      expect(find.textContaining('Offline'), findsOneWidget);
      expect(find.text('Level 2 • Civic Contributor'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    });
  });
}
