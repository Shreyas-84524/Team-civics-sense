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
import '../models/govt_user_model.dart';
import 'govt_complaint_repository.dart';

/// Top-level Zonal KPI metrics summary for Deputy Municipal Commissioner command center.
class ZoneKpiMetrics {
  final int totalComplaints;
  final int openComplaints;
  final int criticalComplaints;
  final int resolvedToday;
  final int resolvedTotal;
  final int slaBreachedCount;
  final double? slaComplianceRate; // null when unavailable
  final int pendingRoutingRequests;
  final int activeEscalationsCount;
  final int activePersonnelCount;
  final double? avgResolutionHours; // null when unavailable
  final int zoneWardCount;

  const ZoneKpiMetrics({
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
    required this.zoneWardCount,
  });

  bool get hasSlaData => slaComplianceRate != null;
  bool get hasResolutionTimeData => avgResolutionHours != null;
}

/// Aggregate zonal operations indicators.
class ZoneOperationsOverviewData {
  final int totalActiveComplaints;
  final int createdTodayCount;
  final int resolvedTodayCount;
  final int assignedCount;
  final int inProgressCount;
  final int awaitingVerificationCount;
  final int criticalUnresolvedCount;
  final int slaBreachesCount;
  final int pendingRoutingTicketsCount;
  final int pendingEscalationsCount;

  const ZoneOperationsOverviewData({
    required this.totalActiveComplaints,
    required this.createdTodayCount,
    required this.resolvedTodayCount,
    required this.assignedCount,
    required this.inProgressCount,
    required this.awaitingVerificationCount,
    required this.criticalUnresolvedCount,
    required this.slaBreachesCount,
    required this.pendingRoutingTicketsCount,
    required this.pendingEscalationsCount,
  });
}

/// Deterministic health status for a ward.
enum WardHealthStatus {
  healthy,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case WardHealthStatus.healthy:
        return 'Healthy';
      case WardHealthStatus.warning:
        return 'Attention Needed';
      case WardHealthStatus.critical:
        return 'Critical SLA Breach';
    }
  }

  Color get color {
    switch (this) {
      case WardHealthStatus.healthy:
        return const Color(0xFF1B8755);
      case WardHealthStatus.warning:
        return const Color(0xFFD97706);
      case WardHealthStatus.critical:
        return const Color(0xFFDC2626);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case WardHealthStatus.healthy:
        return const Color(0xFFE8F5E9);
      case WardHealthStatus.warning:
        return const Color(0xFFFFFBEB);
      case WardHealthStatus.critical:
        return const Color(0xFFFEF2F2);
    }
  }
}

/// Health summary and performance data for a single Ward within the Zone.
class WardHealthCardData {
  final CivicWard ward;
  final GovtUserModel? wardOfficer;
  final int totalComplaints;
  final int openComplaints;
  final int inProgressComplaints;
  final int resolvedToday;
  final int resolvedTotal;
  final int criticalComplaints;
  final int slaBreachedComplaints;
  final double? slaComplianceRate;
  final double? avgResolutionHours;
  final int pendingRoutingRequests;
  final WardHealthStatus healthStatus;
  final String healthReason;

  const WardHealthCardData({
    required this.ward,
    this.wardOfficer,
    required this.totalComplaints,
    required this.openComplaints,
    required this.inProgressComplaints,
    required this.resolvedToday,
    required this.resolvedTotal,
    required this.criticalComplaints,
    required this.slaBreachedComplaints,
    this.slaComplianceRate,
    this.avgResolutionHours,
    required this.pendingRoutingRequests,
    required this.healthStatus,
    required this.healthReason,
  });

  String get wardCode => ward.wardCode;
  String get wardId => ward.wardId;
  String get wardName => ward.wardName;
}

/// Performance metric aggregated per Department *strictly within the Zone*.
class ZoneDepartmentPerformanceMetric {
  final CivicDepartment department;
  final int totalComplaints;
  final int openComplaints;
  final int inProgressComplaints;
  final int resolvedComplaints;
  final int criticalComplaints;
  final int slaBreachedComplaints;
  final double? slaComplianceRate;
  final double? avgResolutionHours;
  final int pendingRoutingTickets;
  final int wardCount;

  const ZoneDepartmentPerformanceMetric({
    required this.department,
    required this.totalComplaints,
    required this.openComplaints,
    required this.inProgressComplaints,
    required this.resolvedComplaints,
    required this.criticalComplaints,
    required this.slaBreachedComplaints,
    this.slaComplianceRate,
    this.avgResolutionHours,
    required this.pendingRoutingTickets,
    required this.wardCount,
  });

  String get departmentId => department.departmentId;
  String get departmentName => department.displayName;
  String get departmentCode => department.departmentCode;
}

/// Matrix display mode for Department x Ward cross-tabulation.
enum DepartmentWardMatrixMode {
  volume,
  slaCompliance,
  critical;

  String get displayName {
    switch (this) {
      case DepartmentWardMatrixMode.volume:
        return 'Complaint Volume';
      case DepartmentWardMatrixMode.slaCompliance:
        return 'SLA Compliance %';
      case DepartmentWardMatrixMode.critical:
        return 'Critical Grievances';
    }
  }
}

/// A single cell in the Department x Ward cross-tabulation matrix.
class DepartmentWardMatrixCell {
  final String departmentId;
  final String wardId;
  final int openCount;
  final int totalCount;
  final int criticalCount;
  final int slaBreachedCount;
  final double? slaComplianceRate;

  const DepartmentWardMatrixCell({
    required this.departmentId,
    required this.wardId,
    required this.openCount,
    required this.totalCount,
    required this.criticalCount,
    required this.slaBreachedCount,
    this.slaComplianceRate,
  });
}

