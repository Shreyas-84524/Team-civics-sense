import 'package:flutter/foundation.dart';
import '../models/sync_queue_item.dart';

/// Structured log entry capturing synchronization events.
class SyncLogEntry {
  final DateTime timestamp;
  final String level; // 'INFO' | 'WARN' | 'ERROR' | 'DEBUG'
  final String message;
  final String? itemId;
  final String? operation;
  final Map<String, dynamic>? metadata;

  SyncLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.itemId,
    this.operation,
    this.metadata,
  });

  @override
  String toString() {
    final itemInfo = itemId != null ? ' [$itemId | $operation]' : '';
    return '[SyncLogger] [${timestamp.toIso8601String()}] [$level]$itemInfo: $message';
  }
}

/// Centralized structured logger for CivicFix synchronization engine.
class SyncLogger {
  static final SyncLogger instance = SyncLogger._internal();
  factory SyncLogger() => instance;
  SyncLogger._internal();

  final List<SyncLogEntry> _history = [];
  static const int _maxHistory = 200;

  List<SyncLogEntry> get history => List.unmodifiable(_history);

  void info(String message, {String? itemId, String? operation, Map<String, dynamic>? metadata}) {
    _log('INFO', message, itemId: itemId, operation: operation, metadata: metadata);
  }

  void warning(String message, {String? itemId, String? operation, Map<String, dynamic>? metadata}) {
    _log('WARN', message, itemId: itemId, operation: operation, metadata: metadata);
  }

  void error(String message, {String? itemId, String? operation, dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    final fullMessage = error != null ? '$message | error: $error' : message;
    _log('ERROR', fullMessage, itemId: itemId, operation: operation, metadata: metadata);
  }

  void logEnqueued(SyncQueueItem item) {
    info(
      'Enqueued sync task: ${item.operation.key} for ${item.entityType} ${item.entityId}',
      itemId: item.id,
      operation: item.operation.key,
    );
  }

  void logProcessing(SyncQueueItem item) {
    info(
      'Processing sync task (attempt #${item.attemptCount + 1}): ${item.operation.key}',
      itemId: item.id,
      operation: item.operation.key,
    );
  }

  void logSuccess(SyncQueueItem item, {String? serverId}) {
    info(
      'Successfully synchronized: ${item.operation.key}${serverId != null ? ' -> serverId: $serverId' : ''}',
      itemId: item.id,
      operation: item.operation.key,
      metadata: serverId != null ? {'serverId': serverId} : null,
    );
  }

  void logFailed(SyncQueueItem item, String error, {bool willRetry = false, Duration? retryDelay}) {
    warning(
      'Sync task failed: $error (attempt #${item.attemptCount})${willRetry ? ' [Will retry in ${retryDelay?.inSeconds ?? 0}s]' : ' [Max retries exhausted]'}',
      itemId: item.id,
      operation: item.operation.key,
      metadata: {
        'error': error,
        'willRetry': willRetry,
        'retryDelaySeconds': retryDelay?.inSeconds,
      },
    );
  }

  void _log(
    String level,
    String message, {
    String? itemId,
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    final entry = SyncLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      itemId: itemId,
      operation: operation,
      metadata: metadata,
    );

    _history.add(entry);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    debugPrint(entry.toString());
  }

  void clearLogs() {
    _history.clear();
  }
}
