import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/services/government_department_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

void main() {
  late GovernmentDepartmentDashboardService dashboardService;
  late MockGovtComplaintRepository complaintRepo;
  late LocalGovernmentHierarchyRepository hierarchyRepo;

  setUp(() async {
    AuthServiceLocator.useMockServices();
    RepositoryLocator.useMockRepositories();
    MockGovtAuthService().resetForTesting(authenticated: true);

    complaintRepo = MockGovtComplaintRepository();
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();

    dashboardService = GovernmentDepartmentDashboardService(
      complaintRepo: complaintRepo,
      hierarchyRepo: hierarchyRepo,
      routingService: ComplaintRoutingService(),
      auditService: DefaultGovernmentAuditService(),
      hazardRepo: RepositoryLocator.hazardRepository,
    );
  });

  group('Phase 5 - Section 1: Jurisdictional Isolation & Department Scoping Tests', () {
    test('Strictly loads SWM department across all 24 wards and 7 zones', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      expect(data.department.departmentId, 'solid_waste_management');
      expect(data.allWards.length, 24);
      expect(data.allZones.length, 7);
      expect(data.wardUnitPerformances.length, 24);
      expect(data.zoneBreakdowns.length, 7);
    });

    test('Zero out-of-department data leakage in complaints', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      for (final complaint in data.criticalComplaints) {
        final deptMatch = GovernmentDepartmentDashboardService.matchesDepartment(
          complaint.assignedDepartmentId ?? complaint.departmentName ?? complaint.category.id,
          'solid_waste_management',
        );
        expect(deptMatch, isTrue,
            reason: 'Complaint ${complaint.id} belonging to other department leaked into SWM dashboard');
      }
    });

    test('Zero out-of-department data leakage in department leads', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      // Verify all ward leads belong to SWM
      for (final leadUnit in data.departmentLeads) {
        expect(leadUnit.lead, isNotNull);
        final deptMatch = GovernmentDepartmentDashboardService.matchesDepartment(
          leadUnit.lead!.departmentId,
          'solid_waste_management',
        );
        expect(deptMatch, isTrue,
            reason: 'Ward lead ${leadUnit.lead!.fullName} (${leadUnit.lead!.departmentId}) leaked into SWM dashboard');
      }
    });

    test('Zero out-of-department data leakage in hazard pins', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      for (final hazard in data.departmentHazards) {
        final categoryMatch = GovernmentDepartmentDashboardService.matchesDepartment(
          hazard.category.id,
          'solid_waste_management',
        );
        expect(categoryMatch, isTrue,
            reason: 'Hazard ${hazard.id} belonging to other category leaked into SWM dashboard');
      }
    });
  });

  group('Phase 5 - Section 2: Department KPI Metrics Calculation Tests', () {
    test('Calculates aggregated department KPIs accurately', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );
      final kpis = data.kpiMetrics;

      expect(kpis.totalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.openComplaints, greaterThanOrEqualTo(0));
      expect(kpis.criticalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.resolvedToday, greaterThanOrEqualTo(0));
      expect(kpis.resolvedTotal, greaterThanOrEqualTo(0));
      expect(kpis.slaBreachedCount, greaterThanOrEqualTo(0));
      expect(kpis.activeWardUnitsCount, 24);
      expect(kpis.activePersonnelCount, greaterThanOrEqualTo(145)); // 1 HOD + 24 Leads + 120 Crew
    });

    test('SLA compliance rate is bounded between 0.0% and 100.0%', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      if (data.kpiMetrics.slaComplianceRate != null) {
        expect(data.kpiMetrics.slaComplianceRate, greaterThanOrEqualTo(0.0));
        expect(data.kpiMetrics.slaComplianceRate, lessThanOrEqualTo(100.0));
      }
    });
  });

  group('Phase 5 - Section 3: 24-Ward Performance Table Tests', () {
    test('All 24 BMC wards are present with unit performance metrics', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      expect(data.wardUnitPerformances.length, 24);

      final wardIds = data.wardUnitPerformances.map((w) => w.ward.wardId).toSet();
      // Check representative wards across City, Western, and Eastern zones
      expect(wardIds.contains('A'), isTrue);
      expect(wardIds.contains('K_WEST'), isTrue);
      expect(wardIds.contains('T'), isTrue);
      expect(wardIds.contains('P_NORTH'), isTrue);

      for (final unit in data.wardUnitPerformances) {
        expect(unit.leadName.isNotEmpty, isTrue);
        expect(unit.crewCount, greaterThanOrEqualTo(1));
        if (unit.slaComplianceRate != null) {
          expect(unit.slaComplianceRate, greaterThanOrEqualTo(0.0));
          expect(unit.slaComplianceRate, lessThanOrEqualTo(100.0));
        }
      }
    });
  });

  group('Phase 5 - Section 4: 7-Zone Breakdown Tests', () {
    test('All 7 BMC zones are present in zone breakdown', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      expect(data.zoneBreakdowns.length, 7);

      final zoneIds = data.zoneBreakdowns.map((z) => z.zoneId).toSet();
      for (int i = 1; i <= 7; i++) {
        expect(zoneIds.contains('ZONE_$i') || zoneIds.contains('Zone $i'), isTrue);
      }

      int totalWardsSum = 0;
      for (final zb in data.zoneBreakdowns) {
        totalWardsSum += zb.wardCount;
      }
      expect(totalWardsSum, 24);
    });
  });

  group('Phase 5 - Section 5: Routing Requests & SLA Monitoring Tests', () {
    test('Filters routing requests involving the department', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      for (final ticket in data.routingTickets) {
        final matches = GovernmentDepartmentDashboardService.matchesDepartment(
              ticket.sourceDepartmentId,
              'solid_waste_management',
            ) ||
            GovernmentDepartmentDashboardService.matchesDepartment(
              ticket.suggestedDepartmentId,
              'solid_waste_management',
            );
        expect(matches, isTrue);
      }
    });

    test('SLA monitoring data contains ward and zone compliance breakdown', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      final slaData = data.slaMonitoringData;
      expect(slaData.breachCountByWard, isNotNull);
      expect(slaData.breachCountByZone, isNotNull);
      expect(slaData.totalBreached, greaterThanOrEqualTo(0));
    });
  });

  group('Phase 5 - Section 6: Personnel & Crew Distribution Tests', () {
    test('Personnel summary matches staff structure (1 HOD + 24 Leads + Crew)', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      final p = data.personnelSummary;
      expect(p.hod, isNotNull);
      expect(p.leadCount, greaterThanOrEqualTo(24));
      expect(p.crewCount, greaterThanOrEqualTo(120));
      expect(p.totalPersonnelCount, greaterThanOrEqualTo(145));
    });

    test('Crew distribution covers all 24 wards with technicians per ward', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
      );

      expect(data.crewDistribution.length, 24);
      for (final dist in data.crewDistribution) {
        expect(dist.crewMembers.length, greaterThanOrEqualTo(1));
        expect(dist.wardCode.isNotEmpty, isTrue);
      }
    });
  });

  group('Phase 5 - Section 7: Ward Unit Drill-down Data Retrieval Tests', () {
    test('Retrieves comprehensive drill-down details for a specific ward unit', () async {
      final unitDetail = await dashboardService.getWardUnitDetailOverview(
        departmentId: 'solid_waste_management',
        wardId: 'A',
      );

      expect(unitDetail.department.departmentId, 'solid_waste_management');
      expect(unitDetail.ward.wardCode, 'A');
      expect(unitDetail.zone.zoneId, 'ZONE_1');
      expect(unitDetail.lead.isWardLead, isTrue);
      expect(unitDetail.crewMembers.isNotEmpty, isTrue);
      expect(unitDetail.totalComplaints, greaterThanOrEqualTo(0));
    });
  });

  group('Phase 5 - Section 8: Multi-Criteria Filtering Tests', () {
    test('Filtering by Zone restricts ward performance to only that zone', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
        zoneFilter: 'ZONE_1',
      );

      // Zone 1 has 3 wards (A, B, C)
      expect(data.wardUnitPerformances.length, 3);
      for (final wp in data.wardUnitPerformances) {
        expect(wp.zone.zoneId, 'ZONE_1');
      }
    });

    test('Filtering by Ward restricts ward performance to single ward', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
        wardFilter: 'A',
      );

      expect(data.wardUnitPerformances.length, 1);
      expect(data.wardUnitPerformances.first.wardCode, 'A');
    });

    test('Filtering by SLA Breached Only works correctly', () async {
      final data = await dashboardService.loadDepartmentDashboard(
        departmentId: 'solid_waste_management',
        slaBreachedOnly: true,
      );

      for (final c in data.criticalComplaints) {
        expect(c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected, isTrue);
      }
    });
  });
}
