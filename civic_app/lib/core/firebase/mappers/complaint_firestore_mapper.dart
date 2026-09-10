import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/complaint_model.dart';
import 'firestore_mapper_helpers.dart';

/// Bidirectional mapper for [ComplaintModel] and [TimelineEvent] to/from Cloud Firestore documents.
class ComplaintFirestoreMapper {
  ComplaintFirestoreMapper._();

  /// Converts a [ComplaintModel] into a Firestore document map.
  static Map<String, dynamic> toFirestore(ComplaintModel complaint, {bool isCreate = false}) {
    final Map<String, dynamic> map = {
      'citizenId': complaint.citizenId,
      'ticketNumber': complaint.ticketNumber,
      'title': complaint.title,
      'description': complaint.description,
      'category': FirestoreMapperHelpers.categoryToMap(complaint.category),
      'status': complaint.status.name,
      'priority': complaint.priority.name,
      'location': FirestoreMapperHelpers.locationToMap(complaint.location),
      'imageUrls': complaint.imageUrls,
      'upvotes': complaint.upvotes,
      'isHazard': complaint.isHazard,
      'officerNotes': complaint.officerNotes,
      'assignedTo': complaint.assignedTo,
      'departmentName': complaint.departmentName,
      'resolvedAt': FirestoreMapperHelpers.dateTimeToTimestamp(complaint.resolvedAt),
    };

    if (isCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
    } else {
      map['updatedAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Converts a Firestore document snapshot or data map into a [ComplaintModel].
  static ComplaintModel fromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
    List<TimelineEvent> timeline = const [],
  }) {
    return ComplaintModel(
      id: documentId,
      citizenId: data['citizenId'] as String? ?? '',
      ticketNumber: data['ticketNumber'] as String? ?? 'CF-2026-UNKNOWN',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: FirestoreMapperHelpers.categoryFromMap(data['category']),
      status: FirestoreMapperHelpers.parseComplaintStatus(data['status'] as String?),
      priority: FirestoreMapperHelpers.parseComplaintPriority(data['priority'] as String?),
      location: FirestoreMapperHelpers.locationFromMap(data['location']),
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? const []),
      createdAt: FirestoreMapperHelpers.timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreMapperHelpers.timestampToDateTime(data['updatedAt']) ?? DateTime.now(),
      timeline: timeline,
      upvotes: data['upvotes'] as int? ?? 0,
      isHazard: data['isHazard'] as bool? ?? false,
      officerNotes: data['officerNotes'] as String?,
      assignedTo: data['assignedTo'] as String?,
      departmentName: data['departmentName'] as String?,
      resolvedAt: FirestoreMapperHelpers.timestampToDateTime(data['resolvedAt']),
      syncStatus: SyncStatus.synced,
      serverId: documentId,
      localId: data['localId'] as String?,
    );
  }

  /// Converts a [TimelineEvent] into a Firestore update subcollection document map.
  static Map<String, dynamic> timelineEventToFirestore(TimelineEvent event) {
    return {
      'title': event.title,
      'description': event.description,
      'status': event.status.name,
      'timestamp': FirestoreMapperHelpers.dateTimeToTimestamp(event.timestamp) ?? FieldValue.serverTimestamp(),
      'updatedBy': event.updatedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts a Firestore update subcollection document map into a [TimelineEvent].
  static TimelineEvent timelineEventFromFirestore(Map<String, dynamic> data) {
    return TimelineEvent(
      title: data['title'] as String? ?? 'Status Update',
      description: data['description'] as String? ?? '',
      timestamp: FirestoreMapperHelpers.timestampToDateTime(data['timestamp']) ?? DateTime.now(),
      status: FirestoreMapperHelpers.parseComplaintStatus(data['status'] as String?),
      updatedBy: data['updatedBy'] as String?,
    );
  }
}
