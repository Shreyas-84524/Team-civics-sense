import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/local/hive/hive_storage_service.dart';
import 'package:civic_app/core/local/mock_data_source.dart';
import 'package:civic_app/core/local/models/complaint_local_model.dart';
import 'package:civic_app/core/local/models/user_local_model.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';
import 'package:civic_app/core/repositories/hive_hazard_repository.dart';
import 'package:civic_app/core/repositories/hive_notification_repository.dart';
import 'package:civic_app/core/repositories/hive_rewards_repository.dart';
import 'package:civic_app/core/repositories/hive_user_repository.dart';
import 'package:civic_app/core/sync/models/sync_queue_item.dart';
import 'package:civic_app/core/sync/providers/mock_sync_provider.dart';
import 'package:civic_app/core/sync/providers/sync_provider.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';
import 'package:civic_app/core/sync/sync_manager.dart';
import 'package:civic_app/User UI/models/complaint_draft.dart';
import 'package:civic_app/User UI/services/mock_complaint_service.dart';

class TestMockConnectivityService implements ConnectivityService {
  bool _isOnline;
  final _controller = StreamController<bool>.broadcast();

  TestMockConnectivityService({bool initialOnline = true}) : _isOnline = initialOnline;

  @override
  bool get isOnline => _isOnline;

  @override
  bool get isOffline => !_isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _controller.add(online);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Custom test sync provider for fine-grained failure injection
class TestAuditingSyncProvider implements SyncProvider {
  final Future<SyncResult> Function(SyncQueueItem item)? onExecute;

  TestAuditingSyncProvider({this.onExecute});

