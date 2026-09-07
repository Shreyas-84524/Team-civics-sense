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

  const CivicAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.howToUnlock,
    required this.icon,
    required this.isUnlocked,
    this.pointsRequired = 0,
    this.unlockedAt,
  });

  CivicAchievement copyWith({
    String? id,
    String? title,
    String? description,
    String? howToUnlock,
    IconData? icon,
    bool? isUnlocked,
    int? pointsRequired,
    DateTime? unlockedAt,
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
    );
  }

  /// Canonical 4 MVP Achievements
  static List<CivicAchievement> defaultAchievements() => [
        CivicAchievement(
          id: 'ach_1',
          title: 'First Report',
          description: 'Submitted your first civic issue.',
          howToUnlock: 'Report any verified road, water, waste, or light issue to unlock.',
          icon: Icons.flag_rounded,
          isUnlocked: true,
          pointsRequired: 20,
        ),
        CivicAchievement(
          id: 'ach_2',
          title: 'Civic Contributor',
          description: 'Reported civic issues that help authorities identify problems in your area.',
          howToUnlock: 'Submit 5 verified civic complaints across your municipality.',
          icon: Icons.volunteer_activism_rounded,
          isUnlocked: true,
          pointsRequired: 150,
        ),
        CivicAchievement(
          id: 'ach_3',
          title: 'Community Helper',
          description: 'Confirmed and verified community resolutions in your neighborhood.',
          howToUnlock: 'Help verify or upvote nearby civic issues reported by fellow citizens.',
          icon: Icons.groups_rounded,
          isUnlocked: true,
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

  const RewardDataModel({
    required this.userId,
    required this.currentPoints,
    this.nextMilestoneTarget = 1000,
    required this.reportsSubmitted,
    required this.reportsResolved,
    required this.achievements,
    this.perks = const [],
  });

  int get pointsToNextMilestone => (nextMilestoneTarget - currentPoints).clamp(0, nextMilestoneTarget);
  double get progressRatio => (currentPoints / nextMilestoneTarget).clamp(0.0, 1.0);
}
