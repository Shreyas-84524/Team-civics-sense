import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../local/hive/hive_boxes.dart';
import '../../local/hive/hive_storage_service.dart';
import '../../local/local_storage_service.dart';
import '../../local/models/pending_sync_local_model.dart';
import '../models/sync_queue_item.dart';

/// Abstract contract for the persistent synchronization queue.
abstract class SyncQueue {
  /// Add a sync task item to the persistent queue.
  Future<void> enqueue(SyncQueueItem item);

  /// Retrieve the next pending item in FIFO order, or null if empty.
  Future<SyncQueueItem?> peek();

  /// Retrieve all items currently in [SyncQueueStatus.pending] state.
  Future<List<SyncQueueItem>> getPendingItems();

  /// Retrieve all items in the queue across all statuses.
  Future<List<SyncQueueItem>> getAllItems();

  /// Update the lifecycle status and optional error message of a queue item.
  Future<void> updateStatus(
    String itemId,
    SyncQueueStatus status, {
    String? errorMessage,
  });

  /// Record an execution attempt, updating attempt count, timestamp, and error message.
  Future<void> recordAttempt(
    String itemId, {
    required int attemptCount,
    required DateTime lastAttemptAt,
    String? errorMessage,
    SyncQueueStatus? newStatus,
  });

  /// Mark an item as completed and/or remove it from persistent queue.
  Future<void> dequeue(String itemId);

  /// Hard remove an item from the queue by ID.
  Future<void> remove(String itemId);

  /// Remove all completed or pruned items from the queue.
  Future<void> clearCompleted();

  /// Check if an identical operation is already queued for an entity (deduplication).
  Future<bool> hasPendingEntity(
    String entityType,
    String entityId,
    SyncOperation operation,
  );

  /// Stream of queue items emitted whenever the queue state changes.
  Stream<List<SyncQueueItem>> watchQueue();

  /// Dispose any active stream controllers.
  void dispose();
}

/// Hive-backed implementation of [SyncQueue] with in-memory fallback for test isolation.
class HiveSyncQueue implements SyncQueue {
  final LocalStorageService _storage;
  final StreamController<List<SyncQueueItem>> _queueStreamController =
      StreamController<List<SyncQueueItem>>.broadcast();

  // In-memory fallback for test environments or when Hive is uninitialized
  final Map<String, SyncQueueItem> _memoryFallback = {};

  HiveSyncQueue({LocalStorageService? storage})
      : _storage = storage ?? HiveStorageService.instance;

  @override
  Future<void> enqueue(SyncQueueItem item) async {
    _memoryFallback[item.id] = item;

    if (_storage.isInitialized) {
      try {
        final localModel = item.toLocalModel();
        await _storage.put<PendingSyncLocalModel>(
          HiveBoxes.pendingSync,
          item.id,
          localModel,
        );
      } catch (e) {
        debugPrint('Warning: HiveSyncQueue.enqueue fallback to memory: $e');
      }
    }

    _notifyQueueChanged();
  }

  @override
  Future<SyncQueueItem?> peek() async {
    final pending = await getPendingItems();
    return pending.isNotEmpty ? pending.first : null;
  }

