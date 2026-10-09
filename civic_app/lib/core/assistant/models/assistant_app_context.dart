import 'package:flutter/foundation.dart';

/// Contextual state from the active mobile app session passed to the assistant.
///
/// Implements Phase 5 Safe Live Application Context:
/// - Exposes verified, role-safe complaint lifecycle data and screen location.
/// - Strictly enforces the Zero-PII privacy allowlist (no phone, email, UIDs, OTPs, credentials, or private URLs).
/// - 100% read-only interface.
@immutable
class AssistantAppContext {
  /// The active user role (e.g. 'citizen', 'department_crew', 'ward_department_lead', 'super_admin').
  final String userRole;

  /// The active screen or route name (e.g. 'home', 'complaintDetails', 'reportIssue', 'myComplaints', 'map', 'profile').
  final String? currentScreen;

  /// Current step if on the report issue flow (e.g. 'issueInfo', 'evidence', 'location', 'review').
  final String? reportStep;

  /// Internal document identifier (used purely for state routing, never formatted as PII or exposed to model prompts).
  final String? selectedComplaintId;

  /// Canonical public ticket number (e.g. 'CF-2026-000024').
  final String? selectedTicketNumber;

  /// Current complaint lifecycle status (e.g. 'underVerification', 'reported', 'assigned', 'inProgress', 'resolved', 'closed', 'reopened').
  final String? complaintStatus;

  /// Grievance category display name or code (e.g. 'Pothole', 'Water Leakage', 'Garbage Overflow').
  final String? complaintCategory;

  /// Administrative ward identifier or display name (e.g. 'R/South', 'K/West', 'ward_r_south').
  final String? wardId;

  /// Responsible municipal department display name or key (e.g. 'Maintenance (Roads & Traffic)', 'Water Works').
  final String? departmentId;

  /// Sub-stage of verification (e.g. 'evidence', 'department', 'humanDepartmentReview', 'verification_completed').
  final String? verificationStage;

  /// Status of automated photo authenticity check ('pending', 'processing', 'passed', 'failed', 'temporarily_unavailable').
  final String? evidenceVerificationStatus;

  /// Status of automated department routing check ('pending', 'processing', 'passed', 'failed', 'temporarily_unavailable').
  final String? departmentVerificationStatus;

  /// Whether a Junior Engineer has been assigned to the grievance.
  final bool hasJuniorEngineerAssigned;

  /// Public display snapshot name of the assigned Junior Engineer (only if exposed in citizen UI).
  final String? assignedJuniorEngineerName;

  /// Whether an on-ground Field Execution Officer has been assigned.
  final bool hasFieldOfficerAssigned;

  /// Public display snapshot name of the assigned Field Execution Officer (only if exposed in citizen UI).
  final String? assignedFieldOfficerName;

  /// Whether ground repair is temporarily blocked by an on-site obstacle.
  final bool isBlocked;

  /// Safe, citizen-facing obstacle description if work is blocked.
  final String? blockedReason;

  /// Number of times supervisory rework has been requested by the Ward Department Lead.
  final int reopenCount;

  /// Safe, citizen-facing rework reason if the grievance is in rework.
  final String? reopenReason;

  /// Local synchronization status for offline queues ('synced', 'pending', 'failed').
  final String? syncState;

  /// Active application language code ('en', 'hi', 'mr').
  final String selectedLanguage;

  /// Whether the authenticated session belongs to a municipal employee.
  final bool isGovernmentUser;

  /// Optional active feature filter when opened from the Map screen (e.g. 'potholes', 'clusters').
  final String? selectedMapFeatureType;

  const AssistantAppContext({
    this.userRole = 'citizen',
    this.currentScreen,
    this.reportStep,
    this.selectedComplaintId,
    this.selectedTicketNumber,
    this.complaintStatus,
    this.complaintCategory,
    this.wardId,
    this.departmentId,
    this.verificationStage,
    this.evidenceVerificationStatus,
    this.departmentVerificationStatus,
    this.hasJuniorEngineerAssigned = false,
    this.assignedJuniorEngineerName,
    this.hasFieldOfficerAssigned = false,
    this.assignedFieldOfficerName,
    this.isBlocked = false,
    this.blockedReason,
    this.reopenCount = 0,
    this.reopenReason,
    this.syncState,
    this.selectedLanguage = 'en',
    this.isGovernmentUser = false,
    this.selectedMapFeatureType,
  });

  /// Convenient alias for ticket ID.
  String? get ticketId => selectedTicketNumber;

  /// Whether a specific complaint is currently loaded in context.
  bool get hasComplaintContext =>
      (selectedTicketNumber != null && selectedTicketNumber!.isNotEmpty) ||
      (selectedComplaintId != null && selectedComplaintId!.isNotEmpty);

  /// Status helper getters.
  bool get isUnderVerification =>
      complaintStatus == 'underVerification' || complaintStatus == 'reported';
  bool get isAssigned => complaintStatus == 'assigned';
  bool get isInProgress => complaintStatus == 'inProgress';
  bool get isResolved => complaintStatus == 'resolved';
  bool get isClosed => complaintStatus == 'closed';
  bool get isReopened =>
      complaintStatus == 'reopened' || reopenCount > 0 || (isInProgress && reopenCount > 0);
  bool get isOfflinePending => syncState == 'offline_pending' || syncState == 'pending';

