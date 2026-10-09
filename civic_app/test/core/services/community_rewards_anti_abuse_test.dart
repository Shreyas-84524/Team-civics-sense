import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/services/achievement_evaluator.dart';
import 'package:civic_app/core/services/reward_evaluation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CIVICFIX REWARDS & GAMIFICATION — PHASE 4: COMMUNITY REWARDS & ANTI-ABUSE', () {
    late RewardEvaluationService service;

    setUp(() {
      service = RewardEvaluationService();
      service.resetState();
    });

    ComplaintModel createComplaint({
      required String id,
      String citizenId = 'citizen_123',
      ComplaintStatus status = ComplaintStatus.underVerification,
      String evidenceVerificationStatus = 'passed',
      String departmentVerificationStatus = 'passed',
      String verificationStage = 'verification_completed',
      String? verificationFailureReason,
      String? lastAiFailureCode,
      int upvotes = 0,
      int reopenCount = 0,
      List<String> imageUrls = const ['https://example.com/photo.jpg'],
    }) {
      return ComplaintModel(
        id: id,
        citizenId: citizenId,
        ticketNumber: 'CF-2026-$id',
        title: 'Issue $id',
        description: 'Description for $id',
        category: CivicCategory.defaultCategories.first,
        status: status,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Mumbai Central',
          ward: 'G/North',
        ),
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        upvotes: upvotes,
        reopenCount: reopenCount,
        evidenceVerificationStatus: evidenceVerificationStatus,
        departmentVerificationStatus: departmentVerificationStatus,
        verificationStage: verificationStage,
        verificationFailureReason: verificationFailureReason,
        lastAiFailureCode: lastAiFailureCode,
      );
    }

    test('Self-upvote is strictly blocked from community rewards', () async {
      final complaint = createComplaint(
        id: 'cmp_101',
        citizenId: 'citizen_123',
        status: ComplaintStatus.verified,
      );

      final result = await service.evaluateCommunityUpvote(
        voterId: 'citizen_123', // Same as complaint.citizenId
        complaint: complaint,
      );

      expect(result.granted, isFalse);
      expect(result.pointsAwarded, equals(0));
      expect(result.reason, contains('Self-upvotes are ineligible'));
    });

    test('Duplicate upvote is blocked from generating reward points', () async {
      final complaint = createComplaint(
        id: 'cmp_102',
        citizenId: 'citizen_owner',
        status: ComplaintStatus.verified,
      );

      // First upvote from citizen_voter
      final firstResult = await service.evaluateCommunityUpvote(
        voterId: 'citizen_voter',
        complaint: complaint,
      );
      expect(firstResult.granted, isTrue);

      // Repeated upvote from the same citizen_voter
      final duplicateResult = await service.evaluateCommunityUpvote(
        voterId: 'citizen_voter',
        complaint: complaint,
      );
      expect(duplicateResult.granted, isFalse);
      expect(duplicateResult.reason, contains('already recorded'));
    });

    test('Upvote toggle farming (repeated on/off cycles) is strictly blocked', () async {
      final complaint = createComplaint(
        id: 'cmp_103',
        citizenId: 'citizen_owner',
        status: ComplaintStatus.verified,
      );

      final r1 = await service.evaluateCommunityUpvote(voterId: 'voter_A', complaint: complaint);
      expect(r1.granted, isTrue);

      // Simulating toggle: trying to upvote again
      final r2 = await service.evaluateCommunityUpvote(voterId: 'voter_A', complaint: complaint);
      expect(r2.granted, isFalse);

      final r3 = await service.evaluateCommunityUpvote(voterId: 'voter_A', complaint: complaint);
      expect(r3.granted, isFalse);
    });

    test('Rejected / fraudulent complaints are strictly blocked from rewards', () async {
      final rejectedComplaint = createComplaint(
        id: 'cmp_rejected',
        citizenId: 'citizen_bad',
        status: ComplaintStatus.rejected,
        evidenceVerificationStatus: 'failed',
        verificationStage: 'evidence_failed',
      );

      // 1. Stage progression beyond submitted is blocked
      final verifiedResult = await service.evaluateStage(
        complaint: rejectedComplaint,
        stage: RewardLifecycleStage.verified,
      );
      expect(verifiedResult.granted, isFalse);
      expect(verifiedResult.reason, contains('rejected'));

      final resolvedResult = await service.evaluateStage(
        complaint: rejectedComplaint,
        stage: RewardLifecycleStage.resolved,
      );
      expect(resolvedResult.granted, isFalse);

      // 2. Community upvotes on rejected complaints are blocked
      final upvoteResult = await service.evaluateCommunityUpvote(
        voterId: 'citizen_good',
        complaint: rejectedComplaint,
      );
      expect(upvoteResult.granted, isFalse);
      expect(upvoteResult.reason, contains('Rejected or fraudulent complaints cannot receive'));
    });

    test('Duplicate complaints are strictly quarantined from reward farming', () async {
      final duplicateComplaint = createComplaint(
        id: 'cmp_duplicate',
        citizenId: 'citizen_spammer',
        status: ComplaintStatus.underVerification,
        verificationFailureReason: 'Identified as duplicate of ticket CF-2026-cmp_001',
      );

      // 1. Lifecycle rewards blocked
      final submittedResult = await service.evaluateStage(
        complaint: duplicateComplaint,
        stage: RewardLifecycleStage.submitted,
      );
      expect(submittedResult.granted, isFalse);
      expect(submittedResult.reason, contains('Duplicate complaints are ineligible'));

      // 2. Community rewards blocked
      final upvoteResult = await service.evaluateCommunityUpvote(
        voterId: 'citizen_helper',
        complaint: duplicateComplaint,
      );
      expect(upvoteResult.granted, isFalse);
      expect(upvoteResult.reason, contains('Duplicate complaints cannot receive'));
    });

    test('Reopened / reworked complaints do NOT re-award completed lifecycle stages', () async {
      final complaint = createComplaint(
        id: 'cmp_reopened',
        citizenId: 'citizen_777',
        status: ComplaintStatus.resolved,
      );

      // Award all stages up to resolved (100 points)
      final stageResults = await service.evaluateAllEligibleStages(complaint: complaint);
      final grantedStages = stageResults.where((r) => r.granted).toList();
      expect(grantedStages.length, equals(5)); // submitted (10) + verified (20) + assigned (15) + inProgress (20) + resolved (35) = 100
      expect(await service.getComplaintAwardedPoints('cmp_reopened'), equals(100));

      // Now simulate supervisory rework: ticket reopened back to inProgress with reworkCount: 1
      final reopenedComplaint = complaint.copyWith(
        status: ComplaintStatus.inProgress,
        reopenCount: 1,
      );

      // Evaluate inProgress stage again
      final reworkInProgressResult = await service.evaluateStage(
        complaint: reopenedComplaint,
        stage: RewardLifecycleStage.inProgress,
      );
      expect(reworkInProgressResult.granted, isFalse);
      expect(reworkInProgressResult.pointsAwarded, equals(0));
      expect(reworkInProgressResult.reason, contains('already been awarded'));

      // Re-advance to resolved again
      final reResolvedComplaint = reopenedComplaint.copyWith(
        status: ComplaintStatus.resolved,
      );
      final reResolvedResult = await service.evaluateStage(
        complaint: reResolvedComplaint,
        stage: RewardLifecycleStage.resolved,
      );
      expect(reResolvedResult.granted, isFalse);
      expect(reResolvedResult.pointsAwarded, equals(0));
      expect(reResolvedResult.reason, contains('already been awarded'));

      // Total awarded remains 100
      expect(await service.getComplaintAwardedPoints('cmp_reopened'), equals(100));
    });

    test('Valid Community Voice progress derives correctly from legitimate complaints only', () {
      const user = UserModel(
        id: 'citizen_creator',
        fullName: 'Creator',
        email: 'c@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
      );

      final legitComplaint1 = createComplaint(
        id: 'c1',
        citizenId: 'citizen_creator',
        status: ComplaintStatus.verified,
        upvotes: 4,
      );
      final legitComplaint2 = createComplaint(
        id: 'c2',
        citizenId: 'citizen_creator',
        status: ComplaintStatus.resolved,
        upvotes: 6,
      );
      final rejectedComplaint = createComplaint(
        id: 'c3',
        citizenId: 'citizen_creator',
        status: ComplaintStatus.rejected,
        evidenceVerificationStatus: 'failed',
        upvotes: 20, // Should be ignored by anti-abuse filter
      );
      final duplicateComplaint = createComplaint(
        id: 'c4',
        citizenId: 'citizen_creator',
        status: ComplaintStatus.verified,
        verificationFailureReason: 'Duplicate ticket',
        upvotes: 50, // Should be ignored by anti-abuse filter
      );

      final achievements = AchievementEvaluator.evaluateAchievements(
        user: user,
        complaints: [legitComplaint1, legitComplaint2, rejectedComplaint, duplicateComplaint],
      );

      final communityVoice = achievements.firstWhere((a) => a.id == 'community_voice');
      // 4 + 6 = 10 legitimate upvotes (rejected 20 and duplicate 50 are filtered out)
      expect(communityVoice.currentProgress, equals(10));
      expect(communityVoice.isUnlocked, isTrue);
    });

    test('Valid Community Helper progress derives correctly and unlocks at 10 verified complaints by others', () async {
      const user = UserModel(
        id: 'citizen_helper_hero',
        fullName: 'Helper Hero',
        email: 'hero@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
      );

      // Generate 10 distinct verified complaints by OTHER citizens
      final supportedComplaints = List.generate(10, (i) {
        return createComplaint(
          id: 'other_cmp_$i',
          citizenId: 'other_citizen_$i',
          status: ComplaintStatus.verified,
        );
      });

      // Also add self-complaint, duplicate complaint, and rejected complaint (should all be filtered out)
      final spamComplaints = [
        createComplaint(id: 'self_1', citizenId: 'citizen_helper_hero', status: ComplaintStatus.verified),
        createComplaint(id: 'bad_1', citizenId: 'other_x', status: ComplaintStatus.rejected, evidenceVerificationStatus: 'failed'),
        createComplaint(id: 'dup_1', citizenId: 'other_y', status: ComplaintStatus.verified, verificationFailureReason: 'Duplicate'),
      ];

      final allSupported = [...supportedComplaints, ...spamComplaints];

      // 1. Evaluate achievement
      final achievements = AchievementEvaluator.evaluateAchievements(
        user: user,
        supportedComplaints: allSupported,
      );

      final communityHelper = achievements.firstWhere((a) => a.id == 'community_helper');
      expect(communityHelper.currentProgress, equals(10));
      expect(communityHelper.isUnlocked, isTrue);

      // 2. Evaluate one-time bonus in RewardEvaluationService
      final bonusResult = await service.evaluateCommunityHelperBonus(
        citizenId: 'citizen_helper_hero',
        supportedComplaints: allSupported,
      );
      expect(bonusResult.granted, isTrue);
      expect(bonusResult.pointsAwarded, equals(10));

      // 3. Repeated bonus evaluation is blocked (idempotent)
      final repeatBonus = await service.evaluateCommunityHelperBonus(
        citizenId: 'citizen_helper_hero',
        supportedComplaints: allSupported,
      );
      expect(repeatBonus.granted, isFalse);
      expect(repeatBonus.reason, contains('already been awarded'));
    });
  });
}
