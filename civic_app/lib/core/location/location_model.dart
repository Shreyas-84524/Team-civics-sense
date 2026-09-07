/// Source through which a location was obtained.
enum LocationSource {
  gps,
  manual,
}

extension LocationSourceExt on LocationSource {
  String get label {
    switch (this) {
      case LocationSource.gps:
        return 'GPS Detected';
      case LocationSource.manual:
        return 'Manually Selected';
    }
  }

  String get iconName {
    switch (this) {
      case LocationSource.gps:
        return 'gps_fixed';
      case LocationSource.manual:
        return 'pin_drop';
    }
  }
}

/// Generic permission status enum used for Location and Camera/Gallery permissions.
enum CivicPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

extension CivicPermissionStatusExt on CivicPermissionStatus {
  bool get isGranted => this == CivicPermissionStatus.granted;
  bool get isDenied => this == CivicPermissionStatus.denied || this == CivicPermissionStatus.permanentlyDenied;
}

/// Civic Location model for geocoded civic issue points.
class CivicLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? ward;
  final String? city;
  final String? pincode;
  final LocationSource source;
  final double? accuracyMeters;
  final DateTime? timestamp;

  const CivicLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.ward,
    this.city,
    this.pincode,
    this.source = LocationSource.manual,
    this.accuracyMeters,
    this.timestamp,
  });

  bool get isGps => source == LocationSource.gps;

  String get sourceLabel => source.label;

  String get shortDisplayAddress {
    if (landmark != null && landmark!.isNotEmpty) {
      return '$landmark, $address';
    }
    return address;
  }

  String get fullDisplayAddress {
    final buffer = StringBuffer(address);
    if (landmark != null && landmark!.isNotEmpty) {
      buffer.write(' (Near $landmark)');
    }
    if (ward != null && ward!.isNotEmpty) {
      buffer.write(', $ward');
    }
    if (city != null && city!.isNotEmpty) {
      buffer.write(', $city');
    }
    if (pincode != null && pincode!.isNotEmpty) {
      buffer.write(' - $pincode');
    }
    return buffer.toString();
  }

  CivicLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    String? ward,
    String? city,
    String? pincode,
    LocationSource? source,
    double? accuracyMeters,
    DateTime? timestamp,
  }) {
    return CivicLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      ward: ward ?? this.ward,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      source: source ?? this.source,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
