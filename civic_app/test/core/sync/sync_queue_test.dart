import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/sync/models/sync_queue_item.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';

void main() {
  group('SyncQueue & HiveSyncQueue Tests', () {
    late SyncQueue queue;

    setUp(() {
      queue = HiveSyncQueue();
    });

    tearDown(() {
      queue.dispose();
    });

    test('enqueue and peek returns items in FIFO order', () async {
      final item1 = SyncQueueItem(
        id: 'sync_1',
        entityType: 'complaint',
        entityId: 'cmp_1',
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );

      final item2 = SyncQueueItem(
        id: 'sync_2',
        entityType: 'complaint',
        entityId: 'cmp_2',
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
      );

      await queue.enqueue(item2);
      await queue.enqueue(item1);

      final peeked = await queue.peek();
      expect(peeked, isNotNull);
      expect(peeked!.id, equals('sync_1'));
    });

    test('updateStatus updates item state in queue', () async {
      final item = SyncQueueItem(
        id: 'sync_update_test',
        entityType: 'complaint',
        entityId: 'cmp_100',
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
      );

      await queue.enqueue(item);
      await queue.updateStatus(
        'sync_update_test',
        SyncQueueStatus.processing,
      );

      final all = await queue.getAllItems();
      final updated = all.firstWhere((i) => i.id == 'sync_update_test');
      expect(updated.status, equals(SyncQueueStatus.processing));
    });

    test('recordAttempt updates attempt count, lastAttemptAt, and errorMessage', () async {
      final item = SyncQueueItem(
        id: 'sync_attempt_test',
        entityType: 'complaint',
        entityId: 'cmp_200',
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
      );

      await queue.enqueue(item);
      final attemptTime = DateTime.now();
      await queue.recordAttempt(
        'sync_attempt_test',
        attemptCount: 2,
        lastAttemptAt: attemptTime,
        errorMessage: 'Network connection dropped',
        newStatus: SyncQueueStatus.pending,
      );

      final all = await queue.getAllItems();
      final updated = all.firstWhere((i) => i.id == 'sync_attempt_test');
      expect(updated.attemptCount, equals(2));
      expect(updated.errorMessage, equals('Network connection dropped'));
      expect(updated.lastAttemptAt, isNotNull);
      expect(updated.status, equals(SyncQueueStatus.pending));
    });

    test('dequeue and remove deletes item from queue', () async {
      final item = SyncQueueItem(
        id: 'sync_delete_test',
        entityType: 'complaint',
        entityId: 'cmp_300',
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
      );

      await queue.enqueue(item);
      expect((await queue.getAllItems()).length, equals(1));

      await queue.dequeue('sync_delete_test');
      expect((await queue.getAllItems()).length, equals(0));
    });

    test('hasPendingEntity prevents duplicate sync items', () async {
      final item = SyncQueueItem(
        id: 'sync_dup_1',
        entityType: 'complaint',
        entityId: 'cmp_400',
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
      );

      await queue.enqueue(item);

      final hasPending = await queue.hasPendingEntity(
        'complaint',
        'cmp_400',
        SyncOperation.createComplaint,
      );
      expect(hasPending, isTrue);

      final hasOther = await queue.hasPendingEntity(
        'complaint',
        'cmp_999',
        SyncOperation.createComplaint,
      );
      expect(hasOther, isFalse);
    });

    test('watchQueue emits updated queue items on changes', () async {
      final streamExpectation = expectLater(
        queue.watchQueue(),
        emits(isA<List<SyncQueueItem>>()),
      );

      final item = SyncQueueItem(
        id: 'sync_stream_test',
        entityType: 'complaint',
        entityId: 'cmp_500',
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
      );

      await queue.enqueue(item);
      await streamExpectation;
    });
  });
}
