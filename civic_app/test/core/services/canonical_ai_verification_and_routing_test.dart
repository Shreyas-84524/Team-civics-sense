import 'package:flutter/material.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Canonical 7-Stage Complaint Verification & Routing Tests', () {
    late LocalGovernmentHierarchyRepository hierarchyRepo;
    late ComplaintRoutingService routingService;

    setUp(() async {
      hierarchyRepo = LocalGovernmentHierarchyRepository();
      await hierarchyRepo.initialize();
      routingService = ComplaintRoutingService(hierarchyRepo: hierarchyRepo);
    });

    test('ComplaintStatus contains canonical underVerification and closed states', () {
      expect(ComplaintStatus.underVerification.name, 'underVerification');
      expect(ComplaintStatus.underVerification.label, 'Under Verification');
      expect(ComplaintStatus.closed.name, 'closed');
      expect(ComplaintStatus.closed.label, 'Closed');
    });

    test('ComplaintModel helper getters reflect verification lifecycle', () {
      final unverified = ComplaintModel(
        id: 'C-001',
        ticketNumber: 'CF-000001',
        title: 'Pothole on Linking Road',
        description: 'Deep road depression near junction',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.058,
          longitude: 72.833,
          address: 'Linking Road, Bandra West',
          ward: 'H_WEST',
        ),
        priority: ComplaintPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ComplaintStatus.underVerification,
        evidenceVerificationStatus: 'pending',
        departmentVerificationStatus: 'pending',
      );

      expect(unverified.isUnderVerification, isTrue);
      expect(unverified.isAiVerificationComplete, isFalse);
      expect(unverified.isClosed, isFalse);

      final verified = unverified.copyWith(
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'passed',
        verifiedDepartmentId: 'maintenance_roads',
        verifiedDepartmentName: 'Roads & Maintenance',
      );

      expect(verified.isUnderVerification, isTrue);
      expect(verified.isAiVerificationComplete, isTrue);
    });

    test('Gate 1 & Gate 2: autoRouteVerifiedComplaint rejects unverified complaints', () async {
      final unverified = ComplaintModel(
        id: 'C-GATE-1',
        ticketNumber: 'CF-000002',
        title: 'Garbage dump',
        description: 'Piles of solid waste',
        category: CivicCategory.defaultCategories[3],
        location: const CivicLocation(
          latitude: 19.041,
          longitude: 72.843,
          address: 'Dharavi Main Road',
          ward: 'G_NORTH',
        ),
        priority: ComplaintPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ComplaintStatus.underVerification,
        evidenceVerificationStatus: 'pending',
        departmentVerificationStatus: 'pending',
      );

      // Gate 1 Failure
      expect(
        () => routingService.autoRouteVerifiedComplaint(unverified),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Gate 1 Failed'))),
      );

      // Gate 2 Failure
      final evidencePassedOnly = unverified.copyWith(
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'pending',
      );
      expect(
        () => routingService.autoRouteVerifiedComplaint(evidencePassedOnly),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Gate 2 Failed'))),
      );
    });

    test('Gate 3: autoRouteVerifiedComplaint rejects hallucinated / invalid departments', () async {
      final hallucinatedDeptComplaint = ComplaintModel(
        id: 'C-GATE-3',
        ticketNumber: 'CF-000003',
        title: 'Traffic Signal defect',
        description: 'Signal timing error',
        category: const CivicCategory(
          id: 'traffic_police_custom_hallucination',
          name: 'Traffic Police Custom Hallucination',
          description: 'Non-BMC entity',
          icon: Icons.traffic_outlined,
        ),
        location: const CivicLocation(
          latitude: 19.041,
          longitude: 72.843,
          address: 'Dharavi, Mumbai',
          ward: 'G_NORTH',
        ),
        priority: ComplaintPriority.high,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ComplaintStatus.underVerification,
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'passed',
        verifiedDepartmentId: 'traffic_police_custom_hallucination',
      );

      expect(
        () => routingService.autoRouteVerifiedComplaint(hallucinatedDeptComplaint),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Gate 3 Failed'))),
      );
    });

    test('Gate 4: autoRouteVerifiedComplaint rejects coordinates outside Mumbai boundary (no silent fallback)', () async {
      final outsideMumbaiComplaint = ComplaintModel(
        id: 'C-GATE-4',
        ticketNumber: 'CF-000004',
        title: 'Road repair in Delhi',
        description: 'Location coordinates in Delhi',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 28.6139, // Delhi
          longitude: 77.2090,
          address: 'Connaught Place, New Delhi',
        ),
        priority: ComplaintPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ComplaintStatus.underVerification,
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'passed',
        verifiedDepartmentId: 'maintenance_roads',
      );

      expect(
        () => routingService.autoRouteVerifiedComplaint(outsideMumbaiComplaint),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Cannot resolve BMC Ward'))),
      );
    });

    test('Gate 5 & Full Pipeline: Successfully auto-routes verified complaint to least-loaded Junior Engineer', () async {
      final verifiedComplaint = ComplaintModel(
        id: 'C-GATE-PASS',
        ticketNumber: 'CF-000005',
        title: 'Pothole on SV Road Bandra',
        description: 'Large road hazard near Bandra station',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.058, // H/West (Bandra)
          longitude: 72.833,
          address: 'SV Road, Bandra West, Mumbai',
          ward: 'H_WEST',
        ),
        priority: ComplaintPriority.high,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: ComplaintStatus.underVerification,
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'passed',
        verifiedDepartmentId: 'maintenance_roads',
        verifiedDepartmentName: 'Roads & Maintenance',
      );

      final routed = await routingService.autoRouteVerifiedComplaint(verifiedComplaint);

      expect(routed.status, ComplaintStatus.assigned);
      expect(routed.assignmentStatus, ComplaintAssignmentStatus.crewAssigned);
      expect(routed.wardId, 'H_WEST');
      expect(routed.assignedDepartmentId, 'maintenance_roads');
      expect(routed.assignedCrewMemberId, isNotNull);
      expect(routed.assignedTo, isNotNull);
      expect(routed.assignedJuniorEngineerNameSnapshot, isNotNull);
      expect(routed.assignedJuniorEngineerDesignationSnapshot, isNotNull);
      expect(routed.slaStartedAt, verifiedComplaint.slaStartedAt);
    });

    test('Stage 7: closeComplaint transitions resolved complaint to closed with audit tracking', () async {
      final resolvedComplaint = ComplaintModel(
        id: 'C-STAGE-7',
        ticketNumber: 'CF-000007',
        title: 'Cleared drain',
        description: 'Storm drain cleared',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.041,
          longitude: 72.843,
          address: 'Dadar, Mumbai',
          ward: 'G_NORTH',
        ),
        priority: ComplaintPriority.low,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ComplaintStatus.resolved,
        resolvedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        resolvedBy: 'FO-001',
      );

      routingService.registerComplaint(resolvedComplaint);

      final closed = await routingService.closeComplaint(
        complaintId: resolvedComplaint.id,
        closedBy: 'CITIZEN-001',
        closureRemarks: 'Work inspected and verified clean. Thank you.',
      );

      expect(closed.status, ComplaintStatus.closed);
      expect(closed.isClosed, isTrue);
      expect(closed.closedBy, 'CITIZEN-001');
      expect(closed.closureRemarks, 'Work inspected and verified clean. Thank you.');
      expect(closed.slaStartedAt, resolvedComplaint.slaStartedAt);
    });

    test('Stage 7 Reopen: Ward Department Lead can reopen closed and resolved complaints', () async {
      final closedComplaint = ComplaintModel(
        id: 'C-REOPEN-TEST',
        ticketNumber: 'CF-000008',
        title: 'Inadequately filled pothole',
        description: 'Pothole asphalt washed away',
        category: CivicCategory.defaultCategories[0],
        location: const CivicLocation(
          latitude: 19.041,
          longitude: 72.843,
          address: 'Dharavi, Mumbai',
          ward: 'G_NORTH',
        ),
        priority: ComplaintPriority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: ComplaintStatus.closed,
        resolvedAt: DateTime.now().subtract(const Duration(hours: 2)),
        closedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      routingService.registerComplaint(closedComplaint);

      final reopened = await routingService.reopenComplaint(
        complaintId: closedComplaint.id,
        reopenedBy: 'BMC-GN-RDS-LEAD',
        reopenReason: 'Supervisory inspection found asphalt compaction inadequate.',
      );

      expect(reopened.status, ComplaintStatus.inProgress);
      expect(reopened.isReopened, isTrue);
      expect(reopened.reopenCount, 1);
      expect(reopened.reopenReason, 'Supervisory inspection found asphalt compaction inadequate.');
      expect(reopened.slaStartedAt, closedComplaint.slaStartedAt);
    });
  });
}
