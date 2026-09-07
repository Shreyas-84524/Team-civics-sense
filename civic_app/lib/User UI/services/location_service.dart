import 'dart:async';
import '../../core/location/location_model.dart';

/// Abstract service interface defining location detection, permissions, and place lookups.
abstract class LocationService {
  /// Gets current device GPS location. Returns `null` if unable to detect.
  Future<CivicLocation?> getCurrentLocation();

  /// Checks current device location permission.
  Future<CivicPermissionStatus> checkPermission();

  /// Requests location permission from the user.
  Future<CivicPermissionStatus> requestPermission();

  /// Checks if location hardware service is enabled on the device.
  Future<bool> isLocationServiceEnabled();

  /// Searches for civic places / addresses matching the query.
  Future<List<CivicLocation>> searchPlaces(String query);

  /// Performs reverse-geocoding for given map coordinates.
  Future<CivicLocation> reverseGeocode(double latitude, double longitude);
}

/// In-memory mock implementation of LocationService for development and testing.
class MockLocationService implements LocationService {
  CivicPermissionStatus permissionStatus;
  bool isServiceEnabled;
  bool simulateError;
  CivicLocation? customGpsLocation;

  MockLocationService({
    this.permissionStatus = CivicPermissionStatus.granted,
    this.isServiceEnabled = true,
    this.simulateError = false,
    this.customGpsLocation,
  });

  static const CivicLocation defaultGpsLocation = CivicLocation(
    latitude: 12.9716,
    longitude: 77.5946,
    address: '4th Cross, 2nd Main Road',
    landmark: 'Opposite Community Park',
    ward: 'Ward 14 (Central Ward)',
    city: 'Bengaluru',
    pincode: '560001',
    source: LocationSource.gps,
    accuracyMeters: 5.0,
  );

  static final List<CivicLocation> mockDirectory = [
    const CivicLocation(
      latitude: 12.9716,
      longitude: 77.5946,
      address: '4th Cross, 2nd Main Road',
      landmark: 'Opposite Community Park',
      ward: 'Ward 14 (Central Ward)',
      city: 'Bengaluru',
      pincode: '560001',
      source: LocationSource.manual,
    ),
    const CivicLocation(
      latitude: 12.9750,
      longitude: 77.6080,
      address: 'MG Road Boulevard, Near Metro Pillar 142',
      landmark: 'Near Central Metro Station',
      ward: 'Ward 12 (Shivajinagar)',
      city: 'Bengaluru',
      pincode: '560001',
      source: LocationSource.manual,
    ),
    const CivicLocation(
      latitude: 12.9784,
      longitude: 77.6408,
      address: '100 Feet Road, 12th Main Junction',
      landmark: 'Behind Indiranagar Club',
      ward: 'Ward 18 (Indiranagar)',
      city: 'Bengaluru',
      pincode: '560038',
      source: LocationSource.manual,
    ),
    const CivicLocation(
      latitude: 12.9352,
      longitude: 77.6245,
      address: '80 Feet Road, 5th Block',
      landmark: 'Opposite Municipal Water Tank',
      ward: 'Ward 22 (Koramangala)',
      city: 'Bengaluru',
      pincode: '560095',
      source: LocationSource.manual,
    ),
    const CivicLocation(
      latitude: 13.0031,
      longitude: 77.5643,
      address: '8th Cross, Sampige Road',
      landmark: 'Near Malleshwaram Market',
      ward: 'Ward 5 (Malleshwaram)',
      city: 'Bengaluru',
      pincode: '560003',
      source: LocationSource.manual,
    ),
    const CivicLocation(
      latitude: 12.9698,
      longitude: 77.7500,
      address: 'ITPB Main Road, Hope Farm Junction',
      landmark: 'Near Tech Park Gate 2',
      ward: 'Ward 30 (Whitefield)',
      city: 'Bengaluru',
      pincode: '560066',
      source: LocationSource.manual,
    ),
  ];

  @override
  Future<CivicPermissionStatus> checkPermission() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return permissionStatus;
  }

  @override
  Future<CivicPermissionStatus> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (permissionStatus == CivicPermissionStatus.notDetermined ||
        permissionStatus == CivicPermissionStatus.denied) {
      permissionStatus = CivicPermissionStatus.granted;
    }
    return permissionStatus;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return isServiceEnabled;
  }

  @override
  Future<CivicLocation?> getCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!isServiceEnabled) {
      throw Exception('Location services are disabled on your device. Please enable them in settings.');
    }

    if (permissionStatus != CivicPermissionStatus.granted) {
      final requested = await requestPermission();
      if (requested != CivicPermissionStatus.granted) {
        throw Exception('Location permission was denied.');
      }
    }

    if (simulateError) {
      throw Exception('GPS hardware error. Unable to acquire satellite signal.');
    }

    final base = customGpsLocation ?? defaultGpsLocation;
    return base.copyWith(
      source: LocationSource.gps,
      timestamp: DateTime.now(),
      accuracyMeters: base.accuracyMeters ?? 4.8,
    );
  }

  @override
  Future<List<CivicLocation>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return const [];

    return mockDirectory.where((loc) {
      return loc.address.toLowerCase().contains(cleanQuery) ||
          (loc.landmark?.toLowerCase().contains(cleanQuery) ?? false) ||
          (loc.ward?.toLowerCase().contains(cleanQuery) ?? false) ||
          (loc.city?.toLowerCase().contains(cleanQuery) ?? false);
    }).toList();
  }

  @override
  Future<CivicLocation> reverseGeocode(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 150));

    // Find closest mock or create synthetic address for coordinates
    for (final loc in mockDirectory) {
      if ((loc.latitude - latitude).abs() < 0.005 &&
          (loc.longitude - longitude).abs() < 0.005) {
        return loc.copyWith(
          latitude: latitude,
          longitude: longitude,
          source: LocationSource.manual,
        );
      }
    }

    return CivicLocation(
      latitude: latitude,
      longitude: longitude,
      address: 'Selected Map Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})',
      ward: 'Ward 14 (Central Ward)',
      city: 'Bengaluru',
      pincode: '560001',
      source: LocationSource.manual,
      timestamp: DateTime.now(),
    );
  }

  void reset() {
    permissionStatus = CivicPermissionStatus.granted;
    isServiceEnabled = true;
    simulateError = false;
    customGpsLocation = null;
  }
}
