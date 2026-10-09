import 'package:flutter/material.dart';

/// MVP Civic Achievement model for gamified community participation.
class CivicAchievement {
  final String id;
  final String title;
  final String description;
  final String howToUnlock;
  final IconData icon;
  final bool isUnlocked;
  final int pointsRequired;
  final DateTime? unlockedAt;
  final int currentProgress;
  final int targetProgress;

  const CivicAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.howToUnlock,
    required this.icon,
    required this.isUnlocked,
    this.pointsRequired = 0,
    this.unlockedAt,
    this.currentProgress = 0,
    this.targetProgress = 0,
  });

  String get requirement => howToUnlock;
  double get progressRatio =>
      targetProgress > 0 ? (currentProgress / targetProgress).clamp(0.0, 1.0) : (isUnlocked ? 1.0 : 0.0);

  CivicAchievement copyWith({
    String? id,
    String? title,
    String? description,
    String? howToUnlock,
    IconData? icon,
    bool? isUnlocked,
    int? pointsRequired,
    DateTime? unlockedAt,
    int? currentProgress,
    int? targetProgress,
  }) {
    return CivicAchievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      howToUnlock: howToUnlock ?? this.howToUnlock,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
    );
  }

  /// Canonical 5 MVP Achievements
  static List<CivicAchievement> defaultAchievements() => [
        const CivicAchievement(id: 'evidence_expert', title: 'Evidence Expert', description: 'Useful evidence helps officers act.', howToUnlock: 'Provide useful images on 5 verified complaints.', icon: Icons.photo_camera_outlined, isUnlocked: false, targetProgress: 5),
        const CivicAchievement(id: 'ground_reporter', title: 'Ground Reporter', description: 'Help officers find the right location.', howToUnlock: 'Provide coordinates matching the assigned ward on 5 verified complaints.', icon: Icons.location_on_outlined, isUnlocked: false, targetProgress: 5),
        const CivicAchievement(id: 'community_voice', title: 'Community Voice', description: 'Make shared civic concerns visible.', howToUnlock: 'Receive support from 10 different citizens on verified complaints.', icon: Icons.thumb_up_outlined, isUnlocked: false, targetProgress: 10),
        const CivicAchievement(id: 'community_helper', title: 'Community Helper', description: 'Support responsible community reports.', howToUnlock: 'Support 10 different verified complaints by others. Earn a one-time 10-point bonus.', icon: Icons.people_outline, isUnlocked: false, targetProgress: 10),
        const CivicAchievement(id: 'resolution_champion', title: 'Resolution Champion', description: 'Follow reports through to resolution.', howToUnlock: 'Have 5 eligible complaints reach resolution.', icon: Icons.emoji_events_outlined, isUnlocked: false, targetProgress: 5),
      ];

  /// Kept only for compatibility with old persisted achievement identifiers.
  static List<CivicAchievement> legacyAchievements() => [
        CivicAchievement(
          id: 'ach_1',
          title: 'First Report',
          description: 'Submitted your first civic issue.',
          howToUnlock: 'Report any verified road, water, waste, or light issue to unlock.',
          icon: Icons.flag_rounded,
          isUnlocked: false,
          pointsRequired: 20,
        ),
        CivicAchievement(
          id: 'ach_2',
          title: 'Civic Contributor',
          description: 'Reported civic issues that help authorities identify problems in your area.',
          howToUnlock: 'Submit 5 verified civic complaints across your municipality.',
          icon: Icons.volunteer_activism_rounded,
          isUnlocked: false,
          pointsRequired: 150,
        ),
        CivicAchievement(
          id: 'ach_3',
          title: 'Community Helper',
          description: 'Confirmed and verified community resolutions in your neighborhood.',
          howToUnlock: 'Help verify or upvote nearby civic issues reported by fellow citizens.',
          icon: Icons.groups_rounded,
          isUnlocked: false,
          pointsRequired: 350,
        ),
        CivicAchievement(
          id: 'ach_4',
          title: 'Active Citizen',
          description: 'Participated consistently in improving your community.',
          howToUnlock: 'Achieve 1,000 Civic Points and participate in 15 resolved community actions.',
          icon: Icons.military_tech_rounded,
          isUnlocked: false,
          pointsRequired: 1000,
        ),
      ];
}

