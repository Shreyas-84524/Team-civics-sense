import 'package:civic_app/User%20UI/services/geolocator_location_service.dart';
import 'package:civic_app/User%20UI/services/location_service.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeolocatorLocationService Unit Tests', () {
    late GeolocatorLocationService service;

    setUp(() {
      service = const GeolocatorLocationService();
    });

    test('implements LocationService interface', () {
      expect(service, isA<LocationService>());
    });

    test('searchPlaces returns matching civic locations for query', () async {
      final results = await service.searchPlaces('Indiranagar');
      expect(results, isNotEmpty);
      expect(results.any((loc) => loc.ward?.contains('Indiranagar') ?? false), isTrue);
    });

    test('searchPlaces returns empty list for empty query', () async {
      final results = await service.searchPlaces('');
      expect(results, isEmpty);
    });

    test('reverseGeocode finds proximate landmarks or generates coordinate location', () async {
      // Proximate to known mock directory coordinate (12.9716, 77.5946)
      final proximate = await service.reverseGeocode(12.9716, 77.5946);
      expect(proximate.latitude, equals(12.9716));
      expect(proximate.longitude, equals(77.5946));
      expect(proximate.source, equals(LocationSource.manual));

      // Arbitrary non-directory coordinate
      final arbitrary = await service.reverseGeocode(28.6139, 77.2090);
      expect(arbitrary.latitude, equals(28.6139));
      expect(arbitrary.longitude, equals(77.2090));
      expect(arbitrary.address, contains('28.6139'));
      expect(arbitrary.source, equals(LocationSource.manual));
    });
  });

  group('RepositoryLocator LocationService Integration', () {
    setUp(() {
      RepositoryLocator.reset();
    });

    tearDown(() {
      RepositoryLocator.reset();
    });

    test('defaults to MockLocationService in test/mock environment', () {
      expect(RepositoryLocator.isProductionActive, isFalse);
      expect(RepositoryLocator.locationService, isA<MockLocationService>());
    });

    test('switches to GeolocatorLocationService when production repositories are enabled', () {
      RepositoryLocator.useProductionRepositories();
      expect(RepositoryLocator.isProductionActive, isTrue);
      expect(RepositoryLocator.locationService, isA<GeolocatorLocationService>());
    });

    test('allows explicit LocationService override for tests', () {
      final customMock = MockLocationService(
        customGpsLocation: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Marine Drive',
          city: 'Mumbai',
        ),
      );
      RepositoryLocator.locationService = customMock;
      expect(RepositoryLocator.locationService, equals(customMock));
    });
  });
}
