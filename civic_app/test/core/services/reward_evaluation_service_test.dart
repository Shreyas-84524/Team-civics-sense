import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/user_repository.dart';
import 'package:civic_app/core/services/reward_evaluation_service.dart';

class FakeUserRepository implements UserRepository {
  UserModel _user;
  final ValueNotifier<UserModel> _userNotifier;

  FakeUserRepository(this._user) : _userNotifier = ValueNotifier<UserModel>(_user);

  @override
  Future<UserModel> getCurrentUser() async => _user;

  @override
  ValueListenable<UserModel> getUserListenable() => _userNotifier;

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

  void setUser(UserModel user) {
    _user = user;
    _userNotifier.value = user;
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

void main() {
  late RewardEvaluationService rewardService;
  late FakeUserRepository fakeUserRepository;

  const testCitizenId = 'citizen_alpha_001';
  const testComplaintId = 'complaint_pothole_999';

  setUp(() {
    fakeUserRepository = FakeUserRepository(
      const UserModel(
        id: testCitizenId,
        fullName: 'John Citizen',
        email: 'john@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
        civicPoints: 0,
        reportsSubmitted: 0,
        reportsResolved: 0,
      ),
    );

    rewardService = RewardEvaluationService(
      userRepository: fakeUserRepository,
    );
    rewardService.resetState();
  });

  ComplaintModel createComplaint({
    String id = testComplaintId,
    String citizenId = testCitizenId,
    ComplaintStatus status = ComplaintStatus.reported,
    String evidenceVerificationStatus = 'pending',
    String departmentVerificationStatus = 'pending',
    String? verificationFailureReason,
    String? assignedTo,
    String? assignedFieldOfficerId,
    DateTime? workStartedAt,
    DateTime? resolvedAt,
    int reopenCount = 0,
    DateTime? reopenedAt,
  }) {
    final now = DateTime.now();
    return ComplaintModel(
      id: id,
      citizenId: citizenId,
      ticketNumber: 'CF-2026-TEST-001',
      title: 'Pothole on Main Street',
      description: 'Severe pothole damaging vehicles',
      category: CivicCategory.defaultCategories.first,
      status: status,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Main Street, Ward 12',
      ),
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
      evidenceVerificationStatus: evidenceVerificationStatus,
      departmentVerificationStatus: departmentVerificationStatus,
      verificationFailureReason: verificationFailureReason,
      assignedTo: assignedTo,
      assignedFieldOfficerId: assignedFieldOfficerId,
      workStartedAt: workStartedAt,
      resolvedAt: resolvedAt,
      reopenCount: reopenCount,
      reopenedAt: reopenedAt,
    );
  }

  group('RewardEvaluationService — Lifecycle Points & Gamification Phase 1', () {
    test('Full complaint lifecycle awards exactly 100 points (10 + 20 + 15 + 20 + 35)', () async {
      // 1. Submitted (+10)
      var complaint = createComplaint(status: ComplaintStatus.reported);
      final subRes = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.submitted,
      );
      expect(subRes.granted, isTrue);
      expect(subRes.pointsAwarded, equals(10));
      expect(subRes.totalComplaintPoints, equals(10));

      // 2. Verified (+20)
      complaint = complaint.copyWith(
        status: ComplaintStatus.verified,
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'passed',
      );
      final verRes = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.verified,
      );
      expect(verRes.granted, isTrue);
      expect(verRes.pointsAwarded, equals(20));
      expect(verRes.totalComplaintPoints, equals(30));

      // 3. Assigned (+15)
      complaint = complaint.copyWith(
        status: ComplaintStatus.assigned,
        assignedTo: 'officer_sharma',
      );
      final assRes = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.assigned,
      );
      expect(assRes.granted, isTrue);
      expect(assRes.pointsAwarded, equals(15));
      expect(assRes.totalComplaintPoints, equals(45));

      // 4. In Progress (+20)
      complaint = complaint.copyWith(
        status: ComplaintStatus.inProgress,
        workStartedAt: DateTime.now(),
      );
      final progRes = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.inProgress,
      );
      expect(progRes.granted, isTrue);
      expect(progRes.pointsAwarded, equals(20));
      expect(progRes.totalComplaintPoints, equals(65));

      // 5. Resolved (+35)
      complaint = complaint.copyWith(
        status: ComplaintStatus.resolved,
        resolvedAt: DateTime.now(),
      );
      final resRes = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.resolved,
      );
      expect(resRes.granted, isTrue);
      expect(resRes.pointsAwarded, equals(35));
      expect(resRes.totalComplaintPoints, equals(100));

      // Total complaint points verification
      final complaintTotal = await rewardService.getComplaintAwardedPoints(testComplaintId);
      expect(complaintTotal, equals(100));

