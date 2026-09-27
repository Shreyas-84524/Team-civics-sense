import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/civic_department_model.dart';
import '../../core/models/civic_ward_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/government_audit_log_model.dart';
import '../../core/models/hazard_model.dart';
import '../../core/repositories/hazard_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/services/complaint_routing_service.dart';
import '../../core/services/government_audit_service.dart';
import '../../core/services/government_authorization_service.dart';
import '../../core/services/government_hierarchy_repository.dart';
import '../models/govt_user_model.dart';
import 'government_department_dashboard_service.dart';
import 'government_department_lead_dashboard_service.dart';
import 'government_ward_dashboard_service.dart';
import 'govt_complaint_repository.dart';

/// Top summary metrics for the field technician / crew workspace.
class CrewKpiMetrics {
  final int assignedToday;
  final int inProgressCount;
  final int criticalCount;
  final int slaAtRiskCount;
  final int awaitingReviewCount;
  final int completedToday;
  final int totalAssignedCount;

  const CrewKpiMetrics({
    required this.assignedToday,
    required this.inProgressCount,
    required this.criticalCount,
    required this.slaAtRiskCount,
    required this.awaitingReviewCount,
    required this.completedToday,
    required this.totalAssignedCount,
  });
}

/// Operational field job item representation for a single assigned grievance.
class CrewJobItem {
  final ComplaintModel complaint;
  final double distanceKm;
  final bool isReturnedForRework;
  final String? reworkReason;
  final SlaHealthState slaState;
  final double remainingHours;
  final double overdueHours;
  final double elapsedHours;
  final DateTime assignedAt;

  const CrewJobItem({
    required this.complaint,
    this.distanceKm = 1.2,
    this.isReturnedForRework = false,
    this.reworkReason,
    required this.slaState,
    required this.remainingHours,
    required this.overdueHours,
    required this.elapsedHours,
    required this.assignedAt,
  });

  String get id => complaint.id;
  String get ticketNumber =>
      complaint.ticketNumber.isNotEmpty ? complaint.ticketNumber : complaint.id;
  String get title => complaint.title;
  String get description => complaint.description;
  ComplaintPriority get priority => complaint.priority;
  ComplaintStatus get status => complaint.status;
  String get address => complaint.location.address;
  String? get landmark => complaint.location.landmark;
  String get ward => complaint.location.ward ?? complaint.wardId ?? 'N';
  String get department => complaint.effectiveDepartment;
  List<String> get citizenImageUrls => complaint.imageUrls;

  bool get canStart =>
      status == ComplaintStatus.assigned || status == ComplaintStatus.reported;

  bool get canSubmitCompletion => status == ComplaintStatus.inProgress;

  bool get isAwaitingVerification =>
      status == ComplaintStatus.verified ||
      (status == ComplaintStatus.inProgress &&
          complaint.officerNotes != null &&
          complaint.officerNotes!.toLowerCase().contains('completion'));

  bool get isCompleted => status == ComplaintStatus.resolved;

  String get formattedDistance =>
      distanceKm < 1.0 ? '${(distanceKm * 1000).toInt()} m' : '${distanceKm.toStringAsFixed(1)} km';
}

/// Complete Master Workspace Dataset for Department Crew Member.
class CrewWorkdeskData {
  final GovtUserModel crewUser;
  final CivicWard ward;
  final CivicDepartment department;
  final CrewKpiMetrics kpiMetrics;
  final List<CrewJobItem> allMyJobs;
  final List<CrewJobItem> inProgressJobs;
  final List<CrewJobItem> awaitingReviewJobs;
  final List<CrewJobItem> completedJobs;
  final List<CrewJobItem> criticalJobs;
  final List<CrewJobItem> filteredJobs;
  final List<HazardModel> crewHazards;
  final List<GovernmentAuditLog> myActivityLogs;
  final DateTime lastRefreshedAt;

  const CrewWorkdeskData({
    required this.crewUser,
    required this.ward,
    required this.department,
    required this.kpiMetrics,
    required this.allMyJobs,
    required this.inProgressJobs,
    required this.awaitingReviewJobs,
    required this.completedJobs,
    required this.criticalJobs,
    required this.filteredJobs,
    required this.crewHazards,
    required this.myActivityLogs,
    required this.lastRefreshedAt,
  });
}

