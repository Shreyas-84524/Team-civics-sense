import '../../models/notification_model.dart';

/// Local persistence model for citizen notifications stored in Hive.
class NotificationLocalModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? complaintId;
  final bool isRead;
  final int createdAtEpochMs;

  const NotificationLocalModel({
    required this.id,
    this.userId = 'user_citizen_001',
    required this.title,
    required this.message,
    required this.type,
    this.complaintId,
    this.isRead = false,
    required this.createdAtEpochMs,
  });

  /// Map from Domain Model [NotificationModel] -> [NotificationLocalModel]
  factory NotificationLocalModel.fromDomain(NotificationModel notification) {
    return NotificationLocalModel(
      id: notification.id,
      userId: notification.userId,
      title: notification.title,
      message: notification.message,
      type: notification.type.name,
      complaintId: notification.complaintId,
      isRead: notification.isRead,
      createdAtEpochMs: notification.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Map from [NotificationLocalModel] -> Domain Model [NotificationModel]
  NotificationModel toDomain() {
    NotificationType parsedType;
    try {
      parsedType = NotificationType.values.firstWhere(
        (t) => t.name.toLowerCase() == type.toLowerCase(),
        orElse: () => NotificationType.generalCivic,
      );
    } catch (_) {
      parsedType = NotificationType.generalCivic;
    }

    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: parsedType,
      complaintId: complaintId,
      isRead: isRead,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtEpochMs),
    );
  }

  NotificationLocalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? complaintId,
    bool? isRead,
    int? createdAtEpochMs,
  }) {
    return NotificationLocalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      complaintId: complaintId ?? this.complaintId,
      isRead: isRead ?? this.isRead,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
    );
  }
}
