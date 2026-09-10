import 'package:cloud_firestore/cloud_firestore.dart';
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
    return HazardModel(
      id: documentId,
      complaintId: data['complaintId'] as String?,
      ticketNumber: data['ticketNumber'] as String?,
      title: data['title'] as String? ?? '',
      category: FirestoreMapperHelpers.categoryFromMap(data['category']),
      status: FirestoreMapperHelpers.parseComplaintStatus(data['status'] as String?),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      address: data['address'] as String? ?? '',
      landmark: data['landmark'] as String?,
      ward: data['ward'] as String?,
      severity: FirestoreMapperHelpers.parseHazardSeverity(data['severity'] as String?),
      imageUrl: data['imageUrl'] as String?,
      upvotes: data['upvotes'] as int? ?? 0,
      createdAt: FirestoreMapperHelpers.timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreMapperHelpers.timestampToDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }
}