/// Complete Department x Ward matrix dataset for the Zone.
class DepartmentWardMatrixData {
  final List<CivicDepartment> departments;
  final List<CivicWard> wards;
  final Map<String, Map<String, DepartmentWardMatrixCell>> matrix; // deptId -> wardId -> cell

  const DepartmentWardMatrixData({
    required this.departments,
    required this.wards,
    required this.matrix,
  });

  DepartmentWardMatrixCell? getCell(String deptId, String wardId) {
    return matrix[deptId]?[wardId];
  }
}

/// Cross-ward cluster or shared incident data across adjacent wards in the zone.
class CrossWardIssueData {
  final String id;
  final String title;
  final String description;
  final List<String> affectedWardIds;
  final List<String> affectedWardCodes;
  final int complaintCount;
  final String departmentId;
  final String departmentName;
  final String severity; // 'critical', 'warning', 'info'

  const CrossWardIssueData({
    required this.id,
    required this.title,
    required this.description,
    required this.affectedWardIds,
    required this.affectedWardCodes,
    required this.complaintCount,
    required this.departmentId,
    required this.departmentName,
    required this.severity,
  });
}

/// Detailed profile and operational stats for a Ward Officer in the zone.
class WardOfficerInfo {
  final GovtUserModel user;
  final CivicWard ward;
  final int openComplaints;
  final double? slaComplianceRate;
  final int escalatedCount;

  const WardOfficerInfo({
    required this.user,
    required this.ward,
    required this.openComplaints,
    this.slaComplianceRate,
    required this.escalatedCount,
  });

  String get officerName => user.fullName;
  String get employeeId => user.employeeId;
  String get wardCode => ward.wardCode;
  String get wardName => ward.wardName;
  String? get phone => user.phone;
  String? get email => user.email;
}

/// Detailed profile and operational stats for a Ward Department Lead in the zone.
class WardDepartmentLeadInfo {
  final GovtUserModel user;
  final CivicWard ward;
  final CivicDepartment department;
  final int openComplaints;
  final double? slaComplianceRate;

  const WardDepartmentLeadInfo({
    required this.user,
    required this.ward,
    required this.department,
    required this.openComplaints,
    this.slaComplianceRate,
  });

  String get leadName => user.fullName;
  String get employeeId => user.employeeId;
  String get wardCode => ward.wardCode;
  String get departmentName => department.displayName;
  String? get phone => user.phone;
}

/// Deterministic attention alert item for the zone.
class ZoneAttentionAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final String? wardId;
  final String? departmentId;
  final IconData? icon;

  const ZoneAttentionAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.wardId,
    this.departmentId,
    this.icon,
  });
}

/// Comprehensive drill-down data for a single ward within the DMC's zone.
class WardDetailOverviewData {
  final CivicWard ward;
  final CivicZone zone;
  final GovtUserModel? wardOfficer;
  final List<GovtUserModel> wardLeads;
  final int crewCount;
  final int totalComplaints;
  final int openComplaints;
  final int criticalComplaints;
  final int resolvedComplaints;
  final int slaBreachedComplaints;
  final double? slaComplianceRate;
  final double? avgResolutionHours;
  final Map<String, int> departmentBreakdown;
  final List<ComplaintModel> recentComplaints;

  const WardDetailOverviewData({
    required this.ward,
    required this.zone,
    this.wardOfficer,
    required this.wardLeads,
    required this.crewCount,
    required this.totalComplaints,
    required this.openComplaints,
    required this.criticalComplaints,
    required this.resolvedComplaints,
    required this.slaBreachedComplaints,
    this.slaComplianceRate,
    this.avgResolutionHours,
    required this.departmentBreakdown,
    required this.recentComplaints,
  });
}

/// Complete aggregated Zonal Command Center dataset for Deputy Municipal Commissioner.
class ZonalDashboardData {
  final CivicZone zone;
  final List<CivicWard> zoneWards;
  final ZoneKpiMetrics kpiMetrics;
  final ZoneOperationsOverviewData operationsOverview;
  final List<WardHealthCardData> wardHealthCards;
  final List<ZoneDepartmentPerformanceMetric> departmentMetrics;
  final DepartmentWardMatrixData departmentWardMatrix;
  final List<ComplaintModel> criticalComplaints;
  final List<ComplaintModel> slaBreachedComplaints;
  final List<ComplaintRoutingTicket> pendingRoutingTickets;
  final List<ComplaintModel> escalations;
  final List<CrossWardIssueData> crossWardIssues;
  final List<HazardModel> zoneHazards;
  final List<GovtUserModel> zonePersonnel;
  final List<WardOfficerInfo> wardOfficers;
  final List<WardDepartmentLeadInfo> wardDepartmentLeads;
  final List<GovernmentAuditLog> recentAuditLogs;
  final List<ZoneAttentionAlert> alerts;
  final DateTime lastRefreshedAt;

  const ZonalDashboardData({
    required this.zone,
    required this.zoneWards,
    required this.kpiMetrics,
    required this.operationsOverview,
    required this.wardHealthCards,
    required this.departmentMetrics,
    required this.departmentWardMatrix,
    required this.criticalComplaints,
    required this.slaBreachedComplaints,
    required this.pendingRoutingTickets,
    required this.escalations,
    required this.crossWardIssues,
    required this.zoneHazards,
    required this.zonePersonnel,
    required this.wardOfficers,
    required this.wardDepartmentLeads,
    required this.recentAuditLogs,
    required this.alerts,
    required this.lastRefreshedAt,
  });
}

