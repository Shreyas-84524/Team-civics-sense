import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/location/location_model.dart';
import 'location_service.dart';

/// Production [LocationService] implementation leveraging the device GPS via `geolocator`.
class GeolocatorLocationService implements LocationService {
  final LocationSettings locationSettings;

  const GeolocatorLocationService({
    this.locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  });

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[GeolocatorLocationService] Error checking location service: $e');
      return false;
    }
  }

  @override
  Future<CivicPermissionStatus> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (e) {
      debugPrint('[GeolocatorLocationService] Error checking location permission: $e');
      return CivicPermissionStatus.notDetermined;
    }
  }

  @override
  Future<CivicPermissionStatus> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return _mapPermission(permission);
    } catch (e) {
      debugPrint('[GeolocatorLocationService] Error requesting location permission: $e');
      return CivicPermissionStatus.denied;
    }
  }

  @override
  Future<CivicLocation?> getCurrentLocation() async {
    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permissionStatus = await checkPermission();
    if (permissionStatus == CivicPermissionStatus.denied ||
        permissionStatus == CivicPermissionStatus.notDetermined) {
      permissionStatus = await requestPermission();
    }

    if (permissionStatus == CivicPermissionStatus.permanentlyDenied) {
      throw const PermissionDeniedException(
        'Location permission is permanently denied. Please enable it in system settings.',
      );
    }

    if (permissionStatus != CivicPermissionStatus.granted) {
      throw const PermissionDeniedException('Location permission was denied.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      return CivicLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
        source: LocationSource.gps,
        address: 'GPS Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
      );
    } on TimeoutException {
      debugPrint('[GeolocatorLocationService] GPS acquisition timed out.');
      throw TimeoutException('GPS acquisition timed out. Please retry or select location on map.');
    } on PlatformException catch (pe) {
      debugPrint('[GeolocatorLocationService] PlatformException: ${pe.message}');
      throw Exception('GPS error: ${pe.message ?? "Unknown platform error"}');
    } catch (e) {
      debugPrint('[GeolocatorLocationService] Unexpected error: $e');
      throw Exception('Unable to acquire GPS coordinates: $e');
    }
  }

  @override
  Future<List<CivicLocation>> searchPlaces(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return const [];

    // Fallback directory search for municipal areas/wards
    return MockLocationService.mockDirectory.where((loc) {
      return loc.address.toLowerCase().contains(cleanQuery) ||
          (loc.landmark?.toLowerCase().contains(cleanQuery) ?? false) ||
          (loc.ward?.toLowerCase().contains(cleanQuery) ?? false) ||
          (loc.city?.toLowerCase().contains(cleanQuery) ?? false);
    }).toList();
  }

  @override
  Future<CivicLocation> reverseGeocode(double latitude, double longitude) async {
    // Check known civic landmarks/wards within geographic proximity threshold
    for (final loc in MockLocationService.mockDirectory) {
      if ((loc.latitude - latitude).abs() < 0.005 &&
          (loc.longitude - longitude).abs() < 0.005) {
        return loc.copyWith(
          latitude: latitude,
          longitude: longitude,
          source: LocationSource.manual,
          timestamp: DateTime.now(),
        );
      }
    }

    return CivicLocation(
      latitude: latitude,
      longitude: longitude,
      address: 'Selected Map Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})',
      source: LocationSource.manual,
      timestamp: DateTime.now(),
    );
  }

  static CivicPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return CivicPermissionStatus.granted;
      case LocationPermission.denied:
        return CivicPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return CivicPermissionStatus.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return CivicPermissionStatus.notDetermined;
    }
  }
}
