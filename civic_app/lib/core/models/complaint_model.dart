import 'package:flutter/material.dart';
import '../ai/models/ai_analysis_status.dart';
import '../ai/models/ai_authenticity_result.dart';
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

/// Local synchronization status for offline persistence & synchronization queue.
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;
}

extension SyncStatusExt on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending Sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Sync Failed';
    }
  }

  Color get color {
    switch (this) {
      case SyncStatus.pending:
        return CivicFixColors.alertDark;
      case SyncStatus.syncing:
        return CivicFixColors.info;
      case SyncStatus.synced:
        return CivicFixColors.secondary;
      case SyncStatus.failed:
        return CivicFixColors.error;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SyncStatus.pending:
        return CivicFixColors.statusInProgressBg;
      case SyncStatus.syncing:
        return CivicFixColors.statusUnderReviewBg;
      case SyncStatus.synced:
        return CivicFixColors.statusResolvedBg;
      case SyncStatus.failed:
        return CivicFixColors.statusRejectedBg;
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.pending:
        return Icons.cloud_off_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
      case SyncStatus.failed:
        return Icons.sync_problem_rounded;
    }
  }

  bool get isPending => this == SyncStatus.pending;
  bool get isSyncing => this == SyncStatus.syncing;
  bool get isSynced => this == SyncStatus.synced;
  bool get isFailed => this == SyncStatus.failed;
}

enum ComplaintRoutingStatus {
  unassigned,
  assigned,
  reassignmentRequested,
  transferred,
  inProgress,
  resolved;

  String get id {
    switch (this) {
      case ComplaintRoutingStatus.unassigned:
        return 'unassigned';
      case ComplaintRoutingStatus.assigned:
        return 'assigned';
      case ComplaintRoutingStatus.reassignmentRequested:
        return 'reassignment_requested';
      case ComplaintRoutingStatus.transferred:
        return 'transferred';
      case ComplaintRoutingStatus.inProgress:
        return 'in_progress';
      case ComplaintRoutingStatus.resolved:
        return 'resolved';
    }
  }

  static ComplaintRoutingStatus fromString(String? val) {
    if (val == null) return ComplaintRoutingStatus.assigned;
    switch (val.toLowerCase().trim()) {
      case 'unassigned':
        return ComplaintRoutingStatus.unassigned;
      case 'reassignment_requested':
      case 'reassignmentrequested':
        return ComplaintRoutingStatus.reassignmentRequested;
      case 'transferred':
        return ComplaintRoutingStatus.transferred;
      case 'in_progress':
      case 'inprogress':
        return ComplaintRoutingStatus.inProgress;
      case 'resolved':
        return ComplaintRoutingStatus.resolved;
      case 'assigned':
      default:
        return ComplaintRoutingStatus.assigned;
    }
  }
}

enum ComplaintAssignmentStatus {
  unassigned,
  leadAssigned,
  crewAssigned;

  String get id {
    switch (this) {
      case ComplaintAssignmentStatus.unassigned:
        return 'unassigned';
      case ComplaintAssignmentStatus.leadAssigned:
        return 'lead_assigned';
      case ComplaintAssignmentStatus.crewAssigned:
        return 'crew_assigned';
    }
  }

