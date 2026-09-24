import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/spatial_feature.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';

void main() {
  group('SpatialFeature Unit Tests', () {
    const validLocation = CivicLocation(
      latitude: 19.0760,
      longitude: 72.8777,
      address: 'Dadar West, Mumbai',
      landmark: 'Near Railway Station',
      ward: 'G/North',
      city: 'Mumbai',
      pincode: '400028',
      source: LocationSource.gps,
      accuracyMeters: 4.5,
    );

    final validComplaint = ComplaintModel(
      id: 'cmp_test_001',
      ticketNumber: 'CF-2026-000001',
      title: 'Pothole on Main Road',
      description: 'Dangerous pothole near the intersection.',
      category: CivicCategory.defaultCategories[0],
      status: ComplaintStatus.inProgress,
      priority: ComplaintPriority.high,
      location: validLocation,
      imageUrls: const ['https://example.com/pothole.jpg'],
      createdAt: DateTime(2026, 9, 20, 10, 30),
      updatedAt: DateTime(2026, 9, 21, 12, 00),
      isHazard: true,
      upvotes: 15,
      departmentName: 'Roads & Infrastructure',
    );

    final validHazard = HazardModel(
      id: 'haz_test_001',
      complaintId: 'cmp_test_001',
      ticketNumber: 'CF-2026-000001',
      title: 'Flooded Street Section',
      category: CivicCategory.defaultCategories[1],
      status: ComplaintStatus.verified,
      severity: HazardSeverity.critical,
      latitude: 19.0178,
      longitude: 72.8478,
      address: 'Hindmata, Dadar East',
      landmark: 'Opposite Cinema',
      ward: 'F/South',
      upvotes: 22,
      createdAt: DateTime(2026, 9, 22, 8, 15),
      updatedAt: DateTime(2026, 9, 22, 9, 30),
    );

    test('Strict GeoJSON coordinate ordering is [longitude, latitude]', () {
      final feature = SpatialFeature.fromComplaint(validComplaint);
      expect(feature, isNotNull);

      final geoJson = feature!.toGeoJsonFeature();
      expect(geoJson['type'], equals('Feature'));
      expect(geoJson['id'], equals('cmp_test_001'));

      final geometry = geoJson['geometry'] as Map<String, dynamic>;
      expect(geometry['type'], equals('Point'));

      final coordinates = geometry['coordinates'] as List<dynamic>;
      expect(coordinates.length, equals(2));
      // First coordinate is LONGITUDE (72.8777)
      expect(coordinates[0], equals(72.8777));
      // Second coordinate is LATITUDE (19.0760)
      expect(coordinates[1], equals(19.0760));
    });

    test('Converts ComplaintModel into SpatialFeature preserving all domain metadata', () {
      final feature = SpatialFeature.fromComplaint(validComplaint);
      expect(feature, isNotNull);
      expect(feature!.id, equals('cmp_test_001'));
      expect(feature.type, equals(SpatialFeatureType.complaint));
      expect(feature.latitude, equals(19.0760));
      expect(feature.longitude, equals(72.8777));
      expect(feature.title, equals('Pothole on Main Road'));
      expect(feature.status, equals(ComplaintStatus.inProgress));
      expect(feature.severity, equals('high'));
      expect(feature.category, equals(CivicCategory.defaultCategories[0].name));
      expect(feature.department, equals('Roads & Infrastructure'));
      expect(feature.address, equals('Dadar West, Mumbai'));
      expect(feature.landmark, equals('Near Railway Station'));
      expect(feature.ward, equals('G/North'));
      expect(feature.city, equals('Mumbai'));
      expect(feature.pincode, equals('400028'));
      expect(feature.isHazard, isTrue);
      expect(feature.upvotes, equals(15));
      expect(feature.createdAt, equals(DateTime(2026, 9, 20, 10, 30)));
    });

    test('Converts HazardModel into SpatialFeature preserving hazard metadata', () {
      final feature = SpatialFeature.fromHazard(validHazard);
      expect(feature, isNotNull);
      expect(feature!.id, equals('haz_test_001'));
      expect(feature.type, equals(SpatialFeatureType.hazard));
      expect(feature.latitude, equals(19.0178));
      expect(feature.longitude, equals(72.8478));
      expect(feature.title, equals('Flooded Street Section'));
      expect(feature.status, equals(ComplaintStatus.verified));
      expect(feature.severity, equals('critical'));
      expect(feature.category, equals(CivicCategory.defaultCategories[1].name));
      expect(feature.address, equals('Hindmata, Dadar East'));
      expect(feature.ward, equals('F/South'));
      expect(feature.isHazard, isTrue);
      expect(feature.upvotes, equals(22));
    });

    test('Spatial validation rejects out-of-bounds, NaN, infinity, and null coordinates', () {
      expect(SpatialFeature.isValidCoordinates(19.0760, 72.8777), isTrue);
      expect(SpatialFeature.isValidCoordinates(-90.0, -180.0), isTrue);
      expect(SpatialFeature.isValidCoordinates(90.0, 180.0), isTrue);

      // Out of bounds
      expect(SpatialFeature.isValidCoordinates(90.1, 72.8777), isFalse);
      expect(SpatialFeature.isValidCoordinates(-90.1, 72.8777), isFalse);
      expect(SpatialFeature.isValidCoordinates(19.0760, 180.1), isFalse);
      expect(SpatialFeature.isValidCoordinates(19.0760, -180.1), isFalse);

      // Null, NaN, Infinity
      expect(SpatialFeature.isValidCoordinates(null, 72.8777), isFalse);
      expect(SpatialFeature.isValidCoordinates(19.0760, null), isFalse);
      expect(SpatialFeature.isValidCoordinates(double.nan, 72.8777), isFalse);
      expect(SpatialFeature.isValidCoordinates(19.0760, double.infinity), isFalse);
      expect(SpatialFeature.isValidCoordinates(double.negativeInfinity, 72.8777), isFalse);
    });

    test('fromComplaint returns null safely when coordinates are invalid', () {
      final invalidComplaint = ComplaintModel(
        id: 'cmp_invalid',
        ticketNumber: 'CF-2026-999999',
        title: 'Malformed Coordinates',
        description: 'Testing coordinate safety',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.low,
        location: const CivicLocation(
          latitude: 95.0, // Invalid latitude > 90
          longitude: 72.8777,
          address: 'Invalid Area',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(SpatialFeature.fromComplaint(invalidComplaint), isNull);
    });

    test('fromHazard returns null safely when coordinates are invalid', () {
      final invalidHazard = HazardModel(
        id: 'haz_invalid',
        title: 'Malformed Coordinates',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        latitude: 19.0760,
        longitude: 250.0, // Invalid longitude > 180
        address: 'Invalid Area',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(SpatialFeature.fromHazard(invalidHazard), isNull);
    });

    test('toFeatureCollection generates valid RFC 7946 FeatureCollection', () {
      final f1 = SpatialFeature.fromComplaint(validComplaint)!;
      final f2 = SpatialFeature.fromHazard(validHazard)!;

      final collection = SpatialFeature.toFeatureCollection([f1, f2]);
      expect(collection['type'], equals('FeatureCollection'));
      expect((collection['features'] as List).length, equals(2));

      final first = (collection['features'] as List)[0] as Map<String, dynamic>;
      expect(first['type'], equals('Feature'));
      expect(first['id'], equals('cmp_test_001'));
      expect((first['geometry'] as Map)['coordinates'], equals([72.8777, 19.0760]));

      final second = (collection['features'] as List)[1] as Map<String, dynamic>;
      expect(second['type'], equals('Feature'));
      expect(second['id'], equals('haz_test_001'));
      expect((second['geometry'] as Map)['coordinates'], equals([72.8478, 19.0178]));
    });
  });
}
