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
import 'govt_complaint_repository.dart';

/// Top-level KPI metrics summary for Central Department HOD command center.
class DepartmentKpiMetrics {
  final int totalComplaints;
  final int openComplaints;
  final int criticalComplaints;
  final int resolvedToday;
  final int resolvedTotal;
  final int slaBreachedCount;
  final double? slaComplianceRate; // percentage (0.0 to 100.0)
  final int pendingRoutingRequests;
  final int activeWardUnitsCount; // 24 canonical ward units
  final int activePersonnelCount; // 1 HOD + 24 Leads + 120 Crew = 145
  final double? avgResolutionHours;

  const DepartmentKpiMetrics({
    required this.totalComplaints,
    required this.openComplaints,
    required this.criticalComplaints,
    required this.resolvedToday,
    required this.resolvedTotal,
    required this.slaBreachedCount,
    this.slaComplianceRate,
    required this.pendingRoutingRequests,
    required this.activeWardUnitsCount,
    required this.activePersonnelCount,
    this.avgResolutionHours,
  });
}

/// Department grievance operations pipeline funnel.
class DepartmentOperationsOverviewData {
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

  const DepartmentOperationsOverviewData({
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

/// Performance data for one Ward Operational Unit in the department.
class WardDepartmentUnitPerformanceData {
  final CivicWard ward;
  final CivicZone zone;
  final GovtUserModel? lead;
  final int openComplaints;
  final int inProgressComplaints;
  final int resolvedToday;
  final int resolvedTotal;
  final int criticalComplaints;
  final int slaBreachedComplaints;
  final double? slaComplianceRate;
  final double? avgResolutionHours;
  final int crewCount; // 5 technicians
  final int activeCrewJobs;

  const WardDepartmentUnitPerformanceData({
    required this.ward,
    required this.zone,
    this.lead,
    required this.openComplaints,
    required this.inProgressComplaints,
    required this.resolvedToday,
    required this.resolvedTotal,
    required this.criticalComplaints,
    required this.slaBreachedComplaints,
    this.slaComplianceRate,
    this.avgResolutionHours,
    required this.crewCount,
    required this.activeCrewJobs,
  });

  String get wardCode => ward.wardCode;
  String get wardName => ward.wardName;
  String get zoneDisplayName => zone.displayName;
  String get leadName => lead?.fullName ?? 'Executive Engineer (${ward.wardCode})';
  String get leadPhone => lead?.phone ?? '+91 22 2262 0251';
}

/// Aggregate performance for the department broken down by Zone (7 Zones).
class DepartmentZoneBreakdownData {
  final CivicZone zone;
  final int wardCount;
  final int totalComplaints;
  final int openComplaints;
  final int inProgressComplaints;
  final int resolvedComplaints;
  final int criticalComplaints;
  final int slaBreachedComplaints;
  final double? slaComplianceRate;
  final double? avgResolutionHours;

  const DepartmentZoneBreakdownData({
    required this.zone,
    required this.wardCount,
    required this.totalComplaints,
    required this.openComplaints,
    required this.inProgressComplaints,
    required this.resolvedComplaints,
    required this.criticalComplaints,
    required this.slaBreachedComplaints,
    this.slaComplianceRate,
    this.avgResolutionHours,
  });

  String get zoneId => zone.zoneId;
  String get displayName => zone.displayName;
}

/// A single SLA breached grievance item with detailed department oversight metrics.
class DepartmentSlaBreachItem {
  final ComplaintModel complaint;
  final CivicWard ward;
  final CivicZone zone;
  final GovtUserModel? lead;
  final List<GovtUserModel> assignedCrew;
  final double overdueHours;
  final int reassignmentCount;

  const DepartmentSlaBreachItem({
    required this.complaint,
    required this.ward,
    required this.zone,
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
  String get wardCode => ward.wardCode;
  String get leadName => lead?.fullName ?? 'Unassigned Lead';
}

/// Comprehensive SLA Monitoring Dataset for the department.
class DepartmentSlaMonitoringData {
  final double? overallSlaComplianceRate;
  final int totalBreached;
  final int atRiskCount; // approaching 40h mark
  final double? avgOverdueHours;
  final List<DepartmentSlaBreachItem> breachedItems;
  final Map<String, int> breachCountByWard; // wardCode -> count
  final Map<String, int> breachCountByZone; // zoneId -> count

  const DepartmentSlaMonitoringData({
    this.overallSlaComplianceRate,
    required this.totalBreached,
    required this.atRiskCount,
    this.avgOverdueHours,
    required this.breachedItems,
    required this.breachCountByWard,
    required this.breachCountByZone,
  });
}

/// Department Personnel Hierarchy Summary.
class DepartmentPersonnelSummary {
  final int totalPersonnelCount; // 145 (1 HOD + 24 Leads + 120 Crew)
  final GovtUserModel? hod;
  final int leadCount; // 24
  final int crewCount; // 120
  final int activePersonnelCount;

  const DepartmentPersonnelSummary({
    required this.totalPersonnelCount,
    this.hod,
    required this.leadCount,
    required this.crewCount,
    required this.activePersonnelCount,
  });
}

/// Crew workload and status distribution in a specific ward for this department.
class WardCrewDistributionData {
  final CivicWard ward;
  final CivicZone zone;
  final List<GovtUserModel> crewMembers; // 5 crew
  final int assignedJobsCount;
  final int inProgressJobsCount;
  final int awaitingVerificationJobsCount;
  final int availableCrewCount;

  const WardCrewDistributionData({
    required this.ward,
    required this.zone,
    required this.crewMembers,
    required this.assignedJobsCount,
    required this.inProgressJobsCount,
    required this.awaitingVerificationJobsCount,
    required this.availableCrewCount,
  });

  String get wardCode => ward.wardCode;
  String get wardName => ward.wardName;
}

/// Deterministic attention alert item for the Department HOD.
class DepartmentAttentionAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final String? wardId;
  final IconData? icon;

  const DepartmentAttentionAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.wardId,
    this.icon,
  });
}

/// Detailed Ward Unit Drill-down Data for HOD inspection.
class WardDepartmentUnitDetailData {
  final CivicDepartment department;
  final CivicWard ward;
  final CivicZone zone;
  final GovtUserModel lead;
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

  const WardDepartmentUnitDetailData({
    required this.department,
    required this.ward,
    required this.zone,
    required this.lead,
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

/// Complete Master Dashboard Dataset for Central Department HOD.
class DepartmentDashboardData {
  final CivicDepartment department;
  final GovtUserModel? hodUser;
  final DepartmentKpiMetrics kpiMetrics;
  final DepartmentOperationsOverviewData operationsOverview;
  final List<WardDepartmentUnitPerformanceData> wardUnitPerformances; // 24 Wards
  final List<DepartmentZoneBreakdownData> zoneBreakdowns; // 7 Zones
  final List<ComplaintModel> criticalComplaints;
  final DepartmentSlaMonitoringData slaMonitoringData;
  final List<ComplaintRoutingTicket> routingTickets;
  final List<ComplaintModel> technicalEscalations;
  final DepartmentPersonnelSummary personnelSummary;
  final List<WardDepartmentUnitPerformanceData> departmentLeads;
  final List<WardCrewDistributionData> crewDistribution; // 24 Wards
  final List<HazardModel> departmentHazards;
  final List<TimeTrendPoint> timeTrends;
  final List<GovernmentAuditLog> recentAuditLogs;
  final List<DepartmentAttentionAlert> alerts;
  final List<CivicZone> allZones;
  final List<CivicWard> allWards;
  final DateTime lastRefreshedAt;

  const DepartmentDashboardData({
    required this.department,
    this.hodUser,
    required this.kpiMetrics,
    required this.operationsOverview,
    required this.wardUnitPerformances,
    required this.zoneBreakdowns,
    required this.criticalComplaints,
    required this.slaMonitoringData,
    required this.routingTickets,
    required this.technicalEscalations,
    required this.personnelSummary,
    required this.departmentLeads,
    required this.crewDistribution,
    required this.departmentHazards,
    required this.timeTrends,
    required this.recentAuditLogs,
    required this.alerts,
    required this.allZones,
    required this.allWards,
    required this.lastRefreshedAt,
  });
}

/// Domain Service providing complete departmental aggregation for Central Department HOD.
class GovernmentDepartmentDashboardService {
  final GovtComplaintRepository _complaintRepo;
  final GovernmentHierarchyRepository _hierarchyRepo;
  final ComplaintRoutingService _routingService;
  final GovernmentAuditService _auditService;
  final HazardRepository _hazardRepo;

  GovernmentDepartmentDashboardService({
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

  /// Canonical normalization for department ID and alias matching.
  static String normalizeDepartmentId(String rawDeptId) {
    final clean = rawDeptId.trim().toLowerCase();
    switch (clean) {
      case 'dept_swm':
      case 'swm':
      case 'solid_waste_mgmt':
      case 'solid_waste_management':
      case 'waste':
      case 'cat_waste':
        return 'solid_waste_management';

      case 'dept_roads':
      case 'rds':
      case 'roads':
      case 'maintenance_roads':
      case 'cat_roads':
        return 'maintenance_roads';

      case 'dept_water':
      case 'ww':
      case 'water':
      case 'water_works':
      case 'cat_water':
        return 'water_works';

      case 'dept_building_factory':
      case 'building_factory':
      case 'bf':
      case 'building':
      case 'cat_building':
      case 'infrastructure':
      case 'infra':
        return 'building_factory';

      case 'dept_garden_trees':
      case 'gardens_trees':
      case 'garden_trees':
      case 'gdn':
      case 'garden':
      case 'trees':
      case 'cat_garden':
        return 'garden_trees';

      case 'dept_public_health':
      case 'public_health':
      case 'health':
      case 'ph':
      case 'cat_health':
        return 'public_health';

      case 'dept_pest_control':
      case 'pest_control_insecticide':
      case 'pest_control':
      case 'pci':
      case 'pest':
      case 'cat_pest':
        return 'pest_control_insecticide';

      case 'dept_encroachment':
      case 'encroachment':
      case 'enc':
      case 'cat_encroachment':
        return 'encroachment';

      case 'dept_licence':
      case 'licence':
      case 'lic':
        return 'licence';

      case 'dept_shops_establishments':
      case 'shops_establishments':
      case 'se':
        return 'shops_establishments';

      case 'dept_assessment_collection':
      case 'assessment_collection':
      case 'ac':
        return 'assessment_collection';

      case 'dept_storm_water_drain':
      case 'storm_water_drain':
      case 'storm_water_drainage':
      case 'swd':
      case 'drainage':
      case 'cat_drainage':
        return 'storm_water_drain';

      case 'dept_mechanical_electrical':
      case 'mechanical_electrical':
      case 'm_e':
      case 'electrical':
      case 'cat_electrical':
        return 'mechanical_electrical';

      case 'dept_estate':
      case 'estate':
      case 'est':
        return 'estate';

      case 'dept_education':
      case 'education':
      case 'edu':
        return 'education';

      case 'dept_disaster_management':
      case 'disaster_management':
      case 'disaster':
      case 'dm':
        return 'disaster_management';

      case 'dept_fire_brigade':
      case 'fire_brigade':
      case 'fire':
      case 'fb':
        return 'fire_brigade';

      case 'dept_environment':
      case 'environment':
      case 'env':
      case 'cat_environment':
      case 'pollution':
        return 'environment';

      default:
        return clean;
    }
  }

  /// Checks whether two department identifiers are semantically equivalent.
  static bool matchesDepartment(String? deptA, String? deptB) {
    if (deptA == null || deptB == null) return false;
    final normA = normalizeDepartmentId(deptA);
    final normB = normalizeDepartmentId(deptB);
    return normA == normB ||
        normA.contains(normB) ||
        normB.contains(normA);
  }

  bool _isSlaBreached(ComplaintModel c, DateTime now) {
    if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) {
      return false;
    }
    return now.difference(c.slaStartedAt).inHours > 48;
  }

  /// Master Loader for Central Department HOD Dashboard.
  Future<DepartmentDashboardData> loadDepartmentDashboard({
    required String departmentId,
    String? zoneFilter,
    String? wardFilter,
    ComplaintPriority? priorityFilter,
    ComplaintStatus? statusFilter,
    String? searchQuery,
    bool? slaBreachedOnly,
    int trendDays = 7,
  }) async {
    final cleanDeptId = normalizeDepartmentId(departmentId);
    final now = DateTime.now();

    // 1. Fetch Hierarchy Reference Data
    final allZones = await _hierarchyRepo.getZones();
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    // 2. Resolve Department Entity
    final department = allDepartments.firstWhere(
      (d) => matchesDepartment(d.departmentId, cleanDeptId),
      orElse: () => CivicDepartment(
        departmentId: cleanDeptId,
        departmentCode: cleanDeptId.replaceAll('dept_', '').toUpperCase(),
        displayName: cleanDeptId
            .replaceAll('dept_', '')
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' '),
        description: 'Municipal Department $cleanDeptId',
        defaultLeadDesignation: 'Executive Engineer',
      ),
    );

    // 3. Resolve HOD User Profile
    final hodUser = allUsers.firstWhere(
      (u) => u.isCentralHod && matchesDepartment(u.departmentId, cleanDeptId),
      orElse: () => GovtUserModel(
        id: 'hod_${department.departmentId}',
        employeeId: 'GOV-HOD-${department.departmentCode}',
        fullName: 'Chief Engineer (${department.displayName})',
        email: 'hod.${department.departmentCode.toLowerCase()}@mcgm.gov.in',
        role: 'central_department_hod',
        departmentId: department.departmentId,
        departmentName: department.displayName,
        displayDesignation: 'Chief Engineer / Head of Department',
        active: true,
      ),
    );

    // 4. Fetch all complaints and strictly filter to authoritative department
    final allRawComplaints = await _complaintRepo.getComplaints();
    final deptComplaints = allRawComplaints.where((c) {
      final cDeptId = _resolveDepartmentIdForComplaint(c, allDepartments);
      return matchesDepartment(cDeptId, cleanDeptId) ||
          matchesDepartment(c.assignedDepartmentId, cleanDeptId) ||
          matchesDepartment(c.category.id, cleanDeptId);
    }).toList();

    // 5. Apply multi-criteria filters (Zone, Ward, Priority, Status, SLA, Search)
    final filteredComplaints = deptComplaints.where((c) {
      final ward = _findWardForComplaint(c, allWards);

      // Zone filter
      if (zoneFilter != null && zoneFilter != 'all' && zoneFilter.isNotEmpty) {
        if (ward == null || ward.zoneId.toUpperCase() != zoneFilter.trim().toUpperCase()) {
          return false;
        }
      }

      // Ward filter
      if (wardFilter != null && wardFilter != 'all' && wardFilter.isNotEmpty) {
        final cleanW = wardFilter.trim().toLowerCase();
        if (ward == null || (ward.wardId.toLowerCase() != cleanW && ward.wardCode.toLowerCase() != cleanW)) {
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
        final matchWard = (ward?.wardCode ?? c.wardId ?? c.location.ward ?? '').toLowerCase().contains(query);
        if (!matchTitle && !matchDesc && !matchTicket && !matchWard) {
          return false;
        }
      }

      return true;
    }).toList();

    // 6. Department Personnel Isolation (1 HOD + 24 Ward Leads + 120 Crew)
    final deptPersonnel = allUsers.where((u) => matchesDepartment(u.departmentId, cleanDeptId)).toList();
    final deptLeadsUsers = deptPersonnel.where((u) => u.isWardLead).toList();
    final deptCrewUsers = deptPersonnel.where((u) => u.isCrew).toList();

    final personnelSummary = DepartmentPersonnelSummary(
      totalPersonnelCount: deptPersonnel.isNotEmpty ? deptPersonnel.length : 145,
      hod: hodUser,
      leadCount: deptLeadsUsers.isNotEmpty ? deptLeadsUsers.length : 24,
      crewCount: deptCrewUsers.isNotEmpty ? deptCrewUsers.length : 120,
      activePersonnelCount: deptPersonnel.where((u) => u.active).length,
    );

    // 7. Operations Overview Funnel (Across department complaints)
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
        final resDate = c.resolvedAt ?? c.updatedAt;
        if (resDate.year == now.year && resDate.month == now.month && resDate.day == now.day) {
          resolvedToday++;
        }
      } else {
        if (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) {
          criticalUnresolved++;
        }
        if (_isSlaBreached(c, now)) {
          slaBreached++;
        }
      }

      switch (c.status) {
        case ComplaintStatus.reported:
          submitted++;
          awaitingVerification++;
          break;
        case ComplaintStatus.verified:
          acknowledged++;
          awaitingVerification++;
          break;
        case ComplaintStatus.assigned:
          assigned++;
          break;
        case ComplaintStatus.inProgress:
          inProgress++;
          break;
        case ComplaintStatus.resolved:
          break;
        case ComplaintStatus.rejected:
          break;
      }
    }

    final totalActive = submitted + acknowledged + assigned + inProgress;

    final operationsOverview = DepartmentOperationsOverviewData(
      totalActiveComplaints: totalActive,
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

    // 8. Top KPI Calculations
    final resolvedItems = filteredComplaints.where((c) => c.status == ComplaintStatus.resolved).toList();
    double? slaComplianceRate;
    double? avgResolutionHours;

    if (resolvedItems.isNotEmpty) {
      int withinSla = 0;
      double hoursSum = 0;
      for (final item in resolvedItems) {
        final end = item.resolvedAt ?? item.updatedAt;
        final h = (end.difference(item.slaStartedAt).inMinutes / 60.0).clamp(0.0, 9999.0);
        hoursSum += h;
        if (h <= 48.0) withinSla++;
      }
      slaComplianceRate = (withinSla / resolvedItems.length) * 100.0;
      avgResolutionHours = hoursSum / resolvedItems.length;
    } else if (filteredComplaints.isNotEmpty) {
      final nonBreached = filteredComplaints.where((c) => !_isSlaBreached(c, now)).length;
      slaComplianceRate = (nonBreached / filteredComplaints.length) * 100.0;
    }

    // 9. Department Routing Requests (Source or Suggested matching this department)
    List<ComplaintRoutingTicket> deptRoutingTickets = [];
    try {
      final pendingTickets = await _routingService.getPendingTickets();
      deptRoutingTickets = pendingTickets.where((t) =>
          matchesDepartment(t.sourceDepartmentId, cleanDeptId) ||
          matchesDepartment(t.suggestedDepartmentId, cleanDeptId)).toList();
    } catch (_) {
      deptRoutingTickets = [];
    }
    final pendingRoutingRequests = deptRoutingTickets.where((t) => t.status == RoutingTicketStatus.pending).length;

    final kpiMetrics = DepartmentKpiMetrics(
      totalComplaints: filteredComplaints.length,
      openComplaints: totalActive,
      criticalComplaints: criticalUnresolved,
      resolvedToday: resolvedToday,
      resolvedTotal: resolved,
      slaBreachedCount: slaBreached,
      slaComplianceRate: slaComplianceRate,
      pendingRoutingRequests: pendingRoutingRequests,
      activeWardUnitsCount: allWards.length, // 24 Wards
      activePersonnelCount: personnelSummary.totalPersonnelCount,
      avgResolutionHours: avgResolutionHours,
    );

    // 10. 24-Ward Department Unit Performances
    final targetWards = allWards.where((w) {
      if (zoneFilter != null && zoneFilter != 'all' && zoneFilter.isNotEmpty) {
        if (w.zoneId.toUpperCase() != zoneFilter.trim().toUpperCase()) {
          return false;
        }
      }
      if (wardFilter != null && wardFilter != 'all' && wardFilter.isNotEmpty) {
        final cleanW = wardFilter.trim().toLowerCase();
        if (w.wardId.toLowerCase() != cleanW && w.wardCode.toLowerCase() != cleanW) {
          return false;
        }
      }
      return true;
    }).toList();

    final wardUnitPerformances = <WardDepartmentUnitPerformanceData>[];
    final crewDistributions = <WardCrewDistributionData>[];

    for (final ward in targetWards) {
      final zone = allZones.firstWhere(
        (z) => z.zoneId.toUpperCase() == ward.zoneId.toUpperCase(),
        orElse: () => CivicZone(zoneId: ward.zoneId, zoneNumber: 1, displayName: 'Zone ${ward.zoneId}'),
      );

      final wardLead = deptLeadsUsers.firstWhere(
        (u) => u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
            u.wardId?.toLowerCase() == ward.wardCode.toLowerCase(),
        orElse: () => GovtUserModel(
          id: 'wl_${ward.wardCode}_${department.departmentCode}',
          employeeId: 'EMP-WL-${ward.wardCode}-${department.departmentCode}',
          fullName: '${department.displayName} Lead (${ward.wardCode})',
          email: 'wl.${ward.wardCode.toLowerCase()}.${department.departmentCode.toLowerCase()}@bmc.gov.in',
          role: 'ward_lead',
          wardId: ward.wardId,
          departmentId: department.departmentId,
          zoneId: ward.zoneId,
          active: true,
        ),
      );

      final wardCrew = deptCrewUsers.where((u) =>
          u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
          u.wardId?.toLowerCase() == ward.wardCode.toLowerCase()).toList();

      final wComplaints = filteredComplaints.where((c) {
        final matchWard = _findWardForComplaint(c, allWards);
        if (matchWard != null && matchWard.wardId == ward.wardId) return true;
        final cWard = (c.wardId ?? c.location.ward ?? '').toLowerCase();
        return cWard == ward.wardId.toLowerCase() || cWard == ward.wardCode.toLowerCase();
      }).toList();

      int wOpen = 0;
      int wInProgress = 0;
      int wResolvedToday = 0;
      int wResolvedTotal = 0;
      int wCritical = 0;
      int wSlaBreached = 0;
      final wResolvedItems = <ComplaintModel>[];

      for (final c in wComplaints) {
        final isRes = c.status == ComplaintStatus.resolved;
        if (isRes) {
          wResolvedTotal++;
          wResolvedItems.add(c);
          final resDate = c.resolvedAt ?? c.updatedAt;
          if (resDate.year == now.year && resDate.month == now.month && resDate.day == now.day) {
            wResolvedToday++;
          }
        } else {
          wOpen++;
          if (c.status == ComplaintStatus.inProgress) wInProgress++;
          if (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) wCritical++;
          if (_isSlaBreached(c, now)) wSlaBreached++;
        }
      }

      double? wSlaRate;
      double? wAvgHours;
      if (wResolvedItems.isNotEmpty) {
        int within = 0;
        double sum = 0;
        for (final item in wResolvedItems) {
          final end = item.resolvedAt ?? item.updatedAt;
          final h = (end.difference(item.slaStartedAt).inMinutes / 60.0).clamp(0.0, 9999.0);
          sum += h;
          if (h <= 48.0) within++;
        }
        wSlaRate = (within / wResolvedItems.length) * 100.0;
        wAvgHours = sum / wResolvedItems.length;
      } else if (wComplaints.isNotEmpty) {
        wSlaRate = ((wComplaints.length - wSlaBreached) / wComplaints.length) * 100.0;
      }

      wardUnitPerformances.add(WardDepartmentUnitPerformanceData(
        ward: ward,
        zone: zone,
        lead: wardLead,
        openComplaints: wOpen,
        inProgressComplaints: wInProgress,
        resolvedToday: wResolvedToday,
        resolvedTotal: wResolvedTotal,
        criticalComplaints: wCritical,
        slaBreachedComplaints: wSlaBreached,
        slaComplianceRate: wSlaRate,
        avgResolutionHours: wAvgHours,
        crewCount: wardCrew.isNotEmpty ? wardCrew.length : 5,
        activeCrewJobs: wInProgress,
      ));

      crewDistributions.add(WardCrewDistributionData(
        ward: ward,
        zone: zone,
        crewMembers: wardCrew.isNotEmpty
            ? wardCrew
            : List.generate(
                5,
                (i) => GovtUserModel(
                  id: 'crew_${ward.wardCode}_${department.departmentCode}_$i',
                  employeeId: 'EMP-CRW-${ward.wardCode}-${department.departmentCode}-0${i + 1}',
                  fullName: 'Technician ${i + 1} (${ward.wardCode})',
                  email: 'crew${i + 1}.${ward.wardCode.toLowerCase()}@bmc.gov.in',
                  role: 'department_crew',
                  wardId: ward.wardId,
                  departmentId: department.departmentId,
                  zoneId: ward.zoneId,
                  active: true,
                ),
              ),
        assignedJobsCount: wOpen,
        inProgressJobsCount: wInProgress,
        awaitingVerificationJobsCount: wComplaints.where((c) => c.status == ComplaintStatus.reported || c.status == ComplaintStatus.verified).length,
        availableCrewCount: (5 - wInProgress).clamp(0, 5),
      ));
    }

    // 11. 7-Zone Breakdown for Department
    final zoneBreakdowns = <DepartmentZoneBreakdownData>[];
    for (final zone in allZones) {
      final zoneWards = allWards.where((w) => w.zoneId.toUpperCase() == zone.zoneId.toUpperCase()).toList();
      final zoneUnits = wardUnitPerformances.where((u) => u.zone.zoneId == zone.zoneId).toList();

      int zTotal = 0;
      int zOpen = 0;
      int zInProgress = 0;
      int zResolved = 0;
      int zCritical = 0;
      int zSlaBreached = 0;
      double hoursSum = 0;
      int hoursCount = 0;

      for (final u in zoneUnits) {
        zTotal += (u.openComplaints + u.resolvedTotal);
        zOpen += u.openComplaints;
        zInProgress += u.inProgressComplaints;
        zResolved += u.resolvedTotal;
        zCritical += u.criticalComplaints;
        zSlaBreached += u.slaBreachedComplaints;
        if (u.avgResolutionHours != null) {
          hoursSum += u.avgResolutionHours!;
          hoursCount++;
        }
      }

      final double? zSlaRate = zTotal > 0 ? (((zTotal - zSlaBreached) / zTotal) * 100.0) : null;
      final double? zAvgHours = hoursCount > 0 ? (hoursSum / hoursCount) : null;

      zoneBreakdowns.add(DepartmentZoneBreakdownData(
        zone: zone,
        wardCount: zoneWards.length,
        totalComplaints: zTotal,
        openComplaints: zOpen,
        inProgressComplaints: zInProgress,
        resolvedComplaints: zResolved,
        criticalComplaints: zCritical,
        slaBreachedComplaints: zSlaBreached,
        slaComplianceRate: zSlaRate,
        avgResolutionHours: zAvgHours,
      ));
    }

    // 12. Critical Department Complaints (High & Emergency)
    final criticalComplaints = filteredComplaints
        .where((c) =>
            (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
            c.status != ComplaintStatus.resolved)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 13. SLA Monitoring & Breached Items Detail
    final breachedItems = <DepartmentSlaBreachItem>[];
    final Map<String, int> breachByWard = {};
    final Map<String, int> breachByZone = {};
    int atRisk = 0;
    double totalOverdueHours = 0;

    for (final c in filteredComplaints) {
      final ward = _findWardForComplaint(c, allWards) ??
          allWards.firstWhere(
            (w) => w.wardId.toLowerCase() == (c.wardId ?? '').toLowerCase(),
            orElse: () => allWards.first,
          );

      final zone = allZones.firstWhere(
        (z) => z.zoneId.toUpperCase() == ward.zoneId.toUpperCase(),
        orElse: () => allZones.first,
      );

      final lead = deptLeadsUsers.firstWhere(
        (u) => u.wardId?.toLowerCase() == ward.wardId.toLowerCase(),
        orElse: () => GovtUserModel(
          id: 'lead_${ward.wardCode}',
          employeeId: 'EMP-WL-${ward.wardCode}',
          fullName: 'Lead (${ward.wardCode})',
          email: 'lead@bmc.gov.in',
          role: 'ward_lead',
          active: true,
        ),
      );

      if (c.status != ComplaintStatus.resolved) {
        final elapsedHours = now.difference(c.slaStartedAt).inMinutes / 60.0;
        if (elapsedHours >= 40.0 && elapsedHours < 48.0) {
          atRisk++;
        }
        if (_isSlaBreached(c, now) || elapsedHours >= 48.0) {
          final overdue = (elapsedHours - 48.0).clamp(0.0, 9999.0);
          totalOverdueHours += overdue;
          breachByWard[ward.wardCode] = (breachByWard[ward.wardCode] ?? 0) + 1;
          breachByZone[zone.zoneId] = (breachByZone[zone.zoneId] ?? 0) + 1;

          breachedItems.add(DepartmentSlaBreachItem(
            complaint: c,
            ward: ward,
            zone: zone,
            lead: lead,
            assignedCrew: const [],
            overdueHours: overdue,
            reassignmentCount: c.assignedTo != null ? 1 : 0,
          ));
        }
      }
    }

    final slaMonitoringData = DepartmentSlaMonitoringData(
      overallSlaComplianceRate: slaComplianceRate,
      totalBreached: breachedItems.length,
      atRiskCount: atRisk,
      avgOverdueHours: breachedItems.isNotEmpty ? (totalOverdueHours / breachedItems.length) : null,
      breachedItems: breachedItems,
      breachCountByWard: breachByWard,
      breachCountByZone: breachByZone,
    );

    // 14. Technical Escalations (Emergency priority or breached items requiring technical intervention)
    final technicalEscalations = filteredComplaints
        .where((c) =>
            c.status != ComplaintStatus.resolved &&
            (c.priority == ComplaintPriority.emergency || _isSlaBreached(c, now)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 15. Department GIS Hazards
    final allHazards = await _hazardRepo.getHazards();
    final deptHazards = allHazards.where((h) =>
        matchesDepartment(h.category.id, cleanDeptId) ||
        matchesDepartment(h.category.name, cleanDeptId)).toList();

    // 16. Department Time Trends
    final timeTrends = _generateRealTimeTrends(filteredComplaints, trendDays);

    // 17. Department Audit Logs
    List<GovernmentAuditLog> deptAuditLogs = [];
    try {
      for (final c in filteredComplaints.take(20)) {
        final logs = await _auditService.getLogsForComplaint(c.id);
        deptAuditLogs.addAll(logs);
      }
      deptAuditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (deptAuditLogs.length > 40) {
        deptAuditLogs = deptAuditLogs.sublist(0, 40);
      }
    } catch (_) {
      deptAuditLogs = [];
    }

    // 18. Attention Alerts
    final alerts = <DepartmentAttentionAlert>[];
    if (criticalComplaints.isNotEmpty) {
      alerts.add(DepartmentAttentionAlert(
        id: 'alert_dept_critical',
        title: '${criticalComplaints.length} Critical Grievances in ${department.displayName}',
        message: 'High-severity civic emergencies requiring immediate technical crew deployment.',
        severity: 'critical',
        icon: Icons.emergency_rounded,
      ));
    }
    if (breachedItems.isNotEmpty) {
      alerts.add(DepartmentAttentionAlert(
        id: 'alert_dept_sla',
        title: '${breachedItems.length} SLA Breaches Active',
        message: 'Multiple complaints in department exceeded 48-hour municipal charter limit.',
        severity: 'warning',
        icon: Icons.timer_off_outlined,
      ));
    }
    if (pendingRoutingRequests > 0) {
      alerts.add(DepartmentAttentionAlert(
        id: 'alert_dept_routing',
        title: '$pendingRoutingRequests Routing Requests Pending',
        message: 'Inter-department transfer tickets awaiting review and reassignment.',
        severity: 'info',
        icon: Icons.swap_horiz,
      ));
    }

    return DepartmentDashboardData(
      department: department,
      hodUser: hodUser,
      kpiMetrics: kpiMetrics,
      operationsOverview: operationsOverview,
      wardUnitPerformances: wardUnitPerformances,
      zoneBreakdowns: zoneBreakdowns,
      criticalComplaints: criticalComplaints,
      slaMonitoringData: slaMonitoringData,
      routingTickets: deptRoutingTickets,
      technicalEscalations: technicalEscalations,
      personnelSummary: personnelSummary,
      departmentLeads: wardUnitPerformances,
      crewDistribution: crewDistributions,
      departmentHazards: deptHazards,
      timeTrends: timeTrends,
      recentAuditLogs: deptAuditLogs,
      alerts: alerts,
      allZones: allZones,
      allWards: allWards,
      lastRefreshedAt: now,
    );
  }

  /// Detailed Ward Unit Drill-down Data Retrieval for HOD supervisory modal.
  Future<WardDepartmentUnitDetailData> getWardUnitDetailOverview({
    required String departmentId,
    required String wardId,
  }) async {
    final cleanDeptId = normalizeDepartmentId(departmentId);
    final now = DateTime.now();

    final allZones = await _hierarchyRepo.getZones();
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    final department = allDepartments.firstWhere(
      (d) => matchesDepartment(d.departmentId, cleanDeptId),
      orElse: () => CivicDepartment(
        departmentId: cleanDeptId,
        departmentCode: cleanDeptId.replaceAll('dept_', '').toUpperCase(),
        displayName: cleanDeptId.replaceAll('dept_', '').replaceAll('_', ' '),
        description: 'Municipal Department $cleanDeptId',
        defaultLeadDesignation: 'Executive Engineer',
      ),
    );

    final cleanW = wardId.trim().toLowerCase();
    final ward = allWards.firstWhere(
      (w) => w.wardId.toLowerCase() == cleanW || w.wardCode.toLowerCase() == cleanW,
      orElse: () => CivicWard(
        wardId: wardId,
        wardCode: wardId.toUpperCase(),
        wardName: 'Ward ${wardId.toUpperCase()}',
        zoneId: 'ZONE_1',
        lat: 19.0760,
        lng: 72.8777,
        pincode: '400001',
      ),
    );

    final zone = allZones.firstWhere(
      (z) => z.zoneId.toUpperCase() == ward.zoneId.toUpperCase(),
      orElse: () => CivicZone(zoneId: ward.zoneId, zoneNumber: 1, displayName: 'Zone ${ward.zoneId}'),
    );

    final deptUsers = allUsers.where((u) => matchesDepartment(u.departmentId, cleanDeptId)).toList();

    final wardLead = deptUsers.firstWhere(
      (u) => u.isWardLead && (u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
          u.wardId?.toLowerCase() == ward.wardCode.toLowerCase()),
      orElse: () => GovtUserModel(
        id: 'wl_${ward.wardCode}_${department.departmentCode}',
        employeeId: 'EMP-WL-${ward.wardCode}-${department.departmentCode}',
        fullName: '${department.displayName} Lead (${ward.wardCode})',
        email: 'wl.${ward.wardCode.toLowerCase()}.${department.departmentCode.toLowerCase()}@bmc.gov.in',
        role: 'ward_lead',
        wardId: ward.wardId,
        departmentId: department.departmentId,
        zoneId: ward.zoneId,
        active: true,
      ),
    );

    final wardCrew = deptUsers.where((u) =>
        u.isCrew && (u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
            u.wardId?.toLowerCase() == ward.wardCode.toLowerCase())).toList();

    final actualCrew = wardCrew.isNotEmpty
        ? wardCrew
        : List.generate(
            5,
            (i) => GovtUserModel(
              id: 'crew_${ward.wardCode}_${department.departmentCode}_$i',
              employeeId: 'EMP-CRW-${ward.wardCode}-${department.departmentCode}-0${i + 1}',
              fullName: 'Technician ${i + 1} (${ward.wardCode})',
              email: 'crew${i + 1}.${ward.wardCode.toLowerCase()}@bmc.gov.in',
              role: 'department_crew',
              wardId: ward.wardId,
              departmentId: department.departmentId,
              zoneId: ward.zoneId,
              active: true,
            ),
          );

    final allRaw = await _complaintRepo.getComplaints();
    final unitComplaints = allRaw.where((c) {
      final cDept = _resolveDepartmentIdForComplaint(c, allDepartments);
      if (!matchesDepartment(cDept, cleanDeptId) &&
          !matchesDepartment(c.assignedDepartmentId, cleanDeptId) &&
          !matchesDepartment(c.category.id, cleanDeptId)) {
        return false;
      }
      final matchWard = _findWardForComplaint(c, allWards);
      if (matchWard != null && matchWard.wardId == ward.wardId) return true;
      final cWard = (c.wardId ?? c.location.ward ?? '').toLowerCase();
      return cWard == ward.wardId.toLowerCase() || cWard == ward.wardCode.toLowerCase();
    }).toList();

    int total = unitComplaints.length;
    int open = 0;
    int critical = 0;
    int slaBreached = 0;
    final resolved = <ComplaintModel>[];

    for (final c in unitComplaints) {
      if (c.status == ComplaintStatus.resolved) {
        resolved.add(c);
      } else {
        open++;
        if (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) {
          critical++;
        }
        if (_isSlaBreached(c, now)) {
          slaBreached++;
        }
      }
    }

    double? slaCompliance;
    double? avgHours;
    if (resolved.isNotEmpty) {
      int withinSla = 0;
      double hoursSum = 0;
      for (final item in resolved) {
        final end = item.resolvedAt ?? item.updatedAt;
        final h = (end.difference(item.slaStartedAt).inMinutes / 60.0).clamp(0.0, 9999.0);
        hoursSum += h;
        if (h <= 48.0) withinSla++;
      }
      slaCompliance = (withinSla / resolved.length) * 100.0;
      avgHours = hoursSum / resolved.length;
    }

    List<ComplaintRoutingTicket> unitRouting = [];
    try {
      final allRouting = await _routingService.getPendingTickets();
      unitRouting = allRouting.where((t) =>
          t.wardId.toLowerCase() == ward.wardId.toLowerCase() &&
          (matchesDepartment(t.sourceDepartmentId, cleanDeptId) ||
              matchesDepartment(t.suggestedDepartmentId, cleanDeptId))).toList();
    } catch (_) {
      unitRouting = [];
    }

    List<GovernmentAuditLog> unitAudit = [];
    try {
      for (final c in unitComplaints.take(10)) {
        final logs = await _auditService.getLogsForComplaint(c.id);
        unitAudit.addAll(logs);
      }
      unitAudit.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      unitAudit = [];
    }

    final recentComplaints = List<ComplaintModel>.from(unitComplaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return WardDepartmentUnitDetailData(
      department: department,
      ward: ward,
      zone: zone,
      lead: wardLead,
      crewMembers: actualCrew,
      totalComplaints: total,
      openComplaints: open,
      criticalComplaints: critical,
      resolvedComplaints: resolved.length,
      slaBreachedComplaints: slaBreached,
      slaComplianceRate: slaCompliance,
      avgResolutionHours: avgHours,
      recentComplaints: recentComplaints.take(10).toList(),
      routingTickets: unitRouting,
      recentAuditLogs: unitAudit,
    );
  }

  CivicWard? _findWardForComplaint(ComplaintModel c, List<CivicWard> allWards) {
    if (c.wardId != null && c.wardId!.isNotEmpty) {
      final w = allWards.where((ward) =>
          ward.wardId.toLowerCase() == c.wardId!.toLowerCase() ||
          ward.wardCode.toLowerCase() == c.wardId!.toLowerCase());
      if (w.isNotEmpty) return w.first;
    }
    if (c.location.ward != null && c.location.ward!.isNotEmpty) {
      final w = allWards.where((ward) =>
          ward.wardId.toLowerCase() == c.location.ward!.toLowerCase() ||
          ward.wardCode.toLowerCase() == c.location.ward!.toLowerCase());
      if (w.isNotEmpty) return w.first;
    }
    return null;
  }

  String _resolveDepartmentIdForComplaint(ComplaintModel c, List<CivicDepartment> allDepartments) {
    if (c.assignedDepartmentId != null && c.assignedDepartmentId!.isNotEmpty) {
      return normalizeDepartmentId(c.assignedDepartmentId!);
    }
    if (c.departmentName != null && c.departmentName!.isNotEmpty) {
      return normalizeDepartmentId(c.departmentName!);
    }
    final catId = c.category.id.toLowerCase();
    switch (catId) {
      case 'waste':
      case 'garbage':
      case 'cat_waste':
      case 'solid_waste_management':
        return 'solid_waste_management';
      case 'pothole':
      case 'roads':
      case 'cat_roads':
      case 'street_light':
        return 'maintenance_roads';
      case 'water':
      case 'cat_water':
      case 'water_works':
        return 'water_works';
      case 'drainage':
      case 'sewage':
      case 'cat_drainage':
        return 'storm_water_drain';
      case 'garden':
      case 'trees':
      case 'cat_garden':
        return 'garden_trees';
      case 'health':
      case 'cat_health':
        return 'public_health';
      case 'pest':
      case 'mosquito':
      case 'cat_pest':
        return 'pest_control_insecticide';
      case 'building':
      case 'encroachment':
        return 'building_factory';
      default:
        return 'general_administration';
    }
  }

  List<TimeTrendPoint> _generateRealTimeTrends(List<ComplaintModel> complaints, int days) {
    final now = DateTime.now();
    final points = <TimeTrendPoint>[];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = days - 1; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final label = days <= 7
          ? dayNames[targetDate.weekday - 1]
          : '${targetDate.day}/${targetDate.month}';

      final reported = complaints.where((c) =>
          c.createdAt.year == targetDate.year &&
          c.createdAt.month == targetDate.month &&
          c.createdAt.day == targetDate.day).length;

      final resolved = complaints.where((c) {
        if (c.status != ComplaintStatus.resolved) return false;
        final resDate = c.resolvedAt ?? c.updatedAt;
        return resDate.year == targetDate.year &&
            resDate.month == targetDate.month &&
            resDate.day == targetDate.day;
      }).length;

      points.add(TimeTrendPoint(
        date: targetDate,
        label: label,
        reportedCount: reported,
        resolvedCount: resolved,
      ));
    }

    return points;
  }
}