/// Domain Service providing complete operational handling strictly scoped to
/// the authenticated crew technician's assigned tasks (Ward × Department × Crew Member).
class GovernmentCrewWorkService {
  final GovtComplaintRepository _complaintRepo;
  final GovernmentHierarchyRepository _hierarchyRepo;
  final ComplaintRoutingService _routingService;
  final GovernmentAuditService _auditService;
  final GovernmentAuthorizationService _authService;
  final HazardRepository _hazardRepo;

  GovernmentCrewWorkService({
    GovtComplaintRepository? complaintRepo,
    GovernmentHierarchyRepository? hierarchyRepo,
    ComplaintRoutingService? routingService,
    GovernmentAuditService? auditService,
    GovernmentAuthorizationService? authService,
    HazardRepository? hazardRepo,
  })  : _complaintRepo = complaintRepo ?? RepositoryLocator.govtComplaintRepository,
        _hierarchyRepo = hierarchyRepo ?? LocalGovernmentHierarchyRepository(),
        _routingService = routingService ?? ComplaintRoutingService(),
        _auditService = auditService ?? DefaultGovernmentAuditService(),
        _authService = authService ??
            GovernmentAuthorizationService(
                hierarchyRepo: hierarchyRepo ?? LocalGovernmentHierarchyRepository()),
        _hazardRepo = hazardRepo ?? RepositoryLocator.hazardRepository;

  GovernmentAuditService getAuditService() => _auditService;
  GovernmentAuthorizationService getAuthService() => _authService;

