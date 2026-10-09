import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/civic_department_model.dart';
import '../../core/models/civic_ward_model.dart';
import '../../core/models/civic_zone_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/complaint_routing_ticket_model.dart';
import '../../core/models/government_audit_log_model.dart';
import '../../core/models/hazard_model.dart';
import '../../core/repositories/hazard_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/services/complaint_routing_service.dart';
import '../../core/services/government_audit_service.dart';
import '../../core/services/government_hierarchy_repository.dart';
import '../models/analytics_model.dart';
import '../models/govt_user_model.dart';
import 'government_department_dashboard_service.dart';
import 'govt_complaint_repository.dart';

/// Top-level KPI metrics summary for Assistant Commissioner / Ward Officer command center.
class WardKpiMetrics {
  final int totalComplaints;
  final int openComplaints;
  final int criticalComplaints;
  final int resolvedToday;
  final int resolvedTotal;
  final int slaBreachedCount;
  final double? slaComplianceRate; // percentage (0.0 to 100.0)
  final int pendingRoutingRequests;
  final int activeEscalationsCount;
  final int activePersonnelCount; // 1 Ward Officer + 18 Leads + 90 Crew = 109
  final double? avgResolutionHours;

  const WardKpiMetrics({
    required this.totalComplaints,
    required this.openComplaints,
    required this.criticalComplaints,
    required this.resolvedToday,
    required this.resolvedTotal,
    required this.slaBreachedCount,
    this.slaComplianceRate,
    required this.pendingRoutingRequests,
    required this.activeEscalationsCount,
    required this.activePersonnelCount,
    this.avgResolutionHours,
  });

  bool get hasSlaData => slaComplianceRate != null;
  bool get hasResolutionTimeData => avgResolutionHours != null;
}

/// Ward grievance operations pipeline funnel (8 stages).
class WardOperationsOverviewData {
  final int totalActiveComplaints;
  final int submittedCount;
  final int acknowledgedCount;
  final int assignedCount;
  final int inProgressCount;
  final int awaitingVerificationCount;
  final int resolvedCount;
  final int criticalUnresolvedCount;
  final int slaBreachesCount;
  final int createdTodayCount;
  final int resolvedTodayCount;

  const WardOperationsOverviewData({
    required this.totalActiveComplaints,
    required this.submittedCount,
    required this.acknowledgedCount,
    required this.assignedCount,
    required this.inProgressCount,
    required this.awaitingVerificationCount,
    required this.resolvedCount,
    required this.criticalUnresolvedCount,
    required this.slaBreachesCount,
    required this.createdTodayCount,
    required this.resolvedTodayCount,
  });
}

/// Performance data for one Department Operational Unit inside the Ward (1 of 18 departments).
class WardDepartmentPerformanceData {
  final CivicDepartment department;
  final GovtUserModel? lead;
  final int openComplaints;
  final int inProgressComplaints;
  final int resolvedToday;
  final int resolvedTotal;
  final int criticalComplaints;
  final int slaBreachedComplaints;
  final double? slaComplianceRate;
  final int pendingRoutingRequests;
  final int activeEscalationsCount;
  final int crewCount; // 5 technicians
  final int activeCrewJobs;
  final double? avgResolutionHours;

  const WardDepartmentPerformanceData({
    required this.department,
    this.lead,
    required this.openComplaints,
    required this.inProgressComplaints,
    required this.resolvedToday,
    required this.resolvedTotal,
    required this.criticalComplaints,
    required this.slaBreachedComplaints,
    this.slaComplianceRate,
    required this.pendingRoutingRequests,
    required this.activeEscalationsCount,
    required this.crewCount,
    required this.activeCrewJobs,
    this.avgResolutionHours,
  });

  String get departmentId => department.departmentId;
  String get displayName => department.displayName;
  String get leadName => lead?.fullName ?? 'Executive Engineer (${department.displayName})';
  String get leadPhone => lead?.phone ?? '+91 22 2262 0251';
}

/// Detailed Ward-Department Unit Drill-down Data for Ward Officer inspection.
class WardDepartmentDetailData {
  final CivicDepartment department;
  final CivicWard ward;
  final GovtUserModel? lead;
  final List<GovtUserModel> crewMembers; // 5 technicians
  final int totalComplaints;
  final int openComplaints;
  final int criticalComplaints;
  final int resolvedComplaints;
  final int slaBreachedComplaints;
  final double? slaComplianceRate;
  final double? avgResolutionHours;
  final List<ComplaintModel> recentComplaints;
  final List<ComplaintRoutingTicket> routingTickets;
  final List<GovernmentAuditLog> recentAuditLogs;

  const WardDepartmentDetailData({
    required this.department,
    required this.ward,
    this.lead,
    required this.crewMembers,
    required this.totalComplaints,
    required this.openComplaints,
    required this.criticalComplaints,
    required this.resolvedComplaints,
    required this.slaBreachedComplaints,
    this.slaComplianceRate,
    this.avgResolutionHours,
    required this.recentComplaints,
    required this.routingTickets,
    required this.recentAuditLogs,
  });
}

