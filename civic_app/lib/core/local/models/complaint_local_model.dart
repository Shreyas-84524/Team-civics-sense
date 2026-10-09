import '../../ai/models/ai_analysis_status.dart';
import '../../ai/models/ai_authenticity_result.dart';
import '../../models/category_model.dart';
import '../../models/complaint_model.dart';
import 'location_local_model.dart';
import 'timeline_event_local_model.dart';

/// Local persistence model for civic complaints stored in Hive.
class ComplaintLocalModel {
  final String id;
  final String citizenId;
  final String ticketNumber;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String categoryDescription;
  final String status;
  final String priority;
  final LocationLocalModel location;
  final List<String> imageUrls;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;
  final List<TimelineEventLocalModel> timeline;
  final int upvotes;
  final bool isHazard;
  final String? officerNotes;
  final String? assignedTo;
  final String? departmentName;
  final int? resolvedAtEpochMs;
  final String syncStatus;
  final String? localId;
  final String? serverId;
  final String? aiAuthenticityJson;
  final String aiAnalysisStatus;

  // Phase 3 Canonical AI Verification Fields
  final String evidenceVerificationStatus;
  final String departmentVerificationStatus;
  final String verificationStage;
  final String? verifiedDepartmentId;
  final String? verifiedDepartmentName;
  final int? evidenceVerificationStartedAtEpochMs;
  final int? evidenceVerificationCompletedAtEpochMs;
  final int? departmentVerificationStartedAtEpochMs;
  final int? departmentVerificationCompletedAtEpochMs;
  final int? verificationCompletedAtEpochMs;
  final String? verificationFailureReason;
  final String? citizenSafeVerificationMessage;

  // AI Verification Resilience & Human Review Fields
  final int aiVerificationAttempts;
  final int? lastAiVerificationAttemptAtEpochMs;
  final String? lastAiFailureCode;
  final int? aiFallbackTriggeredAtEpochMs;
  final String? initialReviewDepartmentId;
  final String? initialReviewDepartmentName;
  final String? humanReviewStatus;
  final String? humanReviewerId;
  final String? humanReviewerName;
  final String? humanReviewRemarks;
  final int? humanReviewedAtEpochMs;
  final String? previousDepartmentId;

  // Phase 3 Closure Lifecycle Fields
  final int? closedAtEpochMs;
  final String? closedBy;
  final String? closureRemarks;

  // Phase 2/3 BMC Matrix & Ground Execution Fields
  final String? wardId;
  final String? assignedDepartmentId;
  final String? assignedDepartmentLeadId;
  final String? assignedCrewMemberId;
  final String? routingStatus;
  final String? assignmentStatus;
  final int? slaStartedAtEpochMs;
  final int? originalCreatedAtEpochMs;
  final int? currentDepartmentAssignedAtEpochMs;
  final int? lastReassignedAtEpochMs;
  final int reassignmentCount;
  final String? assignedJuniorEngineerNameSnapshot;
  final String? assignedJuniorEngineerDesignationSnapshot;
  final String? assignedFieldOfficerId;
  final int? assignedFieldOfficerAtEpochMs;
  final String? assignedFieldOfficerNameSnapshot;
  final String? assignedFieldOfficerDesignationSnapshot;
  final int? workStartedAtEpochMs;
  final String? workStartedBy;
  final String? beforeWorkPhoto;
  final String? beforeWorkNotes;
  final String? afterWorkPhoto;
  final String? resolutionRemarks;
  final String? resolvedBy;
  final int? blockedAtEpochMs;
  final String? blockedBy;
  final String? blockedReason;
  final int? reopenedAtEpochMs;
  final String? reopenedBy;
  final String? reopenReason;
  final int? previousResolvedAtEpochMs;
  final List<String> previousResolutionEvidence;
  final int reopenCount;

