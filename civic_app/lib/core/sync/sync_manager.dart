import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/complaint_model.dart';
import '../network/connectivity_service.dart';
import '../repositories/complaint_repository.dart';
import '../repositories/hive_complaint_repository.dart';
import 'logging/sync_logger.dart';
import 'models/sync_queue_item.dart';
import 'providers/mock_sync_provider.dart';
import 'providers/sync_provider.dart';
import 'queue/sync_queue.dart';
import 'retry/retry_policy.dart';

/// Snapshot of the synchronization engine state for UI reactivity.
class SyncManagerState {
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncManagerState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  SyncManagerState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncManagerState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Central orchestrator for offline synchronization in CivicFix.
class SyncManager {
  static SyncManager? _instance;

  final SyncQueue _queue;
  final SyncProvider _provider;
  final ConnectivityService _connectivity;
  final ComplaintRepository _repository;
  final RetryPolicy _retryPolicy;
  final SyncLogger _logger;

  bool _isProcessingQueue = false;
  final Set<String> _inFlightKeys = {};
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<SyncQueueItem>>? _queueSubscription;

  final StreamController<SyncManagerState> _stateController =
      StreamController<SyncManagerState>.broadcast();
  SyncManagerState _currentState = const SyncManagerState();

  factory SyncManager({
    SyncQueue? queue,
    SyncProvider? provider,
    ConnectivityService? connectivity,
    ComplaintRepository? repository,
    RetryPolicy? retryPolicy,
    SyncLogger? logger,
  }) {
    _instance ??= SyncManager._internal(
      queue: queue ?? HiveSyncQueue(),
      provider: provider ?? MockSyncProvider(),
      connectivity: connectivity ?? AppConnectivityService(),
      repository: repository ?? HiveComplaintRepository(),
      retryPolicy: retryPolicy ?? RetryPolicy(),
      logger: logger ?? SyncLogger.instance,
    );
    return _instance!;
  }

  SyncManager._internal({
    required SyncQueue queue,
    required SyncProvider provider,
    required ConnectivityService connectivity,
    required ComplaintRepository repository,
    required RetryPolicy retryPolicy,
    required SyncLogger logger,
  })  : _queue = queue,
        _provider = provider,
        _connectivity = connectivity,
        _repository = repository,
        _retryPolicy = retryPolicy,
        _logger = logger {
    _initListeners();
  }

  /// Factory for creating isolated test instances without polluting singleton.
  @visibleForTesting
  factory SyncManager.createForTesting({
    required SyncQueue queue,
    required SyncProvider provider,
    required ConnectivityService connectivity,
    required ComplaintRepository repository,
    RetryPolicy? retryPolicy,
    SyncLogger? logger,
  }) {
    return SyncManager._internal(
      queue: queue,
      provider: provider,
      connectivity: connectivity,
      repository: repository,
      retryPolicy: retryPolicy ?? RetryPolicy(),
      logger: logger ?? SyncLogger.instance,
    );
  }

  @visibleForTesting
  static void resetInstanceForTesting() {
    _instance?.dispose();
    _instance = null;
  }

  SyncQueue get queue => _queue;
  SyncProvider get provider => _provider;
  ConnectivityService get connectivity => _connectivity;
  ComplaintRepository get repository => _repository;
  RetryPolicy get retryPolicy => _retryPolicy;
  SyncLogger get logger => _logger;
  SyncManagerState get currentState => _currentState;
  Stream<SyncManagerState> get syncStateStream => _stateController.stream;
  bool get isProcessing => _isProcessingQueue;