/// A single SLA breached grievance item with detailed Ward Officer oversight metrics.
class WardSlaBreachItem {
  final ComplaintModel complaint;
  final CivicDepartment department;
  final GovtUserModel? lead;
  final List<GovtUserModel> assignedCrew;
  final double overdueHours;
  final int reassignmentCount;

  const WardSlaBreachItem({
    required this.complaint,
    required this.department,
    this.lead,
    this.assignedCrew = const [],
    required this.overdueHours,
    this.reassignmentCount = 0,
  });

  String get complaintId => complaint.id;
  String get ticketNumber => complaint.ticketNumber.isNotEmpty ? complaint.ticketNumber : complaint.id;
  String get title => complaint.title;
  ComplaintPriority get priority => complaint.priority;
  ComplaintStatus get status => complaint.status;
  String get departmentName => department.displayName;
  String get leadName => lead?.fullName ?? 'Unassigned Lead';
}

/// Comprehensive SLA Monitoring Dataset for the Ward.
class WardSlaMonitoringData {
  final double? overallSlaComplianceRate;
  final int totalBreached;
  final int atRiskCount; // approaching 40h mark
  final double? avgOverdueHours;
  final List<WardSlaBreachItem> breachedItems;
  final Map<String, int> breachCountByDepartment; // deptId -> count

  const WardSlaMonitoringData({
    this.overallSlaComplianceRate,
    required this.totalBreached,
    required this.atRiskCount,
    this.avgOverdueHours,
    required this.breachedItems,
    required this.breachCountByDepartment,
  });
}

/// Ward Escalation Item for the Escalation Center.
class WardEscalationItem {
  final ComplaintModel complaint;
  final CivicDepartment department;
  final String escalationStage;
  final String reason;
  final String currentOwner;
  final DateTime escalatedAt;
  final Duration waitingDuration;

  const WardEscalationItem({
    required this.complaint,
    required this.department,
    required this.escalationStage,
    required this.reason,
    required this.currentOwner,
    required this.escalatedAt,
    required this.waitingDuration,
  });

  String get id => complaint.id;
  String get ticketNumber => complaint.ticketNumber.isNotEmpty ? complaint.ticketNumber : complaint.id;
  String get title => complaint.title;
  ComplaintPriority get priority => complaint.priority;
  String get departmentName => department.displayName;
}

/// Ward Personnel Hierarchy Summary.
class WardPersonnelSummary {
  final int totalPersonnelCount; // 109 (1 Ward Officer + 18 Leads + 90 Crew)
  final GovtUserModel? wardOfficer;
  final int leadCount; // 18
  final int crewCount; // 90
  final int activePersonnelCount;
  final int departmentCoverageCount; // 18

  const WardPersonnelSummary({
    required this.totalPersonnelCount,
    this.wardOfficer,
    required this.leadCount,
    required this.crewCount,
    required this.activePersonnelCount,
    required this.departmentCoverageCount,
  });
}

/// Objective operational metrics for one of the 18 Ward Department Leads.
class WardDepartmentLeadItem {
  final CivicDepartment department;
  final GovtUserModel lead;
  final int openComplaints;
  final int criticalComplaints;
  final int slaBreachedComplaints;
  final int routingRequests;
  final int crewLoad; // total assigned / in-progress crew jobs

  const WardDepartmentLeadItem({
    required this.department,
    required this.lead,
    required this.openComplaints,
    required this.criticalComplaints,
    required this.slaBreachedComplaints,
    required this.routingRequests,
    required this.crewLoad,
  });

  String get leadName => lead.fullName;
  String get designation => lead.displayDesignation.isNotEmpty ? lead.displayDesignation : 'Ward Department Lead';
  String get departmentName => department.displayName;
  String get phone => lead.phone.isNotEmpty ? lead.phone : '+91 22 2262 0251';
}

/// Crew workload and status distribution in a specific department inside this ward.
class DepartmentCrewWorkloadData {
  final CivicDepartment department;
  final List<GovtUserModel> crewMembers; // 5 crew members
  final int assignedJobsCount;
  final int inProgressJobsCount;
  final int awaitingVerificationJobsCount;
  final int availableCrewCount;

  const DepartmentCrewWorkloadData({
    required this.department,
    required this.crewMembers,
    required this.assignedJobsCount,
    required this.inProgressJobsCount,
    required this.awaitingVerificationJobsCount,
    required this.availableCrewCount,
  });

  String get departmentId => department.departmentId;
  String get departmentName => department.displayName;
}

/// Deterministic attention alert item for the Ward Officer.
class WardAttentionAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final String? departmentId;
  final IconData? icon;

  const WardAttentionAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.departmentId,
    this.icon,
  });
}

