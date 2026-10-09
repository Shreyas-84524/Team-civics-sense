import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/local/models/complaint_local_model.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Verification Resilience & Human Fallback Tests', () {
    late LocalGovernmentHierarchyRepository hierarchyRepo;
    late ComplaintRoutingService routingService;

    setUp(() async {
      hierarchyRepo = LocalGovernmentHierarchyRepository();
      await hierarchyRepo.initialize();
      routingService = ComplaintRoutingService(hierarchyRepo: hierarchyRepo);
    });

    ComplaintModel createPendingFallbackComplaint({
      String id = 'CMP-AI-001',
      String ticketNumber = 'TICK-AI-001',
      String categoryId = 'potholes',
      String wardId = 'G_NORTH',
      String initialDeptId = 'maintenance_roads',
      DateTime? slaStartedAt,
    }) {
      final now = DateTime.now();
      final effectiveSla = slaStartedAt ?? now.subtract(const Duration(hours: 2));

      return ComplaintModel(
        id: id,
        citizenId: 'CITIZEN-001',
        ticketNumber: ticketNumber,
        title: 'Deep crater on main road',
        description: 'Pothole causing vehicle damage near junction',
        category: CivicCategory(
          id: categoryId,
          name: 'Potholes & Road Damage',
          description: 'Road damage and potholes',
          icon: Icons.alt_route,
        ),
        status: ComplaintStatus.underVerification,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 19.0435,
          longitude: 72.8465,
          address: 'Dharavi Main Road, Sion',
          ward: 'G/North',
        ),
        createdAt: effectiveSla,
        updatedAt: now,
        slaStartedAt: effectiveSla,
        originalCreatedAt: effectiveSla,
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'pending',
        verificationStage: 'humanDepartmentReview',
        aiVerificationAttempts: 3,
        lastAiFailureCode: 'GEMINI_503_UNAVAILABLE',
        aiFallbackTriggeredAt: now,
        initialReviewDepartmentId: initialDeptId,
        initialReviewDepartmentName: 'Roads and Traffic Department',
        humanReviewStatus: 'pending',
        wardId: wardId,
        assignedDepartmentId: initialDeptId,
        routingStatus: ComplaintRoutingStatus.unassigned,
        assignmentStatus: ComplaintAssignmentStatus.unassigned,
      );
    }

    test('ComplaintModel getters correctly reflect fallback states', () {
      final pendingComplaint = createPendingFallbackComplaint();
      expect(pendingComplaint.isHumanReviewPending, isTrue);
      expect(pendingComplaint.isHumanReviewCompleted, isFalse);

      final completedComplaint = pendingComplaint.copyWith(
        humanReviewStatus: 'approved',
        verificationStage: 'completed',
        departmentVerificationStatus: 'passed',
      );
      expect(completedComplaint.isHumanReviewPending, isFalse);
      expect(completedComplaint.isHumanReviewCompleted, isTrue);
    });

    test('ComplaintLocalModel roundtrip preserves all AI fallback & review fields', () {
      final domain = createPendingFallbackComplaint();
      final local = ComplaintLocalModel.fromDomain(domain);

      expect(local.aiVerificationAttempts, equals(3));
      expect(local.lastAiFailureCode, equals('GEMINI_503_UNAVAILABLE'));
      expect(local.humanReviewStatus, equals('pending'));
      expect(local.initialReviewDepartmentId, equals('maintenance_roads'));
      expect(local.verificationStage, equals('humanDepartmentReview'));

      final restoredDomain = local.toDomain();
      expect(restoredDomain.aiVerificationAttempts, equals(3));
      expect(restoredDomain.lastAiFailureCode, equals('GEMINI_503_UNAVAILABLE'));
      expect(restoredDomain.humanReviewStatus, equals('pending'));
      expect(restoredDomain.initialReviewDepartmentId, equals('maintenance_roads'));
      expect(restoredDomain.isHumanReviewPending, isTrue);
      expect(restoredDomain.slaStartedAt.millisecondsSinceEpoch, equals(domain.slaStartedAt.millisecondsSinceEpoch));
    });

    test('Scenario A: Department Lead confirms grievance belongs to current department', () async {
      final initialComplaint = createPendingFallbackComplaint();
      routingService.registerComplaint(initialComplaint);

      final lead = await hierarchyRepo.getUserByEmployeeId('LEAD-GN-ROADS') ??
          const GovtUserModel(
            id: 'LEAD-GN-ROADS',
            employeeId: 'LEAD-GN-ROADS',
            fullName: 'Rajesh Sharma',
            email: 'rajesh.sharma@mcgm.gov.in',
            phone: '+919876543210',
            role: 'ward_department_lead',
            wardId: 'G_NORTH',
            departmentId: 'maintenance_roads',
            active: true,
          );

      final routed = await routingService.confirmHumanDepartmentReview(
        complaintId: initialComplaint.id,
        leadId: lead.employeeId,
        remarks: 'Confirmed road pothole under MCGM jurisdiction.',
      );

      // Verify status transitions
      expect(routed.status, equals(ComplaintStatus.assigned));
      expect(routed.humanReviewStatus, equals('approved'));
      expect(routed.departmentVerificationStatus, equals('passed'));
      expect(routed.verificationStage, equals('completed'));
      expect(routed.verifiedDepartmentId, equals('maintenance_roads'));
      expect(routed.humanReviewerId, equals(lead.employeeId));

      // Verify least loaded JE is assigned
      expect(routed.assignedCrewMemberId, isNotNull);
      expect(routed.assignedJuniorEngineerNameSnapshot, isNotNull);

      // Verify SLA clock is immutable
      expect(routed.slaStartedAt, equals(initialComplaint.slaStartedAt));
      expect(routed.originalCreatedAt, equals(initialComplaint.originalCreatedAt));

      // Verify timeline contains manual review confirmation entry
      expect(
        routed.timeline.any((t) => t.title.contains('Department Verified (Manual Review)')),
        isTrue,
      );
    });

    test('Scenario B: Department Lead transfers grievance to another BMC department', () async {
      final initialComplaint = createPendingFallbackComplaint(
        id: 'CMP-SW-002',
        ticketNumber: 'TICK-SW-002',
        categoryId: 'garbage',
        initialDeptId: 'maintenance_roads', // mistakenly arrived at roads
      );
      routingService.registerComplaint(initialComplaint);

      final lead = await hierarchyRepo.getUserByEmployeeId('LEAD-GN-ROADS') ??
          const GovtUserModel(
            id: 'LEAD-GN-ROADS',
            employeeId: 'LEAD-GN-ROADS',
            fullName: 'Rajesh Sharma',
            email: 'rajesh.sharma@mcgm.gov.in',
            phone: '+919876543210',
            role: 'ward_department_lead',
            wardId: 'G_NORTH',
            departmentId: 'maintenance_roads',
            active: true,
          );

      final transferred = await routingService.transferHumanDepartmentReview(
        complaintId: initialComplaint.id,
        leadId: lead.employeeId,
        targetDepartmentId: 'solid_waste_management',
        remarks: 'Waste pile accumulating on curb, requires SWM cleanup squad.',
      );

      // Verify department changed
      expect(transferred.assignedDepartmentId, equals('solid_waste_management'));
      expect(transferred.verifiedDepartmentId, equals('solid_waste_management'));
      expect(transferred.previousDepartmentId, equals('maintenance_roads'));
      expect(transferred.humanReviewStatus, equals('transferred'));
      expect(transferred.departmentVerificationStatus, equals('passed'));
      expect(transferred.verificationStage, equals('completed'));
      expect(transferred.reassignmentCount, equals(1));

      // Verify auto-routed to SWM Junior Engineer
      expect(transferred.assignedCrewMemberId, isNotNull);

      // Verify SLA clock is strictly preserved
      expect(transferred.slaStartedAt, equals(initialComplaint.slaStartedAt));
      expect(transferred.originalCreatedAt, equals(initialComplaint.originalCreatedAt));

      // Verify timeline contains transfer event
      expect(
        transferred.timeline.any((t) => t.title.contains('Department Transferred (Manual Review)')),
        isTrue,
      );
    });

    test('Scenario C: Idempotency prevents double processing of finalized review', () async {
      final initialComplaint = createPendingFallbackComplaint();
      routingService.registerComplaint(initialComplaint);

      final firstPass = await routingService.confirmHumanDepartmentReview(
        complaintId: initialComplaint.id,
        leadId: 'LEAD-GN-ROADS',
        remarks: 'First review confirmation.',
      );

      final assignedJE = firstPass.assignedCrewMemberId;
      expect(assignedJE, isNotNull);

      // Second attempt should return the already finalized complaint without modification
      final secondPass = await routingService.confirmHumanDepartmentReview(
        complaintId: initialComplaint.id,
        leadId: 'LEAD-GN-ROADS',
        remarks: 'Duplicate attempt.',
      );

      expect(secondPass.assignedCrewMemberId, equals(assignedJE));
      expect(secondPass.humanReviewStatus, equals('approved'));
      expect(secondPass.timeline.length, equals(firstPass.timeline.length));
    });
  });
}
