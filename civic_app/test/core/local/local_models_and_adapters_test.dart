import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/models/notification_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/local/models/complaint_local_model.dart';
import 'package:civic_app/core/local/models/hazard_local_model.dart';
import 'package:civic_app/core/local/models/location_local_model.dart';
import 'package:civic_app/core/local/models/notification_local_model.dart';
import 'package:civic_app/core/local/models/pending_sync_local_model.dart';
import 'package:civic_app/core/local/models/reward_local_model.dart';
import 'package:civic_app/core/local/models/settings_local_model.dart';
import 'package:civic_app/core/local/models/timeline_event_local_model.dart';
import 'package:civic_app/core/local/models/user_local_model.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/local/hive/hive_adapters/achievement_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/complaint_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/hazard_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/location_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/notification_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/pending_sync_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/reward_item_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/settings_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/timeline_event_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_adapters/user_hive_adapter.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civic_adapters_test_');
    Hive.init(tempDir.path);
    HiveInitializer.registerAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Location Local Model & Adapter Tests', () {
    test('Converts between CivicLocation and LocationLocalModel accurately', () {
      final now = DateTime.now();
      final location = CivicLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        address: '4th Cross, 2nd Main Road',
        landmark: 'Opposite Park',
        ward: 'Ward 14',
        city: 'Bengaluru',
        pincode: '560001',
        source: LocationSource.gps,
        accuracyMeters: 5.2,
        timestamp: now,
      );

      final local = LocationLocalModel.fromDomain(location);
      expect(local.latitude, 12.9716);
      expect(local.longitude, 77.5946);
      expect(local.address, '4th Cross, 2nd Main Road');
      expect(local.landmark, 'Opposite Park');
      expect(local.ward, 'Ward 14');
      expect(local.source, 'gps');
      expect(local.accuracyMeters, 5.2);

      final domain = local.toDomain();
      expect(domain.latitude, location.latitude);
      expect(domain.longitude, location.longitude);
      expect(domain.address, location.address);
      expect(domain.landmark, location.landmark);
      expect(domain.source, LocationSource.gps);
      expect(domain.isGps, isTrue);
    });

    test('LocationHiveAdapter binary serialization and deserialization', () async {
      final box = await Hive.openBox<LocationLocalModel>('test_locations');
      const item = LocationLocalModel(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Marine Drive',
        landmark: 'Sea face',
        ward: 'Ward A',
        city: 'Mumbai',
        pincode: '400001',
        source: 'manual',
        accuracyMeters: 10.0,
      );

      await box.put('loc_1', item);
      final retrieved = box.get('loc_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.latitude, 19.0760);
      expect(retrieved.address, 'Marine Drive');
      expect(retrieved.city, 'Mumbai');
      expect(retrieved.source, 'manual');

      await box.close();
    });
  });

  group('TimelineEvent Local Model & Adapter Tests', () {
    test('Converts between TimelineEvent and TimelineEventLocalModel', () {
      final now = DateTime.now();
      final event = TimelineEvent(
        title: 'Inspected by Ward Officer',
        description: 'Road team assigned for patch work',
        timestamp: now,
        status: ComplaintStatus.inProgress,
        updatedBy: 'Ward Engineer',
      );

      final local = TimelineEventLocalModel.fromDomain(event);
      expect(local.title, 'Inspected by Ward Officer');
      expect(local.status, 'inProgress');
      expect(local.updatedBy, 'Ward Engineer');

      final domain = local.toDomain();
      expect(domain.title, event.title);
      expect(domain.description, event.description);
      expect(domain.status, ComplaintStatus.inProgress);
      expect(domain.updatedBy, event.updatedBy);
    });

    test('TimelineEventHiveAdapter binary serialization and deserialization', () async {
      final box = await Hive.openBox<TimelineEventLocalModel>('test_timeline');
      const item = TimelineEventLocalModel(
        title: 'Resolved',
        description: 'Pothole fixed with hot asphalt mix',
        timestampEpochMs: 1725700000000,
        status: 'resolved',
        updatedBy: 'Chief Engineer',
      );

      await box.put('event_1', item);
      final retrieved = box.get('event_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Resolved');
      expect(retrieved.status, 'resolved');
      expect(retrieved.updatedBy, 'Chief Engineer');

      await box.close();
    });
  });

  group('Complaint Local Model & Adapter Tests', () {
    test('Converts between ComplaintModel and ComplaintLocalModel preserving full lifecycle', () {
      final now = DateTime.now();
      final complaint = ComplaintModel(
        id: 'cmp_999',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000999',
        title: 'Severe waterlogging at railway subway',
        description: 'Water has accumulated 3 feet high blocking two wheelers',
        category: CivicCategory.defaultCategories[1], // Water
        status: ComplaintStatus.assigned,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Subway Road, Ward 14',
          landmark: 'Near Railway Station',
          ward: 'Ward 14',
          city: 'Bengaluru',
        ),
        imageUrls: ['https://example.com/photo1.jpg'],
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now,
        timeline: [
          TimelineEvent(
            title: 'Reported',
            description: 'Issue reported with GPS coordinates',
            timestamp: now.subtract(const Duration(hours: 4)),
            status: ComplaintStatus.reported,
          ),
          TimelineEvent(
            title: 'Assigned',
            description: 'Assigned to Stormwater Drainage Rapid Unit',
            timestamp: now,
            status: ComplaintStatus.assigned,
            updatedBy: 'Zonal Officer',
          ),
        ],
        upvotes: 15,
        isHazard: true,
        officerNotes: 'High-power pump mobilized',
        assignedTo: 'Drainage Squad 1',
        departmentName: 'Water & Drainage',
        resolvedAt: null,
      );

      final local = ComplaintLocalModel.fromDomain(complaint);
      expect(local.id, 'cmp_999');
      expect(local.ticketNumber, 'CF-2026-000999');
      expect(local.categoryId, 'water');
      expect(local.status, 'assigned');
      expect(local.priority, 'emergency');
      expect(local.timeline.length, 2);
      expect(local.isHazard, isTrue);

      final domain = local.toDomain();
      expect(domain.id, complaint.id);
      expect(domain.ticketNumber, complaint.ticketNumber);
      expect(domain.title, complaint.title);
      expect(domain.status, ComplaintStatus.assigned);
      expect(domain.priority, ComplaintPriority.emergency);
      expect(domain.category.id, 'water');
      expect(domain.timeline.length, 2);
      expect(domain.location.address, 'Subway Road, Ward 14');
      expect(domain.assignedTo, 'Drainage Squad 1');
      expect(domain.isHazard, isTrue);
    });

    test('ComplaintHiveAdapter binary serialization and deserialization', () async {
      final box = await Hive.openBox<ComplaintLocalModel>('test_complaints');
      final complaint = ComplaintLocalModel(
        id: 'cmp_101',
        citizenId: 'user_001',
        ticketNumber: 'CF-2026-000101',
        title: 'Streetlight not working',
        description: 'Dark area creating hazard at night',
        categoryId: 'streetlights',
        categoryName: 'Street Lights',
        categoryDescription: 'Broken street lights',
        status: 'reported',
        priority: 'medium',
        location: const LocationLocalModel(
          latitude: 12.97,
          longitude: 77.59,
          address: '4th Main Road',
        ),
        imageUrls: const ['img1.png', 'img2.png'],
        createdAtEpochMs: 1725700000000,
        updatedAtEpochMs: 1725700000000,
        timeline: const [
          TimelineEventLocalModel(
            title: 'Reported',
            description: 'Submitted by citizen',
            timestampEpochMs: 1725700000000,
            status: 'reported',
          ),
        ],
        upvotes: 7,
        isHazard: false,
      );

      await box.put('cmp_101', complaint);
      final retrieved = box.get('cmp_101');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'cmp_101');
      expect(retrieved.ticketNumber, 'CF-2026-000101');
      expect(retrieved.location.address, '4th Main Road');
      expect(retrieved.imageUrls.length, 2);
      expect(retrieved.timeline.length, 1);

      await box.close();
    });
  });

  group('Hazard Local Model & Adapter Tests', () {
    test('Converts between HazardModel and HazardLocalModel', () {
      final now = DateTime.now();
      final hazard = HazardModel(
        id: 'haz_501',
        complaintId: 'cmp_102',
        ticketNumber: 'CF-2026-000021',
        title: 'Open manhole on pedestrian path',
        category: CivicCategory.defaultCategories[0], // Roads
        status: ComplaintStatus.inProgress,
        latitude: 12.9750,
        longitude: 77.5980,
        address: '4th Main Road',
        landmark: 'Near Metro Pillar 42',
        ward: 'Ward 14',
        severity: HazardSeverity.critical,
        imageUrl: 'https://example.com/manhole.jpg',
        upvotes: 32,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );

      final local = HazardLocalModel.fromDomain(hazard);
      expect(local.id, 'haz_501');
      expect(local.severity, 'critical');
      expect(local.upvotes, 32);

      final domain = local.toDomain();
      expect(domain.id, hazard.id);
      expect(domain.severity, HazardSeverity.critical);
      expect(domain.title, hazard.title);
      expect(domain.latitude, hazard.latitude);
    });

    test('HazardHiveAdapter binary serialization and deserialization', () async {
      final box = await Hive.openBox<HazardLocalModel>('test_hazards');
      const item = HazardLocalModel(
        id: 'haz_1',
        title: 'Live wire hanging from pole',
        categoryId: 'streetlights',
        categoryName: 'Street Lights',
        categoryDescription: 'Electrical hazard',
        status: 'reported',
        latitude: 12.99,
        longitude: 77.60,
        address: '1st Cross',
        severity: 'critical',
        upvotes: 12,
        createdAtEpochMs: 1725700000000,
        updatedAtEpochMs: 1725700000000,
      );

      await box.put('haz_1', item);
      final retrieved = box.get('haz_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'haz_1');
      expect(retrieved.severity, 'critical');
      expect(retrieved.upvotes, 12);

      await box.close();
    });
  });

  group('Notification Local Model & Adapter Tests', () {
    test('Converts between NotificationModel and NotificationLocalModel', () {
      final now = DateTime.now();
      final notif = NotificationModel(
        id: 'notif_100',
        userId: 'user_citizen_001',
        title: 'Work In Progress',
        message: 'Repair vehicle dispatched for CF-2026-000021',
        type: NotificationType.complaintStatusChanged,
        complaintId: 'cmp_102',
        isRead: false,
        createdAt: now,
      );

      final local = NotificationLocalModel.fromDomain(notif);
      expect(local.id, 'notif_100');
      expect(local.type, 'complaintStatusChanged');
      expect(local.isRead, isFalse);

      final domain = local.toDomain();
      expect(domain.id, notif.id);
      expect(domain.title, notif.title);
      expect(domain.type, NotificationType.complaintStatusChanged);
      expect(domain.complaintId, 'cmp_102');
    });

    test('NotificationHiveAdapter binary serialization and deserialization', () async {
      final box = await Hive.openBox<NotificationLocalModel>('test_notifications');
      const item = NotificationLocalModel(
        id: 'n_1',
        userId: 'user_1',
        title: 'Issue Resolved',
        message: 'Your report has been resolved.',
        type: 'complaintResolved',
        complaintId: 'cmp_105',
        isRead: true,
        createdAtEpochMs: 1725700000000,
      );

      await box.put('n_1', item);
      final retrieved = box.get('n_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'n_1');
      expect(retrieved.type, 'complaintResolved');
      expect(retrieved.isRead, isTrue);

      await box.close();
    });
  });

  group('User Local Model & Adapter Tests', () {
    test('Converts between UserModel and UserLocalModel', () {
      const user = UserModel(
        id: 'user_citizen_001',
        fullName: 'Shreyas Shigwan',
        email: 'shreyas@example.com',
        phone: '+91 98765 43210',
        avatarUrl: 'https://example.com/avatar.jpg',
        civicPoints: 950,
        reportsSubmitted: 15,
        reportsResolved: 12,
        badges: ['First Report', 'Civic Contributor', 'Community Helper'],
        languageCode: 'mr',
        wardNumber: 'Ward 14 (Central)',
        role: 'citizen',
      );

      final local = UserLocalModel.fromDomain(user);
      expect(local.id, 'user_citizen_001');
      expect(local.civicPoints, 950);
      expect(local.badges.length, 3);
      expect(local.languageCode, 'mr');

      final domain = local.toDomain();
      expect(domain.id, user.id);
      expect(domain.fullName, user.fullName);
      expect(domain.civicPoints, user.civicPoints);
      expect(domain.badges.length, 3);
      expect(domain.initials, 'SS');
      expect(domain.languageName, 'मराठी (Marathi)');
    });

    test('UserHiveAdapter binary serialization and deserialization', () async {
      final box = await Hive.openBox<UserLocalModel>('test_user');
      const user = UserLocalModel(
        id: 'user_test',
        fullName: 'Test Citizen',
        email: 'test@civicfix.test',
        phone: '+91 9000000000',
        civicPoints: 200,
        reportsSubmitted: 3,
        reportsResolved: 2,
        badges: ['First Report'],
        languageCode: 'hi',
        wardNumber: 'Ward 5',
        role: 'citizen',
      );

      await box.put('profile', user);
      final retrieved = box.get('profile');

      expect(retrieved, isNotNull);
      expect(retrieved!.fullName, 'Test Citizen');
      expect(retrieved.languageCode, 'hi');
      expect(retrieved.civicPoints, 200);

      await box.close();
    });
  });

  group('Reward Local Model & Adapters Tests', () {
    test('Converts CivicAchievement and CivicRewardItem with Local Models', () {
      final achievement = CivicAchievement.defaultAchievements().first;
      final localAch = AchievementLocalModel.fromDomain(achievement);
      expect(localAch.id, 'ach_1');
      expect(localAch.title, 'First Report');

      final domainAch = localAch.toDomain();
      expect(domainAch.id, achievement.id);
      expect(domainAch.title, achievement.title);

      const rewardItem = CivicRewardItem(
        id: 'rew_1',
        title: 'Metro Pass Discount (20%)',
        partner: 'City Transport Corp',
        description: '20% off monthly pass',
        pointsCost: 500,
        expiryDate: 'Dec 31, 2026',
        icon: Icons.directions_subway_rounded,
      );
      final localRew = RewardItemLocalModel.fromDomain(rewardItem);
      expect(localRew.id, 'rew_1');
      expect(localRew.pointsCost, 500);

      final domainRew = localRew.toDomain();
      expect(domainRew.id, rewardItem.id);
      expect(domainRew.title, rewardItem.title);
      expect(domainRew.pointsCost, 500);
    });

    test('AchievementHiveAdapter and RewardItemHiveAdapter binary serialization', () async {
      final achBox = await Hive.openBox<AchievementLocalModel>('test_achievements');
      const ach = AchievementLocalModel(
        id: 'ach_test',
        title: 'Super Reporter',
        description: 'Reported 10 issues',
        howToUnlock: 'Submit 10 verified issues',
        iconCodePoint: 57800,
        isUnlocked: true,
        pointsRequired: 300,
      );
      await achBox.put('ach_1', ach);
      final retrievedAch = achBox.get('ach_1');
      expect(retrievedAch, isNotNull);
      expect(retrievedAch!.title, 'Super Reporter');
      await achBox.close();

      final rewBox = await Hive.openBox<RewardItemLocalModel>('test_rewards');
      const rew = RewardItemLocalModel(
        id: 'rew_test',
        title: 'Free Coffee Pass',
        partner: 'Civic Cafe',
        description: 'Enjoy a free filter coffee',
        pointsCost: 100,
        expiryDate: 'Nov 2026',
        iconCodePoint: 58000,
      );
      await rewBox.put('rew_1', rew);
      final retrievedRew = rewBox.get('rew_1');
      expect(retrievedRew, isNotNull);
      expect(retrievedRew!.partner, 'Civic Cafe');
      await rewBox.close();
    });
  });

  group('PendingSync & Settings Local Models & Adapters Tests', () {
    test('PendingSyncLocalModel and SettingsLocalModel binary serialization', () async {
      final syncBox = await Hive.openBox<PendingSyncLocalModel>('test_pending_sync');
      const syncItem = PendingSyncLocalModel(
        id: 'sync_001',
        entityType: 'complaint',
        action: 'create',
        payloadJson: '{"title":"Pothole","lat":12.97}',
        createdAtEpochMs: 1725700000000,
        retryCount: 1,
        syncStatus: 'pending',
      );
      await syncBox.put('sync_001', syncItem);
      final retrievedSync = syncBox.get('sync_001');
      expect(retrievedSync, isNotNull);
      expect(retrievedSync!.entityType, 'complaint');
      expect(retrievedSync.payloadJson, contains('Pothole'));
      await syncBox.close();

      final settingsBox = await Hive.openBox<SettingsLocalModel>('test_settings');
      const settings = SettingsLocalModel(
        themeMode: 'dark',
        languageCode: 'mr',
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: false,
        soundEnabled: true,
        locationPermissionRequested: true,
      );
      await settingsBox.put('app_config', settings);
      final retrievedSettings = settingsBox.get('app_config');
      expect(retrievedSettings, isNotNull);
      expect(retrievedSettings!.themeMode, 'dark');
      expect(retrievedSettings.languageCode, 'mr');
      expect(retrievedSettings.emailNotificationsEnabled, isFalse);
      await settingsBox.close();
    });
  });

  group('Adapter typeId verification', () {
    test('All 10 TypeAdapters have unique registered typeIds from 0 to 9', () {
      final List<TypeAdapter<dynamic>> adapters = [
        ComplaintHiveAdapter(), // 0
        LocationHiveAdapter(), // 1
        TimelineEventHiveAdapter(), // 2
        HazardHiveAdapter(), // 3
        NotificationHiveAdapter(), // 4
        UserHiveAdapter(), // 5
        AchievementHiveAdapter(), // 6
        RewardItemHiveAdapter(), // 7
        PendingSyncHiveAdapter(), // 8
        SettingsHiveAdapter(), // 9
      ];

      final typeIds = adapters.map((a) => a.typeId).toSet();
      expect(typeIds.length, 10);
      for (int i = 0; i < 10; i++) {
        expect(typeIds.contains(i), isTrue);
      }
    });
  });
}