/// Backward-compatible alias for CivicAchievement.
typedef CivicBadge = CivicAchievement;

/// Model for redeemable community perks and discounts.
class CivicRewardItem {
  final String id;
  final String title;
  final String partner;
  final String description;
  final int pointsCost;
  final String expiryDate;
  final IconData icon;

  const CivicRewardItem({
    required this.id,
    required this.title,
    required this.partner,
    required this.description,
    required this.pointsCost,
    required this.expiryDate,
    required this.icon,
  });
}

/// Centralized data model for rewards summary.
class RewardDataModel {
  final String userId;
  final int currentPoints;
  final int nextMilestoneTarget;
  final int reportsSubmitted;
  final int reportsResolved;
  final List<CivicAchievement> achievements;
  final List<CivicRewardItem> perks;
  final int reportsVerified;
  final int communityUpvotes;
  final int supportedComplaints;
  final List<RewardEvent> recentActivity;
  final bool isCached;
  final bool syncPending;

  const RewardDataModel({
    required this.userId,
    required this.currentPoints,
    this.nextMilestoneTarget = 1000,
    required this.reportsSubmitted,
    required this.reportsResolved,
    required this.achievements,
    this.perks = const [],
    this.reportsVerified = 0,
    this.communityUpvotes = 0,
    this.supportedComplaints = 0,
    this.recentActivity = const [],
    this.isCached = false,
    this.syncPending = false,
  });

  RewardDataModel copyWith({
    String? userId,
    int? currentPoints,
    int? nextMilestoneTarget,
    int? reportsSubmitted,
    int? reportsResolved,
    List<CivicAchievement>? achievements,
    List<CivicRewardItem>? perks,
    int? reportsVerified,
    int? communityUpvotes,
    int? supportedComplaints,
    List<RewardEvent>? recentActivity,
    bool? isCached,
    bool? syncPending,
  }) {
    return RewardDataModel(
      userId: userId ?? this.userId,
      currentPoints: currentPoints ?? this.currentPoints,
      nextMilestoneTarget: nextMilestoneTarget ?? this.nextMilestoneTarget,
      reportsSubmitted: reportsSubmitted ?? this.reportsSubmitted,
      reportsResolved: reportsResolved ?? this.reportsResolved,
      achievements: achievements ?? this.achievements,
      perks: perks ?? this.perks,
      reportsVerified: reportsVerified ?? this.reportsVerified,
      communityUpvotes: communityUpvotes ?? this.communityUpvotes,
      supportedComplaints: supportedComplaints ?? this.supportedComplaints,
      recentActivity: recentActivity ?? this.recentActivity,
      isCached: isCached ?? this.isCached,
      syncPending: syncPending ?? this.syncPending,
    );
  }

  int get pointsToNextMilestone => (nextMilestoneTarget - currentPoints).clamp(0, nextMilestoneTarget);
  double get progressRatio => (currentPoints / nextMilestoneTarget).clamp(0.0, 1.0);
  CivicLevel get level => CivicLevel.forPoints(currentPoints);
  CivicLevelInfo get levelInfo => CivicLevelInfo.calculate(currentPoints);
  CivicImpactSummary get impactSummary => CivicImpactSummary(
        complaintsSubmitted: reportsSubmitted,
        complaintsVerified: reportsVerified,
        complaintsResolved: reportsResolved,
        communityUpvotes: communityUpvotes,
        achievementsUnlocked: achievements.where((a) => a.isUnlocked).length,
      );
}

/// Canonical Civic Level definition.
///
/// Thresholds:
/// - Level 1: 0–99 pts   -> Civic Starter
/// - Level 2: 100–249 pts -> Civic Contributor
/// - Level 3: 250–499 pts -> Civic Champion
/// - Level 4: 500–999 pts -> Civic Leader
/// - Level 5: 1000+ pts   -> Civic Hero
class CivicLevel {
  final int number;
  final String title;
  final String symbol;
  final int minimum;
  final int? nextThreshold;

