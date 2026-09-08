import 'dart:convert';
import '../../local/models/pending_sync_local_model.dart';

/// Supported synchronization operations in the offline queue.
enum SyncOperation {
  createComplaint,
  updateComplaint,
  upvoteComplaint,
  uploadEvidence,
  deleteComplaint;

  String get key {
    switch (this) {
      case SyncOperation.createComplaint:
        return 'create_complaint';
      case SyncOperation.updateComplaint:
        return 'update_complaint';
      case SyncOperation.upvoteComplaint:
        return 'upvote_complaint';
      case SyncOperation.uploadEvidence:
        return 'upload_evidence';
      case SyncOperation.deleteComplaint:
        return 'delete_complaint';
    }
  }

  static SyncOperation fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'create_complaint':
      case 'create':
        return SyncOperation.createComplaint;
      case 'update_complaint':
      case 'update':
        return SyncOperation.updateComplaint;
      case 'upvote_complaint':
      case 'upvote':
        return SyncOperation.upvoteComplaint;
      case 'upload_evidence':
      case 'evidence':
        return SyncOperation.uploadEvidence;
      case 'delete_complaint':
      case 'delete':
        return SyncOperation.deleteComplaint;
      default:
        return SyncOperation.createComplaint;
    }
  }
}

/// Lifecycle status of an item within the offline synchronization queue.
/// 
/// Note: Decoupled from complaint domain status and complaint syncStatus.
enum SyncQueueStatus {
  pending,
  processing,
  completed,
  failed;

  static SyncQueueStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return SyncQueueStatus.pending;
      case 'processing':
      case 'syncing':
        return SyncQueueStatus.processing;
      case 'completed':
      case 'synced':
        return SyncQueueStatus.completed;
      case 'failed':
        return SyncQueueStatus.failed;
      default:
        return SyncQueueStatus.pending;
    }
  }
}

/// Represents an atomic, persistent unit of work queued for synchronization.
class SyncQueueItem {
  final String id;
  final String entityType; // e.g. 'complaint', 'upvote', 'evidence'
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final SyncQueueStatus status;
  final String? errorMessage;
  final String? idempotencyKey;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload = const {},
    required this.createdAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.status = SyncQueueStatus.pending,
    this.errorMessage,
    this.idempotencyKey,
  });

  /// Generate a consistent idempotency key for this sync operation.
  String get effectiveIdempotencyKey =>
      idempotencyKey ?? '${entityType}_${entityId}_${operation.key}';

  /// Convert to Hive persistence model [PendingSyncLocalModel].
  PendingSyncLocalModel toLocalModel() {
    return PendingSyncLocalModel(
      id: id,
      entityType: entityType,
      entityId: entityId,
      action: operation.key,
      payloadJson: jsonEncode(payload),
      createdAtEpochMs: createdAt.millisecondsSinceEpoch,
      retryCount: attemptCount,
      lastAttemptAtEpochMs: lastAttemptAt?.millisecondsSinceEpoch,
      lastError: errorMessage,
      syncStatus: status.name,
      idempotencyKey: effectiveIdempotencyKey,
    );
  }

  /// Factory constructor to reconstruct from Hive persistence model.
  factory SyncQueueItem.fromLocalModel(PendingSyncLocalModel local) {
    Map<String, dynamic> decodedPayload = {};
    try {
      if (local.payloadJson.isNotEmpty) {
        decodedPayload = Map<String, dynamic>.from(jsonDecode(local.payloadJson) as Map);
      }
    } catch (_) {
      decodedPayload = {};
    }

    final resolvedEntityId = local.entityId.isNotEmpty
        ? local.entityId
        : (decodedPayload['id'] as String? ?? local.id.replaceFirst('sync_', ''));

    return SyncQueueItem(
      id: local.id,
      entityType: local.entityType,
      entityId: resolvedEntityId,
      operation: SyncOperation.fromKey(local.action),
      payload: decodedPayload,
      createdAt: DateTime.fromMillisecondsSinceEpoch(local.createdAtEpochMs),
      attemptCount: local.retryCount,
      lastAttemptAt: local.lastAttemptAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(local.lastAttemptAtEpochMs!)
          : null,
      status: SyncQueueStatus.fromString(local.syncStatus),
      errorMessage: local.lastError,
      idempotencyKey: local.idempotencyKey,
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attemptCount,
    DateTime? lastAttemptAt,
    SyncQueueStatus? status,
    String? errorMessage,
    String? idempotencyKey,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}