  static ComplaintAssignmentStatus fromString(String? val) {
    if (val == null) return ComplaintAssignmentStatus.unassigned;
    switch (val.toLowerCase().trim()) {
      case 'lead_assigned':
      case 'leadassigned':
        return ComplaintAssignmentStatus.leadAssigned;
      case 'crew_assigned':
      case 'crewassigned':
        return ComplaintAssignmentStatus.crewAssigned;
      case 'unassigned':
      default:
        return ComplaintAssignmentStatus.unassigned;
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
  final SyncStatus syncStatus;
  final String? localId;
  final String? serverId;
  final AiAuthenticityResult? aiAuthenticity;
  final AiAnalysisStatus aiAnalysisStatus;

  // Phase 2 BMC Matrix Hierarchical Fields
  final String? wardId;
  final String? assignedDepartmentId;
  final String? assignedDepartmentLeadId;
  final String? assignedCrewMemberId;
  final ComplaintRoutingStatus routingStatus;
  final ComplaintAssignmentStatus assignmentStatus;
  final DateTime slaStartedAt;
  final DateTime originalCreatedAt;
  final DateTime? currentDepartmentAssignedAt;
  final DateTime? lastReassignedAt;
  final int reassignmentCount;

  String get effectiveDepartment =>
      departmentName ?? assignedDepartmentId ?? DepartmentHelper.getDepartmentName(category);

  bool get isOfflineDraft => syncStatus == SyncStatus.pending;
  bool get hasAiAuthenticity => aiAuthenticity != null;

  ComplaintModel({
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
    this.syncStatus = SyncStatus.synced,
    this.localId,
    this.serverId,
    this.aiAuthenticity,
    this.aiAnalysisStatus = AiAnalysisStatus.pending,
    this.wardId,
    this.assignedDepartmentId,
    this.assignedDepartmentLeadId,
    this.assignedCrewMemberId,
    ComplaintRoutingStatus? routingStatus,
    ComplaintAssignmentStatus? assignmentStatus,
    DateTime? slaStartedAt,
    DateTime? originalCreatedAt,
    this.currentDepartmentAssignedAt,
    this.lastReassignedAt,
    this.reassignmentCount = 0,
  })  : routingStatus = routingStatus ??
            (assignedTo != null || assignedDepartmentLeadId != null
                ? ComplaintRoutingStatus.assigned
                : ComplaintRoutingStatus.unassigned),
        assignmentStatus = assignmentStatus ??
            (assignedCrewMemberId != null
                ? ComplaintAssignmentStatus.crewAssigned
                : (assignedDepartmentLeadId != null || assignedTo != null
                    ? ComplaintAssignmentStatus.leadAssigned
                    : ComplaintAssignmentStatus.unassigned)),
        slaStartedAt = slaStartedAt ?? createdAt,
        originalCreatedAt = originalCreatedAt ?? createdAt;

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
    SyncStatus? syncStatus,
    String? localId,
    String? serverId,
    AiAuthenticityResult? aiAuthenticity,
    AiAnalysisStatus? aiAnalysisStatus,
    String? wardId,
    String? assignedDepartmentId,
    String? assignedDepartmentLeadId,
    String? assignedCrewMemberId,
    bool clearAssignedCrew = false,
    ComplaintRoutingStatus? routingStatus,
    ComplaintAssignmentStatus? assignmentStatus,
    DateTime? slaStartedAt,
    DateTime? originalCreatedAt,
    DateTime? currentDepartmentAssignedAt,
    DateTime? lastReassignedAt,
    int? reassignmentCount,
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
      syncStatus: syncStatus ?? this.syncStatus,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      aiAuthenticity: aiAuthenticity ?? this.aiAuthenticity,
      aiAnalysisStatus: aiAnalysisStatus ?? this.aiAnalysisStatus,
      wardId: wardId ?? this.wardId,
      assignedDepartmentId: assignedDepartmentId ?? this.assignedDepartmentId,
      assignedDepartmentLeadId: assignedDepartmentLeadId ?? this.assignedDepartmentLeadId,
      assignedCrewMemberId:
          clearAssignedCrew ? null : (assignedCrewMemberId ?? this.assignedCrewMemberId),
      routingStatus: routingStatus ?? this.routingStatus,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      slaStartedAt: slaStartedAt ?? this.slaStartedAt,
      originalCreatedAt: originalCreatedAt ?? this.originalCreatedAt,
      currentDepartmentAssignedAt:
          currentDepartmentAssignedAt ?? this.currentDepartmentAssignedAt,
      lastReassignedAt: lastReassignedAt ?? this.lastReassignedAt,
      reassignmentCount: reassignmentCount ?? this.reassignmentCount,
    );
  }
}

