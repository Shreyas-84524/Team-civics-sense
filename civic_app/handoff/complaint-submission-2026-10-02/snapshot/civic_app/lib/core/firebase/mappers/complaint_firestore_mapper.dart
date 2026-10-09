import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ai/models/ai_analysis_status.dart';
import '../../ai/models/ai_authenticity_result.dart';
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
      'officerNotes': isCreate ? null : complaint.officerNotes,
      'assignedTo': isCreate ? null : complaint.assignedTo,
      // The creation rule requires this legacy assignment field explicitly null.
      // Routing uses assignedDepartmentId; keep both fields in the wire schema.
      'departmentId': isCreate ? null : complaint.assignedDepartmentId,
      'departmentName': isCreate ? null : complaint.departmentName,
      'resolvedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.resolvedAt),
      if (complaint.aiAuthenticity != null)
        'aiAuthenticity': complaint.aiAuthenticity!.toMap(),
      'aiAnalysisStatus': complaint.aiAnalysisStatus.name,
      // Phase 3 Canonical AI Verification Fields
      'evidenceVerificationStatus': isCreate ? 'pending' : complaint.evidenceVerificationStatus,
      'departmentVerificationStatus': isCreate ? 'pending' : complaint.departmentVerificationStatus,
      'verificationStage': isCreate ? 'evidence' : complaint.verificationStage,
      'verifiedDepartmentId': isCreate ? null : complaint.verifiedDepartmentId,
      'verifiedDepartmentName': isCreate ? null : complaint.verifiedDepartmentName,
      'evidenceVerificationStartedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.evidenceVerificationStartedAt),
      'evidenceVerificationCompletedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.evidenceVerificationCompletedAt),
      'departmentVerificationStartedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.departmentVerificationStartedAt),
      'departmentVerificationCompletedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.departmentVerificationCompletedAt),
      'verificationCompletedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.verificationCompletedAt),
      'verificationFailureReason': isCreate ? null : complaint.verificationFailureReason,
      'citizenSafeVerificationMessage': isCreate ? null : complaint.citizenSafeVerificationMessage,
      // Phase 3 Closure Lifecycle Fields
      'closedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.closedAt),
      'closedBy': isCreate ? null : complaint.closedBy,
      'closureRemarks': isCreate ? null : complaint.closureRemarks,
      // Phase 2 BMC Matrix Hierarchical Fields
      'wardId': complaint.wardId,
      'assignedDepartmentId': isCreate ? null : complaint.assignedDepartmentId,
      'assignedDepartmentLeadId': isCreate ? null : complaint.assignedDepartmentLeadId,
      'assignedCrewMemberId': isCreate ? null : complaint.assignedCrewMemberId,
      'routingStatus': isCreate ? ComplaintRoutingStatus.unassigned.id : complaint.routingStatus.id,
      'assignmentStatus': isCreate ? ComplaintAssignmentStatus.unassigned.id : complaint.assignmentStatus.id,
      'slaStartedAt': FirestoreMapperHelpers.dateTimeToTimestamp(complaint.slaStartedAt),
      'originalCreatedAt': FirestoreMapperHelpers.dateTimeToTimestamp(complaint.originalCreatedAt),
      'currentDepartmentAssignedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.currentDepartmentAssignedAt),
      'lastReassignedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.lastReassignedAt),
      'reassignmentCount': isCreate ? 0 : complaint.reassignmentCount,
      // Phase 1/3 Junior Engineer Snapshots
      'assignedJuniorEngineerNameSnapshot': isCreate ? null : complaint.assignedJuniorEngineerNameSnapshot,
      'assignedJuniorEngineerDesignationSnapshot': isCreate ? null : complaint.assignedJuniorEngineerDesignationSnapshot,
      // Phase 2 Field Officer & Ground Execution Fields
      'assignedFieldOfficerId': isCreate ? null : complaint.assignedFieldOfficerId,
      'assignedFieldOfficerAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.assignedFieldOfficerAt),
      'assignedFieldOfficerNameSnapshot': isCreate ? null : complaint.assignedFieldOfficerNameSnapshot,
      'assignedFieldOfficerDesignationSnapshot': isCreate ? null : complaint.assignedFieldOfficerDesignationSnapshot,
      'workStartedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.workStartedAt),
      'workStartedBy': isCreate ? null : complaint.workStartedBy,
      'beforeWorkPhoto': isCreate ? null : complaint.beforeWorkPhoto,
      'beforeWorkNotes': isCreate ? null : complaint.beforeWorkNotes,
      'afterWorkPhoto': isCreate ? null : complaint.afterWorkPhoto,
      'resolutionRemarks': isCreate ? null : complaint.resolutionRemarks,
      'resolvedBy': isCreate ? null : complaint.resolvedBy,
      'blockedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.blockedAt),
      'blockedBy': isCreate ? null : complaint.blockedBy,
      'blockedReason': isCreate ? null : complaint.blockedReason,
      'reopenedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.reopenedAt),
      'reopenedBy': isCreate ? null : complaint.reopenedBy,
      'reopenReason': isCreate ? null : complaint.reopenReason,
      'previousResolvedAt': isCreate ? null : FirestoreMapperHelpers.dateTimeToTimestamp(complaint.previousResolvedAt),
      'previousResolutionEvidence': isCreate ? const [] : complaint.previousResolutionEvidence,
      'reopenCount': isCreate ? 0 : complaint.reopenCount,
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
    AiAuthenticityResult? parsedAuthenticity;
    if (data['aiAuthenticity'] is Map<String, dynamic>) {
      parsedAuthenticity = AiAuthenticityResult.fromMap(data['aiAuthenticity'] as Map<String, dynamic>);
    } else if (data['aiAuthenticity'] is Map) {
      parsedAuthenticity = AiAuthenticityResult.fromMap(Map<String, dynamic>.from(data['aiAuthenticity'] as Map));
    }

    final createdAt = FirestoreMapperHelpers.timestampToDateTime(data['createdAt']) ?? DateTime.now();

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
      createdAt: createdAt,
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
      aiAuthenticity: parsedAuthenticity,
      aiAnalysisStatus: AiAnalysisStatus.fromString(data['aiAnalysisStatus'] as String?),
      // Phase 3 Canonical AI Verification Fields
      evidenceVerificationStatus: data['evidenceVerificationStatus'] as String? ?? 'pending',
      departmentVerificationStatus: data['departmentVerificationStatus'] as String? ?? 'pending',
      verificationStage: data['verificationStage'] as String? ?? 'evidence',
      verifiedDepartmentId: data['verifiedDepartmentId'] as String?,
      verifiedDepartmentName: data['verifiedDepartmentName'] as String?,
      evidenceVerificationStartedAt: FirestoreMapperHelpers.timestampToDateTime(data['evidenceVerificationStartedAt']),
      evidenceVerificationCompletedAt: FirestoreMapperHelpers.timestampToDateTime(data['evidenceVerificationCompletedAt']),
      departmentVerificationStartedAt: FirestoreMapperHelpers.timestampToDateTime(data['departmentVerificationStartedAt']),
      departmentVerificationCompletedAt: FirestoreMapperHelpers.timestampToDateTime(data['departmentVerificationCompletedAt']),
      verificationCompletedAt: FirestoreMapperHelpers.timestampToDateTime(data['verificationCompletedAt']),
      verificationFailureReason: data['verificationFailureReason'] as String?,
      citizenSafeVerificationMessage: data['citizenSafeVerificationMessage'] as String?,
      // Phase 3 Closure Lifecycle Fields
      closedAt: FirestoreMapperHelpers.timestampToDateTime(data['closedAt']),
      closedBy: data['closedBy'] as String?,
      closureRemarks: data['closureRemarks'] as String?,
      // Phase 2 BMC Matrix Hierarchical Fields
      wardId: data['wardId'] as String?,
      assignedDepartmentId: data['assignedDepartmentId'] as String? ?? data['departmentId'] as String?,
      assignedDepartmentLeadId: data['assignedDepartmentLeadId'] as String?,
      assignedCrewMemberId: data['assignedCrewMemberId'] as String?,
      routingStatus: ComplaintRoutingStatus.fromString(data['routingStatus'] as String?),
      assignmentStatus: ComplaintAssignmentStatus.fromString(data['assignmentStatus'] as String?),
      slaStartedAt: FirestoreMapperHelpers.timestampToDateTime(data['slaStartedAt']) ?? createdAt,
      originalCreatedAt: FirestoreMapperHelpers.timestampToDateTime(data['originalCreatedAt']) ?? createdAt,
      currentDepartmentAssignedAt: FirestoreMapperHelpers.timestampToDateTime(data['currentDepartmentAssignedAt']),
      lastReassignedAt: FirestoreMapperHelpers.timestampToDateTime(data['lastReassignedAt']),
      reassignmentCount: data['reassignmentCount'] as int? ?? 0,
      // Phase 1/3 Junior Engineer Snapshots
      assignedJuniorEngineerNameSnapshot: data['assignedJuniorEngineerNameSnapshot'] as String?,
      assignedJuniorEngineerDesignationSnapshot: data['assignedJuniorEngineerDesignationSnapshot'] as String?,
      // Phase 2 Field Officer & Ground Execution Fields
      assignedFieldOfficerId: data['assignedFieldOfficerId'] as String?,
      assignedFieldOfficerAt: FirestoreMapperHelpers.timestampToDateTime(data['assignedFieldOfficerAt']),
      assignedFieldOfficerNameSnapshot: data['assignedFieldOfficerNameSnapshot'] as String?,
      assignedFieldOfficerDesignationSnapshot: data['assignedFieldOfficerDesignationSnapshot'] as String?,
      workStartedAt: FirestoreMapperHelpers.timestampToDateTime(data['workStartedAt']),
      workStartedBy: data['workStartedBy'] as String?,
      beforeWorkPhoto: data['beforeWorkPhoto'] as String?,
      beforeWorkNotes: data['beforeWorkNotes'] as String?,
      afterWorkPhoto: data['afterWorkPhoto'] as String?,
      resolutionRemarks: data['resolutionRemarks'] as String?,
      resolvedBy: data['resolvedBy'] as String?,
      blockedAt: FirestoreMapperHelpers.timestampToDateTime(data['blockedAt']),
      blockedBy: data['blockedBy'] as String?,
      blockedReason: data['blockedReason'] as String?,
      reopenedAt: FirestoreMapperHelpers.timestampToDateTime(data['reopenedAt']),
      reopenedBy: data['reopenedBy'] as String?,
      reopenReason: data['reopenReason'] as String?,
      previousResolvedAt: FirestoreMapperHelpers.timestampToDateTime(data['previousResolvedAt']),
      previousResolutionEvidence: List<String>.from(data['previousResolutionEvidence'] as List<dynamic>? ?? const []),
      reopenCount: data['reopenCount'] as int? ?? 0,
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
