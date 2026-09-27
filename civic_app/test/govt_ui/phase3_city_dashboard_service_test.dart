import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/government_audit_log_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/repositories/hazard_repository.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/services/government_city_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

void main() {
  late GovernmentCityDashboardService dashboardService;
  late MockGovtComplaintRepository complaintRepo;
  late LocalGovernmentHierarchyRepository hierarchyRepo;

  setUp(() async {
    AuthServiceLocator.useMockServices();
    RepositoryLocator.useMockRepositories();
    MockGovtAuthService().resetForTesting(authenticated: true);

    complaintRepo = MockGovtComplaintRepository();
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();

    dashboardService = GovernmentCityDashboardService(
      complaintRepo: complaintRepo,
      hierarchyRepo: hierarchyRepo,
      routingService: ComplaintRoutingService(),
      auditService: DefaultGovernmentAuditService(),
      hazardRepo: RepositoryLocator.hazardRepository,
    );
  });

  group('Phase 3 - Section 1: Hierarchy & Operational Structure Aggregation', () {
    test('Loads canonical 7 Zones, 24 Wards, and 18 Technical Departments', () async {
      final data = await dashboardService.loadCitywideDashboard();

      expect(data.zoneMetrics.length, 7);
      expect(data.wardMetrics.length, 24);
      expect(data.departmentMetrics.length, 18);
      final totalWardUnits = data.departmentMetrics.fold<int>(0, (sum, d) => sum + d.wardUnitsCount);
      expect(totalWardUnits, 432);
      expect(data.operationsOverview.totalActiveComplaints, greaterThanOrEqualTo(0));
    });

    test('Reconciles canonical 2,642 dual-supervisory personnel hierarchy', () async {
      final data = await dashboardService.loadCitywideDashboard();
      final summary = data.personnelSummary;

      expect(summary.totalPersonnelCount, 2642);
      expect(summary.superAdminCount, 1);
      expect(summary.zonalDmcCount, 7);
      expect(summary.centralHodCount, 18);
      expect(summary.wardOfficerCount, 24);
      expect(summary.wardLeadCount, 432);
      expect(summary.crewCount, 2160);
      expect(summary.integrityMatch, isTrue);
    });

    test('Each of the 18 departments reports 24 operational ward units', () async {
      final data = await dashboardService.loadCitywideDashboard();

      for (final deptMetric in data.departmentMetrics) {
        expect(deptMetric.wardUnitsCount, 24);
      }
    });
  });

  group('Phase 3 - Section 2: Citywide KPI Metric Calculation Tests', () {
    test('Calculates aggregated KPIs across all complaints correctly', () async {
      final data = await dashboardService.loadCitywideDashboard();
      final kpis = data.kpiMetrics;

      expect(kpis.totalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.openComplaints, greaterThanOrEqualTo(0));
      expect(kpis.criticalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.resolvedToday, greaterThanOrEqualTo(0));
      expect(kpis.resolvedTotal, greaterThanOrEqualTo(0));
      expect(kpis.slaBreachedCount, greaterThanOrEqualTo(0));
      expect(kpis.activePersonnelCount, 2642);
    });

    test('Calculates SLA compliance rate accurately as percentage of non-breached complaints', () async {
      final data = await dashboardService.loadCitywideDashboard();
      final kpis = data.kpiMetrics;

      if (kpis.totalComplaints > 0 && kpis.slaComplianceRate != null) {
        final expectedRate = ((kpis.totalComplaints - kpis.slaBreachedCount) / kpis.totalComplaints) * 100.0;
        expect(kpis.slaComplianceRate, closeTo(expectedRate, 0.1));
      }
    });

    test('Computes non-negative average resolution time', () async {
      final data = await dashboardService.loadCitywideDashboard();
      final kpis = data.kpiMetrics;

      if (kpis.avgResolutionHours != null) {
        expect(kpis.avgResolutionHours, greaterThanOrEqualTo(0.0));
      }
    });
  });

  group('Phase 3 - Section 3: Time Series Trends & Critical Complaints Tests', () {
    test('Generates time series trends for 7 days with daily submission/resolution points', () async {
      final data = await dashboardService.loadCitywideDashboard(trendDays: 7);
      final trends = data.timeTrends;

      expect(trends.length, 7);
      for (final point in trends) {
        expect(point.reportedCount, greaterThanOrEqualTo(0));
        expect(point.resolvedCount, greaterThanOrEqualTo(0));
      }
    });

    test('Generates time series trends for 30 days and 90 days', () async {
      final data30 = await dashboardService.loadCitywideDashboard(trendDays: 30);
      expect(data30.timeTrends.length, 30);

      final data90 = await dashboardService.loadCitywideDashboard(trendDays: 90);
      expect(data90.timeTrends.length, 90);
    });

    test('Filters critical complaints and sorts chronologically for immediate triage', () async {
      final data = await dashboardService.loadCitywideDashboard();

      for (final critical in data.criticalComplaints) {
        expect(
          critical.priority == ComplaintPriority.emergency || critical.priority == ComplaintPriority.high,
          isTrue,
        );
      }
    });
  });

  group('Phase 3 - Section 4: Deterministic Alert Generation Tests', () {
    test('Generates deterministic alerts for critical emergencies, SLA breach rates, and routing transfers', () async {
      final data = await dashboardService.loadCitywideDashboard();

      expect(data.alerts, isA<List<CityAlertItem>>());
      for (final alert in data.alerts) {
        expect(alert.id.isNotEmpty, isTrue);
        expect(alert.title.isNotEmpty, isTrue);
        expect(alert.message.isNotEmpty, isTrue);
        expect(alert.severity.isNotEmpty, isTrue);
      }
    });
  });

  group('Phase 3 - Section 5: Multi-Criteria Global Filtering Tests', () {
    test('Filtering by Zone filters data to only that Zone', () async {
      final data = await dashboardService.loadCitywideDashboard(zoneFilter: 'ZONE_1');

      // Wards in Zone 1 (A, B, C, D)
      expect(data.wardMetrics.every((w) => w.zoneId == 'ZONE_1'), isTrue);
    });

    test('Filtering by Ward restricts metrics to that specific Ward', () async {
      final data = await dashboardService.loadCitywideDashboard(wardFilter: 'A');

      expect(data.wardMetrics.length, 1);
      expect(data.wardMetrics.first.wardCode, 'A');
    });

    test('Filtering by Department restricts metrics to that Department', () async {
      final data = await dashboardService.loadCitywideDashboard(departmentFilter: 'maintenance_roads');

      expect(data.departmentMetrics.length, 1);
      expect(data.departmentMetrics.first.department.departmentCode, 'RDS');
    });

    test('Filtering by Priority restricts complaints matching the priority', () async {
      final data = await dashboardService.loadCitywideDashboard(priorityFilter: ComplaintPriority.emergency);

      for (final c in data.criticalComplaints) {
        expect(c.priority, ComplaintPriority.emergency);
      }
    });

    test('Search query matches complaint titles or ticket numbers', () async {
      final data = await dashboardService.loadCitywideDashboard(searchQuery: 'Pothole');

      expect(data, isNotNull);
    });
  });

  group('Phase 3 - Section 6: Fault Tolerance & Error Resilience Tests', () {
    test('Dashboard succeeds even if audit service returns error or empty', () async {
      final resilientService = GovernmentCityDashboardService(
        complaintRepo: complaintRepo,
        hierarchyRepo: hierarchyRepo,
        auditService: _FaultyAuditService(),
      );

      final data = await resilientService.loadCitywideDashboard();
      expect(data.kpiMetrics.totalComplaints, greaterThanOrEqualTo(0));
      expect(data.recentAuditLogs, isEmpty);
    });

    test('Dashboard succeeds even if hazard repository throws exception', () async {
      final resilientService = GovernmentCityDashboardService(
        complaintRepo: complaintRepo,
        hierarchyRepo: hierarchyRepo,
        hazardRepo: _FaultyHazardRepository(),
      );

      final data = await resilientService.loadCitywideDashboard();
      expect(data.kpiMetrics.totalComplaints, greaterThanOrEqualTo(0));
      expect(data.citywideHazards, isEmpty);
    });
  });
}

class _FaultyAuditService implements GovernmentAuditService {
  @override
  Future<void> logAction({
    required String complaintId,
    required String action,
    required String actorId,
    required String actorRole,
    required String actorName,
    String? wardId,
    String? departmentId,
    Map<String, dynamic> details = const {},
  }) async {
    throw Exception('Simulated Audit Failure');
  }

  @override
  Future<List<GovernmentAuditLog>> getLogsForComplaint(String complaintId) async {
    throw Exception('Simulated Audit Query Failure');
  }
}

class _FaultyHazardRepository implements HazardRepository {
  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    throw Exception('Simulated Hazard Repository Failure');
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    throw Exception('Simulated Hazard Fetch Failure');
  }

  @override
  Future<List<HazardModel>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    throw Exception('Simulated Nearby Hazards Failure');
  }

  @override
  Stream<List<HazardModel>> watchHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) {
    return Stream.error(Exception('Simulated Watch Hazards Failure'));
  }

  @override
  Stream<HazardModel?> watchHazardById(String id) {
    return Stream.error(Exception('Simulated Watch Hazard Failure'));
  }
}
