import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/civic_department_model.dart';
import '../../core/models/civic_ward_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/complaint_routing_ticket_model.dart';
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
import 'government_ward_dashboard_service.dart';
import 'govt_complaint_repository.dart';

/// Top KPI grid metrics summary for Ward Department Lead operations center.
class DepartmentLeadKpiMetrics {
  final int unassignedComplaints;
  final int assignedComplaints;
  final int inProgressComplaints;
  final int criticalComplaints;
  final int slaAtRiskComplaints;
  final int slaBreachedComplaints;
  final int awaitingVerificationComplaints;
  final int resolvedTodayComplaints;
  final int totalComplaints;
  final double? slaComplianceRate;

  const DepartmentLeadKpiMetrics({
    required this.unassignedComplaints,
    required this.assignedComplaints,
    required this.inProgressComplaints,
    required this.criticalComplaints,
    required this.slaAtRiskComplaints,
    required this.slaBreachedComplaints,
    required this.awaitingVerificationComplaints,
    required this.resolvedTodayComplaints,
    required this.totalComplaints,
    this.slaComplianceRate,
  });

  bool get hasSlaData => slaComplianceRate != null;
}

/// Compact workflow funnel data across the grievance lifecycle.
class DepartmentLeadOperationsFunnel {
  final int newUnassigned;
  final int assigned;
  final int accepted;
  final int inProgress;
  final int awaitingVerification;
  final int resolved;

  const DepartmentLeadOperationsFunnel({
    required this.newUnassigned,
    required this.assigned,
    required this.accepted,
    required this.inProgress,
    required this.awaitingVerification,
    required this.resolved,
  });
}

/// Workload and status distribution for an authorized ground crew member.
class CrewWorkloadItem {
  final GovtUserModel crewUser;
  final int assignedJobs;
  final int inProgress;
  final int awaitingVerification;
  final int completedToday;
  final bool isAvailable;

  const CrewWorkloadItem({
    required this.crewUser,
    required this.assignedJobs,
    required this.inProgress,
    required this.awaitingVerification,
    required this.completedToday,
    required this.isAvailable,
  });

  String get id => crewUser.id;
  String get employeeId => crewUser.employeeId;
  String get fullName => crewUser.fullName;
  String get designation => crewUser.displayDesignation.isNotEmpty
      ? crewUser.displayDesignation
      : 'Junior Engineer / Field Crew';
  String get phone => crewUser.phone;

  int get totalActiveJobs => assignedJobs + inProgress + awaitingVerification;

  String get availabilityStatus {
    if (totalActiveJobs == 0) return 'Available';
    if (totalActiveJobs <= 2) return 'Low Load';
    if (totalActiveJobs <= 4) return 'Moderate Load';
    return 'Heavy Load';
  }

