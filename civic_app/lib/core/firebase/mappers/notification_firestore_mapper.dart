import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import 'firestore_mapper_helpers.dart';

/// Bidirectional mapper for [NotificationModel] to/from Cloud Firestore documents.
class NotificationFirestoreMapper {
  NotificationFirestoreMapper._();

  /// Converts a [NotificationModel] into a Firestore map.
  static Map<String, dynamic> toFirestore(NotificationModel notification) {
    return {
      'userId': notification.userId,
      'title': notification.title,
      'message': notification.message,
      'type': notification.type.name,
      'complaintId': notification.complaintId,
      'isRead': notification.isRead,
      'createdAt': FirestoreMapperHelpers.dateTimeToTimestamp(notification.createdAt) ?? FieldValue.serverTimestamp(),
    };
  }

  /// Converts a Firestore document map into a [NotificationModel].
  static NotificationModel fromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return NotificationModel(
      id: documentId,
      userId: data['userId'] as String? ?? 'user_citizen_001',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: FirestoreMapperHelpers.parseNotificationType(data['type'] as String?),
      complaintId: data['complaintId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: FirestoreMapperHelpers.timestampToDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }
}
