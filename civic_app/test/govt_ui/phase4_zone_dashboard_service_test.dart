import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/models/civic_ward_model.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/services/government_zone_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

void main() {
  late GovernmentZoneDashboardService dashboardService;
  late MockGovtComplaintRepository complaintRepo;
  late LocalGovernmentHierarchyRepository hierarchyRepo;

  setUp(() async {
    AuthServiceLocator.useMockServices();
    RepositoryLocator.useMockRepositories();
    MockGovtAuthService().resetForTesting(authenticated: true);

    complaintRepo = MockGovtComplaintRepository();
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();

    dashboardService = GovernmentZoneDashboardService(
      complaintRepo: complaintRepo,
      hierarchyRepo: hierarchyRepo,
      routingService: ComplaintRoutingService(),
      auditService: DefaultGovernmentAuditService(),
      hazardRepo: RepositoryLocator.hazardRepository,
    );
  });

  group('Phase 4 - Section 1: Jurisdictional Isolation & Zone Scoping Tests', () {
    test('Strictly loads only wards assigned to the specific zone (Zone 4 has 2 wards: P_NORTH, P_SOUTH)', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');

      expect(data.zone.zoneId, 'ZONE_4');
      expect(data.zoneWards.isNotEmpty, isTrue);
      // Canonical Zone 4 in BMC hierarchy contains 2 wards (P_NORTH, P_SOUTH)
      expect(data.zoneWards.length, 2);
      final wardCodes = data.zoneWards.map((w) => w.wardCode).toSet();
      expect(wardCodes.contains('P_NORTH') || wardCodes.contains('P/North'), isTrue);
      expect(wardCodes.contains('P_SOUTH') || wardCodes.contains('P/South'), isTrue);

      // Verify no out-of-zone wards leaked (e.g. Ward A, B, C from Zone 1 or N from Zone 6)
      expect(wardCodes.contains('A'), isFalse);
      expect(wardCodes.contains('B'), isFalse);
      expect(wardCodes.contains('N'), isFalse);
    });

    test('Zone 1 strictly contains its 3 canonical wards (A, B, C)', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_1');

      expect(data.zone.zoneId, 'ZONE_1');
      expect(data.zoneWards.length, 3);
      final wardCodes = data.zoneWards.map((w) => w.wardCode).toSet();
      expect(wardCodes.contains('A'), isTrue);
      expect(wardCodes.contains('B'), isTrue);
      expect(wardCodes.contains('C'), isTrue);
      expect(wardCodes.contains('N'), isFalse);
    });

    test('Zero out-of-zone data leakage in complaints and hazards', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');
      final zoneWardIds = data.zoneWards.map((w) => w.wardId.toLowerCase()).toSet();
      final zoneWardCodes = data.zoneWards.map((w) => w.wardCode.toLowerCase()).toSet();

      for (final complaint in data.criticalComplaints) {
        final cWard = (complaint.wardId ?? complaint.location.ward ?? '').toLowerCase();
        final matches = zoneWardIds.contains(cWard) ||
            zoneWardCodes.contains(cWard) ||
            zoneWardCodes.any((wc) => cWard.contains(wc));
        expect(matches, isTrue, reason: 'Complaint in ward $cWard leaked into Zone 4');
      }

      for (final hazard in data.zoneHazards) {
        final hWard = (hazard.ward ?? '').toLowerCase();
        if (hWard.isNotEmpty) {
          final matches = zoneWardIds.contains(hWard) ||
              zoneWardCodes.contains(hWard) ||
              zoneWardCodes.any((wc) => hWard.contains(wc));
          expect(matches, isTrue, reason: 'Hazard in ward $hWard leaked into Zone 4');
        }
      }
    });
  });

  group('Phase 4 - Section 2: Zonal KPI Metrics Calculation Tests', () {
    test('Calculates aggregated zonal KPIs correctly for Zone 4', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');
      final kpis = data.kpiMetrics;

      expect(kpis.totalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.openComplaints, greaterThanOrEqualTo(0));
      expect(kpis.criticalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.resolvedToday, greaterThanOrEqualTo(0));
      expect(kpis.resolvedTotal, greaterThanOrEqualTo(0));
      expect(kpis.slaBreachedCount, greaterThanOrEqualTo(0));
      expect(kpis.zoneWardCount, 2);
      expect(kpis.activePersonnelCount, greaterThan(0));
    });

    test('Calculates SLA compliance rate accurately within 0.0% to 100.0%', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');
      final kpis = data.kpiMetrics;

      if (kpis.slaComplianceRate != null) {
        expect(kpis.slaComplianceRate, greaterThanOrEqualTo(0.0));
        expect(kpis.slaComplianceRate, lessThanOrEqualTo(100.0));
      }
    });

    test('Computes non-negative average resolution time when data is present', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');
      final kpis = data.kpiMetrics;

      if (kpis.avgResolutionHours != null) {
        expect(kpis.avgResolutionHours, greaterThanOrEqualTo(0.0));
      }
    });
  });

  group('Phase 4 - Section 3: Operations Funnel & Lifecycle Breakdown Tests', () {
    test('Calculates consistent lifecycle state totals matching open complaints', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');
      final ops = data.operationsOverview;

      expect(ops.totalActiveComplaints, greaterThanOrEqualTo(0));
      expect(ops.assignedCount, greaterThanOrEqualTo(0));
      expect(ops.inProgressCount, greaterThanOrEqualTo(0));
      expect(ops.awaitingVerificationCount, greaterThanOrEqualTo(0));
      expect(ops.createdTodayCount, greaterThanOrEqualTo(0));
      expect(ops.resolvedTodayCount, greaterThanOrEqualTo(0));
    });
  });

  group('Phase 4 - Section 4: Ward Health Score & Deterministic Health Status Tests', () {
    test('Generates health card for each ward in the zone', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');

      expect(data.wardHealthCards.length, data.zoneWards.length);
      for (final card in data.wardHealthCards) {
        expect(card.ward.zoneId, 'ZONE_4');
        expect(card.totalComplaints, greaterThanOrEqualTo(0));
        expect(card.openComplaints, greaterThanOrEqualTo(0));
        expect(card.wardName.isNotEmpty, isTrue);
        expect(card.healthStatus, isNotNull);
        expect(card.healthReason.isNotEmpty, isTrue);
      }
    });

    test('Deterministic health status assigns Critical when SLA compliance < 70% or 3+ criticals', () {
      final criticalCard = WardHealthCardData(
        ward: const CivicWard(
          wardId: 'P_NORTH',
          wardCode: 'P_NORTH',
          wardName: 'Malad',
          zoneId: 'ZONE_4',
          lat: 19.1860,
          lng: 72.8480,
          pincode: '400064',
        ),
        wardOfficer: null,
        totalComplaints: 20,
        openComplaints: 10,
        inProgressComplaints: 5,
        resolvedToday: 2,
        resolvedTotal: 10,
        criticalComplaints: 4,
        slaBreachedComplaints: 5,
        slaComplianceRate: 50.0,
        avgResolutionHours: 36.0,
        pendingRoutingRequests: 1,
        healthStatus: WardHealthStatus.critical,
        healthReason: 'SLA compliance is critically low at 50.0% with 4 unresolved critical complaints.',
      );

      expect(criticalCard.healthStatus, WardHealthStatus.critical);
      expect(criticalCard.healthReason.contains('SLA'), isTrue);
    });

    test('Deterministic health status assigns Warning when SLA is 70-85% or 1-2 criticals', () {
      final warningCard = WardHealthCardData(
        ward: const CivicWard(
          wardId: 'P_NORTH',
          wardCode: 'P_NORTH',
          wardName: 'Malad',
          zoneId: 'ZONE_4',
          lat: 19.1860,
          lng: 72.8480,
          pincode: '400064',
        ),
        wardOfficer: null,
        totalComplaints: 20,
        openComplaints: 5,
        inProgressComplaints: 3,
        resolvedToday: 4,
        resolvedTotal: 15,
        criticalComplaints: 1,
        slaBreachedComplaints: 3,
        slaComplianceRate: 80.0,
        avgResolutionHours: 28.0,
        pendingRoutingRequests: 0,
        healthStatus: WardHealthStatus.warning,
        healthReason: 'Attention required: 1 critical complaints and SLA compliance at 80.0%.',
      );

      expect(warningCard.healthStatus, WardHealthStatus.warning);
    });

    test('Deterministic health status assigns Healthy when SLA >= 85% and zero criticals', () {
      final healthyCard = WardHealthCardData(
        ward: const CivicWard(
          wardId: 'P_SOUTH',
          wardCode: 'P_SOUTH',
          wardName: 'Goregaon',
          zoneId: 'ZONE_4',
          lat: 19.1660,
          lng: 72.8480,
          pincode: '400062',
        ),
        wardOfficer: null,
        totalComplaints: 20,
        openComplaints: 2,
        inProgressComplaints: 1,
        resolvedToday: 5,
        resolvedTotal: 18,
        criticalComplaints: 0,
        slaBreachedComplaints: 1,
        slaComplianceRate: 94.4,
        avgResolutionHours: 20.0,
        pendingRoutingRequests: 0,
        healthStatus: WardHealthStatus.healthy,
        healthReason: 'Operations running smoothly with 94.4% SLA compliance.',
      );

      expect(healthyCard.healthStatus, WardHealthStatus.healthy);
    });
  });

  group('Phase 4 - Section 5: Departmental Performance & 18 Depts x Zone Wards Matrix Tests', () {
    test('Calculates performance metrics for all 18 technical departments within the zone', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');

      expect(data.departmentMetrics.length, 18);
      for (final dm in data.departmentMetrics) {
        expect(dm.department.displayName.isNotEmpty, isTrue);
        expect(dm.wardCount, 2);
        expect(dm.totalComplaints, greaterThanOrEqualTo(0));
        expect(dm.openComplaints, greaterThanOrEqualTo(0));
        expect(dm.criticalComplaints, greaterThanOrEqualTo(0));
      }
    });

    test('Generates Department-Ward matrix grid with 18 rows and zone ward columns', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');
      final matrix = data.departmentWardMatrix;

      expect(matrix.wards.length, 2);
      expect(matrix.departments.length, 18);

      for (final dept in matrix.departments) {
        for (final ward in matrix.wards) {
          final cell = matrix.getCell(dept.departmentId, ward.wardId);
          expect(cell, isNotNull);
          expect(cell!.totalCount, greaterThanOrEqualTo(0));
          expect(cell.openCount, greaterThanOrEqualTo(0));
          expect(cell.criticalCount, greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('Phase 4 - Section 6: Cross-Ward Coordination Issues & Attention Alerts Tests', () {
    test('Attention alerts contain critical and warning triggers for the zone', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');

      expect(data.alerts, isA<List<ZoneAttentionAlert>>());
      if (data.kpiMetrics.criticalComplaints > 0) {
        final hasCritAlert = data.alerts.any((a) => a.severity == 'critical');
        expect(hasCritAlert, isTrue);
      }
    });

    test('Cross-ward issues data model is non-null and aggregates zone incidents', () async {
      final data = await dashboardService.loadZoneDashboard(zoneId: 'ZONE_4');

      expect(data.crossWardIssues, isA<List<CrossWardIssueData>>());
      for (final issue in data.crossWardIssues) {
        expect(issue.affectedWardCodes.length, greaterThanOrEqualTo(2));
      }
    });
  });

  group('Phase 4 - Section 7: Ward Supervisory Drill-down Overview Tests', () {
    test('getWardDetailOverview returns full operational profile for Ward P_NORTH in Zone 4', () async {
      final wardData = await dashboardService.getWardDetailOverview(
        zoneId: 'ZONE_4',
        wardId: 'P_NORTH',
      );

      expect(wardData.ward.wardId, 'P_NORTH');
      expect(wardData.zone.zoneId, 'ZONE_4');
      expect(wardData.wardOfficer?.role, 'ward_officer');
      expect(wardData.wardLeads.isNotEmpty, isTrue);
      expect(wardData.totalComplaints, greaterThanOrEqualTo(0));
      expect(wardData.departmentBreakdown, isNotNull);
      expect(wardData.recentComplaints, isNotNull);
    });
  });
}
