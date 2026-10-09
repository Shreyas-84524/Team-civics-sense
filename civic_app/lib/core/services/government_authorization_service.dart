import '../models/complaint_model.dart';
import '../models/complaint_routing_ticket_model.dart';
import '../../Govt UI/models/govt_user_model.dart';
import 'government_hierarchy_repository.dart';

/// BMC Government Role-Based Access Control (RBAC) & Authorization Service.
///
/// Implements strict matrix authorization rules for administrative actions,
/// wrong-department reassignment tickets, crew assignments, and grievance visibility.
class GovernmentAuthorizationService {
  final GovernmentHierarchyRepository _hierarchyRepo;

  GovernmentAuthorizationService({GovernmentHierarchyRepository? hierarchyRepo})
      : _hierarchyRepo = hierarchyRepo ?? LocalGovernmentHierarchyRepository();

  /// Validates whether [user] can raise a wrong-department reassignment ticket for [complaint].
  /// Only the assigned Ward Department Lead (or Super Admin override) can raise a ticket.
  bool canRaiseReassignmentTicket(GovtUserModel user, ComplaintModel complaint) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    if (!user.isWardLead) return false;

    // Must match complaint ward and department
    final complaintWard = complaint.wardId ?? complaint.location.ward;
    final complaintDept = complaint.assignedDepartmentId ?? complaint.category.id;

    final wardMatches = user.wardId != null &&
        complaintWard != null &&
        user.wardId!.trim().toLowerCase() == complaintWard.trim().toLowerCase();

    final deptMatches = user.departmentId != null &&
        complaintDept.trim().toLowerCase().contains(user.departmentId!.trim().toLowerCase());

