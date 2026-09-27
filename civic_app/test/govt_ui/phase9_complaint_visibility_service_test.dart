import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_routing_ticket_model.dart';
import 'package:civic_app/core/services/government_authorization_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/services/government_complaint_visibility_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GovernmentHierarchyRepository hierarchyRepo;
  late GovernmentAuthorizationService authService;
  late GovernmentComplaintVisibilityService visibilityService;

  // Sample Government Officers across all 6 Roles
  const superAdmin = GovtUserModel(
    id: 'GOV-SUPER-01',
    employeeId: 'EMP-SUPER-01',
    fullName: 'Municipal Commissioner',
    email: 'commissioner@mcgm.gov.in',
    role: 'super_admin',
    wardId: 'A',
    departmentId: 'dept_admin',
    departmentName: 'General Administration',
    displayDesignation: 'Municipal Commissioner & CEO',
    active: true,
  );

  const zonalDmcZone6 = GovtUserModel(
    id: 'GOV-DMC-Z6',
    employeeId: 'EMP-DMC-Z6',
    fullName: 'Deputy Municipal Commissioner (Zone 6)',
    email: 'dmc.zone6@mcgm.gov.in',
    role: 'zonal_dmc',
    zoneId: 'ZONE_6',
    wardId: 'N',
    departmentId: 'dept_admin',
    departmentName: 'Zonal Administration',
    displayDesignation: 'DMC Zone 6',
    active: true,
  );

  const centralHodRoads = GovtUserModel(
    id: 'GOV-HOD-ROADS',
    employeeId: 'EMP-HOD-ROADS',
    fullName: 'Chief Engineer (Roads & Traffic)',
    email: 'hod.roads@mcgm.gov.in',
    role: 'central_department_hod',
    departmentId: 'dept_roads',
    departmentName: 'Maintenance & Roads',
    wardId: 'A',
    displayDesignation: 'Chief Engineer (Roads)',
    active: true,
  );

  const wardOfficerNWard = GovtUserModel(
    id: 'GOV-WO-N',
    employeeId: 'EMP-WO-N',
    fullName: 'Assistant Municipal Commissioner (N Ward)',
    email: 'ac.nward@mcgm.gov.in',
    role: 'ward_officer',
    wardId: 'N',
    zoneId: 'ZONE_4',
    departmentId: 'dept_admin',
    departmentName: 'Ward Administration',
    displayDesignation: 'Assistant Commissioner (N Ward)',
    active: true,
  );

  const leadNWardRoads = GovtUserModel(
    id: 'GOV-WDL-N-ROADS',
    employeeId: 'EMP-WDL-N-ROADS',
    fullName: 'Executive Engineer (N Ward Roads)',
    email: 'lead.roads.n@mcgm.gov.in',
    role: 'ward_department_lead',
    wardId: 'N',
    departmentId: 'dept_roads',
    departmentName: 'Maintenance & Roads',
    displayDesignation: 'Executive Engineer',
    active: true,
  );

  const crew1NWardRoads = GovtUserModel(
    id: 'GOV-CREW-N-ROADS-01',
    employeeId: 'EMP-CREW-01',
    fullName: 'Ground Tech Rajesh Kumar',
    email: 'crew.01.n@mcgm.gov.in',
    role: 'department_crew',
    wardId: 'N',
    departmentId: 'dept_roads',
    departmentName: 'Maintenance & Roads',
    displayDesignation: 'Junior Engineer / Ground Tech',
    active: true,
  );

  const crew2NWardRoads = GovtUserModel(
    id: 'GOV-CREW-N-ROADS-02',
    employeeId: 'EMP-CREW-02',
    fullName: 'Ground Tech Suresh Patil',
    email: 'crew.02.n@mcgm.gov.in',
    role: 'department_crew',
    wardId: 'N',
    departmentId: 'dept_roads',
    departmentName: 'Maintenance & Roads',
    displayDesignation: 'Junior Engineer / Ground Tech',
    active: true,
  );

  // Sample Complaint in N Ward (Zone 4) under Roads Department
  final complaintInNWardRoads = ComplaintModel(
    id: 'CF-10001',
    ticketNumber: 'TKT-10001',
    title: 'Severe Pothole on LBS Marg',
    description: 'Deep road cavity causing traffic congestion.',
    category: CivicCategory.defaultCategories[0], // Roads
    status: ComplaintStatus.assigned,
    priority: ComplaintPriority.high,
    location: const CivicLocation(
      latitude: 19.0850,
      longitude: 72.8900,
      address: 'LBS Marg, Ghatkopar West',
      ward: 'N',
    ),
    wardId: 'N',
    assignedDepartmentId: 'dept_roads',
    assignedDepartmentLeadId: 'EMP-WDL-N-ROADS',
    assignedCrewMemberId: 'EMP-CREW-01',
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    originalCreatedAt: DateTime.now().subtract(const Duration(hours: 10)),
    slaStartedAt: DateTime.now().subtract(const Duration(hours: 10)),
    imageUrls: ['https://civicfix.gov.in/evidence1.jpg'],
  );

  // Sample Complaint in A Ward (Zone 1) under Solid Waste Management
  final complaintInAWardSWM = ComplaintModel(
    id: 'CF-20002',
    ticketNumber: 'TKT-20002',
    title: 'Garbage accumulation near Colaba',
    description: 'Waste bin overflowing on main avenue.',
    category: CivicCategory.defaultCategories[3], // Waste Management
    status: ComplaintStatus.reported,
    priority: ComplaintPriority.medium,
    location: const CivicLocation(
      latitude: 18.9220,
      longitude: 72.8340,
      address: 'Colaba Causeway',
      ward: 'A',
    ),
    wardId: 'A',
    assignedDepartmentId: 'dept_swm',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    originalCreatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    slaStartedAt: DateTime.now().subtract(const Duration(hours: 5)),
  );

  setUp(() async {
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();
    authService = GovernmentAuthorizationService(hierarchyRepo: hierarchyRepo);
    visibilityService = GovernmentComplaintVisibilityService(
      hierarchyRepo: hierarchyRepo,
      authService: authService,
    );
  });

  group('PHASE 9 — GovernmentComplaintVisibilityService Jurisdiction Tests', () {
    test('Super Admin has citywide visibility across all complaints', () async {
      expect(
        await visibilityService.canViewComplaint(
          user: superAdmin,
          complaint: complaintInNWardRoads,
        ),
        isTrue,
      );
      expect(
        await visibilityService.canViewComplaint(
          user: superAdmin,
          complaint: complaintInAWardSWM,
        ),
        isTrue,
      );
    });

    test('Zonal DMC can view complaints in their zone wards, denied outside', () async {
      // Zone 6 contains N Ward, S Ward, etc.
      expect(
        await visibilityService.canViewComplaint(
          user: zonalDmcZone6,
          complaint: complaintInNWardRoads,
        ),
        isTrue,
      );

      // A Ward belongs to Zone 1, so Zone 6 DMC must be denied
      expect(
        await visibilityService.canViewComplaint(
          user: zonalDmcZone6,
          complaint: complaintInAWardSWM,
        ),
        isFalse,
      );
    });

    test('Central Department HOD can view complaints in their department citywide', () async {
      // Roads HOD can inspect roads complaint in N Ward
      expect(
        await visibilityService.canViewComplaint(
          user: centralHodRoads,
          complaint: complaintInNWardRoads,
        ),
        isTrue,
      );

      // Roads HOD cannot inspect Solid Waste Management complaint
      expect(
        await visibilityService.canViewComplaint(
          user: centralHodRoads,
          complaint: complaintInAWardSWM,
        ),
        isFalse,
      );
    });

    test('Ward Officer can view all complaints in their assigned Ward, denied other wards', () async {
      // N Ward Officer can view N Ward complaint
      expect(
        await visibilityService.canViewComplaint(
          user: wardOfficerNWard,
          complaint: complaintInNWardRoads,
        ),
        isTrue,
      );

      // N Ward Officer cannot view A Ward complaint
      expect(
        await visibilityService.canViewComplaint(
          user: wardOfficerNWard,
          complaint: complaintInAWardSWM,
        ),
        isFalse,
      );
    });

    test('Ward Department Lead can view only matching (Ward × Department) unit complaints', () async {
      // N Ward Roads Lead can view N Ward Roads complaint
      expect(
        await visibilityService.canViewComplaint(
          user: leadNWardRoads,
          complaint: complaintInNWardRoads,
        ),
        isTrue,
      );

      // N Ward Roads Lead cannot view A Ward SWM complaint
      expect(
        await visibilityService.canViewComplaint(
          user: leadNWardRoads,
          complaint: complaintInAWardSWM,
        ),
        isFalse,
      );
    });

    test('Department Crew can view only complaints directly assigned to them', () async {
      // Crew 1 is assigned to complaintInNWardRoads -> Granted
      expect(
        await visibilityService.canViewComplaint(
          user: crew1NWardRoads,
          complaint: complaintInNWardRoads,
        ),
        isTrue,
      );

      // Crew 2 is in same unit but not assigned -> Denied
      expect(
        await visibilityService.canViewComplaint(
          user: crew2NWardRoads,
          complaint: complaintInNWardRoads,
        ),
        isFalse,
      );
    });
  });

  group('PHASE 9 — Role-Aware Action Permissions Evaluation', () {
    test('Department Crew receives Start Work and Submit Completion when assigned', () {
      final assignedComplaint = complaintInNWardRoads.copyWith(
        status: ComplaintStatus.assigned,
      );

      final actions = visibilityService.getPermittedActions(
        user: crew1NWardRoads,
        complaint: assignedComplaint,
      );

      expect(actions.contains(GovernmentComplaintAction.startWork), isTrue);
      expect(actions.contains(GovernmentComplaintAction.assignCrew), isFalse);
      expect(actions.contains(GovernmentComplaintAction.approveRouting), isFalse);
      expect(actions.contains(GovernmentComplaintAction.verifyCompletion), isFalse);
    });

    test('Department Lead receives Dispatch, Reassign, Wrong Dept, Verification actions', () {
      final unassignedComplaint = complaintInNWardRoads.copyWith(
        status: ComplaintStatus.verified,
        clearAssignedCrew: true,
      );

      final unassignedActions = visibilityService.getPermittedActions(
        user: leadNWardRoads,
        complaint: unassignedComplaint,
      );

      expect(unassignedActions.contains(GovernmentComplaintAction.assignCrew), isTrue);
      expect(unassignedActions.contains(GovernmentComplaintAction.raiseWrongDepartment), isTrue);
      expect(unassignedActions.contains(GovernmentComplaintAction.approveRouting), isFalse); // Only Ward Officer can approve routing

      final assignedComplaint = complaintInNWardRoads.copyWith(
        status: ComplaintStatus.inProgress,
      );

      final assignedActions = visibilityService.getPermittedActions(
        user: leadNWardRoads,
        complaint: assignedComplaint,
      );

      expect(assignedActions.contains(GovernmentComplaintAction.reassignCrew), isTrue);
    });

    test('Ward Officer receives Approve/Reject routing when pending ticket exists', () {
      final pendingTicket = ComplaintRoutingTicket(
        id: 'CRT-001',
        complaintId: complaintInNWardRoads.id,
        ticketNumber: complaintInNWardRoads.ticketNumber,
        wardId: 'N',
        sourceDepartmentId: 'dept_roads',
        sourceLeadId: 'EMP-WDL-N-ROADS',
        suggestedDepartmentId: 'dept_swm',
        reason: 'Misrouted garbage issue.',
        status: RoutingTicketStatus.pending,
        createdAt: DateTime.now(),
      );

      final woActions = visibilityService.getPermittedActions(
        user: wardOfficerNWard,
        complaint: complaintInNWardRoads,
        activeTicket: pendingTicket,
      );

      expect(woActions.contains(GovernmentComplaintAction.approveRouting), isTrue);
      expect(woActions.contains(GovernmentComplaintAction.rejectRouting), isTrue);
    });

    test('Supervisory roles (Super Admin, DMC, HOD) have inspection and escalation', () {
      final dmcActions = visibilityService.getPermittedActions(
        user: zonalDmcZone6,
        complaint: complaintInNWardRoads,
      );

      expect(dmcActions.contains(GovernmentComplaintAction.escalate), isTrue);
      expect(dmcActions.contains(GovernmentComplaintAction.startWork), isFalse);
    });

    test('Resolved complaints enforce view-only state', () {
      final resolvedComplaint = complaintInNWardRoads.copyWith(
        status: ComplaintStatus.resolved,
      );

      final actions = visibilityService.getPermittedActions(
        user: leadNWardRoads,
        complaint: resolvedComplaint,
      );

      expect(actions.contains(GovernmentComplaintAction.viewOnly), isTrue);
      expect(actions.contains(GovernmentComplaintAction.assignCrew), isFalse);
      expect(actions.contains(GovernmentComplaintAction.startWork), isFalse);
      expect(actions.contains(GovernmentComplaintAction.submitCompletion), isFalse);
    });
  });
}
