import 'dart:async';
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
import 'package:civic_app/Govt UI/models/department_model.dart';
import 'package:civic_app/Govt UI/services/government_crew_work_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

class _MockGovtComplaintRepo implements GovtComplaintRepository {
  List<ComplaintModel> complaints = [];

  @override
  Future<List<ComplaintModel>> getComplaints({
    String? departmentId,
    String? categoryId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    bool? isAssigned,
    String? searchQuery,
    GovtComplaintSort sortBy = GovtComplaintSort.newest,
  }) async {
    return List<ComplaintModel>.from(complaints);
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    return complaints.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<GovtDashboardMetrics> getDashboardMetrics({String? departmentId}) async {
    return const GovtDashboardMetrics(
      totalComplaints: 0,
      reportedCount: 0,
      verifiedCount: 0,
      assignedCount: 0,
      inProgressCount: 0,
      resolvedCount: 0,
      criticalHazardsCount: 0,
    );
  }

  @override
  Future<List<CategoryDistributionItem>> getCategoryDistribution() async => const [];

  @override
  Future<List<StatusDistributionItem>> getStatusDistribution() async => const [];

  @override
  Future<List<ComplaintModel>> getAttentionRequiredComplaints({int limit = 5}) async => const [];

  @override
  Future<bool> verifyComplaint({required String complaintId, required String notes, String? officerName}) async => true;

  @override
  Future<bool> flagComplaint({required String complaintId, required String reason, String? officerName}) async => true;

  @override
  Future<bool> rejectComplaint({required String complaintId, required String reason, String? officerName}) async => true;

  @override
  Future<bool> updateStatus({required String complaintId, required ComplaintStatus nextStatus, required String updateMessage, String? officerName}) async => true;

  @override
  Future<bool> assignComplaint({required String complaintId, required String departmentId, required String officerName, String? assignmentNote}) async => true;

  @override
  Future<List<GovtDepartmentModel>> getDepartments() async => const [];

  @override
  Future<List<GovtOfficerModel>> getOfficers({String? departmentId}) async => const [];

  @override
  Stream<List<ComplaintModel>> watchComplaints({String? departmentId, String? categoryId, ComplaintStatus? status, ComplaintPriority? priority, bool? isAssigned, String? searchQuery, GovtComplaintSort sortBy = GovtComplaintSort.newest}) async* {
    yield complaints;
  }

  @override
  Stream<ComplaintModel?> watchComplaint(String id) async* {
    yield complaints.where((c) => c.id == id).firstOrNull;
  }

  @override
  Stream<GovtDashboardMetrics> watchDashboardMetrics({String? departmentId}) async* {
    yield await getDashboardMetrics(departmentId: departmentId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String jeId = 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-01';
  const String foId = 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-02';
  const String fo3Id = 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-03';
  const String fo4Id = 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-04';
  const String fo5Id = 'GOV-CREW-G_NORTH-MAINTENANCE_ROADS-05';
  const String leadId = 'GOV-LEAD-G_NORTH-MAINTENANCE_ROADS';
  const String aJe = 'GOV-CREW-A-WATER_WORKS-01';

  late LocalGovernmentHierarchyRepository hierarchyRepo;
  late DefaultGovernmentAuditService auditService;
  late GovernmentAuthorizationService authService;
  late ComplaintRoutingService routingService;
  late _MockGovtComplaintRepo mockRepo;
  late GovernmentCrewWorkService crewWorkService;

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
    mockRepo = _MockGovtComplaintRepo();
    crewWorkService = GovernmentCrewWorkService(
      complaintRepo: mockRepo,
      hierarchyRepo: hierarchyRepo,
      routingService: routingService,
      auditService: auditService,
      authService: authService,
    );
  });

  ComplaintModel createBaseComplaint({
    String id = 'cmp_phase2_001',
    String wardId = 'G_NORTH',
    String departmentId = 'maintenance_roads',
    String? assignedCrewMemberId,
    ComplaintStatus status = ComplaintStatus.assigned,
    ComplaintAssignmentStatus assignmentStatus = ComplaintAssignmentStatus.crewAssigned,
    DateTime? slaStartedAt,
    DateTime? originalCreatedAt,
  }) {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final c = ComplaintModel(
      id: id,
      citizenId: 'citizen_mumbai_001',
      ticketNumber: 'CF-2026-GN-RDS-0042',
      title: 'Deep pothole on Senapati Bapat Marg near Dadar station',
      description: 'Dangerous pothole causing severe traffic bottleneck and vehicle damage.',
      category: CivicCategory.defaultCategories[0], // roads
      status: status,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0178,
        longitude: 72.8478,
        address: 'Senapati Bapat Marg, Dadar West, Mumbai 400028',
        ward: 'G/North',
        city: 'Mumbai',
        pincode: '400028',
      ),
      createdAt: now,
      updatedAt: now,
      wardId: wardId,
      assignedDepartmentId: departmentId,
      assignedCrewMemberId: assignedCrewMemberId ?? jeId,
      assignmentStatus: assignmentStatus,
      slaStartedAt: slaStartedAt ?? now,
      originalCreatedAt: originalCreatedAt ?? now,
    );
    routingService.registerComplaint(c);
    return c;
  }

