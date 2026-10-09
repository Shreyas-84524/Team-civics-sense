import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/models/reward_model.dart';

void main() {
  group('CivicLevel & CivicLevelInfo Calculator Tests — Phase 2', () {
    test('0 points evaluates to Level 1: Civic Starter with 100 points remaining', () {
      final info = CivicLevelInfo.calculate(0);
      expect(info.level, equals(1));
      expect(info.title, equals('Civic Starter'));
      expect(info.symbol, equals('🌱'));
      expect(info.totalPoints, equals(0));
      expect(info.nextLevelNumber, equals(2));
      expect(info.nextLevelTitle, equals('Civic Contributor'));
      expect(info.nextLevelMinPoints, equals(100));
      expect(info.pointsRemaining, equals(100));
      expect(info.progress, equals(0.0));
      expect(info.isMaxLevel, isFalse);
    });

    test('100 points evaluates to Level 2: Civic Contributor with 150 points remaining', () {
      final info = CivicLevelInfo.calculate(100);
      expect(info.level, equals(2));
      expect(info.title, equals('Civic Contributor'));
      expect(info.symbol, equals('🌿'));
      expect(info.totalPoints, equals(100));
      expect(info.nextLevelNumber, equals(3));
      expect(info.nextLevelTitle, equals('Civic Champion'));
      expect(info.nextLevelMinPoints, equals(250));
      expect(info.pointsRemaining, equals(150));
      expect(info.progress, equals(0.0));
      expect(info.isMaxLevel, isFalse);
    });

    test('250 points evaluates to Level 3: Civic Champion with 250 points remaining', () {
      final info = CivicLevelInfo.calculate(250);
      expect(info.level, equals(3));
      expect(info.title, equals('Civic Champion'));
      expect(info.symbol, equals('🌳'));
      expect(info.totalPoints, equals(250));
      expect(info.nextLevelNumber, equals(4));
      expect(info.nextLevelTitle, equals('Civic Leader'));
      expect(info.nextLevelMinPoints, equals(500));
      expect(info.pointsRemaining, equals(250));
      expect(info.progress, equals(0.0));
      expect(info.isMaxLevel, isFalse);
    });

    test('500 points evaluates to Level 4: Civic Leader with 500 points remaining', () {
      final info = CivicLevelInfo.calculate(500);
      expect(info.level, equals(4));
      expect(info.title, equals('Civic Leader'));
      expect(info.symbol, equals('🏆'));
      expect(info.totalPoints, equals(500));
      expect(info.nextLevelNumber, equals(5));
      expect(info.nextLevelTitle, equals('Civic Hero'));
      expect(info.nextLevelMinPoints, equals(1000));
      expect(info.pointsRemaining, equals(500));
      expect(info.progress, equals(0.0));
      expect(info.isMaxLevel, isFalse);
    });

    test('1000 points evaluates to Level 5: Civic Hero with no fake next level & complete progress', () {
      final info = CivicLevelInfo.calculate(1000);
      expect(info.level, equals(5));
      expect(info.title, equals('Civic Hero'));
      expect(info.symbol, equals('⭐'));
      expect(info.totalPoints, equals(1000));
      expect(info.nextLevel, isNull);
      expect(info.nextLevelNumber, isNull);
      expect(info.nextLevelTitle, isNull);
      expect(info.nextLevelMinPoints, isNull);
      expect(info.pointsRemaining, equals(0));
      expect(info.progress, equals(1.0));
      expect(info.isMaxLevel, isTrue);
    });

    test('Over 1000 points stays at Level 5: Civic Hero with 100% progress', () {
      final info = CivicLevelInfo.calculate(2500);
      expect(info.level, equals(5));
      expect(info.title, equals('Civic Hero'));
      expect(info.nextLevel, isNull);
      expect(info.pointsRemaining, equals(0));
      expect(info.progress, equals(1.0));
      expect(info.isMaxLevel, isTrue);
    });

    test('Negative points safely defaults to Level 1: Civic Starter with 0 points', () {
      final info = CivicLevelInfo.calculate(-50);
      expect(info.level, equals(1));
      expect(info.title, equals('Civic Starter'));
      expect(info.totalPoints, equals(0));
      expect(info.pointsRemaining, equals(100));
      expect(info.progress, equals(0.0));
    });

    test('Tier progress calculation accurately measures intermediate points', () {
      // 50 points -> half of Level 1 (0 to 100)
      final info50 = CivicLevelInfo.calculate(50);
      expect(info50.progress, closeTo(0.5, 0.001));
      expect(info50.pointsRemaining, equals(50));

      // 175 points -> half of Level 2 (100 to 250, span=150)
      final info175 = CivicLevelInfo.calculate(175);
      expect(info175.progress, closeTo(0.5, 0.001));
      expect(info175.pointsRemaining, equals(75));

      // 375 points -> half of Level 3 (250 to 500, span=250)
      final info375 = CivicLevelInfo.calculate(375);
      expect(info375.progress, closeTo(0.5, 0.001));
      expect(info375.pointsRemaining, equals(125));

      // 750 points -> half of Level 4 (500 to 1000, span=500)
      final info750 = CivicLevelInfo.calculate(750);
      expect(info750.progress, closeTo(0.5, 0.001));
      expect(info750.pointsRemaining, equals(250));
    });

    test('Level boundaries are exact and transitions occur at specified thresholds', () {
      // Level 1 max boundary: 99
      final info99 = CivicLevelInfo.calculate(99);
      expect(info99.level, equals(1));
      expect(info99.title, equals('Civic Starter'));
      expect(info99.pointsRemaining, equals(1));

      // Level 2 entry: 100
      final info100 = CivicLevelInfo.calculate(100);
      expect(info100.level, equals(2));
      expect(info100.title, equals('Civic Contributor'));

      // Level 2 max boundary: 249
      final info249 = CivicLevelInfo.calculate(249);
      expect(info249.level, equals(2));
      expect(info249.pointsRemaining, equals(1));

      // Level 3 entry: 250
      final info250 = CivicLevelInfo.calculate(250);
      expect(info250.level, equals(3));
      expect(info250.title, equals('Civic Champion'));

      // Level 3 max boundary: 499
      final info499 = CivicLevelInfo.calculate(499);
      expect(info499.level, equals(3));
      expect(info499.pointsRemaining, equals(1));

      // Level 4 entry: 500
      final info500 = CivicLevelInfo.calculate(500);
      expect(info500.level, equals(4));
      expect(info500.title, equals('Civic Leader'));

      // Level 4 max boundary: 999
      final info999 = CivicLevelInfo.calculate(999);
      expect(info999.level, equals(4));
      expect(info999.pointsRemaining, equals(1));

      // Level 5 entry: 1000
      final info1000 = CivicLevelInfo.calculate(1000);
      expect(info1000.level, equals(5));
      expect(info1000.title, equals('Civic Hero'));
      expect(info1000.pointsRemaining, equals(0));
    });

    test('CivicImpactSummary derives counters cleanly without duplicate state', () {
      const summary = CivicImpactSummary(
        complaintsSubmitted: 10,
        complaintsVerified: 8,
        complaintsResolved: 6,
        communityUpvotes: 42,
        achievementsUnlocked: 3,
      );

      expect(summary.complaintsSubmitted, equals(10));
      expect(summary.complaintsVerified, equals(8));
      expect(summary.complaintsResolved, equals(6));
      expect(summary.communityUpvotes, equals(42));
      expect(summary.achievementsUnlocked, equals(3));
    });
  });
}
