import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/repositories/hive_rewards_repository.dart';

void main() {
  group('HiveRewardsRepository Caching Tests', () {
    late Directory tempDir;
    late HiveRewardsRepository repository;

    final customAchievements = [
      CivicAchievement(
        id: 'ach_civic_starter',
        title: 'Civic Starter',
        description: 'Submit your first verified civic issue.',
        howToUnlock: 'Submit 1 issue that passes triage',
        icon: Icons.star_outline_rounded,
        isUnlocked: true,
        pointsRequired: 0,
        unlockedAt: DateTime.now(),
      ),
      CivicAchievement(
        id: 'ach_road_guardian',
        title: 'Road Guardian',
        description: 'Report 5 pothole or road safety hazards.',
        howToUnlock: 'Report 5 verified road hazards',
        icon: Icons.shield_outlined,
        isUnlocked: false,
        pointsRequired: 100,
      ),
    ];

    final customPerks = [
      const CivicRewardItem(
        id: 'perk_coffee_discount',
        title: '₹50 Off at Cafe Coffee Day',
        partner: 'Cafe Coffee Day',
        description: 'Valid on orders above ₹200.',
        pointsCost: 150,
        expiryDate: '31 Dec 2026',
        icon: Icons.local_cafe_outlined,
      ),
    ];

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('civic_rewards_repo_test_');
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      await HiveInitializer.openEssentialBoxes();
      repository = HiveRewardsRepository();
      await repository.cacheAchievements(customAchievements);
      await repository.cacheRewardsCatalog(customPerks);
    });

    tearDown(() async {
      await HiveInitializer.resetForTesting();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('getAchievements and getRewardsCatalog retrieve cached items', () async {
      final achievements = await repository.getAchievements();
      expect(achievements.length, equals(2));
      expect(achievements.first.id, equals('ach_civic_starter'));
      expect(achievements.first.isUnlocked, isTrue);

      final perks = await repository.getRewardsCatalog();
      expect(perks.length, equals(1));
      expect(perks.first.partner, equals('Cafe Coffee Day'));
    });

    test('getAchievementById returns specific item or null if missing', () async {
      final starter = await repository.getAchievementById('ach_civic_starter');
      expect(starter, isNotNull);
      expect(starter!.title, equals('Civic Starter'));

      final missing = await repository.getAchievementById('ach_non_existent');
      expect(missing, isNull);
    });

    test('getRewardData aggregates user points, achievements, and perks', () async {
      final rewardData = await repository.getRewardData('user_001');
      expect(rewardData.achievements.length, equals(2));
      expect(rewardData.perks.length, equals(1));
      expect(rewardData.nextMilestoneTarget, equals(1000));
    });
  });
}
