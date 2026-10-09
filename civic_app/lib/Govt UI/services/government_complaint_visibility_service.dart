import '../../core/models/complaint_model.dart';
import '../../core/models/complaint_routing_ticket_model.dart';
import '../../core/services/government_authorization_service.dart';
import '../../core/services/government_hierarchy_repository.dart';
import '../models/govt_user_model.dart';
import 'government_department_dashboard_service.dart';
import 'government_ward_dashboard_service.dart';

/// Supported operational actions on a Civic Grievance.
enum GovernmentComplaintAction {
  verify,
  flag,
  assignCrew,
  reassignCrew,
  assignFieldOfficer,
  raiseWrongDepartment,
  approveRouting,
  rejectRouting,
  startWork,
  submitCompletion,
  verifyCompletion,
  returnForRework,
  escalate,
  viewOnly,
}

extension GovernmentComplaintActionExt on GovernmentComplaintAction {
  String get label {
    switch (this) {
      case GovernmentComplaintAction.verify:
        return 'Verify';
      case GovernmentComplaintAction.flag:
        return 'Flag / Review';
      case GovernmentComplaintAction.assignCrew:
        return 'Assign Crew';
      case GovernmentComplaintAction.reassignCrew:
        return 'Reassign Crew';
      case GovernmentComplaintAction.assignFieldOfficer:
        return 'Assign Execution Officer';
      case GovernmentComplaintAction.raiseWrongDepartment:
        return 'Raise Wrong Dept';
      case GovernmentComplaintAction.approveRouting:
        return 'Approve Routing';
      case GovernmentComplaintAction.rejectRouting:
        return 'Reject Routing';
      case GovernmentComplaintAction.startWork:
        return 'Start Work';
      case GovernmentComplaintAction.submitCompletion:
        return 'Submit Completion';
      case GovernmentComplaintAction.verifyCompletion:
        return 'Verify & Close';
      case GovernmentComplaintAction.returnForRework:
        return 'Return for Rework';
      case GovernmentComplaintAction.escalate:
        return 'Escalate SLA';
      case GovernmentComplaintAction.viewOnly:
        return 'View Only';
    }
  }
}

/// Centralized service for validating complaint visibility, jurisdiction, and action permissions.
class GovernmentComplaintVisibilityService {
  final GovernmentHierarchyRepository _hierarchyRepo;
  final GovernmentAuthorizationService _authService;

  GovernmentComplaintVisibilityService({
    GovernmentHierarchyRepository? hierarchyRepo,
    GovernmentAuthorizationService? authService,
  })  : _hierarchyRepo = hierarchyRepo ?? LocalGovernmentHierarchyRepository(),
        _authService = authService ??
            GovernmentAuthorizationService(
              hierarchyRepo: hierarchyRepo ?? LocalGovernmentHierarchyRepository(),
            );

  /// Validates whether [user] can view [complaint] under municipal jurisdiction.
  Future<bool> canViewComplaint({
    required GovtUserModel user,
    required ComplaintModel complaint,
  }) async {
    // 1. Super Admin has citywide access
    if (user.isSuperAdmin ||
        user.hasPermission('admin_override') ||
        user.hasPermission('all')) {
      return true;
    }

    final complaintWard = complaint.wardId ?? complaint.location.ward;
    final complaintDept = complaint.assignedDepartmentId ?? complaint.category.id;

    // 2. Zonal DMC: access to all wards within their assigned zone
    if (user.isZonalDmc) {
      if (user.zoneId == null || complaintWard == null) return false;
      final wards = await _hierarchyRepo.getWards(zoneId: user.zoneId);
      final wardIds = wards.map((w) => w.wardId.toUpperCase()).toSet();
      final wardCodes = wards.map((w) => w.wardCode.toUpperCase()).toSet();
      final targetWard = complaintWard.toUpperCase();
      return wardIds.contains(targetWard) || wardCodes.contains(targetWard);
    }

    // 3. Central Department HOD: access to their department across all 24 wards
    if (user.isCentralHod) {
      if (user.departmentId == null) return false;
      return GovernmentDepartmentDashboardService.matchesDepartment(
        complaintDept,
        user.departmentId!,
      );
    }

    // 4. Ward Officer: access to all complaints within their administrative ward
    if (user.isWardOfficer) {
      if (user.wardId == null || complaintWard == null) return false;
      return GovernmentWardDashboardService.matchesWard(
        complaintWard,
        user.wardId!,
      );
    }

    // 5. Ward Department Lead: access strictly to their Ward × Department unit
    if (user.isWardLead) {
      if (user.wardId == null || complaintWard == null || user.departmentId == null) {
        return false;
      }
      final wardMatch = GovernmentWardDashboardService.matchesWard(
        complaintWard,
        user.wardId!,
      );
      final deptMatch = GovernmentDepartmentDashboardService.matchesDepartment(
        complaintDept,
        user.departmentId!,
      );
      return wardMatch && deptMatch;
    }

    // 6. Department Crew: access strictly to complaints assigned to this technician
    if (user.isCrew) {
      final isAssignedDirectly = (complaint.assignedCrewMemberId != null &&
              (complaint.assignedCrewMemberId!.toUpperCase() == user.employeeId.toUpperCase() ||
                  complaint.assignedCrewMemberId!.toUpperCase() == user.id.toUpperCase())) ||
          (complaint.assignedTo != null &&
              complaint.assignedTo!.trim().isNotEmpty &&
              (complaint.assignedTo!.toLowerCase() == user.fullName.toLowerCase() ||
                  complaint.assignedTo!.toLowerCase().contains(user.employeeId.toLowerCase())));

      return isAssignedDirectly;
    }

    return false;
  }