  /// Formats the active app context into a concise, privacy-safe string for prompt assembly.
  /// Omits empty or unpopulated fields to minimize prompt token usage.
  String toPromptContextString() {
    final buffer = StringBuffer();
    buffer.writeln('=== CURRENT CIVICFIX APP CONTEXT ===');
    buffer.writeln('Active Language: $selectedLanguage');
    buffer.writeln('User Role: $userRole');

    if (currentScreen != null && currentScreen!.isNotEmpty) {
      buffer.writeln('Active Screen: $currentScreen');
    }
    if (reportStep != null && reportStep!.isNotEmpty) {
      buffer.writeln('Report Flow Step: $reportStep');
    }
    if (selectedTicketNumber != null && selectedTicketNumber!.isNotEmpty) {
      buffer.writeln('Referenced Complaint Ticket: $selectedTicketNumber');
    }
    if (complaintStatus != null && complaintStatus!.isNotEmpty) {
      buffer.writeln('Complaint Status: $complaintStatus');
    }
    if (complaintCategory != null && complaintCategory!.isNotEmpty) {
      buffer.writeln('Category: $complaintCategory');
    }
    if (wardId != null && wardId!.isNotEmpty) {
      buffer.writeln('Ward: $wardId');
    }
    if (departmentId != null && departmentId!.isNotEmpty) {
      buffer.writeln('Department: $departmentId');
    }
    if (verificationStage != null && verificationStage!.isNotEmpty) {
      buffer.writeln('Verification Stage: $verificationStage');
    }
    if (hasJuniorEngineerAssigned) {
      final jeName = assignedJuniorEngineerName;
      buffer.writeln(
        jeName != null && jeName.isNotEmpty
            ? 'Junior Engineer Assigned: Yes ($jeName)'
            : 'Junior Engineer Assigned: Yes',
      );
    }
    if (hasFieldOfficerAssigned) {
      final foName = assignedFieldOfficerName;
      buffer.writeln(
        foName != null && foName.isNotEmpty
            ? 'Field Officer Assigned: Yes ($foName)'
            : 'Field Officer Assigned: Yes',
      );
    }
    if (isBlocked) {
      buffer.writeln(
        blockedReason != null && blockedReason!.isNotEmpty
            ? 'Blocked Status: Yes ($blockedReason)'
            : 'Blocked Status: Yes (Obstacle on site)',
      );
    }
    if (reopenCount > 0) {
      buffer.writeln(
        reopenReason != null && reopenReason!.isNotEmpty
            ? 'Rework Count: $reopenCount (Reason: $reopenReason)'
            : 'Rework Count: $reopenCount',
      );
    }
    if (syncState != null && syncState!.isNotEmpty) {
      buffer.writeln('Sync State: $syncState');
    }
    if (selectedMapFeatureType != null && selectedMapFeatureType!.isNotEmpty) {
      buffer.writeln('Map Feature Context: $selectedMapFeatureType');
    }

    return buffer.toString().trim();
  }

  AssistantAppContext copyWith({
    String? userRole,
    String? currentScreen,
    String? reportStep,
    String? selectedComplaintId,
    String? selectedTicketNumber,
    String? complaintStatus,
    String? complaintCategory,
    String? wardId,
    String? departmentId,
    String? verificationStage,
    String? evidenceVerificationStatus,
    String? departmentVerificationStatus,
    bool? hasJuniorEngineerAssigned,
    String? assignedJuniorEngineerName,
    bool? hasFieldOfficerAssigned,
    String? assignedFieldOfficerName,
    bool? isBlocked,
    String? blockedReason,
    int? reopenCount,
    String? reopenReason,
    String? syncState,
    String? selectedLanguage,
    bool? isGovernmentUser,
    String? selectedMapFeatureType,
  }) {
    return AssistantAppContext(
      userRole: userRole ?? this.userRole,
      currentScreen: currentScreen ?? this.currentScreen,
      reportStep: reportStep ?? this.reportStep,
      selectedComplaintId: selectedComplaintId ?? this.selectedComplaintId,
      selectedTicketNumber: selectedTicketNumber ?? this.selectedTicketNumber,
      complaintStatus: complaintStatus ?? this.complaintStatus,
      complaintCategory: complaintCategory ?? this.complaintCategory,
      wardId: wardId ?? this.wardId,
      departmentId: departmentId ?? this.departmentId,
      verificationStage: verificationStage ?? this.verificationStage,
      evidenceVerificationStatus:
          evidenceVerificationStatus ?? this.evidenceVerificationStatus,
      departmentVerificationStatus:
          departmentVerificationStatus ?? this.departmentVerificationStatus,
      hasJuniorEngineerAssigned:
          hasJuniorEngineerAssigned ?? this.hasJuniorEngineerAssigned,
      assignedJuniorEngineerName:
          assignedJuniorEngineerName ?? this.assignedJuniorEngineerName,
      hasFieldOfficerAssigned:
          hasFieldOfficerAssigned ?? this.hasFieldOfficerAssigned,
      assignedFieldOfficerName:
          assignedFieldOfficerName ?? this.assignedFieldOfficerName,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedReason: blockedReason ?? this.blockedReason,
      reopenCount: reopenCount ?? this.reopenCount,
      reopenReason: reopenReason ?? this.reopenReason,
      syncState: syncState ?? this.syncState,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isGovernmentUser: isGovernmentUser ?? this.isGovernmentUser,
      selectedMapFeatureType:
          selectedMapFeatureType ?? this.selectedMapFeatureType,
    );
  }

  /// Empty / default unauthenticated context.
  static const AssistantAppContext empty = AssistantAppContext();
}
