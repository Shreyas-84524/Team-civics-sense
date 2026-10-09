import 'package:flutter/material.dart';
import '../ai/models/ai_analysis_status.dart';
import '../ai/models/ai_authenticity_enums.dart';
import '../ai/models/ai_authenticity_result.dart';
import '../constants/app_colors.dart';
import '../location/location_model.dart';
import '../map/spatial_chunk.dart';
import '../utils/department_helper.dart';
import 'category_model.dart';

enum ComplaintStatus {
  underVerification,
  reported,
  verified,
  assigned,
  inProgress,
  resolved,
  closed,
  rejected;

  // Backwards compatibility aliases
  static const ComplaintStatus submitted = ComplaintStatus.reported;
  static const ComplaintStatus underReview = ComplaintStatus.verified;
}

extension ComplaintStatusExt on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.underVerification:
        return 'Under Verification';
      case ComplaintStatus.reported:
        return 'Reported';
      case ComplaintStatus.verified:
        return 'Verified';
      case ComplaintStatus.assigned:
        return 'Assigned';
      case ComplaintStatus.inProgress:
        return 'Work In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.underVerification:
        return CivicFixColors.primaryAccent;
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
      case ComplaintStatus.closed:
        return CivicFixColors.secondaryText;
      case ComplaintStatus.rejected:
        return CivicFixColors.error;
    }
  }

  Color get badgeColor => color;

  Color get backgroundColor {
    switch (this) {
      case ComplaintStatus.underVerification:
        return CivicFixColors.warningContainer;
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
      case ComplaintStatus.closed:
        return CivicFixColors.infoContainer;
      case ComplaintStatus.rejected:
        return CivicFixColors.statusRejectedBg;
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.underVerification:
        return Icons.hourglass_top_rounded;
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
      case ComplaintStatus.closed:
        return Icons.lock_outline_rounded;
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
  crewAssigned,
  fieldOfficerAssigned;

  String get id {
    switch (this) {
      case ComplaintAssignmentStatus.unassigned:
        return 'unassigned';
      case ComplaintAssignmentStatus.leadAssigned:
        return 'lead_assigned';
      case ComplaintAssignmentStatus.crewAssigned:
        return 'crew_assigned';
      case ComplaintAssignmentStatus.fieldOfficerAssigned:
        return 'field_officer_assigned';
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
      case 'field_officer_assigned':
      case 'fieldofficerassigned':
        return ComplaintAssignmentStatus.fieldOfficerAssigned;
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

  // Phase 3 Canonical AI Verification & Fallback Resilience Fields
  final String evidenceVerificationStatus; // 'pending' | 'processing' | 'passed' | 'failed' | 'temporarily_unavailable'
  final String departmentVerificationStatus; // 'pending' | 'processing' | 'passed' | 'failed' | 'temporarily_unavailable'
  final String verificationStage; // 'evidence' | 'department' | 'humanDepartmentReview' | 'verification_completed' | 'evidence_failed' | 'department_failed'
  final String? verifiedDepartmentId;
  final String? verifiedDepartmentName;
  final DateTime? evidenceVerificationStartedAt;
  final DateTime? evidenceVerificationCompletedAt;
  final DateTime? departmentVerificationStartedAt;
  final DateTime? departmentVerificationCompletedAt;
  final DateTime? verificationCompletedAt;
  final String? verificationFailureReason;
  final String? citizenSafeVerificationMessage;
  final int aiVerificationAttempts;
  final DateTime? lastAiVerificationAttemptAt;
  final String? lastAiFailureCode;
  final DateTime? aiFallbackTriggeredAt;
  final String? initialReviewDepartmentId;
  final String? initialReviewDepartmentName;
  final String? humanReviewStatus; // 'pending' | 'approved' | 'transferred' | 'none'
  final String? humanReviewerId;
  final String? humanReviewerName;
  final String? humanReviewRemarks;
  final DateTime? humanReviewedAt;
  final String? previousDepartmentId;

  // Phase 3 Closure Lifecycle Fields
  final DateTime? closedAt;
  final String? closedBy;
  final String? closureRemarks;

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

  // Phase 2 Field Officer & Ground Execution Fields
  final String? assignedJuniorEngineerNameSnapshot;
  final String? assignedJuniorEngineerDesignationSnapshot;
  final String? assignedFieldOfficerId;
  final DateTime? assignedFieldOfficerAt;
  final String? assignedFieldOfficerNameSnapshot;
  final String? assignedFieldOfficerDesignationSnapshot;
  final DateTime? workStartedAt;
  final String? workStartedBy;
  final String? beforeWorkPhoto;
  final String? beforeWorkNotes;
  final String? afterWorkPhoto;
  final String? resolutionRemarks;
  final String? resolvedBy;
  final DateTime? blockedAt;
  final String? blockedBy;
  final String? blockedReason;
  final DateTime? reopenedAt;
  final String? reopenedBy;
  final String? reopenReason;
  final DateTime? previousResolvedAt;
  final List<String> previousResolutionEvidence;
  final int reopenCount;
  final String? spatialChunkId;
  final String? geohash;

  String get computedSpatialChunkId =>
      spatialChunkId ??
      (location.latitude != 0.0 || location.longitude != 0.0
          ? GeohashUtils.encode(location.latitude, location.longitude, precision: 5)
          : 'te7u8');

  String get citizenPhaseLabel {
    if (status == ComplaintStatus.inProgress && reopenCount > 0) {
      return 'Rework / Work In Progress';
    }
    return status.label;
  }

  String get effectiveDepartment =>
      verifiedDepartmentName ?? departmentName ?? assignedDepartmentId ?? DepartmentHelper.getDepartmentName(category);

  bool get isOfflineDraft => syncStatus == SyncStatus.pending;
  bool get hasAiAuthenticity => aiAuthenticity != null;

  // Phase 3 Canonical Verification Getters
  bool get isUnderVerification => status == ComplaintStatus.underVerification;
  bool get isClosed => status == ComplaintStatus.closed;
  bool get isEvidenceVerified => evidenceVerificationStatus == 'passed';
  bool get isDepartmentVerified => departmentVerificationStatus == 'passed';
  bool get isAiVerificationComplete => isEvidenceVerified && isDepartmentVerified;
  bool get isHumanReviewPending =>
      verificationStage == 'humanDepartmentReview' || humanReviewStatus == 'pending';
  bool get isHumanReviewCompleted =>
      humanReviewStatus == 'approved' || humanReviewStatus == 'transferred';

  // Evidence Authenticity & Rejection Getters
  bool get isAiGeneratedEvidenceRejected {
    if (aiAuthenticity?.status == AiAuthenticityStatus.likelyAiGenerated) {
      return true;
    }
    final code = lastAiFailureCode?.toLowerCase();
    if (code == 'ai_generated' ||
        code == 'synthetic_image' ||
        code == 'manipulated_evidence' ||
        code == 'fake_evidence') {
      return true;
    }
    final failureReason = verificationFailureReason?.toLowerCase() ?? '';
    if (failureReason.contains('ai-generated') ||
        failureReason.contains('synthetic') ||
        failureReason.contains('digitally manipulated') ||
        failureReason.contains('manipulated image')) {
      return true;
    }
    return false;
  }

  bool get isEvidenceRejected =>
      status == ComplaintStatus.rejected ||
      verificationStage == 'evidence_failed' ||
      verificationStage == 'rejected' ||
      evidenceVerificationStatus == 'failed';


  // Junior Engineer Semantic Aliases & Snapshots (Phase 1/3)
  String? get assignedJuniorEngineerId => assignedCrewMemberId;
  DateTime? get assignedJuniorEngineerAt => currentDepartmentAssignedAt ?? updatedAt;
  bool get isJuniorEngineerAssigned =>
      assignedCrewMemberId != null && assignedCrewMemberId!.isNotEmpty;
  String? get assignedJuniorEngineerName =>
      assignedJuniorEngineerNameSnapshot ??
      (assignedCrewMemberId != null
          ? (assignedTo ?? 'Junior Engineer ($effectiveDepartment)')
          : assignedTo);
  String? get assignedJuniorEngineerDesignation =>
      assignedJuniorEngineerDesignationSnapshot ??
      (assignedCrewMemberId != null
          ? 'Junior Engineer — $effectiveDepartment'
          : null);

  // Field Officer Semantic Aliases & Execution Getters (Phase 2/3)
  DateTime? get fieldExecutionStartedAt => workStartedAt;
  String? get resolvedByFieldOfficerId => resolvedBy;
  bool get isFieldOfficerAssigned =>
      assignedFieldOfficerId != null && assignedFieldOfficerId!.trim().isNotEmpty;
  String? get assignedFieldOfficerName =>
      assignedFieldOfficerNameSnapshot ??
      (isFieldOfficerAssigned ? 'Execution Officer ($effectiveDepartment)' : null);
  String? get assignedFieldOfficerDesignation =>
      assignedFieldOfficerDesignationSnapshot ??
      (isFieldOfficerAssigned ? 'Execution Officer — $effectiveDepartment' : null);
  bool get isBlocked => blockedAt != null && status == ComplaintStatus.inProgress;
  bool get isReopened => reopenedAt != null && status != ComplaintStatus.resolved;

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
    this.evidenceVerificationStatus = 'pending',
    this.departmentVerificationStatus = 'pending',
    this.verificationStage = 'evidence',
    this.verifiedDepartmentId,
    this.verifiedDepartmentName,
    this.evidenceVerificationStartedAt,
    this.evidenceVerificationCompletedAt,
    this.departmentVerificationStartedAt,
    this.departmentVerificationCompletedAt,
    this.verificationCompletedAt,
    this.verificationFailureReason,
    this.citizenSafeVerificationMessage,
    this.aiVerificationAttempts = 0,
    this.lastAiVerificationAttemptAt,
    this.lastAiFailureCode,
    this.aiFallbackTriggeredAt,
    this.initialReviewDepartmentId,
    this.initialReviewDepartmentName,
    this.humanReviewStatus,
    this.humanReviewerId,
    this.humanReviewerName,
    this.humanReviewRemarks,
    this.humanReviewedAt,
    this.previousDepartmentId,
    this.closedAt,
    this.closedBy,
    this.closureRemarks,
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
    this.assignedJuniorEngineerNameSnapshot,
    this.assignedJuniorEngineerDesignationSnapshot,
    this.assignedFieldOfficerId,
    this.assignedFieldOfficerAt,
    this.assignedFieldOfficerNameSnapshot,
    this.assignedFieldOfficerDesignationSnapshot,
    this.workStartedAt,
    this.workStartedBy,
    this.beforeWorkPhoto,
    this.beforeWorkNotes,
    this.afterWorkPhoto,
    this.resolutionRemarks,
    this.resolvedBy,
    this.blockedAt,
    this.blockedBy,
    this.blockedReason,
    this.reopenedAt,
    this.reopenedBy,
    this.reopenReason,
    this.previousResolvedAt,
    this.previousResolutionEvidence = const [],
    this.reopenCount = 0,
    this.spatialChunkId,
    this.geohash,
  })  : routingStatus = routingStatus ??
            (assignedTo != null || assignedDepartmentLeadId != null
                ? ComplaintRoutingStatus.assigned
                : ComplaintRoutingStatus.unassigned),
        assignmentStatus = assignmentStatus ??
            (assignedFieldOfficerId != null
                ? ComplaintAssignmentStatus.fieldOfficerAssigned
                : (assignedCrewMemberId != null
                    ? ComplaintAssignmentStatus.crewAssigned
                    : (assignedDepartmentLeadId != null || assignedTo != null
                        ? ComplaintAssignmentStatus.leadAssigned
                        : ComplaintAssignmentStatus.unassigned))),
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
    String? evidenceVerificationStatus,
    String? departmentVerificationStatus,
    String? verificationStage,
    String? verifiedDepartmentId,
    String? verifiedDepartmentName,
    DateTime? evidenceVerificationStartedAt,
    DateTime? evidenceVerificationCompletedAt,
    DateTime? departmentVerificationStartedAt,
    DateTime? departmentVerificationCompletedAt,
    DateTime? verificationCompletedAt,
    String? verificationFailureReason,
    String? citizenSafeVerificationMessage,
    int? aiVerificationAttempts,
    DateTime? lastAiVerificationAttemptAt,
    String? lastAiFailureCode,
    DateTime? aiFallbackTriggeredAt,
    String? initialReviewDepartmentId,
    String? initialReviewDepartmentName,
    String? humanReviewStatus,
    String? humanReviewerId,
    String? humanReviewerName,
    String? humanReviewRemarks,
    DateTime? humanReviewedAt,
    String? previousDepartmentId,
    DateTime? closedAt,
    String? closedBy,
    String? closureRemarks,
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
    String? assignedJuniorEngineerNameSnapshot,
    String? assignedJuniorEngineerDesignationSnapshot,
    String? assignedFieldOfficerId,
    bool clearAssignedFieldOfficer = false,
    DateTime? assignedFieldOfficerAt,
    String? assignedFieldOfficerNameSnapshot,
    String? assignedFieldOfficerDesignationSnapshot,
    DateTime? workStartedAt,
    String? workStartedBy,
    String? beforeWorkPhoto,
    String? beforeWorkNotes,
    String? afterWorkPhoto,
    String? resolutionRemarks,
    String? resolvedBy,
    DateTime? blockedAt,
    bool clearBlocked = false,
    String? blockedBy,
    String? blockedReason,
    DateTime? reopenedAt,
    String? reopenedBy,
    String? reopenReason,
    DateTime? previousResolvedAt,
    List<String>? previousResolutionEvidence,
    int? reopenCount,
    String? spatialChunkId,
    String? geohash,
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
      evidenceVerificationStatus:
          evidenceVerificationStatus ?? this.evidenceVerificationStatus,
      departmentVerificationStatus:
          departmentVerificationStatus ?? this.departmentVerificationStatus,
      verificationStage: verificationStage ?? this.verificationStage,
      verifiedDepartmentId: verifiedDepartmentId ?? this.verifiedDepartmentId,
      verifiedDepartmentName:
          verifiedDepartmentName ?? this.verifiedDepartmentName,
      evidenceVerificationStartedAt:
          evidenceVerificationStartedAt ?? this.evidenceVerificationStartedAt,
      evidenceVerificationCompletedAt: evidenceVerificationCompletedAt ??
          this.evidenceVerificationCompletedAt,
      departmentVerificationStartedAt: departmentVerificationStartedAt ??
          this.departmentVerificationStartedAt,
      departmentVerificationCompletedAt: departmentVerificationCompletedAt ??
          this.departmentVerificationCompletedAt,
      verificationCompletedAt:
          verificationCompletedAt ?? this.verificationCompletedAt,
      verificationFailureReason:
          verificationFailureReason ?? this.verificationFailureReason,
      citizenSafeVerificationMessage:
          citizenSafeVerificationMessage ?? this.citizenSafeVerificationMessage,
      aiVerificationAttempts:
          aiVerificationAttempts ?? this.aiVerificationAttempts,
      lastAiVerificationAttemptAt:
          lastAiVerificationAttemptAt ?? this.lastAiVerificationAttemptAt,
      lastAiFailureCode: lastAiFailureCode ?? this.lastAiFailureCode,
      aiFallbackTriggeredAt:
          aiFallbackTriggeredAt ?? this.aiFallbackTriggeredAt,
      initialReviewDepartmentId:
          initialReviewDepartmentId ?? this.initialReviewDepartmentId,
      initialReviewDepartmentName:
          initialReviewDepartmentName ?? this.initialReviewDepartmentName,
      humanReviewStatus: humanReviewStatus ?? this.humanReviewStatus,
      humanReviewerId: humanReviewerId ?? this.humanReviewerId,
      humanReviewerName: humanReviewerName ?? this.humanReviewerName,
      humanReviewRemarks: humanReviewRemarks ?? this.humanReviewRemarks,
      humanReviewedAt: humanReviewedAt ?? this.humanReviewedAt,
      previousDepartmentId:
          previousDepartmentId ?? this.previousDepartmentId,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
      closureRemarks: closureRemarks ?? this.closureRemarks,
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
      assignedJuniorEngineerNameSnapshot: assignedJuniorEngineerNameSnapshot ??
          this.assignedJuniorEngineerNameSnapshot,
      assignedJuniorEngineerDesignationSnapshot:
          assignedJuniorEngineerDesignationSnapshot ??
              this.assignedJuniorEngineerDesignationSnapshot,
      assignedFieldOfficerId: clearAssignedFieldOfficer
          ? null
          : (assignedFieldOfficerId ?? this.assignedFieldOfficerId),
      assignedFieldOfficerAt: clearAssignedFieldOfficer
          ? null
          : (assignedFieldOfficerAt ?? this.assignedFieldOfficerAt),
      assignedFieldOfficerNameSnapshot: clearAssignedFieldOfficer
          ? null
          : (assignedFieldOfficerNameSnapshot ?? this.assignedFieldOfficerNameSnapshot),
      assignedFieldOfficerDesignationSnapshot: clearAssignedFieldOfficer
          ? null
          : (assignedFieldOfficerDesignationSnapshot ??
              this.assignedFieldOfficerDesignationSnapshot),
      workStartedAt: workStartedAt ?? this.workStartedAt,
      workStartedBy: workStartedBy ?? this.workStartedBy,
      beforeWorkPhoto: beforeWorkPhoto ?? this.beforeWorkPhoto,
      beforeWorkNotes: beforeWorkNotes ?? this.beforeWorkNotes,
      afterWorkPhoto: afterWorkPhoto ?? this.afterWorkPhoto,
      resolutionRemarks: resolutionRemarks ?? this.resolutionRemarks,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      blockedAt: clearBlocked ? null : (blockedAt ?? this.blockedAt),
      blockedBy: clearBlocked ? null : (blockedBy ?? this.blockedBy),
      blockedReason: clearBlocked ? null : (blockedReason ?? this.blockedReason),
      reopenedAt: reopenedAt ?? this.reopenedAt,
      reopenedBy: reopenedBy ?? this.reopenedBy,
      reopenReason: reopenReason ?? this.reopenReason,
      previousResolvedAt: previousResolvedAt ?? this.previousResolvedAt,
      previousResolutionEvidence:
          previousResolutionEvidence ?? this.previousResolutionEvidence,
      reopenCount: reopenCount ?? this.reopenCount,
      spatialChunkId: spatialChunkId ?? this.spatialChunkId,
      geohash: geohash ?? this.geohash,
    );
  }
}