  /// Master Loader for Department Crew Workdesk.
  /// Strictly enforces individual crew isolation by matching [crewId] and [user.employeeId].
  Future<CrewWorkdeskData> loadCrewWorkdesk({
    required String crewId,
    required String wardId,
    required String departmentId,
    ComplaintPriority? priorityFilter,
    ComplaintStatus? statusFilter,
    String? slaFilter,
    String? searchQuery,
    String? activeTab, // 'all', 'in_progress', 'awaiting_review', 'completed', 'critical'
    DateTimeRange? dateRange,
  }) async {
    final cleanWardCode = GovernmentWardDashboardService.normalizeWardId(wardId);
    final cleanDeptId =
        GovernmentDepartmentDashboardService.normalizeDepartmentId(departmentId);
    final now = DateTime.now();

    // 1. Fetch Reference Data
    await _hierarchyRepo.initialize();
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    // 2. Resolve Ward & Department
    final ward = allWards.firstWhere(
      (w) =>
          GovernmentWardDashboardService.matchesWard(w.wardCode, cleanWardCode) ||
          GovernmentWardDashboardService.matchesWard(w.wardId, cleanWardCode),
      orElse: () => CivicWard(
        wardId: cleanWardCode,
        wardCode: cleanWardCode,
        wardName: '$cleanWardCode Ward',
        zoneId: 'ZONE_4',
        lat: 19.0760,
        lng: 72.8777,
        pincode: '400077',
      ),
    );

    final department = allDepartments.firstWhere(
      (d) => GovernmentDepartmentDashboardService.matchesDepartment(
          d.departmentId, cleanDeptId),
      orElse: () => CivicDepartment(
        departmentId: cleanDeptId,
        departmentCode: cleanDeptId.replaceAll('dept_', '').toUpperCase(),
        displayName: cleanDeptId.replaceAll('_', ' ').toUpperCase(),
        description: 'Municipal Department Operations Unit',
        defaultLeadDesignation: 'Executive Engineer',
      ),
    );

    // 3. Resolve Crew User Profile
    final cleanCrewId = crewId.trim().toUpperCase();
    final crewUser = allUsers.where(
      (u) =>
          u.employeeId.toUpperCase() == cleanCrewId ||
          u.id.toUpperCase() == cleanCrewId,
    ).firstOrNull ?? (cleanCrewId.isEmpty
        ? allUsers.where(
            (u) =>
                u.isCrew &&
                GovernmentWardDashboardService.matchesWard(u.wardId, cleanWardCode) &&
                GovernmentDepartmentDashboardService.matchesDepartment(
                    u.departmentId, cleanDeptId),
          ).firstOrNull
        : null) ?? GovtUserModel(
      id: cleanCrewId,
      employeeId: cleanCrewId,
      fullName: 'Field Technician ($cleanWardCode-${department.displayName})',
      email: 'crew.${cleanDeptId.toLowerCase()}.${cleanWardCode.toLowerCase()}@mcgm.gov.in',
      role: 'department_crew',
      wardId: cleanWardCode,
      departmentId: department.departmentId,
      departmentName: department.displayName,
      displayDesignation: 'Junior Engineer / Ground Technician',
      phone: '+91 98765 43201',
      active: true,
    );

    // 4. Fetch Complaints & Apply STRICT CREW ISOLATION
    final allRawComplaints = await _complaintRepo.getComplaints();
    final assignedComplaints = allRawComplaints.where((c) {
      // 1. Crew Isolation: Complaint must be assigned directly to THIS technician
      final matchCrewId = c.assignedCrewMemberId != null &&
          (c.assignedCrewMemberId!.toUpperCase() == crewUser.employeeId.toUpperCase() ||
              c.assignedCrewMemberId!.toUpperCase() == crewUser.id.toUpperCase());

      final matchCrewName = c.assignedTo != null &&
          c.assignedTo!.trim().isNotEmpty &&
          (c.assignedTo!.toLowerCase() == crewUser.fullName.toLowerCase() ||
              c.assignedTo!.toLowerCase().contains(crewUser.employeeId.toLowerCase()));

      if (!matchCrewId && !matchCrewName) {
        return false;
      }

      // 2. Ward & Department Isolation
      final cWard = c.wardId ?? c.location.ward;
      final cDept = c.assignedDepartmentId ?? c.category.id;

      final wardMatches = cWard == null ||
          GovernmentWardDashboardService.matchesWard(cWard, cleanWardCode);
      final deptMatches = cDept.isEmpty ||
          GovernmentDepartmentDashboardService.matchesDepartment(cDept, cleanDeptId);

      return wardMatches && deptMatches;
    }).toList();

    // Register assigned complaints into routing cache for state resilience
    for (final c in assignedComplaints) {
      _routingService.registerComplaint(c);
    }

    // 5. Build CrewJobItem representations
    final List<CrewJobItem> allJobItems = [];
    final List<CrewJobItem> inProgressItems = [];
    final List<CrewJobItem> awaitingReviewItems = [];
    final List<CrewJobItem> completedItems = [];
    final List<CrewJobItem> criticalItems = [];

    int assignedTodayCount = 0;
    int completedTodayCount = 0;
    int criticalCount = 0;
    int slaAtRiskCount = 0;

    final startOfToday = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < assignedComplaints.length; i++) {
      final c = assignedComplaints[i];

      // SLA Calculations
      final elapsed = now.difference(c.slaStartedAt).inHours.toDouble();
      final totalAllowed = c.priority == ComplaintPriority.emergency
          ? 24.0
          : (c.priority == ComplaintPriority.high ? 36.0 : 48.0);
      final remaining = (totalAllowed - elapsed).clamp(-999.0, totalAllowed);
      final isBreached = elapsed > totalAllowed;
      final isAtRisk = !isBreached && remaining <= 8.0;

      SlaHealthState slaState;
      if (isBreached) {
        slaState = SlaHealthState.breached;
      } else if (isAtRisk) {
        slaState = SlaHealthState.atRisk;
        if (c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected) {
          slaAtRiskCount++;
        }
      } else {
        slaState = SlaHealthState.healthy;
      }

      // Rework detection
      final isReturnedForRework = c.status == ComplaintStatus.inProgress &&
          c.officerNotes != null &&
          (c.officerNotes!.toLowerCase().contains('rework') ||
              c.officerNotes!.toLowerCase().contains('defect'));

      // Distance estimation (deterministic per complaint)
      final distance = 0.5 + ((c.id.hashCode.abs() % 45) / 10.0);

      final jobItem = CrewJobItem(
        complaint: c,
        distanceKm: distance,
        isReturnedForRework: isReturnedForRework,
        reworkReason: isReturnedForRework ? c.officerNotes : null,
        slaState: slaState,
        remainingHours: remaining,
        overdueHours: isBreached ? (elapsed - totalAllowed) : 0.0,
        elapsedHours: elapsed,
        assignedAt: c.currentDepartmentAssignedAt ?? c.createdAt,
      );

      allJobItems.add(jobItem);

      // Category / Status Bucketing
      if (c.createdAt.isAfter(startOfToday) ||
          (c.currentDepartmentAssignedAt != null &&
              c.currentDepartmentAssignedAt!.isAfter(startOfToday))) {
        assignedTodayCount++;
      }

      if (c.priority == ComplaintPriority.emergency ||
          c.priority == ComplaintPriority.high) {
        criticalItems.add(jobItem);
        if (c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected) {
          criticalCount++;
        }
      }

      if (c.status == ComplaintStatus.inProgress) {
        inProgressItems.add(jobItem);
      } else if (c.status == ComplaintStatus.verified ||
          (c.status == ComplaintStatus.inProgress &&
              c.officerNotes != null &&
              c.officerNotes!.toLowerCase().contains('completion'))) {
        awaitingReviewItems.add(jobItem);
      } else if (c.status == ComplaintStatus.resolved) {
        completedItems.add(jobItem);
        final resDate = c.resolvedAt ?? c.updatedAt;
        if (resDate.isAfter(startOfToday)) {
          completedTodayCount++;
        }
      }
    }

