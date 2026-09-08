import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/sync/logging/sync_logger.dart';
import 'package:civic_app/core/sync/models/sync_queue_item.dart';
import 'package:civic_app/core/sync/providers/mock_sync_provider.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';
import 'package:civic_app/core/sync/retry/retry_policy.dart';
import 'package:civic_app/core/sync/sync_manager.dart';

void main() {
  group('SyncManager Tests', () {
    late SyncQueue queue;
    late MockSyncProvider provider;
    late AppConnectivityService connectivity;
    late MockComplaintRepository repository;
    late SyncManager syncManager;

    final sampleComplaint = ComplaintModel(
      id: 'cmp_test_101',
      ticketNumber: 'LOCAL-2026-000101',
      title: 'Broken street lamp',
      description: 'The street lamp near park is broken.',
      category: CivicCategory.defaultCategories.first,
      status: ComplaintStatus.reported,
      priority: ComplaintPriority.medium,
      location: const CivicLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        address: '1st Cross, Indiranagar',
      ),
      imageUrls: const ['https://example.com/lamp1.jpg', 'https://example.com/lamp2.jpg'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    setUp(() {
      queue = HiveSyncQueue();
      provider = MockSyncProvider();
      connectivity = AppConnectivityService();
      connectivity.resetForTesting(initialOnline: true);
      repository = MockComplaintRepository();

      syncManager = SyncManager.createForTesting(
        queue: queue,
        provider: provider,
        connectivity: connectivity,
        repository: repository,
        retryPolicy: RetryPolicy(maxRetries: 3, initialDelay: const Duration(milliseconds: 10)),
        logger: SyncLogger(),
      );
    });

    tearDown(() {
      syncManager.dispose();
    });

    test('online flow synchronizes complaint and updates repository to synced with serverId', () async {
      await repository.saveOfflineComplaint(sampleComplaint);
      await syncManager.queueComplaintCreation(sampleComplaint);

      // Verify item processed and dequeued
      final pendingAfter = await queue.getPendingItems();
      expect(pendingAfter.isEmpty, isTrue);

      // Verify repository updated
      final updatedComplaint = await repository.getComplaintById(sampleComplaint.id);
      expect(updatedComplaint, isNotNull);
      expect(updatedComplaint!.syncStatus, equals(SyncStatus.synced));
      expect(updatedComplaint.serverId, isNotNull);
      expect(updatedComplaint.serverId, startsWith('srv_cmp_'));
    });

    test('offline flow pauses processing until network is restored', () async {
      connectivity.setOnline(false);

      await repository.saveOfflineComplaint(sampleComplaint);
      await syncManager.queueComplaintCreation(sampleComplaint);

      // While offline, queue should still contain item
      final pendingOffline = await queue.getPendingItems();
      expect(pendingOffline.length, equals(1));
      expect(pendingOffline.first.entityId, equals(sampleComplaint.id));

      final offlineComplaint = await repository.getComplaintById(sampleComplaint.id);
      expect(offlineComplaint!.syncStatus, equals(SyncStatus.pending));

      // Network restored -> auto process
      connectivity.setOnline(true);
      await Future.delayed(const Duration(milliseconds: 50));

      final pendingOnline = await queue.getPendingItems();
      expect(pendingOnline.isEmpty, isTrue);

      final syncedComplaint = await repository.getComplaintById(sampleComplaint.id);
      expect(syncedComplaint!.syncStatus, equals(SyncStatus.synced));
    });

    test('transient network failure triggers retry policy backoff', () async {
      provider.simulateNetworkFailure = true;

      await repository.saveOfflineComplaint(sampleComplaint);
      await syncManager.queueComplaintCreation(sampleComplaint);

      final allItems = await queue.getAllItems();
      expect(allItems.length, equals(1));
      expect(allItems.first.attemptCount, equals(1));
      expect(allItems.first.status, equals(SyncQueueStatus.pending));
      expect(allItems.first.errorMessage, contains('Simulated network timeout'));
    });

    test('exhausting max retries marks queue item and complaint as failed', () async {
      provider.simulateNetworkFailure = true;

      await repository.saveOfflineComplaint(sampleComplaint);

      final syncItem = SyncQueueItem(
        id: 'sync_${sampleComplaint.id}',
        entityType: 'complaint',
        entityId: sampleComplaint.id,
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
        attemptCount: 2, // 1 away from maxRetries (3)
        status: SyncQueueStatus.pending,
      );
      await queue.enqueue(syncItem);

      await syncManager.processQueue();

      final allItems = await queue.getAllItems();
      expect(allItems.first.attemptCount, equals(3));
      expect(allItems.first.status, equals(SyncQueueStatus.failed));

      final failedComplaint = await repository.getComplaintById(sampleComplaint.id);
      expect(failedComplaint!.syncStatus, equals(SyncStatus.failed));
    });

    test('partial failure syncs complaint and queues evidence retry item', () async {
      provider.simulatePartialUploadFailure = true;

      await repository.saveOfflineComplaint(sampleComplaint);
      await syncManager.queueComplaintCreation(sampleComplaint);

      // Complaint is synced on backend
      final complaint = await repository.getComplaintById(sampleComplaint.id);
      expect(complaint!.syncStatus, equals(SyncStatus.synced));
      expect(complaint.serverId, isNotNull);

      // Evidence upload item is queued
      final allItems = await queue.getAllItems();
      expect(allItems.any((i) => i.operation == SyncOperation.uploadEvidence), isTrue);
    });

    test('retryFailed resets failed tasks to pending and re-executes queue', () async {
      provider.simulateNetworkFailure = true;
      await repository.saveOfflineComplaint(sampleComplaint);

      final syncItem = SyncQueueItem(
        id: 'sync_${sampleComplaint.id}',
        entityType: 'complaint',
        entityId: sampleComplaint.id,
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
        attemptCount: 3,
        status: SyncQueueStatus.failed,
      );
      await queue.enqueue(syncItem);

      // Now server is back online
      provider.simulateNetworkFailure = false;
      await syncManager.retryFailed();

      final allItems = await queue.getAllItems();
      expect(allItems.isEmpty, isTrue);

      final synced = await repository.getComplaintById(sampleComplaint.id);
      expect(synced!.syncStatus, equals(SyncStatus.synced));
    });
  });
}
