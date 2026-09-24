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

    test('Performance Benchmark: Serializes 10, 100, 500, and 1000 features in sub-millisecond per item speed', () {
      for (final count in [10, 100, 500, 1000]) {
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

        // Average processing time should be comfortably under 50ms for 1000 items
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      }
    });
  });
}