    // Deterministic Sorting: Critical first -> High Priority -> SLA Risk -> Oldest Assigned
    allJobItems.sort((a, b) {
      // 1. Critical Emergency first
      if (a.priority == ComplaintPriority.emergency &&
          b.priority != ComplaintPriority.emergency) {
        return -1;
      }
      if (b.priority == ComplaintPriority.emergency &&
          a.priority != ComplaintPriority.emergency) {
        return 1;
      }

      // 2. High Priority next
      if (a.priority == ComplaintPriority.high &&
          b.priority != ComplaintPriority.high) {
        return -1;
      }
      if (b.priority == ComplaintPriority.high &&
          a.priority != ComplaintPriority.high) {
        return 1;
      }

      // 3. SLA Breached / At Risk
      if (a.slaState == SlaHealthState.breached &&
          b.slaState != SlaHealthState.breached) {
        return -1;
      }
      if (b.slaState == SlaHealthState.breached &&
          a.slaState != SlaHealthState.breached) {
        return 1;
      }

      // 4. Oldest Assigned first
      return a.complaint.createdAt.compareTo(b.complaint.createdAt);
    });

    // 6. Compute KPI Metrics
    final kpiMetrics = CrewKpiMetrics(
      assignedToday: assignedTodayCount,
      inProgressCount: inProgressItems.length,
      criticalCount: criticalCount,
      slaAtRiskCount: slaAtRiskCount,
      awaitingReviewCount: awaitingReviewItems.length,
      completedToday: completedTodayCount,
      totalAssignedCount: allJobItems.length,
    );