/// Complete Master Dashboard Dataset for Assistant Commissioner / Ward Officer.
class WardDashboardData {
  final CivicWard ward;
  final CivicZone zone;
  final GovtUserModel? wardOfficer;
  final WardKpiMetrics kpiMetrics;
  final WardOperationsOverviewData operationsOverview;
  final List<WardDepartmentPerformanceData> departmentPerformances; // 18 Departments
  final List<ComplaintModel> criticalComplaints;
  final WardSlaMonitoringData slaMonitoringData;
  final List<ComplaintRoutingTicket> routingTickets;
  final List<WardEscalationItem> escalations;
  final WardPersonnelSummary personnelSummary;
  final List<WardDepartmentLeadItem> departmentLeads; // 18 Leads
  final List<DepartmentCrewWorkloadData> crewDistribution; // 18 Departments
  final List<HazardModel> wardHazards;
  final List<TimeTrendPoint> timeTrends;
  final List<GovernmentAuditLog> recentAuditLogs;
  final List<WardAttentionAlert> alerts;
  final List<CivicDepartment> allDepartments;
  final List<ComplaintModel> filteredComplaints;
  final DateTime lastRefreshedAt;

  const WardDashboardData({
    required this.ward,
    required this.zone,
    this.wardOfficer,
    required this.kpiMetrics,
    required this.operationsOverview,
    required this.departmentPerformances,
    required this.criticalComplaints,
    required this.slaMonitoringData,
    required this.routingTickets,
    required this.escalations,
    required this.personnelSummary,
    required this.departmentLeads,
    required this.crewDistribution,
    required this.wardHazards,
    required this.timeTrends,
    required this.recentAuditLogs,
    required this.alerts,
    required this.allDepartments,
    required this.filteredComplaints,
    required this.lastRefreshedAt,
  });
}

/// Domain Service providing complete municipal aggregation strictly for the assigned Ward.
class GovernmentWardDashboardService {
  final GovtComplaintRepository _complaintRepo;
  final GovernmentHierarchyRepository _hierarchyRepo;
  final ComplaintRoutingService _routingService;
  final GovernmentAuditService _auditService;
  final HazardRepository _hazardRepo;

  GovernmentWardDashboardService({
    GovtComplaintRepository? complaintRepo,
    GovernmentHierarchyRepository? hierarchyRepo,
    ComplaintRoutingService? routingService,
    GovernmentAuditService? auditService,
    HazardRepository? hazardRepo,
  })  : _complaintRepo = complaintRepo ?? RepositoryLocator.govtComplaintRepository,
        _hierarchyRepo = hierarchyRepo ?? LocalGovernmentHierarchyRepository(),
        _routingService = routingService ?? ComplaintRoutingService(),
        _auditService = auditService ?? DefaultGovernmentAuditService(),
        _hazardRepo = hazardRepo ?? RepositoryLocator.hazardRepository;

  ComplaintRoutingService getRoutingService() => _routingService;

  /// Canonical normalization for ward ID matching.
  static String normalizeWardId(String rawWardId) {
    final clean = rawWardId.trim().toUpperCase();
    if (clean.startsWith('WARD_')) {
      return clean.replaceFirst('WARD_', '');
    }
    if (clean.startsWith('WARD ')) {
      return clean.replaceFirst('WARD ', '');
    }
    if (clean.endsWith(' WARD')) {
      return clean.replaceFirst(' WARD', '');
    }
    return clean;
  }

  /// Checks whether two ward identifiers are semantically equivalent.
  static bool matchesWard(String? wardA, String? wardB) {
    if (wardA == null || wardB == null) return false;
    final normA = normalizeWardId(wardA);
    final normB = normalizeWardId(wardB);
    return normA == normB ||
        normA.toLowerCase() == normB.toLowerCase() ||
        normA.replaceAll('/', '').replaceAll('-', '').replaceAll('_', '').toLowerCase() ==
            normB.replaceAll('/', '').replaceAll('-', '').replaceAll('_', '').toLowerCase();
  }

