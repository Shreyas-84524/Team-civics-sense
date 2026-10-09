import '../models/complaint_model.dart';
import '../models/reward_model.dart';
import '../models/user_model.dart';

/// Centralized configuration for canonical CivicFix achievement thresholds.
///
/// Configurable Target Thresholds:
/// - Evidence Expert:     5 verified complaints with photo evidence
/// - Ground Reporter:     5 verified complaints with GPS coordinates
/// - Community Voice:     10 community upvotes received on complaints
/// - Community Helper:    10 other community complaints supported
/// - Resolution Champion: 5 complaints reaching resolution
class AchievementThresholds {
  const AchievementThresholds._();

  static const int evidenceExpert = 5;
  static const int groundReporter = 5;
  static const int communityVoice = 10;
  static const int communityHelper = 10;
  static const int resolutionChampion = 5;
}

/// Centralized Achievement Evaluator for CivicFix.
///
/// Evaluates and derives achievement unlock states and live progress directly
/// from existing complaint, user, and upvote models without duplicating state.
///
/// Guarantees:
/// 1. **Idempotent Unlocks**: Once an achievement is unlocked, its `unlockedAt` timestamp is immutable.
/// 2. **Derived Progress**: Accurately counts from real complaint properties.
/// 3. **Canonical 5 Achievements**: Implements the canonical 5 badges defined in the source of truth.
class AchievementEvaluator {
  const AchievementEvaluator._();

