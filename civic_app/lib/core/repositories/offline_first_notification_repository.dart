import 'dart:async';
import 'package:flutter/foundation.dart';
import '../firebase/firestore/firebase_notification_data_source.dart';
import '../models/notification_model.dart';
import '../network/connectivity_service.dart';
import 'hive_notification_repository.dart';
import 'notification_repository.dart';

/// Offline-first cache-aware repository for managing citizen notifications.
class OfflineFirstNotificationRepository implements NotificationRepository {
  final HiveNotificationRepository _localRepo;
  final FirebaseNotificationDataSource _remoteDataSource;
  final ConnectivityService _connectivity;

  OfflineFirstNotificationRepository({
    HiveNotificationRepository? localRepository,
    FirebaseNotificationDataSource? remoteDataSource,
    ConnectivityService? connectivity,
  })  : _localRepo = localRepository ?? HiveNotificationRepository(),
        _remoteDataSource = remoteDataSource ?? FirebaseNotificationDataSource(),
        _connectivity = connectivity ?? AppConnectivityService();

  @override
  ValueListenable<int> get unreadCountListenable => _localRepo.unreadCountListenable;

  @override
  Future<List<NotificationModel>> getNotifications({
    String? userId,
    bool? unreadOnly,
    NotificationType? type,
  }) async {
    // 1. Return cached notifications immediately
    final localList = await _localRepo.getNotifications(
      userId: userId,
      unreadOnly: unreadOnly,
      type: type,
    );

    // 2. If online and userId provided, sync remote notifications
    if (_connectivity.isOnline && userId != null && userId.isNotEmpty) {
      try {
        final remotePage = await _remoteDataSource.getUserNotifications(
          userId: userId,
          unreadOnly: unreadOnly,
          limit: 50,
        );

        if (remotePage.items.isNotEmpty) {
          await _localRepo.cacheNotifications(remotePage.items);
          final refreshed = await _localRepo.getNotifications(
            userId: userId,
            unreadOnly: unreadOnly,
            type: type,
          );
          return refreshed;
        }
      } catch (e) {
        debugPrint('[OfflineFirstNotificationRepository] Remote notifications fetch failed (using cache): $e');
      }
    }

    return localList;
  }

  @override
  Future<void> markAsRead(String id) async {
    // 1. Update local cache immediately
    await _localRepo.markAsRead(id);

    // 2. If online, sync to Cloud Firestore
    if (_connectivity.isOnline) {
      try {
        await _remoteDataSource.markAsRead(id);
      } catch (e) {
        debugPrint('[OfflineFirstNotificationRepository] Remote markAsRead failed: $e');
      }
    }
  }

  @override
  Future<void> markAllAsRead({String? userId}) async {
    // 1. Update local cache immediately
    await _localRepo.markAllAsRead(userId: userId);

    // 2. If online, sync to Cloud Firestore
    if (_connectivity.isOnline && userId != null && userId.isNotEmpty) {
      try {
        await _remoteDataSource.markAllAsRead(userId);
      } catch (e) {
        debugPrint('[OfflineFirstNotificationRepository] Remote markAllAsRead failed: $e');
      }
    }
  }

  @override
  Future<int> getUnreadCount({String? userId}) async {
    if (_connectivity.isOnline && userId != null && userId.isNotEmpty) {
      try {
        return await _remoteDataSource.getUnreadCount(userId);
      } catch (_) {}
    }
    return _localRepo.getUnreadCount(userId: userId);
  }

  // ===========================================================================
  // REAL-TIME NOTIFICATION STREAMS (Prompt 8)
  // ===========================================================================

  @override
  Stream<List<NotificationModel>> watchNotifications({
    String? userId,
    bool? unreadOnly,
    NotificationType? type,
  }) async* {
    final localList = await _localRepo.getNotifications(
      userId: userId,
      unreadOnly: unreadOnly,
      type: type,
    );
    yield localList;

    if (!_connectivity.isOnline || userId == null || userId.isEmpty) {
      yield* _localRepo.watchNotifications(userId: userId, unreadOnly: unreadOnly, type: type);
      return;
    }

    try {
      yield* _remoteDataSource
          .watchUserNotifications(userId: userId, unreadOnly: unreadOnly, limit: 50)
          .asyncMap((remoteList) async {
        if (remoteList.isNotEmpty) {
          await _localRepo.cacheNotifications(remoteList);
        }
        return _localRepo.getNotifications(
          userId: userId,
          unreadOnly: unreadOnly,
          type: type,
        );
      });
    } catch (e) {
      debugPrint('[OfflineFirstNotificationRepository] watchNotifications fallback: $e');
      yield* _localRepo.watchNotifications(userId: userId, unreadOnly: unreadOnly, type: type);
    }
  }

  @override
  Stream<int> watchUnreadCount({String? userId}) async* {
    final localCount = await _localRepo.getUnreadCount(userId: userId);
    yield localCount;

    if (!_connectivity.isOnline || userId == null || userId.isEmpty) {
      yield* _localRepo.watchUnreadCount(userId: userId);
      return;
    }

    try {
      yield* _remoteDataSource.watchUnreadCount(userId);
    } catch (e) {
      debugPrint('[OfflineFirstNotificationRepository] watchUnreadCount fallback: $e');
      yield* _localRepo.watchUnreadCount(userId: userId);
    }
  }
}

