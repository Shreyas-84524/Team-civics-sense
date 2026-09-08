import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/hive/hive_storage_service.dart';
import 'package:civic_app/core/local/models/complaint_local_model.dart';
import 'package:civic_app/core/local/models/location_local_model.dart';
import 'package:civic_app/core/local/models/user_local_model.dart';

void main() {
  late Directory tempDir;
  late HiveStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_storage_test_');
    storage = HiveStorageService();
    await storage.init(subDir: tempDir.path, isTest: true);
  });

  tearDown(() async {
    await storage.closeAll();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveStorageService CRUD Operations', () {
    test('put and get primitive and custom types', () async {
      // 1. Primitive string
      await storage.put('settings', 'app_lang', 'hi');
      final lang = await storage.get<String>('settings', 'app_lang');
      expect(lang, 'hi');

      // 2. Default value for missing key
      final missing = await storage.get<String>('settings', 'non_existent_key', defaultValue: 'en');
      expect(missing, 'en');

      // 3. UserLocalModel persistence
      const user = UserLocalModel(
        id: 'u_101',
        fullName: 'Rahul Sharma',
        email: 'rahul@example.com',
        phone: '+91 9876543210',
        civicPoints: 450,
        wardNumber: 'Ward 14',
      );
      await storage.put(HiveBoxes.user, HiveBoxes.currentUserKey, user);
      final retrievedUser = await storage.get<UserLocalModel>(HiveBoxes.user, HiveBoxes.currentUserKey);

      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.fullName, 'Rahul Sharma');
      expect(retrievedUser.civicPoints, 450);
      expect(retrievedUser.wardNumber, 'Ward 14');
    });

    test('putAll and getAll batch operations', () async {
      final complaints = {
        'cmp_1': const ComplaintLocalModel(
          id: 'cmp_1',
          citizenId: 'u_1',
          ticketNumber: 'CF-2026-000001',
          title: 'Pothole 1',
          description: 'Desc 1',
          categoryId: 'roads',
          categoryName: 'Roads',
          categoryDescription: 'Roads issues',
          status: 'reported',
          priority: 'high',
          location: LocationLocalModel(latitude: 12.97, longitude: 77.59, address: 'Road 1'),
          createdAtEpochMs: 1725700000000,
          updatedAtEpochMs: 1725700000000,
        ),
        'cmp_2': const ComplaintLocalModel(
          id: 'cmp_2',
          citizenId: 'u_1',
          ticketNumber: 'CF-2026-000002',
          title: 'Drainage 2',
          description: 'Desc 2',
          categoryId: 'drainage',
          categoryName: 'Drainage',
          categoryDescription: 'Drainage issues',
          status: 'verified',
          priority: 'medium',
          location: LocationLocalModel(latitude: 12.98, longitude: 77.60, address: 'Road 2'),
          createdAtEpochMs: 1725700000000,
          updatedAtEpochMs: 1725700000000,
        ),
      };

      await storage.putAll<ComplaintLocalModel>(HiveBoxes.complaints, complaints);

      // Check count
      final count = await storage.count(HiveBoxes.complaints);
      expect(count, 2);

      // Check getAll
      final allList = await storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);
      expect(allList.length, 2);
      expect(allList.any((c) => c.id == 'cmp_1'), isTrue);
      expect(allList.any((c) => c.id == 'cmp_2'), isTrue);

      // Check getAllEntries
      final entriesMap = await storage.getAllEntries<ComplaintLocalModel>(HiveBoxes.complaints);
      expect(entriesMap.length, 2);
      expect(entriesMap['cmp_1']?.ticketNumber, 'CF-2026-000001');
      expect(entriesMap['cmp_2']?.ticketNumber, 'CF-2026-000002');
    });

    test('containsKey, delete, and deleteAll', () async {
      await storage.put('test_box', 'k1', 'val1');
      await storage.put('test_box', 'k2', 'val2');
      await storage.put('test_box', 'k3', 'val3');

      expect(await storage.containsKey('test_box', 'k1'), isTrue);
      expect(await storage.containsKey('test_box', 'k4'), isFalse);

      // Delete single key
      await storage.delete('test_box', 'k1');
      expect(await storage.containsKey('test_box', 'k1'), isFalse);
      expect(await storage.count('test_box'), 2);

      // Delete multiple keys
      await storage.deleteAll('test_box', ['k2', 'k3']);
      expect(await storage.count('test_box'), 0);
    });

    test('clear box removes all keys without destroying box', () async {
      await storage.put('hazards', 'h1', 'Hazard 1');
      await storage.put('hazards', 'h2', 'Hazard 2');
      expect(await storage.count('hazards'), 2);

      await storage.clear('hazards');
      expect(await storage.count('hazards'), 0);
      expect(storage.isBoxOpen('hazards'), isTrue);
    });

    test('resetAllBoxes clears all canonical HiveBoxes', () async {
      await storage.put(HiveBoxes.complaints, 'c1', 'Complaint 1');
      await storage.put(HiveBoxes.notifications, 'n1', 'Notif 1');
      await storage.put(HiveBoxes.rewards, 'r1', 'Reward 1');

      expect(await storage.count(HiveBoxes.complaints), 1);
      expect(await storage.count(HiveBoxes.notifications), 1);
      expect(await storage.count(HiveBoxes.rewards), 1);

      await storage.resetAllBoxes();

      expect(await storage.count(HiveBoxes.complaints), 0);
      expect(await storage.count(HiveBoxes.notifications), 0);
      expect(await storage.count(HiveBoxes.rewards), 0);
    });

    test('closeBox and deleteBoxFromDisk', () async {
      await storage.put('temp_box', 'k1', 'val1');
      expect(storage.isBoxOpen('temp_box'), isTrue);

      await storage.closeBox('temp_box');
      expect(storage.isBoxOpen('temp_box'), isFalse);

      await storage.deleteBoxFromDisk('temp_box');
      expect(storage.isBoxOpen('temp_box'), isFalse);
    });
  });

  group('HiveStorageService Error Handling', () {
    test('Initialization is marked initialized upon successful init', () {
      expect(storage.isInitialized, isTrue);
    });
  });
}
