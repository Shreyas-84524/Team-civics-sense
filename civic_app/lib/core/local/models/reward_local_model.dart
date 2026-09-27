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
    IconData resolvedIcon = Icons.military_tech_rounded;
    for (final def in CivicAchievement.defaultAchievements()) {
      if (def.id == id || def.icon.codePoint == iconCodePoint) {
        resolvedIcon = def.icon;
        break;
      }
    }

    return CivicAchievement(
      id: id,
      title: title,
      description: description,
      howToUnlock: howToUnlock,
      icon: resolvedIcon,
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
    IconData resolvedIcon = Icons.card_giftcard_rounded;
    if (iconCodePoint == Icons.local_offer_rounded.codePoint) {
      resolvedIcon = Icons.local_offer_rounded;
    } else if (iconCodePoint == Icons.local_cafe_rounded.codePoint) {
      resolvedIcon = Icons.local_cafe_rounded;
    } else if (iconCodePoint == Icons.directions_bus_rounded.codePoint) {
      resolvedIcon = Icons.directions_bus_rounded;
    } else if (iconCodePoint == Icons.confirmation_number_rounded.codePoint) {
      resolvedIcon = Icons.confirmation_number_rounded;
    } else if (iconCodePoint == Icons.shopping_bag_rounded.codePoint) {
      resolvedIcon = Icons.shopping_bag_rounded;
    }

    return CivicRewardItem(
      id: id,
      title: title,
      partner: partner,
      description: description,
      pointsCost: pointsCost,
      expiryDate: expiryDate,
      icon: resolvedIcon,
    );
  }
}
