// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import '../../models/reward_model.dart';

/// Local persistence model for gamification achievements stored in Hive.
class AchievementLocalModel {
  final String id;
  final String title;
  final String description;
  final String howToUnlock;
  final int iconCodePoint;
  final String? iconFontFamily;
  final bool isUnlocked;
  final int pointsRequired;
  final int? unlockedAtEpochMs;

  const AchievementLocalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.howToUnlock,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.isUnlocked,
    this.pointsRequired = 0,
    this.unlockedAtEpochMs,
  });

  /// Map from Domain Model [CivicAchievement] -> [AchievementLocalModel]
  factory AchievementLocalModel.fromDomain(CivicAchievement achievement) {
    return AchievementLocalModel(
      id: achievement.id,
      title: achievement.title,
      description: achievement.description,
      howToUnlock: achievement.howToUnlock,
      iconCodePoint: achievement.icon.codePoint,
      iconFontFamily: achievement.icon.fontFamily,
      isUnlocked: achievement.isUnlocked,
      pointsRequired: achievement.pointsRequired,
      unlockedAtEpochMs: achievement.unlockedAt?.millisecondsSinceEpoch,
    );
  }

  /// Map from [AchievementLocalModel] -> Domain Model [CivicAchievement]
  CivicAchievement toDomain() {
    return CivicAchievement(
      id: id,
      title: title,
      description: description,
      howToUnlock: howToUnlock,
      icon: _getIconFromCodePoint(iconCodePoint),
      isUnlocked: isUnlocked,
      pointsRequired: pointsRequired,
      unlockedAt: unlockedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(unlockedAtEpochMs!)
          : null,
    );
  }
}

/// Local persistence model for redeemable perks stored in Hive.
class RewardItemLocalModel {
  final String id;
  final String title;
  final String partner;
  final String description;
  final int pointsCost;
  final String expiryDate;
  final int iconCodePoint;
  final String? iconFontFamily;

  const RewardItemLocalModel({
    required this.id,
    required this.title,
    required this.partner,
    required this.description,
    required this.pointsCost,
    required this.expiryDate,
    required this.iconCodePoint,
    this.iconFontFamily,
  });

  /// Map from Domain Model [CivicRewardItem] -> [RewardItemLocalModel]
  factory RewardItemLocalModel.fromDomain(CivicRewardItem reward) {
    return RewardItemLocalModel(
      id: reward.id,
      title: reward.title,
      partner: reward.partner,
      description: reward.description,
      pointsCost: reward.pointsCost,
      expiryDate: reward.expiryDate,
      iconCodePoint: reward.icon.codePoint,
      iconFontFamily: reward.icon.fontFamily,
    );
  }

  /// Map from [RewardItemLocalModel] -> Domain Model [CivicRewardItem]
  CivicRewardItem toDomain() {
    return CivicRewardItem(
      id: id,
      title: title,
      partner: partner,
      description: description,
      pointsCost: pointsCost,
      expiryDate: expiryDate,
      icon: _getIconFromCodePoint(iconCodePoint),
    );
  }
}

/// Helper to map code points back to constant [IconData] to avoid tree-shaking errors in release builds.
IconData _getIconFromCodePoint(int codePoint) {
  if (codePoint == Icons.photo_camera_outlined.codePoint) return Icons.photo_camera_outlined;
  if (codePoint == Icons.location_on_outlined.codePoint) return Icons.location_on_outlined;
  if (codePoint == Icons.thumb_up_outlined.codePoint) return Icons.thumb_up_outlined;
  if (codePoint == Icons.people_outline.codePoint) return Icons.people_outline;
  if (codePoint == Icons.emoji_events_outlined.codePoint) return Icons.emoji_events_outlined;
  
  if (codePoint == Icons.flag_rounded.codePoint) return Icons.flag_rounded;
  if (codePoint == Icons.volunteer_activism_rounded.codePoint) return Icons.volunteer_activism_rounded;
  if (codePoint == Icons.groups_rounded.codePoint) return Icons.groups_rounded;
  if (codePoint == Icons.military_tech_rounded.codePoint) return Icons.military_tech_rounded;
  
  if (codePoint == Icons.directions_subway_rounded.codePoint) return Icons.directions_subway_rounded;
  if (codePoint == Icons.park_rounded.codePoint) return Icons.park_rounded;
  if (codePoint == Icons.sports_tennis_rounded.codePoint) return Icons.sports_tennis_rounded;
  if (codePoint == Icons.local_offer_rounded.codePoint) return Icons.local_offer_rounded;

  return Icons.star_rounded;
}