  /// Evaluates all 5 canonical achievements given citizen profile, complaints, and prior unlock state.
  static List<CivicAchievement> evaluateAchievements({
    required UserModel user,
    List<ComplaintModel> complaints = const [],
    List<CivicAchievement>? existingAchievements,
    int? supportedComplaintsCount,
    List<ComplaintModel>? supportedComplaints,
  }) {
    final existingMap = <String, CivicAchievement>{
      for (final a in (existingAchievements ?? [])) a.id: a,
    };

    // Helper: Anti-abuse filter for legitimate complaints
    bool isLegitimate(ComplaintModel c) {
      if (c.status == ComplaintStatus.rejected) return false;
      if (c.isEvidenceRejected) return false;
      if (c.isAiGeneratedEvidenceRejected) return false;
      if (c.evidenceVerificationStatus == 'failed') return false;
      if (c.verificationFailureReason?.toLowerCase().contains('duplicate') == true) return false;
      if (c.lastAiFailureCode?.toLowerCase() == 'duplicate') return false;
      return true;
    }

    // 1. Evidence Expert: Verified complaints with photo evidence (legitimate only)
    final verifiedWithPhotos = complaints.isNotEmpty
        ? complaints.where((c) {
            if (!isLegitimate(c)) return false;
            final isVerified = c.isEvidenceVerified ||
                c.departmentVerificationStatus == 'passed' ||
                c.status == ComplaintStatus.verified ||
                c.status == ComplaintStatus.assigned ||
                c.status == ComplaintStatus.inProgress ||
                c.status == ComplaintStatus.resolved ||
                c.status == ComplaintStatus.closed;
            return isVerified && c.imageUrls.isNotEmpty;
          }).length
        : (existingMap['evidence_expert']?.currentProgress ?? 0);

    // 2. Ground Reporter: Verified complaints with coordinates (legitimate only)
    final verifiedWithCoords = complaints.isNotEmpty
        ? complaints.where((c) {
            if (!isLegitimate(c)) return false;
            final isVerified = c.isEvidenceVerified ||
                c.departmentVerificationStatus == 'passed' ||
                c.status == ComplaintStatus.verified ||
                c.status == ComplaintStatus.assigned ||
                c.status == ComplaintStatus.inProgress ||
                c.status == ComplaintStatus.resolved ||
                c.status == ComplaintStatus.closed;
            final hasCoords = c.location.latitude != 0.0 || c.location.longitude != 0.0;
            return isVerified && hasCoords;
          }).length
        : (existingMap['ground_reporter']?.currentProgress ?? 0);

    // 3. Community Voice: Upvotes received across user's legitimate complaints
    final totalUpvotes = complaints.isNotEmpty
        ? complaints
            .where((c) => isLegitimate(c))
            .fold<int>(0, (sum, c) => sum + (c.upvotes > 0 ? c.upvotes : 0))
        : (existingMap['community_voice']?.currentProgress ?? 0);

    // 4. Community Helper: Supported complaints by other citizens
    int effectiveSupportedCount = 0;
    if (supportedComplaints != null) {
      final distinctSupportedIds = <String>{};
      for (final c in supportedComplaints) {
        if (c.citizenId.trim() == user.id.trim()) continue;
        if (!isLegitimate(c)) continue;
        final isVerified = c.isEvidenceVerified ||
            c.departmentVerificationStatus == 'passed' ||
            c.status == ComplaintStatus.verified ||
            c.status == ComplaintStatus.assigned ||
            c.status == ComplaintStatus.inProgress ||
            c.status == ComplaintStatus.resolved ||
            c.status == ComplaintStatus.closed;
        if (!isVerified) continue;

        distinctSupportedIds.add(c.id.trim());
      }
      effectiveSupportedCount = distinctSupportedIds.length;
    } else if (supportedComplaintsCount != null) {
      effectiveSupportedCount = supportedComplaintsCount;
    } else if (existingMap['community_helper'] != null) {
      effectiveSupportedCount = existingMap['community_helper']!.currentProgress;
    } else {
      effectiveSupportedCount = user.badges.contains('community_helper')
          ? AchievementThresholds.communityHelper
          : 0;
    }

    // 5. Resolution Champion: Resolved legitimate complaints
    final resolvedCount = complaints.isNotEmpty
        ? complaints.where((c) => isLegitimate(c) && (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.closed)).length
        : (existingMap['resolution_champion']?.currentProgress ?? user.reportsResolved);

    return [
      _buildEvaluatedAchievement(
        base: CivicAchievement.defaultAchievements()[0], // evidence_expert
        target: AchievementThresholds.evidenceExpert,
        current: verifiedWithPhotos,
        existing: existingMap['evidence_expert'],
      ),
      _buildEvaluatedAchievement(
        base: CivicAchievement.defaultAchievements()[1], // ground_reporter
        target: AchievementThresholds.groundReporter,
        current: verifiedWithCoords,
        existing: existingMap['ground_reporter'],
      ),
      _buildEvaluatedAchievement(
        base: CivicAchievement.defaultAchievements()[2], // community_voice
        target: AchievementThresholds.communityVoice,
        current: totalUpvotes,
        existing: existingMap['community_voice'],
      ),
      _buildEvaluatedAchievement(
        base: CivicAchievement.defaultAchievements()[3], // community_helper
        target: AchievementThresholds.communityHelper,
        current: effectiveSupportedCount,
        existing: existingMap['community_helper'],
      ),
      _buildEvaluatedAchievement(
        base: CivicAchievement.defaultAchievements()[4], // resolution_champion
        target: AchievementThresholds.resolutionChampion,
        current: resolvedCount,
        existing: existingMap['resolution_champion'],
      ),
    ];
  }

  static CivicAchievement _buildEvaluatedAchievement({
    required CivicAchievement base,
    required int target,
    required int current,
    CivicAchievement? existing,
  }) {
    final wasAlreadyUnlocked = existing?.isUnlocked ?? false;
    final isNowUnlocked = wasAlreadyUnlocked || current >= target;

    DateTime? unlockTimestamp;
    if (wasAlreadyUnlocked) {
      unlockTimestamp = existing?.unlockedAt ?? DateTime.now();
    } else if (isNowUnlocked) {
      unlockTimestamp = DateTime.now();
    }

    return base.copyWith(
      isUnlocked: isNowUnlocked,
      unlockedAt: unlockTimestamp,
      currentProgress: current > target ? target : (current < 0 ? 0 : current),
      targetProgress: target,
    );
  }
}