  const ComplaintLocalModel({
    required this.id,
    required this.citizenId,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
    required this.status,
    required this.priority,
    required this.location,
    this.imageUrls = const [],
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
    this.timeline = const [],
    this.upvotes = 0,
    this.isHazard = false,
    this.officerNotes,
    this.assignedTo,
    this.departmentName,
    this.resolvedAtEpochMs,
    this.syncStatus = 'synced',
    this.localId,
    this.serverId,
    this.aiAuthenticityJson,
    this.aiAnalysisStatus = 'pending',
    this.evidenceVerificationStatus = 'pending',
    this.departmentVerificationStatus = 'pending',
    this.verificationStage = 'evidence',
    this.verifiedDepartmentId,
    this.verifiedDepartmentName,
    this.evidenceVerificationStartedAtEpochMs,
    this.evidenceVerificationCompletedAtEpochMs,
    this.departmentVerificationStartedAtEpochMs,
    this.departmentVerificationCompletedAtEpochMs,
    this.verificationCompletedAtEpochMs,
    this.verificationFailureReason,
    this.citizenSafeVerificationMessage,
    this.closedAtEpochMs,
    this.closedBy,
    this.closureRemarks,
    this.aiVerificationAttempts = 0,
    this.lastAiVerificationAttemptAtEpochMs,
    this.lastAiFailureCode,
    this.aiFallbackTriggeredAtEpochMs,
    this.initialReviewDepartmentId,
    this.initialReviewDepartmentName,
    this.humanReviewStatus,
    this.humanReviewerId,
    this.humanReviewerName,
    this.humanReviewRemarks,
    this.humanReviewedAtEpochMs,
    this.previousDepartmentId,
    this.wardId,
    this.assignedDepartmentId,
    this.assignedDepartmentLeadId,
    this.assignedCrewMemberId,
    this.routingStatus,
    this.assignmentStatus,
    this.slaStartedAtEpochMs,
    this.originalCreatedAtEpochMs,
    this.currentDepartmentAssignedAtEpochMs,
    this.lastReassignedAtEpochMs,
    this.reassignmentCount = 0,
    this.assignedJuniorEngineerNameSnapshot,
    this.assignedJuniorEngineerDesignationSnapshot,
    this.assignedFieldOfficerId,
    this.assignedFieldOfficerAtEpochMs,
    this.assignedFieldOfficerNameSnapshot,
    this.assignedFieldOfficerDesignationSnapshot,
    this.workStartedAtEpochMs,
    this.workStartedBy,
    this.beforeWorkPhoto,
    this.beforeWorkNotes,
    this.afterWorkPhoto,
    this.resolutionRemarks,
    this.resolvedBy,
    this.blockedAtEpochMs,
    this.blockedBy,
    this.blockedReason,
    this.reopenedAtEpochMs,
    this.reopenedBy,
    this.reopenReason,
    this.previousResolvedAtEpochMs,
    this.previousResolutionEvidence = const [],
    this.reopenCount = 0,
  });