    // 7. Apply Filter Criteria
    final filteredJobs = allJobItems.where((item) {
      final c = item.complaint;

      // Tab filter
      if (activeTab != null && activeTab.isNotEmpty && activeTab != 'all') {
        if (activeTab == 'in_progress' && c.status != ComplaintStatus.inProgress) {
          return false;
        }
        if (activeTab == 'awaiting_review' && !item.isAwaitingVerification) {
          return false;
        }
        if (activeTab == 'completed' && c.status != ComplaintStatus.resolved) {
          return false;
        }
        if (activeTab == 'critical' &&
            c.priority != ComplaintPriority.emergency &&
            c.priority != ComplaintPriority.high) {
          return false;
        }
      }

      // Priority filter
      if (priorityFilter != null && c.priority != priorityFilter) {
        return false;
      }

      // Status filter
      if (statusFilter != null && c.status != statusFilter) {
        return false;
      }

      // SLA filter
      if (slaFilter != null && slaFilter.isNotEmpty && slaFilter != 'all') {
        if (slaFilter == 'breached' && item.slaState != SlaHealthState.breached) {
          return false;
        }
        if (slaFilter == 'atRisk' && item.slaState != SlaHealthState.atRisk) {
          return false;
        }
        if (slaFilter == 'healthy' && item.slaState != SlaHealthState.healthy) {
          return false;
        }
      }

      // Date Range filter
      if (dateRange != null) {
        if (c.createdAt.isBefore(dateRange.start) ||
            c.createdAt.isAfter(dateRange.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Search Query filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchTicket = item.ticketNumber.toLowerCase().contains(q);
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        final matchAddress = item.address.toLowerCase().contains(q);

        if (!matchTicket && !matchTitle && !matchDesc && !matchAddress) {
          return false;
        }
      }

      return true;
    }).toList();

    // 8. Fetch Crew Hazards (Hazards corresponding to assigned complaints)
    final allHazards = await _hazardRepo.getHazards();
    final crewHazards = allHazards.where((h) {
      return assignedComplaints.any((c) =>
          h.complaintId == c.id ||
          (c.ticketNumber.isNotEmpty && h.ticketNumber == c.ticketNumber));
    }).toList();

    // 9. Fetch My Activity Logs (Audit logs where crew is the actor or complaint is assigned to them)
    final List<GovernmentAuditLog> myLogs = [];
    for (final c in assignedComplaints) {
      final logs = await _auditService.getLogsForComplaint(c.id);
      for (final log in logs) {
        final isMyActor = log.actorId.toUpperCase() == crewUser.employeeId.toUpperCase() ||
            log.actorId.toUpperCase() == crewUser.id.toUpperCase();
        final isMyComplaint = log.details['crewMemberId'] == crewUser.employeeId ||
            log.details['crewMemberName'] == crewUser.fullName;
        if (isMyActor || isMyComplaint) {
          myLogs.add(log);
        }
      }
    }
    myLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return CrewWorkdeskData(
      crewUser: crewUser,
      ward: ward,
      department: department,
      kpiMetrics: kpiMetrics,
      allMyJobs: allJobItems,
      inProgressJobs: inProgressItems,
      awaitingReviewJobs: awaitingReviewItems,
      completedJobs: completedItems,
      criticalJobs: criticalItems,
      filteredJobs: filteredJobs,
      crewHazards: crewHazards,
      myActivityLogs: myLogs,
      lastRefreshedAt: now,
    );
  }

  /// Starts field work on an assigned grievance.
  /// Transitions status from `assigned` -> `inProgress`.
  Future<ComplaintModel> startJob({
    required String complaintId,
    required String crewId,
  }) async {
    final complaint = await _complaintRepo.getComplaintById(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final crewUser = await _getUser(crewId);
    if (crewUser == null) {
      throw ArgumentError('Crew technician not found for ID: $crewId');
    }

    // Security check: Must be assigned to this crew member
    final isAssignedToCrew = complaint.assignedCrewMemberId == crewUser.employeeId ||
        complaint.assignedCrewMemberId == crewUser.id ||
        complaint.assignedTo == crewUser.fullName;

    if (!isAssignedToCrew && !crewUser.isSuperAdmin) {
      throw StateError(
          'Security Violation: Complaint $complaintId is not assigned to crew member ${crewUser.employeeId}.');
    }

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..insert(
        0,
        TimelineEvent(
          title: 'Work Started in Field',
          description:
              'Field technician ${crewUser.fullName} (${crewUser.displayDesignation}) has commenced work on site.',
          timestamp: DateTime.now(),
          status: ComplaintStatus.inProgress,
          updatedBy: crewUser.employeeId,
        ),
      );

    final updated = complaint.copyWith(
      status: ComplaintStatus.inProgress,
      timeline: updatedTimeline,
      updatedAt: DateTime.now(),
      // SLA Policy: Original creation timestamp and SLA clock are strictly PRESERVED
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    _routingService.registerComplaint(updated);

    await _complaintRepo.updateStatus(
      complaintId: complaint.id,
      nextStatus: ComplaintStatus.inProgress,
      updateMessage:
          'Field technician ${crewUser.fullName} commenced work on site.',
      officerName: crewUser.fullName,
    );

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.statusUpdated,
      actorId: crewUser.employeeId,
      actorRole: crewUser.role,
      actorName: crewUser.fullName,
      wardId: complaint.wardId,
      departmentId: complaint.assignedDepartmentId,
      details: {
        'action': 'work_started',
        'startedAt': DateTime.now().toIso8601String(),
      },
    );

    return updated;
  }

  /// Submits completed field work with Before, After (and optional During) photos and remarks.
  /// Transitions grievance to Awaiting Verification (`verified` status).
  ///
  /// CRITICAL ARCHITECTURAL RULE:
  /// The crew member DOES NOT finally resolve the complaint.
  /// Final resolution and certification belongs to the Ward Department Lead.
  Future<ComplaintModel> submitWorkCompletion({
    required String complaintId,
    required String crewId,
    required String beforePhotoUrl,
    required String afterPhotoUrl,
    String? duringPhotoUrl,
    required String workRemarks,
  }) async {
    if (beforePhotoUrl.trim().isEmpty) {
      throw ArgumentError('Before-work photo evidence is required.');
    }
    if (afterPhotoUrl.trim().isEmpty) {
      throw ArgumentError('After-work completion photo evidence is required.');
    }
    if (workRemarks.trim().isEmpty) {
      throw ArgumentError('Work performed description / remarks are required.');
    }

    final complaint = await _complaintRepo.getComplaintById(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final crewUser = await _getUser(crewId);
    if (crewUser == null) {
      throw ArgumentError('Crew technician not found for ID: $crewId');
    }

    // Security check
    final isAssignedToCrew = complaint.assignedCrewMemberId == crewUser.employeeId ||
        complaint.assignedCrewMemberId == crewUser.id ||
        complaint.assignedTo == crewUser.fullName;

    if (!isAssignedToCrew && !crewUser.isSuperAdmin) {
      throw StateError(
          'Security Violation: Crew member ${crewUser.employeeId} cannot submit completion for unassigned complaint $complaintId.');
    }

    final updatedImageUrls = List<String>.from(complaint.imageUrls);
    if (!updatedImageUrls.contains(beforePhotoUrl)) {
      updatedImageUrls.add(beforePhotoUrl);
    }
    if (duringPhotoUrl != null &&
        duringPhotoUrl.isNotEmpty &&
        !updatedImageUrls.contains(duringPhotoUrl)) {
      updatedImageUrls.add(duringPhotoUrl);
    }
    if (!updatedImageUrls.contains(afterPhotoUrl)) {
      updatedImageUrls.add(afterPhotoUrl);
    }

    final completionNote =
        'Field work completed by ${crewUser.fullName}. Remarks: $workRemarks. Submitted for Ward Department Lead verification.';

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..insert(
        0,
        TimelineEvent(
          title: 'Work Completed — Awaiting Lead Verification',
          description: completionNote,
          timestamp: DateTime.now(),
          status: ComplaintStatus.verified,
          updatedBy: crewUser.employeeId,
        ),
      );

    // Moves to verified / awaiting verification state.
    // NOTE: complaint.status is set to ComplaintStatus.verified (not resolved!).
    final updated = complaint.copyWith(
      status: ComplaintStatus.verified,
      imageUrls: updatedImageUrls,
      officerNotes: completionNote,
      timeline: updatedTimeline,
      updatedAt: DateTime.now(),
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    _routingService.registerComplaint(updated);

    await _complaintRepo.updateStatus(
      complaintId: complaint.id,
      nextStatus: ComplaintStatus.verified,
      updateMessage: completionNote,
      officerName: crewUser.fullName,
    );

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.statusUpdated,
      actorId: crewUser.employeeId,
      actorRole: crewUser.role,
      actorName: crewUser.fullName,
      wardId: complaint.wardId,
      departmentId: complaint.assignedDepartmentId,
      details: {
        'action': 'completion_submitted',
        'remarks': workRemarks,
        'beforePhoto': beforePhotoUrl,
        'afterPhoto': afterPhotoUrl,
        'submittedAt': DateTime.now().toIso8601String(),
      },
    );

    return updated;
  }

  /// Resumes work on a grievance returned for rework by the Ward Department Lead.
  Future<ComplaintModel> resumeWorkAfterRework({
    required String complaintId,
    required String crewId,
    String? remarks,
  }) async {
    final complaint = await _complaintRepo.getComplaintById(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final crewUser = await _getUser(crewId);
    if (crewUser == null) {
      throw ArgumentError('Crew technician not found for ID: $crewId');
    }

    final resumptionNote = remarks?.isNotEmpty == true
        ? 'Rework commenced: $remarks'
        : 'Field crew resumed rectification work on site.';

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..insert(
        0,
        TimelineEvent(
          title: 'Rework Resumed in Field',
          description: resumptionNote,
          timestamp: DateTime.now(),
          status: ComplaintStatus.inProgress,
          updatedBy: crewUser.employeeId,
        ),
      );

    final updated = complaint.copyWith(
      status: ComplaintStatus.inProgress,
      timeline: updatedTimeline,
      updatedAt: DateTime.now(),
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    _routingService.registerComplaint(updated);

    await _complaintRepo.updateStatus(
      complaintId: complaint.id,
      nextStatus: ComplaintStatus.inProgress,
      updateMessage: resumptionNote,
      officerName: crewUser.fullName,
    );

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.statusUpdated,
      actorId: crewUser.employeeId,
      actorRole: crewUser.role,
      actorName: crewUser.fullName,
      wardId: complaint.wardId,
      departmentId: complaint.assignedDepartmentId,
      details: {
        'action': 'rework_resumed',
        'notes': resumptionNote,
      },
    );

    return updated;
  }

  /// Reports an operational blockage or on-site issue (e.g. Site Inaccessible, Equipment Required).
  /// Records the note without changing the department or resolving the complaint.
  Future<ComplaintModel> reportBlockedIssue({
    required String complaintId,
    required String crewId,
    required String reasonCategory,
    required String details,
  }) async {
    final complaint = await _complaintRepo.getComplaintById(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    final crewUser = await _getUser(crewId);
    if (crewUser == null) {
      throw ArgumentError('Crew technician not found for ID: $crewId');
    }

    final blockageMessage =
        'Field Issue Reported: [$reasonCategory] - $details';

    final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
      ..insert(
        0,
        TimelineEvent(
          title: 'On-Site Issue Reported',
          description: blockageMessage,
          timestamp: DateTime.now(),
          status: complaint.status,
          updatedBy: crewUser.employeeId,
        ),
      );

    final updated = complaint.copyWith(
      officerNotes: blockageMessage,
      timeline: updatedTimeline,
      updatedAt: DateTime.now(),
      originalCreatedAt: complaint.originalCreatedAt,
      slaStartedAt: complaint.slaStartedAt,
    );

    _routingService.registerComplaint(updated);

    await _auditService.logAction(
      complaintId: complaint.id,
      action: GovernmentAuditActions.statusUpdated,
      actorId: crewUser.employeeId,
      actorRole: crewUser.role,
      actorName: crewUser.fullName,
      wardId: complaint.wardId,
      departmentId: complaint.assignedDepartmentId,
      details: {
        'action': 'issue_reported',
        'reasonCategory': reasonCategory,
        'details': details,
      },
    );

    return updated;
  }

  Future<GovtUserModel?> _getUser(String idOrEmployeeId, {ComplaintModel? complaint}) async {
    final user = await _hierarchyRepo.getUserByEmployeeId(idOrEmployeeId) ??
        await _hierarchyRepo.getUserById(idOrEmployeeId);
    if (user != null) return user;

    final allUsers = await _hierarchyRepo.getUsers();
    final cleanId = idOrEmployeeId.trim().toUpperCase();
    final matched = allUsers.where((u) =>
        u.employeeId.toUpperCase() == cleanId ||
        u.id.toUpperCase() == cleanId ||
        u.fullName.toLowerCase() == idOrEmployeeId.toLowerCase()).firstOrNull;
    if (matched != null) return matched;

    // Fallback constructed user for field crew operations
    return GovtUserModel(
      id: idOrEmployeeId,
      employeeId: idOrEmployeeId,
      fullName: (complaint?.assignedTo != null && complaint!.assignedTo!.isNotEmpty)
          ? complaint.assignedTo!
          : 'Field Technician ($idOrEmployeeId)',
      email: 'crew.${idOrEmployeeId.toLowerCase().replaceAll('-', '.')}@mcgm.gov.in',
      role: 'department_crew',
      wardId: complaint?.wardId ?? 'N',
      departmentId: complaint?.assignedDepartmentId ?? 'dept_roads',
      departmentName: 'Department Field Operations',
      displayDesignation: 'Junior Engineer / Ground Technician',
      active: true,
    );
  }
}