  Color get availabilityColor {
    if (totalActiveJobs == 0) return const Color(0xFF10B981);
    if (totalActiveJobs <= 2) return const Color(0xFF3B82F6);
    if (totalActiveJobs <= 4) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

/// SLA state classification enum.
enum SlaHealthState {
  healthy,
  atRisk,
  breached;

  String get label {
    switch (this) {
      case SlaHealthState.healthy:
        return 'SLA Healthy';
      case SlaHealthState.atRisk:
        return 'SLA At Risk';
      case SlaHealthState.breached:
        return 'SLA Breached';
    }
  }

  Color get color {
    switch (this) {
      case SlaHealthState.healthy:
        return const Color(0xFF10B981);
      case SlaHealthState.atRisk:
        return const Color(0xFFF59E0B);
      case SlaHealthState.breached:
        return const Color(0xFFEF4444);
    }
  }
}

/// Detailed SLA tracking item for a single grievance.
class DepartmentLeadSlaItem {
  final ComplaintModel complaint;
  final ComplaintPriority priority;
  final ComplaintStatus status;
  final GovtUserModel? assignedCrew;
  final double overdueHours;
  final double elapsedHours;
  final double remainingHours;
  final DateTime reportedTime;
  final SlaHealthState slaState;

  const DepartmentLeadSlaItem({
    required this.complaint,
    required this.priority,
    required this.status,
    this.assignedCrew,
    required this.overdueHours,
    required this.elapsedHours,
    required this.remainingHours,
    required this.reportedTime,
    required this.slaState,
  });

  String get complaintId => complaint.id;
  String get ticketNumber =>
      complaint.ticketNumber.isNotEmpty ? complaint.ticketNumber : complaint.id;
  String get title => complaint.title;
  String get crewName => assignedCrew?.fullName ?? 'Unassigned';
}

/// Department SLA monitoring summary dataset.
class DepartmentLeadSlaMonitoringData {
  final int slaHealthyCount;
  final int slaAtRiskCount;
  final int slaBreachedCount;
  final double? slaComplianceRate;
  final Map<ComplaintPriority, int> priorityBreakdown;
  final Map<ComplaintStatus, int> statusBreakdown;
  final Map<String, int> crewBreakdown;
  final List<DepartmentLeadSlaItem> overdueComplaints;
  final List<DepartmentLeadSlaItem> allSlaItems;

  const DepartmentLeadSlaMonitoringData({
    required this.slaHealthyCount,
    required this.slaAtRiskCount,
    required this.slaBreachedCount,
    this.slaComplianceRate,
    required this.priorityBreakdown,
    required this.statusBreakdown,
    required this.crewBreakdown,
    required this.overdueComplaints,
    required this.allSlaItems,
  });
}

/// Complete aggregated dashboard dataset for Ward Department Lead.
class DepartmentLeadDashboardData {
  final CivicWard ward;
  final CivicDepartment department;
  final GovtUserModel leadUser;
  final List<GovtUserModel> crewMembers; // Canonical 5 crew members
  final DepartmentLeadKpiMetrics kpiMetrics;
  final DepartmentLeadOperationsFunnel operationsFunnel;
  final List<ComplaintModel> allUnitComplaints;
  final List<ComplaintModel> unassignedComplaints;
  final List<ComplaintModel> awaitingVerificationComplaints;
  final List<ComplaintModel> inProgressComplaints;
  final List<ComplaintModel> criticalComplaints;
  final List<ComplaintModel> completedComplaints;
  final List<ComplaintModel> filteredComplaints;
  final List<CrewWorkloadItem> crewWorkload;
  final DepartmentLeadSlaMonitoringData slaMonitoringData;
  final List<ComplaintRoutingTicket> routingTickets;
  final List<HazardModel> departmentHazards;
  final List<GovernmentAuditLog> recentAuditLogs;
  final List<CivicDepartment> allDepartments;
  final DateTime lastRefreshedAt;

  const DepartmentLeadDashboardData({
    required this.ward,
    required this.department,
    required this.leadUser,
    required this.crewMembers,
    required this.kpiMetrics,
    required this.operationsFunnel,
    required this.allUnitComplaints,
    required this.unassignedComplaints,
    required this.awaitingVerificationComplaints,
    required this.inProgressComplaints,
    required this.criticalComplaints,
    required this.completedComplaints,
    required this.filteredComplaints,
    required this.crewWorkload,
    required this.slaMonitoringData,
    required this.routingTickets,
    required this.departmentHazards,
    required this.recentAuditLogs,
    required this.allDepartments,
    required this.lastRefreshedAt,
  });
}

/// Domain Service providing complete municipal operations aggregation strictly
/// scoped to the Ward Department Lead's authoritative (Ward × Department) unit.
class GovernmentDepartmentLeadDashboardService {
  final GovtComplaintRepository _complaintRepo;
  final GovernmentHierarchyRepository _hierarchyRepo;
  final ComplaintRoutingService _routingService;
  final GovernmentAuditService _auditService;
  final GovernmentAuthorizationService _authService;
  final HazardRepository _hazardRepo;

  GovernmentDepartmentLeadDashboardService({
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

  ComplaintRoutingService getRoutingService() => _routingService;
  GovernmentAuditService getAuditService() => _auditService;
  GovernmentAuthorizationService getAuthService() => _authService;

  bool _isSlaBreached(ComplaintModel c, DateTime now) {
    if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) {
      return false;
    }
    return now.difference(c.slaStartedAt).inHours > 48;
  }

  bool _isSlaAtRisk(ComplaintModel c, DateTime now) {
    if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) {
      return false;
    }
    final elapsed = now.difference(c.slaStartedAt).inHours;
    return elapsed >= 36 && elapsed <= 48;
  }

  /// Master Loader for Ward Department Lead Operations Dashboard.
  Future<DepartmentLeadDashboardData> loadDepartmentLeadDashboard({
    required String wardId,
    required String departmentId,
    ComplaintPriority? priorityFilter,
    ComplaintStatus? statusFilter,
    String? crewFilter,
    String? slaFilter,
    String? searchQuery,
    DateTimeRange? dateRange,
  }) async {
    final cleanWardCode = GovernmentWardDashboardService.normalizeWardId(wardId);
    final cleanDeptId =
        GovernmentDepartmentDashboardService.normalizeDepartmentId(departmentId);
    final now = DateTime.now();

    // 1. Fetch Hierarchy Reference Entities
    await _hierarchyRepo.initialize();
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    // 2. Resolve Ward Entity
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

    // 3. Resolve Department Entity
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

    // 4. Resolve Department Lead User
    final leadUser = allUsers.firstWhere(
      (u) =>
          u.isWardLead &&
          GovernmentWardDashboardService.matchesWard(u.wardId, cleanWardCode) &&
          GovernmentDepartmentDashboardService.matchesDepartment(
              u.departmentId, cleanDeptId),
      orElse: () => GovtUserModel(
        id: 'GOV-WDL-$cleanWardCode-$cleanDeptId',
        employeeId: 'GOV-WDL-$cleanWardCode-$cleanDeptId',
        fullName: 'Executive Engineer (${department.displayName})',
        email: 'lead.${cleanDeptId.toLowerCase()}.${cleanWardCode.toLowerCase()}@mcgm.gov.in',
        role: 'ward_department_lead',
        wardId: cleanWardCode,
        departmentId: department.departmentId,
        departmentName: department.displayName,
        displayDesignation: 'Executive Engineer (${department.displayName})',
        active: true,
      ),
    );

    // 5. Resolve Authorized Crew Members (Strictly 5 for this Ward × Dept unit)
    final crewMembers = await getUnitCrewMembers(
      wardId: cleanWardCode,
      departmentId: department.departmentId,
    );

    // 6. Fetch Complaints & Apply Strict Unit Isolation (wardId × departmentId)
    final allRawComplaints = await _complaintRepo.getComplaints();
    final unitComplaints = allRawComplaints.where((c) {
      final cWard = _resolveWardCodeForComplaint(c, allWards);
      final cDept = _resolveDepartmentIdForComplaint(c, allDepartments);

      final wardMatches =
          GovernmentWardDashboardService.matchesWard(cWard, cleanWardCode) ||
              GovernmentWardDashboardService.matchesWard(c.wardId, cleanWardCode) ||
              GovernmentWardDashboardService.matchesWard(
                  c.location.ward, cleanWardCode);

      final deptMatches =
          GovernmentDepartmentDashboardService.matchesDepartment(
                  cDept, cleanDeptId) ||
              GovernmentDepartmentDashboardService.matchesDepartment(
                  c.assignedDepartmentId, cleanDeptId) ||
              GovernmentDepartmentDashboardService.matchesDepartment(
                  c.category.id, cleanDeptId);

      return wardMatches && deptMatches;
    }).toList();

    // Register unit complaints into routing service cache
    for (final c in unitComplaints) {
      _routingService.registerComplaint(c);
    }

    // 7. Compute Top KPI Metrics
    int unassignedCount = 0;
    int assignedCount = 0;
    int inProgressCount = 0;
    int criticalCount = 0;
    int slaAtRiskCount = 0;
    int slaBreachedCount = 0;
    int awaitingVerificationCount = 0;
    int resolvedTodayCount = 0;

    final List<ComplaintModel> unassignedList = [];
    final List<ComplaintModel> awaitingVerificationList = [];
    final List<ComplaintModel> inProgressList = [];
    final List<ComplaintModel> criticalList = [];
    final List<ComplaintModel> completedList = [];

    final startOfToday = DateTime(now.year, now.month, now.day);

    for (final c in unitComplaints) {
      final isResolved = c.status == ComplaintStatus.resolved;
      final isRejected = c.status == ComplaintStatus.rejected;
      final isClosed = isResolved || isRejected;

      final isUnassigned =
          c.assignedCrewMemberId == null || c.assignedCrewMemberId!.trim().isEmpty;

      final isAwaitingVerification = !isClosed &&
          (c.status == ComplaintStatus.verified ||
              (c.status == ComplaintStatus.inProgress &&
                  c.officerNotes != null &&
                  c.officerNotes!.toLowerCase().contains('completion')));

      if (!isClosed) {
        if (isUnassigned) {
          unassignedCount++;
          unassignedList.add(c);
        } else {
          assignedCount++;
        }

        if (c.status == ComplaintStatus.inProgress) {
          inProgressCount++;
          inProgressList.add(c);
        }

        if (c.priority == ComplaintPriority.emergency ||
            c.priority == ComplaintPriority.high) {
          criticalCount++;
          criticalList.add(c);
        }

        if (_isSlaBreached(c, now)) {
          slaBreachedCount++;
        } else if (_isSlaAtRisk(c, now)) {
          slaAtRiskCount++;
        }

        if (isAwaitingVerification) {
          awaitingVerificationCount++;
          awaitingVerificationList.add(c);
        }
      }

      if (isResolved) {
        completedList.add(c);
        final resDate = c.resolvedAt ?? c.updatedAt;
        if (resDate.isAfter(startOfToday)) {
          resolvedTodayCount++;
        }
      }
    }

    final double slaComplianceRate = unitComplaints.isNotEmpty
        ? ((unitComplaints.length - slaBreachedCount) /
                unitComplaints.length *
                100.0)
            .clamp(0.0, 100.0)
        : 100.0;

    final kpiMetrics = DepartmentLeadKpiMetrics(
      unassignedComplaints: unassignedCount,
      assignedComplaints: assignedCount,
      inProgressComplaints: inProgressCount,
      criticalComplaints: criticalCount,
      slaAtRiskComplaints: slaAtRiskCount,
      slaBreachedComplaints: slaBreachedCount,
      awaitingVerificationComplaints: awaitingVerificationCount,
      resolvedTodayComplaints: resolvedTodayCount,
      totalComplaints: unitComplaints.length,
      slaComplianceRate: slaComplianceRate,
    );

    // 8. Compute Compact Operations Funnel
    int funnelNewUnassigned = 0;
    int funnelAssigned = 0;
    int funnelAccepted = 0;
    int funnelInProgress = 0;
    int funnelAwaitingVerification = 0;
    int funnelResolved = 0;

    for (final c in unitComplaints) {
      switch (c.status) {
        case ComplaintStatus.reported:
          funnelNewUnassigned++;
          break;
        case ComplaintStatus.verified:
          if (c.assignedCrewMemberId == null ||
              c.assignedCrewMemberId!.trim().isEmpty) {
            funnelNewUnassigned++;
          } else {
            funnelAwaitingVerification++;
          }
          break;
        case ComplaintStatus.assigned:
          funnelAssigned++;
          break;
        case ComplaintStatus.inProgress:
          funnelAccepted++;
          funnelInProgress++;
          break;
        case ComplaintStatus.resolved:
          funnelResolved++;
          break;
        case ComplaintStatus.rejected:
          break;
      }
    }

    final operationsFunnel = DepartmentLeadOperationsFunnel(
      newUnassigned: funnelNewUnassigned,
      assigned: funnelAssigned,
      accepted: funnelAccepted,
      inProgress: funnelInProgress,
      awaitingVerification: funnelAwaitingVerification,
      resolved: funnelResolved,
    );

    // 9. Compute Ground Crew Workloads
    final List<CrewWorkloadItem> crewWorkloads = [];
    for (final crew in crewMembers) {
      int crewAssigned = 0;
      int crewInProgress = 0;
      int crewAwaiting = 0;
      int crewCompletedToday = 0;

      for (final c in unitComplaints) {
        final matchesCrew = c.assignedCrewMemberId == crew.employeeId ||
            c.assignedCrewMemberId == crew.id ||
            (c.assignedTo != null &&
                c.assignedTo!.toLowerCase() == crew.fullName.toLowerCase());

        if (matchesCrew) {
          if (c.status == ComplaintStatus.assigned) {
            crewAssigned++;
          } else if (c.status == ComplaintStatus.inProgress) {
            crewInProgress++;
          } else if (c.status == ComplaintStatus.verified) {
            crewAwaiting++;
          } else if (c.status == ComplaintStatus.resolved) {
            final resDate = c.resolvedAt ?? c.updatedAt;
            if (resDate.isAfter(startOfToday)) {
              crewCompletedToday++;
            }
          }
        }
      }

      final totalActive = crewAssigned + crewInProgress + crewAwaiting;
      crewWorkloads.add(CrewWorkloadItem(
        crewUser: crew,
        assignedJobs: crewAssigned,
        inProgress: crewInProgress,
        awaitingVerification: crewAwaiting,
        completedToday: crewCompletedToday,
        isAvailable: totalActive <= 2,
      ));
    }

    // 10. Compute SLA Monitoring Data & Breakdowns
    final List<DepartmentLeadSlaItem> allSlaItems = [];
    final List<DepartmentLeadSlaItem> overdueItems = [];
    final Map<ComplaintPriority, int> priorityBreakdown = {
      ComplaintPriority.emergency: 0,
      ComplaintPriority.high: 0,
      ComplaintPriority.medium: 0,
      ComplaintPriority.low: 0,
    };
    final Map<ComplaintStatus, int> statusBreakdown = {
      ComplaintStatus.reported: 0,
      ComplaintStatus.verified: 0,
      ComplaintStatus.assigned: 0,
      ComplaintStatus.inProgress: 0,
      ComplaintStatus.resolved: 0,
    };
    final Map<String, int> crewBreakdown = {};

    int healthyCount = 0;
    int atRiskCount = 0;
    int breachedCount = 0;

    for (final c in unitComplaints) {
      if (c.status == ComplaintStatus.resolved ||
          c.status == ComplaintStatus.rejected) {
        continue;
      }

      final elapsed = now.difference(c.slaStartedAt).inHours.toDouble();
      final totalAllowed = c.priority == ComplaintPriority.emergency
          ? 24.0
          : (c.priority == ComplaintPriority.high ? 36.0 : 48.0);
      final remaining = (totalAllowed - elapsed).clamp(-999.0, totalAllowed);
      final isBreached = elapsed > totalAllowed;
      final isAtRisk = !isBreached && remaining <= 12.0;

      SlaHealthState state;
      if (isBreached) {
        state = SlaHealthState.breached;
        breachedCount++;
      } else if (isAtRisk) {
        state = SlaHealthState.atRisk;
        atRiskCount++;
      } else {
        state = SlaHealthState.healthy;
        healthyCount++;
      }

      GovtUserModel? assignedCrew;
      if (c.assignedCrewMemberId != null &&
          c.assignedCrewMemberId!.isNotEmpty) {
        assignedCrew = crewMembers.cast<GovtUserModel?>().firstWhere(
              (cr) =>
                  cr?.employeeId == c.assignedCrewMemberId ||
                  cr?.id == c.assignedCrewMemberId,
              orElse: () => null,
            );
      }

      final slaItem = DepartmentLeadSlaItem(
        complaint: c,
        priority: c.priority,
        status: c.status,
        assignedCrew: assignedCrew,
        overdueHours: isBreached ? (elapsed - totalAllowed) : 0.0,
        elapsedHours: elapsed,
        remainingHours: remaining,
        reportedTime: c.createdAt,
        slaState: state,
      );

      allSlaItems.add(slaItem);
      if (isBreached) {
        overdueItems.add(slaItem);
      }

      priorityBreakdown[c.priority] = (priorityBreakdown[c.priority] ?? 0) + 1;
      statusBreakdown[c.status] = (statusBreakdown[c.status] ?? 0) + 1;

      final crewKey = assignedCrew?.fullName ?? 'Unassigned';
      crewBreakdown[crewKey] = (crewBreakdown[crewKey] ?? 0) + 1;
    }

    final slaMonitoringData = DepartmentLeadSlaMonitoringData(
      slaHealthyCount: healthyCount,
      slaAtRiskCount: atRiskCount,
      slaBreachedCount: breachedCount,
      slaComplianceRate: slaComplianceRate,
      priorityBreakdown: priorityBreakdown,
      statusBreakdown: statusBreakdown,
      crewBreakdown: crewBreakdown,
      overdueComplaints: overdueItems,
      allSlaItems: allSlaItems,
    );

    // 11. Fetch Unit Routing Tickets (Raised by or targeted at this department in this ward)
    final allPendingTickets =
        await _routingService.getPendingTickets(wardId: cleanWardCode);
    final unitTickets = allPendingTickets.where((t) {
      final matchesDept = GovernmentDepartmentDashboardService.matchesDepartment(
              t.sourceDepartmentId, cleanDeptId) ||
          GovernmentDepartmentDashboardService.matchesDepartment(
              t.suggestedDepartmentId, cleanDeptId);
      return matchesDept;
    }).toList();

    // 12. Fetch Unit Hazards
    final allHazards = await _hazardRepo.getHazards();
    final unitHazards = allHazards.where((h) {
      final hWard = h.ward ?? '';
      final hDept = h.category.id;
      final wardMatch =
          GovernmentWardDashboardService.matchesWard(hWard, cleanWardCode);
      final deptMatch = GovernmentDepartmentDashboardService.matchesDepartment(
          hDept, cleanDeptId);
      return wardMatch && deptMatch;
    }).toList();

    // 13. Fetch Unit Audit Logs
    final List<GovernmentAuditLog> unitAuditLogs = [];
    for (final c in unitComplaints) {
      final logs = await _auditService.getLogsForComplaint(c.id);
      unitAuditLogs.addAll(logs);
    }
    unitAuditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 14. Apply Multi-Criteria Filters on Complaints Queue
    final filteredComplaints = unitComplaints.where((c) {
      // Priority filter
      if (priorityFilter != null && c.priority != priorityFilter) {
        return false;
      }

      // Status filter
      if (statusFilter != null && c.status != statusFilter) {
        return false;
      }

      // Crew filter
      if (crewFilter != null && crewFilter.isNotEmpty && crewFilter != 'all') {
        final matchesCrew = c.assignedCrewMemberId == crewFilter ||
            (c.assignedTo != null &&
                c.assignedTo!.toLowerCase().contains(crewFilter.toLowerCase()));
        if (!matchesCrew) return false;
      }

      // SLA filter
      if (slaFilter != null && slaFilter.isNotEmpty && slaFilter != 'all') {
        if (slaFilter == 'breached' && !_isSlaBreached(c, now)) return false;
        if (slaFilter == 'atRisk' && !_isSlaAtRisk(c, now)) return false;
        if (slaFilter == 'healthy' &&
            (_isSlaBreached(c, now) || _isSlaAtRisk(c, now))) {
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
        final matchesTicket = c.ticketNumber.toLowerCase().contains(q);
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesDesc = c.description.toLowerCase().contains(q);
        final matchesLocation = c.location.address.toLowerCase().contains(q) ||
            (c.location.landmark != null &&
                c.location.landmark!.toLowerCase().contains(q));
        final matchesCrew =
            c.assignedTo != null && c.assignedTo!.toLowerCase().contains(q);

        if (!matchesTicket &&
            !matchesTitle &&
            !matchesDesc &&
            !matchesLocation &&
            !matchesCrew) {
          return false;
        }
      }

      return true;
    }).toList();

    return DepartmentLeadDashboardData(
      ward: ward,
      department: department,
      leadUser: leadUser,
      crewMembers: crewMembers,
      kpiMetrics: kpiMetrics,
      operationsFunnel: operationsFunnel,
      allUnitComplaints: unitComplaints,
      unassignedComplaints: unassignedList,
      awaitingVerificationComplaints: awaitingVerificationList,
      inProgressComplaints: inProgressList,
      criticalComplaints: criticalList,
      completedComplaints: completedList,
      filteredComplaints: filteredComplaints,
      crewWorkload: crewWorkloads,
      slaMonitoringData: slaMonitoringData,
      routingTickets: unitTickets,
      departmentHazards: unitHazards,
      recentAuditLogs: unitAuditLogs,
      allDepartments: allDepartments,
      lastRefreshedAt: now,
    );
  }

  /// Resolves the exact 5 authorized crew members for this (ward, department) unit.
  Future<List<GovtUserModel>> getUnitCrewMembers({
    required String wardId,
    required String departmentId,
  }) async {
    final cleanWard = GovernmentWardDashboardService.normalizeWardId(wardId);
    final cleanDept =
        GovernmentDepartmentDashboardService.normalizeDepartmentId(departmentId);

    // 1. Try fetching from hierarchy repository by role and jurisdiction
    final users = await _hierarchyRepo.getUsers(
      role: 'department_crew',
      wardId: cleanWard,
      departmentId: cleanDept,
    );

    if (users.isNotEmpty) {
      return users.take(5).toList();
    }

    // 2. Try looking up ward_departments mapping
    final wd = await _hierarchyRepo.getWardDepartment(cleanWard, cleanDept);
    if (wd != null && wd.crewMemberIds.isNotEmpty) {
      final List<GovtUserModel> crewList = [];
      for (final empId in wd.crewMemberIds) {
        final u = await _hierarchyRepo.getUserByEmployeeId(empId);
        if (u != null) {
          crewList.add(u);
        }
      }
      if (crewList.isNotEmpty) {
        return crewList;
      }
    }

    // 3. Fallback: synthesize canonical 5 crew technicians for this unit
    final deptName = cleanDept.replaceAll('_', ' ').toUpperCase();
    return List.generate(5, (index) {
      final numStr = '${index + 1}'.padLeft(2, '0');
      final empId = 'GOV-CREW-$cleanWard-$cleanDept-$numStr';
      return GovtUserModel(
        id: empId,
        employeeId: empId,
        fullName: 'Technician $numStr ($cleanWard-$deptName)',
        email: 'crew.$numStr.${cleanDept.toLowerCase()}.${cleanWard.toLowerCase()}@mcgm.gov.in',
        role: 'department_crew',
        wardId: cleanWard,
        departmentId: cleanDept,
        departmentName: deptName,
        displayDesignation: 'Junior Engineer / Ground Technician $numStr',
        phone: '+91 98765 432$numStr',
        active: true,
      );
    });
  }

  /// Assigns an authorized unit ground crew member to execute [complaintId].
  /// Strictly enforces that [crewMemberId] belongs to this Ward × Department unit.
  Future<ComplaintModel> assignCrewMember({
    required String complaintId,
    required String leadId,
    required String crewMemberId,
  }) async {
    final lead = await _getUser(leadId);
    if (lead == null) {
      throw ArgumentError('Department Lead not found for ID: $leadId');
    }

    // Load complaint
    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    // Authoritative check
    if (!_authService.canAssignCrew(lead, complaint)) {
      throw StateError(
          'User ${lead.employeeId} is not authorized to assign crew for complaint $complaintId.');
    }

    // STRICT UNIT ISOLATION: Validate crew member belongs to this unit
    final authorizedCrew = await getUnitCrewMembers(
      wardId: lead.wardId ?? complaint.wardId ?? 'N',
      departmentId: lead.departmentId ?? complaint.assignedDepartmentId ?? 'maintenance_roads',
    );

    final isAuthorized = authorizedCrew.any(
      (c) =>
          c.employeeId.toUpperCase() == crewMemberId.toUpperCase() ||
          c.id.toUpperCase() == crewMemberId.toUpperCase(),
    );

    if (!isAuthorized) {
      throw ArgumentError(
          'Security Violation: Crew member $crewMemberId does not belong to authorized unit (Ward ${lead.wardId}, Dept ${lead.departmentId}).');
    }

    final assignedCrewUser = authorizedCrew.firstWhere(
      (c) =>
          c.employeeId.toUpperCase() == crewMemberId.toUpperCase() ||
          c.id.toUpperCase() == crewMemberId.toUpperCase(),
    );

    // Perform assignment using routing service
    final updated = await _routingService.assignCrewMember(
      complaintId: complaint.id,
      leadId: lead.employeeId,
      crewMemberId: assignedCrewUser.employeeId,
    );

    // Sync with GovtComplaintRepository if mock repo is active
    if (_complaintRepo is MockGovtComplaintRepository) {
      await _complaintRepo.assignComplaint(
        complaintId: complaint.id,
        departmentId: complaint.assignedDepartmentId ?? lead.departmentId ?? 'dept_roads',
        officerName: assignedCrewUser.fullName,
        assignmentNote: 'Assigned to field technician ${assignedCrewUser.fullName} (${assignedCrewUser.employeeId}).',
      );
    }

    return updated;
  }

  /// Reassigns grievance from current crew to another authorized crew member in this unit.
  Future<ComplaintModel> reassignCrewMember({
    required String complaintId,
    required String leadId,
    required String newCrewMemberId,
    String? reason,
  }) async {
    return assignCrewMember(
      complaintId: complaintId,
      leadId: leadId,
      crewMemberId: newCrewMemberId,
    );
  }

  /// Raises a Wrong-Department Reassignment ticket.
  Future<ComplaintRoutingTicket> raiseRoutingRequest({
    required String complaintId,
    required String sourceLeadId,
    required String suggestedDepartmentId,
    required String reason,
    String? remarks,
  }) async {
    return _routingService.raiseReassignmentRequest(
      complaintId: complaintId,
      sourceLeadId: sourceLeadId,
      suggestedDepartmentId: suggestedDepartmentId,
      reason: remarks != null && remarks.isNotEmpty ? '$reason. Notes: $remarks' : reason,
    );
  }

  /// Verifies completed field work and closes grievance OR returns work for rework.
  Future<bool> verifyCompletion({
    required String complaintId,
    required String leadId,
    required String notes,
    bool returnForRework = false,
    String? reworkReason,
  }) async {
    final lead = await _getUser(leadId);
    if (lead == null) {
      throw ArgumentError('Department Lead not found for ID: $leadId');
    }

    final complaint = await _getComplaint(complaintId);
    if (complaint == null) {
      throw ArgumentError('Complaint not found for ID: $complaintId');
    }

    if (!_authService.canVerifyResolution(lead, complaint)) {
      throw StateError('Lead ${lead.employeeId} is not authorized to verify this complaint.');
    }

    if (returnForRework) {
      // Transition back to inProgress / assigned for rework
      final reworkMessage = reworkReason?.isNotEmpty == true
          ? reworkReason!
          : 'Field work rejected by Department Lead. Returned for rework.';

      final updatedTimeline = List<TimelineEvent>.from(complaint.timeline)
        ..insert(
          0,
          TimelineEvent(
            title: 'Returned for Rework',
            description: reworkMessage,
            timestamp: DateTime.now(),
            status: ComplaintStatus.inProgress,
            updatedBy: lead.fullName,
          ),
        );

      final updatedComplaint = complaint.copyWith(
        status: ComplaintStatus.inProgress,
        officerNotes: reworkMessage,
        timeline: updatedTimeline,
        updatedAt: DateTime.now(),
      );

      _routingService.registerComplaint(updatedComplaint);

      await _complaintRepo.updateStatus(
        complaintId: complaint.id,
        nextStatus: ComplaintStatus.inProgress,
        updateMessage: reworkMessage,
        officerName: lead.fullName,
      );

      await _auditService.logAction(
        complaintId: complaint.id,
        action: GovernmentAuditActions.statusUpdated,
        actorId: lead.employeeId,
        actorRole: lead.role,
        actorName: lead.fullName,
        wardId: complaint.wardId,
        departmentId: complaint.assignedDepartmentId,
        details: {
          'action': 'return_for_rework',
          'reason': reworkMessage,
        },
      );

      return true;
    } else {
      // Final Administrative Verification & Resolution
      final success = await _complaintRepo.updateStatus(
        complaintId: complaint.id,
        nextStatus: ComplaintStatus.resolved,
        updateMessage: notes.isNotEmpty
            ? notes
            : 'Field work verified and certified resolved by ${lead.displayDesignation}.',
        officerName: lead.fullName,
      );

      if (success) {
        await _auditService.logAction(
          complaintId: complaint.id,
          action: GovernmentAuditActions.resolutionVerified,
          actorId: lead.employeeId,
          actorRole: lead.role,
          actorName: lead.fullName,
          wardId: complaint.wardId,
          departmentId: complaint.assignedDepartmentId,
          details: {
            'verificationNotes': notes,
            'verifiedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      return success;
    }
  }

  // Internal Helper Resolvers
  String _resolveWardCodeForComplaint(ComplaintModel c, List<CivicWard> allWards) {
    if (c.wardId != null && c.wardId!.isNotEmpty) {
      return GovernmentWardDashboardService.normalizeWardId(c.wardId!);
    }
    final locWard = c.location.ward;
    if (locWard != null && locWard.isNotEmpty) {
      return GovernmentWardDashboardService.normalizeWardId(locWard);
    }
    return 'N';
  }

  String _resolveDepartmentIdForComplaint(
      ComplaintModel c, List<CivicDepartment> allDepts) {
    if (c.assignedDepartmentId != null && c.assignedDepartmentId!.isNotEmpty) {
      return GovernmentDepartmentDashboardService.normalizeDepartmentId(
          c.assignedDepartmentId!);
    }
    if (c.departmentName != null && c.departmentName!.isNotEmpty) {
      return GovernmentDepartmentDashboardService.normalizeDepartmentId(
          c.departmentName!);
    }
    return GovernmentDepartmentDashboardService.normalizeDepartmentId(
        c.category.id);
  }

  Future<ComplaintModel?> _getComplaint(String id) async {
    return await _complaintRepo.getComplaintById(id);
  }

  Future<GovtUserModel?> _getUser(String idOrEmployeeId) async {
    return await _hierarchyRepo.getUserByEmployeeId(idOrEmployeeId) ??
        await _hierarchyRepo.getUserById(idOrEmployeeId);
  }
}
