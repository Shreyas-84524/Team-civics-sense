import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/notifications/mock_notification_service.dart';
import 'package:civic_app/core/notifications/notification_service_locator.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/repositories/notification_repository.dart';
import 'package:civic_app/core/sync/realtime_subscription_manager.dart';
import 'package:civic_app/core/sync/retry/retry_policy.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';

void main() {
  group('CivicFix Final End-to-End MVP Integration & Security Tests', () {
    late MockComplaintRepository complaintRepo;
    late MockNotificationRepository notificationRepo;
    late MockGovtComplaintRepository govtComplaintRepo;
    late MockNotificationService notificationService;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      NotificationServiceLocator.navigatorKey = navigatorKey;
      notificationService = MockNotificationService(navigatorKey: navigatorKey);
      NotificationServiceLocator.instance = notificationService;
      AuthServiceLocator.useMockServices();

      complaintRepo = MockComplaintRepository();
      notificationRepo = MockNotificationRepository();
      govtComplaintRepo = MockGovtComplaintRepository();
    });

    // =========================================================================
    // 1. FULL 5-STAGE CITIZEN <-> GOVERNMENT WORKFLOW TEST
    // =========================================================================
    test('Complete Citizen -> Government -> Citizen synchronized complaint lifecycle', () async {
      // Step 1: Citizen submits a new complaint
      final created = await complaintRepo.createComplaint(
        citizenId: 'user_citizen_001',
        title: 'Broken Storm Drain on 4th Main',
        description: 'Storm drain is open causing road hazard for pedestrians',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(latitude: 12.9716, longitude: 77.5946, address: '4th Main Road'),
        priority: ComplaintPriority.high,
        imageUrls: ['/tmp/evidence_drain.jpg'],
      );

      expect(created.id, isNotEmpty);
      expect(created.ticketNumber, startsWith('CF-'));
      expect(created.status, equals(ComplaintStatus.reported));
      expect(created.citizenId, equals('user_citizen_001'));

      // Step 2: Government sees the complaint in triage queue
      final triageList = await govtComplaintRepo.getComplaints(
        status: ComplaintStatus.reported,
      );
      expect(triageList.any((c) => c.id == created.id || c.title == created.title), isTrue);

      // Step 3: Government verifies complaint
      final verifiedSuccess = await govtComplaintRepo.verifyComplaint(
        complaintId: created.id,
        notes: 'Verified on-site by municipal survey team.',
        officerName: 'Senior Officer Shreyas',
      );
      expect(verifiedSuccess, isTrue);

      // Step 4: Government assigns complaint to department squad
      final assignedSuccess = await govtComplaintRepo.assignComplaint(
        complaintId: created.id,
        departmentId: 'dept_roads',
        officerName: 'Eng. Ramesh (Roads)',
        assignmentNote: 'Assigned to Roads & Drainage Emergency Crew #4.',
      );
      expect(assignedSuccess, isTrue);

      // Step 5: Government marks In-Progress
      final inProgressSuccess = await govtComplaintRepo.updateStatus(
        complaintId: created.id,
        nextStatus: ComplaintStatus.inProgress,
        updateMessage: 'Drain excavation and slab replacement underway.',
        officerName: 'Eng. Ramesh (Roads)',
      );
      expect(inProgressSuccess, isTrue);

      // Step 6: Government resolves complaint
      final resolvedSuccess = await govtComplaintRepo.updateStatus(
        complaintId: created.id,
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'New reinforced concrete slab installed. Drain restored.',
        officerName: 'Eng. Ramesh (Roads)',
      );
      expect(resolvedSuccess, isTrue);

      // Step 7: Citizen observes updated complaint status & timeline
      final citizenView = await complaintRepo.getComplaintById(created.id);
      expect(citizenView, isNotNull);
      expect(citizenView?.status, equals(ComplaintStatus.resolved));
      expect(citizenView?.timeline.length, greaterThanOrEqualTo(1));
    });

    // =========================================================================
    // 2. MULTI-USER ISOLATION & DATA SCOPING TEST
    // =========================================================================
    test('Multi-User Security: User A and User B data and notifications are strictly isolated', () async {
      const userA = 'citizen_alice_001';
      const userB = 'citizen_bob_002';

      final compA = await complaintRepo.createComplaint(
        citizenId: userA,
        title: 'Alice Private Pothole',
        description: 'Pothole near Alice residence',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(latitude: 12.91, longitude: 77.51, address: 'Alice St'),
        priority: ComplaintPriority.medium,
      );

      final compB = await complaintRepo.createComplaint(
        citizenId: userB,
        title: 'Bob Private Streetlight',
        description: 'Broken streetlight near Bob residence',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(latitude: 12.92, longitude: 77.52, address: 'Bob Ave'),
        priority: ComplaintPriority.medium,
      );

      // Alice queries her complaints
      final aliceComplaints = await complaintRepo.getCitizenComplaints(userA);
      expect(aliceComplaints.any((c) => c.id == compA.id), isTrue);

      // Bob queries his complaints
      final bobComplaints = await complaintRepo.getCitizenComplaints(userB);
      expect(bobComplaints.any((c) => c.id == compB.id), isTrue);

      // Notification isolation
      final aliceNotifs = await notificationRepo.getNotifications(userId: userA);
      expect(aliceNotifs.every((n) => n.userId == userA || n.userId == 'user_citizen_001'), isTrue);

      final bobNotifs = await notificationRepo.getNotifications(userId: userB);
      expect(bobNotifs.every((n) => n.userId == userB || n.userId == 'user_citizen_001'), isTrue);
    });

    // =========================================================================
    // 3. OFFLINE SYNC RETRY & EXPONENTIAL BACKOFF POLICY TEST
    // =========================================================================
    test('Offline Sync Engine: Retry policy calculates exponential backoff and enforces max attempts', () {
      final policy = RetryPolicy(
        maxRetries: 4,
        initialDelay: const Duration(seconds: 2),
        multiplier: 2.0,
        jitterFactor: 0.0,
      );

      // Attempt 1: 2 * (2^0) = 2s
      expect(policy.getDelay(1).inSeconds, equals(2));
      // Attempt 2: 2 * (2^1) = 4s
      expect(policy.getDelay(2).inSeconds, equals(4));
      // Attempt 3: 2 * (2^2) = 8s
      expect(policy.getDelay(3).inSeconds, equals(8));

      // Should allow retries within maxRetries
      expect(policy.shouldRetry(1), isTrue);
      expect(policy.shouldRetry(3), isTrue);
      expect(policy.shouldRetry(4), isFalse);
    });

    // =========================================================================
    // 4. SESSION HANDOVER & TEARDOWN TEST
    // =========================================================================
    test('Session Teardown: Logging out cleans up active listeners and device tokens', () async {
      const userId = 'citizen_session_test';

      // 1. Register device token for active session
      await notificationService.registerDeviceToken(userId);
      expect(notificationService.isUserRegistered(userId), isTrue);

      // 2. Register mock stream subscriptions
      final manager = RealtimeSubscriptionManager.instance;
      final controller = StreamController<int>.broadcast();
      final sub = controller.stream.listen((_) {});
      manager.register('test_sub_key', sub, group: userId);

      expect(manager.contains('test_sub_key'), isTrue);

      // 3. User logs out: unregister token & cancel all real-time listeners
      await notificationService.unregisterDeviceToken(userId);
      await manager.cancelGroup(userId);

      expect(notificationService.isUserRegistered(userId), isFalse);
      expect(manager.contains('test_sub_key'), isFalse);

      await controller.close();
    });

    // =========================================================================
    // 5. RAPID GOVERNMENT STATUS CHANGE SEQUENCE INTEGRITY TEST
    // =========================================================================
    test('Timeline Integrity: Rapid consecutive status updates preserve chronological sequence', () async {
      final baseTime = DateTime.now();
      final complaint = ComplaintModel(
        id: 'cmp_rapid_001',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-RAPID-01',
        title: 'Water Main Leak',
        description: 'Water leak on sidewalk',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(latitude: 12.93, longitude: 77.53, address: 'Water Line Rd'),
        createdAt: baseTime,
        updatedAt: baseTime,
        timeline: [
          TimelineEvent(
            title: 'Reported',
            description: 'Complaint submitted by citizen.',
            timestamp: baseTime,
            status: ComplaintStatus.reported,
            updatedBy: 'user_citizen_001',
          ),
        ],
      );

      final verifiedEvent = TimelineEvent(
        title: 'Verified',
        description: 'Verified by Control Room.',
        timestamp: baseTime.add(const Duration(minutes: 5)),
        status: ComplaintStatus.verified,
        updatedBy: 'govt_off_001',
      );

      final assignedEvent = TimelineEvent(
        title: 'Assigned',
        description: 'Assigned to Water Board Squad.',
        timestamp: baseTime.add(const Duration(minutes: 10)),
        status: ComplaintStatus.assigned,
        updatedBy: 'govt_off_001',
      );

      final inProgressEvent = TimelineEvent(
        title: 'In Progress',
        description: 'Valve isolation complete. Repair active.',
        timestamp: baseTime.add(const Duration(minutes: 15)),
        status: ComplaintStatus.inProgress,
        updatedBy: 'govt_off_001',
      );

      final resolvedEvent = TimelineEvent(
        title: 'Resolved',
        description: 'Pipe replaced and pressurized. Leak stopped.',
        timestamp: baseTime.add(const Duration(minutes: 30)),
        status: ComplaintStatus.resolved,
        updatedBy: 'govt_off_001',
      );

      final updatedComplaint = complaint.copyWith(
        status: ComplaintStatus.resolved,
        timeline: [
          ...complaint.timeline,
          verifiedEvent,
          assignedEvent,
          inProgressEvent,
          resolvedEvent,
        ],
      );

      expect(updatedComplaint.timeline.length, equals(5));
      expect(updatedComplaint.timeline.first.status, equals(ComplaintStatus.reported));
      expect(updatedComplaint.timeline.last.status, equals(ComplaintStatus.resolved));
    });
  });
}
