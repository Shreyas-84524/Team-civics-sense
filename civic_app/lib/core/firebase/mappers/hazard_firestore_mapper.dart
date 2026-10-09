import 'package:cloud_firestore/cloud_firestore.dart';
import '../../map/spatial_chunk.dart';
import '../../models/hazard_model.dart';
import 'firestore_mapper_helpers.dart';

/// Bidirectional mapper for [HazardModel] to/from Cloud Firestore documents.
class HazardFirestoreMapper {
  HazardFirestoreMapper._();

  /// Converts a [HazardModel] into a Firestore map (strictly omitting PII).
  static Map<String, dynamic> toFirestore(HazardModel hazard, {bool isCreate = false}) {
    final Map<String, dynamic> map = {
      'complaintId': hazard.complaintId,
      'ticketNumber': hazard.ticketNumber,
      'title': hazard.title,
      'category': FirestoreMapperHelpers.categoryToMap(hazard.category),
      'status': hazard.status.name,
      'latitude': hazard.latitude,
      'longitude': hazard.longitude,
      'address': hazard.address,
      'landmark': hazard.landmark,
      'ward': hazard.ward,
      'severity': hazard.severity.name,
      'imageUrl': hazard.imageUrl,
      'upvotes': hazard.upvotes,
      'spatialChunkId': hazard.spatialChunkId ??
          (hazard.latitude != 0.0 || hazard.longitude != 0.0
              ? GeohashUtils.encode(hazard.latitude, hazard.longitude, precision: 5)
              : null),
      'geohash': hazard.geohash ??
          (hazard.latitude != 0.0 || hazard.longitude != 0.0
              ? GeohashUtils.encode(hazard.latitude, hazard.longitude, precision: 7)
              : null),
    };

    if (isCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
    } else {
      map['updatedAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Converts a Firestore document map into a [HazardModel].
  static HazardModel fromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    return HazardModel(
      id: documentId,
      complaintId: data['complaintId'] as String?,
      ticketNumber: data['ticketNumber'] as String?,
      title: data['title'] as String? ?? '',
      category: FirestoreMapperHelpers.categoryFromMap(data['category']),
      status: FirestoreMapperHelpers.parseComplaintStatus(data['status'] as String?),
      latitude: lat,
      longitude: lng,
      address: data['address'] as String? ?? '',
      landmark: data['landmark'] as String?,
      ward: data['ward'] as String?,
      severity: FirestoreMapperHelpers.parseHazardSeverity(data['severity'] as String?),
      imageUrl: data['imageUrl'] as String?,
      upvotes: data['upvotes'] as int? ?? 0,
      createdAt: FirestoreMapperHelpers.timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreMapperHelpers.timestampToDateTime(data['updatedAt']) ?? DateTime.now(),
      spatialChunkId: data['spatialChunkId'] as String? ??
          (lat != 0.0 || lng != 0.0 ? GeohashUtils.encode(lat, lng, precision: 5) : null),
      geohash: data['geohash'] as String? ??
          (lat != 0.0 || lng != 0.0 ? GeohashUtils.encode(lat, lng, precision: 7) : null),
    );
  }
}
