import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/cache/cache_metadata.dart';

void main() {
  group('CacheMetadata & CachePolicy Unit Tests', () {
    test('CacheMetadata calculates age and staleness correctly', () {
      final now = DateTime.now();
      final recent = CacheMetadata(boxName: 'complaints', cachedAt: now);
      expect(recent.isStale(const Duration(hours: 1)), isFalse);
      expect(recent.formattedAge, equals('just now'));
      expect(recent.displayLabel, equals('Updated recently'));

      final oneHourAgo = CacheMetadata(
        boxName: 'complaints',
        cachedAt: now.subtract(const Duration(minutes: 65)),
        recordCount: 12,
      );
      expect(oneHourAgo.isStale(const Duration(hours: 1)), isTrue);
      expect(oneHourAgo.formattedAge, equals('1h ago'));
      expect(oneHourAgo.displayLabel, contains('Showing cached information'));
    });

    test('CacheMetadata serialization and deserialization', () {
      final meta = CacheMetadata(
        boxName: 'hazards',
        cachedAt: DateTime(2026, 9, 8, 12, 0),
        recordCount: 42,
        version: '1.2.0',
      );

      final map = meta.toMap();
      final restored = CacheMetadata.fromMap(map);

      expect(restored.boxName, equals('hazards'));
      expect(restored.cachedAt.millisecondsSinceEpoch, equals(meta.cachedAt.millisecondsSinceEpoch));
      expect(restored.recordCount, equals(42));
      expect(restored.version, equals('1.2.0'));
    });

    test('CachePolicy defines standard non-null durations for all domains', () {
      expect(CachePolicy.complaintsMaxAge, equals(const Duration(days: 14)));
      expect(CachePolicy.hazardsMaxAge, equals(const Duration(hours: 2)));
      expect(CachePolicy.notificationsMaxAge, equals(const Duration(days: 7)));
      expect(CachePolicy.userProfileMaxAge, equals(const Duration(days: 30)));
      expect(CachePolicy.rewardsMaxAge, equals(const Duration(days: 7)));
      expect(CachePolicy.analyticsMaxAge, equals(const Duration(hours: 1)));
    });
  });
}
