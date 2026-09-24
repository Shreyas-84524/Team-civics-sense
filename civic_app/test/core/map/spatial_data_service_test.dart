import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/spatial_data_service.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';

void main() {
  const service = SpatialDataService();

  final sampleComplaints = [
    ComplaintModel(
      id: 'cmp_1',
      ticketNumber: 'CF-2026-000001',
      title: 'Pothole on Linking Road',
      description: 'Large pothole causing traffic slowdown.',
      category: CivicCategory.defaultCategories[0], // Roads
      status: ComplaintStatus.inProgress,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0596,
        longitude: 72.8295,
        address: 'Linking Road, Bandra West',
        ward: 'H/West',
        city: 'Mumbai',
      ),
      departmentName: 'Roads & Infrastructure',
      createdAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 20),
    ),
    ComplaintModel(
      id: 'cmp_2',
      ticketNumber: 'CF-2026-000002',
      title: 'Water supply interruption',
      description: 'Low water pressure in municipal lines.',
      category: CivicCategory.defaultCategories[1], // Water
      status: ComplaintStatus.assigned,
      priority: ComplaintPriority.medium,
      location: const CivicLocation(
        latitude: 19.0178,
        longitude: 72.8478,
        address: 'Dadar East, Mumbai',
        ward: 'F/South',
        city: 'Mumbai',
      ),
      departmentName: 'Water Supply & Sewerage',
      createdAt: DateTime(2026, 9, 21),
      updatedAt: DateTime(2026, 9, 21),
    ),
    ComplaintModel(
      id: 'cmp_invalid',
      ticketNumber: 'CF-2026-000003',
      title: 'Garbage dump with bad coordinates',
      description: 'Testing invalid coordinate skipping.',
      category: CivicCategory.defaultCategories[3], // Waste Management
      status: ComplaintStatus.reported,
      priority: ComplaintPriority.low,
      location: const CivicLocation(
        latitude: 120.0, // Invalid lat > 90
        longitude: 72.8500,
        address: 'Nowhere',
      ),
      createdAt: DateTime(2026, 9, 22),
      updatedAt: DateTime(2026, 9, 22),
    ),
  ];

  final sampleHazards = [
    HazardModel(
      id: 'haz_1',
      complaintId: 'cmp_1',
      ticketNumber: 'CF-2026-000001',
      title: 'Flooded subway underpass',
      category: CivicCategory.defaultCategories[1], // Water
      status: ComplaintStatus.inProgress,
      severity: HazardSeverity.critical,
      latitude: 19.1136,
      longitude: 72.8697,
      address: 'Andheri East Subway',
      ward: 'K/East',
      createdAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 20),
    ),
    HazardModel(
      id: 'haz_2',
      ticketNumber: 'CF-2026-000004',
      title: 'Open transformer box',
      category: CivicCategory.defaultCategories[4], // Street Lights / Electrical
      status: ComplaintStatus.reported,
      severity: HazardSeverity.high,
      latitude: 19.0760,
      longitude: 72.8777,
      address: 'Dharavi Main Road',
      ward: 'G/North',
      createdAt: DateTime(2026, 9, 21),
      updatedAt: DateTime(2026, 9, 21),
    ),
  ];

  group('SpatialDataService Unit Tests', () {
    test('extractComplaintFeatures extracts valid complaints and skips malformed coordinates', () {
      final features = service.extractComplaintFeatures(sampleComplaints);
      expect(features.length, equals(2));
      expect(features.map((f) => f.id), containsAll(['cmp_1', 'cmp_2']));
      expect(features.map((f) => f.id), isNot(contains('cmp_invalid')));
    });

    test('extractComplaintFeatures filters by category and status', () {
      final roadComplaints = service.extractComplaintFeatures(
        sampleComplaints,
        categoryId: 'cat_roads_potholes',
      );
      expect(roadComplaints.length, equals(1));
      expect(roadComplaints.first.id, equals('cmp_1'));

      final assignedComplaints = service.extractComplaintFeatures(
        sampleComplaints,
        status: ComplaintStatus.assigned,
      );
      expect(assignedComplaints.length, equals(1));
      expect(assignedComplaints.first.id, equals('cmp_2'));
    });

    test('extractComplaintFeatures filters by department and ward', () {
      final waterDept = service.extractComplaintFeatures(
        sampleComplaints,
        department: 'Water Supply',
      );
      expect(waterDept.length, equals(1));
      expect(waterDept.first.id, equals('cmp_2'));

      final bandraWard = service.extractComplaintFeatures(
        sampleComplaints,
        ward: 'H/West',
      );
      expect(bandraWard.length, equals(1));
      expect(bandraWard.first.id, equals('cmp_1'));
    });

    test('extractHazardFeatures extracts hazards and filters by severity and status', () {
      final criticalHazards = service.extractHazardFeatures(
        sampleHazards,
        severity: HazardSeverity.critical,
      );
      expect(criticalHazards.length, equals(1));
      expect(criticalHazards.first.id, equals('haz_1'));

      final reportedHazards = service.extractHazardFeatures(
        sampleHazards,
        status: ComplaintStatus.reported,
      );
      expect(reportedHazards.length, equals(1));
      expect(reportedHazards.first.id, equals('haz_2'));
    });

    test('buildFeatureCollection combines complaints and hazards into a valid GeoJSON FeatureCollection', () {
      final collection = service.buildFeatureCollection(
        complaints: sampleComplaints,
        hazards: sampleHazards,
      );

      expect(collection['type'], equals('FeatureCollection'));
      final features = collection['features'] as List<dynamic>;
      expect(features.length, equals(4)); // 2 valid complaints + 2 valid hazards

      // Verify coordinate order for all features is [longitude, latitude]
      for (final f in features) {
        final map = f as Map<String, dynamic>;
        final coords = (map['geometry'] as Map)['coordinates'] as List<dynamic>;
        expect(coords.length, equals(2));
        final lng = coords[0] as double;
        final lat = coords[1] as double;
        expect(lng, inInclusiveRange(72.0, 74.0)); // Mumbai longitude range
        expect(lat, inInclusiveRange(18.0, 20.0)); // Mumbai latitude range
      }
    });

    test('createEmptyFeatureCollection returns standard empty FeatureCollection', () {
      final empty = SpatialDataService.createEmptyFeatureCollection();
      expect(empty['type'], equals('FeatureCollection'));
      expect(empty['features'], isEmpty);
    });

    test('SpatialTimeFilter filters complaints by creation date relative to reference time', () {
      final now = DateTime(2026, 9, 24, 12, 0);

      final timedComplaints = [
        ComplaintModel(
          id: 'cmp_2h',
          ticketNumber: 'CF-2026-000010',
          title: 'Recent pothole 2 hours ago',
          description: 'Pothole on main road',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.high,
          location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        ComplaintModel(
          id: 'cmp_3d',
          ticketNumber: 'CF-2026-000011',
          title: 'Issue 3 days ago',
          description: 'Water leak',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        ComplaintModel(
          id: 'cmp_15d',
          ticketNumber: 'CF-2026-000012',
          title: 'Issue 15 days ago',
          description: 'Street light broken',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.low,
          location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 15)),
        ),
        ComplaintModel(
          id: 'cmp_45d',
          ticketNumber: 'CF-2026-000013',
          title: 'Issue 45 days ago',
          description: 'Garbage accumulation',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.low,
          location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
          createdAt: now.subtract(const Duration(days: 45)),
          updatedAt: now.subtract(const Duration(days: 45)),
        ),
      ];

      // 1. Last 24 Hours
      final last24h = service.extractComplaintFeatures(
        timedComplaints,
        timeFilter: SpatialTimeFilter.last24Hours,
        referenceTime: now,
      );
      expect(last24h.length, equals(1));
      expect(last24h.first.id, equals('cmp_2h'));

      // 2. Last 7 Days
      final last7d = service.extractComplaintFeatures(
        timedComplaints,
        timeFilter: SpatialTimeFilter.last7Days,
        referenceTime: now,
      );
      expect(last7d.length, equals(2));
      expect(last7d.map((f) => f.id), containsAll(['cmp_2h', 'cmp_3d']));

      // 3. Last 30 Days
      final last30d = service.extractComplaintFeatures(
        timedComplaints,
        timeFilter: SpatialTimeFilter.last30Days,
        referenceTime: now,
      );
      expect(last30d.length, equals(3));
      expect(last30d.map((f) => f.id), containsAll(['cmp_2h', 'cmp_3d', 'cmp_15d']));

      // 4. All Time
      final allTime = service.extractComplaintFeatures(
        timedComplaints,
        timeFilter: SpatialTimeFilter.allTime,
        referenceTime: now,
      );
      expect(allTime.length, equals(4));
    });

    test('Density Semantics: Exact N valid inputs result in exactly N GeoJSON spatial features without distortion', () {
      final inputList = List.generate(50, (i) {
        return HazardModel(
          id: 'haz_density_$i',
          title: 'Hazard #$i',
          category: CivicCategory.defaultCategories[i % CivicCategory.defaultCategories.length],
          status: ComplaintStatus.reported,
          severity: HazardSeverity.medium,
          latitude: 19.0 + (i * 0.001),
          longitude: 72.8 + (i * 0.001),
          address: 'Location #$i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });

      final collection = service.buildFeatureCollection(hazards: inputList);
      final features = collection['features'] as List;
      expect(features.length, equals(50));
    });

    test('Performance Benchmark: Serializes 100, 500, 1000, 5000, and 10000 features cleanly', () {
      for (final count in [100, 500, 1000, 5000, 10000]) {
        final syntheticComplaints = List.generate(count, (i) {
          return ComplaintModel(
            id: 'perf_cmp_$i',
            ticketNumber: 'CF-2026-${i.toString().padLeft(6, '0')}',
            title: 'Synthetic Civic Issue #$i',
            description: 'Performance testing feature serialization.',
            category: CivicCategory.defaultCategories[i % CivicCategory.defaultCategories.length],
            status: ComplaintStatus.values[i % ComplaintStatus.values.length],
            priority: ComplaintPriority.values[i % ComplaintPriority.values.length],
            location: CivicLocation(
              latitude: 18.90 + (i % 40) * 0.01,
              longitude: 72.80 + (i % 30) * 0.01,
              address: 'Street $i, Mumbai',
              ward: 'Ward ${i % 24}',
              city: 'Mumbai',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });

        final stopwatch = Stopwatch()..start();
        final collection = service.buildFeatureCollection(complaints: syntheticComplaints);
        stopwatch.stop();

        expect(collection['type'], equals('FeatureCollection'));
        expect((collection['features'] as List).length, equals(count));

        // Average processing time should remain under 300ms even for 10,000 items
        expect(stopwatch.elapsedMilliseconds, lessThan( count > 2000 ? 500 : 150 ));
      }
    });

    test('Boundary & Timezone Edge Cases: Exact cutoffs and UTC representations', () {
      final nowUtc = DateTime.utc(2026, 9, 24, 12, 0, 0);

      final exact24hAgo = nowUtc.subtract(const Duration(hours: 24));
      final past24h1sAgo = nowUtc.subtract(const Duration(hours: 24, seconds: 1));
      final future10mAgo = nowUtc.add(const Duration(minutes: 10));

      final testCases = [
        ComplaintModel(
          id: 'cmp_exact_24h',
          ticketNumber: 'CF-2026-900001',
          title: 'Exact 24h boundary',
          description: 'Boundary test',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
          createdAt: exact24hAgo,
          updatedAt: exact24hAgo,
        ),
        ComplaintModel(
          id: 'cmp_past_24h',
          ticketNumber: 'CF-2026-900002',
          title: 'Past 24h boundary',
          description: 'Boundary test',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
          createdAt: past24h1sAgo,
          updatedAt: past24h1sAgo,
        ),
        ComplaintModel(
          id: 'cmp_future_drift',
          ticketNumber: 'CF-2026-900003',
          title: 'Clock drift future timestamp',
          description: 'Boundary test',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Mumbai'),
          createdAt: future10mAgo,
          updatedAt: future10mAgo,
        ),
      ];

      final filtered24h = service.extractComplaintFeatures(
        testCases,
        timeFilter: SpatialTimeFilter.last24Hours,
        referenceTime: nowUtc,
      );

      // Exact 24h and future clock drift are included, 24h + 1s is excluded
      expect(filtered24h.map((f) => f.id), containsAll(['cmp_exact_24h', 'cmp_future_drift']));
      expect(filtered24h.map((f) => f.id), isNot(contains('cmp_past_24h')));
    });

    test('Duplicate Coordinates: Multiple reports at same coordinate preserved without deduplication', () {
      final duplicateList = List.generate(5, (i) {
        return ComplaintModel(
          id: 'cmp_dup_$i',
          ticketNumber: 'CF-2026-00000$i',
          title: 'Duplicate Location Report #$i',
          description: 'Multiple citizens reporting same spot',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.high,
          location: const CivicLocation(
            latitude: 19.0760,
            longitude: 72.8777,
            address: 'Dharavi Junction',
          ),
          createdAt: DateTime(2026, 9, 24),
          updatedAt: DateTime(2026, 9, 24),
        );
      });

      final collection = service.buildFeatureCollection(complaints: duplicateList);
      final features = collection['features'] as List;

      // All 5 features must exist to accumulate natural heatmap density
      expect(features.length, equals(5));
      for (final f in features) {
        final coords = (f['geometry'] as Map)['coordinates'] as List;
        expect(coords[0], equals(72.8777));
        expect(coords[1], equals(19.0760));
      }
    });

    test('Empty Dataset: Returns valid GeoJSON with 0 features without error', () {
      final collection = service.buildFeatureCollection(complaints: [], hazards: []);
      expect(collection['type'], equals('FeatureCollection'));
      expect((collection['features'] as List).isEmpty, isTrue);
    });
  });
}

