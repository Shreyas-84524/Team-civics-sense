import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/repositories/hive_hazard_repository.dart';

void main() {
  group('HiveHazardRepository Caching Tests', () {
    late Directory tempDir;
    late HiveHazardRepository repository;

    final testHazards = [
      HazardModel(
        id: 'haz_101',
        complaintId: 'cmp_101',
        ticketNumber: 'CF-2026-000101',
        title: 'Open Manhole without Cover',
        category: CivicCategory.defaultCategories[5], // Drainage
        status: ComplaintStatus.reported,
        latitude: 12.9716, // Near MG Road
        longitude: 77.5946,
        address: 'MG Road Junction',
        landmark: 'Metro Station Exit B',
        ward: 'Ward 111',
        severity: HazardSeverity.critical,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      HazardModel(
        id: 'haz_102',
        complaintId: 'cmp_102',
        ticketNumber: 'CF-2026-000102',
        title: 'Water pipe burst flooding street',
        category: CivicCategory.defaultCategories[1], // Water
        status: ComplaintStatus.inProgress,
        latitude: 12.9750, // Approx 0.5km away
        longitude: 77.5980,
        address: 'Brigade Road',
        ward: 'Ward 111',
        severity: HazardSeverity.high,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      HazardModel(
        id: 'haz_103',
        complaintId: 'cmp_103',
        ticketNumber: 'CF-2026-000103',
        title: 'Resolved fallen tree branch',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.resolved,
        latitude: 13.1000, // > 15km away
        longitude: 77.7000,
        address: 'Yelahanka High Street',
        severity: HazardSeverity.medium,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('civic_hazard_repo_test_');
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      await HiveInitializer.openEssentialBoxes();
      repository = HiveHazardRepository();
      await repository.cacheHazards(testHazards);
    });

    tearDown(() async {
      await HiveInitializer.resetForTesting();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('getHazards filters by category, severity, status, and query', () async {
      final critical = await repository.getHazards(severity: HazardSeverity.critical);
      expect(critical.length, equals(1));
      expect(critical.first.id, equals('haz_101'));

      final searchResults = await repository.getHazards(searchQuery: 'Brigade');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.title, contains('Water pipe burst'));
    });

    test('getNearbyHazards filters active hazards within radiusKm', () async {
      // Coordinate near MG Road
      final nearby = await repository.getNearbyHazards(
        latitude: 12.9716,
        longitude: 77.5946,
        radiusKm: 2.0,
      );

      // Should return haz_101 and haz_102, omitting far away and resolved haz_103
      expect(nearby.length, equals(2));
      expect(nearby.any((h) => h.id == 'haz_101'), isTrue);
      expect(nearby.any((h) => h.id == 'haz_102'), isTrue);
    });

    test('clearStaleHazards purges resolved hazards older than threshold', () async {
      await repository.clearStaleHazards(maxAge: const Duration(hours: 1));

      final all = await repository.getHazards();
      // haz_103 was 3 days old and resolved -> should be purged
      expect(all.any((h) => h.id == 'haz_103'), isFalse);
      // Active hazards are preserved
      expect(all.length, equals(2));
    });
  });
}
