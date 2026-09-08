import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/local/mock_data_source.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/hive_user_repository.dart';

void main() {
  group('HiveUserRepository Caching Tests', () {
    late Directory tempDir;
    late HiveUserRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('civic_user_repo_test_');
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      await HiveInitializer.openEssentialBoxes();
      MockDataSource().resetMockData();
      repository = HiveUserRepository();
    });

    tearDown(() async {
      await HiveInitializer.resetForTesting();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('cacheUser stores user profile and retrieves it accurately', () async {
      const testUser = UserModel(
        id: 'usr_test_777',
        fullName: 'Dr. Ramesh Kumar',
        email: 'ramesh.kumar@example.com',
        phone: '+91 98765 43210',
        avatarUrl: 'https://example.com/avatar.jpg',
        civicPoints: 450,
        reportsSubmitted: 15,
        reportsResolved: 12,
        badges: ['badge_first_report', 'badge_verified_citizen'],
        languageCode: 'hi',
        wardNumber: 'Ward 25 (East)',
      );

      await repository.cacheUser(testUser);

      final retrieved = await repository.getCurrentUser();
      expect(retrieved.id, equals(testUser.id));
      expect(retrieved.fullName, equals(testUser.fullName));
      expect(retrieved.email, equals(testUser.email));
      expect(retrieved.phone, equals(testUser.phone));
      expect(retrieved.civicPoints, equals(450));
      expect(retrieved.languageCode, equals('hi'));
      expect(retrieved.wardNumber, equals('Ward 25 (East)'));
      expect(retrieved.badges.length, equals(2));
    });

    test('updateUserProfile updates persistent cache and emits to ValueListenable', () async {
      bool listenableTriggered = false;
      repository.getUserListenable().addListener(() {
        listenableTriggered = true;
      });

      final updated = await repository.updateUserProfile(
        fullName: 'Ramesh K. Sharma',
        wardNumber: 'Ward 108',
      );

      expect(updated.fullName, equals('Ramesh K. Sharma'));
      expect(updated.wardNumber, equals('Ward 108'));
      expect(listenableTriggered, isTrue);

      final current = await repository.getCurrentUser();
      expect(current.fullName, equals('Ramesh K. Sharma'));
    });

    test('redeemReward decrements points and caches updated points balance', () async {
      final catalog = await repository.getRewardsCatalog();
      final firstReward = catalog.first;

      final initialUser = await repository.getCurrentUser();
      final expectedPoints = initialUser.civicPoints - firstReward.pointsCost;

      final success = await repository.redeemReward(firstReward.id);
      expect(success, isTrue);

      final updatedUser = await repository.getCurrentUser();
      expect(updatedUser.civicPoints, equals(expectedPoints));
    });
  });
}