  group('CIVICFIX PHASE 2: JUNIOR ENGINEER → FIELD OFFICER → GROUND EXECUTION → RESOLUTION', () {
    // =========================================================================
    // PART 1: JUNIOR ENGINEER RECEIPT & FIELD OFFICER ELIGIBILITY
    // =========================================================================
    group('1. Junior Engineer Visibility & Field Officer Eligibility Discovery', () {
      test('Scenario 1: JE sees Phase 1 complaint in assigned status', () async {
        final complaint = createBaseComplaint(assignedCrewMemberId: jeId);

        expect(complaint.status, equals(ComplaintStatus.assigned));
        expect(complaint.assignedJuniorEngineerId, equals(jeId));
        expect(complaint.isJuniorEngineerAssigned, isTrue);
        expect(complaint.assignmentStatus, equals(ComplaintAssignmentStatus.crewAssigned));
        expect(complaint.assignedFieldOfficerId, isNull);
        expect(complaint.isFieldOfficerAssigned, isFalse);
      });

      test('Scenario 2: JE retrieves eligible Field Officers for complaint Ward × Dept', () async {
        final eligibleOfficers = await routingService.getEligibleFieldOfficers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
          juniorEngineerId: jeId,
        );

        expect(eligibleOfficers, isNotEmpty);
        // There are 5 crew members per unit, 1 is JE, so 4 eligible FOs
        expect(eligibleOfficers.length, equals(4));
        for (final officer in eligibleOfficers) {
          expect(officer.wardId, equals('G_NORTH'));
          expect(officer.departmentId, equals('maintenance_roads'));
          expect(officer.active, isTrue);
          expect(officer.isCrew, isTrue);
          expect(officer.employeeId, isNot(equals(jeId)));
        }
      });

      test('Scenario 3: Candidate list excludes Junior Engineer themselves', () async {
        final eligibleOfficers = await routingService.getEligibleFieldOfficers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
          juniorEngineerId: jeId,
        );

        final containsJE = eligibleOfficers.any((fo) => fo.id == jeId || fo.employeeId == jeId);
        expect(containsJE, isFalse);
      });

      test('Scenario 4: Candidate list contains only active crew members in same Ward × Dept', () async {
        final eligibleOfficers = await routingService.getEligibleFieldOfficers(
          wardId: 'A',
          departmentId: 'water_works',
          juniorEngineerId: aJe,
        );

        expect(eligibleOfficers.length, equals(4));
        for (final officer in eligibleOfficers) {
          expect(officer.wardId, equals('A'));
          expect(officer.departmentId, equals('water_works'));
          expect(officer.role, equals(GovernmentRole.departmentCrewId));
        }
      });

      test('Scenario 5: Candidate list sorted by active field workload ascending', () async {
        // Create mock existing active complaints assigning heavy workload to foId
        final activeComplaints = [
          createBaseComplaint(id: 'c1').copyWith(
            assignedFieldOfficerId: foId,
            status: ComplaintStatus.inProgress,
          ),
          createBaseComplaint(id: 'c2').copyWith(
            assignedFieldOfficerId: foId,
            status: ComplaintStatus.assigned,
          ),
          createBaseComplaint(id: 'c3').copyWith(
            assignedFieldOfficerId: fo3Id,
            status: ComplaintStatus.inProgress,
          ),
        ];

        final sortedOfficers = await routingService.getEligibleFieldOfficers(
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
          juniorEngineerId: jeId,
          allComplaints: activeComplaints,
        );

        expect(sortedOfficers.first.employeeId, isNot(equals(foId)));
        expect(sortedOfficers.last.employeeId, equals(foId));
      });
    });