  const CivicLevel(this.number, this.title, this.symbol, this.minimum, this.nextThreshold);

  static const levels = [
    CivicLevel(1, 'Civic Starter', '🌱', 0, 100),
    CivicLevel(2, 'Civic Contributor', '🌿', 100, 250),
    CivicLevel(3, 'Civic Champion', '🌳', 250, 500),
    CivicLevel(4, 'Civic Leader', '🏆', 500, 1000),
    CivicLevel(5, 'Civic Hero', '⭐', 1000, null),
  ];

  static CivicLevel forPoints(int points) {
    final effective = points < 0 ? 0 : points;
    return levels.firstWhere(
      (l) => l.nextThreshold == null || effective < l.nextThreshold!,
      orElse: () => levels.last,
    );
  }

  static CivicLevel fromLevel(int levelNumber) {
    if (levelNumber < 1) return levels.first;
    if (levelNumber > levels.length) return levels.last;
    return levels[levelNumber - 1];
  }

  CivicLevel? get nextLevel => number < levels.length ? levels[number] : null;
  String? get nextTitle => nextLevel?.title;

  double progress(int points) {
    if (nextThreshold == null) return 1.0;
    final effective = points < minimum ? minimum : points;
    if (effective >= nextThreshold!) return 1.0;
    final span = nextThreshold! - minimum;
    if (span <= 0) return 1.0;
    return ((effective - minimum) / span).clamp(0.0, 1.0);
  }