  @override
  Future<List<SyncQueueItem>> getPendingItems() async {
    final all = await getAllItems();
    return all
        .where((item) =>
            item.status == SyncQueueStatus.pending ||
            item.status == SyncQueueStatus.processing)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<List<SyncQueueItem>> getAllItems() async {
    if (_storage.isInitialized) {
      try {
        final stored = await _storage.getAll<PendingSyncLocalModel>(HiveBoxes.pendingSync);
        if (stored.isNotEmpty) {
          final items = stored.map(SyncQueueItem.fromLocalModel).toList();
          items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return items;
        }
      } catch (e) {
        debugPrint('Warning: HiveSyncQueue.getAllItems fallback to memory: $e');
      }
    }

    final list = _memoryFallback.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<void> updateStatus(
    String itemId,
    SyncQueueStatus status, {
    String? errorMessage,
  }) async {
    if (_storage.isInitialized) {
      try {
        final stored = await _storage.get<PendingSyncLocalModel>(
          HiveBoxes.pendingSync,
          itemId,
        );
        if (stored != null) {
          final updated = stored.copyWith(
            syncStatus: status.name,
            lastError: errorMessage ?? stored.lastError,
          );
          await _storage.put<PendingSyncLocalModel>(
            HiveBoxes.pendingSync,
            itemId,
            updated,
          );
        }
      } catch (e) {
        debugPrint('Warning: HiveSyncQueue.updateStatus fallback to memory: $e');
      }
    }

    if (_memoryFallback.containsKey(itemId)) {
      final current = _memoryFallback[itemId]!;
      _memoryFallback[itemId] = current.copyWith(
        status: status,
        errorMessage: errorMessage ?? current.errorMessage,
      );
    }

    _notifyQueueChanged();
  }

  @override
  Future<void> recordAttempt(
    String itemId, {
    required int attemptCount,
    required DateTime lastAttemptAt,
    String? errorMessage,
    SyncQueueStatus? newStatus,
  }) async {
    if (_storage.isInitialized) {
      try {
        final stored = await _storage.get<PendingSyncLocalModel>(
          HiveBoxes.pendingSync,
          itemId,
        );
        if (stored != null) {
          final updated = stored.copyWith(
            retryCount: attemptCount,
            lastAttemptAtEpochMs: lastAttemptAt.millisecondsSinceEpoch,
            lastError: errorMessage ?? stored.lastError,
            syncStatus: newStatus?.name ?? stored.syncStatus,
          );
          await _storage.put<PendingSyncLocalModel>(
            HiveBoxes.pendingSync,
            itemId,
            updated,
          );
        }
      } catch (e) {
        debugPrint('Warning: HiveSyncQueue.recordAttempt fallback to memory: $e');
      }
    }

    if (_memoryFallback.containsKey(itemId)) {
      final current = _memoryFallback[itemId]!;
      _memoryFallback[itemId] = current.copyWith(
        attemptCount: attemptCount,
        lastAttemptAt: lastAttemptAt,
        errorMessage: errorMessage ?? current.errorMessage,
        status: newStatus ?? current.status,
      );
    }

    _notifyQueueChanged();
  }

  @override
  Future<void> dequeue(String itemId) async {
    await remove(itemId);
  }

  @override
  Future<void> remove(String itemId) async {
    if (_storage.isInitialized) {
      try {
        await _storage.delete(HiveBoxes.pendingSync, itemId);
      } catch (e) {
        debugPrint('Warning: HiveSyncQueue.remove fallback: $e');
      }
    }

    _memoryFallback.remove(itemId);
    _notifyQueueChanged();
  }

  @override
  Future<void> clearCompleted() async {
    if (_storage.isInitialized) {
      try {
        final all = await _storage.getAll<PendingSyncLocalModel>(HiveBoxes.pendingSync);
        for (final item in all) {
          if (item.syncStatus == SyncQueueStatus.completed.name) {
            await _storage.delete(HiveBoxes.pendingSync, item.id);
          }
        }
      } catch (e) {
        debugPrint('Warning: HiveSyncQueue.clearCompleted error: $e');
      }
    }

    _memoryFallback.removeWhere((_, item) => item.status == SyncQueueStatus.completed);
    _notifyQueueChanged();
  }

  @override
  Future<bool> hasPendingEntity(
    String entityType,
    String entityId,
    SyncOperation operation,
  ) async {
    final pending = await getPendingItems();
    return pending.any(
      (item) =>
          item.entityType == entityType &&
          item.entityId == entityId &&
          item.operation == operation &&
          item.status != SyncQueueStatus.completed,
    );
  }

  @override
  Stream<List<SyncQueueItem>> watchQueue() => _queueStreamController.stream;

  void _notifyQueueChanged() {
    if (!_queueStreamController.isClosed) {
      getAllItems().then((items) {
        if (!_queueStreamController.isClosed) {
          _queueStreamController.add(items);
        }
      });
    }
  }

  @override
  void dispose() {
    _queueStreamController.close();
  }
}
