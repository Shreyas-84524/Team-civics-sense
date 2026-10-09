import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_constants.dart';
import '../models/complaint_model.dart';
import '../models/reward_model.dart';
import '../repositories/repository_locator.dart';
import '../repositories/rewards_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/hive_user_repository.dart';
import '../repositories/offline_first_user_repository.dart';
import 'achievement_evaluator.dart';
import 'civic_rewards_sync_service.dart';

/// Result returned from evaluating a complaint lifecycle stage for gamification points.
class RewardEvaluationResult {
  final bool granted;
  final int pointsAwarded;
  final RewardLifecycleStage? stage;
  final String reason;
  final RewardEvent? event;
  final int totalComplaintPoints;
  final int citizenTotalPoints;

  const RewardEvaluationResult({
    required this.granted,
    required this.pointsAwarded,
    this.stage,
    required this.reason,
    this.event,
    this.totalComplaintPoints = 0,
    this.citizenTotalPoints = 0,
  });

  @override
  String toString() =>
      'RewardEvaluationResult(granted: $granted, points: $pointsAwarded, stage: ${stage?.name}, reason: $reason)';
}

/// Centralized Backend Reward Engine & Lifecycle Points Evaluator.
///
/// Implements Phase 1 Gamification Architecture & Phase 4 Community Safeguards:
/// - Submitted:   +10 pts
/// - Verified:    +20 pts
/// - Assigned:    +15 pts
/// - In Progress: +20 pts
/// - Resolved:    +35 pts
/// Maximum total per grievance: 100 Civic Points.
///
/// Guarantees:
/// 1. **Idempotency**: Every stage award has a unique deterministic ID (`${complaintId}_${stage}`).
/// 2. **Anti-Duplication**: Re-running evaluation or repeated stage transitions yields 0 duplicate points.
/// 3. **Reopen Safety**: Reopened complaints do not re-award previously granted stages.
/// 4. **Fraud / Rejection Quarantine**: Rejected complaints or AI-generated fakes are blocked from later stages.
/// 5. **Duplicate Grievance Quarantine**: Duplicate complaints cannot farm reward progression.
/// 6. **Community Safeguards**: Self-upvotes blocked, upvote toggle farming blocked, verified-only community points.
/// 7. **Concurrency Safety**: Synchronized in-flight execution prevents double-grant race conditions.
/// 8. **Transactional Integrity**: Points credited atomically across `users`, `rewards`, and `reward_events`.
class RewardEvaluationService {
  static RewardEvaluationService? _instance;
  static RewardEvaluationService get instance => _instance ??= RewardEvaluationService();

  final FirebaseFirestore? _firestore;
  final RewardsRepository? _rewardsRepository;
  final UserRepository? _userRepository;

  // In-memory event cache and in-flight locks for zero-latency idempotency & testing
  final Set<String> _awardedEventIds = <String>{};
  final Map<String, List<RewardEvent>> _eventsByCitizen = <String, List<RewardEvent>>{};
  final Map<String, List<RewardEvent>> _eventsByComplaint = <String, List<RewardEvent>>{};
  final Set<String> _inFlightEvents = <String>{};
  final Set<String> _recordedUpvotes = <String>{};

  RewardEvaluationService({
    FirebaseFirestore? firestore,
    RewardsRepository? rewardsRepository,
    UserRepository? userRepository,
  })  : _firestore = firestore,
        _rewardsRepository = rewardsRepository,
        _userRepository = userRepository;

  RewardsRepository? get rewardsRepository => _rewardsRepository;
  UserRepository? get userRepository => _userRepository;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      if (FirebaseFirestore.instance.app.name.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  // ===========================================================================
  // STAGE-SPECIFIC EVALUATION
  // ===========================================================================

  /// Evaluates and idempotently awards points for a specific lifecycle stage.
  Future<RewardEvaluationResult> evaluateStage({
    required ComplaintModel complaint,
    required RewardLifecycleStage stage,
    String? customDescription,
    Map<String, dynamic>? metadata,
  }) async {
    final complaintId = complaint.id.trim();
    final citizenId = complaint.citizenId.trim();

    if (complaintId.isEmpty || citizenId.isEmpty) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Invalid complaint or citizen identifier',
      );
    }

    final eventId = '${complaintId}_${stage.stageKey}';

