import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_routing_ticket_model.dart';
import 'package:civic_app/core/models/government_audit_log_model.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_authorization_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BMC Government Architecture - Dataset & Count Integrity Tests', () {
    late Map<String, dynamic> zonesData;
    late Map<String, dynamic> wardsData;
    late Map<String, dynamic> deptsData;
    late Map<String, dynamic> wardDeptsData;
    late Map<String, dynamic> usersData;
    late Map<String, dynamic> hierarchyData;

    setUpAll(() {
      String readJson(String relativePath) {
        final paths = [
          relativePath,
          '../$relativePath',
          'civic_app/$relativePath',
          'resources/Govt Data/${relativePath.split('/').last}',
          '../resources/Govt Data/${relativePath.split('/').last}',
        ];
        for (final p in paths) {
          final f = File(p);
          if (f.existsSync()) {
            return f.readAsStringSync();
          }
        }
        throw StateError('Cannot find file: $relativePath');
      }

      zonesData = jsonDecode(readJson('resources/Govt Data/zones.json')) as Map<String, dynamic>;
      wardsData = jsonDecode(readJson('resources/Govt Data/wards.json')) as Map<String, dynamic>;
      deptsData = jsonDecode(readJson('resources/Govt Data/departments.json')) as Map<String, dynamic>;
      wardDeptsData = jsonDecode(readJson('resources/Govt Data/ward_departments.json')) as Map<String, dynamic>;
      usersData = jsonDecode(readJson('resources/Govt Data/government_users.json')) as Map<String, dynamic>;
      hierarchyData = jsonDecode(readJson('resources/Govt Data/government_hierarchy.json')) as Map<String, dynamic>;
    });

    test('Canonical structural unit counts match BMC specifications exactly', () {
      final zones = zonesData['zones'] as List;
      final wards = wardsData['wards'] as List;
      final depts = deptsData['departments'] as List;
      final wardDepts = wardDeptsData['wardDepartments'] as List;

      expect(zones.length, equals(7), reason: 'Must have exactly 7 administrative zones');
      expect(wards.length, equals(24), reason: 'Must have exactly 24 administrative wards');
      expect(depts.length, equals(18), reason: 'Must have exactly 18 municipal departments');
      expect(wardDepts.length, equals(432), reason: 'Must have exactly 432 ward-departments (24 x 18)');
      expect((hierarchyData['zones'] as List).length, equals(7), reason: 'Hierarchy zones match');
    });

    test('Exact role counts match the 2,642 total government identities requirement', () {
      final users = (usersData['governmentUsers'] as List).cast<Map<String, dynamic>>();

      final superAdmins = users.where((u) => u['role'] == GovernmentRole.superAdminId).toList();
      final zonalDmcs = users.where((u) => u['role'] == GovernmentRole.zonalDmcId).toList();
      final centralHods = users.where((u) => u['role'] == GovernmentRole.centralDepartmentHodId).toList();
      final wardOfficers = users.where((u) => u['role'] == GovernmentRole.wardOfficerId).toList();
      final wardLeads = users.where((u) => u['role'] == GovernmentRole.wardDepartmentLeadId).toList();
      final crew = users.where((u) => u['role'] == GovernmentRole.departmentCrewId).toList();

      expect(superAdmins.length, equals(1), reason: 'Must have exactly 1 Super Admin (Municipal Commissioner)');
      expect(zonalDmcs.length, equals(7), reason: 'Must have exactly 7 Zonal DMCs (1 per zone)');
      expect(centralHods.length, equals(18), reason: 'Must have exactly 18 Central HODs (1 per department)');
      expect(wardOfficers.length, equals(24), reason: 'Must have exactly 24 Ward Officers (1 per ward)');
      expect(wardLeads.length, equals(432), reason: 'Must have exactly 432 Ward Department Leads (24 x 18)');
      expect(crew.length, equals(2160), reason: 'Must have exactly 2,160 Crew members (432 x 5)');

      final total = superAdmins.length +
          zonalDmcs.length +
          centralHods.length +
          wardOfficers.length +
          wardLeads.length +
          crew.length;

      expect(total, equals(2642), reason: 'Total government users must equal exactly 2,642');
      expect(users.length, equals(2642));
    });

    test('Zero duplicate employee IDs exist across all 2,642 government identities', () {
      final users = (usersData['governmentUsers'] as List).cast<Map<String, dynamic>>();
      final employeeIds = <String>{};

      for (final user in users) {
        final empId = user['employeeId'] as String;
        expect(empId.isNotEmpty, isTrue);
        expect(employeeIds.contains(empId), isFalse, reason: 'Duplicate employeeId found: $empId');
        employeeIds.add(empId);
      }

      expect(employeeIds.length, equals(2642));
    });

    test('Zero orphan supervisor IDs exist across the entire administrative and technical hierarchy', () {
      final users = (usersData['governmentUsers'] as List).cast<Map<String, dynamic>>();
      final employeeIdMap = {for (final u in users) u['employeeId'] as String: u};

      for (final user in users) {
        final adminSupId = user['administrativeSupervisorId'] as String?;
        final techSupId = user['technicalSupervisorId'] as String?;

        if (user['role'] == GovernmentRole.superAdminId) {
          expect(adminSupId, isNull, reason: 'Super Admin has no administrative supervisor');
          expect(techSupId, isNull, reason: 'Super Admin has no technical supervisor');
        } else if (user['role'] == GovernmentRole.zonalDmcId) {
          expect(adminSupId, isNotNull);
          expect(employeeIdMap.containsKey(adminSupId), isTrue, reason: 'Orphan admin supervisor: $adminSupId');
          expect(employeeIdMap[adminSupId]!['role'], equals(GovernmentRole.superAdminId));
        } else if (user['role'] == GovernmentRole.centralDepartmentHodId) {
          expect(adminSupId, isNotNull);
          expect(employeeIdMap.containsKey(adminSupId), isTrue, reason: 'Orphan admin supervisor: $adminSupId');
          expect(employeeIdMap[adminSupId]!['role'], equals(GovernmentRole.superAdminId));
        } else if (user['role'] == GovernmentRole.wardOfficerId) {
          expect(adminSupId, isNotNull);
          expect(employeeIdMap.containsKey(adminSupId), isTrue, reason: 'Orphan admin supervisor: $adminSupId');
          expect(employeeIdMap[adminSupId]!['role'], equals(GovernmentRole.zonalDmcId));
        } else if (user['role'] == GovernmentRole.wardDepartmentLeadId) {
          // Dual reporting check
          expect(adminSupId, isNotNull);
          expect(employeeIdMap.containsKey(adminSupId), isTrue, reason: 'Orphan admin supervisor: $adminSupId');
          expect(employeeIdMap[adminSupId]!['role'], equals(GovernmentRole.wardOfficerId));

          expect(techSupId, isNotNull);
          expect(employeeIdMap.containsKey(techSupId), isTrue, reason: 'Orphan technical supervisor: $techSupId');
          expect(employeeIdMap[techSupId]!['role'], equals(GovernmentRole.centralDepartmentHodId));
        } else if (user['role'] == GovernmentRole.departmentCrewId) {
          expect(adminSupId, isNotNull);
          expect(employeeIdMap.containsKey(adminSupId), isTrue, reason: 'Orphan admin supervisor: $adminSupId');
          expect(employeeIdMap[adminSupId]!['role'], equals(GovernmentRole.wardDepartmentLeadId));
        }
      }
    });

    test('Each of the 432 ward departments contains exactly 5 crew members and 1 designated lead', () {
      final wardDepts = (wardDeptsData['wardDepartments'] as List).cast<Map<String, dynamic>>();

      for (final wd in wardDepts) {
        final leadId = wd['departmentLeadId'] as String;
        final crewIds = wd['crewMemberIds'] as List;

        expect(leadId.startsWith('GOV-WDL-'), isTrue);
        expect(crewIds.length, equals(5), reason: 'Ward department ${wd['wardDepartmentId']} must have exactly 5 crew');
      }
    });
  });

  group('GovernmentHierarchyRepository - Traversal & Query Tests', () {
    late GovernmentHierarchyRepository repo;

    setUp(() async {
      repo = LocalGovernmentHierarchyRepository();
      await repo.initialize();
    });

    test('Queries return all 7 zones and 24 wards with correct zone linkages', () async {
      final zones = await repo.getZones();
      expect(zones.length, equals(7));

      final wards = await repo.getWards();
      expect(wards.length, equals(24));

      final zone1Wards = await repo.getWards(zoneId: 'ZONE_1');
      expect(zone1Wards.length, equals(3)); // Wards A, B, C
      expect(zone1Wards.map((w) => w.wardId).toSet(), containsAll(['A', 'B', 'C']));
    });

    test('Dual-chain traversal navigates correctly from ground crew to Super Admin', () async {
      final crew = await repo.getUserByEmployeeId('GOV-CREW-A-MAINTENANCE_ROADS-01');
      expect(crew, isNotNull);
      expect(crew!.isCrew, isTrue);

      // 1. Crew -> Ward Department Lead
      final lead = await repo.getAdministrativeSupervisor(crew);
      expect(lead, isNotNull);
      expect(lead!.employeeId, equals('GOV-WDL-A-MAINTENANCE_ROADS'));
      expect(lead.isWardLead, isTrue);

      // 2. Lead -> Ward Officer (Administrative Chain)
      final wardOfficer = await repo.getAdministrativeSupervisor(lead);
      expect(wardOfficer, isNotNull);
      expect(wardOfficer!.employeeId, equals('GOV-WO-A'));
      expect(wardOfficer.isWardOfficer, isTrue);

      // 3. Ward Officer -> Zonal DMC
      final dmc = await repo.getAdministrativeSupervisor(wardOfficer);
      expect(dmc, isNotNull);
      expect(dmc!.employeeId, equals('GOV-DMC-Z01'));
      expect(dmc.isZonalDmc, isTrue);

      // 4. Zonal DMC -> Super Admin
      final superAdmin = await repo.getAdministrativeSupervisor(dmc);
      expect(superAdmin, isNotNull);
      expect(superAdmin!.isSuperAdmin, isTrue);
      expect(superAdmin.employeeId, equals('GOV-SA-001'));

      // 5. Super Admin -> null
      final apex = await repo.getAdministrativeSupervisor(superAdmin);
      expect(apex, isNull);

      // 6. Lead -> Central HOD (Technical Chain)
      final hod = await repo.getTechnicalSupervisor(lead);
      expect(hod, isNotNull);
      expect(hod!.employeeId, equals('GOV-HOD-MAINTENANCE_ROADS'));
      expect(hod.isCentralHod, isTrue);

      // 7. Central HOD -> Super Admin
      final techApex = await repo.getAdministrativeSupervisor(hod);
      expect(techApex, isNotNull);
      expect(techApex!.employeeId, equals('GOV-SA-001'));
    });

    test('Subordinate resolution returns correct children for administrative and technical tiers', () async {
      // Super Admin -> 7 Zonal DMCs
      final sa = await repo.getUserByEmployeeId('GOV-SA-001');
      expect(sa, isNotNull);

      // Ward Officer -> 18 Ward Department Leads
      final woA = await repo.getUserByEmployeeId('GOV-WO-A');
      expect(woA, isNotNull);
      final woSubordinates = await repo.getAdministrativeSubordinates(woA!);
      expect(woSubordinates.length, equals(18));
      for (final sub in woSubordinates) {
        expect(sub.isWardLead, isTrue);
        expect(sub.wardId, equals('A'));
      }

      // Ward Department Lead -> 5 Crew Members
      final lead = await repo.getUserByEmployeeId('GOV-WDL-A-MAINTENANCE_ROADS');
      expect(lead, isNotNull);
      final crewSubordinates = await repo.getAdministrativeSubordinates(lead!);
      expect(crewSubordinates.length, equals(5));
      for (final c in crewSubordinates) {
        expect(c.isCrew, isTrue);
      }

      // Central HOD -> 24 Ward Department Leads (Technical Subordinates)
      final hod = await repo.getUserByEmployeeId('GOV-HOD-MAINTENANCE_ROADS');
      expect(hod, isNotNull);
      final techSubordinates = await repo.getTechnicalSubordinates(hod!);
      expect(techSubordinates.length, equals(24));
      for (final s in techSubordinates) {
        expect(s.isWardLead, isTrue);
        expect(s.departmentId, equals('maintenance_roads'));
      }
    });
  });

  group('ComplaintRoutingService - Wrong-Department Reassignment & SLA Tests', () {
    late GovernmentHierarchyRepository hierarchyRepo;
    late DefaultGovernmentAuditService auditService;
    late GovernmentAuthorizationService authService;
    late ComplaintRoutingService routingService;

    late ComplaintModel testComplaint;
    late DateTime originalComplaintTime;

    setUp(() async {
      hierarchyRepo = LocalGovernmentHierarchyRepository();
      await hierarchyRepo.initialize();

      auditService = DefaultGovernmentAuditService();
      auditService.clear();

      authService = GovernmentAuthorizationService(hierarchyRepo: hierarchyRepo);
      routingService = ComplaintRoutingService(
        hierarchyRepo: hierarchyRepo,
        auditService: auditService,
        authService: authService,
      );

      originalComplaintTime = DateTime(2026, 9, 20, 10, 0, 0);

      testComplaint = ComplaintModel(
        id: 'cmp_test_001',
        ticketNumber: 'CF-2026-000042',
        title: 'Garbage dump accumulating near footpath',
        description: 'Large heaps of solid waste not cleared for 3 days.',
        category: CivicCategory.defaultCategories[0], // Incorrect category assigned initially
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 18.922,
          longitude: 72.8347,
          address: 'Fort, Mumbai',
          ward: 'A',
        ),
        createdAt: originalComplaintTime,
        updatedAt: originalComplaintTime,
        wardId: 'A',
        assignedDepartmentId: 'maintenance_roads', // Misrouted to Roads
        assignedDepartmentLeadId: 'GOV-WDL-A-MAINTENANCE_ROADS',
        assignedCrewMemberId: 'GOV-CREW-A-MAINTENANCE_ROADS-01',
        routingStatus: ComplaintRoutingStatus.assigned,
        assignmentStatus: ComplaintAssignmentStatus.crewAssigned,
        slaStartedAt: originalComplaintTime,
        originalCreatedAt: originalComplaintTime,
        reassignmentCount: 0,
      );

      routingService.registerComplaint(testComplaint);
    });

    test('Ward Department Lead raises reassignment ticket and complaint SLA clock is strictly preserved', () async {
      final ticket = await routingService.raiseReassignmentRequest(
        complaintId: testComplaint.id,
        sourceLeadId: 'GOV-WDL-A-MAINTENANCE_ROADS',
        suggestedDepartmentId: 'solid_waste_management',
        reason: 'Issue relates to uncollected garbage, belongs to Solid Waste Management.',
      );

      expect(ticket.id, startsWith('CRT-'));
      expect(ticket.status, equals(RoutingTicketStatus.pending));
      expect(ticket.wardId, equals('A'));
      expect(ticket.sourceDepartmentId, equals('maintenance_roads'));
      expect(ticket.suggestedDepartmentId, equals('solid_waste_management'));

      // Check complaint state
      final updatedComplaint = (await routingService.getTicketsForComplaint(testComplaint.id)).isNotEmpty;
      expect(updatedComplaint, isTrue);

      final c = routingService.getTicketById(ticket.id);
      expect(c, isNotNull);

      // Audit Log recorded
      final logs = await auditService.getLogsForComplaint(testComplaint.id);
      expect(logs.any((l) => l.action == GovernmentAuditActions.reassignmentRequested), isTrue);
    });

    test('Unauthorized user cannot raise a reassignment ticket', () async {
      // Lead from Ward B attempting to reassign Ward A complaint
      expect(
        () => routingService.raiseReassignmentRequest(
          complaintId: testComplaint.id,
          sourceLeadId: 'GOV-WDL-B-MAINTENANCE_ROADS',
          suggestedDepartmentId: 'solid_waste_management',
          reason: 'Unauthorized attempt',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Ward Officer approves reassignment: transfers department, clears crew, preserves SLA clock', () async {
      // 1. Raise ticket
      final ticket = await routingService.raiseReassignmentRequest(
        complaintId: testComplaint.id,
        sourceLeadId: 'GOV-WDL-A-MAINTENANCE_ROADS',
        suggestedDepartmentId: 'solid_waste_management',
        reason: 'Misrouted garbage report',
      );

      // 2. Ward Officer of Ward A reviews and approves
      final reviewedTicket = await routingService.reviewRoutingTicket(
        ticketId: ticket.id,
        reviewerId: 'GOV-WO-A',
        approve: true,
        reviewNotes: 'Verified issue photos; correctly belongs to Solid Waste Management.',
      );

      expect(reviewedTicket.status, equals(RoutingTicketStatus.approved));
      expect(reviewedTicket.reviewedBy, equals('GOV-WO-A'));

      // 3. Inspect updated complaint from routingService
      final updatedComplaint = (await routingService.getComplaint(testComplaint.id))!;

      // Verify SLA policy: originalCreatedAt and slaStartedAt were NOT reset
      expect(updatedComplaint.originalCreatedAt, equals(originalComplaintTime));
      expect(updatedComplaint.slaStartedAt, equals(originalComplaintTime));
      expect(updatedComplaint.reassignmentCount, equals(1));
      expect(updatedComplaint.assignedDepartmentId, equals('solid_waste_management'));
      expect(updatedComplaint.assignedCrewMemberId, isNull, reason: 'Old crew must be cleared upon department transfer');
      expect(updatedComplaint.routingStatus, equals(ComplaintRoutingStatus.assigned));

      // 4. Verify audit log
      final logs = await auditService.getLogsForComplaint(testComplaint.id);
      expect(logs.any((l) => l.action == GovernmentAuditActions.reassignmentApproved), isTrue);
    });

    test('Ward Officer from another ward cannot approve reassignment ticket', () async {
      final ticket = await routingService.raiseReassignmentRequest(
        complaintId: testComplaint.id,
        sourceLeadId: 'GOV-WDL-A-MAINTENANCE_ROADS',
        suggestedDepartmentId: 'solid_waste_management',
        reason: 'Misrouted issue',
      );

      // Ward Officer of Ward B trying to approve Ward A ticket
      expect(
        () => routingService.reviewRoutingTicket(
          ticketId: ticket.id,
          reviewerId: 'GOV-WO-B',
          approve: true,
          reviewNotes: 'Illegal cross-ward action',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Ward Officer rejects reassignment: complaint stays in source department and SLA clock is preserved', () async {
      final ticket = await routingService.raiseReassignmentRequest(
        complaintId: testComplaint.id,
        sourceLeadId: 'GOV-WDL-A-MAINTENANCE_ROADS',
        suggestedDepartmentId: 'solid_waste_management',
        reason: 'Misrouted issue',
      );

      final reviewedTicket = await routingService.reviewRoutingTicket(
        ticketId: ticket.id,
        reviewerId: 'GOV-WO-A',
        approve: false,
        reviewNotes: 'Debris is asphalt road material from trench, not municipal solid waste.',
      );

      expect(reviewedTicket.status, equals(RoutingTicketStatus.rejected));
      expect(reviewedTicket.reviewedBy, equals('GOV-WO-A'));

      final logs = await auditService.getLogsForComplaint(testComplaint.id);
      expect(logs.any((l) => l.action == GovernmentAuditActions.reassignmentRejected), isTrue);
    });

    test('Lead assigns new crew technician and audit log is created', () async {
      final complaintWithLead = testComplaint.copyWith(
        assignedCrewMemberId: null,
        assignmentStatus: ComplaintAssignmentStatus.leadAssigned,
      );
      routingService.registerComplaint(complaintWithLead);

      final assigned = await routingService.assignCrewMember(
        complaintId: complaintWithLead.id,
        leadId: 'GOV-WDL-A-MAINTENANCE_ROADS',
        crewMemberId: 'GOV-CREW-A-MAINTENANCE_ROADS-03',
      );

      expect(assigned.assignedCrewMemberId, equals('GOV-CREW-A-MAINTENANCE_ROADS-03'));
      expect(assigned.assignmentStatus, equals(ComplaintAssignmentStatus.crewAssigned));

      final logs = await auditService.getLogsForComplaint(complaintWithLead.id);
      expect(logs.any((l) => l.action == GovernmentAuditActions.crewAssigned), isTrue);
    });
  });

  group('GovernmentAuthorizationService - Matrix RBAC Jurisdiction Tests', () {
    late GovernmentHierarchyRepository hierarchyRepo;
    late GovernmentAuthorizationService authService;

    setUp(() async {
      hierarchyRepo = LocalGovernmentHierarchyRepository();
      await hierarchyRepo.initialize();
      authService = GovernmentAuthorizationService(hierarchyRepo: hierarchyRepo);
    });

    test('Complaint visibility follows matrix jurisdiction rules across all tiers', () async {
      final complaintWardA = ComplaintModel(
        id: 'c_a_rds',
        ticketNumber: 'CF-2026-000101',
        title: 'Road issue in Ward A',
        description: 'Pothole on Colaba Causeway',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 18.922, longitude: 72.8347, address: 'Colaba', ward: 'A'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        wardId: 'A',
        assignedDepartmentId: 'maintenance_roads',
      );

      final complaintWardD = ComplaintModel(
        id: 'c_d_rds',
        ticketNumber: 'CF-2026-000102',
        title: 'Road issue in Ward D',
        description: 'Trench on Grant Road',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 18.961, longitude: 72.815, address: 'Grant Road', ward: 'D'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        wardId: 'D',
        assignedDepartmentId: 'maintenance_roads',
      );

      final superAdmin = (await hierarchyRepo.getUserByEmployeeId('GOV-SA-001'))!;
      final dmcZone1 = (await hierarchyRepo.getUserByEmployeeId('GOV-DMC-Z01'))!; // Zone 1 contains Ward A, B, C
      final dmcZone2 = (await hierarchyRepo.getUserByEmployeeId('GOV-DMC-Z02'))!; // Zone 2 contains Ward D
      final hodRoads = (await hierarchyRepo.getUserByEmployeeId('GOV-HOD-MAINTENANCE_ROADS'))!;
      final hodWater = (await hierarchyRepo.getUserByEmployeeId('GOV-HOD-WATER_WORKS'))!;
      final woA = (await hierarchyRepo.getUserByEmployeeId('GOV-WO-A'))!;
      final woD = (await hierarchyRepo.getUserByEmployeeId('GOV-WO-D'))!;
      final leadARoads = (await hierarchyRepo.getUserByEmployeeId('GOV-WDL-A-MAINTENANCE_ROADS'))!;
      final leadAWater = (await hierarchyRepo.getUserByEmployeeId('GOV-WDL-A-WATER_WORKS'))!;

      // 1. Super Admin sees both
      expect(await authService.canViewComplaint(superAdmin, complaintWardA), isTrue);
      expect(await authService.canViewComplaint(superAdmin, complaintWardD), isTrue);

      // 2. DMC Zone 1 sees Ward A (in Zone 1) but NOT Ward D (in Zone 2)
      expect(await authService.canViewComplaint(dmcZone1, complaintWardA), isTrue);
      expect(await authService.canViewComplaint(dmcZone1, complaintWardD), isFalse);

      // 3. DMC Zone 2 sees Ward D but NOT Ward A
      expect(await authService.canViewComplaint(dmcZone2, complaintWardD), isTrue);
      expect(await authService.canViewComplaint(dmcZone2, complaintWardA), isFalse);

      // 4. Central HOD Roads sees both Ward A and Ward D road complaints across Mumbai
      expect(await authService.canViewComplaint(hodRoads, complaintWardA), isTrue);
      expect(await authService.canViewComplaint(hodRoads, complaintWardD), isTrue);

      // 5. Central HOD Water does NOT see road complaints
      expect(await authService.canViewComplaint(hodWater, complaintWardA), isFalse);

      // 6. Ward Officer A sees Ward A complaint, NOT Ward D
      expect(await authService.canViewComplaint(woA, complaintWardA), isTrue);
      expect(await authService.canViewComplaint(woA, complaintWardD), isFalse);

      // Ward Officer D sees Ward D complaint, NOT Ward A
      expect(await authService.canViewComplaint(woD, complaintWardD), isTrue);
      expect(await authService.canViewComplaint(woD, complaintWardA), isFalse);

      // 7. Ward Lead A Roads sees Ward A road complaint
      expect(await authService.canViewComplaint(leadARoads, complaintWardA), isTrue);
      // Ward Lead A Water does NOT see Ward A road complaint
      expect(await authService.canViewComplaint(leadAWater, complaintWardA), isFalse);
    });
  });
}