    // =========================================================================
    // PART 2: FIELD OFFICER ASSIGNMENT VALIDATIONS & METADATA
    // =========================================================================
    group('2. Field Officer Assignment & Authorization Rules', () {
      test('Scenario 6: JE assigns distinct Field Officer successfully', () async {
        final initial = createBaseComplaint(assignedCrewMemberId: jeId);

        final updated = await routingService.assignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          fieldOfficerId: foId,
        );

        expect(updated.assignedFieldOfficerId, equals(foId));
        expect(updated.assignedFieldOfficerAt, isNotNull);
        expect(updated.assignedFieldOfficerNameSnapshot, isNotEmpty);
        expect(updated.assignedFieldOfficerDesignationSnapshot, contains('Field'));
        expect(updated.isFieldOfficerAssigned, isTrue);
      });

      test('Scenario 7: Complaint status remains assigned after FO assignment', () async {
        final initial = createBaseComplaint(status: ComplaintStatus.assigned);
        final updated = await routingService.assignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          fieldOfficerId: foId,
        );

        expect(updated.status, equals(ComplaintStatus.assigned));
      });

      test('Scenario 8: Complaint assignmentStatus becomes fieldOfficerAssigned', () async {
        final initial = createBaseComplaint();
        final updated = await routingService.assignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          fieldOfficerId: foId,
        );

        expect(updated.assignmentStatus, equals(ComplaintAssignmentStatus.fieldOfficerAssigned));
      });

      test('Scenario 9: assignedFieldOfficerId, assignedFieldOfficerAt, snapshot names set correctly', () async {
        final initial = createBaseComplaint();
        final updated = await routingService.assignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          fieldOfficerId: fo3Id,
        );

        expect(updated.assignedFieldOfficerId, equals(fo3Id));
        expect(updated.assignedFieldOfficerName, isNotEmpty);
        expect(updated.assignedFieldOfficerDesignation, contains('Field'));
      });

      test('Scenario 10: assignedJuniorEngineerId remains intact and unchanged', () async {
        final initial = createBaseComplaint(assignedCrewMemberId: jeId);
        final updated = await routingService.assignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          fieldOfficerId: foId,
        );

        expect(updated.assignedJuniorEngineerId, equals(jeId));
        expect(updated.assignedCrewMemberId, equals(jeId));
      });

      test('Scenario 11: Audit log field_officer_assigned recorded with metadata', () async {
        final initial = createBaseComplaint();
        await routingService.assignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          fieldOfficerId: foId,
        );

        final logs = await auditService.getLogsForComplaint(initial.id);
        final foLog = logs.firstWhere(
          (l) => l.action == GovernmentAuditActions.fieldOfficerAssigned,
        );

        expect(foLog.actorId, equals(jeId));
        expect(foLog.details['assignedFieldOfficerId'], equals(foId));
        expect(foLog.details['assignedJuniorEngineerId'], equals(jeId));
      });

      test('Scenario 12: Attempting to assign JE to themselves throws ArgumentError', () async {
        final initial = createBaseComplaint(assignedCrewMemberId: jeId);

        expect(
          () => routingService.assignFieldOfficer(
            complaintId: initial.id,
            juniorEngineerId: jeId,
            fieldOfficerId: jeId, // Same as JE!
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Scenario 13: Attempting to assign FO from different ward throws ArgumentError', () async {
        final initial = createBaseComplaint(wardId: 'G_NORTH');

        expect(
          () => routingService.assignFieldOfficer(
            complaintId: initial.id,
            juniorEngineerId: jeId,
            fieldOfficerId: 'GOV-CREW-A-maintenance_roads-01', // Ward A instead of G_NORTH
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Scenario 14: Attempting to assign FO from different department throws ArgumentError', () async {
        final initial = createBaseComplaint(wardId: 'G_NORTH', departmentId: 'maintenance_roads');

        expect(
          () => routingService.assignFieldOfficer(
            complaintId: initial.id,
            juniorEngineerId: jeId,
            fieldOfficerId: 'GOV-CREW-G_NORTH-water_works-01', // water_works instead of maintenance_roads
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Scenario 15: Attempting to assign FO when caller is not JE/authorized throws StateError', () async {
        final initial = createBaseComplaint(assignedCrewMemberId: jeId);

        expect(
          () => routingService.assignFieldOfficer(
            complaintId: initial.id,
            juniorEngineerId: fo5Id, // Unauthorized crew member
            fieldOfficerId: foId,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    // =========================================================================
    // PART 3: FIELD OFFICER DESK & MY JOBS FILTERING
    // =========================================================================
    group('3. Field Officer Workdesk Queue & Filtering', () {
      test('Scenario 16: FO logs in and sees complaint in My Jobs queue', () async {
        final complaint = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
        );
        mockRepo.complaints = [complaint];

        final workdesk = await crewWorkService.loadCrewWorkdesk(
          crewId: foId,
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        expect(workdesk.allMyJobs.length, equals(1));
        expect(workdesk.allMyJobs.first.id, equals(complaint.id));
      });

      test('Scenario 17: Other crew members do NOT see complaint in My Jobs queue', () async {
        final complaint = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
        );
        mockRepo.complaints = [complaint];

        final workdesk = await crewWorkService.loadCrewWorkdesk(
          crewId: fo4Id,
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        expect(workdesk.allMyJobs, isEmpty);
      });
    });

    // =========================================================================
    // PART 4: GROUND EXECUTION — START WORK, PHOTOS, BLOCKAGES
    // =========================================================================
    group('4. Ground Execution: Work Start, Blockages, & SLA Preservation', () {
      test('Scenario 18: FO initiates work -> status transitions to inProgress', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
        );
        routingService.registerComplaint(initial);

        final started = await routingService.startFieldWork(
          complaintId: initial.id,
          fieldOfficerId: foId,
        );

        expect(started.status, equals(ComplaintStatus.inProgress));
        expect(started.routingStatus, equals(ComplaintRoutingStatus.inProgress));
      });

      test('Scenario 19: workStartedAt and workStartedBy recorded accurately', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
        );
        routingService.registerComplaint(initial);

        final started = await routingService.startFieldWork(
          complaintId: initial.id,
          fieldOfficerId: foId,
        );

        expect(started.workStartedAt, isNotNull);
        expect(started.workStartedBy, equals(foId));
        expect(started.fieldExecutionStartedAt, equals(started.workStartedAt));
      });

      test('Scenario 20: SLA clock (slaStartedAt) is NOT reset when starting work', () async {
        final originalSlaTime = DateTime.now().subtract(const Duration(hours: 3));
        final initial = createBaseComplaint(
          slaStartedAt: originalSlaTime,
          originalCreatedAt: originalSlaTime,
        ).copyWith(
          assignedFieldOfficerId: foId,
        );
        routingService.registerComplaint(initial);

        final started = await routingService.startFieldWork(
          complaintId: initial.id,
          fieldOfficerId: foId,
        );

        expect(started.slaStartedAt, equals(originalSlaTime));
        expect(started.originalCreatedAt, equals(originalSlaTime));
      });

      test('Scenario 21: Audit log field_work_started recorded', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
        );
        routingService.registerComplaint(initial);

        await routingService.startFieldWork(
          complaintId: initial.id,
          fieldOfficerId: foId,
        );

        final logs = await auditService.getLogsForComplaint(initial.id);
        expect(
          logs.any((l) => l.action == GovernmentAuditActions.fieldWorkStarted),
          isTrue,
        );
      });

      test('Scenario 22: Non-assigned crew member attempting to start work throws StateError', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
        );
        routingService.registerComplaint(initial);

        expect(
          () => routingService.startFieldWork(
            complaintId: initial.id,
            fieldOfficerId: fo3Id, // Wrong FO
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('Scenario 23: FO records optional before-work photo and notes', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
        );
        routingService.registerComplaint(initial);

        final started = await routingService.startFieldWork(
          complaintId: initial.id,
          fieldOfficerId: foId,
          beforePhotoUrl: 'https://storage.civicfix.gov.in/evidence/before_001.jpg',
          beforeNotes: 'Asphalt milling machine stationed at Dadar junction',
        );

        expect(started.beforeWorkPhoto, equals('https://storage.civicfix.gov.in/evidence/before_001.jpg'));
        expect(started.beforeWorkNotes, contains('Asphalt milling'));
      });

      test('Scenario 24: FO marks work blocked with mandatory reason', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
        );
        routingService.registerComplaint(inProgress);

        final blocked = await routingService.markFieldWorkBlocked(
          complaintId: inProgress.id,
          fieldOfficerId: foId,
          reason: 'Heavy monsoon downpour prevents hot-mix asphalt curing',
        );

        expect(blocked.blockedAt, isNotNull);
        expect(blocked.blockedBy, equals(foId));
        expect(blocked.blockedReason, contains('Heavy monsoon'));
        expect(blocked.isBlocked, isTrue);
      });

      test('Scenario 25: Blocked complaint shows blocked status / badge', () async {
        final blockedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.inProgress,
          blockedAt: DateTime.now(),
          blockedReason: 'Underground gas utility line detected',
        );

        expect(blockedComplaint.isBlocked, isTrue);
      });

      test('Scenario 26: Audit log field_work_blocked recorded', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
        );
        routingService.registerComplaint(inProgress);

        await routingService.markFieldWorkBlocked(
          complaintId: inProgress.id,
          fieldOfficerId: foId,
          reason: 'Access blocked by unauthorized parked heavy trailers',
        );

        final logs = await auditService.getLogsForComplaint(inProgress.id);
        expect(
          logs.any((l) => l.action == GovernmentAuditActions.fieldWorkBlocked),
          isTrue,
        );
      });

      test('Scenario 27: FO resumes blocked work -> blockage cleared', () async {
        final blockedComplaint = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          blockedAt: DateTime.now(),
          blockedBy: foId,
          blockedReason: 'Rain delay',
        );
        routingService.registerComplaint(blockedComplaint);

        final resumed = await routingService.resumeFieldWork(
          complaintId: blockedComplaint.id,
          fieldOfficerId: foId,
        );

        expect(resumed.blockedAt, isNull);
        expect(resumed.blockedBy, isNull);
        expect(resumed.blockedReason, isNull);
        expect(resumed.isBlocked, isFalse);
        expect(resumed.status, equals(ComplaintStatus.inProgress));
      });

      test('Scenario 28: Audit log field_work_resumed recorded', () async {
        final blockedComplaint = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          blockedAt: DateTime.now(),
          blockedReason: 'Rain delay',
        );
        routingService.registerComplaint(blockedComplaint);

        await routingService.resumeFieldWork(
          complaintId: blockedComplaint.id,
          fieldOfficerId: foId,
        );

        final logs = await auditService.getLogsForComplaint(blockedComplaint.id);
        expect(
          logs.any((l) => l.action == GovernmentAuditActions.fieldWorkResumed),
          isTrue,
        );
      });
    });

    // =========================================================================
    // PART 5: DIRECT RESOLUTION & VALIDATION RULES
    // =========================================================================
    group('5. Direct Resolution & Strict Evidence Validation', () {
      test('Scenario 29: FO submits resolution with After Photo & remarks -> status transitions to resolved', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          workStartedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        );
        routingService.registerComplaint(inProgress);

        final resolved = await routingService.resolveByFieldOfficer(
          complaintId: inProgress.id,
          fieldOfficerId: foId,
          afterPhotoUrl: 'https://storage.civicfix.gov.in/evidence/resolved_after_001.jpg',
          resolutionRemarks: 'Mastic asphalt patch laid, compacted, and traffic reopened.',
        );

        expect(resolved.status, equals(ComplaintStatus.resolved));
        expect(resolved.routingStatus, equals(ComplaintRoutingStatus.resolved));
      });

      test('Scenario 30: resolvedAt, resolvedBy, afterWorkPhoto, resolutionRemarks recorded accurately', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          workStartedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        );
        routingService.registerComplaint(inProgress);

        final resolved = await routingService.resolveByFieldOfficer(
          complaintId: inProgress.id,
          fieldOfficerId: foId,
          afterPhotoUrl: 'https://storage.civicfix.gov.in/evidence/after_pothole.jpg',
          resolutionRemarks: 'Pothole filled with cold mix, roller compaction completed.',
        );

        expect(resolved.resolvedAt, isNotNull);
        expect(resolved.resolvedBy, equals(foId));
        expect(resolved.resolvedByFieldOfficerId, equals(foId));
        expect(resolved.afterWorkPhoto, equals('https://storage.civicfix.gov.in/evidence/after_pothole.jpg'));
        expect(resolved.resolutionRemarks, contains('Pothole filled'));
        expect(resolved.imageUrls, contains('https://storage.civicfix.gov.in/evidence/after_pothole.jpg'));
      });

      test('Scenario 31: Audit log complaint_resolved recorded', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          workStartedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        );
        routingService.registerComplaint(inProgress);

        await routingService.resolveByFieldOfficer(
          complaintId: inProgress.id,
          fieldOfficerId: foId,
          afterPhotoUrl: 'https://storage.civicfix.gov.in/evidence/after_pothole.jpg',
          resolutionRemarks: 'Pothole filled and sealed.',
        );

        final logs = await auditService.getLogsForComplaint(inProgress.id);
        expect(
          logs.any((l) => l.action == GovernmentAuditActions.complaintResolved),
          isTrue,
        );
      });

      test('Scenario 32: Complaint resolved directly without mandatory Lead approval gate', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          workStartedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        routingService.registerComplaint(inProgress);

        final resolved = await routingService.resolveByFieldOfficer(
          complaintId: inProgress.id,
          fieldOfficerId: foId,
          afterPhotoUrl: 'https://storage.civicfix.gov.in/evidence/fixed.jpg',
          resolutionRemarks: 'Work completed on ground.',
        );

        // Does NOT transition to "under_review" or "pending_lead_approval"
        expect(resolved.status, equals(ComplaintStatus.resolved));
      });

      test('Scenario 33: Attempting resolution without afterWorkPhoto fails with ArgumentError', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
        );
        routingService.registerComplaint(inProgress);

        expect(
          () => routingService.resolveByFieldOfficer(
            complaintId: inProgress.id,
            fieldOfficerId: foId,
            afterPhotoUrl: '', // Empty photo!
            resolutionRemarks: 'Completed',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Scenario 34: Attempting resolution without remarks fails with ArgumentError', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
        );
        routingService.registerComplaint(inProgress);

        expect(
          () => routingService.resolveByFieldOfficer(
            complaintId: inProgress.id,
            fieldOfficerId: foId,
            afterPhotoUrl: 'https://storage.civicfix.gov.in/photo.jpg',
            resolutionRemarks: '   ', // Whitespace only!
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Scenario 35: Attempting resolution before starting work (status == assigned) fails', () async {
        final notStarted = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.assigned, // Not inProgress!
        );
        routingService.registerComplaint(notStarted);

        expect(
          () => routingService.resolveByFieldOfficer(
            complaintId: notStarted.id,
            fieldOfficerId: foId,
            afterPhotoUrl: 'https://storage.civicfix.gov.in/photo.jpg',
            resolutionRemarks: 'Done',
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('Scenario 36: Non-assigned crew member attempting resolution throws StateError', () async {
        final inProgress = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          workStartedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        routingService.registerComplaint(inProgress);

        expect(
          () => routingService.resolveByFieldOfficer(
            complaintId: inProgress.id,
            fieldOfficerId: fo4Id, // Wrong FO
            afterPhotoUrl: 'https://storage.civicfix.gov.in/photo.jpg',
            resolutionRemarks: 'Done',
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('Scenario 37: SLA started time unchanged upon resolution', () async {
        final originalSlaTime = DateTime.now().subtract(const Duration(hours: 4));
        final inProgress = createBaseComplaint(
          slaStartedAt: originalSlaTime,
          originalCreatedAt: originalSlaTime,
        ).copyWith(
          assignedFieldOfficerId: foId,
          status: ComplaintStatus.inProgress,
          workStartedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        routingService.registerComplaint(inProgress);

        final resolved = await routingService.resolveByFieldOfficer(
          complaintId: inProgress.id,
          fieldOfficerId: foId,
          afterPhotoUrl: 'https://storage.civicfix.gov.in/photo.jpg',
          resolutionRemarks: 'Fixed correctly.',
        );

        expect(resolved.slaStartedAt, equals(originalSlaTime));
        expect(resolved.originalCreatedAt, equals(originalSlaTime));
      });
    });

    // =========================================================================
    // PART 6: FIELD OFFICER REASSIGNMENT & WRONG-DEPT TRANSFERS
    // =========================================================================
    group('6. Reassignment & Transfer Cleanup', () {
      test('Scenario 38: JE reassigns complaint to another FO before work starts', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          assignedFieldOfficerAt: DateTime.now().subtract(const Duration(hours: 1)),
          assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
        );
        routingService.registerComplaint(initial);

        final reassigned = await routingService.reassignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          newFieldOfficerId: fo3Id,
          reason: 'Officer reassigned to emergency sinkhole',
        );

        expect(reassigned.assignedFieldOfficerId, equals(fo3Id));
        expect(reassigned.reassignmentCount, equals(1));
        expect(reassigned.lastReassignedAt, isNotNull);
      });

      test('Scenario 39: Reassignment increments reassignmentCount and updates audit log', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          reassignmentCount: 1,
        );
        routingService.registerComplaint(initial);

        final reassigned = await routingService.reassignFieldOfficer(
          complaintId: initial.id,
          juniorEngineerId: jeId,
          newFieldOfficerId: fo4Id,
          reason: 'Load rebalancing',
        );

        expect(reassigned.reassignmentCount, equals(2));

        final logs = await auditService.getLogsForComplaint(initial.id);
        expect(
          logs.any((l) => l.action == GovernmentAuditActions.fieldOfficerReassigned),
          isTrue,
        );
      });

      test('Scenario 40: Wrong department transfer cleans up assignedFieldOfficerId', () async {
        final initial = createBaseComplaint().copyWith(
          assignedFieldOfficerId: foId,
          assignedFieldOfficerNameSnapshot: 'Sanjay Shinde',
          assignedFieldOfficerDesignationSnapshot: 'Field Officer',
        );
        routingService.registerComplaint(initial);

        final transferred = await routingService.transferWrongDepartmentDirect(
          complaintId: initial.id,
          requestedBy: leadId,
          newDepartmentId: 'water_works',
          reason: 'Burst water pipeline under road requires water department excavation',
        );

        expect(transferred.assignedDepartmentId, equals('water_works'));
        expect(transferred.assignedFieldOfficerId, isNull);
        expect(transferred.assignedFieldOfficerNameSnapshot, isNull);
        expect(transferred.assignedFieldOfficerDesignationSnapshot, isNull);
        expect(transferred.isFieldOfficerAssigned, isFalse);
      });
    });

    // =========================================================================
    // PART 7: WARD DEPARTMENT LEAD QUALITY REVIEW & REOPEN DISPATCH
    // =========================================================================
    group('7. Ward Department Lead Quality Oversight & Complaint Reopening', () {
      test('Scenario 41: Ward Department Lead can reopen resolved complaint with mandatory reason', () async {
        final resolvedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.resolved,
          routingStatus: ComplaintRoutingStatus.resolved,
          assignedFieldOfficerId: foId,
          afterWorkPhoto: 'https://storage.civicfix.gov.in/photo1.jpg',
          resolutionRemarks: 'Done',
          resolvedAt: DateTime.now().subtract(const Duration(hours: 1)),
          resolvedBy: foId,
        );
        routingService.registerComplaint(resolvedComplaint);

        final reopened = await routingService.reopenComplaint(
          complaintId: resolvedComplaint.id,
          reopenedBy: leadId,
          reopenReason: 'After photo shows incomplete leveling and loose gravel hazards remaining on footpath.',
        );

        expect(reopened.status, equals(ComplaintStatus.inProgress));
        expect(reopened.reopenReason, contains('loose gravel hazards'));
      });

      test('Scenario 42: Reopened complaint status transitions back to inProgress', () async {
        final resolvedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.resolved,
          assignedFieldOfficerId: foId,
          afterWorkPhoto: 'https://storage.civicfix.gov.in/photo1.jpg',
          resolutionRemarks: 'Done',
        );
        routingService.registerComplaint(resolvedComplaint);

        final reopened = await routingService.reopenComplaint(
          complaintId: resolvedComplaint.id,
          reopenedBy: leadId,
          reopenReason: 'Quality review rejected',
        );

        expect(reopened.status, equals(ComplaintStatus.inProgress));
        expect(reopened.routingStatus, equals(ComplaintRoutingStatus.inProgress));
      });

      test('Scenario 43: reopenedAt, reopenedBy, reopenReason populated accurately', () async {
        final resolvedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.resolved,
          assignedFieldOfficerId: foId,
          afterWorkPhoto: 'https://storage.civicfix.gov.in/photo1.jpg',
          resolutionRemarks: 'Done',
        );
        routingService.registerComplaint(resolvedComplaint);

        final reopened = await routingService.reopenComplaint(
          complaintId: resolvedComplaint.id,
          reopenedBy: leadId,
          reopenReason: 'Quality review failed: inadequate bitumen grade.',
        );

        expect(reopened.reopenedAt, isNotNull);
        expect(reopened.reopenedBy, equals(leadId));
        expect(reopened.reopenReason, equals('Quality review failed: inadequate bitumen grade.'));
      });

      test('Scenario 44: Previous resolution photo & remarks archived in previousResolutionEvidence', () async {
        final resolvedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.resolved,
          assignedFieldOfficerId: foId,
          afterWorkPhoto: 'https://storage.civicfix.gov.in/photo_v1.jpg',
          resolutionRemarks: 'Quick patch applied.',
        );
        routingService.registerComplaint(resolvedComplaint);

        final reopened = await routingService.reopenComplaint(
          complaintId: resolvedComplaint.id,
          reopenedBy: leadId,
          reopenReason: 'Requires hot-mix compaction.',
        );

        expect(reopened.previousResolutionEvidence, isNotEmpty);
        expect(
          reopened.previousResolutionEvidence.any((e) => e.contains('photo_v1.jpg')),
          isTrue,
        );
      });

      test('Scenario 45: reopenCount incremented', () async {
        final resolvedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.resolved,
          reopenCount: 0,
          assignedFieldOfficerId: foId,
          afterWorkPhoto: 'https://storage.civicfix.gov.in/photo1.jpg',
          resolutionRemarks: 'Done',
        );
        routingService.registerComplaint(resolvedComplaint);

        final reopened = await routingService.reopenComplaint(
          complaintId: resolvedComplaint.id,
          reopenedBy: leadId,
          reopenReason: 'Inadequate repair',
        );

        expect(reopened.reopenCount, equals(1));
      });

      test('Scenario 46: Audit log complaint_reopened recorded', () async {
        final resolvedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.resolved,
          assignedFieldOfficerId: foId,
          afterWorkPhoto: 'https://storage.civicfix.gov.in/photo1.jpg',
          resolutionRemarks: 'Done',
        );
        routingService.registerComplaint(resolvedComplaint);

        await routingService.reopenComplaint(
          complaintId: resolvedComplaint.id,
          reopenedBy: leadId,
          reopenReason: 'Audit review rejection',
        );

        final logs = await auditService.getLogsForComplaint(resolvedComplaint.id);
        expect(
          logs.any((l) => l.action == GovernmentAuditActions.complaintReopened),
          isTrue,
        );
      });

      test('Scenario 47: Reopened complaint reappears in JE / FO execution queue with reopen badge', () async {
        final reopenedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.inProgress,
          assignedFieldOfficerId: foId,
          reopenedAt: DateTime.now(),
          reopenReason: 'Unfinished work',
          reopenCount: 1,
        );

        expect(reopenedComplaint.isReopened, isTrue);

        mockRepo.complaints = [reopenedComplaint];

        final workdesk = await crewWorkService.loadCrewWorkdesk(
          crewId: foId,
          wardId: 'G_NORTH',
          departmentId: 'maintenance_roads',
        );

        expect(workdesk.allMyJobs.first.complaint.isReopened, isTrue);
      });

      test('Scenario 48: FO completes second resolution cycle with new after-work photo and remarks', () async {
        final reopenedComplaint = createBaseComplaint().copyWith(
          status: ComplaintStatus.inProgress,
          assignedFieldOfficerId: foId,
          reopenedAt: DateTime.now(),
          reopenReason: 'Loose gravel must be cleared and edges sealed',
          previousResolutionEvidence: [
            'https://storage.civicfix.gov.in/v1.jpg',
          ],
          reopenCount: 1,
          workStartedAt: DateTime.now(),
        );
        routingService.registerComplaint(reopenedComplaint);

        final finalResolved = await routingService.resolveByFieldOfficer(
          complaintId: reopenedComplaint.id,
          fieldOfficerId: foId,
          afterPhotoUrl: 'https://storage.civicfix.gov.in/v2_final_smooth.jpg',
          resolutionRemarks: 'Loose gravel removed, emulsion tack coat applied, seamless flush joint achieved.',
        );

        expect(finalResolved.status, equals(ComplaintStatus.resolved));
        expect(finalResolved.afterWorkPhoto, equals('https://storage.civicfix.gov.in/v2_final_smooth.jpg'));
        expect(finalResolved.resolutionRemarks, contains('seamless flush joint'));
        expect(finalResolved.reopenCount, equals(1));
        expect(finalResolved.previousResolutionEvidence.length, equals(1));
      });
    });
  });
}