    return wardMatches && deptMatches;
  }

  /// Validates whether [user] can approve or reject a wrong-department [ticket].
  /// Only the responsible Ward Officer of that ward (or Super Admin override) has authority.
  bool canReviewRoutingTicket(GovtUserModel user, ComplaintRoutingTicket ticket) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    if (!user.isWardOfficer) return false;

    // Must be Ward Officer for the ticket's ward
    return user.wardId != null &&
        ticket.wardId.isNotEmpty &&
        user.wardId!.trim().toLowerCase() == ticket.wardId.trim().toLowerCase();
  }

  /// Validates whether [user] can assign a crew technician to [complaint].
  /// Only the assigned Ward Department Lead (or Super Admin) can assign crew members.
  bool canAssignCrew(GovtUserModel user, ComplaintModel complaint) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    if (!user.isWardLead) return false;

    final complaintWard = complaint.wardId ?? complaint.location.ward;
    final complaintDept = complaint.assignedDepartmentId ?? complaint.category.id;

    final wardMatches = user.wardId != null &&
        complaintWard != null &&
        user.wardId!.trim().toLowerCase() == complaintWard.trim().toLowerCase();

    final deptMatches = user.departmentId != null &&
        complaintDept.trim().toLowerCase().contains(user.departmentId!.trim().toLowerCase());

    return wardMatches && deptMatches;
  }

  /// Validates whether [user] can assign a Field Officer to [complaint].
  /// The assigned Junior Engineer (or Lead / Super Admin) has authority to assign field officers.
  bool canAssignFieldOfficer(GovtUserModel user, ComplaintModel complaint) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    if (user.isCrew) {
      return complaint.assignedCrewMemberId == user.employeeId ||
          complaint.assignedCrewMemberId == user.id ||
          complaint.assignedTo == user.fullName;
    }

    if (user.isWardLead) {
      return canAssignCrew(user, complaint);
    }

    return false;
  }

  /// Validates whether [user] can start field execution on [complaint].
  /// Strictly the assigned Field Officer (or Super Admin).
  bool canStartFieldWork(GovtUserModel user, ComplaintModel complaint) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    if (complaint.assignedFieldOfficerId != null &&
        complaint.assignedFieldOfficerId!.trim().isNotEmpty) {
      final cleanFO = complaint.assignedFieldOfficerId!.trim().toUpperCase();
      return cleanFO == user.employeeId.trim().toUpperCase() ||
          cleanFO == user.id.trim().toUpperCase();
    }

    // Legacy single-crew fallback (when no dedicated field officer is assigned)
    if (user.isCrew) {
      final cleanCrew = complaint.assignedCrewMemberId?.trim().toUpperCase();
      return (cleanCrew != null &&
              (cleanCrew == user.employeeId.trim().toUpperCase() ||
                  cleanCrew == user.id.trim().toUpperCase())) ||
          (complaint.assignedTo != null &&
              complaint.assignedTo!.trim().toLowerCase() ==
                  user.fullName.trim().toLowerCase());
    }

    return false;
  }

  /// Validates whether [user] can submit work resolution evidence and close [complaint].
  /// Strictly the assigned Field Officer (or Super Admin).
  bool canSubmitFieldResolution(GovtUserModel user, ComplaintModel complaint) {
    return canStartFieldWork(user, complaint);
  }

  /// Validates whether [user] can report an operational blockage or on-site issue.
  /// Strictly the assigned Field Officer (or assigned crew member / Super Admin).
  bool canReportFieldObstacle(GovtUserModel user, ComplaintModel complaint) {
    return canStartFieldWork(user, complaint);
  }

  /// Validates whether [user] can resume field rework.
  /// Strictly the assigned Field Officer (or assigned crew member / Super Admin).
  bool canResumeFieldWork(GovtUserModel user, ComplaintModel complaint) {
    return canStartFieldWork(user, complaint);
  }

  /// Validates whether [user] can reopen an improperly resolved [complaint].
  /// Ward Department Leads, Ward Officers, Central HODs, and Super Admins have quality-control reopen authority.
  bool canReopenComplaint(GovtUserModel user, ComplaintModel complaint) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    final complaintWard = complaint.wardId ?? complaint.location.ward;
    final complaintDept = complaint.assignedDepartmentId ?? complaint.category.id;

    if (user.isWardLead) {
      final wardMatches = user.wardId != null &&
          complaintWard != null &&
          user.wardId!.trim().toLowerCase() == complaintWard.trim().toLowerCase();
      final deptMatches = user.departmentId != null &&
          complaintDept.trim().toLowerCase().contains(user.departmentId!.trim().toLowerCase());
      return wardMatches && deptMatches;
    }

    if (user.isWardOfficer) {
      return user.wardId != null &&
          complaintWard != null &&
          user.wardId!.trim().toLowerCase() == complaintWard.trim().toLowerCase();
    }

    if (user.isCentralHod) {
      return user.departmentId != null &&
          complaintDept.toLowerCase().contains(user.departmentId!.toLowerCase());
    }

    return false;
  }

  /// Validates whether [user] can submit work resolution evidence.
  bool canSubmitResolution(GovtUserModel user, ComplaintModel complaint) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    if (user.isCrew) {
      final isFO = complaint.assignedFieldOfficerId == user.employeeId ||
          complaint.assignedFieldOfficerId == user.id;
      final isJE = complaint.assignedCrewMemberId == user.employeeId ||
          complaint.assignedCrewMemberId == user.id ||
          complaint.assignedTo == user.fullName;
      return isFO || isJE;
    }

    if (user.isWardLead) {
      return canAssignCrew(user, complaint);
    }

    return false;
  }

  /// Validates whether [user] can verify and close a complaint.
  bool canVerifyResolution(GovtUserModel user, ComplaintModel complaint) {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    if (user.isWardLead) {
      return canAssignCrew(user, complaint);
    }

    if (user.isWardOfficer) {
      final complaintWard = complaint.wardId ?? complaint.location.ward;
      return user.wardId != null &&
          complaintWard != null &&
          user.wardId!.trim().toLowerCase() == complaintWard.trim().toLowerCase();
    }

    return false;
  }

  /// Validates whether [user] has read visibility for [complaint] based on matrix jurisdiction.
  Future<bool> canViewComplaint(GovtUserModel user, ComplaintModel complaint) async {
    if (user.isSuperAdmin || user.hasPermission('admin_override')) {
      return true;
    }

    final complaintWard = complaint.wardId ?? complaint.location.ward;
    final complaintDept = complaint.assignedDepartmentId ?? complaint.category.id;

    // 1. Zonal DMC: can view all complaints in their zone's wards
    if (user.isZonalDmc) {
      if (user.zoneId == null || complaintWard == null) return false;
      final wards = await _hierarchyRepo.getWards(zoneId: user.zoneId);
      final wardIds = wards.map((w) => w.wardId.toLowerCase()).toSet();
      return wardIds.contains(complaintWard.toLowerCase());
    }

    // 2. Central Department HOD: can view all complaints in their department across all 24 wards
    if (user.isCentralHod) {
      if (user.departmentId == null) return false;
      return complaintDept.toLowerCase().contains(user.departmentId!.toLowerCase());
    }

    // 3. Ward Officer: can view all complaints in their administrative ward
    if (user.isWardOfficer) {
      if (user.wardId == null || complaintWard == null) return false;
      return user.wardId!.toLowerCase() == complaintWard.toLowerCase();
    }

    // 4. Ward Department Lead: can view complaints in their ward AND department
    if (user.isWardLead) {
      if (user.wardId == null || complaintWard == null || user.departmentId == null) return false;
      return user.wardId!.toLowerCase() == complaintWard.toLowerCase() &&
          complaintDept.toLowerCase().contains(user.departmentId!.toLowerCase());
    }

    // 5. Department Crew: can view assigned work (as JE or FO) or unit complaints
    if (user.isCrew) {
      if (complaint.assignedCrewMemberId == user.employeeId ||
          complaint.assignedCrewMemberId == user.id ||
          complaint.assignedFieldOfficerId == user.employeeId ||
          complaint.assignedFieldOfficerId == user.id ||
          complaint.assignedTo == user.fullName) {
        return true;
      }
      if (user.wardId == null || complaintWard == null || user.departmentId == null) return false;
      return user.wardId!.toLowerCase() == complaintWard.toLowerCase() &&
          complaintDept.toLowerCase().contains(user.departmentId!.toLowerCase());
    }

    return false;
  }

  /// Filters a list of complaints to only those visible to [user].
  Future<List<ComplaintModel>> filterVisibleComplaints(
    GovtUserModel user,
    List<ComplaintModel> complaints,
  ) async {
    if (user.isSuperAdmin) return complaints;

    final List<ComplaintModel> visible = [];
    for (final c in complaints) {
      if (await canViewComplaint(user, c)) {
        visible.add(c);
      }
    }
    return visible;
  }
}
