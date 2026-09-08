import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/models/notification_model.dart';
import 'package:civic_app/core/repositories/hive_notification_repository.dart';

void main() {
  group('HiveNotificationRepository Caching Tests', () {
    late Directory tempDir;
    late HiveNotificationRepository repository;

    final testNotifications = [
      NotificationModel(
        id: 'notif_101',
        userId: 'usr_test_1',
        title: 'Issue Assigned',
        message: 'Your streetlight grievance has been assigned to EE Ward 14.',
        type: NotificationType.statusUpdate,
        complaintId: 'cmp_101',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'notif_102',
        userId: 'usr_test_1',
        title: 'Safety Alert',
        message: 'Heavy waterlogging reported near Silk Board Junction.',
        type: NotificationType.hazardAlert,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif_103',
        userId: 'usr_test_2',
        title: 'Points Earned',
        message: 'You earned 20 CivicPoints for your verified report.',
        type: NotificationType.rewardEarned,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('civic_notif_repo_test_');
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      await HiveInitializer.openEssentialBoxes();
      repository = HiveNotificationRepository();
      await repository.cacheNotifications(testNotifications);
    });

    tearDown(() async {
      await HiveInitializer.resetForTesting();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('getNotifications filters by user and unread status accurately', () async {
      final user1All = await repository.getNotifications(userId: 'usr_test_1');
      expect(user1All.length, equals(2));

      final user1Unread = await repository.getNotifications(
        userId: 'usr_test_1',
        unreadOnly: true,
      );
      expect(user1Unread.length, equals(2));

      final hazardNotifs = await repository.getNotifications(
        type: NotificationType.hazardAlert,
      );
      expect(hazardNotifs.length, equals(1));
      expect(hazardNotifs.first.id, equals('notif_102'));
    });

    test('markAsRead updates item state and decrements unread count', () async {
      final initialUnread = await repository.getUnreadCount(userId: 'usr_test_1');
      expect(initialUnread, equals(2));

      await repository.markAsRead('notif_101');

      final updatedUnread = await repository.getUnreadCount(userId: 'usr_test_1');
      expect(updatedUnread, equals(1));

      final user1Unread = await repository.getNotifications(
        userId: 'usr_test_1',
        unreadOnly: true,
      );
      expect(user1Unread.length, equals(1));
      expect(user1Unread.first.id, equals('notif_102'));
    });

    test('markAllAsRead marks all user notifications as read', () async {
      await repository.markAllAsRead(userId: 'usr_test_1');

      final unread = await repository.getUnreadCount(userId: 'usr_test_1');
      expect(unread, equals(0));
    });
  });
}