  int pointsRemaining(int points) {
    if (nextThreshold == null) return 0;
    final effective = points < 0 ? 0 : points;
    if (effective >= nextThreshold!) return 0;
    return (nextThreshold! - effective).clamp(0, nextThreshold!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CivicLevel && runtimeType == other.runtimeType && number == other.number;

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() => 'CivicLevel(L$number: $title, min: $minimum, next: $nextThreshold)';
}

/// Calculated snapshot of a citizen's level progression, points remaining, and progress.
class CivicLevelInfo {
  final CivicLevel currentLevel;
  final int totalPoints;
  final CivicLevel? nextLevel;
  final int pointsRemaining;
  final double progress;

  const CivicLevelInfo({
    required this.currentLevel,
    required this.totalPoints,
    this.nextLevel,
    required this.pointsRemaining,
    required this.progress,
  });

  int get level => currentLevel.number;
  String get title => currentLevel.title;
  String get symbol => currentLevel.symbol;
  int? get nextLevelNumber => nextLevel?.number;
  String? get nextLevelTitle => nextLevel?.title;
  int? get nextLevelMinPoints => nextLevel?.minimum;
  bool get isMaxLevel => nextLevel == null;

  factory CivicLevelInfo.calculate(int points) {
    final effectivePoints = points < 0 ? 0 : points;
    final current = CivicLevel.forPoints(effectivePoints);
    final next = current.nextLevel;
    final remaining = current.pointsRemaining(effectivePoints);
    final prog = current.progress(effectivePoints);

    return CivicLevelInfo(
      currentLevel: current,
      totalPoints: effectivePoints,
      nextLevel: next,
      pointsRemaining: remaining,
      progress: prog,
    );
  }

  @override
  String toString() =>
      'CivicLevelInfo(level: $level ($title), points: $totalPoints, remaining: $pointsRemaining, progress: ${(progress * 100).toStringAsFixed(1)}%)';
}

/// Aggregated civic impact metrics derived cleanly from existing data.
class CivicImpactSummary {
  final int complaintsSubmitted;
  final int complaintsVerified;
  final int complaintsResolved;
  final int communityUpvotes;
  final int achievementsUnlocked;

  const CivicImpactSummary({
    required this.complaintsSubmitted,
    required this.complaintsVerified,
    required this.complaintsResolved,
    required this.communityUpvotes,
    required this.achievementsUnlocked,
  });

  @override
  String toString() =>
      'CivicImpactSummary(submitted: $complaintsSubmitted, verified: $complaintsVerified, resolved: $complaintsResolved, upvotes: $communityUpvotes, achievements: $achievementsUnlocked)';
}

/// Canonical complaint lifecycle stages eligible for gamification points.
///
/// Point Schedule:
/// - [submitted]   -> +10 points
/// - [verified]    -> +20 points
/// - [assigned]    -> +15 points
/// - [inProgress]  -> +20 points
/// - [resolved]    -> +35 points
/// Total maximum per grievance = 100 Civic Points.
enum RewardLifecycleStage {
  submitted,
  verified,
  assigned,
  inProgress,
  resolved;

  int get points {
    switch (this) {
      case RewardLifecycleStage.submitted:
        return 10;
      case RewardLifecycleStage.verified:
        return 20;
      case RewardLifecycleStage.assigned:
        return 15;
      case RewardLifecycleStage.inProgress:
        return 20;
      case RewardLifecycleStage.resolved:
        return 35;
    }
  }

  String get stageKey {
    switch (this) {
      case RewardLifecycleStage.submitted:
        return 'submitted';
      case RewardLifecycleStage.verified:
        return 'verified';
      case RewardLifecycleStage.assigned:
        return 'assigned';
      case RewardLifecycleStage.inProgress:
        return 'in_progress';
      case RewardLifecycleStage.resolved:
        return 'resolved';
    }
  }

  String get defaultDescription {
    switch (this) {
      case RewardLifecycleStage.submitted:
        return 'Grievance submitted successfully (+10 points)';
      case RewardLifecycleStage.verified:
        return 'Evidence & Department authenticity verified (+20 points)';
      case RewardLifecycleStage.assigned:
        return 'Grievance assigned to Junior Engineer / Officer (+15 points)';
      case RewardLifecycleStage.inProgress:
        return 'Field crew commenced on-ground resolution (+20 points)';
      case RewardLifecycleStage.resolved:
        return 'Civic issue verified and successfully resolved (+35 points)';
    }
  }

  static const int maxPointsPerComplaint = 100;

  static RewardLifecycleStage? fromString(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final normalized = val.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'submitted':
      case 'reported':
        return RewardLifecycleStage.submitted;
      case 'verified':
      case 'underreview':
      case 'under_review':
        return RewardLifecycleStage.verified;
      case 'assigned':
      case 'officerassigned':
      case 'officer_assigned':
        return RewardLifecycleStage.assigned;
      case 'inprogress':
      case 'in_progress':
      case 'workinprogress':
      case 'work_in_progress':
        return RewardLifecycleStage.inProgress;
      case 'resolved':
      case 'closed':
        return RewardLifecycleStage.resolved;
      default:
        return null;
    }
  }
}

/// Canonical Reward Event model representing an immutable, idempotent point award.
class RewardEvent {
  final String id;
  final String citizenId;
  final String complaintId;
  final String complaintTitle;
  final String rewardType;
  final int points;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  RewardEvent({
    required this.id,
    this.citizenId = '',
    this.complaintId = '',
    this.complaintTitle = 'Civic complaint',
    required this.rewardType,
    required this.description,
    required this.points,
    DateTime? createdAt,
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  RewardLifecycleStage? get lifecycleStage => RewardLifecycleStage.fromString(rewardType);

  RewardEvent copyWith({
    String? id,
    String? citizenId,
    String? complaintId,
    String? complaintTitle,
    String? rewardType,
    int? points,
    String? description,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return RewardEvent(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      complaintId: complaintId ?? this.complaintId,
      complaintTitle: complaintTitle ?? this.complaintTitle,
      rewardType: rewardType ?? this.rewardType,
      points: points ?? this.points,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'citizenId': citizenId,
        'complaintId': complaintId,
        'complaintTitle': complaintTitle,
        'rewardType': rewardType,
        'points': points,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory RewardEvent.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['createdAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    return RewardEvent(
      id: json['id'] as String? ?? '',
      citizenId: json['citizenId'] as String? ?? '',
      complaintId: json['complaintId'] as String? ?? '',
      complaintTitle: json['complaintTitle'] as String? ?? 'Civic complaint',
      rewardType: json['rewardType'] as String? ?? '',
      description: json['description'] as String? ?? 'Civic contribution',
      points: (json['points'] as num?)?.toInt() ?? 0,
      createdAt: parsedDate,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }
}

