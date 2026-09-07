import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../location/location_model.dart';
import '../utils/department_helper.dart';
import 'category_model.dart';

enum ComplaintStatus {
  reported,
  verified,
  assigned,
  inProgress,
  resolved,
  rejected;

  // Backwards compatibility aliases
  static const ComplaintStatus submitted = ComplaintStatus.reported;
  static const ComplaintStatus underReview = ComplaintStatus.verified;
}

extension ComplaintStatusExt on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.reported:
        return 'Reported';
      case ComplaintStatus.verified:
        return 'Verified';
      case ComplaintStatus.assigned:
        return 'Assigned';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.reported:
        return CivicFixColors.primary;
      case ComplaintStatus.verified:
        return CivicFixColors.secondary;
      case ComplaintStatus.assigned:
        return CivicFixColors.info;
      case ComplaintStatus.inProgress:
        return CivicFixColors.alertDark;
      case ComplaintStatus.resolved:
        return CivicFixColors.secondary;
      case ComplaintStatus.rejected:
        return CivicFixColors.error;
    }
  }

  Color get badgeColor => color;

  Color get backgroundColor {
    switch (this) {
      case ComplaintStatus.reported:
        return CivicFixColors.statusSubmittedBg;
      case ComplaintStatus.verified:
        return CivicFixColors.statusUnderReviewBg;
      case ComplaintStatus.assigned:
        return CivicFixColors.statusUnderReviewBg;
      case ComplaintStatus.inProgress:
        return CivicFixColors.statusInProgressBg;
      case ComplaintStatus.resolved:
        return CivicFixColors.statusResolvedBg;
      case ComplaintStatus.rejected:
        return CivicFixColors.statusRejectedBg;
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.reported:
        return Icons.assignment_outlined;
      case ComplaintStatus.verified:
        return Icons.verified_outlined;
      case ComplaintStatus.assigned:
        return Icons.person_pin_circle_outlined;
      case ComplaintStatus.inProgress:
        return Icons.engineering_rounded;
      case ComplaintStatus.resolved:
        return Icons.check_circle_rounded;
      case ComplaintStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}

enum ComplaintPriority {
  low,
  medium,
  high,
  emergency,
}

extension ComplaintPriorityExt on ComplaintPriority {
  String get label {
    switch (this) {
      case ComplaintPriority.low:
        return 'Low Priority';
      case ComplaintPriority.medium:
        return 'Medium Priority';
      case ComplaintPriority.high:
        return 'High Priority';
      case ComplaintPriority.emergency:
        return 'Emergency Hazard';
    }
  }

  Color get color {
    switch (this) {
      case ComplaintPriority.low:
        return CivicFixColors.secondaryText;
      case ComplaintPriority.medium:
        return CivicFixColors.info;
      case ComplaintPriority.high:
        return CivicFixColors.alert;
      case ComplaintPriority.emergency:
        return CivicFixColors.error;
    }
  }
}

class TimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final ComplaintStatus status;
  final String? updatedBy;

  const TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    this.updatedBy,
  });
}

class ComplaintModel {
  final String id;
  final String citizenId;
  final String ticketNumber;
  final String title;
  final String description;
  final CivicCategory category;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final CivicLocation location;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TimelineEvent> timeline;
  final int upvotes;
  final bool isHazard;
  final String? officerNotes;
  final String? assignedTo;
  final String? departmentName;
  final DateTime? resolvedAt;

  String get effectiveDepartment => departmentName ?? DepartmentHelper.getDepartmentName(category);

  const ComplaintModel({
    required this.id,
    this.citizenId = 'user_citizen_001',
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.location,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.timeline = const [],
    this.upvotes = 0,
    this.isHazard = false,
    this.officerNotes,
    this.assignedTo,
    this.departmentName,
    this.resolvedAt,
  });

  ComplaintModel copyWith({
    String? id,
    String? citizenId,
    String? ticketNumber,
    String? title,
    String? description,
    CivicCategory? category,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    CivicLocation? location,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TimelineEvent>? timeline,
    int? upvotes,
    bool? isHazard,
    String? officerNotes,
    String? assignedTo,
    String? departmentName,
    DateTime? resolvedAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeline: timeline ?? this.timeline,
      upvotes: upvotes ?? this.upvotes,
      isHazard: isHazard ?? this.isHazard,
      officerNotes: officerNotes ?? this.officerNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      departmentName: departmentName ?? this.departmentName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
