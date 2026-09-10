import 'dart:async';
import 'logging/sync_logger.dart';

/// Centralized manager for active real-time Firestore stream subscriptions.
///
/// Ensures clean lifecycle management, prevents memory leaks, and enables
/// automatic subscription teardown upon citizen or government logout.
class RealtimeSubscriptionManager {
  static final RealtimeSubscriptionManager _instance =
      RealtimeSubscriptionManager._internal();
  static RealtimeSubscriptionManager get instance => _instance;

  RealtimeSubscriptionManager({SyncLogger? logger})
      : _logger = logger ?? SyncLogger.instance;

  RealtimeSubscriptionManager._internal() : _logger = SyncLogger.instance;

  final SyncLogger _logger;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, String> _subscriptionGroups = {};

  /// Registers an active subscription with a unique key and optional group tag.
  /// If a subscription with the same key already exists, it is cancelled first.
  void register(
    String key,
    StreamSubscription subscription, {
    String? group,
  }) {
    if (_subscriptions.containsKey(key)) {
      _logger.debug('Replacing existing subscription for key: $key');
      cancel(key);
    }

    _subscriptions[key] = subscription;
    if (group != null) {
      _subscriptionGroups[key] = group;
    }
    _logger.debug('Registered real-time subscription: $key (group: $group, total active: ${_subscriptions.length})');
  }

  /// Cancels an individual subscription by its unique key.
  Future<void> cancel(String key) async {
    final sub = _subscriptions.remove(key);
    _subscriptionGroups.remove(key);
    if (sub != null) {
      try {
        await sub.cancel();
        _logger.debug('Cancelled subscription: $key (remaining active: ${_subscriptions.length})');
      } catch (e) {
        _logger.warning('Error cancelling subscription $key: $e');
      }
    }
  }

  /// Cancels all subscriptions belonging to a specific group (e.g., 'user_123' or 'dept_pwd').
  Future<void> cancelGroup(String group) async {
    final keysToCancel = _subscriptionGroups.entries
        .where((entry) => entry.value == group)
        .map((entry) => entry.key)
        .toList();

    for (final key in keysToCancel) {
      await cancel(key);
    }
    _logger.info('Cancelled all subscriptions for group: $group (${keysToCancel.length} cancelled)');
  }

  /// Cancels all active subscriptions. Called automatically on user logout / auth teardown.
  Future<void> cancelAll() async {
    final total = _subscriptions.length;
    final keys = _subscriptions.keys.toList();
    for (final key in keys) {
      final sub = _subscriptions.remove(key);
      if (sub != null) {
        try {
          await sub.cancel();
        } catch (e) {
          _logger.warning('Error cancelling subscription during cancelAll ($key): $e');
        }
      }
    }
    _subscriptionGroups.clear();
    _logger.info('RealtimeSubscriptionManager cancelled all active subscriptions ($total cancelled)');
  }

  /// Returns true if a subscription with the given key is currently registered.
  bool contains(String key) => _subscriptions.containsKey(key);

  /// Returns total count of currently active subscriptions.
  int get activeSubscriptionCount => _subscriptions.length;

  /// Returns an unmodifiable list of active subscription keys.
  List<String> get activeKeys => List.unmodifiable(_subscriptions.keys);
}