  /// Map from Domain Model [ComplaintModel] -> [ComplaintLocalModel]
  factory ComplaintLocalModel.fromDomain(ComplaintModel complaint) {
    return ComplaintLocalModel(
      id: complaint.id,
      citizenId: complaint.citizenId,
      ticketNumber: complaint.ticketNumber,
      title: complaint.title,
      description: complaint.description,
      categoryId: complaint.category.id,
      categoryName: complaint.category.name,
      categoryDescription: complaint.category.description,
      status: complaint.status.name,
      priority: complaint.priority.name,
      location: LocationLocalModel.fromDomain(complaint.location),
      imageUrls: List.unmodifiable(complaint.imageUrls),
      createdAtEpochMs: complaint.createdAt.millisecondsSinceEpoch,
      updatedAtEpochMs: complaint.updatedAt.millisecondsSinceEpoch,
      timeline: complaint.timeline.map(TimelineEventLocalModel.fromDomain).toList(),
      upvotes: complaint.upvotes,
      isHazard: complaint.isHazard,
      officerNotes: complaint.officerNotes,
      assignedTo: complaint.assignedTo,
      departmentName: complaint.departmentName,
      resolvedAtEpochMs: complaint.resolvedAt?.millisecondsSinceEpoch,
      syncStatus: complaint.syncStatus.name,
      localId: complaint.localId,
      serverId: complaint.serverId,
      aiAuthenticityJson: complaint.aiAuthenticity?.toJson(),
      aiAnalysisStatus: complaint.aiAnalysisStatus.name,
      evidenceVerificationStatus: complaint.evidenceVerificationStatus,
      departmentVerificationStatus: complaint.departmentVerificationStatus,
      verificationStage: complaint.verificationStage,
      verifiedDepartmentId: complaint.verifiedDepartmentId,
      verifiedDepartmentName: complaint.verifiedDepartmentName,
      evidenceVerificationStartedAtEpochMs: complaint.evidenceVerificationStartedAt?.millisecondsSinceEpoch,
      evidenceVerificationCompletedAtEpochMs: complaint.evidenceVerificationCompletedAt?.millisecondsSinceEpoch,
      departmentVerificationStartedAtEpochMs: complaint.departmentVerificationStartedAt?.millisecondsSinceEpoch,
      departmentVerificationCompletedAtEpochMs: complaint.departmentVerificationCompletedAt?.millisecondsSinceEpoch,
      verificationCompletedAtEpochMs: complaint.verificationCompletedAt?.millisecondsSinceEpoch,
      verificationFailureReason: complaint.verificationFailureReason,
      citizenSafeVerificationMessage: complaint.citizenSafeVerificationMessage,
      aiVerificationAttempts: complaint.aiVerificationAttempts,
      lastAiVerificationAttemptAtEpochMs: complaint.lastAiVerificationAttemptAt?.millisecondsSinceEpoch,
      lastAiFailureCode: complaint.lastAiFailureCode,
      aiFallbackTriggeredAtEpochMs: complaint.aiFallbackTriggeredAt?.millisecondsSinceEpoch,
      initialReviewDepartmentId: complaint.initialReviewDepartmentId,
      initialReviewDepartmentName: complaint.initialReviewDepartmentName,
      humanReviewStatus: complaint.humanReviewStatus,
      humanReviewerId: complaint.humanReviewerId,
      humanReviewerName: complaint.humanReviewerName,
      humanReviewRemarks: complaint.humanReviewRemarks,
      humanReviewedAtEpochMs: complaint.humanReviewedAt?.millisecondsSinceEpoch,
      previousDepartmentId: complaint.previousDepartmentId,
      closedAtEpochMs: complaint.closedAt?.millisecondsSinceEpoch,
      closedBy: complaint.closedBy,
      closureRemarks: complaint.closureRemarks,
      wardId: complaint.wardId,
      assignedDepartmentId: complaint.assignedDepartmentId,
      assignedDepartmentLeadId: complaint.assignedDepartmentLeadId,
      assignedCrewMemberId: complaint.assignedCrewMemberId,
      routingStatus: complaint.routingStatus.id,
      assignmentStatus: complaint.assignmentStatus.id,
      slaStartedAtEpochMs: complaint.slaStartedAt.millisecondsSinceEpoch,
      originalCreatedAtEpochMs: complaint.originalCreatedAt.millisecondsSinceEpoch,
      currentDepartmentAssignedAtEpochMs: complaint.currentDepartmentAssignedAt?.millisecondsSinceEpoch,
      lastReassignedAtEpochMs: complaint.lastReassignedAt?.millisecondsSinceEpoch,
      reassignmentCount: complaint.reassignmentCount,
      assignedJuniorEngineerNameSnapshot: complaint.assignedJuniorEngineerNameSnapshot,
      assignedJuniorEngineerDesignationSnapshot: complaint.assignedJuniorEngineerDesignationSnapshot,
      assignedFieldOfficerId: complaint.assignedFieldOfficerId,
      assignedFieldOfficerAtEpochMs: complaint.assignedFieldOfficerAt?.millisecondsSinceEpoch,
      assignedFieldOfficerNameSnapshot: complaint.assignedFieldOfficerNameSnapshot,
      assignedFieldOfficerDesignationSnapshot: complaint.assignedFieldOfficerDesignationSnapshot,
      workStartedAtEpochMs: complaint.workStartedAt?.millisecondsSinceEpoch,
      workStartedBy: complaint.workStartedBy,
      beforeWorkPhoto: complaint.beforeWorkPhoto,
      beforeWorkNotes: complaint.beforeWorkNotes,
      afterWorkPhoto: complaint.afterWorkPhoto,
      resolutionRemarks: complaint.resolutionRemarks,
      resolvedBy: complaint.resolvedBy,
      blockedAtEpochMs: complaint.blockedAt?.millisecondsSinceEpoch,
      blockedBy: complaint.blockedBy,
      blockedReason: complaint.blockedReason,
      reopenedAtEpochMs: complaint.reopenedAt?.millisecondsSinceEpoch,
      reopenedBy: complaint.reopenedBy,
      reopenReason: complaint.reopenReason,
      previousResolvedAtEpochMs: complaint.previousResolvedAt?.millisecondsSinceEpoch,
      previousResolutionEvidence: List.unmodifiable(complaint.previousResolutionEvidence),
      reopenCount: complaint.reopenCount,
    );
  }

