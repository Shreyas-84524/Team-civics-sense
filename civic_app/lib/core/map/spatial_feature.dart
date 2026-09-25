import 'package:flutter/foundation.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';

/// Type of civic spatial entity represented on the map.
enum SpatialFeatureType {
  complaint,
  hazard,
}

/// Lightweight, map-ready spatial feature contract representing a geotagged
/// complaint or hazard ready for GeoJSON serialization and MapLibre rendering.
class SpatialFeature {
  final String id;
  final SpatialFeatureType type;
  final double latitude;
  final double longitude;
  final String title;
  final ComplaintStatus status;
  final String severity;
  final String category;
  final String categoryId;
  final String? department;
  final String address;
  final String? landmark;
  final String? ward;
  final String? city;
  final String? pincode;
  final bool isHazard;
  final int upvotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> customProperties;

  const SpatialFeature({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.status,
    required this.severity,
    required this.category,
    required this.categoryId,
    this.department,
    required this.address,
    this.landmark,
    this.ward,
    this.city,
    this.pincode,
    this.isHazard = false,
    this.upvotes = 0,
    required this.createdAt,
    this.updatedAt,
    this.customProperties = const {},
  });

  /// Validates whether [latitude] and [longitude] fall within standard WGS84 geographic limits.
  static bool isValidCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN || latitude.isInfinite || longitude.isInfinite) return false;
    return latitude >= -90.0 && latitude <= 90.0 && longitude >= -180.0 && longitude <= 180.0;
  }

  /// Converts a [ComplaintModel] into a map-ready [SpatialFeature].
  ///
  /// Returns `null` if the complaint location coordinates are invalid or out of bounds.
  static SpatialFeature? fromComplaint(ComplaintModel complaint) {
    final lat = complaint.location.latitude;
    final lng = complaint.location.longitude;

    if (!isValidCoordinates(lat, lng)) {
      debugPrint('[SpatialFeature] Skipped complaint ${complaint.id} with invalid coordinates ($lat, $lng)');
      return null;
    }

    return SpatialFeature(
      id: complaint.id,
      type: SpatialFeatureType.complaint,
      latitude: lat,
      longitude: lng,
      title: complaint.title,
      status: complaint.status,
      severity: complaint.priority.name,
      category: complaint.category.name,
      categoryId: complaint.category.id,
      department: complaint.effectiveDepartment,
      address: complaint.location.address,
      landmark: complaint.location.landmark,
      ward: complaint.location.ward,
      city: complaint.location.city,
      pincode: complaint.location.pincode,
      isHazard: complaint.isHazard,
      upvotes: complaint.upvotes,
      createdAt: complaint.createdAt,
      updatedAt: complaint.updatedAt,
    );
  }

  /// Converts a [HazardModel] into a map-ready [SpatialFeature].
  ///
  /// Returns `null` if the hazard coordinates are invalid or out of bounds.
  static SpatialFeature? fromHazard(HazardModel hazard) {
    final lat = hazard.latitude;
    final lng = hazard.longitude;

    if (!isValidCoordinates(lat, lng)) {
      debugPrint('[SpatialFeature] Skipped hazard ${hazard.id} with invalid coordinates ($lat, $lng)');
      return null;
    }

    return SpatialFeature(
      id: hazard.id,
      type: SpatialFeatureType.hazard,
      latitude: lat,
      longitude: lng,
      title: hazard.title,
      status: hazard.status,
      severity: hazard.severity.name,
      category: hazard.category.name,
      categoryId: hazard.category.id,
      address: hazard.address,
      landmark: hazard.landmark,
      ward: hazard.ward,
      isHazard: true,
      upvotes: hazard.upvotes,
      createdAt: hazard.createdAt,
      updatedAt: hazard.updatedAt,
    );
  }

  /// Serializes this spatial feature into a standard GeoJSON Point Feature.
  ///
  /// Note: In GeoJSON standard (RFC 7946), coordinates MUST be ordered as [longitude, latitude].
  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'id': id,
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude], // [lng, lat]
      },
      'properties': {
        'id': id,
        'type': type.name,
        'title': title,
        'status': status.name,
        'statusLabel': status.label,
        'severity': severity,
        'category': category,
        'categoryId': categoryId,
        if (department != null) 'department': department,
        'address': address,
        if (landmark != null) 'landmark': landmark,
        if (ward != null) 'ward': ward,
        if (city != null) 'city': city,
        if (pincode != null) 'pincode': pincode,
        'isHazard': isHazard,
        'upvotes': upvotes,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        ...customProperties,
      },
    };
  }

  /// Serializes a list of [SpatialFeature] items into a standard GeoJSON FeatureCollection.
  static Map<String, dynamic> toFeatureCollection(List<SpatialFeature> features) {
    return {
      'type': 'FeatureCollection',
      'features': features.map((f) => f.toGeoJsonFeature()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialFeature &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(id, type, latitude, longitude);
}
