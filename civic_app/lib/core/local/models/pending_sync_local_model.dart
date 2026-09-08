/// Local persistence model representing an item queued for synchronization.
class PendingSyncLocalModel {
  final String id;
  final String entityType; // 'complaint' | 'upvote' | 'status_update' | 'user_profile' | 'evidence'
  final String entityId;
  final String action; // 'create' | 'update' | 'delete' | 'upload_evidence' | 'upvote'
  final String payloadJson;
  final int createdAtEpochMs;
  final int retryCount;
  final int? lastAttemptAtEpochMs;
  final String? lastError;
  final String syncStatus; // 'pending' | 'processing' | 'completed' | 'failed'
  final String? idempotencyKey;

  const PendingSyncLocalModel({
    required this.id,
    required this.entityType,
    this.entityId = '',
    required this.action,
    required this.payloadJson,
    required this.createdAtEpochMs,
    this.retryCount = 0,
    this.lastAttemptAtEpochMs,
    this.lastError,
    this.syncStatus = 'pending',
    this.idempotencyKey,
  });

  PendingSyncLocalModel copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    String? payloadJson,
    int? createdAtEpochMs,
    int? retryCount,
    int? lastAttemptAtEpochMs,
    String? lastError,
    String? syncStatus,
    String? idempotencyKey,
  }) {
    return PendingSyncLocalModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAtEpochMs: lastAttemptAtEpochMs ?? this.lastAttemptAtEpochMs,
      lastError: lastError ?? this.lastError,
      syncStatus: syncStatus ?? this.syncStatus,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}
