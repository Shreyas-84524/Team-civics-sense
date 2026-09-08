import 'package:flutter/foundation.dart';
import '../local/hive/hive_boxes.dart';
import '../local/hive/hive_storage_service.dart';
import '../local/local_storage_service.dart';
import '../local/mock_data_source.dart';
import '../local/models/notification_local_model.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

/// Hive-backed cache-aware repository for managing citizen notifications.
class HiveNotificationRepository implements NotificationRepository {
  final LocalStorageService _storage;
  final MockDataSource _dataSource;
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier<int>(0);
  DateTime? _lastCachedAt;

  HiveNotificationRepository({
    LocalStorageService? storage,
    MockDataSource? dataSource,
  })  : _storage = storage ?? HiveStorageService.instance,
        _dataSource = dataSource ?? MockDataSource() {
    _initFromCache();
  }

  DateTime? get lastCachedAt => _lastCachedAt;

  @override
  ValueListenable<int> get unreadCountListenable => _unreadCountNotifier;

  Future<void> _initFromCache() async {
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.getAll<NotificationLocalModel>(HiveBoxes.notifications);
        if (cached.isNotEmpty) {
          final domainList = cached.map((e) => e.toDomain()).toList();
          _dataSource.notifications
            ..clear()
            ..addAll(domainList);
          _lastCachedAt = DateTime.now();
        } else {
          // Seed with default notifications
          await cacheNotifications(_dataSource.notifications);
        }
      } catch (e) {
        debugPrint('Warning: HiveNotificationRepository failed reading cache: $e');
      }
    }
    _syncUnreadCount();
  }

  /// Bulk cache notifications from server/network snapshot into Hive.
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    if (_storage.isInitialized) {
      try {
        final Map<String, NotificationLocalModel> entries = {
          for (final n in notifications) n.id: NotificationLocalModel.fromDomain(n),
        };
        await _storage.putAll<NotificationLocalModel>(HiveBoxes.notifications, entries);
        _lastCachedAt = DateTime.now();
      } catch (e) {
        debugPrint('Warning: HiveNotificationRepository.cacheNotifications fallback: $e');
      }
    }

    _dataSource.notifications
      ..clear()
      ..addAll(notifications);
    _syncUnreadCount();
  }

  int _calculateUnread([String? userId]) {
    return _dataSource.notifications.where((n) {
      if (userId != null && n.userId != userId) return false;
      return !n.isRead;
    }).length;
  }

  void _syncUnreadCount() {
    _unreadCountNotifier.value = _calculateUnread();
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    String? userId,
    bool? unreadOnly,
    NotificationType? type,
  }) async {
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.getAll<NotificationLocalModel>(HiveBoxes.notifications);
        if (cached.isNotEmpty) {
          var list = cached.map((e) => e.toDomain()).toList();

          if (userId != null) {
            list = list.where((n) => n.userId == userId).toList();
          }
          if (unreadOnly == true) {
            list = list.where((n) => !n.isRead).toList();
          }
          if (type != null) {
            list = list.where((n) => n.type == type).toList();
          }

          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        }
      } catch (e) {
        debugPrint('Warning: HiveNotificationRepository.getNotifications reading error: $e');
      }
    }

    var list = _dataSource.notifications.toList();
    if (userId != null) {
      list = list.where((n) => n.userId == userId).toList();
    }
    if (unreadOnly == true) {
      list = list.where((n) => !n.isRead).toList();
    }
    if (type != null) {
      list = list.where((n) => n.type == type).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> markAsRead(String id) async {
    // 1. Update in Hive
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.get<NotificationLocalModel>(HiveBoxes.notifications, id);
        if (cached != null && !cached.isRead) {
          final updated = cached.copyWith(isRead: true);
          await _storage.put<NotificationLocalModel>(HiveBoxes.notifications, id, updated);
        }
      } catch (e) {
        debugPrint('Warning: HiveNotificationRepository.markAsRead storage error: $e');
      }
    }

    // 2. Update memory
    final index = _dataSource.notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_dataSource.notifications[index].isRead) {
      _dataSource.notifications[index] = _dataSource.notifications[index].copyWith(isRead: true);
      _syncUnreadCount();
    }
  }

  @override
  Future<void> markAllAsRead({String? userId}) async {
    if (_storage.isInitialized) {
      try {
        final all = await _storage.getAll<NotificationLocalModel>(HiveBoxes.notifications);
        for (final item in all) {
          if ((userId == null || item.userId == userId) && !item.isRead) {
            final updated = item.copyWith(isRead: true);
            await _storage.put<NotificationLocalModel>(HiveBoxes.notifications, updated.id, updated);
          }
        }
      } catch (e) {
        debugPrint('Warning: HiveNotificationRepository.markAllAsRead storage error: $e');
      }
    }

    bool modified = false;
    for (int i = 0; i < _dataSource.notifications.length; i++) {
      final item = _dataSource.notifications[i];
      if ((userId == null || item.userId == userId) && !item.isRead) {
        _dataSource.notifications[i] = item.copyWith(isRead: true);
        modified = true;
      }
    }
    if (modified) {
      _syncUnreadCount();
    }
  }

  @override
  Future<int> getUnreadCount({String? userId}) async {
    final count = _calculateUnread(userId);
    _unreadCountNotifier.value = count;
    return count;
  }
}
