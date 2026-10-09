import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/services/achievement_evaluator.dart';

void main() {
  const testCitizenId = 'citizen_beta_001';

  const defaultUser = UserModel(
    id: testCitizenId,
    fullName: 'Jane Citizen',
    email: 'jane@civicfix.org',
    phone: '+919876543210',
    role: 'citizen',
    civicPoints: 400,
    reportsSubmitted: 6,
    reportsResolved: 4,
  );

  ComplaintModel createComplaint({
    required String id,
    ComplaintStatus status = ComplaintStatus.reported,
    bool isEvidenceVerified = false,
    List<String> imageUrls = const [],
    double latitude = 19.0760,
    double longitude = 72.8777,
    int upvotes = 0,
  }) {
    return ComplaintModel(
      id: id,
      citizenId: testCitizenId,
      ticketNumber: 'CF-2026-ACH-$id',
      title: 'Issue #$id',
      description: 'Complaint description for test',
      category: CivicCategory.defaultCategories.first,
      status: status,
      priority: ComplaintPriority.high,
      location: CivicLocation(
        latitude: latitude,
        longitude: longitude,
        address: 'Mumbai Central',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
      evidenceVerificationStatus: isEvidenceVerified ? 'passed' : 'pending',
      departmentVerificationStatus: isEvidenceVerified ? 'passed' : 'pending',
      imageUrls: imageUrls,
      upvotes: upvotes,
    );
  }

  group('AchievementEvaluator & Canonical 5 Badges — Phase 3', () {
    test('Initial zero data evaluates all 5 badges as locked with 0 progress', () {
      const emptyUser = UserModel(
        id: testCitizenId,
        fullName: 'New Citizen',
        email: 'new@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
        civicPoints: 0,
        reportsSubmitted: 0,
        reportsResolved: 0,
      );

      final achievements = AchievementEvaluator.evaluateAchievements(
        user: emptyUser,
        complaints: [],
      );

      expect(achievements.length, equals(5));

      for (final a in achievements) {
        expect(a.isUnlocked, isFalse);
        expect(a.currentProgress, equals(0));
        expect(a.progressRatio, equals(0.0));
        expect(a.unlockedAt, isNull);
        expect(a.requirement, isNotEmpty);
      }

      final ids = achievements.map((a) => a.id).toList();
      expect(ids, containsAll([
        'evidence_expert',
        'ground_reporter',
        'community_voice',
        'community_helper',
        'resolution_champion',
      ]));
    });

    test('Evidence Expert unlocks at 5 verified complaints with photos', () {
      // 3 verified complaints with photos (progress: 3/5)
      final partialComplaints = List.generate(
        3,
        (i) => createComplaint(
          id: 'c_$i',
          status: ComplaintStatus.verified,
          isEvidenceVerified: true,
          imageUrls: ['https://storage.civicfix.org/photo_$i.jpg'],
        ),
      );

      var achievements = AchievementEvaluator.evaluateAchievements(
        user: defaultUser,
        complaints: partialComplaints,
      );

      var evidenceExpert = achievements.firstWhere((a) => a.id == 'evidence_expert');
      expect(evidenceExpert.isUnlocked, isFalse);
      expect(evidenceExpert.currentProgress, equals(3));
      expect(evidenceExpert.targetProgress, equals(5));
      expect(evidenceExpert.progressRatio, equals(0.6));

      // Add 2 more to reach 5 (progress: 5/5 -> Unlocked)
      final completeComplaints = [
        ...partialComplaints,
        createComplaint(
          id: 'c_3',
          status: ComplaintStatus.assigned,
          isEvidenceVerified: true,
          imageUrls: ['https://storage.civicfix.org/photo_3.jpg'],
        ),
        createComplaint(
          id: 'c_4',
          status: ComplaintStatus.resolved,
          isEvidenceVerified: true,
          imageUrls: ['https://storage.civicfix.org/photo_4.jpg'],
        ),
      ];

      achievements = AchievementEvaluator.evaluateAchievements(
        user: defaultUser,
        complaints: completeComplaints,
      );

      evidenceExpert = achievements.firstWhere((a) => a.id == 'evidence_expert');
      expect(evidenceExpert.isUnlocked, isTrue);
      expect(evidenceExpert.currentProgress, equals(5));
      expect(evidenceExpert.progressRatio, equals(1.0));
      expect(evidenceExpert.unlockedAt, isNotNull);
    });

    test('Ground Reporter unlocks at 5 verified complaints with GPS coordinates', () {
      final complaints = List.generate(
        5,
        (i) => createComplaint(
          id: 'gr_$i',
          status: ComplaintStatus.inProgress,
          isEvidenceVerified: true,
          latitude: 19.0760 + (i * 0.001),
          longitude: 72.8777 + (i * 0.001),
        ),
      );

      final achievements = AchievementEvaluator.evaluateAchievements(
        user: defaultUser,
        complaints: complaints,
      );

      final groundReporter = achievements.firstWhere((a) => a.id == 'ground_reporter');
      expect(groundReporter.isUnlocked, isTrue);
      expect(groundReporter.currentProgress, equals(5));
      expect(groundReporter.targetProgress, equals(5));
      expect(groundReporter.progressRatio, equals(1.0));
    });

    test('Community Voice unlocks at 10 total community upvotes received', () {
      final complaints = [
        createComplaint(id: 'cv_1', upvotes: 4),
        createComplaint(id: 'cv_2', upvotes: 3),
        createComplaint(id: 'cv_3', upvotes: 3),
      ]; // total 10 upvotes

      final achievements = AchievementEvaluator.evaluateAchievements(
        user: defaultUser,
        complaints: complaints,
      );

      final communityVoice = achievements.firstWhere((a) => a.id == 'community_voice');
      expect(communityVoice.isUnlocked, isTrue);
      expect(communityVoice.currentProgress, equals(10));
      expect(communityVoice.targetProgress, equals(10));
      expect(communityVoice.progressRatio, equals(1.0));
    });

    test('Community Helper unlocks at 10 supported complaints by others', () {
      final achievements = AchievementEvaluator.evaluateAchievements(
        user: defaultUser,
        complaints: [],
        supportedComplaintsCount: 10,
      );

      final helper = achievements.firstWhere((a) => a.id == 'community_helper');
      expect(helper.isUnlocked, isTrue);
      expect(helper.currentProgress, equals(10));
      expect(helper.targetProgress, equals(10));
    });

    test('Resolution Champion unlocks at 5 resolved complaints', () {
      final complaints = List.generate(
        5,
        (i) => createComplaint(
          id: 'rc_$i',
          status: ComplaintStatus.resolved,
        ),
      );

      final achievements = AchievementEvaluator.evaluateAchievements(
        user: defaultUser,
        complaints: complaints,
      );

      final resolutionChampion = achievements.firstWhere((a) => a.id == 'resolution_champion');
      expect(resolutionChampion.isUnlocked, isTrue);
      expect(resolutionChampion.currentProgress, equals(5));
      expect(resolutionChampion.progressRatio, equals(1.0));
    });

    test('Unlock happens only once and unlockedAt timestamp is immutable', () {
      final originalUnlockTime = DateTime(2026, 10, 1, 14, 30);

      final previouslyUnlocked = CivicAchievement(
        id: 'evidence_expert',
        title: 'Evidence Expert',
        description: 'Useful evidence helps officers act.',
        howToUnlock: 'Provide useful images on 5 verified complaints.',
        icon: CivicAchievement.defaultAchievements()[0].icon,
        isUnlocked: true,
        unlockedAt: originalUnlockTime,
        currentProgress: 5,
        targetProgress: 5,
      );

      // Evaluate again with fewer current complaints (e.g. archived records)
      final achievements = AchievementEvaluator.evaluateAchievements(
        user: defaultUser,
        complaints: [],
        existingAchievements: [previouslyUnlocked],
      );

      final reevaluated = achievements.firstWhere((a) => a.id == 'evidence_expert');
      expect(reevaluated.isUnlocked, isTrue);
      expect(reevaluated.unlockedAt, equals(originalUnlockTime));
    });
  });
}
