import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Categories of civic notifications delivered to citizens
enum NotificationType {
  complaintSubmitted,
  complaintVerified,
  complaintAssigned,
  complaintStatusChanged,
  complaintResolved,
  generalCivic,
  // Backward compatibility types
  statusUpdate,
  hazardAlert,
  rewardEarned,
  civicBroadcast,
}

extension NotificationTypeExt on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.complaintSubmitted:
        return Icons.add_task_rounded;
      case NotificationType.complaintVerified:
        return Icons.verified_outlined;
      case NotificationType.complaintAssigned:
        return Icons.engineering_rounded;
      case NotificationType.complaintStatusChanged:
      case NotificationType.statusUpdate:
        return Icons.sync_alt_rounded;
      case NotificationType.complaintResolved:
        return Icons.check_circle_outline_rounded;
      case NotificationType.generalCivic:
      case NotificationType.civicBroadcast:
        return Icons.campaign_rounded;
      case NotificationType.hazardAlert:
        return Icons.warning_amber_rounded;
      case NotificationType.rewardEarned:
        return Icons.military_tech_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.complaintSubmitted:
        return CivicFixColors.primary;
      case NotificationType.complaintVerified:
        return CivicFixColors.info;
      case NotificationType.complaintAssigned:
        return const Color(0xFFE65100);
      case NotificationType.complaintStatusChanged:
      case NotificationType.statusUpdate:
        return CivicFixColors.info;
      case NotificationType.complaintResolved:
        return CivicFixColors.secondary;
      case NotificationType.generalCivic:
      case NotificationType.civicBroadcast:
        return CivicFixColors.primary;
      case NotificationType.hazardAlert:
        return CivicFixColors.alertDark;
      case NotificationType.rewardEarned:
        return CivicFixColors.secondary;
    }
  }

  String get label {
    switch (this) {
      case NotificationType.complaintSubmitted:
        return 'Submitted';
      case NotificationType.complaintVerified:
        return 'Verified';
      case NotificationType.complaintAssigned:
        return 'Assigned';
      case NotificationType.complaintStatusChanged:
      case NotificationType.statusUpdate:
        return 'Status Update';
      case NotificationType.complaintResolved:
        return 'Resolved';
      case NotificationType.generalCivic:
      case NotificationType.civicBroadcast:
        return 'Civic Info';
      case NotificationType.hazardAlert:
        return 'Hazard Alert';
      case NotificationType.rewardEarned:
        return 'Reward';
    }
  }
}

/// Citizen notification model for complaint lifecycle events and civic notices.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? complaintId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId = 'user_citizen_001',
    required this.title,
    required this.message,
    required this.type,
    String? complaintId,
    this.isRead = false,
    DateTime? createdAt,
    DateTime? timestamp,
    String? relatedComplaintId,
  })  : createdAt = createdAt ?? timestamp ?? DateTime.now(),
        complaintId = complaintId ?? relatedComplaintId;

  /// Backward compatibility getters
  DateTime get timestamp => createdAt;
  String? get relatedComplaintId => complaintId;

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? complaintId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? timestamp,
    String? relatedComplaintId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      complaintId: complaintId ?? relatedComplaintId ?? this.complaintId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? timestamp ?? this.createdAt,
    );
  }
}