      // Awarded stages verification
      final stages = await rewardService.getAwardedStages(testComplaintId);
      expect(stages.length, equals(5));
      expect(stages, containsAll(RewardLifecycleStage.values));
    });

    test('Repeated stage awards 0 points (Idempotency guarantee)', () async {
      final complaint = createComplaint(
        status: ComplaintStatus.assigned,
        evidenceVerificationStatus: 'passed',
        assignedTo: 'officer_sharma',
      );

      // First evaluation of assigned (+15)
      final firstAssigned = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.assigned,
      );
      expect(firstAssigned.granted, isTrue);
      expect(firstAssigned.pointsAwarded, equals(15));

      // Repeated evaluation of assigned (+0)
      final duplicateAssigned = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.assigned,
      );
      expect(duplicateAssigned.granted, isFalse);
      expect(duplicateAssigned.pointsAwarded, equals(0));
      expect(duplicateAssigned.reason, contains('already been awarded'));

      // Total complaint points remains 15
      final total = await rewardService.getComplaintAwardedPoints(testComplaintId);
      expect(total, equals(15));
    });

    test('Reopened complaint does not re-award earlier or subsequent repeated stages', () async {
      // Complete full lifecycle to 100 points
      var complaint = createComplaint(
        status: ComplaintStatus.resolved,
        evidenceVerificationStatus: 'passed',
        assignedTo: 'officer_sharma',
        workStartedAt: DateTime.now().subtract(const Duration(hours: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final batch = await rewardService.evaluateAllEligibleStages(complaint: complaint);
      final totalBatchPoints = batch.fold<int>(0, (sum, item) => sum + item.pointsAwarded);
      expect(totalBatchPoints, equals(100));

      // Citizen reopens complaint -> transitions back to inProgress
      complaint = complaint.copyWith(
        status: ComplaintStatus.inProgress,
        reopenCount: 1,
        reopenedAt: DateTime.now(),
      );

      // Re-evaluate inProgress stage on reopened complaint
      final reopenProgRes = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.inProgress,
      );
      expect(reopenProgRes.granted, isFalse);
      expect(reopenProgRes.pointsAwarded, equals(0));

      // Re-resolve complaint
      complaint = complaint.copyWith(
        status: ComplaintStatus.resolved,
        resolvedAt: DateTime.now(),
      );

      final reResolveRes = await rewardService.evaluateStage(
        complaint: complaint,
        stage: RewardLifecycleStage.resolved,
      );
      expect(reResolveRes.granted, isFalse);
      expect(reResolveRes.pointsAwarded, equals(0));

      // Total remains strictly 100
      final total = await rewardService.getComplaintAwardedPoints(testComplaintId);
      expect(total, equals(100));
    });

    test('Rejected / AI-generated fake evidence complaints are blocked from later rewards', () async {
      // Rejected complaint
      final rejectedComplaint = createComplaint(
        status: ComplaintStatus.rejected,
        evidenceVerificationStatus: 'failed',
        verificationFailureReason: 'AI synthetic texture detected with 98% confidence',
      );

      final verifiedRes = await rewardService.evaluateStage(
        complaint: rejectedComplaint,
        stage: RewardLifecycleStage.verified,
      );
      expect(verifiedRes.granted, isFalse);
      expect(verifiedRes.pointsAwarded, equals(0));
      expect(verifiedRes.reason, contains('rejected'));

      final assignedRes = await rewardService.evaluateStage(
        complaint: rejectedComplaint,
        stage: RewardLifecycleStage.assigned,
      );
      expect(assignedRes.granted, isFalse);
      expect(assignedRes.pointsAwarded, equals(0));

      final resolvedRes = await rewardService.evaluateStage(
        complaint: rejectedComplaint,
        stage: RewardLifecycleStage.resolved,
      );
      expect(resolvedRes.granted, isFalse);
      expect(resolvedRes.pointsAwarded, equals(0));
    });

    test('Duplicate complaints cannot farm reward progression', () async {
      final duplicateComplaint = createComplaint(
        status: ComplaintStatus.reported,
        verificationFailureReason: 'Duplicate complaint detected for nearby incident',
      );

      final subRes = await rewardService.evaluateStage(
        complaint: duplicateComplaint,
        stage: RewardLifecycleStage.submitted,
      );
      expect(subRes.granted, isFalse);
      expect(subRes.pointsAwarded, equals(0));
      expect(subRes.reason, contains('Duplicate'));
    });

    test('evaluateAllEligibleStages progresses multi-stage jumps seamlessly up to 100 points', () async {
      final jumpedComplaint = createComplaint(
        status: ComplaintStatus.resolved,
        evidenceVerificationStatus: 'passed',
        assignedTo: 'officer_sharma',
        workStartedAt: DateTime.now(),
        resolvedAt: DateTime.now(),
      );

      final results = await rewardService.evaluateAllEligibleStages(complaint: jumpedComplaint);
      expect(results.length, equals(5));
      expect(results.every((r) => r.granted), isTrue);

      final totalAwarded = results.fold<int>(0, (sum, r) => sum + r.pointsAwarded);
      expect(totalAwarded, equals(100));

      final total = await rewardService.getComplaintAwardedPoints(testComplaintId);
      expect(total, equals(100));
    });

    test('Reward history records all canonical RewardEvent objects with metadata', () async {
      final complaint = createComplaint(
        status: ComplaintStatus.resolved,
        evidenceVerificationStatus: 'passed',
        assignedTo: 'officer_sharma',
        workStartedAt: DateTime.now(),
        resolvedAt: DateTime.now(),
      );

      await rewardService.evaluateAllEligibleStages(complaint: complaint);

      final history = await rewardService.getRewardHistory(testCitizenId);
      expect(history.length, equals(5));

      final firstEvent = history.first;
      expect(firstEvent.citizenId, equals(testCitizenId));
      expect(firstEvent.complaintId, equals(testComplaintId));
      expect(firstEvent.complaintTitle, equals('Pothole on Main Street'));
      expect(firstEvent.points, greaterThan(0));
      expect(firstEvent.metadata, isNotNull);
      expect(firstEvent.metadata['ticketNumber'], equals('CF-2026-TEST-001'));
    });
  });
}
