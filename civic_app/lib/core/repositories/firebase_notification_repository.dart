import 'package:flutter/foundation.dart';
import '../firebase/firestore/firebase_notification_data_source.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

/// Firebase Firestore remote implementation of [NotificationRepository].
class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseNotificationDataSource _dataSource;
  final String _currentUserId;
  final ValueNotifier<int> _unreadCountNotifier;

  FirebaseNotificationRepository({
    FirebaseNotificationDataSource? dataSource,
    String currentUserId = '',
  })  : _dataSource = dataSource ?? FirebaseNotificationDataSource(),
        _currentUserId = currentUserId,
        _unreadCountNotifier = ValueNotifier<int>(0);

  @override
  ValueListenable<int> get unreadCountListenable => _unreadCountNotifier;

  @override
  Future<List<NotificationModel>> getNotifications({
    String? userId,
    bool? unreadOnly,
    NotificationType? type,
  }) async {
    final targetUserId = userId ?? _currentUserId;
    final page = await _dataSource.getUserNotifications(
      userId: targetUserId,
      unreadOnly: unreadOnly,
      limit: 50,
    );

    var list = page.items;
    if (type != null) {
      list = list.where((n) => n.type == type).toList();
    }

    await getUnreadCount(userId: targetUserId);
    return list;
  }

  @override
  Future<void> markAsRead(String id) async {
    await _dataSource.markAsRead(id);
    await getUnreadCount(userId: _currentUserId);
  }

  @override
  Future<void> markAllAsRead({String? userId}) async {
    final targetUserId = userId ?? _currentUserId;
    await _dataSource.markAllAsRead(targetUserId);
    _unreadCountNotifier.value = 0;
  }

  @override
  Future<int> getUnreadCount({String? userId}) async {
    final targetUserId = userId ?? _currentUserId;
    final count = await _dataSource.getUnreadCount(targetUserId);
    _unreadCountNotifier.value = count;
    return count;
  }

  @override
  Stream<List<NotificationModel>> watchNotifications({
    String? userId,
    bool? unreadOnly,
    NotificationType? type,
  }) {
    final targetUserId = userId ?? _currentUserId;
    return _dataSource
        .watchUserNotifications(
          userId: targetUserId,
          unreadOnly: unreadOnly,
          limit: 50,
        )
        .map((items) {
      if (type != null) {
        return items.where((n) => n.type == type).toList();
      }
      return items;
    });
  }

  @override
  Stream<int> watchUnreadCount({String? userId}) {
    final targetUserId = userId ?? _currentUserId;
    return _dataSource.watchUnreadCount(targetUserId);
  }
}

