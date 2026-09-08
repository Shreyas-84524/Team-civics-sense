import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/User%20UI/models/complaint_draft.dart';
import 'package:civic_app/User%20UI/screens/complaint_details_screen.dart';
import 'package:civic_app/User%20UI/services/mock_complaint_service.dart';
import 'package:civic_app/User%20UI/widgets/complaint_card.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/sync/logging/sync_logger.dart';
import 'package:civic_app/core/sync/providers/mock_sync_provider.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';
import 'package:civic_app/core/sync/retry/retry_policy.dart';
import 'package:civic_app/core/sync/sync_manager.dart';

void main() {
  group('CivicFix Offline Sync Queue & Synchronization Engine Integration Tests', () {
    late SyncQueue syncQueue;
    late MockSyncProvider syncProvider;
    late AppConnectivityService connectivityService;
    late MockComplaintRepository repository;
    late SyncManager syncManager;
    late MockComplaintService complaintService;

    setUp(() {
      syncQueue = HiveSyncQueue();
      syncProvider = MockSyncProvider();
      connectivityService = AppConnectivityService();
      connectivityService.resetForTesting(initialOnline: false);
      repository = MockComplaintRepository();

      syncManager = SyncManager.createForTesting(
        queue: syncQueue,
        provider: syncProvider,
        connectivity: connectivityService,
        repository: repository,
        retryPolicy: RetryPolicy(maxRetries: 3, initialDelay: const Duration(milliseconds: 10)),
        logger: SyncLogger(),
      );

      complaintService = MockComplaintService(
        connectivityService: connectivityService,
        repository: repository,
      );
    });

    tearDown(() {
      syncManager.dispose();
      syncQueue.dispose();
    });

    test('Full Offline Creation -> Queue -> Online Auto-Sync Lifecycle', () async {
      // 1. Citizen is offline
      expect(connectivityService.isOnline, isFalse);

      // 2. Citizen fills and submits complaint
      final draft = ComplaintDraft(
        title: 'Large Pothole on 100ft Road',
        description: 'Deep pothole causing traffic jams near signal.',
        category: CivicCategory.defaultCategories.first,
        isHazard: true,
        location: const CivicLocation(
          latitude: 12.9352,
          longitude: 77.6245,
          address: '100ft Road, Koramangala',
          ward: 'Ward 151',
          city: 'Bengaluru',
        ),
        imageUrls: ['https://example.com/pothole.jpg'],
      );

      final submittedComplaint = await complaintService.submitComplaint(draft);

      // Verify offline draft state
      expect(submittedComplaint.syncStatus, equals(SyncStatus.pending));
      expect(submittedComplaint.ticketNumber, startsWith('LOCAL-2026-'));

      // Queue in SyncManager
      await syncManager.queueComplaintCreation(submittedComplaint);

      // Check item in sync queue
      final pendingQueueItems = await syncQueue.getPendingItems();
      expect(pendingQueueItems.length, equals(1));
      expect(pendingQueueItems.first.entityId, equals(submittedComplaint.id));

      // 3. Network Restored: transition offline -> online
      connectivityService.setOnline(true);
      expect(connectivityService.isOnline, isTrue);

      // Wait brief moment for reactive queue processing
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Verify sync completed
      final queueAfterSync = await syncQueue.getPendingItems();
      expect(queueAfterSync.isEmpty, isTrue);

      final syncedComplaint = await repository.getComplaintById(submittedComplaint.id);
      expect(syncedComplaint, isNotNull);
      expect(syncedComplaint!.syncStatus, equals(SyncStatus.synced));
      expect(syncedComplaint.serverId, isNotNull);
      expect(syncedComplaint.serverId, startsWith('srv_cmp_'));
    });

    testWidgets('ComplaintCard renders pending, syncing, and failed badges appropriately', (tester) async {
      final baseComplaint = ComplaintModel(
        id: 'cmp_badge_test',
        ticketNumber: 'LOCAL-2026-000888',
        title: 'Water pipe leak',
        description: 'Drinking water pipe leaking continuously.',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.9, longitude: 77.6, address: 'Indiranagar'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      // Pending badge test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(complaint: baseComplaint, onTap: () {}),
          ),
        ),
      );
      expect(find.text('Pending Sync'), findsOneWidget);

      // Syncing badge test
      final syncingComplaint = baseComplaint.copyWith(syncStatus: SyncStatus.syncing);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(complaint: syncingComplaint, onTap: () {}),
          ),
        ),
      );
      expect(find.text('Syncing...'), findsOneWidget);

      // Failed badge test
      final failedComplaint = baseComplaint.copyWith(syncStatus: SyncStatus.failed);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(complaint: failedComplaint, onTap: () {}),
          ),
        ),
      );
      expect(find.text('Sync Failed'), findsOneWidget);
    });

    testWidgets('ComplaintDetailsScreen displays sync banners and retry button for failed sync', (tester) async {
      final failedComplaint = ComplaintModel(
        id: 'cmp_failed_details_test',
        ticketNumber: 'LOCAL-2026-000999',
        title: 'Overflowing Garbage Bin',
        description: 'Garbage overflowing onto main footpath.',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 12.9, longitude: 77.6, address: 'MG Road'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.failed,
      );

      await repository.saveOfflineComplaint(failedComplaint);

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailsScreen(
            complaint: failedComplaint,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Synchronization Failed'), findsOneWidget);
      expect(find.text('Retry Sync'), findsOneWidget);
    });
  });
}
