import '../../models/complaint_model.dart';
import '../models/assistant_app_context.dart';

/// Central privacy-safe mapper converting [ComplaintModel] to [AssistantAppContext].
///
/// Implements Phase 5 Zero-PII Context Sanitization:
/// - Maps ONLY explicitly approved lifecycle fields, public snapshots, and municipal codes.
/// - Strictly scrubs citizen UIDs, civil servant credentials, private storage URLs, OTPs, and passwords.
/// - Operates 100% in-memory without duplicate Firestore queries.
class ComplaintToAssistantContextMapper {
  /// Transforms a [ComplaintModel] into a sanitized, safe [AssistantAppContext].
  static AssistantAppContext mapFromComplaint(
    ComplaintModel complaint, {
    String currentScreen = 'complaintDetails',
    String selectedLanguage = 'en',
    String userRole = 'citizen',
    String? reportStep,
    String? selectedMapFeatureType,
  }) {
    // 1. Resolve normalized status label
    String normalizedStatus;
    if (complaint.status == ComplaintStatus.inProgress && complaint.reopenCount > 0) {
      normalizedStatus = 'reopened';
    } else {
      normalizedStatus = complaint.status.name;
    }

    // 2. Resolve clean ward display / code
    String? cleanWard = complaint.wardId;
    if (cleanWard != null) {
      cleanWard = cleanWard.replaceFirst('ward_', '').toUpperCase();
      if (cleanWard.contains('_')) {
        cleanWard = cleanWard.replaceAll('_', '/');
      }
    }

    // 3. Resolve clean category
    final categoryDisplayName = complaint.category.name;

    // 4. Resolve clean department
    final departmentName = complaint.effectiveDepartment;

    // 5. Resolve assignment state and safe public snapshots (Zero UIDs)
    final hasJe = complaint.isJuniorEngineerAssigned;
    final jeSnapshot = complaint.assignedJuniorEngineerNameSnapshot;

    final hasFo = complaint.assignedFieldOfficerId != null &&
        complaint.assignedFieldOfficerId!.isNotEmpty;
    final foSnapshot = complaint.assignedFieldOfficerNameSnapshot;

    // 6. Resolve obstacle / blocked state
    final isBlocked = complaint.blockedAt != null ||
        (complaint.blockedReason != null && complaint.blockedReason!.trim().isNotEmpty);
    final blockedReason = isBlocked ? complaint.blockedReason : null;

    // 7. Resolve rework state
    final reopenCount = complaint.reopenCount;
    final reopenReason = reopenCount > 0 ? complaint.reopenReason : null;

    // 8. Resolve sync state
    String syncStateStr;
    switch (complaint.syncStatus) {
      case SyncStatus.pending:
        syncStateStr = 'pending';
        break;
      case SyncStatus.failed:
        syncStateStr = 'failed';
        break;
      case SyncStatus.synced:
      case SyncStatus.syncing:
        syncStateStr = 'synced';
        break;
    }

    return AssistantAppContext(
      userRole: userRole,
      currentScreen: currentScreen,
      reportStep: reportStep,
      selectedComplaintId: complaint.id,
      selectedTicketNumber: complaint.ticketNumber,
      complaintStatus: normalizedStatus,
      complaintCategory: categoryDisplayName,
      wardId: cleanWard,
      departmentId: departmentName,
      verificationStage: complaint.verificationStage,
      evidenceVerificationStatus: complaint.evidenceVerificationStatus,
      departmentVerificationStatus: complaint.departmentVerificationStatus,
      hasJuniorEngineerAssigned: hasJe,
      assignedJuniorEngineerName: jeSnapshot,
      hasFieldOfficerAssigned: hasFo,
      assignedFieldOfficerName: foSnapshot,
      isBlocked: isBlocked,
      blockedReason: blockedReason,
      reopenCount: reopenCount,
      reopenReason: reopenReason,
      syncState: syncStateStr,
      selectedLanguage: selectedLanguage,
      isGovernmentUser: userRole != 'citizen',
      selectedMapFeatureType: selectedMapFeatureType,
    );
  }

  /// Creates a context for non-complaint screens (Home, Map, Report Issue, Profile).
  static AssistantAppContext mapForScreen({
    required String screenName,
    String? reportStep,
    String? selectedMapFeatureType,
    String selectedLanguage = 'en',
    String userRole = 'citizen',
  }) {
    return AssistantAppContext(
      userRole: userRole,
      currentScreen: screenName,
      reportStep: reportStep,
      selectedMapFeatureType: selectedMapFeatureType,
      selectedLanguage: selectedLanguage,
      isGovernmentUser: userRole != 'citizen',
    );
  }
}