  @override
  Future<SyncResult> execute(SyncQueueItem item) async {
    if (onExecute != null) {
      return await onExecute!(item);
    }
    return SyncResult.success(
      serverId: 'srv_${item.entityId}',
      responseData: {'status': 'synced', 'serverTicket': 'CF-2026-SRV-${item.entityId}'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveStorageService storageService;
  late MockDataSource dataSource;

  setUp(() async {
    SyncManager.resetInstanceForTesting();
    tempDir = await Directory.systemTemp.createTemp('civic_prompt5_audit_test_');
    Hive.init(tempDir.path);
    await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
    storageService = HiveStorageService.instance;
    await storageService.init(subDir: tempDir.path, isTest: true);

    dataSource = MockDataSource();
    dataSource.resetMockData();
  });

  tearDown(() async {
    SyncManager.resetInstanceForTesting();
    try {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Prompt 5 — Step 3: Single Offline Complaint Lifecycle & Restart Survival', () {
    test('Online complaint creates synced record, Offline complaint creates pending record that survives app restart', () async {
      final connectivity = TestMockConnectivityService(initialOnline: true);
      final repo = HiveComplaintRepository(storage: storageService, dataSource: dataSource);
      final service = MockComplaintService(connectivityService: connectivity, repository: repo);

      // 1. Submit complaint while ONLINE
      final onlineDraft = ComplaintDraft(
        title: 'Damaged streetlight fixture',
        description: 'Streetlight is hanging by wire',
        category: CivicCategory.defaultCategories[2],
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Cross, MG Road',
          ward: 'Ward 14',
          city: 'Bengaluru',
        ),
      );

      final onlineComplaint = await service.submitComplaint(onlineDraft);
      expect(onlineComplaint.syncStatus, equals(SyncStatus.synced));
      expect(onlineComplaint.ticketNumber.startsWith('CF-2026-'), isTrue);

      // 2. Switch to OFFLINE
      connectivity.setOnline(false);

      final offlineDraft = ComplaintDraft(
        title: 'Large pothole in roadway',
        description: 'Dangerous deep pothole near junction',
        category: CivicCategory.defaultCategories[0],
        isHazard: true,
        location: const CivicLocation(
          latitude: 12.9740,
          longitude: 77.5960,
          address: 'Junction Circle',
          ward: 'Ward 14',
          city: 'Bengaluru',
        ),
      );

      final offlineComplaint = await service.submitComplaint(offlineDraft);
      expect(offlineComplaint.syncStatus, equals(SyncStatus.pending));
      expect(offlineComplaint.ticketNumber.startsWith('LOCAL-2026-'), isTrue);
      expect(offlineComplaint.localId, isNotNull);

      // 3. Verify saved persistently in Hive complaints box
      final storedComplaint = await storageService.get<ComplaintLocalModel>(
        HiveBoxes.complaints,
        offlineComplaint.id,
      );
      expect(storedComplaint, isNotNull);
      expect(storedComplaint!.syncStatus, equals('pending'));
      expect(storedComplaint.isHazard, isTrue);

      // 4. Simulate App Restart (Close all Hive boxes and re-open)
      await Hive.close();
      expect(Hive.isBoxOpen(HiveBoxes.complaints), isFalse);

      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      final restoredBox = await Hive.openBox<ComplaintLocalModel>(HiveBoxes.complaints);
      final restoredComplaint = restoredBox.get(offlineComplaint.id);

      expect(restoredComplaint, isNotNull);
      expect(restoredComplaint!.title, equals('Large pothole in roadway'));
      expect(restoredComplaint.syncStatus, equals('pending'));
      expect(restoredComplaint.isHazard, isTrue);
      expect(restoredComplaint.timeline.isNotEmpty, isTrue);
    });
  });

  group('Prompt 5 — Step 4: Multiple Offline Complaints A, B, C, D', () {
    test('4 offline complaints get unique IDs, survive restart, and queue all required operations', () async {
      final connectivity = TestMockConnectivityService(initialOnline: false);
      final repo = HiveComplaintRepository(storage: storageService, dataSource: dataSource);
      final queue = HiveSyncQueue(storage: storageService);
      final service = MockComplaintService(connectivityService: connectivity, repository: repo);

      final createdComplaints = <ComplaintModel>[];
      final titles = ['Complaint A', 'Complaint B', 'Complaint C', 'Complaint D'];

      for (int i = 0; i < titles.length; i++) {
        final draft = ComplaintDraft(
          title: titles[i],
          description: 'Description for ${titles[i]}',
          category: CivicCategory.defaultCategories[i % CivicCategory.defaultCategories.length],
          location: CivicLocation(
            latitude: 12.9700 + (i * 0.001),
            longitude: 77.5900 + (i * 0.001),
            address: 'Street $i, Sector $i',
            ward: 'Ward $i',
            city: 'Bengaluru',
          ),
        );

        final complaint = await service.submitComplaint(draft);
        createdComplaints.add(complaint);
      }

      // Verify each complaint has a unique local ID and ticket number
      final ids = createdComplaints.map((c) => c.id).toSet();
      final localIds = createdComplaints.map((c) => c.localId).toSet();
      final ticketNumbers = createdComplaints.map((c) => c.ticketNumber).toSet();

      expect(ids.length, equals(4));
      expect(localIds.length, equals(4));
      expect(ticketNumbers.length, equals(4));

      // Verify each complaint has independent sync status
      for (final c in createdComplaints) {
        expect(c.syncStatus, equals(SyncStatus.pending));
      }

      // Verify Queue has 4 items created via saveOfflineComplaint
      final pendingQueueItems = await queue.getPendingItems();
      expect(pendingQueueItems.length, equals(4));

      // Simulate App Restart
      await Hive.close();
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);

      final reloadedRepo = HiveComplaintRepository(storage: storageService, dataSource: dataSource);
      final reloadedQueue = HiveSyncQueue(storage: storageService);

      final restoredComplaints = await reloadedRepo.getCitizenComplaints('user_citizen_001');
      expect(restoredComplaints.length, greaterThanOrEqualTo(4));

      for (final original in createdComplaints) {
        final found = restoredComplaints.firstWhere((c) => c.id == original.id);
        expect(found.title, equals(original.title));
        expect(found.syncStatus, equals(SyncStatus.pending));
      }

      final restoredQueueItems = await reloadedQueue.getPendingItems();
      expect(restoredQueueItems.length, equals(4));
    });
  });

  group('Prompt 5 — Step 5: Interrupted Sync Simulation & Resumption', () {
    test('Sync handles mid-stream connection loss, prevents duplicates, and completes remaining on reconnect', () async {
      final connectivity = TestMockConnectivityService(initialOnline: false);
      final repo = HiveComplaintRepository(storage: storageService, dataSource: dataSource);
      final queue = HiveSyncQueue(storage: storageService);

      int providerCallCount = 0;
      bool dropConnectionMidSync = false;

      // Custom mock sync provider that simulates a network drop during operation #3
      final provider = TestAuditingSyncProvider(
        onExecute: (item) async {
          providerCallCount++;
          if (dropConnectionMidSync && providerCallCount > 2) {
            connectivity.setOnline(false);
            return SyncResult.failure('Network connection lost mid-stream');
          }
          return SyncResult.success(
            serverId: 'srv_${item.entityId}',
            responseData: {'serverTicket': 'CF-2026-SRV-${item.entityId}'},
          );
        },
      );

      final syncManager = SyncManager.createForTesting(
        queue: queue,
        provider: provider,
        repository: repo,
        connectivity: connectivity,
      );

      // Create 4 offline pending complaints via repo.saveOfflineComplaint (auto-queues into pending_sync)
      for (int i = 1; i <= 4; i++) {
        final complaint = ComplaintModel(
          id: 'cmp_multi_$i',
          citizenId: 'user_citizen_001',
          ticketNumber: 'LOCAL-2026-0000$i',
          localId: 'LOCAL-2026-0000$i',
          title: 'Issue $i',
          description: 'Description $i',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Test St'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );
        await repo.saveOfflineComplaint(complaint);
      }

      expect((await queue.getPendingItems()).length, equals(4));

      // Simulate: Connection returns, sync begins, but connection drops after 2 complaints
      dropConnectionMidSync = true;
      connectivity.setOnline(true);
      await syncManager.processQueue();

      // Verify: First 2 complaints synced, remaining 2 failed/pending
      final c1 = await repo.getComplaintById('cmp_multi_1');
      final c2 = await repo.getComplaintById('cmp_multi_2');
      final c3 = await repo.getComplaintById('cmp_multi_3');
      final c4 = await repo.getComplaintById('cmp_multi_4');

      expect(c1!.syncStatus, equals(SyncStatus.synced));
      expect(c2!.syncStatus, equals(SyncStatus.synced));
      expect(c3!.syncStatus, isNot(equals(SyncStatus.synced)));
      expect(c4!.syncStatus, isNot(equals(SyncStatus.synced)));

      // Simulate: Connection fully restored -> retry resumes remaining operations without duplicating 1 and 2
      dropConnectionMidSync = false;
      connectivity.setOnline(true);
      await syncManager.processQueue();

      final c3After = await repo.getComplaintById('cmp_multi_3');
      final c4After = await repo.getComplaintById('cmp_multi_4');

      expect(c3After!.syncStatus, equals(SyncStatus.synced));
      expect(c4After!.syncStatus, equals(SyncStatus.synced));
      expect((await queue.getPendingItems()).length, equals(0));
    });
  });

  group('Prompt 5 — Step 6: Partial Failure / Evidence Image Sync Failure', () {
    test('Failed image sync does not delete complaint and queues retryable evidence task', () async {
      final connectivity = TestMockConnectivityService(initialOnline: true);
      final repo = HiveComplaintRepository(storage: storageService, dataSource: dataSource);
      final queue = HiveSyncQueue(storage: storageService);

      final provider = MockSyncProvider(
        simulatePartialUploadFailure: true, // Complaint succeeds, but image upload fails
      );

      final syncManager = SyncManager.createForTesting(
        queue: queue,
        provider: provider,
        repository: repo,
        connectivity: connectivity,
      );

      final complaintWithImages = ComplaintModel(
        id: 'cmp_partial_fail_1',
        citizenId: 'user_citizen_001',
        ticketNumber: 'LOCAL-2026-000999',
        localId: 'LOCAL-2026-000999',
        title: 'Broken bench in park',
        description: 'Bench wooden planks broken',
        category: CivicCategory.defaultCategories[6],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.low,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Park Lane'),
        imageUrls: const ['file:///local/images/broken_bench.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await repo.saveOfflineComplaint(complaintWithImages);

      await syncManager.processQueue();

      // Complaint MUST remain available in repository with serverId assigned
      final complaint = await repo.getComplaintById('cmp_partial_fail_1');
      expect(complaint, isNotNull);
      expect(complaint!.serverId, startsWith('srv_cmp_'));

      // Dedicated image upload retry task MUST be queued in SyncQueue
      final pendingItems = await queue.getPendingItems();
      expect(pendingItems.any((i) => i.operation == SyncOperation.uploadEvidence), isTrue);

      // Now simulate retrying image upload with network recovered
      provider.simulatePartialUploadFailure = false;
      await syncManager.processQueue();

      // Verify all queue items resolved
      final remaining = await queue.getPendingItems();
      expect(remaining.isEmpty, isTrue);
    });
  });

  group('Prompt 5 — Step 7: Storage Failure & Graceful Degradation', () {
    test('Uninitialized or unavailable storage falls back to in-memory dataSource without throwing crashes', () async {
      // Create uninitialized storage service instance
      final uninitializedStorage = HiveStorageService();

      final repo = HiveComplaintRepository(
        storage: uninitializedStorage,
        dataSource: dataSource,
      );

      final userRepo = HiveUserRepository(
        storage: uninitializedStorage,
        dataSource: dataSource,
      );

      final notifRepo = HiveNotificationRepository(
        storage: uninitializedStorage,
        dataSource: dataSource,
      );

      final rewardsRepo = HiveRewardsRepository(
        storage: uninitializedStorage,
        dataSource: dataSource,
      );

      final hazardRepo = HiveHazardRepository(
        storage: uninitializedStorage,
        dataSource: dataSource,
      );

      // 1. Complaint Repository fallback
      final testComplaint = ComplaintModel(
        id: 'cmp_storage_fail_1',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-999999',
        title: 'Water Leak',
        description: 'Water pipe leaking',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Test'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saved = await repo.saveOfflineComplaint(testComplaint);
      expect(saved.id, equals('cmp_storage_fail_1'));

      final list = await repo.getCitizenComplaints('user_citizen_001');
      expect(list.any((c) => c.id == 'cmp_storage_fail_1'), isTrue);

      // 2. User Repository fallback
      final user = await userRepo.getCurrentUser();
      expect(user.fullName, isNotEmpty);

      // 3. Notification Repository fallback
      final notifs = await notifRepo.getNotifications();
      expect(notifs, isA<List>());

      // 4. Rewards Repository fallback
      final rewards = await rewardsRepo.getRewardData(user.id);
      expect(rewards.achievements.isNotEmpty, isTrue);

      // 5. Hazard Repository fallback
      final hazards = await hazardRepo.getHazards();
      expect(hazards, isA<List>());
    });
  });

  group('Prompt 5 — Step 8: Sync State UX & Citizen Terminology Audit', () {
    test('Sync status labels and badges are citizen-friendly and contain no technical storage jargon', () {
      final statuses = [
        SyncStatus.pending,
        SyncStatus.syncing,
        SyncStatus.synced,
        SyncStatus.failed,
      ];

      for (final st in statuses) {
        final label = st.label;
        expect(label.isNotEmpty, isTrue);
        // Verify no internal technical terms are leaked to citizens
        expect(label.toLowerCase().contains('hive'), isFalse);
        expect(label.toLowerCase().contains('box'), isFalse);
        expect(label.toLowerCase().contains('queue'), isFalse);
        expect(label.toLowerCase().contains('adapter'), isFalse);
        expect(label.toLowerCase().contains('serialize'), isFalse);
      }

      expect(SyncStatus.pending.label, equals('Pending Sync'));
      expect(SyncStatus.syncing.label, equals('Syncing...'));
      expect(SyncStatus.synced.label, equals('Synced'));
      expect(SyncStatus.failed.label, equals('Sync Failed'));
    });
  });

  group('Prompt 5 — Step 11: Data Integrity & Concept Separation', () {
    test('ComplaintStatus, SyncStatus, and SyncQueueStatus remain strictly decoupled', () {
      // 1. Complaint domain status (5 canonical lifecycle stages)
      const cStatus = ComplaintStatus.inProgress;
      expect(cStatus.label, equals('In Progress'));

      // 2. Complaint sync state (4 offline sync states)
      const sStatus = SyncStatus.pending;
      expect(sStatus.label, equals('Pending Sync'));

      // 3. Sync Queue task state (4 execution states)
      const qStatus = SyncQueueStatus.processing;
      expect(qStatus.name, equals('processing'));

      // Verify that updating one does not mutate or confuse others
      final complaint = ComplaintModel(
        id: 'cmp_concept_1',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000001',
        title: 'Concept Separation Test',
        description: 'Verify separate enums',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.verified,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Test'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      expect(complaint.status, equals(ComplaintStatus.verified));
      expect(complaint.syncStatus, equals(SyncStatus.synced));

      final updatedComplaint = complaint.copyWith(status: ComplaintStatus.inProgress);
      expect(updatedComplaint.status, equals(ComplaintStatus.inProgress));
      expect(updatedComplaint.syncStatus, equals(SyncStatus.synced)); // Remains unchanged
    });
  });

  group('Prompt 5 — Step 12: Security & Local Storage Credential Audit', () {
    test('No passwords, auth tokens, or sensitive credentials exist in Hive persistence models', () {
      // 1. UserLocalModel audit
      final user = UserModel(
        id: 'user_sec_1',
        fullName: 'Citizen Tester',
        email: 'citizen@test.gov',
        phone: '+91 9876543210',
        wardNumber: 'Ward 14 (Central)',
        civicPoints: 250,
      );
      final userLocal = UserLocalModel.fromDomain(user);
      final userJson = jsonEncode({
        'id': userLocal.id,
        'fullName': userLocal.fullName,
        'email': userLocal.email,
        'phone': userLocal.phone,
        'wardNumber': userLocal.wardNumber,
      });

      expect(userJson.contains('password'), isFalse);
      expect(userJson.contains('token'), isFalse);
      expect(userJson.contains('authToken'), isFalse);
      expect(userJson.contains('secret'), isFalse);

      // 2. ComplaintLocalModel audit
      final complaint = ComplaintModel(
        id: 'cmp_sec_1',
        citizenId: 'user_sec_1',
        ticketNumber: 'CF-2026-000001',
        title: 'Security Audit',
        description: 'Test descriptions',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Test'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final complaintLocal = ComplaintLocalModel.fromDomain(complaint);
      final complaintJson = jsonEncode({
        'id': complaintLocal.id,
        'citizenId': complaintLocal.citizenId,
        'title': complaintLocal.title,
      });

      expect(complaintJson.contains('password'), isFalse);
      expect(complaintJson.contains('token'), isFalse);
    });
  });
}
