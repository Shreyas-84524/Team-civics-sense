import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/reward_model.dart';
import 'firestore_mapper_helpers.dart';

/// Bidirectional mapper for Rewards, Achievements, and Perks to/from Cloud Firestore documents.
class RewardFirestoreMapper {
  RewardFirestoreMapper._();

  /// Converts a [RewardDataModel] into a Firestore map.
  static Map<String, dynamic> toFirestore(RewardDataModel data) {
    return {
      'userId': data.userId,
      'points': data.currentPoints,
      'nextMilestoneTarget': data.nextMilestoneTarget,
      'reportsSubmitted': data.reportsSubmitted,
      'reportsResolved': data.reportsResolved,
      'achievements': data.achievements.map(achievementToMap).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts a Firestore document map into a [RewardDataModel].
  static RewardDataModel fromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
    List<CivicRewardItem> perks = const [],
  }) {
    final rawAchievements = data['achievements'] as List<dynamic>? ?? [];
    final List<CivicAchievement> parsedAchievements = [];

    if (rawAchievements.isNotEmpty) {
      for (final raw in rawAchievements) {
        if (raw is Map<String, dynamic>) {
          parsedAchievements.add(achievementFromMap(raw));
        } else if (raw is Map) {
          parsedAchievements.add(achievementFromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return RewardDataModel(
      userId: documentId,
      currentPoints: (data['points'] ?? data['currentPoints']) as int? ?? 0,
      nextMilestoneTarget: data['nextMilestoneTarget'] as int? ?? 1000,
      reportsSubmitted: data['reportsSubmitted'] as int? ?? 0,
      reportsResolved: data['reportsResolved'] as int? ?? 0,
      achievements: parsedAchievements.isNotEmpty
          ? parsedAchievements
          : CivicAchievement.defaultAchievements(),
      perks: perks,
    );
  }

  /// Converts a [CivicAchievement] into a map.
  static Map<String, dynamic> achievementToMap(CivicAchievement achievement) {
    return {
      'id': achievement.id,
      'title': achievement.title,
      'description': achievement.description,
      'howToUnlock': achievement.howToUnlock,
      'isUnlocked': achievement.isUnlocked,
      'pointsRequired': achievement.pointsRequired,
      'unlockedAt': FirestoreMapperHelpers.dateTimeToTimestamp(achievement.unlockedAt),
    };
  }

  /// Converts a map into a [CivicAchievement].
  static CivicAchievement achievementFromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? 'ach_1';
    final defaultAch = CivicAchievement.defaultAchievements().firstWhere(
      (a) => a.id == id,
      orElse: () => CivicAchievement(
        id: id,
        title: map['title'] as String? ?? 'Civic Achievement',
        description: map['description'] as String? ?? '',
        howToUnlock: map['howToUnlock'] as String? ?? '',
        icon: Icons.military_tech_rounded,
        isUnlocked: map['isUnlocked'] as bool? ?? false,
      ),
    );

    return defaultAch.copyWith(
      title: map['title'] as String?,
      description: map['description'] as String?,
      howToUnlock: map['howToUnlock'] as String?,
      isUnlocked: map['isUnlocked'] as bool?,
      pointsRequired: map['pointsRequired'] as int?,
      unlockedAt: FirestoreMapperHelpers.timestampToDateTime(map['unlockedAt']),
    );
  }

  /// Converts a [CivicRewardItem] into a map.
  static Map<String, dynamic> perkToMap(CivicRewardItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'partner': item.partner,
      'description': item.description,
      'pointsCost': item.pointsCost,
      'expiryDate': item.expiryDate,
    };
  }

  /// Converts a map into a [CivicRewardItem].
  static CivicRewardItem perkFromMap(Map<String, dynamic> map) {
    return CivicRewardItem(
      id: map['id'] as String? ?? 'rw_1',
      title: map['title'] as String? ?? '',
      partner: map['partner'] as String? ?? '',
      description: map['description'] as String? ?? '',
      pointsCost: map['pointsCost'] as int? ?? 100,
      expiryDate: map['expiryDate'] as String? ?? '31 Dec 2026',
      icon: Icons.local_offer_rounded,
    );
  }
}
