import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/models/notification_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';
import 'package:civic_app/core/repositories/hive_hazard_repository.dart';
import 'package:civic_app/core/repositories/hive_notification_repository.dart';
import 'package:civic_app/core/repositories/hive_rewards_repository.dart';
import 'package:civic_app/core/repositories/hive_user_repository.dart';
import 'package:civic_app/core/widgets/offline_cache_banner.dart';

void main() {
  group('Offline Read Experience & Cache Persistence Tests', () {
    late Directory tempDir;
    late AppConnectivityService connectivity;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('civic_offline_read_test_');
      connectivity = AppConnectivityService();
      connectivity.resetForTesting(initialOnline: true);
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      await HiveInitializer.openEssentialBoxes();
    });

    tearDown(() async {
      await HiveInitializer.resetForTesting();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('Online Load -> Cache -> Offline Read across all domain repositories', () async {
      // 1. ONLINE PHASE: Populate and cache datasets
      final complaintRepo = HiveComplaintRepository();
      final userRepo = HiveUserRepository();
      final notifRepo = HiveNotificationRepository();
      final rewardsRepo = HiveRewardsRepository();
      final hazardRepo = HiveHazardRepository();

      const cachedUser = UserModel(
        id: 'usr_offline_demo',
        fullName: 'Ananya Deshmukh',
        email: 'ananya@example.com',
        phone: '+91 99887 76655',
        civicPoints: 320,
        wardNumber: 'Ward 45',
      );
      await userRepo.cacheUser(cachedUser);

      final cachedComplaint = ComplaintModel(
        id: 'cmp_offline_demo_1',
        ticketNumber: 'CF-2026-000800',
        title: 'Waterlogging near school',
        description: 'Road flooded after rain',
        category: CivicCategory.defaultCategories[3],
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'School Road'),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        syncStatus: SyncStatus.synced,
        timeline: [
          TimelineEvent(
            title: 'Reported',
            description: 'Submitted',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            status: ComplaintStatus.reported,
          ),
          TimelineEvent(
            title: 'Assigned',
            description: 'Assigned to Ward Engineer',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            status: ComplaintStatus.assigned,
            updatedBy: 'Chief Engineer',
          ),
        ],
      );
      await complaintRepo.cacheComplaints([cachedComplaint]);

      final cachedNotif = NotificationModel(
        id: 'notif_offline_1',
        userId: 'usr_offline_demo',
        title: 'Issue Assigned',
        message: 'Your report has been assigned.',
        type: NotificationType.statusUpdate,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await notifRepo.cacheNotifications([cachedNotif]);

      final cachedHazard = HazardModel(
        id: 'haz_offline_1',
        title: 'Open Trench',
        category: CivicCategory.defaultCategories[6],
        status: ComplaintStatus.reported,
        latitude: 12.971,
        longitude: 77.594,
        address: 'School Lane',
        severity: HazardSeverity.high,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await hazardRepo.cacheHazards([cachedHazard]);

      // 2. OFFLINE TRANSITION: Device loses internet connectivity
      connectivity.setOnline(false);
      expect(connectivity.isOffline, isTrue);

      // 3. OFFLINE READS: Verify all data is retrieved accurately from cache
      final offlineUser = await userRepo.getCurrentUser();
      expect(offlineUser.fullName, equals('Ananya Deshmukh'));
      expect(offlineUser.civicPoints, equals(320));

      final offlineComplaints = await complaintRepo.getComplaints();
      expect(offlineComplaints.any((c) => c.id == 'cmp_offline_demo_1'), isTrue);

      final offlineComplaintDetail = await complaintRepo.getComplaintById('cmp_offline_demo_1');
      expect(offlineComplaintDetail, isNotNull);
      expect(offlineComplaintDetail!.timeline.length, equals(2));
      expect(offlineComplaintDetail.timeline.last.updatedBy, equals('Chief Engineer'));

      final offlineNotifs = await notifRepo.getNotifications(userId: 'usr_offline_demo');
      expect(offlineNotifs.length, equals(1));
      expect(offlineNotifs.first.title, equals('Issue Assigned'));

      final offlineHazards = await hazardRepo.getHazards();
      expect(offlineHazards.any((h) => h.id == 'haz_offline_1'), isTrue);

      final offlineAchievements = await rewardsRepo.getAchievements();
      expect(offlineAchievements, isNotEmpty);
    });

    test('App restart simulation preserves all cached collections across cold starts', () async {
      // 1. Write data in session 1
      final userRepo1 = HiveUserRepository();
      await userRepo1.cacheUser(const UserModel(
        id: 'usr_restart_test',
        fullName: 'Vikram Joshi',
        email: 'vikram@example.com',
        phone: '+91 98765 00000',
        civicPoints: 500,
      ));

      final complaintRepo1 = HiveComplaintRepository();
      await complaintRepo1.cacheComplaints([
        ComplaintModel(
          id: 'cmp_restart_test',
          ticketNumber: 'CF-2026-000999',
          title: 'Street Light Bulb Replacement',
          description: 'Dark area at night',
          category: CivicCategory.defaultCategories[4],
          status: ComplaintStatus.verified,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 12.9, longitude: 77.6, address: 'Ring Road'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      // 2. Simulate Cold App Termination: Close Hive boxes
      await HiveInitializer.resetForTesting();

      // 3. Simulate App Cold Launch: Re-initialize Hive with same storage directory
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      await HiveInitializer.openEssentialBoxes();

      // 4. Verify data in session 2
      final userRepo2 = HiveUserRepository();
      final restoredUser = await userRepo2.getCurrentUser();
      expect(restoredUser.id, equals('usr_restart_test'));
      expect(restoredUser.fullName, equals('Vikram Joshi'));
      expect(restoredUser.civicPoints, equals(500));

      final complaintRepo2 = HiveComplaintRepository();
      final restoredComplaint = await complaintRepo2.getComplaintById('cmp_restart_test');
      expect(restoredComplaint, isNotNull);
      expect(restoredComplaint!.title, equals('Street Light Bulb Replacement'));
    });

    testWidgets('OfflineCacheBanner displays cached time and triggers optional refresh', (tester) async {
      bool refreshed = false;
      final cachedTime = DateTime.now().subtract(const Duration(minutes: 15));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineCacheBanner(
              cachedAt: cachedTime,
              onRefresh: () {
                refreshed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline — Saved 15m ago'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    test('Corrupted box recovery restores corrupted box safely without crash', () async {
      // Simulate corrupted box recovery
      final recovered = await HiveInitializer.recoverCorruptedBox(HiveBoxes.complaints);
      expect(recovered, isTrue);

      final complaintRepo = HiveComplaintRepository();
      expect(await complaintRepo.getComplaints(), isNotNull);
    });
  });
}
