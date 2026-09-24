import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/firestore/firebase_complaint_data_source.dart';
import 'package:civic_app/core/local/mock_data_source.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/offline_first_govt_complaint_repository.dart';
import 'package:civic_app/core/services/supabase_notification_service.dart';
import 'package:civic_app/core/sync/models/sync_queue_item.dart';
import 'package:civic_app/core/sync/providers/firebase_sync_provider.dart';
import 'package:civic_app/core/sync/sync_manager.dart';

class MockTestConnectivityService implements ConnectivityService {
  bool _online;
  MockTestConnectivityService({bool online = true}) : _online = online;

  @override
  bool get isOnline => _online;

  @override
  bool get isOffline => !_online;

  @override
  void setOnline(bool val) => _online = val;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(_online);
}

/// Headless in-memory test double for FirebaseComplaintDataSource
class FakeFirebaseComplaintDataSource extends FirebaseComplaintDataSource {
  final Map<String, ComplaintModel> complaints = {};
  final List<TimelineEvent> addedEvents = [];
  bool simulateError = false;

  FakeFirebaseComplaintDataSource() : super(firestore: null);

  @override
  Future<void> updateGovernmentWorkflow(
    String complaintId, {
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    String? departmentId,
    String? departmentName,
    String? officerNotes,
    DateTime? resolvedAt,
  }) async {
    if (simulateError) {
      throw Exception('Simulated Firestore remote failure');
    }
  }

  @override
  Future<void> addTimelineEvent(String complaintId, TimelineEvent event) async {
    if (simulateError) {
      throw Exception('Simulated timeline write failure');
    }
    addedEvents.add(event);
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id, {bool includeTimeline = true}) async {
    return complaints[id];
  }
}

void main() {
  group('Government Complaint Notification Pipeline Integration Tests', () {
    late MockSupabaseNotificationService mockNotificationService;
    late MockTestConnectivityService mockConnectivity;
    late FakeFirebaseComplaintDataSource fakeDataSource;
    late OfflineFirstGovtComplaintRepository govtRepo;
    late SyncManager syncManager;
    const String testComplaintId = 'cmp_101';

    setUp(() async {
      MockDataSource().resetMockData();
      mockNotificationService = MockSupabaseNotificationService();
      mockConnectivity = MockTestConnectivityService(online: true);
      fakeDataSource = FakeFirebaseComplaintDataSource();
      syncManager = SyncManager();

      govtRepo = OfflineFirstGovtComplaintRepository(
        connectivity: mockConnectivity,
        complaintDataSource: fakeDataSource,
        notificationService: mockNotificationService,
        syncManager: syncManager,
      );

      mockNotificationService.dispatchedEvents.clear();
    });

    test('Status update while online triggers Supabase notification after local/remote update', () async {
      final success = await govtRepo.updateStatus(
        complaintId: testComplaintId,
        nextStatus: ComplaintStatus.inProgress,
        updateMessage: 'Field squad actively excavating pipeline.',
      );

      expect(success, isTrue);

      // Verify notification trigger was invoked
      await Future.delayed(const Duration(milliseconds: 20));
      expect(mockNotificationService.dispatchedEvents.length, equals(1));

      final event = mockNotificationService.dispatchedEvents.first;
      expect(event['complaintId'], equals(testComplaintId));
      expect(event['newStatus'], equals('inProgress'));
      expect(event['officerNotes'], contains('Field squad'));
    });

    test('Status update while offline queues in SyncManager and delays notification trigger', () async {
      mockConnectivity.setOnline(false);

      final success = await govtRepo.updateStatus(
        complaintId: testComplaintId,
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'Pipe replaced and water pressure restored.',
      );

      expect(success, isTrue);

      // Verify notification trigger was NOT invoked immediately while offline
      await Future.delayed(const Duration(milliseconds: 20));
      expect(mockNotificationService.dispatchedEvents.isEmpty, isTrue);

      // Verify item was queued in SyncManager
      final pending = await syncManager.queue.getPendingItems();
      expect(pending.isNotEmpty, isTrue);
      expect(pending.last.payload['status'], equals('resolved'));
    });

    test('Notification dispatch failure does NOT roll back or fail status update', () async {
      mockNotificationService.shouldSucceed = false;

      final success = await govtRepo.updateStatus(
        complaintId: testComplaintId,
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'Resolved despite network notification issue.',
      );

      expect(success, isTrue);

      final updatedComplaint = await govtRepo.getComplaintById(testComplaintId);
      expect(updatedComplaint, isNotNull);
      expect(updatedComplaint!.status, equals(ComplaintStatus.resolved));
    });

    test('Assigning complaint triggers notification with assigned status', () async {
      final success = await govtRepo.assignComplaint(
        complaintId: testComplaintId,
        departmentId: 'water',
        officerName: 'Engineer Sharma',
        assignmentNote: 'Assigned for immediate pressure check.',
      );

      expect(success, isTrue);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(mockNotificationService.dispatchedEvents.length, equals(1));

      final event = mockNotificationService.dispatchedEvents.first;
      expect(event['newStatus'], equals('assigned'));
      expect(event['officerNotes'], contains('pressure check'));
    });

    test('FirebaseSyncProvider dispatches notification upon executing queued status sync', () async {
      final syncProvider = FirebaseSyncProvider(
        complaintDataSource: fakeDataSource,
        notificationService: mockNotificationService,
      );

      final syncItem = SyncQueueItem(
        id: 'sync_item_test_001',
        entityType: 'complaint',
        entityId: 'cmp_101',
        operation: SyncOperation.updateComplaint,
        payload: {
          'complaintId': 'cmp_101',
          'serverId': 'cmp_101',
          'citizenId': 'usr_citizen_99',
          'ticketNumber': 'CF-2026-000101',
          'title': 'Leaking Water Pipe',
          'oldStatus': 'assigned',
          'status': 'resolved',
          'officerNotes': 'Completed via offline sync batch',
        },
        createdAt: DateTime.now(),
        status: SyncQueueStatus.pending,
      );

      final result = await syncProvider.execute(syncItem);
      expect(result.isSuccess, isTrue);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(mockNotificationService.dispatchedEvents.length, equals(1));

      final event = mockNotificationService.dispatchedEvents.first;
      expect(event['complaintId'], equals('cmp_101'));
      expect(event['citizenId'], equals('usr_citizen_99'));
      expect(event['newStatus'], equals('resolved'));
      expect(event['eventId'], equals('sync_item_test_001'));
    });
  });
}
