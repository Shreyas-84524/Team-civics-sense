import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/government_audit_log_model.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_authorization_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalGovernmentHierarchyRepository hierarchyRepo;
  late DefaultGovernmentAuditService auditService;
  late GovernmentAuthorizationService authService;
  late ComplaintRoutingService routingService;

  setUp(() async {
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();

    auditService = DefaultGovernmentAuditService();
    authService = GovernmentAuthorizationService(hierarchyRepo: hierarchyRepo);
    routingService = ComplaintRoutingService(
      hierarchyRepo: hierarchyRepo,
      auditService: auditService,
      authService: authService,
    );
  });

  group('CIVICFIX PHASE 1: AUTOMATED COMPLAINT ROUTING TO JUNIOR ENGINEER', () {
    // =========================================================================
    // PART 1 & 2: WARD RESOLUTION (GEOTAGGING & PROXIMITY)
    // =========================================================================
    group('1. GPS Geotagging & Ward Detection', () {
      test('Scenario 1: Resolves exact ward by canonical wardId (e.g. G_NORTH)', () async {
        final ward = await routingService.resolveWardForLocation(rawWard: 'G_NORTH');
        expect(ward.wardId, equals('G_NORTH'));
        expect(ward.wardCode, equals('G/North'));
      });

      test('Scenario 2: Resolves ward by formatted wardCode (e.g. G/North, A)', () async {
        final ward1 = await routingService.resolveWardForLocation(rawWard: 'G/North');
        expect(ward1.wardId, equals('G_NORTH'));

        final ward2 = await routingService.resolveWardForLocation(rawWard: 'A');
        expect(ward2.wardId, equals('A'));
      });

      test('Scenario 3: Resolves ward by GPS coordinates (Dadar / Dharavi -> G_NORTH)', () async {
        // Dadar / Dharavi Coordinates (19.035, 72.842)
        final ward = await routingService.resolveWardForLocation(lat: 19.035, lng: 72.842);
        expect(ward.wardId, equals('G_NORTH'));
        expect(ward.wardCode, equals('G/North'));
      });

      test('Scenario 4: Resolves ward by GPS coordinates (Colaba / Fort -> A Ward)', () async {
        // Colaba / Fort Coordinates (18.922, 72.8347)
        final ward = await routingService.resolveWardForLocation(lat: 18.922, lng: 72.8347);
        expect(ward.wardId, equals('A'));
      });

      test('Scenario 5: Resolves ward by Byculla coordinates -> E Ward', () async {
        // Byculla Coordinates (18.973, 72.831)
        final ward = await routingService.resolveWardForLocation(lat: 18.973, lng: 72.831);
        expect(ward.wardId, equals('E'));
      });

      test('Scenario 6: Fallback to default canonical ward when coordinates are (0,0) and no raw ward', () async {
        final ward = await routingService.resolveWardForLocation(lat: 0.0, lng: 0.0, rawWard: '');
        expect(ward.wardId, isNotEmpty);
      });
    });

    // =========================================================================
    // PART 3: DEPARTMENT CLASSIFICATION (18 BMC DEPARTMENTS)
    // =========================================================================
    group('2. Department Classification', () {
      test('Scenario 7: Classifies roads and potholes -> maintenance_roads', () async {
        final deptRoads = await routingService.resolveDepartmentForCategory(
          category: CivicCategory.defaultCategories[0], // roads
        );
        expect(deptRoads.departmentId, equals('maintenance_roads'));
        expect(deptRoads.departmentCode, equals('RDS'));
      });

      test('Scenario 8: Classifies water grievances -> water_works', () async {
        final deptWater = await routingService.resolveDepartmentForCategory(
          category: CivicCategory.defaultCategories[1], // water
        );
        expect(deptWater.departmentId, equals('water_works'));
        expect(deptWater.departmentCode, equals('WW'));
      });

      test('Scenario 9: Classifies waste and sanitation -> solid_waste_management', () async {
        final deptWaste = await routingService.resolveDepartmentForCategory(
          category: CivicCategory.defaultCategories[3], // waste
        );
        expect(deptWaste.departmentId, equals('solid_waste_management'));
        expect(deptWaste.departmentCode, equals('SWM'));

        final deptSanitation = await routingService.resolveDepartmentForCategory(
          category: CivicCategory.defaultCategories[2], // sanitation
        );
        expect(deptSanitation.departmentId, equals('solid_waste_management'));
      });

      test('Scenario 10: Classifies drainage grievances -> maintenance_roads', () async {
        final deptDrain = await routingService.resolveDepartmentForCategory(
          category: CivicCategory.defaultCategories[5], // drainage
        );
        expect(deptDrain.departmentId, equals('maintenance_roads'));
      });

      test('Scenario 11: Classifies streetlights -> maintenance_roads / mechanical_electrical', () async {
        final deptLights = await routingService.resolveDepartmentForCategory(
          category: CivicCategory.defaultCategories[4], // streetlights
        );
        expect(deptLights.departmentId, equals('maintenance_roads'));
      });

      test('Scenario 12: Normalizes raw department identifiers (e.g. dept_swm, rds, ww)', () async {
        final dept1 = await routingService.resolveDepartmentForCategory(rawDept: 'dept_swm');
        expect(dept1.departmentId, equals('solid_waste_management'));

        final dept2 = await routingService.resolveDepartmentForCategory(rawDept: 'rds');
        expect(dept2.departmentId, equals('maintenance_roads'));

        final dept3 = await routingService.resolveDepartmentForCategory(rawDept: 'water_works');
        expect(dept3.departmentId, equals('water_works'));
      });
    });

    // =========================================================================
    // PART 4: JUNIOR ENGINEER ELIGIBILITY & ROLE IDENTIFICATION
    // =========================================================================
    group('3. Junior Engineer Role Identification & Eligibility', () {
      test('Scenario 13: Queries canonical Junior Engineers (role: department_crew)', () async {
        final eligible = await routingService.getEligibleJuniorEngineers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        expect(eligible, isNotEmpty);
        expect(eligible.length, equals(5)); // Exactly 5 JEs per Ward × Dept unit in canonical dataset
        for (final je in eligible) {
          expect(je.role, equals(GovernmentRole.departmentCrewId));
          expect(je.isCrew, isTrue);
          expect(je.isJuniorEngineer, isTrue);
          expect(je.active, isTrue);
        }
      });

      test('Scenario 14: Eligible JEs are strictly sorted by employeeId ascending for deterministic ordering', () async {
        final eligible = await routingService.getEligibleJuniorEngineers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        for (int i = 0; i < eligible.length - 1; i++) {
          expect(
            eligible[i].employeeId.compareTo(eligible[i + 1].employeeId) <= 0,
            isTrue,
            reason: 'JEs must be sorted alphabetically by employeeId',
          );
        }
      });

      test('Scenario 15: GovtUserModel and GovernmentRole helpers correctly identify Junior Engineer', () {
        const user = GovtUserModel(
          id: 'GOV-CREW-G_NORTH-maintenance_roads-01',
          employeeId: 'GOV-CREW-G_NORTH-maintenance_roads-01',
          fullName: 'Sanjay Shinde',
          email: 'sanjay.shinde@mcgm.gov.in',
          role: 'department_crew',
          displayDesignation: 'Junior Engineer (Roads)',
        );

        expect(user.isCrew, isTrue);
        expect(user.isJuniorEngineer, isTrue);
        expect(user.govtRole, equals(GovernmentRole.departmentCrew));
        expect(user.govtRole.isJuniorEngineer, isTrue);
        expect(GovernmentRole.juniorEngineerId, equals('department_crew'));
      });
    });

    // =========================================================================
    // PART 5: WORKLOAD-AWARE SELECTION & DETERMINISTIC TIE-BREAKING
    // =========================================================================
    group('4. Workload Balancing & Deterministic Tie-Breaking', () {
      test('Scenario 16: Selects least-loaded Junior Engineer when workloads differ', () async {
        final eligibleJEs = await routingService.getEligibleJuniorEngineers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );
        expect(eligibleJEs.length, greaterThanOrEqualTo(2));

        final je1 = eligibleJEs[0];
        final je2 = eligibleJEs[1];

        // Give JE1 two active complaints
        final activeComplaints = [
          ComplaintModel(
            id: 'cmp_load_1',
            ticketNumber: 'CF-2026-1001',
            title: 'Pothole 1',
            description: 'Desc',
            category: CivicCategory.defaultCategories[0],
            status: ComplaintStatus.inProgress,
            priority: ComplaintPriority.high,
            location: const CivicLocation(latitude: 19.035, longitude: 72.842, address: 'Dadar'),
            assignedCrewMemberId: je1.employeeId,
            assignedTo: je1.fullName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ComplaintModel(
            id: 'cmp_load_2',
            ticketNumber: 'CF-2026-1002',
            title: 'Pothole 2',
            description: 'Desc',
            category: CivicCategory.defaultCategories[0],
            status: ComplaintStatus.assigned,
            priority: ComplaintPriority.medium,
            location: const CivicLocation(latitude: 19.035, longitude: 72.842, address: 'Dadar'),
            assignedCrewMemberId: je1.employeeId,
            assignedTo: je1.fullName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // JE2 has 0 load, JE1 has 2 load -> Must pick JE2 (or lowest load candidate)
        final selected = routingService.selectLeastLoadedJuniorEngineer(
          eligibleJEs: eligibleJEs,
          allComplaints: activeComplaints,
        );

        expect(selected, isNotNull);
        expect(selected!.employeeId, isNot(equals(je1.employeeId)));
        expect(selected.employeeId, equals(je2.employeeId)); // je2 is next lowest
      });

      test('Scenario 17: Resolved and rejected complaints do not count toward active workload', () async {
        final eligibleJEs = await routingService.getEligibleJuniorEngineers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        final je1 = eligibleJEs[0];

        // Give JE1 two resolved/rejected complaints
        final pastComplaints = [
          ComplaintModel(
            id: 'cmp_resolved_1',
            ticketNumber: 'CF-2026-1003',
            title: 'Resolved Pothole',
            description: 'Desc',
            category: CivicCategory.defaultCategories[0],
            status: ComplaintStatus.resolved,
            priority: ComplaintPriority.high,
            location: const CivicLocation(latitude: 19.035, longitude: 72.842, address: 'Dadar'),
            assignedCrewMemberId: je1.employeeId,
            assignedTo: je1.fullName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ComplaintModel(
            id: 'cmp_rejected_1',
            ticketNumber: 'CF-2026-1004',
            title: 'Rejected Issue',
            description: 'Desc',
            category: CivicCategory.defaultCategories[0],
            status: ComplaintStatus.rejected,
            priority: ComplaintPriority.low,
            location: const CivicLocation(latitude: 19.035, longitude: 72.842, address: 'Dadar'),
            assignedCrewMemberId: je1.employeeId,
            assignedTo: je1.fullName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Both JE1 and JE2 have 0 active load -> tie-break picks JE1 (lowest employeeId)
        final selected = routingService.selectLeastLoadedJuniorEngineer(
          eligibleJEs: eligibleJEs,
          allComplaints: pastComplaints,
        );

        expect(selected, isNotNull);
        expect(selected!.employeeId, equals(je1.employeeId));
      });

      test('Scenario 18: Deterministic tie-breaking selects lower employeeId when loads are equal', () async {
        final eligibleJEs = await routingService.getEligibleJuniorEngineers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        // When all 5 JEs have 0 load, tie-break must select candidate #1 (lowest employeeId)
        final selected = routingService.selectLeastLoadedJuniorEngineer(
          eligibleJEs: eligibleJEs,
          allComplaints: [],
        );

        expect(selected, isNotNull);
        expect(selected!.employeeId, equals(eligibleJEs.first.employeeId));
      });
    });

    // =========================================================================
    // PART 6: AUTOMATED END-TO-END ROUTING & SLA PRESERVATION
    // =========================================================================
    group('5. Automated End-to-End Routing Execution & SLA Preservation', () {
      test('Scenario 19: Auto-routes new complaint directly to Junior Engineer in assigned state', () async {
        final initialComplaint = ComplaintModel(
          id: 'cmp_auto_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-AUTO-01',
          title: 'Dangerous Pothole on Senapati Bapat Marg',
          description: 'Deep pothole causing accidents near Dadar station.',
          category: CivicCategory.defaultCategories[0], // roads
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.high,
          location: const CivicLocation(
            latitude: 19.035,
            longitude: 72.842,
            address: 'Senapati Bapat Marg, Dadar',
            ward: 'G/North',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final routed = await routingService.autoRouteComplaint(initialComplaint);

        // Operational Assertions
        expect(routed.status, equals(ComplaintStatus.assigned));
        expect(routed.assignmentStatus, equals(ComplaintAssignmentStatus.crewAssigned));
        expect(routed.routingStatus, equals(ComplaintRoutingStatus.assigned));
        expect(routed.wardId, equals('G_NORTH'));
        expect(routed.assignedDepartmentId, equals('maintenance_roads'));
        expect(routed.assignedCrewMemberId, isNotNull);
        expect(routed.assignedJuniorEngineerId, equals(routed.assignedCrewMemberId));
        expect(routed.isJuniorEngineerAssigned, isTrue);
        expect(routed.assignedTo, isNotNull);
        expect(routed.assignedDepartmentLeadId, isNotNull); // Lead recorded for supervisory oversight
        expect(routed.timeline.any((t) => t.title.contains('Junior Engineer') || t.title.contains('Assigned')), isTrue);
      });

      test('Scenario 20: SLA clock (slaStartedAt) and originalCreatedAt are strictly preserved during auto-routing', () async {
        final submissionTime = DateTime.now().subtract(const Duration(minutes: 15));
        final initialComplaint = ComplaintModel(
          id: 'cmp_sla_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-SLA-01',
          title: 'Water Pipe Burst',
          description: 'Water pipeline burst on Lady Jamshedji Road.',
          category: CivicCategory.defaultCategories[1], // water
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.emergency,
          location: const CivicLocation(
            latitude: 19.035,
            longitude: 72.842,
            address: 'Lady Jamshedji Road',
            ward: 'G_NORTH',
          ),
          createdAt: submissionTime,
          updatedAt: submissionTime,
          slaStartedAt: submissionTime,
          originalCreatedAt: submissionTime,
        );

        final routed = await routingService.autoRouteComplaint(initialComplaint);

        expect(routed.slaStartedAt, equals(submissionTime));
        expect(routed.originalCreatedAt, equals(submissionTime));
        expect(routed.createdAt, equals(submissionTime));
      });

      test('Scenario 21: Auto-routing logs immutable GovernmentAuditLog with action auto_routed_to_junior_engineer', () async {
        final complaint = ComplaintModel(
          id: 'cmp_audit_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-AUDIT-01',
          title: 'Garbage Dump Overflow',
          description: 'Overflowing dustbin near market.',
          category: CivicCategory.defaultCategories[3], // waste
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(
            latitude: 19.035,
            longitude: 72.842,
            address: 'Dharavi Main Road',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final routed = await routingService.autoRouteComplaint(complaint);
        expect(routed.isJuniorEngineerAssigned, isTrue);

        final logs = await auditService.getLogsForComplaint(complaint.id);
        expect(logs, isNotEmpty);
        expect(logs.any((l) => l.action == GovernmentAuditActions.autoRoutedToJuniorEngineer), isTrue);

        final routingLog = logs.firstWhere((l) => l.action == GovernmentAuditActions.autoRoutedToJuniorEngineer);
        expect(routingLog.wardId, equals('G_NORTH'));
        expect(routingLog.departmentId, equals('solid_waste_management'));
        expect(routingLog.details['assignedJuniorEngineerId'], equals(routed.assignedCrewMemberId));
      });

      test('Scenario 22: Auto-routing is idempotent (re-routing an assigned ticket returns early)', () async {
        final complaint = ComplaintModel(
          id: 'cmp_idempotent_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-IDEM-01',
          title: 'Blocked Drain',
          description: 'Desc',
          category: CivicCategory.defaultCategories[5],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 19.035, longitude: 72.842, address: 'Dadar'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final firstRoute = await routingService.autoRouteComplaint(complaint);
        final initialTimelineCount = firstRoute.timeline.length;

        // Re-route the already assigned complaint
        final secondRoute = await routingService.autoRouteComplaint(firstRoute);

        expect(secondRoute.assignedCrewMemberId, equals(firstRoute.assignedCrewMemberId));
        expect(secondRoute.timeline.length, equals(initialTimelineCount)); // No duplicate timeline entries
      });

      test('Scenario 23: Safe fallback when no active Junior Engineer is available', () async {
        // Query for a non-existent unit or empty pool scenario
        final unassignedComplaint = ComplaintModel(
          id: 'cmp_fallback_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-FALLBACK-01',
          title: 'Unknown issue in non-existent ward',
          description: 'Desc',
          category: CivicCategory.defaultCategories[6],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.low,
          location: const CivicLocation(
            latitude: 0,
            longitude: 0,
            address: 'Unknown Boundary',
            ward: 'NON_EXISTENT_WARD',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Pass an empty eligible JE list by using routing fallback
        final result = await routingService.autoRouteComplaint(unassignedComplaint);
        expect(result.id, isNotEmpty);
      });
    });

    // =========================================================================
    // PART 7: DIRECT WRONG-DEPARTMENT TRANSFER (PART 12)
    // =========================================================================
    group('6. Direct Wrong-Department Reassignment & Transfer', () {
      test('Scenario 24: Directly transfers complaint to new department and assigns least-loaded JE', () async {
        // 1. Initial complaint routed to Roads
        final initialComplaint = ComplaintModel(
          id: 'cmp_transfer_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-TRANS-01',
          title: 'Contaminated pipeline leak',
          description: 'Reported as roads but actually a potable water pipeline issue.',
          category: CivicCategory.defaultCategories[0], // roads
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.high,
          location: const CivicLocation(
            latitude: 19.035,
            longitude: 72.842,
            address: 'Dadar Market',
            ward: 'G_NORTH',
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        final routedToRoads = await routingService.autoRouteComplaint(initialComplaint);
        expect(routedToRoads.assignedDepartmentId, equals('maintenance_roads'));
        final initialJE = routedToRoads.assignedCrewMemberId;
        final initialSlaStartedAt = routedToRoads.slaStartedAt;

        // 2. Junior Engineer / Lead triggers direct department transfer to water_works
        final transferred = await routingService.transferWrongDepartmentDirect(
          complaintId: routedToRoads.id,
          requestedBy: initialJE!,
          newDepartmentId: 'water_works',
          reason: 'Issue is a potable water pipeline rupture, not road surface defect.',
        );

        // 3. Verify transfer results
        expect(transferred.assignedDepartmentId, equals('water_works'));
        expect(transferred.assignedCrewMemberId, isNotNull);
        expect(transferred.assignedCrewMemberId?.toUpperCase(), equals('GOV-CREW-G_NORTH-WATER_WORKS-01'));
        expect(transferred.assignedCrewMemberId, isNot(equals(initialJE))); // Assigned to Water Works JE
        expect(transferred.reassignmentCount, equals(1));
        expect(transferred.lastReassignedAt, isNotNull);
        expect(transferred.currentDepartmentAssignedAt, isNotNull);

        // 4. CRITICAL: SLA clock and creation date are NEVER reset
        expect(transferred.slaStartedAt, equals(initialSlaStartedAt));
        expect(transferred.originalCreatedAt, equals(routedToRoads.originalCreatedAt));

        // 5. Verify audit logging
        final logs = await auditService.getLogsForComplaint(transferred.id);
        expect(logs.any((l) => l.action == GovernmentAuditActions.departmentTransferred), isTrue);
      });
    });

    // =========================================================================
    // PART 8: DEPARTMENT LEAD OVERSIGHT & JURISDICTION ISOLATION
    // =========================================================================
    group('7. Department Lead Supervisory Oversight & Jurisdiction Isolation', () {
      test('Scenario 25: Ward Department Lead retains full oversight visibility over auto-assigned complaints in their unit', () async {
        final complaint = ComplaintModel(
          id: 'cmp_oversight_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-OVER-01',
          title: 'Resurfacing needed',
          description: 'Desc',
          category: CivicCategory.defaultCategories[0], // roads
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(
            latitude: 19.035,
            longitude: 72.842,
            address: 'Dadar G/North',
            ward: 'G_NORTH',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final routed = await routingService.autoRouteComplaint(complaint);

        // Lead for G_NORTH Roads
        const leadUser = GovtUserModel(
          id: 'GOV-WDL-G_NORTH-maintenance_roads',
          employeeId: 'GOV-WDL-G_NORTH-maintenance_roads',
          fullName: 'Executive Engineer (Roads)',
          email: 'lead.roads.gnorth@mcgm.gov.in',
          role: 'ward_department_lead',
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        final canView = await authService.canViewComplaint(leadUser, routed);
        expect(canView, isTrue, reason: 'Department Lead must maintain supervisory oversight visibility');
      });

      test('Scenario 26: Junior Engineer has visibility over their own assigned tickets', () async {
        final complaint = ComplaintModel(
          id: 'cmp_je_vis_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-JE-VIS-01',
          title: 'Pothole on Main Road',
          description: 'Desc',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(
            latitude: 19.035,
            longitude: 72.842,
            address: 'Dadar G/North',
            ward: 'G_NORTH',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final routed = await routingService.autoRouteComplaint(complaint);
        final assignedJEId = routed.assignedCrewMemberId!;

        final jeUser = await hierarchyRepo.getUserByEmployeeId(assignedJEId);
        expect(jeUser, isNotNull);

        final canView = await authService.canViewComplaint(jeUser!, routed);
        expect(canView, isTrue, reason: 'Junior Engineer must have visibility over assigned complaints');
      });

      test('Scenario 27: Cross-department crew cannot view unrelated department complaints', () async {
        final complaint = ComplaintModel(
          id: 'cmp_isolated_001',
          citizenId: 'user_citizen_001',
          ticketNumber: 'CF-2026-ISO-01',
          title: 'Water leak',
          description: 'Desc',
          category: CivicCategory.defaultCategories[1], // water
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(
            latitude: 19.035,
            longitude: 72.842,
            address: 'Dadar G/North',
            ward: 'G_NORTH',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final routed = await routingService.autoRouteComplaint(complaint);

        // Roads JE in G_NORTH
        const roadsJE = GovtUserModel(
          id: 'GOV-CREW-G_NORTH-maintenance_roads-01',
          employeeId: 'GOV-CREW-G_NORTH-maintenance_roads-01',
          fullName: 'Roads Crew',
          email: 'crew.roads@mcgm.gov.in',
          role: 'department_crew',
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        final canView = await authService.canViewComplaint(roadsJE, routed);
        expect(canView, isFalse, reason: 'Roads JE cannot view Water Works complaints');
      });
    });
  });
}
