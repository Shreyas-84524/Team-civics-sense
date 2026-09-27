import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/local/mock_data_source.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_routing_ticket_model.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_authorization_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/services/government_department_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/government_department_lead_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/government_ward_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

void main() {
  late GovernmentDepartmentLeadDashboardService dashboardService;
  late MockGovtComplaintRepository complaintRepo;
  late LocalGovernmentHierarchyRepository hierarchyRepo;
  late ComplaintRoutingService routingService;
  late DefaultGovernmentAuditService auditService;
  late GovernmentAuthorizationService authService;
  late GovtUserModel roadsLead;
  late List<GovtUserModel> unitCrew;

  setUp(() async {
    AuthServiceLocator.useMockServices();
    RepositoryLocator.useMockRepositories();
    MockGovtAuthService().resetForTesting(authenticated: true);

    complaintRepo = MockGovtComplaintRepository();
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();
    auditService = DefaultGovernmentAuditService();
    routingService = ComplaintRoutingService(
      hierarchyRepo: hierarchyRepo,
      auditService: auditService,
    );
    authService = GovernmentAuthorizationService(hierarchyRepo: hierarchyRepo);

    dashboardService = GovernmentDepartmentLeadDashboardService(
      complaintRepo: complaintRepo,
      hierarchyRepo: hierarchyRepo,
      routingService: routingService,
      auditService: auditService,
      authService: authService,
      hazardRepo: RepositoryLocator.hazardRepository,
    );

    final wardNLeads = await hierarchyRepo.getUsers(
      role: 'ward_department_lead',
      wardId: 'N',
    );
    roadsLead = wardNLeads.firstWhere(
      (u) => GovernmentDepartmentDashboardService.matchesDepartment(
        u.departmentId,
        'dept_roads',
      ),
    );

    unitCrew = await hierarchyRepo.getUsers(
      role: 'department_crew',
      wardId: 'N',
      departmentId: roadsLead.departmentId,
    );
  });

  group('Phase 7 - Section 1: Strict Unit Isolation (Ward × Department)', () {
    test('Loads exactly Ward N × Maintenance & Roads unit', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      expect(data.ward.wardCode, 'N');
      expect(
        GovernmentDepartmentDashboardService.matchesDepartment(
          data.department.departmentId,
          'dept_roads',
        ),
        isTrue,
      );
      expect(data.crewMembers.length, 5);
      expect(data.crewWorkload.length, 5);
    });

    test('Zero cross-ward data leakage in unit complaints', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      for (final complaint in data.allUnitComplaints) {
        final wardMatch = GovernmentWardDashboardService.matchesWard(
          complaint.wardId,
          'N',
        );
        expect(
          wardMatch,
          isTrue,
          reason: 'Complaint ${complaint.id} belonging to ward ${complaint.wardId} leaked into Ward N Lead dashboard',
        );
      }
    });

    test('Zero cross-department data leakage in unit complaints', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      for (final complaint in data.allUnitComplaints) {
        final deptMatch = GovernmentDepartmentDashboardService.matchesDepartment(
          complaint.assignedDepartmentId ?? complaint.category.id,
          'dept_roads',
        );
        expect(
          deptMatch,
          isTrue,
          reason: 'Complaint ${complaint.id} belonging to department ${complaint.assignedDepartmentId} leaked into dept_roads',
        );
      }
    });

    test('Zero cross-unit data leakage in critical complaints and unassigned items', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      for (final c in data.criticalComplaints) {
        expect(GovernmentWardDashboardService.matchesWard(c.wardId, 'N'), isTrue);
        expect(GovernmentDepartmentDashboardService.matchesDepartment(c.assignedDepartmentId ?? c.category.id, 'dept_roads'), isTrue);
      }

      for (final c in data.unassignedComplaints) {
        expect(GovernmentWardDashboardService.matchesWard(c.wardId, 'N'), isTrue);
        expect(GovernmentDepartmentDashboardService.matchesDepartment(c.assignedDepartmentId ?? c.category.id, 'dept_roads'), isTrue);
        expect(c.assignedCrewMemberId, isNull);
      }
    });
  });

  group('Phase 7 - Section 2: Top KPI Metrics & Operations Workflow Funnel', () {
    test('Calculates unit-scoped KPIs accurately', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      final kpis = data.kpiMetrics;
      expect(kpis.unassignedComplaints, greaterThanOrEqualTo(0));
      expect(kpis.assignedComplaints, greaterThanOrEqualTo(0));
      expect(kpis.inProgressComplaints, greaterThanOrEqualTo(0));
      expect(kpis.criticalComplaints, greaterThanOrEqualTo(0));
      expect(kpis.slaAtRiskComplaints, greaterThanOrEqualTo(0));
      expect(kpis.slaBreachedComplaints, greaterThanOrEqualTo(0));
      expect(kpis.awaitingVerificationComplaints, greaterThanOrEqualTo(0));
      expect(kpis.resolvedTodayComplaints, greaterThanOrEqualTo(0));
      expect(kpis.slaComplianceRate, inInclusiveRange(0.0, 100.0));
      expect(kpis.totalComplaints, equals(data.allUnitComplaints.length));
    });

    test('Calculates 6-stage operations workflow funnel metrics accurately', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      final funnel = data.operationsFunnel;
      expect(funnel.newUnassigned, greaterThanOrEqualTo(0));
      expect(funnel.assigned, greaterThanOrEqualTo(0));
      expect(funnel.accepted, greaterThanOrEqualTo(0));
      expect(funnel.inProgress, greaterThanOrEqualTo(0));
      expect(funnel.awaitingVerification, greaterThanOrEqualTo(0));
      expect(funnel.resolved, greaterThanOrEqualTo(0));
    });
  });

  group('Phase 7 - Section 3: Ground Crew Authorization & Assignment', () {
    test('Resolves exactly 5 authorized crew members for the Ward N × dept_roads unit', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      expect(data.crewWorkload.length, 5);
      for (final crew in data.crewWorkload) {
        expect(GovernmentWardDashboardService.matchesWard(crew.crewUser.wardId, 'N'), isTrue);
        expect(GovernmentDepartmentDashboardService.matchesDepartment(crew.crewUser.departmentId, 'dept_roads'), isTrue);
        expect(crew.crewUser.isCrew, isTrue);
        expect(crew.assignedJobs, greaterThanOrEqualTo(0));
        expect(crew.inProgress, greaterThanOrEqualTo(0));
      }
    });

    test('Ward Department Lead can assign complaint to authorized unit crew member', () async {
      final now = DateTime.now();
      final testComplaint = ComplaintModel(
        id: 'TEST-COMP-001',
        ticketNumber: 'TKT-2026-TEST01',
        title: 'Road Pothole on 90 Feet Road',
        description: 'Deep pothole causing vehicle slowdown',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: '90 Feet Road, Ghatkopar East',
          ward: 'N',
        ),
        wardId: 'N',
        assignedDepartmentId: roadsLead.departmentId,
        status: ComplaintStatus.submitted,
        priority: ComplaintPriority.high,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      );

      MockDataSource().complaints.add(testComplaint);
      routingService.registerComplaint(testComplaint);

      final targetCrew = unitCrew.first;
      final assignedResult = await dashboardService.assignCrewMember(
        complaintId: 'TEST-COMP-001',
        crewMemberId: targetCrew.employeeId,
        leadId: roadsLead.id,
      );

      expect(assignedResult, isNotNull);
      expect(assignedResult.assignedCrewMemberId, targetCrew.employeeId);
      expect(assignedResult.status, ComplaintStatus.assigned);
    });

    test('Strictly rejects assignment of crew member from another ward or department', () async {
      final now = DateTime.now();
      final testComplaint = ComplaintModel(
        id: 'TEST-COMP-002',
        ticketNumber: 'TKT-2026-TEST02',
        title: 'Road Pothole on MG Road',
        description: 'Pothole needing patch repair',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'MG Road, Ghatkopar',
          ward: 'N',
        ),
        wardId: 'N',
        assignedDepartmentId: roadsLead.departmentId,
        status: ComplaintStatus.submitted,
        priority: ComplaintPriority.medium,
        createdAt: now,
        updatedAt: now,
      );

      MockDataSource().complaints.add(testComplaint);
      routingService.registerComplaint(testComplaint);

      // Attempt assigning crew from foreign ward or foreign department
      expect(
        () => dashboardService.assignCrewMember(
          complaintId: 'TEST-COMP-002',
          crewMemberId: 'GOV-CREW-M-ROADS-01', // Foreign ward M
          leadId: roadsLead.id,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => dashboardService.assignCrewMember(
          complaintId: 'TEST-COMP-002',
          crewMemberId: 'GOV-CREW-N-SWM-01', // Foreign dept SWM
          leadId: roadsLead.id,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Phase 7 - Section 4: Wrong Department Routing & SLA Preservation', () {
    test('Department Lead can raise wrong department reassignment request', () async {
      final now = DateTime.now().subtract(const Duration(hours: 5));
      final testComplaint = ComplaintModel(
        id: 'TEST-COMP-MISROUTED',
        ticketNumber: 'TKT-2026-MISROUTED',
        title: 'Garbage Dump on Footpath',
        description: 'Solid waste dumped on footpath, misrouted to Roads',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Station Road, Ghatkopar',
          ward: 'N',
        ),
        wardId: 'N',
        assignedDepartmentId: roadsLead.departmentId,
        status: ComplaintStatus.submitted,
        priority: ComplaintPriority.medium,
        createdAt: now,
        updatedAt: now,
      );

      MockDataSource().complaints.add(testComplaint);
      routingService.registerComplaint(testComplaint);

      final ticket = await dashboardService.raiseRoutingRequest(
        complaintId: 'TEST-COMP-MISROUTED',
        sourceLeadId: roadsLead.id,
        suggestedDepartmentId: 'solid_waste_management',
        reason: 'Issue is solid waste accumulation, belongs to Solid Waste Management',
      );

      expect(ticket, isNotNull);
      expect(ticket.status, RoutingTicketStatus.pending);
      expect(ticket.suggestedDepartmentId, 'solid_waste_management');

      // Verify original complaint SLA timestamps remain preserved
      final updatedComplaint = await complaintRepo.getComplaintById('TEST-COMP-MISROUTED');
      expect(updatedComplaint, isNotNull);
      expect(updatedComplaint!.createdAt, equals(now));
      expect(updatedComplaint.status, isNot(ComplaintStatus.resolved));
    });

    test('Department Lead CANNOT approve their own routing request (Ward Officer authority only)', () async {
      final leadUser = MockGovtAuthService.mockWardLead;
      final wardOfficer = MockGovtAuthService.mockWardOfficer;
      final sampleTicket = ComplaintRoutingTicket(
        id: 'TKT-ROUT-TEST-001',
        complaintId: 'TEST-COMP-001',
        ticketNumber: 'TKT-2026-TEST01',
        wardId: 'N',
        sourceDepartmentId: 'dept_roads',
        suggestedDepartmentId: 'dept_swm',
        sourceLeadId: roadsLead.id,
        reason: 'Wrong dept',
        createdAt: DateTime.now(),
        status: RoutingTicketStatus.pending,
      );

      expect(authService.canReviewRoutingTicket(leadUser, sampleTicket), isFalse);
      expect(authService.canReviewRoutingTicket(wardOfficer, sampleTicket), isTrue);
    });
  });

  group('Phase 7 - Section 5: Completion Verification & Rework Flow', () {
    test('Ward Department Lead can verify completion and resolve complaint', () async {
      final now = DateTime.now();
      final targetCrew = unitCrew.first;
      final testComplaint = ComplaintModel(
        id: 'TEST-COMP-VERIFY',
        ticketNumber: 'TKT-2026-VERIFY01',
        title: 'Drainage grate repair',
        description: 'Broken drain grate fixed by crew',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'LBS Marg, Ghatkopar',
          ward: 'N',
        ),
        wardId: 'N',
        assignedDepartmentId: roadsLead.departmentId,
        assignedCrewMemberId: targetCrew.employeeId,
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        officerNotes: 'Work completed by crew. Awaiting lead verification.',
        imageUrls: ['https://example.com/before.jpg', 'https://example.com/after.jpg'],
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      MockDataSource().complaints.add(testComplaint);
      routingService.registerComplaint(testComplaint);

      final success = await dashboardService.verifyCompletion(
        complaintId: 'TEST-COMP-VERIFY',
        leadId: roadsLead.id,
        notes: 'Grate installation inspected and verified on site.',
      );

      expect(success, isTrue);

      final resolved = await complaintRepo.getComplaintById('TEST-COMP-VERIFY');
      expect(resolved, isNotNull);
      expect(resolved!.status, ComplaintStatus.resolved);
      expect(resolved.resolvedAt, isNotNull);
    });

    test('Ward Department Lead can return work for rework when rejected', () async {
      final now = DateTime.now();
      final targetCrew = unitCrew.first;
      final testComplaint = ComplaintModel(
        id: 'TEST-COMP-REWORK',
        ticketNumber: 'TKT-2026-REWORK01',
        title: 'Asphalt Patchwork',
        description: 'Patch repair uneven',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Pant Nagar, Ghatkopar',
          ward: 'N',
        ),
        wardId: 'N',
        assignedDepartmentId: roadsLead.departmentId,
        assignedCrewMemberId: targetCrew.employeeId,
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.medium,
        officerNotes: 'Completion submitted.',
        createdAt: now.subtract(const Duration(hours: 10)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      MockDataSource().complaints.add(testComplaint);
      routingService.registerComplaint(testComplaint);

      final success = await dashboardService.verifyCompletion(
        complaintId: 'TEST-COMP-REWORK',
        leadId: roadsLead.id,
        notes: 'Inspection failed: asphalt leveling incomplete.',
        returnForRework: true,
        reworkReason: 'Asphalt leveling incomplete. Re-level and compact.',
      );

      expect(success, isTrue);

      final reworked = await complaintRepo.getComplaintById('TEST-COMP-REWORK');
      expect(reworked, isNotNull);
      expect(reworked!.status, ComplaintStatus.inProgress);
      expect(reworked.officerNotes, contains('Asphalt leveling incomplete'));
    });
  });

  group('Phase 7 - Section 6: SLA Monitoring & Overdue Calculation', () {
    test('Categorizes Healthy, At-Risk, and Breached SLAs correctly', () async {
      final data = await dashboardService.loadDepartmentLeadDashboard(
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      final sla = data.slaMonitoringData;
      expect(sla.slaHealthyCount, greaterThanOrEqualTo(0));
      expect(sla.slaAtRiskCount, greaterThanOrEqualTo(0));
      expect(sla.slaBreachedCount, greaterThanOrEqualTo(0));
      expect(sla.slaComplianceRate, inInclusiveRange(0.0, 100.0));
      expect(sla.priorityBreakdown.length, 4);
      expect(sla.statusBreakdown.length, greaterThanOrEqualTo(4));
      expect(sla.crewBreakdown, isNotNull);
    });
  });
}