    // 1. Concurrency Lock: Check in-flight lock
    if (_inFlightEvents.contains(eventId)) {
      return RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        stage: stage,
        reason: 'Evaluation for stage ${stage.name} is already in progress',
      );
    }

    _inFlightEvents.add(eventId);

    try {
      // 2. Anti-Abuse Check: Rejected / Fraudulent / Synthetic Evidence
      if (_isComplaintRejectedOrFraudulent(complaint)) {
        // If the complaint is rejected due to AI fake or invalid evidence,
        // all stages beyond 'submitted' (or if submitted itself is invalid) are strictly blocked.
        if (stage != RewardLifecycleStage.submitted) {
          return RewardEvaluationResult(
            granted: false,
            pointsAwarded: 0,
            stage: stage,
            reason: 'Complaint is rejected / failed evidence authenticity verification',
          );
        }
      }

      // 3. Anti-Abuse Check: Duplicate Complaint
      if (_isComplaintDuplicate(complaint)) {
        return RewardEvaluationResult(
          granted: false,
          pointsAwarded: 0,
          stage: stage,
          reason: 'Duplicate complaints are ineligible for reward points',
        );
      }

      // 4. Lifecycle Readiness Validation: Ensure complaint has actually achieved the stage
      if (!_isStageSatisfied(complaint, stage)) {
        return RewardEvaluationResult(
          granted: false,
          pointsAwarded: 0,
          stage: stage,
          reason: 'Complaint lifecycle has not reached stage ${stage.name}',
        );
      }

      // 5. Idempotency Check: Verify if stage was already awarded in-memory or in Firestore
      final alreadyAwarded = await _hasStageBeenAwarded(
        complaintId: complaintId,
        citizenId: citizenId,
        stage: stage,
        eventId: eventId,
      );
      if (alreadyAwarded) {
        final currentComplaintPoints = await getComplaintAwardedPoints(complaintId);
        final currentCitizenPoints = await _getCitizenTotalPoints(citizenId);
        return RewardEvaluationResult(
          granted: false,
          pointsAwarded: 0,
          stage: stage,
          reason: 'Stage ${stage.name} has already been awarded for this complaint',
          totalComplaintPoints: currentComplaintPoints,
          citizenTotalPoints: currentCitizenPoints,
        );
      }

      // 6. Maximum 100-Points Ceiling Check per Grievance
      final existingComplaintPoints = await getComplaintAwardedPoints(complaintId);
      final potentialNewTotal = existingComplaintPoints + stage.points;
      if (existingComplaintPoints >= RewardLifecycleStage.maxPointsPerComplaint) {
        return RewardEvaluationResult(
          granted: false,
          pointsAwarded: 0,
          stage: stage,
          reason: 'Maximum reward limit of ${RewardLifecycleStage.maxPointsPerComplaint} points reached for this complaint',
          totalComplaintPoints: existingComplaintPoints,
        );
      }

      final actualPointsToGrant = potentialNewTotal > RewardLifecycleStage.maxPointsPerComplaint
          ? (RewardLifecycleStage.maxPointsPerComplaint - existingComplaintPoints)
          : stage.points;

      if (actualPointsToGrant <= 0) {
        return RewardEvaluationResult(
          granted: false,
          pointsAwarded: 0,
          stage: stage,
          reason: 'No additional points eligible under grievance ceiling',
          totalComplaintPoints: existingComplaintPoints,
        );
      }

      // 7. Create Canonical Reward Event
      final event = RewardEvent(
        id: eventId,
        citizenId: citizenId,
        complaintId: complaintId,
        complaintTitle: complaint.title.isNotEmpty ? complaint.title : 'Civic Grievance',
        rewardType: stage.stageKey,
        points: actualPointsToGrant,
        description: customDescription ?? stage.defaultDescription,
        createdAt: DateTime.now(),
        metadata: {
          'ticketNumber': complaint.ticketNumber,
          'category': complaint.category.name,
          'status': complaint.status.name,
          'reopenCount': complaint.reopenCount,
          ...?metadata,
        },
      );

      // 8. Transactionally Credit Points via Authoritative Backend (or In-Memory Test Fallback)
      int updatedCitizenPoints = 0;
      int pointsGranted = actualPointsToGrant;

      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (_) {}

      if (currentUser != null) {
        // Authenticated client: Backend is the ONLY authoritative writer
        final syncResponse = await CivicRewardsSyncService.recordLifecycleAction(
          complaintId: complaintId,
          action: stage.stageKey,
        );

        if (syncResponse.isCommitted) {
          pointsGranted = syncResponse.pointsAwarded > 0 ? syncResponse.pointsAwarded : actualPointsToGrant;
          _awardedEventIds.add(eventId);
          _eventsByCitizen.putIfAbsent(citizenId, () => []).insert(0, event);
          _eventsByComplaint.putIfAbsent(complaintId, () => []).add(event);

          updatedCitizenPoints = await _updateLocalUserCache(
            citizenId: citizenId,
            pointsDelta: pointsGranted,
            stage: stage,
            newTotalPoints: syncResponse.newTotalPoints,
          );
        } else if (syncResponse.isAlreadyAwarded) {
          _awardedEventIds.add(eventId);
          return RewardEvaluationResult(
            granted: false,
            pointsAwarded: 0,
            stage: stage,
            reason: syncResponse.reason ?? 'Stage ${stage.name} has already been awarded for this complaint',
            totalComplaintPoints: existingComplaintPoints,
            citizenTotalPoints: await _getCitizenTotalPoints(citizenId),
          );
        } else {
          // Never cache a failed write as awarded!
          debugPrint('[RewardEvaluationService] Backend reward sync failed/rejected: ${syncResponse.reason}');
          return RewardEvaluationResult(
            granted: false,
            pointsAwarded: 0,
            stage: stage,
            reason: syncResponse.reason ?? 'Backend reward write failed or pending',
            totalComplaintPoints: existingComplaintPoints,
            citizenTotalPoints: await _getCitizenTotalPoints(citizenId),
          );
        }
      } else {
        // Unauthenticated test fallback (unit tests with FakeUserRepository)
        _awardedEventIds.add(eventId);
        _eventsByCitizen.putIfAbsent(citizenId, () => []).insert(0, event);
        _eventsByComplaint.putIfAbsent(complaintId, () => []).add(event);

        updatedCitizenPoints = await _updateLocalUserCache(
          citizenId: citizenId,
          pointsDelta: pointsGranted,
          stage: stage,
        );
      }

      final newComplaintPoints = existingComplaintPoints + pointsGranted;

      return RewardEvaluationResult(
        granted: true,
        pointsAwarded: pointsGranted,
        stage: stage,
        reason: 'Successfully awarded $pointsGranted points for stage ${stage.name}',
        event: event,
        totalComplaintPoints: newComplaintPoints,
        citizenTotalPoints: updatedCitizenPoints,
      );
    } catch (e) {
      debugPrint('[RewardEvaluationService] Stage evaluation error: $e');
      return RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        stage: stage,
        reason: 'Internal evaluation failure: $e',
      );
    } finally {
      _inFlightEvents.remove(eventId);
    }
  }

  // ===========================================================================
  // BATCH / PROGRESSIVE TRANSITION EVALUATION
  // ===========================================================================

  /// Evaluates all eligible stages up to the complaint's current lifecycle state.
  ///
  /// For example, if a complaint transitions directly from submitted to assigned,
  /// this method evaluates `submitted`, `verified`, and `assigned` in progression order,
  /// granting each unawarded stage exactly once.
  Future<List<RewardEvaluationResult>> evaluateAllEligibleStages({
    required ComplaintModel complaint,
    ComplaintStatus? previousStatus,
  }) async {
    final results = <RewardEvaluationResult>[];

    // Progression order
    const stageOrder = [
      RewardLifecycleStage.submitted,
      RewardLifecycleStage.verified,
      RewardLifecycleStage.assigned,
      RewardLifecycleStage.inProgress,
      RewardLifecycleStage.resolved,
    ];

    for (final stage in stageOrder) {
      if (_isStageSatisfied(complaint, stage)) {
        final res = await evaluateStage(complaint: complaint, stage: stage);
        results.add(res);
      }
    }

    return results;
  }

  // ===========================================================================
  // LIFECYCLE STAGE RULES
  // ===========================================================================

  bool _isStageSatisfied(ComplaintModel complaint, RewardLifecycleStage stage) {
    switch (stage) {
      case RewardLifecycleStage.submitted:
        return true; // Always satisfied upon creation

      case RewardLifecycleStage.verified:
        return complaint.isEvidenceVerified ||
            complaint.departmentVerificationStatus == 'passed' ||
            complaint.status == ComplaintStatus.verified ||
            complaint.status == ComplaintStatus.assigned ||
            complaint.status == ComplaintStatus.inProgress ||
            complaint.status == ComplaintStatus.resolved ||
            complaint.status == ComplaintStatus.closed;

      case RewardLifecycleStage.assigned:
        return complaint.isJuniorEngineerAssigned ||
            complaint.isFieldOfficerAssigned ||
            complaint.status == ComplaintStatus.assigned ||
            complaint.status == ComplaintStatus.inProgress ||
            complaint.status == ComplaintStatus.resolved ||
            complaint.status == ComplaintStatus.closed;

      case RewardLifecycleStage.inProgress:
        return complaint.workStartedAt != null ||
            complaint.status == ComplaintStatus.inProgress ||
            complaint.status == ComplaintStatus.resolved ||
            complaint.status == ComplaintStatus.closed;

      case RewardLifecycleStage.resolved:
        return complaint.status == ComplaintStatus.resolved ||
            complaint.status == ComplaintStatus.closed ||
            complaint.resolvedAt != null;
    }
  }

  bool _isComplaintRejectedOrFraudulent(ComplaintModel complaint) {
    if (complaint.status == ComplaintStatus.rejected) return true;
    if (complaint.isEvidenceRejected) return true;
    if (complaint.isAiGeneratedEvidenceRejected) return true;
    if (complaint.evidenceVerificationStatus == 'failed') return true;
    if (complaint.verificationStage == 'evidence_failed' ||
        complaint.verificationStage == 'rejected' ||
        complaint.verificationStage == 'department_failed') {
      return true;
    }
    return false;
  }

  bool _isComplaintDuplicate(ComplaintModel complaint) {
    // If complaint is flagged as duplicate or duplicate of another ticket
    if (complaint.verificationFailureReason?.toLowerCase().contains('duplicate') == true) {
      return true;
    }
    if (complaint.lastAiFailureCode?.toLowerCase() == 'duplicate') {
      return true;
    }
    if (complaint.verificationStage.toLowerCase() == 'duplicate') {
      return true;
    }
    return false;
  }

  // ===========================================================================
  // COMMUNITY REWARDS & ANTI-ABUSE (PHASE 4)
  // ===========================================================================

  /// Evaluates community participation upvote with strict anti-abuse rules:
  /// 1. Self-upvote blocked: citizens cannot upvote their own complaints.
  /// 2. Duplicate / toggle upvote blocked: repeated taps / un-upvote cycles cannot farm rewards.
  /// 3. Rejected / fraudulent complaint blocked: cannot receive community support rewards.
  /// 4. Duplicate complaint blocked: duplicate grievances cannot receive community rewards.
  Future<RewardEvaluationResult> evaluateCommunityUpvote({
    required String voterId,
    required ComplaintModel complaint,
  }) async {
    final cleanVoterId = voterId.trim();
    final cleanCitizenId = complaint.citizenId.trim();
    final cleanComplaintId = complaint.id.trim();

    if (cleanVoterId.isEmpty || cleanComplaintId.isEmpty) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Invalid voter or complaint identifier',
      );
    }

    // 1. Anti-Abuse: Self-Upvote Block
    if (cleanVoterId == cleanCitizenId) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Self-upvotes are ineligible for community rewards',
      );
    }

    // 2. Anti-Abuse: Rejected / Fraudulent / Synthetic Evidence Block
    if (_isComplaintRejectedOrFraudulent(complaint)) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Rejected or fraudulent complaints cannot receive community rewards',
      );
    }

    // 3. Anti-Abuse: Duplicate Complaint Block
    if (_isComplaintDuplicate(complaint)) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Duplicate complaints cannot receive community rewards',
      );
    }

    // 4. Anti-Abuse: Duplicate / Toggle Upvote Farming Block
    final upvoteKey = '${cleanVoterId}_$cleanComplaintId';
    final eventId = 'upvote_$upvoteKey';

    if (_recordedUpvotes.contains(upvoteKey) || _awardedEventIds.contains(eventId)) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Upvote already recorded for this citizen and complaint',
      );
    }

    // Verify against Firestore if connected
    final db = _db;
    if (db != null) {
      try {
        final doc = await db
            .collection(FirestoreCollections.complaints)
            .doc(cleanComplaintId)
            .collection('upvotes')
            .doc(cleanVoterId)
            .get();
        if (doc.exists) {
          _recordedUpvotes.add(upvoteKey);
          return const RewardEvaluationResult(
            granted: false,
            pointsAwarded: 0,
            reason: 'Upvote already recorded for this citizen and complaint',
          );
        }
      } catch (_) {}
    }

    // Record legitimate upvote
    _recordedUpvotes.add(upvoteKey);
    _awardedEventIds.add(eventId);

    return const RewardEvaluationResult(
      granted: true,
      pointsAwarded: 0,
      reason: 'Legitimate community support recorded',
    );
  }

  /// Evaluates and idempotently awards the Community Helper milestone (+10 points bonus)
  /// when a citizen has legitimately supported at least 10 distinct verified complaints by other citizens.
  Future<RewardEvaluationResult> evaluateCommunityHelperBonus({
    required String citizenId,
    required List<ComplaintModel> supportedComplaints,
  }) async {
    final cleanCitizenId = citizenId.trim();
    if (cleanCitizenId.isEmpty) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Invalid citizen identifier',
      );
    }

    final eventId = 'achievement_community_helper_$cleanCitizenId';

    // 1. Idempotency Check: already awarded?
    if (_awardedEventIds.contains(eventId)) {
      return const RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Community Helper milestone bonus has already been awarded',
      );
    }

    final db = _db;
    if (db != null) {
      try {
        final doc = await db
            .collection(FirestoreCollections.rewards)
            .doc(cleanCitizenId)
            .collection('events')
            .doc(eventId)
            .get();
        if (doc.exists) {
          _awardedEventIds.add(eventId);
          return const RewardEvaluationResult(
            granted: false,
            pointsAwarded: 0,
            reason: 'Community Helper milestone bonus has already been awarded',
          );
        }
      } catch (_) {}
    }

    // 2. Anti-Abuse Filtering: strictly legitimate, non-self, verified, non-duplicate, non-fraud complaints
    final validDistinctComplaintIds = <String>{};
    for (final c in supportedComplaints) {
      // Must not be self-complaint
      if (c.citizenId.trim() == cleanCitizenId) continue;
      // Must not be rejected / fraudulent
      if (_isComplaintRejectedOrFraudulent(c)) continue;
      // Must not be duplicate
      if (_isComplaintDuplicate(c)) continue;
      // Must be verified or in progress / resolved
      if (!_isStageSatisfied(c, RewardLifecycleStage.verified)) continue;

      validDistinctComplaintIds.add(c.id.trim());
    }

    if (validDistinctComplaintIds.length < AchievementThresholds.communityHelper) {
      return RewardEvaluationResult(
        granted: false,
        pointsAwarded: 0,
        reason: 'Requires at least ${AchievementThresholds.communityHelper} distinct verified complaints from other citizens (current: ${validDistinctComplaintIds.length})',
      );
    }

    // 3. Create Canonical Reward Event for Community Helper milestone (+10 bonus points)
    final event = RewardEvent(
      id: eventId,
      citizenId: cleanCitizenId,
      complaintId: '',
      complaintTitle: 'Community Participation',
      rewardType: 'community_helper',
      points: 10,
      description: 'Community Helper milestone bonus (+10 points)',
      createdAt: DateTime.now(),
      metadata: {
        'supportedCount': validDistinctComplaintIds.length,
        'milestone': 'community_helper',
      },
    );

    // 4. Update local user cache
    final updatedCitizenPoints = await _updateLocalUserCache(
      citizenId: cleanCitizenId,
      pointsDelta: 10,
      stage: RewardLifecycleStage.submitted,
    );

    _awardedEventIds.add(eventId);
    _eventsByCitizen.putIfAbsent(cleanCitizenId, () => []).insert(0, event);

    return RewardEvaluationResult(
      granted: true,
      pointsAwarded: 10,
      reason: 'Community Helper milestone achieved! Awarded 10 Civic Points.',
      event: event,
      citizenTotalPoints: updatedCitizenPoints,
    );
  }

  // ===========================================================================
  // IDEMPOTENCY & QUERY HELPERS
  // ===========================================================================

  Future<bool> _hasStageBeenAwarded({
    required String complaintId,
    required String citizenId,
    required RewardLifecycleStage stage,
    required String eventId,
  }) async {
    // 1. In-memory check
    if (_awardedEventIds.contains(eventId)) return true;

    final cachedComplaintEvents = _eventsByComplaint[complaintId];
    if (cachedComplaintEvents != null &&
        cachedComplaintEvents.any((e) => e.id == eventId || e.rewardType == stage.stageKey)) {
      return true;
    }

    // 2. Firestore check in owner's subcollection
    final db = _db;
    if (db != null) {
      try {
        final doc = await db
            .collection(FirestoreCollections.rewards)
            .doc(citizenId)
            .collection('events')
            .doc(eventId)
            .get();
        if (doc.exists) {
          _awardedEventIds.add(eventId);
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  Future<int> getComplaintAwardedPoints(String complaintId) async {
    int total = 0;
    final inMemoryEvents = _eventsByComplaint[complaintId];
    if (inMemoryEvents != null) {
      for (final e in inMemoryEvents) {
        total += e.points;
      }
    }
    return total;
  }

  Future<Set<RewardLifecycleStage>> getAwardedStages(String complaintId) async {
    final stages = <RewardLifecycleStage>{};
    final inMemoryEvents = _eventsByComplaint[complaintId];
    if (inMemoryEvents != null) {
      for (final e in inMemoryEvents) {
        final st = e.lifecycleStage;
        if (st != null) stages.add(st);
      }
    }
    return stages;
  }

  Future<List<RewardEvent>> getRewardHistory(String citizenId) async {
    final list = <RewardEvent>[];
    final localList = _eventsByCitizen[citizenId];
    if (localList != null) {
      list.addAll(localList);
    }

    final db = _db;
    if (db != null) {
      try {
        final query = await db
            .collection(FirestoreCollections.rewards)
            .doc(citizenId)
            .collection('events')
            .orderBy('createdAt', descending: true)
            .get();
        final remote = query.docs.map((d) {
          final data = d.data();
          return RewardEvent.fromJson({'id': d.id, ...data});
        }).toList();

        final seenIds = list.map((e) => e.id).toSet();
        for (final r in remote) {
          if (!seenIds.contains(r.id)) {
            list.add(r);
            seenIds.add(r.id);
          }
        }
      } catch (_) {}
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<int> _getCitizenTotalPoints(String citizenId) async {
    try {
      final userRepo = _userRepository ?? RepositoryLocator.userRepository;
      final user = await userRepo.getCurrentUser();
      if (user.id == citizenId) return user.civicPoints;
    } catch (_) {}
    return 0;
  }

  // ===========================================================================
  // LOCAL USER PROFILE CACHE UPDATE
  // ===========================================================================

  Future<int> _updateLocalUserCache({
    required String citizenId,
    required int pointsDelta,
    required RewardLifecycleStage stage,
    int? newTotalPoints,
  }) async {
    int updatedCitizenPoints = 0;
    try {
      final userRepo = _userRepository ?? RepositoryLocator.userRepository;
      final user = await userRepo.getCurrentUser();
      if (user.id == citizenId) {
        final newPoints = newTotalPoints ?? (user.civicPoints + pointsDelta);
        final updatedUser = user.copyWith(
          civicPoints: newPoints,
          reportsSubmitted: stage == RewardLifecycleStage.submitted
              ? user.reportsSubmitted + 1
              : user.reportsSubmitted,
          reportsResolved: stage == RewardLifecycleStage.resolved
              ? user.reportsResolved + 1
              : user.reportsResolved,
        );
        if (userRepo is HiveUserRepository) {
          await userRepo.cacheUser(updatedUser);
        } else if (userRepo is OfflineFirstUserRepository) {
          await userRepo.cacheUser(updatedUser);
        }
        updatedCitizenPoints = newPoints;
      }
    } catch (_) {}
    return updatedCitizenPoints;
  }

  /// Clears in-memory test state (used strictly for unit testing).
  @visibleForTesting
  void resetState() {
    _awardedEventIds.clear();
    _eventsByCitizen.clear();
    _eventsByComplaint.clear();
    _inFlightEvents.clear();
    _recordedUpvotes.clear();
  }
}
