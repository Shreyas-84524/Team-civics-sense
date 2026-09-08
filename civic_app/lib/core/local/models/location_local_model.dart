import '../../location/location_model.dart';

/// Local persistence model for geographic coordinates and addresses.
class LocationLocalModel {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? ward;
  final String? city;
  final String? pincode;
  final String source; // 'gps' | 'manual'
  final double? accuracyMeters;
  final int? timestampEpochMs;

  const LocationLocalModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.ward,
    this.city,
    this.pincode,
    this.source = 'manual',
    this.accuracyMeters,
    this.timestampEpochMs,
  });

  /// Map from Domain Model [CivicLocation] -> [LocationLocalModel]
  factory LocationLocalModel.fromDomain(CivicLocation location) {
    return LocationLocalModel(
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      landmark: location.landmark,
      ward: location.ward,
      city: location.city,
      pincode: location.pincode,
      source: location.source == LocationSource.gps ? 'gps' : 'manual',
      accuracyMeters: location.accuracyMeters,
      timestampEpochMs: location.timestamp?.millisecondsSinceEpoch,
    );
  }

  /// Map from [LocationLocalModel] -> Domain Model [CivicLocation]
  CivicLocation toDomain() {
    return CivicLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
      landmark: landmark,
      ward: ward,
      city: city,
      pincode: pincode,
      source: source == 'gps' ? LocationSource.gps : LocationSource.manual,
      accuracyMeters: accuracyMeters,
      timestamp: timestampEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(timestampEpochMs!)
          : null,
    );
  }

  LocationLocalModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    String? ward,
    String? city,
    String? pincode,
    String? source,
    double? accuracyMeters,
    int? timestampEpochMs,
  }) {
    return LocationLocalModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      ward: ward ?? this.ward,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      source: source ?? this.source,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestampEpochMs: timestampEpochMs ?? this.timestampEpochMs,
    );
  }
}