  /// Map from [ComplaintLocalModel] -> Domain Model [ComplaintModel]
  ComplaintModel toDomain() {
    ComplaintStatus parsedStatus;
    try {
      parsedStatus = ComplaintStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == status.toLowerCase(),
        orElse: () => ComplaintStatus.reported,
      );
    } catch (_) {
      parsedStatus = ComplaintStatus.reported;
    }

    ComplaintPriority parsedPriority;
    try {
      parsedPriority = ComplaintPriority.values.firstWhere(
        (p) => p.name.toLowerCase() == priority.toLowerCase(),
        orElse: () => ComplaintPriority.medium,
      );
    } catch (_) {
      parsedPriority = ComplaintPriority.medium;
    }

    SyncStatus parsedSyncStatus;
    try {
      parsedSyncStatus = SyncStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == syncStatus.toLowerCase(),
        orElse: () => SyncStatus.synced,
      );
    } catch (_) {
      parsedSyncStatus = SyncStatus.synced;
    }

    // Resolve category from default categories or create an instance
    CivicCategory resolvedCategory;
    try {
      resolvedCategory = CivicCategory.defaultCategories.firstWhere(
        (c) => c.id.toLowerCase() == categoryId.toLowerCase(),
        orElse: () => CivicCategory(
          id: categoryId,
          name: categoryName,
          description: categoryDescription,
          icon: CivicCategory.defaultCategories.first.icon,
        ),
      );
    } catch (_) {
      resolvedCategory = CivicCategory.defaultCategories.first;
    }

    final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtEpochMs);

    return ComplaintModel(
      id: id,
      citizenId: citizenId,
      ticketNumber: ticketNumber,
      title: title,
      description: description,
      category: resolvedCategory,
      status: parsedStatus,
      priority: parsedPriority,
      location: location.toDomain(),
      imageUrls: imageUrls,
      createdAt: createdAt,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtEpochMs),
      timeline: timeline.map((e) => e.toDomain()).toList(),
      upvotes: upvotes,
      isHazard: isHazard,
      officerNotes: officerNotes,
      assignedTo: assignedTo,
      departmentName: departmentName,
      resolvedAt: resolvedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(resolvedAtEpochMs!)
          : null,
      syncStatus: parsedSyncStatus,
      localId: localId,
      serverId: serverId,
      aiAuthenticity: aiAuthenticityJson != null && aiAuthenticityJson!.isNotEmpty
          ? AiAuthenticityResult.fromJsonString(aiAuthenticityJson!)
          : null,
      aiAnalysisStatus: AiAnalysisStatus.fromString(aiAnalysisStatus),
      evidenceVerificationStatus: evidenceVerificationStatus,
      departmentVerificationStatus: departmentVerificationStatus,
      verificationStage: verificationStage,
      verifiedDepartmentId: verifiedDepartmentId,
      verifiedDepartmentName: verifiedDepartmentName,
      evidenceVerificationStartedAt: evidenceVerificationStartedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(evidenceVerificationStartedAtEpochMs!)
          : null,
      evidenceVerificationCompletedAt: evidenceVerificationCompletedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(evidenceVerificationCompletedAtEpochMs!)
          : null,
      departmentVerificationStartedAt: departmentVerificationStartedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(departmentVerificationStartedAtEpochMs!)
          : null,
      departmentVerificationCompletedAt: departmentVerificationCompletedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(departmentVerificationCompletedAtEpochMs!)
          : null,
      verificationCompletedAt: verificationCompletedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(verificationCompletedAtEpochMs!)
          : null,
      verificationFailureReason: verificationFailureReason,
      citizenSafeVerificationMessage: citizenSafeVerificationMessage,
      aiVerificationAttempts: aiVerificationAttempts,
      lastAiVerificationAttemptAt: lastAiVerificationAttemptAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastAiVerificationAttemptAtEpochMs!)
          : null,
      lastAiFailureCode: lastAiFailureCode,
      aiFallbackTriggeredAt: aiFallbackTriggeredAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(aiFallbackTriggeredAtEpochMs!)
          : null,
      initialReviewDepartmentId: initialReviewDepartmentId,
      initialReviewDepartmentName: initialReviewDepartmentName,
      humanReviewStatus: humanReviewStatus,
      humanReviewerId: humanReviewerId,
      humanReviewerName: humanReviewerName,
      humanReviewRemarks: humanReviewRemarks,
      humanReviewedAt: humanReviewedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(humanReviewedAtEpochMs!)
          : null,
      previousDepartmentId: previousDepartmentId,
      closedAt: closedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(closedAtEpochMs!)
          : null,
      closedBy: closedBy,
      closureRemarks: closureRemarks,
      wardId: wardId,
      assignedDepartmentId: assignedDepartmentId,
      assignedDepartmentLeadId: assignedDepartmentLeadId,
      assignedCrewMemberId: assignedCrewMemberId,
      routingStatus: ComplaintRoutingStatus.fromString(routingStatus),
      assignmentStatus: ComplaintAssignmentStatus.fromString(assignmentStatus),
      slaStartedAt: slaStartedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(slaStartedAtEpochMs!)
          : createdAt,
      originalCreatedAt: originalCreatedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(originalCreatedAtEpochMs!)
          : createdAt,
      currentDepartmentAssignedAt: currentDepartmentAssignedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(currentDepartmentAssignedAtEpochMs!)
          : null,
      lastReassignedAt: lastReassignedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastReassignedAtEpochMs!)
          : null,
      reassignmentCount: reassignmentCount,
      assignedJuniorEngineerNameSnapshot: assignedJuniorEngineerNameSnapshot,
      assignedJuniorEngineerDesignationSnapshot: assignedJuniorEngineerDesignationSnapshot,
      assignedFieldOfficerId: assignedFieldOfficerId,
      assignedFieldOfficerAt: assignedFieldOfficerAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(assignedFieldOfficerAtEpochMs!)
          : null,
      assignedFieldOfficerNameSnapshot: assignedFieldOfficerNameSnapshot,
      assignedFieldOfficerDesignationSnapshot: assignedFieldOfficerDesignationSnapshot,
      workStartedAt: workStartedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(workStartedAtEpochMs!)
          : null,
      workStartedBy: workStartedBy,
      beforeWorkPhoto: beforeWorkPhoto,
      beforeWorkNotes: beforeWorkNotes,
      afterWorkPhoto: afterWorkPhoto,
      resolutionRemarks: resolutionRemarks,
      resolvedBy: resolvedBy,
      blockedAt: blockedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(blockedAtEpochMs!)
          : null,
      blockedBy: blockedBy,
      blockedReason: blockedReason,
      reopenedAt: reopenedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(reopenedAtEpochMs!)
          : null,
      reopenedBy: reopenedBy,
      reopenReason: reopenReason,
      previousResolvedAt: previousResolvedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(previousResolvedAtEpochMs!)
          : null,
      previousResolutionEvidence: previousResolutionEvidence,
      reopenCount: reopenCount,
    );
  }

  ComplaintLocalModel copyWith({
    String? id,
    String? citizenId,
    String? ticketNumber,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? categoryDescription,
    String? status,
    String? priority,
    LocationLocalModel? location,
    List<String>? imageUrls,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
    List<TimelineEventLocalModel>? timeline,
    int? upvotes,
    bool? isHazard,
    String? officerNotes,
    String? assignedTo,
    String? departmentName,
    int? resolvedAtEpochMs,
    String? syncStatus,
    String? localId,
    String? serverId,
    String? aiAuthenticityJson,
    String? aiAnalysisStatus,
    String? evidenceVerificationStatus,
    String? departmentVerificationStatus,
    String? verificationStage,
    String? verifiedDepartmentId,
    String? verifiedDepartmentName,
    int? evidenceVerificationStartedAtEpochMs,
    int? evidenceVerificationCompletedAtEpochMs,
    int? departmentVerificationStartedAtEpochMs,
    int? departmentVerificationCompletedAtEpochMs,
    int? verificationCompletedAtEpochMs,
    String? verificationFailureReason,
    String? citizenSafeVerificationMessage,
    int? aiVerificationAttempts,
    int? lastAiVerificationAttemptAtEpochMs,
    String? lastAiFailureCode,
    int? aiFallbackTriggeredAtEpochMs,
    String? initialReviewDepartmentId,
    String? initialReviewDepartmentName,
    String? humanReviewStatus,
    String? humanReviewerId,
    String? humanReviewerName,
    String? humanReviewRemarks,
    int? humanReviewedAtEpochMs,
    String? previousDepartmentId,
    int? closedAtEpochMs,
    String? closedBy,
    String? closureRemarks,
    String? wardId,
    String? assignedDepartmentId,
    String? assignedDepartmentLeadId,
    String? assignedCrewMemberId,
    String? routingStatus,
    String? assignmentStatus,
    int? slaStartedAtEpochMs,
    int? originalCreatedAtEpochMs,
    int? currentDepartmentAssignedAtEpochMs,
    int? lastReassignedAtEpochMs,
    int? reassignmentCount,
    String? assignedJuniorEngineerNameSnapshot,
    String? assignedJuniorEngineerDesignationSnapshot,
    String? assignedFieldOfficerId,
    int? assignedFieldOfficerAtEpochMs,
    String? assignedFieldOfficerNameSnapshot,
    String? assignedFieldOfficerDesignationSnapshot,
    int? workStartedAtEpochMs,
    String? workStartedBy,
    String? beforeWorkPhoto,
    String? beforeWorkNotes,
    String? afterWorkPhoto,
    String? resolutionRemarks,
    String? resolvedBy,
    int? blockedAtEpochMs,
    String? blockedBy,
    String? blockedReason,
    int? reopenedAtEpochMs,
    String? reopenedBy,
    String? reopenReason,
    int? previousResolvedAtEpochMs,
    List<String>? previousResolutionEvidence,
    int? reopenCount,
  }) {
    return ComplaintLocalModel(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      timeline: timeline ?? this.timeline,
      upvotes: upvotes ?? this.upvotes,
      isHazard: isHazard ?? this.isHazard,
      officerNotes: officerNotes ?? this.officerNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      departmentName: departmentName ?? this.departmentName,
      resolvedAtEpochMs: resolvedAtEpochMs ?? this.resolvedAtEpochMs,
      syncStatus: syncStatus ?? this.syncStatus,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      aiAuthenticityJson: aiAuthenticityJson ?? this.aiAuthenticityJson,
      aiAnalysisStatus: aiAnalysisStatus ?? this.aiAnalysisStatus,
      evidenceVerificationStatus: evidenceVerificationStatus ?? this.evidenceVerificationStatus,
      departmentVerificationStatus: departmentVerificationStatus ?? this.departmentVerificationStatus,
      verificationStage: verificationStage ?? this.verificationStage,
      verifiedDepartmentId: verifiedDepartmentId ?? this.verifiedDepartmentId,
      verifiedDepartmentName: verifiedDepartmentName ?? this.verifiedDepartmentName,
      evidenceVerificationStartedAtEpochMs: evidenceVerificationStartedAtEpochMs ?? this.evidenceVerificationStartedAtEpochMs,
      evidenceVerificationCompletedAtEpochMs: evidenceVerificationCompletedAtEpochMs ?? this.evidenceVerificationCompletedAtEpochMs,
      departmentVerificationStartedAtEpochMs: departmentVerificationStartedAtEpochMs ?? this.departmentVerificationStartedAtEpochMs,
      departmentVerificationCompletedAtEpochMs: departmentVerificationCompletedAtEpochMs ?? this.departmentVerificationCompletedAtEpochMs,
      verificationCompletedAtEpochMs: verificationCompletedAtEpochMs ?? this.verificationCompletedAtEpochMs,
      verificationFailureReason: verificationFailureReason ?? this.verificationFailureReason,
      citizenSafeVerificationMessage: citizenSafeVerificationMessage ?? this.citizenSafeVerificationMessage,
      aiVerificationAttempts: aiVerificationAttempts ?? this.aiVerificationAttempts,
      lastAiVerificationAttemptAtEpochMs: lastAiVerificationAttemptAtEpochMs ?? this.lastAiVerificationAttemptAtEpochMs,
      lastAiFailureCode: lastAiFailureCode ?? this.lastAiFailureCode,
      aiFallbackTriggeredAtEpochMs: aiFallbackTriggeredAtEpochMs ?? this.aiFallbackTriggeredAtEpochMs,
      initialReviewDepartmentId: initialReviewDepartmentId ?? this.initialReviewDepartmentId,
      initialReviewDepartmentName: initialReviewDepartmentName ?? this.initialReviewDepartmentName,
      humanReviewStatus: humanReviewStatus ?? this.humanReviewStatus,
      humanReviewerId: humanReviewerId ?? this.humanReviewerId,
      humanReviewerName: humanReviewerName ?? this.humanReviewerName,
      humanReviewRemarks: humanReviewRemarks ?? this.humanReviewRemarks,
      humanReviewedAtEpochMs: humanReviewedAtEpochMs ?? this.humanReviewedAtEpochMs,
      previousDepartmentId: previousDepartmentId ?? this.previousDepartmentId,
      closedAtEpochMs: closedAtEpochMs ?? this.closedAtEpochMs,
      closedBy: closedBy ?? this.closedBy,
      closureRemarks: closureRemarks ?? this.closureRemarks,
      wardId: wardId ?? this.wardId,
      assignedDepartmentId: assignedDepartmentId ?? this.assignedDepartmentId,
      assignedDepartmentLeadId: assignedDepartmentLeadId ?? this.assignedDepartmentLeadId,
      assignedCrewMemberId: assignedCrewMemberId ?? this.assignedCrewMemberId,
      routingStatus: routingStatus ?? this.routingStatus,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      slaStartedAtEpochMs: slaStartedAtEpochMs ?? this.slaStartedAtEpochMs,
      originalCreatedAtEpochMs: originalCreatedAtEpochMs ?? this.originalCreatedAtEpochMs,
      currentDepartmentAssignedAtEpochMs: currentDepartmentAssignedAtEpochMs ?? this.currentDepartmentAssignedAtEpochMs,
      lastReassignedAtEpochMs: lastReassignedAtEpochMs ?? this.lastReassignedAtEpochMs,
      reassignmentCount: reassignmentCount ?? this.reassignmentCount,
      assignedJuniorEngineerNameSnapshot: assignedJuniorEngineerNameSnapshot ?? this.assignedJuniorEngineerNameSnapshot,
      assignedJuniorEngineerDesignationSnapshot: assignedJuniorEngineerDesignationSnapshot ?? this.assignedJuniorEngineerDesignationSnapshot,
      assignedFieldOfficerId: assignedFieldOfficerId ?? this.assignedFieldOfficerId,
      assignedFieldOfficerAtEpochMs: assignedFieldOfficerAtEpochMs ?? this.assignedFieldOfficerAtEpochMs,
      assignedFieldOfficerNameSnapshot: assignedFieldOfficerNameSnapshot ?? this.assignedFieldOfficerNameSnapshot,
      assignedFieldOfficerDesignationSnapshot: assignedFieldOfficerDesignationSnapshot ?? this.assignedFieldOfficerDesignationSnapshot,
      workStartedAtEpochMs: workStartedAtEpochMs ?? this.workStartedAtEpochMs,
      workStartedBy: workStartedBy ?? this.workStartedBy,
      beforeWorkPhoto: beforeWorkPhoto ?? this.beforeWorkPhoto,
      beforeWorkNotes: beforeWorkNotes ?? this.beforeWorkNotes,
      afterWorkPhoto: afterWorkPhoto ?? this.afterWorkPhoto,
      resolutionRemarks: resolutionRemarks ?? this.resolutionRemarks,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      blockedAtEpochMs: blockedAtEpochMs ?? this.blockedAtEpochMs,
      blockedBy: blockedBy ?? this.blockedBy,
      blockedReason: blockedReason ?? this.blockedReason,
      reopenedAtEpochMs: reopenedAtEpochMs ?? this.reopenedAtEpochMs,
      reopenedBy: reopenedBy ?? this.reopenedBy,
      reopenReason: reopenReason ?? this.reopenReason,
      previousResolvedAtEpochMs: previousResolvedAtEpochMs ?? this.previousResolvedAtEpochMs,
      previousResolutionEvidence: previousResolutionEvidence ?? this.previousResolutionEvidence,
      reopenCount: reopenCount ?? this.reopenCount,
    );
  }
}