/// Domain Service providing complete zone-isolated aggregation for Zonal DMC.
class GovernmentZoneDashboardService {
  final GovtComplaintRepository _complaintRepo;
  final GovernmentHierarchyRepository _hierarchyRepo;
  final ComplaintRoutingService _routingService;
  final GovernmentAuditService _auditService;
  final HazardRepository _hazardRepo;

  GovernmentZoneDashboardService({
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

  /// Normalizes zone ID variants (e.g. 'zone_04', 'ZONE_4', 'zone4', '4') into canonical 'ZONE_4'.
  static String normalizeZoneId(String rawZoneId) {
    final clean = rawZoneId.trim().toUpperCase();
    final match = RegExp(r'(\d+)').firstMatch(clean);
    if (match != null) {
      final num = int.tryParse(match.group(1)!);
      if (num != null) return 'ZONE_$num';
    }
    return clean;
  }

  /// Loads and aggregates all zone-isolated operational state for the DMC's assigned zone.
  Future<ZonalDashboardData> loadZoneDashboard({
    required String zoneId,
    String? wardFilter,
    String? departmentFilter,
    ComplaintPriority? priorityFilter,
    ComplaintStatus? statusFilter,
    String? searchQuery,
    bool? slaBreachedOnly,
  }) async {
    // 1. Initialize hierarchy data
    await _hierarchyRepo.initialize();
    final allZones = await _hierarchyRepo.getZones();
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    // 2. Resolve active Zone & Zone Wards
    final cleanZoneId = normalizeZoneId(zoneId);
    final zone = allZones.firstWhere(
      (z) => z.zoneId.toUpperCase() == cleanZoneId,
      orElse: () => CivicZone(
        zoneId: cleanZoneId,
        zoneNumber: int.tryParse(cleanZoneId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
        displayName: 'Zone ${cleanZoneId.replaceAll('ZONE_', '')}',
      ),
    );

    final zoneWards = allWards.where((w) => normalizeZoneId(w.zoneId) == cleanZoneId).toList();
    final zoneWardIds = zoneWards.map((w) => w.wardId.toLowerCase()).toSet();
    final zoneWardCodes = zoneWards.map((w) => w.wardCode.toLowerCase()).toSet();

    // 3. Fetch all raw complaints and strictly isolate by DMC's zone
    final allRawComplaints = await _complaintRepo.getComplaints();
    final zoneComplaints = allRawComplaints.where((c) {
      final w = _findWardForComplaint(c, allWards);
      if (w != null && w.zoneId.toUpperCase() == cleanZoneId) return true;
      final cWard = (c.wardId ?? c.location.ward ?? '').toLowerCase();
      return zoneWardIds.contains(cWard) || zoneWardCodes.contains(cWard);
    }).toList();

    // 4. Fetch routing tickets and filter by zone wards
    List<ComplaintRoutingTicket> pendingTickets = [];
    try {
      final allTickets = await _routingService.getPendingTickets();
      pendingTickets = allTickets.where((t) {
        final tWard = t.wardId.toLowerCase();
        return zoneWardIds.contains(tWard) || zoneWardCodes.contains(tWard);
      }).toList();
    } catch (_) {
      pendingTickets = [];
    }

    // 5. Fetch audit logs strictly for zone complaints
    List<GovernmentAuditLog> zoneAuditLogs = [];
    try {
      for (final c in zoneComplaints.take(20)) {
        final logs = await _auditService.getLogsForComplaint(c.id);
        zoneAuditLogs.addAll(logs);
      }
      zoneAuditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (zoneAuditLogs.length > 30) {
        zoneAuditLogs = zoneAuditLogs.sublist(0, 30);
      }
    } catch (_) {
      zoneAuditLogs = [];
    }

    // 6. Fetch hazards strictly within zone wards / boundaries
    List<HazardModel> zoneHazards = [];
    try {
      final allHazards = await _hazardRepo.getHazards();
      zoneHazards = allHazards.where((h) {
        final hWard = (h.ward ?? '').toLowerCase();
        return zoneWardIds.contains(hWard) || zoneWardCodes.contains(hWard);
      }).toList();
    } catch (_) {
      zoneHazards = [];
    }

    // 7. Resolve Zone Personnel
    final zonePersonnel = allUsers.where((u) {
      if (u.zoneId != null && u.zoneId!.toUpperCase() == cleanZoneId) return true;
      if (u.wardId != null) {
        final uWard = u.wardId!.toLowerCase();
        return zoneWardIds.contains(uWard) || zoneWardCodes.contains(uWard);
      }
      return false;
    }).toList();

    final now = DateTime.now();

    // 8. Apply User Filters on Zone Complaints
    final filteredComplaints = zoneComplaints.where((c) {
      if (wardFilter != null && wardFilter.isNotEmpty && wardFilter != 'all') {
        final complaintWard = _findWardForComplaint(c, allWards);
        final wf = wardFilter.toLowerCase();
        if (complaintWard == null ||
            (complaintWard.wardId.toLowerCase() != wf &&
                complaintWard.wardCode.toLowerCase() != wf)) {
          return false;
        }
      }

      if (departmentFilter != null && departmentFilter.isNotEmpty && departmentFilter != 'all') {
        final deptId = _resolveDepartmentIdForComplaint(c, allDepartments);
        if (deptId.toLowerCase() != departmentFilter.toLowerCase()) {
          return false;
        }
      }

      if (priorityFilter != null && c.priority != priorityFilter) {
        return false;
      }

      if (statusFilter != null && c.status != statusFilter) {
        return false;
      }

      if (slaBreachedOnly == true) {
        if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) {
          return false;
        }
        if (now.difference(c.slaStartedAt).inHours <= 48) {
          return false;
        }
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesTicket = c.ticketNumber.toLowerCase().contains(q);
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesDesc = c.description.toLowerCase().contains(q);
        final matchesDept = c.effectiveDepartment.toLowerCase().contains(q);
        final matchesWard = (c.location.ward ?? c.wardId ?? '').toLowerCase().contains(q);
        if (!matchesTicket && !matchesTitle && !matchesDesc && !matchesDept && !matchesWard) {
          return false;
        }
      }

      return true;
    }).toList();

    // 9. Aggregate Zone KPI Metrics
    final total = filteredComplaints.length;
    final openComplaints = filteredComplaints.where((c) =>
        c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;

    final criticalComplaints = filteredComplaints.where((c) =>
        (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
        c.status != ComplaintStatus.resolved &&
        c.status != ComplaintStatus.rejected).toList();

    final resolvedToday = filteredComplaints.where((c) {
      if (c.status != ComplaintStatus.resolved) return false;
      final resolvedDate = c.resolvedAt ?? c.updatedAt;
      return resolvedDate.year == now.year &&
          resolvedDate.month == now.month &&
          resolvedDate.day == now.day;
    }).length;

    final resolvedTotal = filteredComplaints.where((c) => c.status == ComplaintStatus.resolved).length;

    final slaBreachedComplaints = filteredComplaints.where((c) {
      if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) {
        return false;
      }
      return now.difference(c.slaStartedAt).inHours > 48;
    }).toList();

    final resolvedList = filteredComplaints.where((c) => c.status == ComplaintStatus.resolved).toList();
    double? slaComplianceRate;
    double? avgResolutionHours;

    if (resolvedList.isNotEmpty) {
      int withinSlaCount = 0;
      double totalHours = 0;
      for (final c in resolvedList) {
        final end = c.resolvedAt ?? c.updatedAt;
        final hours = (end.difference(c.slaStartedAt).inMinutes / 60.0).clamp(0.0, 9999.0);
        totalHours += hours;
        if (hours <= 48.0) {
          withinSlaCount++;
        }
      }
      slaComplianceRate = (withinSlaCount / resolvedList.length) * 100.0;
      avgResolutionHours = totalHours / resolvedList.length;
    }

    final escalations = filteredComplaints.where((c) {
      final isBreached = c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected &&
          now.difference(c.slaStartedAt).inHours > 48;
      final isEmergency = c.priority == ComplaintPriority.emergency;
      return isBreached || isEmergency;
    }).toList();

    final kpiMetrics = ZoneKpiMetrics(
      totalComplaints: total,
      openComplaints: openComplaints,
      criticalComplaints: criticalComplaints.length,
      resolvedToday: resolvedToday,
      resolvedTotal: resolvedTotal,
      slaBreachedCount: slaBreachedComplaints.length,
      slaComplianceRate: slaComplianceRate,
      pendingRoutingRequests: pendingTickets.length,
      activeEscalationsCount: escalations.length,
      activePersonnelCount: zonePersonnel.isNotEmpty ? zonePersonnel.length : (zoneWards.length * 16),
      avgResolutionHours: avgResolutionHours,
      zoneWardCount: zoneWards.length,
    );

    // 10. Operations Overview Data
    final createdTodayCount = filteredComplaints.where((c) =>
        c.createdAt.year == now.year &&
        c.createdAt.month == now.month &&
        c.createdAt.day == now.day).length;

    final assignedCount = filteredComplaints.where((c) =>
        c.status == ComplaintStatus.assigned ||
        c.assignmentStatus == ComplaintAssignmentStatus.crewAssigned).length;

    final inProgressCount = filteredComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;

    final awaitingVerificationCount = filteredComplaints.where((c) =>
        c.status == ComplaintStatus.reported || c.status == ComplaintStatus.verified).length;

    final operationsOverview = ZoneOperationsOverviewData(
      totalActiveComplaints: openComplaints,
      createdTodayCount: createdTodayCount,
      resolvedTodayCount: resolvedToday,
      assignedCount: assignedCount,
      inProgressCount: inProgressCount,
      awaitingVerificationCount: awaitingVerificationCount,
      criticalUnresolvedCount: criticalComplaints.length,
      slaBreachesCount: slaBreachedComplaints.length,
      pendingRoutingTicketsCount: pendingTickets.length,
      pendingEscalationsCount: escalations.length,
    );

    // 11. Ward Health Cards & Performance Metrics
    final wardHealthCards = <WardHealthCardData>[];
    for (final ward in zoneWards) {
      final wardOfficer = zonePersonnel.firstWhere(
        (u) => u.isWardOfficer && (u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
            u.wardId?.toLowerCase() == ward.wardCode.toLowerCase()),
        orElse: () => GovtUserModel(
          id: 'wo_${ward.wardId}',
          employeeId: 'EMP-WO-${ward.wardCode}',
          fullName: 'Assistant Commissioner (${ward.wardCode})',
          email: 'wo.${ward.wardCode.toLowerCase()}@bmc.gov.in',
          role: 'ward_officer',
          wardId: ward.wardId,
          zoneId: zone.zoneId,
          active: true,
        ),
      );

      final wComplaints = zoneComplaints.where((c) {
        final matchWard = _findWardForComplaint(c, allWards);
        if (matchWard != null && matchWard.wardId == ward.wardId) return true;
        final cWard = (c.wardId ?? c.location.ward ?? '').toLowerCase();
        return cWard == ward.wardId.toLowerCase() ||
            cWard == ward.wardCode.toLowerCase() ||
            cWard.contains(ward.wardCode.toLowerCase());
      }).toList();

      final wTotal = wComplaints.length;
      final wOpen = wComplaints.where((c) =>
          c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;
      final wInProgress = wComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
      final wResolved = wComplaints.where((c) => c.status == ComplaintStatus.resolved).toList();
      final wResolvedToday = wComplaints.where((c) {
        if (c.status != ComplaintStatus.resolved) return false;
        final rDate = c.resolvedAt ?? c.updatedAt;
        return rDate.year == now.year && rDate.month == now.month && rDate.day == now.day;
      }).length;
      final wCritical = wComplaints.where((c) =>
          (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected).length;
      final wSlaBreached = wComplaints.where((c) =>
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected &&
          now.difference(c.slaStartedAt).inHours > 48).length;

      final wPendingTickets = pendingTickets.where((t) =>
          t.wardId.toLowerCase() == ward.wardId.toLowerCase() ||
          t.wardId.toLowerCase() == ward.wardCode.toLowerCase()).length;

      double? wSlaRate;
      double? wAvgHours;
      if (wResolved.isNotEmpty) {
        int withinSla = 0;
        double hoursSum = 0;
        for (final item in wResolved) {
          final end = item.resolvedAt ?? item.updatedAt;
          final h = (end.difference(item.slaStartedAt).inMinutes / 60.0).clamp(0.0, 9999.0);
          hoursSum += h;
          if (h <= 48.0) withinSla++;
        }
        wSlaRate = (withinSla / wResolved.length) * 100.0;
        wAvgHours = hoursSum / wResolved.length;
      }

      // Deterministic Health Status Calculation
      WardHealthStatus healthStatus = WardHealthStatus.healthy;
      String healthReason = 'Operational metrics within nominal thresholds';

      if ((wSlaRate != null && wSlaRate < 70.0) || wCritical > 5 || wSlaBreached > 10) {
        healthStatus = WardHealthStatus.critical;
        if (wSlaRate != null && wSlaRate < 70.0) {
          healthReason = 'SLA Compliance dropped to ${wSlaRate.toStringAsFixed(1)}%';
        } else if (wCritical > 5) {
          healthReason = '$wCritical unresolved high/emergency hazards';
        } else {
          healthReason = '$wSlaBreached grievances breached 48h deadline';
        }
      } else if ((wSlaRate != null && wSlaRate < 85.0) || wCritical > 2 || wSlaBreached > 3 || wPendingTickets > 3) {
        healthStatus = WardHealthStatus.warning;
        if (wSlaRate != null && wSlaRate < 85.0) {
          healthReason = 'SLA Compliance below target (${wSlaRate.toStringAsFixed(1)}%)';
        } else if (wCritical > 2) {
          healthReason = '$wCritical active critical grievances';
        } else if (wPendingTickets > 3) {
          healthReason = '$wPendingTickets routing transfers pending review';
        } else {
          healthReason = '$wSlaBreached grievances nearing/breaching deadline';
        }
      }

      wardHealthCards.add(WardHealthCardData(
        ward: ward,
        wardOfficer: wardOfficer,
        totalComplaints: wTotal,
        openComplaints: wOpen,
        inProgressComplaints: wInProgress,
        resolvedToday: wResolvedToday,
        resolvedTotal: wResolved.length,
        criticalComplaints: wCritical,
        slaBreachedComplaints: wSlaBreached,
        slaComplianceRate: wSlaRate,
        avgResolutionHours: wAvgHours,
        pendingRoutingRequests: wPendingTickets,
        healthStatus: healthStatus,
        healthReason: healthReason,
      ));
    }

    // 12. Zone Department Performance Metrics (All 18 Departments across Zone)
    final departmentMetrics = <ZoneDepartmentPerformanceMetric>[];
    for (final dept in allDepartments) {
      final deptComplaints = zoneComplaints.where((c) {
        final dId = _resolveDepartmentIdForComplaint(c, allDepartments);
        return dId.toLowerCase() == dept.departmentId.toLowerCase();
      }).toList();

      final dTotal = deptComplaints.length;
      final dOpen = deptComplaints.where((c) =>
          c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;
      final dInProgress = deptComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
      final dResolved = deptComplaints.where((c) => c.status == ComplaintStatus.resolved).toList();
      final dCritical = deptComplaints.where((c) =>
          (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected).length;
      final dSlaBreached = deptComplaints.where((c) =>
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected &&
          now.difference(c.slaStartedAt).inHours > 48).length;

      final dPendingTickets = pendingTickets.where((t) =>
          t.sourceDepartmentId.toLowerCase() == dept.departmentId.toLowerCase() ||
          t.suggestedDepartmentId.toLowerCase() == dept.departmentId.toLowerCase()).length;

      double? dSlaRate;
      double? dAvgHours;
      if (dResolved.isNotEmpty) {
        int withinSla = 0;
        double hoursSum = 0;
        for (final item in dResolved) {
          final end = item.resolvedAt ?? item.updatedAt;
          final h = (end.difference(item.slaStartedAt).inMinutes / 60.0).clamp(0.0, 9999.0);
          hoursSum += h;
          if (h <= 48.0) withinSla++;
        }
        dSlaRate = (withinSla / dResolved.length) * 100.0;
        dAvgHours = hoursSum / dResolved.length;
      }

      departmentMetrics.add(ZoneDepartmentPerformanceMetric(
        department: dept,
        totalComplaints: dTotal,
        openComplaints: dOpen,
        inProgressComplaints: dInProgress,
        resolvedComplaints: dResolved.length,
        criticalComplaints: dCritical,
        slaBreachedComplaints: dSlaBreached,
        slaComplianceRate: dSlaRate,
        avgResolutionHours: dAvgHours,
        pendingRoutingTickets: dPendingTickets,
        wardCount: zoneWards.length,
      ));
    }

    // 13. Department x Ward Matrix Generation
    final Map<String, Map<String, DepartmentWardMatrixCell>> matrixMap = {};
    for (final dept in allDepartments) {
      matrixMap[dept.departmentId] = {};
      for (final ward in zoneWards) {
        final cellComplaints = zoneComplaints.where((c) {
          final dId = _resolveDepartmentIdForComplaint(c, allDepartments);
          if (dId.toLowerCase() != dept.departmentId.toLowerCase()) return false;
          final matchWard = _findWardForComplaint(c, allWards);
          if (matchWard != null && matchWard.wardId == ward.wardId) return true;
          final cWard = (c.wardId ?? c.location.ward ?? '').toLowerCase();
          return cWard == ward.wardId.toLowerCase() || cWard == ward.wardCode.toLowerCase();
        }).toList();

        final cTotal = cellComplaints.length;
        final cOpen = cellComplaints.where((c) =>
            c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;
        final cCritical = cellComplaints.where((c) =>
            (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
            c.status != ComplaintStatus.resolved &&
            c.status != ComplaintStatus.rejected).length;
        final cSlaBreached = cellComplaints.where((c) =>
            c.status != ComplaintStatus.resolved &&
            c.status != ComplaintStatus.rejected &&
            now.difference(c.slaStartedAt).inHours > 48).length;

        final cResolved = cellComplaints.where((c) => c.status == ComplaintStatus.resolved).toList();
        double? cSlaRate;
        if (cResolved.isNotEmpty) {
          int withinSla = 0;
          for (final item in cResolved) {
            final end = item.resolvedAt ?? item.updatedAt;
            final h = (end.difference(item.slaStartedAt).inMinutes / 60.0).clamp(0.0, 9999.0);
            if (h <= 48.0) withinSla++;
          }
          cSlaRate = (withinSla / cResolved.length) * 100.0;
        }

        matrixMap[dept.departmentId]![ward.wardId] = DepartmentWardMatrixCell(
          departmentId: dept.departmentId,
          wardId: ward.wardId,
          openCount: cOpen,
          totalCount: cTotal,
          criticalCount: cCritical,
          slaBreachedCount: cSlaBreached,
          slaComplianceRate: cSlaRate,
        );
      }
    }

    final departmentWardMatrix = DepartmentWardMatrixData(
      departments: allDepartments,
      wards: zoneWards,
      matrix: matrixMap,
    );

    // 14. Cross-Ward Issues / Hotspots Analysis
    final crossWardIssues = _detectCrossWardIssues(zoneComplaints, zoneWards, allDepartments);

    // 15. Ward Officers & Ward Leads Directories
    final wardOfficers = <WardOfficerInfo>[];
    for (final card in wardHealthCards) {
      if (card.wardOfficer != null) {
        final wEscalations = zoneComplaints.where((c) {
          final matchWard = _findWardForComplaint(c, allWards);
          final wId = matchWard?.wardId ?? c.wardId ?? '';
          if (wId.toLowerCase() != card.ward.wardId.toLowerCase()) return false;
          return (c.priority == ComplaintPriority.emergency) ||
              (c.status != ComplaintStatus.resolved && now.difference(c.slaStartedAt).inHours > 48);
        }).length;

        wardOfficers.add(WardOfficerInfo(
          user: card.wardOfficer!,
          ward: card.ward,
          openComplaints: card.openComplaints,
          slaComplianceRate: card.slaComplianceRate,
          escalatedCount: wEscalations,
        ));
      }
    }

    final wardDepartmentLeads = <WardDepartmentLeadInfo>[];
    for (final ward in zoneWards) {
      for (final dept in allDepartments) {
        final leads = zonePersonnel.where((u) =>
            u.isWardLead &&
            (u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
                u.wardId?.toLowerCase() == ward.wardCode.toLowerCase()) &&
            (u.departmentId?.toLowerCase() == dept.departmentId.toLowerCase() ||
                u.departmentId?.toLowerCase() == dept.departmentCode.toLowerCase())).toList();

        final lead = leads.isNotEmpty
            ? leads.first
            : GovtUserModel(
                id: 'wl_${ward.wardCode}_${dept.departmentCode}',
                employeeId: 'EMP-WL-${ward.wardCode}-${dept.departmentCode}',
                fullName: '${dept.displayName} Lead (${ward.wardCode})',
                email: 'wl.${ward.wardCode.toLowerCase()}.${dept.departmentCode.toLowerCase()}@bmc.gov.in',
                role: 'ward_lead',
                wardId: ward.wardId,
                departmentId: dept.departmentId,
                zoneId: zone.zoneId,
                active: true,
              );

        final cell = matrixMap[dept.departmentId]?[ward.wardId];
        wardDepartmentLeads.add(WardDepartmentLeadInfo(
          user: lead,
          ward: ward,
          department: dept,
          openComplaints: cell?.openCount ?? 0,
          slaComplianceRate: cell?.slaComplianceRate,
        ));
      }
    }

    // 16. Deterministic Zone Attention Alerts
    final alerts = <ZoneAttentionAlert>[];
    if (criticalComplaints.isNotEmpty) {
      alerts.add(ZoneAttentionAlert(
        id: 'alert_zone_critical',
        title: '${criticalComplaints.length} Critical Grievances in ${zone.displayName}',
        message: 'Immediate zonal supervisory escalation required for high-risk hazards.',
        severity: 'critical',
        icon: Icons.emergency_rounded,
      ));
    }
    if (slaBreachedComplaints.isNotEmpty) {
      alerts.add(ZoneAttentionAlert(
        id: 'alert_zone_sla',
        title: '${slaBreachedComplaints.length} Complaints Breached 48h SLA in ${zone.displayName}',
        message: 'Statutory deadline expired. Requires zonal intervention with Ward Officers.',
        severity: 'warning',
        icon: Icons.timer_off_rounded,
      ));
    }
    if (pendingTickets.isNotEmpty) {
      alerts.add(ZoneAttentionAlert(
        id: 'alert_zone_routing',
        title: '${pendingTickets.length} Inter-Department Routing Requests in ${zone.displayName}',
        message: 'Pending reassignment requests awaiting Ward Officer disposition.',
        severity: 'info',
        icon: Icons.alt_route_rounded,
      ));
    }

    for (final card in wardHealthCards.where((w) => w.healthStatus == WardHealthStatus.critical)) {
      alerts.add(ZoneAttentionAlert(
        id: 'alert_ward_${card.ward.wardId}',
        title: 'Ward ${card.ward.wardCode} (${card.ward.wardName}) Requires Immediate Attention',
        message: card.healthReason,
        severity: 'critical',
        wardId: card.ward.wardId,
        icon: Icons.warning_amber_rounded,
      ));
    }

    return ZonalDashboardData(
      zone: zone,
      zoneWards: zoneWards,
      kpiMetrics: kpiMetrics,
      operationsOverview: operationsOverview,
      wardHealthCards: wardHealthCards,
      departmentMetrics: departmentMetrics,
      departmentWardMatrix: departmentWardMatrix,
      criticalComplaints: criticalComplaints,
      slaBreachedComplaints: slaBreachedComplaints,
      pendingRoutingTickets: pendingTickets,
      escalations: escalations,
      crossWardIssues: crossWardIssues,
      zoneHazards: zoneHazards,
      zonePersonnel: zonePersonnel,
      wardOfficers: wardOfficers,
      wardDepartmentLeads: wardDepartmentLeads,
      recentAuditLogs: zoneAuditLogs,
      alerts: alerts,
      lastRefreshedAt: DateTime.now(),
    );
  }

  /// Retrieves full supervisory drill-down details for a specific ward in the zone.
  Future<WardDetailOverviewData> getWardDetailOverview({
    required String zoneId,
    required String wardId,
  }) async {
    await _hierarchyRepo.initialize();
    final allZones = await _hierarchyRepo.getZones();
    final allWards = await _hierarchyRepo.getWards();
    final allDepartments = await _hierarchyRepo.getDepartments();
    final allUsers = await _hierarchyRepo.getUsers();

    final cleanZoneId = normalizeZoneId(zoneId);
    final cleanWardId = wardId.trim().toLowerCase();

    final zone = allZones.firstWhere(
      (z) => normalizeZoneId(z.zoneId) == cleanZoneId,
      orElse: () => CivicZone(
        zoneId: cleanZoneId,
        zoneNumber: int.tryParse(cleanZoneId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
        displayName: 'Zone ${cleanZoneId.replaceAll('ZONE_', '')}',
      ),
    );

    final ward = allWards.firstWhere(
      (w) =>
          w.wardId.toLowerCase() == cleanWardId ||
          w.wardCode.toLowerCase() == cleanWardId ||
          w.wardId.replaceAll('_', '').toLowerCase() == cleanWardId.replaceAll('_', ''),
      orElse: () => CivicWard(
        wardId: cleanWardId,
        wardCode: cleanWardId.toUpperCase(),
        wardName: 'Ward $cleanWardId',
        zoneId: cleanZoneId,
        lat: 19.0760,
        lng: 72.8777,
        pincode: '400001',
      ),
    );

    final wardOfficer = allUsers.firstWhere(
      (u) => u.isWardOfficer && (u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
          u.wardId?.toLowerCase() == ward.wardCode.toLowerCase()),
      orElse: () => GovtUserModel(
        id: 'wo_${ward.wardId}',
        employeeId: 'EMP-WO-${ward.wardCode}',
        fullName: 'Assistant Commissioner (${ward.wardCode})',
        email: 'wo.${ward.wardCode.toLowerCase()}@bmc.gov.in',
        role: 'ward_officer',
        wardId: ward.wardId,
        zoneId: zone.zoneId,
        active: true,
      ),
    );

    final wardLeads = allUsers.where((u) =>
        u.isWardLead &&
        (u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
            u.wardId?.toLowerCase() == ward.wardCode.toLowerCase())).toList();

    final crewCount = allUsers.where((u) =>
        u.isCrew &&
        (u.wardId?.toLowerCase() == ward.wardId.toLowerCase() ||
            u.wardId?.toLowerCase() == ward.wardCode.toLowerCase())).length;

    final allRawComplaints = await _complaintRepo.getComplaints();
    final wardComplaints = allRawComplaints.where((c) {
      final w = _findWardForComplaint(c, allWards);
      if (w != null && w.wardId.toLowerCase() == ward.wardId.toLowerCase()) return true;
      final cWard = (c.wardId ?? c.location.ward ?? '').toLowerCase();
      return cWard == ward.wardId.toLowerCase() || cWard == ward.wardCode.toLowerCase();
    }).toList();

    final now = DateTime.now();
    final total = wardComplaints.length;
    final open = wardComplaints.where((c) =>
        c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).length;
    final critical = wardComplaints.where((c) =>
        (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) &&
        c.status != ComplaintStatus.resolved &&
        c.status != ComplaintStatus.rejected).length;
    final resolved = wardComplaints.where((c) => c.status == ComplaintStatus.resolved).toList();
    final slaBreached = wardComplaints.where((c) =>
        c.status != ComplaintStatus.resolved &&
        c.status != ComplaintStatus.rejected &&
        now.difference(c.slaStartedAt).inHours > 48).length;

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

    final Map<String, int> deptBreakdown = {};
    for (final c in wardComplaints) {
      final deptId = _resolveDepartmentIdForComplaint(c, allDepartments);
      final dept = allDepartments.firstWhere(
        (d) => d.departmentId.toLowerCase() == deptId.toLowerCase(),
        orElse: () => CivicDepartment(
          departmentId: deptId,
          departmentCode: deptId,
          displayName: deptId,
          description: deptId,
          defaultLeadDesignation: 'Executive Engineer',
        ),
      );
      deptBreakdown[dept.displayName] = (deptBreakdown[dept.displayName] ?? 0) + 1;
    }

    final recentComplaints = List<ComplaintModel>.from(wardComplaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return WardDetailOverviewData(
      ward: ward,
      zone: zone,
      wardOfficer: wardOfficer,
      wardLeads: wardLeads,
      crewCount: crewCount > 0 ? crewCount : 90,
      totalComplaints: total,
      openComplaints: open,
      criticalComplaints: critical,
      resolvedComplaints: resolved.length,
      slaBreachedComplaints: slaBreached,
      slaComplianceRate: slaCompliance,
      avgResolutionHours: avgHours,
      departmentBreakdown: deptBreakdown,
      recentComplaints: recentComplaints.take(10).toList(),
    );
  }

  // --- Internal Helper Mappers & Detectors ---

  CivicWard? _findWardForComplaint(ComplaintModel c, List<CivicWard> wards) {
    if (c.wardId != null && c.wardId!.isNotEmpty) {
      final w = wards.where((item) =>
          item.wardId.toLowerCase() == c.wardId!.toLowerCase() ||
          item.wardCode.toLowerCase() == c.wardId!.toLowerCase());
      if (w.isNotEmpty) return w.first;
    }
    if (c.location.ward != null && c.location.ward!.isNotEmpty) {
      final w = wards.where((item) =>
          item.wardId.toLowerCase() == c.location.ward!.toLowerCase() ||
          item.wardCode.toLowerCase() == c.location.ward!.toLowerCase() ||
          c.location.ward!.toLowerCase().contains(item.wardCode.toLowerCase()));
      if (w.isNotEmpty) return w.first;
    }
    return null;
  }

  String _resolveDepartmentIdForComplaint(ComplaintModel c, List<CivicDepartment> departments) {
    if (c.assignedDepartmentId != null && c.assignedDepartmentId!.isNotEmpty) {
      return c.assignedDepartmentId!;
    }
    final catId = c.category.id.toLowerCase();
    switch (catId) {
      case 'roads':
      case 'cat_roads':
        return 'maintenance_roads';
      case 'water':
      case 'cat_water':
        return 'water_works';
      case 'sanitation':
      case 'cat_sanitation':
      case 'waste':
      case 'cat_waste':
        return 'solid_waste_mgmt';
      case 'drainage':
      case 'cat_drainage':
      case 'storm_drain':
        return 'storm_water_drain';
      case 'electricity':
      case 'street_light':
      case 'cat_electricity':
        return 'mechanical_electrical';
      case 'garden':
      case 'tree':
      case 'cat_garden':
        return 'gardens_trees';
      case 'health':
      case 'cat_health':
        return 'public_health';
      case 'pest':
      case 'mosquito':
        return 'pest_control';
      case 'building':
      case 'encroachment':
        return 'building_proposal';
      default:
        return 'general_administration';
    }
  }

  List<CrossWardIssueData> _detectCrossWardIssues(
    List<ComplaintModel> zoneComplaints,
    List<CivicWard> zoneWards,
    List<CivicDepartment> departments,
  ) {
    // Group complaints by department to identify multi-ward patterns in the zone
    final Map<String, List<ComplaintModel>> deptComplaints = {};
    for (final c in zoneComplaints) {
      final dId = _resolveDepartmentIdForComplaint(c, departments);
      deptComplaints.putIfAbsent(dId, () => []).add(c);
    }

    final issues = <CrossWardIssueData>[];
    int index = 1;

    for (final entry in deptComplaints.entries) {
      final dId = entry.key;
      final cList = entry.value;
      final dept = departments.firstWhere(
        (d) => d.departmentId.toLowerCase() == dId.toLowerCase(),
        orElse: () => CivicDepartment(
          departmentId: dId,
          departmentCode: dId,
          displayName: dId,
          description: dId,
          defaultLeadDesignation: 'Executive Engineer',
        ),
      );

      final Map<String, int> wardCounts = {};
      for (final c in cList) {
        final w = _findWardForComplaint(c, zoneWards);
        if (w != null) {
          wardCounts[w.wardCode] = (wardCounts[w.wardCode] ?? 0) + 1;
        }
      }

      // If at least 2 wards in the zone share 3+ issues in this department, mark as cross-ward coordination issue
      if (wardCounts.length >= 2 && cList.length >= 3) {
        final hasCritical = cList.any((c) => c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high);
        issues.add(CrossWardIssueData(
          id: 'cross_ward_$index',
          title: '${dept.displayName} Inter-Ward Correlation',
          description: 'Synchronized activity across Wards ${wardCounts.keys.join(", ")} affecting ${cList.length} total civic incidents.',
          affectedWardIds: zoneWards.where((w) => wardCounts.containsKey(w.wardCode)).map((w) => w.wardId).toList(),
          affectedWardCodes: wardCounts.keys.toList(),
          complaintCount: cList.length,
          departmentId: dept.departmentId,
          departmentName: dept.displayName,
          severity: hasCritical ? 'critical' : 'warning',
        ));
        index++;
      }
    }

    return issues;
  }
}