  /// Filters a list of complaints to only those within [user]'s authoritative jurisdiction.
  Future<List<ComplaintModel>> filterComplaintsForUser({
    required GovtUserModel user,
    required List<ComplaintModel> complaints,
  }) async {
    if (user.isSuperAdmin) return complaints;

    final List<ComplaintModel> visible = [];
    for (final c in complaints) {
      if (await canViewComplaint(user: user, complaint: c)) {
        visible.add(c);
      }
    }
    return visible;
  }

  /// Evaluates permissible actions on [complaint] for [user] based on RBAC matrix and lifecycle state.
  Set<GovernmentComplaintAction> getPermittedActions({
    required GovtUserModel user,
    required ComplaintModel complaint,
    ComplaintRoutingTicket? activeTicket,
  }) {
    final actions = <GovernmentComplaintAction>{};

    // If complaint is closed, resolved or rejected
    final isClosedOrResolved = complaint.status == ComplaintStatus.closed ||
        complaint.status == ComplaintStatus.resolved;
    final isRejected = complaint.status == ComplaintStatus.rejected;

    if (isClosedOrResolved) {
      if (_authService.canReopenComplaint(user, complaint)) {
        actions.add(GovernmentComplaintAction.returnForRework);
      }
      if (actions.isEmpty) {
        actions.add(GovernmentComplaintAction.viewOnly);
      }
      return actions;
    }

    if (isRejected) {
      actions.add(GovernmentComplaintAction.viewOnly);
      return actions;
    }

    // 0. Reported Grievance Verification & Moderation (Super Admin, DMC, HOD, Ward Officer, Ward Lead)
    if (complaint.status == ComplaintStatus.reported) {
      if (user.isSuperAdmin ||
          user.isZonalDmc ||
          user.isCentralHod ||
          user.isWardOfficer ||
          user.isWardLead) {
        actions.add(GovernmentComplaintAction.verify);
        actions.add(GovernmentComplaintAction.flag);
      }
    }

    // 1. Crew Work Actions
    if (user.isCrew || user.isSuperAdmin) {
      if (user.isCrew &&
          _authService.canAssignFieldOfficer(user, complaint) &&
          complaint.assignedCrewMemberId != null &&
          complaint.assignedFieldOfficerId == null) {
        actions.add(GovernmentComplaintAction.assignFieldOfficer);
      }

      if (_authService.canStartFieldWork(user, complaint)) {
        if (complaint.status == ComplaintStatus.assigned) {
          actions.add(GovernmentComplaintAction.startWork);
        } else if (complaint.status == ComplaintStatus.inProgress) {
          actions.add(GovernmentComplaintAction.submitCompletion);
        }
      }
    }

    // 2. Ward Department Lead Actions & Crew Assignment
    if (user.isWardLead ||
        user.isSuperAdmin ||
        user.isWardOfficer ||
        user.hasPermission('assign_officer')) {
      final canOperateUnit = user.isSuperAdmin ||
          user.hasPermission('assign_officer') ||
          _authService.canAssignCrew(user, complaint);

      if (canOperateUnit) {
        // Crew Assignment / Reassignment
        if (complaint.assignedCrewMemberId == null ||
            complaint.assignedCrewMemberId!.trim().isEmpty) {
          actions.add(GovernmentComplaintAction.assignCrew);
        } else {
          actions.add(GovernmentComplaintAction.reassignCrew);
        }

        // Raise Wrong Department Reassignment
        if (_authService.canRaiseReassignmentTicket(user, complaint)) {
          actions.add(GovernmentComplaintAction.raiseWrongDepartment);
        }

        // Verification of Work / Return for Rework
        final isAwaitingVerification = complaint.status == ComplaintStatus.verified ||
            (complaint.officerNotes != null &&
                complaint.officerNotes!.toLowerCase().contains('submitted for'));

        if (isAwaitingVerification && _authService.canVerifyResolution(user, complaint)) {
          actions.add(GovernmentComplaintAction.verifyCompletion);
          actions.add(GovernmentComplaintAction.returnForRework);
        }
      }
    }

    // 3. Ward Officer Actions (Routing Approval & Administrative Verification)
    if (user.isWardOfficer || user.isSuperAdmin) {
      final complaintWard = complaint.wardId ?? complaint.location.ward;
      final isWardMatch = user.isSuperAdmin ||
          (user.wardId != null &&
              complaintWard != null &&
              GovernmentWardDashboardService.matchesWard(complaintWard, user.wardId!));

      if (isWardMatch) {
        // Routing Ticket Adjudication
        if (activeTicket != null && activeTicket.isPending) {
          actions.add(GovernmentComplaintAction.approveRouting);
          actions.add(GovernmentComplaintAction.rejectRouting);
        }

        // Can also verify resolution if awaiting verification
        if (complaint.status == ComplaintStatus.verified) {
          actions.add(GovernmentComplaintAction.verifyCompletion);
          actions.add(GovernmentComplaintAction.returnForRework);
        }
      }
    }

    // 4. Supervisory Escalation (DMC, HOD, Super Admin, Ward Officer)
    final isSupervisory = user.isZonalDmc || user.isCentralHod || user.isSuperAdmin || user.isWardOfficer;
    if (isSupervisory) {
      actions.add(GovernmentComplaintAction.escalate);
    }

    if (actions.isEmpty) {
      actions.add(GovernmentComplaintAction.viewOnly);
    }

    return actions;
  }
}