  bool _isSlaBreached(ComplaintModel c, DateTime now) {
    if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) {
      return false;
    }
    return now.difference(c.slaStartedAt).inHours > 48;
  }

  /// Master Loader for Assistant Commissioner / Ward Officer Dashboard.
  Future<WardDashboardData> loadWardDashboard({
    required String wardId,
    String? departmentFilter,
    ComplaintPriority? priorityFilter,
    ComplaintStatus? statusFilter,
    String? searchQuery,
    bool? slaBreachedOnly,
    int trendDays = 7,
  }) async {
    final cleanWardCode = normalizeWardId(wardId);
    final now = DateTime.now();

    // 1. Fetch Hierarchy Reference Data
    final allZones = await _hierarchyRepo.getZones();
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    // 2. Resolve Ward & Zone Entity
    final ward = allWards.firstWhere(
      (w) => matchesWard(w.wardCode, cleanWardCode) || matchesWard(w.wardId, cleanWardCode),
      orElse: () => CivicWard(
        wardId: cleanWardCode,
        wardCode: cleanWardCode,
        wardName: '$cleanWardCode Ward',
        zoneId: 'ZONE_1',
        lat: 19.0760,
        lng: 72.8777,
        pincode: '400001',
      ),
    );

    final zone = allZones.firstWhere(
      (z) => z.zoneId.toUpperCase() == ward.zoneId.toUpperCase(),
      orElse: () => CivicZone(
        zoneId: ward.zoneId,
        zoneNumber: int.tryParse(ward.zoneId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
        displayName: 'Zone ${ward.zoneId.replaceAll('ZONE_', '')}',
      ),
    );

    // 3. Resolve Ward Officer User Profile
    final wardOfficer = allUsers.firstWhere(
      (u) => u.isWardOfficer && matchesWard(u.wardId, cleanWardCode),
      orElse: () => GovtUserModel(
        id: 'ward_officer_${ward.wardCode.toLowerCase()}',
        employeeId: 'GOV-WO-${ward.wardCode}',
        fullName: 'Assistant Commissioner (${ward.wardCode} Ward)',
        email: 'ac.${ward.wardCode.toLowerCase()}@mcgm.gov.in',
        role: 'ward_officer',
        wardId: ward.wardCode,
        displayDesignation: 'Assistant Commissioner / Ward Officer',
        active: true,
      ),
    );

    // 4. Fetch all complaints and strictly filter to authoritative ward
    final allRawComplaints = await _complaintRepo.getComplaints();
    final wardComplaints = allRawComplaints.where((c) {
      final cWard = _resolveWardCodeForComplaint(c, allWards);
      return matchesWard(cWard, cleanWardCode) ||
          matchesWard(c.wardId, cleanWardCode) ||
          matchesWard(c.location.ward, cleanWardCode);
    }).toList();

    // Register all ward complaints in routing service for workflow resilience
    for (final c in wardComplaints) {
      _routingService.registerComplaint(c);
    }

    // 5. Apply multi-criteria filters (Department, Priority, Status, SLA, Search)
    final filteredComplaints = wardComplaints.where((c) {
      final deptId = _resolveDepartmentIdForComplaint(c, allDepartments);

      // Department filter
      if (departmentFilter != null && departmentFilter != 'all' && departmentFilter.isNotEmpty) {
        if (!GovernmentDepartmentDashboardService.matchesDepartment(deptId, departmentFilter)) {
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

      // SLA Breached filter
      if (slaBreachedOnly == true && !_isSlaBreached(c, now)) {
        return false;
      }

      // Search Query
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchTitle = c.title.toLowerCase().contains(query);
        final matchDesc = c.description.toLowerCase().contains(query);
        final matchTicket = (c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id).toLowerCase().contains(query);
        final matchDept = (c.effectiveDepartment).toLowerCase().contains(query);
        if (!matchTitle && !matchDesc && !matchTicket && !matchDept) {
          return false;
        }
      }

      return true;
    }).toList();

    // 6. Ward Personnel Isolation (1 Ward Officer + 18 Ward Leads + 90 Crew = 109)
    final canonicalWardUsers = allUsers.where((u) => u.employeeId.startsWith('GOV-') && matchesWard(u.wardId, cleanWardCode)).toList();
    final wardPersonnel = canonicalWardUsers.isNotEmpty
        ? canonicalWardUsers
        : allUsers.where((u) => matchesWard(u.wardId, cleanWardCode)).toList();
    final wardLeadsUsers = wardPersonnel.where((u) => u.isWardLead).toList();
    final wardCrewUsers = wardPersonnel.where((u) => u.isCrew).toList();

    final personnelSummary = WardPersonnelSummary(
      totalPersonnelCount: wardPersonnel.isNotEmpty ? wardPersonnel.length : 109,
      wardOfficer: wardOfficer,
      leadCount: wardLeadsUsers.isNotEmpty ? wardLeadsUsers.length : 18,
      crewCount: wardCrewUsers.isNotEmpty ? wardCrewUsers.length : 90,
      activePersonnelCount: wardPersonnel.where((u) => u.active).length,
      departmentCoverageCount: allDepartments.length,
    );

    // 7. Operations Overview Funnel (Across ward complaints)
    int submitted = 0;
    int acknowledged = 0;
    int assigned = 0;
    int inProgress = 0;
    int awaitingVerification = 0;
    int resolved = 0;
    int criticalUnresolved = 0;
    int slaBreached = 0;
    int createdToday = 0;
    int resolvedToday = 0;

    for (final c in filteredComplaints) {
      if (c.createdAt.year == now.year && c.createdAt.month == now.month && c.createdAt.day == now.day) {
        createdToday++;
      }

      final isResolved = c.status == ComplaintStatus.resolved;
      if (isResolved) {
        resolved++;
        if (c.resolvedAt != null &&
            c.resolvedAt!.year == now.year &&
            c.resolvedAt!.month == now.month &&
            c.resolvedAt!.day == now.day) {
          resolvedToday++;
        }
      } else {
        // Active pipeline
        if (c.status == ComplaintStatus.reported) {
          submitted++;
        } else if (c.status == ComplaintStatus.verified) {
          acknowledged++;
        } else if (c.status == ComplaintStatus.assigned) {
          assigned++;
        } else if (c.status == ComplaintStatus.inProgress) {
          inProgress++;
        }

        if (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) {
          criticalUnresolved++;
        }

        if (_isSlaBreached(c, now)) {
          slaBreached++;
        }
      }
    }

    final operationsOverview = WardOperationsOverviewData(
      totalActiveComplaints: filteredComplaints.where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length,
      submittedCount: submitted,
      acknowledgedCount: acknowledged,
      assignedCount: assigned,
      inProgressCount: inProgress,
      awaitingVerificationCount: awaitingVerification,
      resolvedCount: resolved,
      criticalUnresolvedCount: criticalUnresolved,
      slaBreachesCount: slaBreached,
      createdTodayCount: createdToday,
      resolvedTodayCount: resolvedToday,
    );

    // 8. Fetch Ward Routing Tickets
    List<ComplaintRoutingTicket> wardRoutingTickets = [];
    try {
      final pendingTickets = await _routingService.getPendingTickets(wardId: ward.wardCode);
      wardRoutingTickets = pendingTickets;
    } catch (_) {
      wardRoutingTickets = [];
    }

    // 9. Department Performance (All 18 Departments)
    final List<WardDepartmentPerformanceData> departmentPerformances = [];
    final List<WardDepartmentLeadItem> departmentLeads = [];
    final List<DepartmentCrewWorkloadData> crewDistributions = [];

    for (final dept in allDepartments) {
      final deptComplaints = filteredComplaints.where((c) {
        final cDeptId = _resolveDepartmentIdForComplaint(c, allDepartments);
        return GovernmentDepartmentDashboardService.matchesDepartment(cDeptId, dept.departmentId);
      }).toList();

      final deptLead = wardLeadsUsers.firstWhere(
        (u) => GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, dept.departmentId),
        orElse: () => GovtUserModel(
          id: 'lead_${ward.wardCode.toLowerCase()}_${dept.departmentId}',
          employeeId: 'GOV-LEAD-${ward.wardCode}-${dept.departmentCode}',
          fullName: 'Executive Engineer (${dept.displayName})',
          email: 'lead.${dept.departmentCode.toLowerCase()}.${ward.wardCode.toLowerCase()}@mcgm.gov.in',
          role: 'ward_department_lead',
          wardId: ward.wardCode,
          departmentId: dept.departmentId,
          departmentName: dept.displayName,
          displayDesignation: 'Executive Engineer · ${dept.displayName}',
          active: true,
        ),
      );

      final deptCrew = wardCrewUsers.where(
        (u) => GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, dept.departmentId),
      ).toList();

      final openCount = deptComplaints.where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;
      final inProgCount = deptComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
      final critCount = deptComplaints.where((c) =>
          (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected).length;

      final resolvedTotal = deptComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
      final resToday = deptComplaints.where((c) =>
          c.status == ComplaintStatus.resolved &&
          c.resolvedAt != null &&
          c.resolvedAt!.year == now.year &&
          c.resolvedAt!.month == now.month &&
          c.resolvedAt!.day == now.day).length;

      final breachedCount = deptComplaints.where((c) => _isSlaBreached(c, now)).length;

      double? complianceRate;
      if (deptComplaints.isNotEmpty) {
        final compliant = deptComplaints.where((c) => !_isSlaBreached(c, now)).length;
        complianceRate = (compliant / deptComplaints.length) * 100.0;
      }

      // Resolution time in hours
      final resolvedList = deptComplaints.where((c) => c.status == ComplaintStatus.resolved && c.resolvedAt != null).toList();
      double? avgResHours;
      if (resolvedList.isNotEmpty) {
        final totalHours = resolvedList.fold<double>(0, (sum, c) => sum + c.resolvedAt!.difference(c.createdAt).inMinutes / 60.0);
        avgResHours = totalHours / resolvedList.length;
      }

      final deptRoutingTickets = wardRoutingTickets.where(
        (t) => GovernmentDepartmentDashboardService.matchesDepartment(t.sourceDepartmentId, dept.departmentId) ||
            GovernmentDepartmentDashboardService.matchesDepartment(t.suggestedDepartmentId, dept.departmentId),
      ).length;

      final activeEscCount = deptComplaints.where((c) =>
          c.priority == ComplaintPriority.emergency &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected).length;

      final crewJobCount = deptComplaints.where((c) =>
          c.assignmentStatus == ComplaintAssignmentStatus.crewAssigned &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected).length;

      final unitPerf = WardDepartmentPerformanceData(
        department: dept,
        lead: deptLead,
        openComplaints: openCount,
        inProgressComplaints: inProgCount,
        resolvedToday: resToday,
        resolvedTotal: resolvedTotal,
        criticalComplaints: critCount,
        slaBreachedComplaints: breachedCount,
        slaComplianceRate: complianceRate,
        pendingRoutingRequests: deptRoutingTickets,
        activeEscalationsCount: activeEscCount,
        crewCount: deptCrew.isNotEmpty ? deptCrew.length : 5,
        activeCrewJobs: crewJobCount,
        avgResolutionHours: avgResHours,
      );

      departmentPerformances.add(unitPerf);

      // Add to Lead Directory
      departmentLeads.add(WardDepartmentLeadItem(
        department: dept,
        lead: deptLead,
        openComplaints: openCount,
        criticalComplaints: critCount,
        slaBreachedComplaints: breachedCount,
        routingRequests: deptRoutingTickets,
        crewLoad: crewJobCount,
      ));

      // Crew Workload Distribution
      final assignedJobs = deptComplaints.where((c) => c.status == ComplaintStatus.assigned).length;
      final inProgJobs = inProgCount;
      final awaitingVerif = deptComplaints.where((c) => c.status == ComplaintStatus.verified).length;
      final availableCrew = (deptCrew.isNotEmpty ? deptCrew.length : 5) - inProgJobs;

      crewDistributions.add(DepartmentCrewWorkloadData(
        department: dept,
        crewMembers: deptCrew,
        assignedJobsCount: assignedJobs,
        inProgressJobsCount: inProgJobs,
        awaitingVerificationJobsCount: awaitingVerif,
        availableCrewCount: availableCrew > 0 ? availableCrew : 0,
      ));
    }

    // 10. Top-Level KPI Summary Metrics
    final totalComplaintsCount = filteredComplaints.length;
    final openComplaintsCount = filteredComplaints.where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;
    final criticalComplaintsCount = filteredComplaints.where((c) =>
        (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
        c.status != ComplaintStatus.resolved &&
        c.status != ComplaintStatus.rejected).length;
    final resolvedTotalCount = filteredComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final slaBreachedTotalCount = filteredComplaints.where((c) => _isSlaBreached(c, now)).length;

    double? overallCompliance;
    if (totalComplaintsCount > 0) {
      final compliant = filteredComplaints.where((c) => !_isSlaBreached(c, now)).length;
      overallCompliance = (compliant / totalComplaintsCount) * 100.0;
    }

    final resolvedComplaintsList = filteredComplaints.where((c) => c.status == ComplaintStatus.resolved && c.resolvedAt != null).toList();
    double? avgResolutionHoursTotal;
    if (resolvedComplaintsList.isNotEmpty) {
      final totalHours = resolvedComplaintsList.fold<double>(0, (sum, c) => sum + c.resolvedAt!.difference(c.createdAt).inMinutes / 60.0);
      avgResolutionHoursTotal = totalHours / resolvedComplaintsList.length;
    }

    final activeEscalationsTotal = filteredComplaints.where((c) =>
        c.priority == ComplaintPriority.emergency &&
        c.status != ComplaintStatus.resolved &&
        c.status != ComplaintStatus.rejected).length;

    final kpiMetrics = WardKpiMetrics(
      totalComplaints: totalComplaintsCount,
      openComplaints: openComplaintsCount,
      criticalComplaints: criticalComplaintsCount,
      resolvedToday: resolvedToday,
      resolvedTotal: resolvedTotalCount,
      slaBreachedCount: slaBreachedTotalCount,
      slaComplianceRate: overallCompliance,
      pendingRoutingRequests: wardRoutingTickets.length,
      activeEscalationsCount: activeEscalationsTotal,
      activePersonnelCount: personnelSummary.totalPersonnelCount,
      avgResolutionHours: avgResolutionHoursTotal,
    );

    // 11. Critical Grievances List (High and Emergency, unresolved)
    final criticalComplaints = filteredComplaints.where((c) =>
        (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
        c.status != ComplaintStatus.resolved &&
        c.status != ComplaintStatus.rejected).toList()
      ..sort((a, b) {
        if (a.priority == ComplaintPriority.emergency && b.priority != ComplaintPriority.emergency) return -1;
        if (b.priority == ComplaintPriority.emergency && a.priority != ComplaintPriority.emergency) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

    // 12. SLA Monitoring Dataset
    final List<WardSlaBreachItem> breachedItems = [];
    final Map<String, int> breachMapByDept = {};
    int atRiskCount = 0;
    double totalOverdueHours = 0;

    for (final c in filteredComplaints) {
      if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) continue;

      final ageHours = now.difference(c.slaStartedAt).inHours;
      if (ageHours >= 40 && ageHours <= 48) {
        atRiskCount++;
      }

      if (ageHours > 48) {
        final overdueHours = ageHours - 48.0;
        totalOverdueHours += overdueHours;

        final dept = allDepartments.firstWhere(
          (d) => GovernmentDepartmentDashboardService.matchesDepartment(d.departmentId, _resolveDepartmentIdForComplaint(c, allDepartments)),
          orElse: () => allDepartments.first,
        );

        final lead = wardLeadsUsers.firstWhere(
          (u) => GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, dept.departmentId),
          orElse: () => wardOfficer,
        );

        final assignedCrew = wardCrewUsers.where((u) => u.employeeId == c.assignedCrewMemberId || u.id == c.assignedCrewMemberId).toList();

        breachedItems.add(WardSlaBreachItem(
          complaint: c,
          department: dept,
          lead: lead,
          assignedCrew: assignedCrew,
          overdueHours: overdueHours,
          reassignmentCount: c.reassignmentCount,
        ));

        breachMapByDept[dept.departmentId] = (breachMapByDept[dept.departmentId] ?? 0) + 1;
      }
    }

    breachedItems.sort((a, b) => b.overdueHours.compareTo(a.overdueHours));

    final slaMonitoringData = WardSlaMonitoringData(
      overallSlaComplianceRate: overallCompliance,
      totalBreached: breachedItems.length,
      atRiskCount: atRiskCount,
      avgOverdueHours: breachedItems.isNotEmpty ? (totalOverdueHours / breachedItems.length) : null,
      breachedItems: breachedItems,
      breachCountByDepartment: breachMapByDept,
    );

    // 13. Escalations Dataset
    final List<WardEscalationItem> escalations = [];
    for (final c in filteredComplaints) {
      if (c.priority == ComplaintPriority.emergency &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected) {
        final dept = allDepartments.firstWhere(
          (d) => GovernmentDepartmentDashboardService.matchesDepartment(d.departmentId, _resolveDepartmentIdForComplaint(c, allDepartments)),
          orElse: () => allDepartments.first,
        );
        final lead = wardLeadsUsers.firstWhere(
          (u) => GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, dept.departmentId),
          orElse: () => wardOfficer,
        );

        escalations.add(WardEscalationItem(
          complaint: c,
          department: dept,
          escalationStage: _isSlaBreached(c, now) ? 'Level 2 - SLA Breached' : 'Level 1 - Emergency Response',
          reason: c.title,
          currentOwner: lead.fullName,
          escalatedAt: c.createdAt,
          waitingDuration: now.difference(c.createdAt),
        ));
      }
    }

    // 14. Ward Spatial GIS Hazards
    List<HazardModel> wardHazards = [];
    try {
      final allHazards = await _hazardRepo.getHazards();
      wardHazards = allHazards.where((h) => matchesWard(h.ward, cleanWardCode)).toList();
    } catch (_) {
      wardHazards = [];
    }

    // 15. Time Trend Points (7/30/90 Days)
    final List<TimeTrendPoint> timeTrends = [];
    for (int i = trendDays - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dateLabel = '${date.day}/${date.month}';

      final createdOnDay = filteredComplaints.where((c) =>
          c.createdAt.year == date.year &&
          c.createdAt.month == date.month &&
          c.createdAt.day == date.day).length;

      final resolvedOnDay = filteredComplaints.where((c) =>
          c.resolvedAt != null &&
          c.resolvedAt!.year == date.year &&
          c.resolvedAt!.month == date.month &&
          c.resolvedAt!.day == date.day).length;

      timeTrends.add(TimeTrendPoint(
        date: date,
        label: dateLabel,
        reportedCount: createdOnDay,
        resolvedCount: resolvedOnDay,
      ));
    }

    // 16. Ward Audit Logs
    List<GovernmentAuditLog> wardAuditLogs = [];
    try {
      for (final c in filteredComplaints.take(20)) {
        final logs = await _auditService.getLogsForComplaint(c.id);
        wardAuditLogs.addAll(logs);
      }
      wardAuditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (wardAuditLogs.length > 30) {
        wardAuditLogs = wardAuditLogs.sublist(0, 30);
      }
    } catch (_) {
      wardAuditLogs = [];
    }

    // 17. Attention Alerts
    final List<WardAttentionAlert> alerts = [];
    if (slaBreachedTotalCount > 0) {
      alerts.add(WardAttentionAlert(
        id: 'alert_sla_breach',
        title: '$slaBreachedTotalCount SLA Breaches in ${ward.wardCode} Ward',
        message: 'Multiple complaints in this ward have exceeded the mandatory 48-hour SLA deadline and require direct administrative intervention.',
        severity: 'critical',
        icon: Icons.alarm_off_rounded,
      ));
    }

    if (wardRoutingTickets.isNotEmpty) {
      alerts.add(WardAttentionAlert(
        id: 'alert_routing_pending',
        title: '${wardRoutingTickets.length} Reassignment Requests Awaiting Approval',
        message: 'Department Leads have reported misrouted tickets requiring Ward Officer authorization for inter-department transfer.',
        severity: 'warning',
        icon: Icons.alt_route_rounded,
      ));
    }

    if (criticalComplaintsCount > 0) {
      alerts.add(WardAttentionAlert(
        id: 'alert_critical_hazards',
        title: '$criticalComplaintsCount Emergency Hazards Unresolved',
        message: 'Active emergency and high-priority public safety hazards are currently under resolution across ward operational units.',
        severity: 'critical',
        icon: Icons.warning_amber_rounded,
      ));
    }

    return WardDashboardData(
      ward: ward,
      zone: zone,
      wardOfficer: wardOfficer,
      kpiMetrics: kpiMetrics,
      operationsOverview: operationsOverview,
      departmentPerformances: departmentPerformances,
      criticalComplaints: criticalComplaints,
      slaMonitoringData: slaMonitoringData,
      routingTickets: wardRoutingTickets,
      escalations: escalations,
      personnelSummary: personnelSummary,
      departmentLeads: departmentLeads,
      crewDistribution: crewDistributions,
      wardHazards: wardHazards,
      timeTrends: timeTrends,
      recentAuditLogs: wardAuditLogs,
      alerts: alerts,
      allDepartments: allDepartments,
      filteredComplaints: filteredComplaints,
      lastRefreshedAt: now,
    );
  }

  /// Fetches detailed drill-down data for a single department inside this ward.
  Future<WardDepartmentDetailData> getDepartmentUnitDetailData({
    required String wardId,
    required String departmentId,
  }) async {
    final cleanWardCode = normalizeWardId(wardId);
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    final ward = allWards.firstWhere(
      (w) => matchesWard(w.wardCode, cleanWardCode) || matchesWard(w.wardId, cleanWardCode),
      orElse: () => CivicWard(
        wardId: cleanWardCode,
        wardCode: cleanWardCode,
        wardName: '$cleanWardCode Ward',
        zoneId: 'ZONE_1',
        lat: 19.0760,
        lng: 72.8777,
        pincode: '400001',
      ),
    );

    final department = allDepartments.firstWhere(
      (d) => GovernmentDepartmentDashboardService.matchesDepartment(d.departmentId, departmentId),
      orElse: () => allDepartments.first,
    );

    final wardPersonnel = allUsers.where((u) => matchesWard(u.wardId, cleanWardCode)).toList();

    final lead = wardPersonnel.firstWhere(
      (u) => u.isWardLead && GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, department.departmentId),
      orElse: () => GovtUserModel(
        id: 'lead_${ward.wardCode.toLowerCase()}_${department.departmentId}',
        employeeId: 'GOV-LEAD-${ward.wardCode}-${department.departmentCode}',
        fullName: 'Executive Engineer (${department.displayName})',
        email: 'lead.${department.departmentCode.toLowerCase()}.${ward.wardCode.toLowerCase()}@mcgm.gov.in',
        role: 'ward_department_lead',
        wardId: ward.wardCode,
        departmentId: department.departmentId,
        departmentName: department.displayName,
        displayDesignation: 'Executive Engineer · ${department.displayName}',
        active: true,
      ),
    );

    final crewMembers = wardPersonnel.where(
      (u) => u.isCrew && GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, department.departmentId),
    ).toList();

    final allRawComplaints = await _complaintRepo.getComplaints();
    final now = DateTime.now();

    final unitComplaints = allRawComplaints.where((c) {
      final cWard = _resolveWardCodeForComplaint(c, allWards);
      final cDeptId = _resolveDepartmentIdForComplaint(c, allDepartments);
      return matchesWard(cWard, cleanWardCode) &&
          GovernmentDepartmentDashboardService.matchesDepartment(cDeptId, department.departmentId);
    }).toList();

    final total = unitComplaints.length;
    final open = unitComplaints.where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;
    final critical = unitComplaints.where((c) =>
        (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
        c.status != ComplaintStatus.resolved &&
        c.status != ComplaintStatus.rejected).length;
    final resolved = unitComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final slaBreached = unitComplaints.where((c) => _isSlaBreached(c, now)).length;

    double? compliance;
    if (total > 0) {
      final compliant = unitComplaints.where((c) => !_isSlaBreached(c, now)).length;
      compliance = (compliant / total) * 100.0;
    }

    final resolvedList = unitComplaints.where((c) => c.status == ComplaintStatus.resolved && c.resolvedAt != null).toList();
    double? avgResHours;
    if (resolvedList.isNotEmpty) {
      final totalHours = resolvedList.fold<double>(0, (sum, c) => sum + c.resolvedAt!.difference(c.createdAt).inMinutes / 60.0);
      avgResHours = totalHours / resolvedList.length;
    }

    final recentComplaints = unitComplaints.take(10).toList();

    List<ComplaintRoutingTicket> routingTickets = [];
    try {
      final allPending = await _routingService.getPendingTickets(wardId: ward.wardCode);
      routingTickets = allPending.where(
        (t) => GovernmentDepartmentDashboardService.matchesDepartment(t.sourceDepartmentId, department.departmentId) ||
            GovernmentDepartmentDashboardService.matchesDepartment(t.suggestedDepartmentId, department.departmentId),
      ).toList();
    } catch (_) {}

    List<GovernmentAuditLog> auditLogs = [];
    try {
      for (final c in recentComplaints.take(5)) {
        final logs = await _auditService.getLogsForComplaint(c.id);
        auditLogs.addAll(logs);
      }
      auditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {}

    return WardDepartmentDetailData(
      department: department,
      ward: ward,
      lead: lead,
      crewMembers: crewMembers,
      totalComplaints: total,
      openComplaints: open,
      criticalComplaints: critical,
      resolvedComplaints: resolved,
      slaBreachedComplaints: slaBreached,
      slaComplianceRate: compliance,
      avgResolutionHours: avgResHours,
      recentComplaints: recentComplaints,
      routingTickets: routingTickets,
      recentAuditLogs: auditLogs,
    );
  }

  // Internal Helpers
  String _resolveWardCodeForComplaint(ComplaintModel c, List<CivicWard> allWards) {
    if (c.wardId != null && c.wardId!.isNotEmpty) {
      return normalizeWardId(c.wardId!);
    }
    if (c.location.ward != null && c.location.ward!.isNotEmpty) {
      return normalizeWardId(c.location.ward!);
    }
    return 'A';
  }

  String _resolveDepartmentIdForComplaint(ComplaintModel c, List<CivicDepartment> allDepartments) {
    if (c.assignedDepartmentId != null && c.assignedDepartmentId!.isNotEmpty) {
      return GovernmentDepartmentDashboardService.normalizeDepartmentId(c.assignedDepartmentId!);
    }
    if (c.category.id.isNotEmpty) {
      return GovernmentDepartmentDashboardService.normalizeDepartmentId(c.category.id);
    }
    return 'maintenance_roads';
  }
}
