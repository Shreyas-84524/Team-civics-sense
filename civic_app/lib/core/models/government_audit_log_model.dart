/// Standardized audit log actions for government operations.
class GovernmentAuditActions {
  GovernmentAuditActions._();

  static const String complaintCreated = 'complaint_created';
  static const String autoRoutedToJuniorEngineer = 'auto_routed_to_junior_engineer';
  static const String departmentTransferred = 'department_transferred';
  static const String routingFailed = 'routing_failed';
  static const String reassignmentRequested = 'reassignment_requested';
  static const String reassignmentApproved = 'reassignment_approved';
  static const String reassignmentRejected = 'reassignment_rejected';
  static const String crewAssigned = 'crew_assigned';
  static const String fieldOfficerAssigned = 'field_officer_assigned';
  static const String fieldOfficerReassigned = 'field_officer_reassigned';
  static const String fieldWorkStarted = 'field_work_started';
  static const String fieldWorkBlocked = 'field_work_blocked';
  static const String fieldWorkResumed = 'field_work_resumed';
  static const String statusUpdated = 'status_updated';
  static const String resolutionSubmitted = 'resolution_submitted';
  static const String resolutionVerified = 'resolution_verified';
  static const String complaintResolved = 'complaint_resolved';
  static const String complaintClosed = 'complaint_closed';
  static const String complaintReopened = 'complaint_reopened';
  static const String complaintRejected = 'complaint_rejected';
  static const String adminOverride = 'admin_override';
}

/// Immutable Government Operation Audit Log Model.
///
/// Records every critical administrative action (routing, assignments, approvals, resolutions)
/// into the `government_audit_logs` collection.
class GovernmentAuditLog {
  final String id;
  final String complaintId;
  final String action;
  final String actorId;
  final String actorRole;
  final String actorName;
  final String? wardId;
  final String? departmentId;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  const GovernmentAuditLog({
    required this.id,
    required this.complaintId,
    required this.action,
    required this.actorId,
    required this.actorRole,
    required this.actorName,
    this.wardId,
    this.departmentId,
    this.details = const {},
    required this.timestamp,
  });

  factory GovernmentAuditLog.fromJson(Map<String, dynamic> json) {
    return GovernmentAuditLog(
      id: json['id'] as String? ?? '',
      complaintId: json['complaintId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      actorRole: json['actorRole'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      wardId: json['wardId'] as String?,
      departmentId: json['departmentId'] as String?,
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : (json['details'] is Map ? Map<String, dynamic>.from(json['details'] as Map) : const {}),
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is DateTime
              ? json['timestamp'] as DateTime
              : DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintId': complaintId,
      'action': action,
      'actorId': actorId,
      'actorRole': actorRole,
      'actorName': actorName,
      if (wardId != null) 'wardId': wardId,
      if (departmentId != null) 'departmentId': departmentId,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory GovernmentAuditLog.fromMap(Map<String, dynamic> map) => GovernmentAuditLog.fromJson(map);
}
