import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_authorization_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/core/local/mock_data_source.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/services/government_department_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/government_crew_work_service.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

void main() {
  late GovernmentCrewWorkService workService;
  late MockGovtComplaintRepository complaintRepo;
  late LocalGovernmentHierarchyRepository hierarchyRepo;
  late ComplaintRoutingService routingService;
  late DefaultGovernmentAuditService auditService;
  late GovernmentAuthorizationService authService;
  late GovtUserModel testCrew01;
  late GovtUserModel testCrew02;

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

    workService = GovernmentCrewWorkService(
      complaintRepo: complaintRepo,
      hierarchyRepo: hierarchyRepo,
      routingService: routingService,
      auditService: auditService,
      authService: authService,
      hazardRepo: RepositoryLocator.hazardRepository,
    );

    testCrew01 = const GovtUserModel(
      id: 'GOV-CREW-N-ROADS-01',
      employeeId: 'GOV-CREW-N-ROADS-01',
      fullName: 'Ramesh Powar (Technician 01)',
      email: 'ramesh.powar@mcgm.gov.in',
      role: 'department_crew',
      wardId: 'N',
      departmentId: 'dept_roads',
      departmentName: 'Roads & Maintenance',
      displayDesignation: 'Junior Engineer / Ground Technician',
      active: true,
    );

    testCrew02 = const GovtUserModel(
      id: 'GOV-CREW-N-ROADS-02',
      employeeId: 'GOV-CREW-N-ROADS-02',
      fullName: 'Suresh Patil (Technician 02)',
      email: 'suresh.patil@mcgm.gov.in',
      role: 'department_crew',
      wardId: 'N',
      departmentId: 'dept_roads',
      departmentName: 'Roads & Maintenance',
      displayDesignation: 'Junior Engineer / Ground Technician',
      active: true,
    );

    // Seed mock complaints with distinct crew assignments
    final now = DateTime.now();

    // 1. Complaint assigned to testCrew01 (Assigned state)
    final c1 = ComplaintModel(
      id: 'CMP-CREW-TEST-001',
      ticketNumber: 'TKT-CREW-001',
      title: 'Major Pothole on LBS Marg',
      description: 'Dangerous depression in asphalt near railway bridge.',
      category: const CivicCategory(
        id: 'dept_roads',
        name: 'Roads & Traffic',
        description: 'Road damage and potholes',
        icon: Icons.traffic,
      ),
      status: ComplaintStatus.assigned,
      priority: ComplaintPriority.emergency,
      location: const CivicLocation(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'LBS Marg, Ghatkopar West',
        ward: 'N',
      ),
      createdAt: now.subtract(const Duration(hours: 10)),
      updatedAt: now.subtract(const Duration(hours: 10)),
      assignedDepartmentId: 'dept_roads',
      assignedDepartmentLeadId: 'GOV-LEAD-N-ROADS',
      assignedCrewMemberId: testCrew01.employeeId,
      assignedTo: testCrew01.fullName,
      wardId: 'N',
      slaStartedAt: now.subtract(const Duration(hours: 10)),
      originalCreatedAt: now.subtract(const Duration(hours: 10)),
    );

    // 2. Complaint assigned to testCrew01 (In-progress state)
    final c2 = ComplaintModel(
      id: 'CMP-CREW-TEST-002',
      ticketNumber: 'TKT-CREW-002',
      title: 'Broken Paver Blocks at MG Road',
      description: 'Uneven pedestrian pathway needing paver replacement.',
      category: const CivicCategory(
        id: 'dept_roads',
        name: 'Roads & Traffic',
        description: 'Road damage and potholes',
        icon: Icons.traffic,
      ),
      status: ComplaintStatus.inProgress,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0800,
        longitude: 72.8800,
        address: 'MG Road, Ghatkopar East',
        ward: 'N',
      ),
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      assignedDepartmentId: 'dept_roads',
      assignedCrewMemberId: testCrew01.employeeId,
      assignedTo: testCrew01.fullName,
      wardId: 'N',
      slaStartedAt: now.subtract(const Duration(hours: 4)),
      originalCreatedAt: now.subtract(const Duration(hours: 4)),
    );

    // 3. Complaint assigned to testCrew02 (Same Ward, Same Dept, Different Crew!)
    final c3 = ComplaintModel(
      id: 'CMP-CREW-TEST-003',
      ticketNumber: 'TKT-CREW-003',
      title: 'Curb Stone Displacement',
      description: 'Damaged sidewalk curb on 90 Feet Road.',
      category: const CivicCategory(
        id: 'dept_roads',
        name: 'Roads & Traffic',
        description: 'Road damage and potholes',
        icon: Icons.traffic,
      ),
      status: ComplaintStatus.assigned,
      priority: ComplaintPriority.medium,
      location: const CivicLocation(
        latitude: 19.0850,
        longitude: 72.8850,
        address: '90 Feet Road, Ghatkopar',
        ward: 'N',
      ),
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 6)),
      assignedDepartmentId: 'dept_roads',
      assignedCrewMemberId: testCrew02.employeeId,
      assignedTo: testCrew02.fullName,
      wardId: 'N',
    );

    // 4. Complaint in different department (SWM in Ward N)
    final c4 = ComplaintModel(
      id: 'CMP-CREW-TEST-004',
      ticketNumber: 'TKT-CREW-004',
      title: 'Garbage Bin Overflow',
      description: 'Waste overflowing near market area.',
      category: const CivicCategory(
        id: 'dept_swm',
        name: 'Solid Waste',
        description: 'Garbage accumulation',
        icon: Icons.delete_outline_rounded,
      ),
      status: ComplaintStatus.assigned,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Market Lane, Ghatkopar',
        ward: 'N',
      ),
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 3)),
      assignedDepartmentId: 'dept_swm',
      assignedCrewMemberId: 'GOV-CREW-N-SWM-01',
      wardId: 'N',
    );

    // 5. Complaint in different ward (Ward M Maintenance)
    final c5 = ComplaintModel(
      id: 'CMP-CREW-TEST-005',
      ticketNumber: 'TKT-CREW-005',
      title: 'Pothole in Ward M Chembur',
      description: 'Pothole on Sion Trombay Road.',
      category: const CivicCategory(
        id: 'dept_roads',
        name: 'Roads & Traffic',
        description: 'Road damage and potholes',
        icon: Icons.traffic,
      ),
      status: ComplaintStatus.assigned,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0600,
        longitude: 72.8900,
        address: 'Sion Trombay Road, Chembur',
        ward: 'M',
      ),
      createdAt: now.subtract(const Duration(hours: 8)),
      updatedAt: now.subtract(const Duration(hours: 8)),
      assignedDepartmentId: 'dept_roads',
      assignedCrewMemberId: 'GOV-CREW-M-ROADS-01',
      wardId: 'M',
    );

    // Register into MockDataSource
    MockDataSource().complaints.addAll([c1, c2, c3, c4, c5]);
    for (final c in [c1, c2, c3, c4, c5]) {
      routingService.registerComplaint(c);
      await complaintRepo.assignComplaint(
        complaintId: c.id,
        departmentId: c.assignedDepartmentId ?? 'dept_roads',
        officerName: c.assignedTo ?? 'Field Crew',
      );
    }
  });

  group('Phase 8 - Section 1: Strict Crew Member Isolation', () {
    test('Loads strictly assigned jobs for testCrew01', () async {
      final data = await workService.loadCrewWorkdesk(
        crewId: testCrew01.employeeId,
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
      expect(data.crewUser.employeeId, testCrew01.employeeId);

      // Verify all jobs belong strictly to testCrew01
      for (final item in data.allMyJobs) {
        final matchesCrewId = item.complaint.assignedCrewMemberId == testCrew01.employeeId;
        final matchesCrewName = item.complaint.assignedTo == testCrew01.fullName;
        expect(matchesCrewId || matchesCrewName, isTrue);
      }
    });

    test('Zero cross-crew data leakage (testCrew02 assignments are HIDDEN)', () async {
      final data = await workService.loadCrewWorkdesk(
        crewId: testCrew01.employeeId,
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      final hasCrew02Job = data.allMyJobs.any(
        (j) => j.complaint.assignedCrewMemberId == testCrew02.employeeId || j.id == 'CMP-CREW-TEST-003',
      );
      expect(hasCrew02Job, isFalse);
    });

    test('Zero cross-department data leakage (SWM complaints are HIDDEN)', () async {
      final data = await workService.loadCrewWorkdesk(
        crewId: testCrew01.employeeId,
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      final hasSwmJob = data.allMyJobs.any(
        (j) => j.complaint.assignedDepartmentId == 'dept_swm' || j.id == 'CMP-CREW-TEST-004',
      );
      expect(hasSwmJob, isFalse);
    });

    test('Zero cross-ward data leakage (Ward M complaints are HIDDEN)', () async {
      final data = await workService.loadCrewWorkdesk(
        crewId: testCrew01.employeeId,
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      final hasWardMJob = data.allMyJobs.any(
        (j) => j.complaint.wardId == 'M' || j.id == 'CMP-CREW-TEST-005',
      );
      expect(hasWardMJob, isFalse);
    });
  });

  group('Phase 8 - Section 2: KPI Metrics Calculation', () {
    test('Calculates accurate field metrics for crew member', () async {
      final data = await workService.loadCrewWorkdesk(
        crewId: testCrew01.employeeId,
        wardId: 'N',
        departmentId: 'dept_roads',
      );

      final kpis = data.kpiMetrics;
      expect(kpis.totalAssignedCount, greaterThanOrEqualTo(2));
      expect(kpis.inProgressCount, greaterThanOrEqualTo(1));
      expect(kpis.criticalCount, greaterThanOrEqualTo(1));
    });
  });

  group('Phase 8 - Section 3: Start Job Workflow', () {
    test('Technician can start an assigned job', () async {
      final updated = await workService.startJob(
        complaintId: 'CMP-CREW-TEST-001',
        crewId: testCrew01.employeeId,
      );

      expect(updated.status, ComplaintStatus.inProgress);
      expect(updated.timeline.first.title, 'Work Started in Field');
    });

    test('Non-assigned crew member cannot start another crew\'s job', () async {
      expect(
        () => workService.startJob(
          complaintId: 'CMP-CREW-TEST-001',
          crewId: testCrew02.employeeId,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Phase 8 - Section 4: Evidence Capture & Direct Closure Submission', () {
    test('Submits completion evidence and directly transitions to Closed without mandatory lead verification', () async {
      final updated = await workService.submitWorkCompletion(
        complaintId: 'CMP-CREW-TEST-002',
        crewId: testCrew01.employeeId,
        beforePhotoUrl: 'https://images.unsplash.com/photo-before.jpg',
        afterPhotoUrl: 'https://images.unsplash.com/photo-after.jpg',
        workRemarks: 'Paver blocks reset and leveled with sand bedding.',
      );

      // CRITICAL: Complaint transitions directly to Closed upon valid completion submission
      expect(updated.status, equals(ComplaintStatus.closed));
      expect(updated.closedAt, isNotNull);
      expect(updated.closedBy, equals(testCrew01.employeeId));
      expect(updated.resolvedAt, isNotNull);
      expect(updated.resolvedBy, equals(testCrew01.employeeId));
      expect(updated.imageUrls, contains('https://images.unsplash.com/photo-before.jpg'));
      expect(updated.imageUrls, contains('https://images.unsplash.com/photo-after.jpg'));
      expect(updated.officerNotes, contains('Paver blocks reset'));
      expect(updated.timeline.first.title, equals('Field Work Completed & Closed'));
      expect(updated.timeline.first.description, contains('Field work completed with resolution evidence'));
    });

    test('Rejects completion submission if Before Photo is missing', () async {
      expect(
        () => workService.submitWorkCompletion(
          complaintId: 'CMP-CREW-TEST-002',
          crewId: testCrew01.employeeId,
          beforePhotoUrl: '',
          afterPhotoUrl: 'https://images.unsplash.com/photo-after.jpg',
          workRemarks: 'Done.',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejects completion submission if After Photo is missing', () async {
      expect(
        () => workService.submitWorkCompletion(
          complaintId: 'CMP-CREW-TEST-002',
          crewId: testCrew01.employeeId,
          beforePhotoUrl: 'https://images.unsplash.com/photo-before.jpg',
          afterPhotoUrl: '',
          workRemarks: 'Done.',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Accepts completion submission with empty remarks and closes complaint', () async {
      final updated = await workService.submitWorkCompletion(
        complaintId: 'CMP-CREW-TEST-002',
        crewId: testCrew01.employeeId,
        beforePhotoUrl: 'https://images.unsplash.com/photo-before.jpg',
        afterPhotoUrl: 'https://images.unsplash.com/photo-after.jpg',
        workRemarks: '   ',
      );
      expect(updated.status, equals(ComplaintStatus.closed));
    });
  });

  group('Phase 8 - Section 5: Rework Resumption & Blocked Issue Logging', () {
    test('Resumes field work on job returned for rework', () async {
      final updated = await workService.resumeWorkAfterRework(
        complaintId: 'CMP-CREW-TEST-002',
        crewId: testCrew01.employeeId,
        remarks: 'Repaired edge joint with additional asphalt mix.',
      );

      expect(updated.status, ComplaintStatus.inProgress);
      expect(updated.timeline.first.title, 'Rework Resumed in Field');
    });

    test('Logs on-site issue without changing department or closing complaint', () async {
      final updated = await workService.reportBlockedIssue(
        complaintId: 'CMP-CREW-TEST-001',
        crewId: testCrew01.employeeId,
        reasonCategory: 'Specialized Equipment Required',
        details: 'Trench cutter required for deep cable conduit repair.',
      );

      expect(updated.assignedDepartmentId, 'dept_roads');
      expect(updated.status, ComplaintStatus.assigned);
      expect(updated.officerNotes, contains('Specialized Equipment Required'));
    });
  });

  group('Phase 8 - Section 6: Field Execution Officer (JE -> FO Separation & Start Job Auth Alignment)', () {
    late GovtUserModel ganeshFO;
    late GovtUserModel rameshJE;
    late GovtUserModel otherCrew;
    late ComplaintModel foAssignedComplaint;

    setUp(() async {
      rameshJE = const GovtUserModel(
        id: 'GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-01',
        employeeId: 'GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-01',
        fullName: 'Ramesh Powar',
        email: 'ramesh.powar@mcgm.gov.in',
        role: 'department_crew',
        wardId: 'R_SOUTH',
        departmentId: 'maintenance_roads',
        departmentName: 'Roads & Maintenance',
        displayDesignation: 'Junior Engineer',
        active: true,
      );

      ganeshFO = const GovtUserModel(
        id: 'rbQflILEPabot9t9EScfQmdmvn73',
        employeeId: 'GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-02',
        fullName: 'Ganesh Kulkarni',
        email: 'crew.r_south.rds.02@civicfix.dev',
        role: 'department_crew',
        wardId: 'R_SOUTH',
        departmentId: 'maintenance_roads',
        departmentName: 'Roads & Maintenance',
        displayDesignation: 'Field Crew Technician 2',
        active: true,
      );

      otherCrew = const GovtUserModel(
        id: 'GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-03',
        employeeId: 'GOV-CREW-R_SOUTH-MAINTENANCE_ROADS-03',
        fullName: 'Sanjay Shinde',
        email: 'sanjay.shinde@mcgm.gov.in',
        role: 'department_crew',
        wardId: 'R_SOUTH',
        departmentId: 'maintenance_roads',
        departmentName: 'Roads & Maintenance',
        displayDesignation: 'Field Crew Technician 3',
        active: true,
      );

      final now = DateTime.now();
      foAssignedComplaint = ComplaintModel(
        id: 'CF-2026-1791368464448000-a32fe69cef8b',
        ticketNumber: 'CF-2026-1791368464448000-a32fe69cef8b',
        title: 'Dangerous Pothole on Link Road',
        description: 'Large crater in road creating traffic hazard.',
        category: const CivicCategory(
          id: 'maintenance_roads',
          name: 'Roads & Maintenance',
          description: 'Road damage and potholes',
          icon: Icons.traffic,
        ),
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(
          latitude: 19.2000,
          longitude: 72.8500,
          address: 'Link Road, Kandivali West',
          ward: 'R_SOUTH',
        ),
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        wardId: 'R_SOUTH',
        assignedDepartmentId: 'maintenance_roads',
        assignedDepartmentLeadId: 'GOV-WDL-R_SOUTH-MAINTENANCE_ROADS',
        assignedCrewMemberId: rameshJE.employeeId,
        assignedJuniorEngineerNameSnapshot: rameshJE.fullName,
        assignedJuniorEngineerDesignationSnapshot: rameshJE.displayDesignation,
        assignedFieldOfficerId: ganeshFO.employeeId,
        assignedFieldOfficerNameSnapshot: ganeshFO.fullName,
        assignedFieldOfficerDesignationSnapshot: ganeshFO.displayDesignation,
        assignedFieldOfficerAt: now.subtract(const Duration(hours: 1)),
        assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
        slaStartedAt: now.subtract(const Duration(hours: 5)),
        originalCreatedAt: now.subtract(const Duration(hours: 5)),
      );

      MockDataSource().complaints.removeWhere((c) => c.id == foAssignedComplaint.id);
      MockDataSource().complaints.add(foAssignedComplaint);
      routingService.registerComplaint(foAssignedComplaint);
    });

    test('Assigned Field Officer (Ganesh) successfully starts the job and records workStartedAt', () async {
      final updated = await workService.startJob(
        complaintId: foAssignedComplaint.id,
        crewId: ganeshFO.employeeId,
      );

      expect(updated.status, ComplaintStatus.inProgress);
      expect(updated.routingStatus, ComplaintRoutingStatus.inProgress);
      expect(updated.workStartedAt, isNotNull);
      expect(updated.workStartedBy, ganeshFO.employeeId);
      expect(updated.timeline.first.title, 'Work Started in Field');
      expect(updated.assignedFieldOfficerId, ganeshFO.employeeId);
      expect(updated.assignedCrewMemberId, rameshJE.employeeId);
    });

    test('Supervising Junior Engineer cannot start the job once Field Officer is assigned (JE/FO Separation)', () async {
      expect(
        () => workService.startJob(
          complaintId: foAssignedComplaint.id,
          crewId: rameshJE.employeeId,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Security Violation'),
        )),
      );
    });

    test('Unassigned crew member in same Ward and Dept cannot start the job', () async {
      expect(
        () => workService.startJob(
          complaintId: foAssignedComplaint.id,
          crewId: otherCrew.employeeId,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Security Violation'),
        )),
      );
    });

    test('Assigned Field Officer can submit completion and report obstacle', () async {
      // 1. Ganesh reports obstacle
      final blocked = await workService.reportBlockedIssue(
        complaintId: foAssignedComplaint.id,
        crewId: ganeshFO.employeeId,
        reasonCategory: 'Site Inaccessible',
        details: 'Blocked by parked vehicles.',
      );
      expect(blocked.officerNotes, contains('Site Inaccessible'));

      // 2. Ganesh starts work
      await workService.startJob(
        complaintId: foAssignedComplaint.id,
        crewId: ganeshFO.employeeId,
      );

      // 3. Ganesh submits completion
      final completed = await workService.submitWorkCompletion(
        complaintId: foAssignedComplaint.id,
        crewId: ganeshFO.employeeId,
        beforePhotoUrl: 'https://images.unsplash.com/before.jpg',
        afterPhotoUrl: 'https://images.unsplash.com/after.jpg',
        workRemarks: 'Pothole filled with cold asphalt mix.',
      );
      expect(completed.status, ComplaintStatus.closed);
      expect(completed.imageUrls, contains('https://images.unsplash.com/before.jpg'));
      expect(completed.imageUrls, contains('https://images.unsplash.com/after.jpg'));

      // 4. Ward Department Lead reopens complaint for rework (SLA preserved, increments reopenCount)
      final reopened = await workService.reopenComplaint(
        complaintId: foAssignedComplaint.id,
        actorId: 'GOV-LEAD-R_SOUTH-ROADS',
        reopenReason: 'Cold mix uncompacted and already eroding.',
      );
      expect(reopened.status, ComplaintStatus.inProgress);
      expect(reopened.reopenCount, 1);
      expect(reopened.reopenReason, contains('Cold mix uncompacted'));
      expect(reopened.slaStartedAt, equals(foAssignedComplaint.slaStartedAt));
      expect(reopened.originalCreatedAt, equals(foAssignedComplaint.originalCreatedAt));
      expect(reopened.previousResolutionEvidence, contains('https://images.unsplash.com/after.jpg'));
    });
  });
}