  void _initListeners() {
    // Listen to network changes: auto-sync when transitioning from offline -> online
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        _logger.info('Network restored (ONLINE). Triggering automatic queue synchronization.');
        processQueue();
      } else {
        _logger.info('Network dropped (OFFLINE). Pausing active queue operations.');
      }
    });

    // Listen to queue changes to refresh state counts
    _queueSubscription = _queue.watchQueue().listen((items) {
      _updateCountsFromItems(items);
    });

    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    final all = await _queue.getAllItems();
    _updateCountsFromItems(all);
  }

  void _updateCountsFromItems(List<SyncQueueItem> items) {
    final pending = items.where((i) => i.status == SyncQueueStatus.pending || i.status == SyncQueueStatus.processing).length;
    final failed = items.where((i) => i.status == SyncQueueStatus.failed).length;

    _currentState = _currentState.copyWith(
      pendingCount: pending,
      failedCount: failed,
      isSyncing: _isProcessingQueue,
    );
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  /// Enqueue a complaint for synchronization.
  Future<void> queueComplaintCreation(ComplaintModel complaint) async {
    final syncItem = SyncQueueItem(
      id: 'sync_${complaint.id}',
      entityType: 'complaint',
      entityId: complaint.id,
      operation: SyncOperation.createComplaint,
      payload: {
        'id': complaint.id,
        'localId': complaint.localId ?? complaint.id,
        'ticketNumber': complaint.ticketNumber,
        'citizenId': complaint.citizenId,
        'title': complaint.title,
        'description': complaint.description,
        'categoryId': complaint.category.id,
        'categoryName': complaint.category.name,
        'categoryDescription': complaint.category.description,
        'priority': complaint.priority.name,
        'isHazard': complaint.isHazard,
        'latitude': complaint.location.latitude,
        'longitude': complaint.location.longitude,
        'address': complaint.location.address,
        'landmark': complaint.location.landmark,
        'ward': complaint.location.ward,
        'imageUrls': complaint.imageUrls,
        'createdAt': complaint.createdAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
      status: SyncQueueStatus.pending,
    );

    _logger.logEnqueued(syncItem);
    await _queue.enqueue(syncItem);

    // If online, immediately process queue
    if (_connectivity.isOnline) {
      await processQueue();
    }
  }

  /// Process pending items in the synchronization queue.
  Future<void> processQueue() async {
    // Mutex lock check
    if (_isProcessingQueue) {
      _logger.info('SyncManager is already processing queue. Skipping concurrent execution.');
      return;
    }

    if (!_connectivity.isOnline) {
      _logger.info('Device is offline. Queue processing deferred.');
      return;
    }

    _isProcessingQueue = true;
    _currentState = _currentState.copyWith(isSyncing: true);
    if (!_stateController.isClosed) _stateController.add(_currentState);

    try {
      final pendingItems = await _queue.getPendingItems();

      for (final item in pendingItems) {
        if (!_connectivity.isOnline) break;

        final idempotencyKey = item.effectiveIdempotencyKey;
        if (_inFlightKeys.contains(idempotencyKey)) {
          // Skip if already in flight
          continue;
        }

        _inFlightKeys.add(idempotencyKey);

        try {
          await _processSingleItem(item);
        } finally {
          _inFlightKeys.remove(idempotencyKey);
        }
      }
    } catch (e, st) {
      _logger.error('Unexpected error processing sync queue', error: e, stackTrace: st);
    } finally {
      _isProcessingQueue = false;
      _currentState = _currentState.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
      );
      if (!_stateController.isClosed) _stateController.add(_currentState);
      await _refreshCounts();
    }
  }

  Future<void> _processSingleItem(SyncQueueItem item) async {
    _logger.logProcessing(item);

    // 1. Update queue status to processing
    await _queue.updateStatus(item.id, SyncQueueStatus.processing);

    // 2. Update complaint syncStatus to syncing if entity is complaint
    if (item.entityType == 'complaint') {
      await _repository.updateSyncStatus(item.entityId, SyncStatus.syncing);
    }

    // 3. Execute via provider
    final result = await _provider.execute(item);

    if (result.isSuccess) {
      // Success handling
      _logger.logSuccess(item, serverId: result.serverId);

      if (item.entityType == 'complaint') {
        await _repository.updateSyncStatus(
          item.entityId,
          SyncStatus.synced,
          serverId: result.serverId,
        );
      }

      // Handle partial failure (complaint synced, but evidence upload failed)
      if (result.isPartialFailure && result.failedImageUrls.isNotEmpty) {
        _logger.warning(
          'Partial sync: Complaint synced, but ${result.failedImageUrls.length} images failed. Queueing evidence upload retry.',
          itemId: item.id,
        );

        final evidenceItem = SyncQueueItem(
          id: 'evidence_${item.entityId}_${DateTime.now().millisecondsSinceEpoch}',
          entityType: 'evidence',
          entityId: item.entityId,
          operation: SyncOperation.uploadEvidence,
          payload: {
            'complaintId': item.entityId,
            'serverId': result.serverId,
            'imageUrls': result.failedImageUrls,
          },
          createdAt: DateTime.now(),
          status: SyncQueueStatus.pending,
        );
        await _queue.enqueue(evidenceItem);
      }

      // Dequeue completed item
      await _queue.dequeue(item.id);
    } else {
      // Failure handling
      final newAttemptCount = item.attemptCount + 1;
      final willRetry = _retryPolicy.shouldRetry(newAttemptCount);
      final delay = willRetry ? _retryPolicy.getDelay(newAttemptCount) : null;

      _logger.logFailed(item, result.errorMessage ?? 'Sync failed', willRetry: willRetry, retryDelay: delay);

      if (willRetry) {
        await _queue.recordAttempt(
          item.id,
          attemptCount: newAttemptCount,
          lastAttemptAt: DateTime.now(),
          errorMessage: result.errorMessage,
          newStatus: SyncQueueStatus.pending,
        );

        if (item.entityType == 'complaint') {
          await _repository.updateSyncStatus(item.entityId, SyncStatus.pending);
        }
      } else {
        // Max retries exhausted -> mark as failed
        await _queue.recordAttempt(
          item.id,
          attemptCount: newAttemptCount,
          lastAttemptAt: DateTime.now(),
          errorMessage: result.errorMessage ?? 'Max retries exhausted',
          newStatus: SyncQueueStatus.failed,
        );

        if (item.entityType == 'complaint') {
          await _repository.updateSyncStatus(item.entityId, SyncStatus.failed);
        }
      }
    }
  }

  /// Manually retry all items in the queue that have failed.
  Future<void> retryFailed() async {
    final all = await _queue.getAllItems();
    final failedItems = all.where((i) => i.status == SyncQueueStatus.failed).toList();

    _logger.info('Retrying ${failedItems.length} failed sync tasks.');

    for (final item in failedItems) {
      await _queue.recordAttempt(
        item.id,
        attemptCount: 0,
        lastAttemptAt: DateTime.now(),
        newStatus: SyncQueueStatus.pending,
      );
      if (item.entityType == 'complaint') {
        await _repository.updateSyncStatus(item.entityId, SyncStatus.pending);
      }
    }

    if (_connectivity.isOnline) {
      await processQueue();
    }
  }

  /// Manually retry a specific complaint synchronization.
  Future<void> retryComplaint(String complaintId) async {
    final all = await _queue.getAllItems();
    final item = all.firstWhere(
      (i) => i.entityId == complaintId || i.id == 'sync_$complaintId',
      orElse: () => SyncQueueItem(
        id: 'sync_$complaintId',
        entityType: 'complaint',
        entityId: complaintId,
        operation: SyncOperation.createComplaint,
        createdAt: DateTime.now(),
      ),
    );

    await _queue.recordAttempt(
      item.id,
      attemptCount: 0,
      lastAttemptAt: DateTime.now(),
      newStatus: SyncQueueStatus.pending,
    );
    await _repository.updateSyncStatus(complaintId, SyncStatus.pending);

    if (_connectivity.isOnline) {
      await processQueue();
    }
  }

  /// Clear all items from queue.
  Future<void> clearQueue() async {
    final all = await _queue.getAllItems();
    for (final item in all) {
      await _queue.remove(item.id);
    }
    await _refreshCounts();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _queueSubscription?.cancel();
    _stateController.close();
    _queue.dispose();
  }
}
