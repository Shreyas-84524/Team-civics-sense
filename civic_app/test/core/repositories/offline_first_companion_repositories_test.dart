import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:civic_app/core/repositories/offline_first_govt_complaint_repository.dart';
import 'package:civic_app/core/repositories/offline_first_hazard_repository.dart';
import 'package:civic_app/core/repositories/offline_first_notification_repository.dart';
import 'package:civic_app/core/repositories/offline_first_rewards_repository.dart';
import 'package:civic_app/core/repositories/offline_first_user_repository.dart';
import 'package:civic_app/core/sync/providers/mock_sync_provider.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';
import 'package:civic_app/core/sync/sync_manager.dart';

class TestConnService implements ConnectivityService {
  bool _isOnline = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _isOnline;

  @override
  bool get isOffline => !_isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void setOnline(bool online) {
    _isOnline = online;
    _controller.add(online);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineFirstGovtComplaintRepository Tests', () {
    late HiveComplaintRepository localRepo;
    late TestConnService connectivity;
    late HiveSyncQueue syncQueue;
    late SyncManager syncManager;
    late OfflineFirstGovtComplaintRepository govtRepo;

    setUp(() {
      localRepo = HiveComplaintRepository();
      connectivity = TestConnService();
      syncQueue = HiveSyncQueue();
      syncManager = SyncManager.createForTesting(
        queue: syncQueue,
        provider: MockSyncProvider(),
        connectivity: connectivity,
        repository: localRepo,
      );

      govtRepo = OfflineFirstGovtComplaintRepository(
        localRepository: localRepo,
        syncManager: syncManager,
        connectivity: connectivity,
      );
    });

    tearDown(() {
      syncManager.dispose();
      syncQueue.dispose();
      connectivity.dispose();
    });

    test('Govt status updates, verification, and assignment update local cache and dashboard metrics', () async {
      // 1. Seed complaint
      final complaint = ComplaintModel(
        id: 'cmp_govt_001',
        citizenId: 'user_001',
        ticketNumber: 'CF-2026-000111',
        title: 'Dangerous Open Manhole',
        description: 'Open sewer drain on pavement',
        category: const CivicCategory(id: 'sewage', name: 'Sewage', description: '', icon: Icons.water),
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'MG Road'),
        imageUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );
      await localRepo.saveOfflineComplaint(complaint);

      // 2. Verify complaint
      final verified = await govtRepo.verifyComplaint(
        complaintId: 'cmp_govt_001',
        notes: 'Verified emergency hazard',
      );
      expect(verified, isTrue);

      var updated = await govtRepo.getComplaintById('cmp_govt_001');
      expect(updated!.status, equals(ComplaintStatus.verified));

      // 3. Assign complaint
      final assigned = await govtRepo.assignComplaint(
        complaintId: 'cmp_govt_001',
        departmentId: 'drainage',
        officerName: 'Inspector Patil',
        assignmentNote: 'Crew dispatched with safety barriers',
      );
      expect(assigned, isTrue);

      updated = await govtRepo.getComplaintById('cmp_govt_001');
      expect(updated!.status, equals(ComplaintStatus.assigned));
      expect(updated.assignedTo, equals('Inspector Patil'));

      // 4. Check dashboard metrics
      final metrics = await govtRepo.getDashboardMetrics();
      expect(metrics.totalComplaints, greaterThanOrEqualTo(1));
      expect(metrics.criticalHazardsCount, greaterThanOrEqualTo(1));

      // 5. Category distribution
      final catDist = await govtRepo.getCategoryDistribution();
      expect(catDist, isNotEmpty);

      // 6. Attention required
      final attention = await govtRepo.getAttentionRequiredComplaints();
      expect(attention, isNotEmpty);
    });
  });

  group('OfflineFirstUserRepository Tests', () {
    late HiveUserRepository localUserRepo;
    late TestConnService connectivity;
    late OfflineFirstUserRepository userRepo;

    setUp(() async {
      localUserRepo = HiveUserRepository();
      connectivity = TestConnService();
      userRepo = OfflineFirstUserRepository(
        localRepository: localUserRepo,
        connectivity: connectivity,
      );
      await localUserRepo.cacheUser(const UserModel(
        id: 'usr_test_companion',
        fullName: 'Civic User',
        email: 'civic@example.com',
        phone: '+91 99999 00000',
      ));
    });

    tearDown(() {
      connectivity.dispose();
    });

    test('User profile reads from cache and updates profile locally and securely', () async {
      final user = await userRepo.getCurrentUser();
      expect(user, isNotNull);
      expect(user.id, isNotEmpty);

      final updated = await userRepo.updateUserProfile(
        fullName: 'Civic Hero User',
        wardNumber: 'Ward 108',
      );
      expect(updated.fullName, equals('Civic Hero User'));
      expect(updated.wardNumber, equals('Ward 108'));

      final listenable = userRepo.getUserListenable();
      expect(listenable.value.fullName, equals('Civic Hero User'));
    });
  });

  group('OfflineFirstHazardRepository Tests', () {
    late HiveHazardRepository localHazardRepo;
    late TestConnService connectivity;
    late OfflineFirstHazardRepository hazardRepo;

    setUp(() async {
      localHazardRepo = HiveHazardRepository();
      connectivity = TestConnService();
      hazardRepo = OfflineFirstHazardRepository(
        localRepository: localHazardRepo,
        connectivity: connectivity,
      );
      await localHazardRepo.cacheHazards([
        HazardModel(
          id: 'haz_test_1',
          title: 'Pothole on Main Road',
          category: CivicCategory.defaultCategories[0],
          status: ComplaintStatus.reported,
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Main Road',
          severity: HazardSeverity.high,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
    });

    tearDown(() {
      connectivity.dispose();
    });

    test('Hazard queries filter by category, status, severity, and search term', () async {
      final hazards = await hazardRepo.getHazards();
      expect(hazards, isNotEmpty);

      final nearby = await hazardRepo.getNearbyHazards(
        latitude: 12.9716,
        longitude: 77.5946,
        radiusKm: 10.0,
      );
      expect(nearby, isA<List<HazardModel>>());
    });
  });

  group('OfflineFirstNotificationRepository Tests', () {
    late HiveNotificationRepository localNotifRepo;
    late TestConnService connectivity;
    late OfflineFirstNotificationRepository notifRepo;

    setUp(() async {
      localNotifRepo = HiveNotificationRepository();
      connectivity = TestConnService();
      notifRepo = OfflineFirstNotificationRepository(
        localRepository: localNotifRepo,
        connectivity: connectivity,
      );
      await localNotifRepo.cacheNotifications([
        NotificationModel(
          id: 'notif_test_1',
          userId: 'user_citizen_001',
          title: 'Update on Complaint',
          message: 'Status transitioned',
          type: NotificationType.statusUpdate,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ]);
    });

    tearDown(() {
      connectivity.dispose();
    });

    test('Notification repository reads list, marks single/all read, and updates unread count listenable', () async {
      final notifs = await notifRepo.getNotifications();
      expect(notifs, isNotEmpty);

      final firstId = notifs.first.id;
      await notifRepo.markAsRead(firstId);

      final count = await notifRepo.getUnreadCount();
      expect(count, greaterThanOrEqualTo(0));
      expect(notifRepo.unreadCountListenable.value, equals(count));

      await notifRepo.markAllAsRead();
      final afterAllRead = await notifRepo.getUnreadCount();
      expect(afterAllRead, equals(0));
    });
  });

  group('OfflineFirstRewardsRepository Tests', () {
    late HiveRewardsRepository localRewardsRepo;
    late TestConnService connectivity;
    late OfflineFirstRewardsRepository rewardsRepo;

    setUp(() {
      localRewardsRepo = HiveRewardsRepository();
      connectivity = TestConnService();
      rewardsRepo = OfflineFirstRewardsRepository(
        localRepository: localRewardsRepo,
        connectivity: connectivity,
      );
    });

    tearDown(() {
      connectivity.dispose();
    });

    test('Rewards repository returns reward data, achievements, and catalog', () async {
      final rewardData = await rewardsRepo.getRewardData('user_citizen_001');
      expect(rewardData, isNotNull);
      expect(rewardData.achievements, isNotEmpty);
      expect(rewardData.perks, isNotEmpty);

      final achievements = await rewardsRepo.getAchievements();
      expect(achievements, isNotEmpty);

      final catalog = await rewardsRepo.getRewardsCatalog();
      expect(catalog, isNotEmpty);
    });
  });
}
