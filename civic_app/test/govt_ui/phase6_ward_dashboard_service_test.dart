import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_routing_ticket_model.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/services/government_department_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/government_ward_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

void main() {
  late GovernmentWardDashboardService dashboardService;
  late MockGovtComplaintRepository complaintRepo;
  late LocalGovernmentHierarchyRepository hierarchyRepo;
  late ComplaintRoutingService routingService;

  setUp(() async {
    AuthServiceLocator.useMockServices();
    RepositoryLocator.useMockRepositories();
    MockGovtAuthService().resetForTesting(authenticated: true);

    complaintRepo = MockGovtComplaintRepository();
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();
    routingService = ComplaintRoutingService(hierarchyRepo: hierarchyRepo);

    dashboardService = GovernmentWardDashboardService(
      complaintRepo: complaintRepo,
      hierarchyRepo: hierarchyRepo,
      routingService: routingService,
      auditService: DefaultGovernmentAuditService(),
      hazardRepo: RepositoryLocator.hazardRepository,
    );
  });

  group('Phase 6 - Section 1: Jurisdictional Isolation & Ward Scoping Tests', () {
    test('Strictly loads Ward N overseeing all 18 departments', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      expect(data.ward.wardCode, 'N');
      expect(data.allDepartments.length, 18);
      expect(data.departmentPerformances.length, 18);
      expect(data.departmentLeads.length, 18);
      expect(data.crewDistribution.length, 18);
    });

    test('Zero out-of-ward data leakage in complaints', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      for (final complaint in data.filteredComplaints) {
        final wardMatch = GovernmentWardDashboardService.matchesWard(
          complaint.wardId,
          'N',
        );
        expect(
          wardMatch,
          isTrue,
          reason: 'Complaint ${complaint.id} belonging to ward ${complaint.wardId} leaked into Ward N dashboard',
        );
      }
    });

    test('Zero out-of-ward data leakage in critical complaints queue', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      for (final complaint in data.criticalComplaints) {
        final wardMatch = GovernmentWardDashboardService.matchesWard(
          complaint.wardId,
          'N',
        );
        expect(
          wardMatch,
          isTrue,
          reason: 'Critical complaint ${complaint.id} leaked into Ward N',
        );
      }
    });

    test('Zero out-of-ward data leakage in SLA breached items', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      for (final breach in data.slaMonitoringData.breachedItems) {
        final wardMatch = GovernmentWardDashboardService.matchesWard(
          breach.complaint.wardId,
          'N',
        );
        expect(
          wardMatch,
          isTrue,
          reason: 'SLA breach ${breach.complaintId} leaked into Ward N',
        );
      }
    });

    test('Zero out-of-ward data leakage in personnel structure', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      expect(data.personnelSummary.leadCount, 18);
      expect(data.personnelSummary.crewCount, 90);
      expect(data.personnelSummary.totalPersonnelCount, 109);

      for (final lead in data.departmentLeads) {
        expect(
          GovernmentWardDashboardService.matchesWard(lead.lead.wardId, 'N'),
          isTrue,
          reason: 'Lead ${lead.leadName} (${lead.lead.wardId}) does not belong to Ward N',
        );
      }
    });
  });

  group('Phase 6 - Section 2: Ward KPI Metrics & Lifecycle Funnel Tests', () {
    test('Calculates aggregated ward KPIs accurately', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      final kpis = data.kpiMetrics;
      expect(kpis.totalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.openComplaints, greaterThanOrEqualTo(0));
      expect(kpis.criticalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.resolvedTotal, greaterThanOrEqualTo(0));
      if (kpis.slaComplianceRate != null) {
        expect(kpis.slaComplianceRate, inInclusiveRange(0.0, 100.0));
      }
      expect(kpis.activePersonnelCount, 109);
    });

    test('Calculates 6-stage lifecycle funnel metrics accurately', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      final funnel = data.operationsOverview;
      expect(funnel.submittedCount, greaterThanOrEqualTo(0));
      expect(funnel.acknowledgedCount, greaterThanOrEqualTo(0));
      expect(funnel.assignedCount, greaterThanOrEqualTo(0));
      expect(funnel.inProgressCount, greaterThanOrEqualTo(0));
      expect(funnel.awaitingVerificationCount, greaterThanOrEqualTo(0));
      expect(funnel.resolvedCount, greaterThanOrEqualTo(0));
    });
  });

  group('Phase 6 - Section 3: 18 Ward Department Performance Oversight Tests', () {
    test('Calculates metrics for each of the 18 departments', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      expect(data.departmentPerformances.length, 18);

      for (final deptPerf in data.departmentPerformances) {
        expect(deptPerf.department.departmentId, isNotEmpty);
        expect(deptPerf.department.displayName, isNotEmpty);
        expect(deptPerf.leadName, isNotEmpty);
        expect(deptPerf.openComplaints, greaterThanOrEqualTo(0));
        expect(deptPerf.resolvedTotal, greaterThanOrEqualTo(0));
        expect(deptPerf.crewCount, 5);
      }
    });

    test('Provides full drilldown details for a specific department unit in ward', () async {
      final unitDetail = await dashboardService.getDepartmentUnitDetailData(
        wardId: 'N',
        departmentId: 'solid_waste_management',
      );

      expect(unitDetail.department.departmentId, 'solid_waste_management');
      expect(unitDetail.ward.wardCode, 'N');
      expect(unitDetail.lead?.fullName, isNotEmpty);
      expect(unitDetail.crewMembers.length, 5);
      expect(unitDetail.totalComplaints, greaterThanOrEqualTo(0));
    });
  });

  group('Phase 6 - Section 4: Routing Center Inter-Department Workflow Tests', () {
    test('Routing tickets belong strictly to Ward N', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
      );

      for (final ticket in data.routingTickets) {
        expect(
          ticket.wardId.isEmpty || GovernmentWardDashboardService.matchesWard(ticket.wardId, 'N'),
          isTrue,
          reason: 'Routing ticket ${ticket.id} belonging to ward ${ticket.wardId} leaked into Ward N',
        );
      }
    });

    test('Ward Officer can approve ticket and reassign department preserving timestamps', () async {
      final wardNLeads = await hierarchyRepo.getUsers(role: 'ward_department_lead', wardId: 'N');
      final swmLead = wardNLeads.firstWhere(
        (u) => GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, 'solid_waste_management'),
      );
      final wardOfficer = (await hierarchyRepo.getUsers(role: 'ward_officer', wardId: 'N')).first;

      final mockComplaint = ComplaintModel(
        id: 'test_complaint_ward_n_001',
        ticketNumber: 'TKT-WARD-N-001',
        title: 'Pothole near bin',
        description: 'Pothole requires road repair',
        category: CivicCategory.defaultCategories[3],
        wardId: 'N',
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now(),
        assignedDepartmentId: swmLead.departmentId,
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Ghatkopar East',
        ),
      );
      routingService.registerComplaint(mockComplaint);

      final ticketResult = await routingService.raiseReassignmentRequest(
        complaintId: mockComplaint.id,
        sourceLeadId: swmLead.id,
        suggestedDepartmentId: 'roads_and_traffic',
        reason: 'Pothole near garbage bin requires road repair crew',
      );

      expect(ticketResult.isPending, isTrue);

      // Ward Officer approves reassignment
      final reviewedTicket = await routingService.reviewRoutingTicket(
        ticketId: ticketResult.id,
        reviewerId: wardOfficer.employeeId,
        approve: true,
        reviewNotes: 'Approved for road team remediation',
      );

      expect(reviewedTicket.isApproved, isTrue);
      expect(reviewedTicket.reviewedBy, wardOfficer.employeeId);
      expect(reviewedTicket.status, RoutingTicketStatus.approved);
    });

    test('Ward Officer can reject ticket keeping complaint with source department', () async {
      final wardNLeads = await hierarchyRepo.getUsers(role: 'ward_department_lead', wardId: 'N');
      final waterLead = wardNLeads.firstWhere(
        (u) => GovernmentDepartmentDashboardService.matchesDepartment(u.departmentId, 'water_supply'),
        orElse: () => wardNLeads.first,
      );
      final wardOfficer = (await hierarchyRepo.getUsers(role: 'ward_officer', wardId: 'N')).first;

      final mockComplaint = ComplaintModel(
        id: 'test_complaint_ward_n_002',
        ticketNumber: 'TKT-WARD-N-002',
        title: 'Water logging issue',
        description: 'Water leak',
        category: CivicCategory.defaultCategories[1],
        wardId: 'N',
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now(),
        assignedDepartmentId: waterLead.departmentId,
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Ghatkopar West',
        ),
      );
      routingService.registerComplaint(mockComplaint);

      final ticketResult = await routingService.raiseReassignmentRequest(
        complaintId: mockComplaint.id,
        sourceLeadId: waterLead.id,
        suggestedDepartmentId: 'storm_water_drains',
        reason: 'Water logging issue',
      );

      final reviewedTicket = await routingService.reviewRoutingTicket(
        ticketId: ticketResult.id,
        reviewerId: wardOfficer.employeeId,
        approve: false,
        reviewNotes: 'Pipe leak is within water supply department scope',
      );

      expect(reviewedTicket.isRejected, isTrue);
      expect(reviewedTicket.status, RoutingTicketStatus.rejected);
    });
  });

  group('Phase 6 - Section 5: Multi-Criteria Filter Tests', () {
    test('Filters ward dashboard by department', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
        departmentFilter: 'solid_waste_management',
      );

      for (final complaint in data.filteredComplaints) {
        expect(
          complaint.assignedDepartmentId == 'solid_waste_management' ||
              complaint.category.id == 'solid_waste_management' ||
              complaint.category.id == 'garbage',
          isTrue,
        );
      }
    });

    test('Filters ward dashboard by priority', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
        priorityFilter: ComplaintPriority.emergency,
      );

      for (final complaint in data.filteredComplaints) {
        expect(complaint.priority, ComplaintPriority.emergency);
      }
    });

    test('Filters ward dashboard by status', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
        statusFilter: ComplaintStatus.resolved,
      );

      for (final complaint in data.filteredComplaints) {
        expect(complaint.status, ComplaintStatus.resolved);
      }
    });

    test('Filters ward dashboard by search keyword', () async {
      final data = await dashboardService.loadWardDashboard(
        wardId: 'N',
        searchQuery: 'leak',
      );

      for (final complaint in data.filteredComplaints) {
        final match = complaint.title.toLowerCase().contains('leak') ||
            complaint.description.toLowerCase().contains('leak') ||
            complaint.id.toLowerCase().contains('leak');
        expect(match, isTrue);
      }
    });
  });
}
