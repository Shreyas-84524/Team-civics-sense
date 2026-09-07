import 'package:flutter/foundation.dart';
import '../local/mock_data_source.dart';
import '../models/notification_model.dart';

/// Abstract repository for managing citizen notifications.
abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({
    String? userId,
    bool? unreadOnly,
    NotificationType? type,
  });

  Future<void> markAsRead(String id);
  Future<void> markAllAsRead({String? userId});
  Future<int> getUnreadCount({String? userId});

  ValueListenable<int> get unreadCountListenable;
}

/// In-memory mock implementation of [NotificationRepository].
class MockNotificationRepository implements NotificationRepository {
  static final MockNotificationRepository _instance = MockNotificationRepository._internal();
  factory MockNotificationRepository() => _instance;
  MockNotificationRepository._internal() {
    _unreadCountNotifier.value = _calculateUnread();
  }

  final MockDataSource _dataSource = MockDataSource();
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier<int>(0);

  @override
  ValueListenable<int> get unreadCountListenable => _unreadCountNotifier;

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
    await Future.delayed(const Duration(milliseconds: 100));

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

    // Sort newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _dataSource.notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_dataSource.notifications[index].isRead) {
      _dataSource.notifications[index] = _dataSource.notifications[index].copyWith(isRead: true);
      _syncUnreadCount();
    }
  }

  @override
  Future<void> markAllAsRead({String? userId}) async {
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
