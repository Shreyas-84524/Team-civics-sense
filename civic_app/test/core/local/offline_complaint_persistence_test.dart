import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/local/hive/hive_storage_service.dart';
import 'package:civic_app/core/local/models/complaint_local_model.dart';
import 'package:civic_app/core/local/models/pending_sync_local_model.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';
import 'package:civic_app/User UI/models/complaint_draft.dart';
import 'package:civic_app/User UI/screens/complaint_details_screen.dart';
import 'package:civic_app/User UI/screens/complaint_submitted_screen.dart';
import 'package:civic_app/User UI/services/mock_complaint_service.dart';
import 'package:civic_app/User UI/widgets/complaint_card.dart';
import 'package:civic_app/User UI/widgets/complaint_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveStorageService storageService;
  late HiveComplaintRepository repository;
  late AppConnectivityService connectivityService;
  late MockComplaintService complaintService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('civicfix_offline_test_');
    await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
    storageService = HiveStorageService.instance;
    await storageService.init(subDir: tempDir.path, isTest: true);
    repository = HiveComplaintRepository(storage: storageService);
    connectivityService = AppConnectivityService();
    connectivityService.resetForTesting(initialOnline: true);
    complaintService = MockComplaintService(
      connectivityService: connectivityService,
      repository: repository,
    );
  });

  tearDown(() async {
    await storageService.closeAll();
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('SyncStatus & ComplaintModel Tests', () {
    test('SyncStatus enum properties and extensions', () {
      expect(SyncStatus.pending.isPending, isTrue);
      expect(SyncStatus.pending.label, equals('Pending Sync'));
      expect(SyncStatus.pending.icon, equals(Icons.cloud_off_rounded));

      expect(SyncStatus.syncing.isSyncing, isTrue);
      expect(SyncStatus.syncing.label, equals('Syncing...'));

      expect(SyncStatus.synced.isSynced, isTrue);
      expect(SyncStatus.synced.label, equals('Synced'));

      expect(SyncStatus.failed.isFailed, isTrue);
      expect(SyncStatus.failed.label, equals('Sync Failed'));
    });

    test('ComplaintModel copyWith and offline properties', () {
      final complaint = ComplaintModel(
        id: 'cmp_test_1',
        ticketNumber: 'LOCAL-2026-000025',
        localId: 'LOCAL-2026-000025',
        title: 'Broken Pothole',
        description: 'Large trench on 5th cross road.',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: '5th Cross'),
        createdAt: DateTime(2026, 9, 8),
        updatedAt: DateTime(2026, 9, 8),
        syncStatus: SyncStatus.pending,
      );

      expect(complaint.isOfflineDraft, isTrue);
      expect(complaint.localId, equals('LOCAL-2026-000025'));
      expect(complaint.syncStatus, equals(SyncStatus.pending));

      final updated = complaint.copyWith(
        syncStatus: SyncStatus.synced,
        serverId: 'srv_12345',
        ticketNumber: 'CF-2026-000025',
      );
      expect(updated.isOfflineDraft, isFalse);
      expect(updated.syncStatus, equals(SyncStatus.synced));
      expect(updated.serverId, equals('srv_12345'));
      expect(updated.ticketNumber, equals('CF-2026-000025'));
    });

    test('ComplaintLocalModel mapping preserves syncStatus, localId, and serverId', () {
      final domain = ComplaintModel(
        id: 'cmp_test_map',
        ticketNumber: 'LOCAL-2026-000099',
        localId: 'LOCAL-2026-000099',
        serverId: 'srv_99',
        title: 'Street Light Issue',
        description: 'Non working light',
        category: CivicCategory.defaultCategories[2],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Test St'),
        createdAt: DateTime(2026, 9, 8, 10, 0),
        updatedAt: DateTime(2026, 9, 8, 10, 0),
        syncStatus: SyncStatus.pending,
      );

      final local = ComplaintLocalModel.fromDomain(domain);
      expect(local.syncStatus, equals('pending'));
      expect(local.localId, equals('LOCAL-2026-000099'));
      expect(local.serverId, equals('srv_99'));

      final restored = local.toDomain();
      expect(restored.syncStatus, equals(SyncStatus.pending));
      expect(restored.localId, equals('LOCAL-2026-000099'));
      expect(restored.serverId, equals('srv_99'));
      expect(restored.title, equals(domain.title));
    });
  });

  group('Hive Offline Persistence & Restart Simulation', () {
    test('saveOfflineComplaint stores complaint and queues pending sync in Hive', () async {
      final complaint = ComplaintModel(
        id: 'cmp_offline_001',
        ticketNumber: 'LOCAL-2026-000101',
        localId: 'LOCAL-2026-000101',
        title: 'Water pipe leak',
        description: 'Clean drinking water leaking on street.',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 12.98, longitude: 77.60, address: 'Main Road'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isHazard: true,
      );

      final saved = await repository.saveOfflineComplaint(complaint);
      expect(saved.syncStatus, equals(SyncStatus.pending));
      expect(saved.localId, equals('LOCAL-2026-000101'));

      // Check Hive storage directly
      final storedInBox = await storageService.get<ComplaintLocalModel>(
        HiveBoxes.complaints,
        'cmp_offline_001',
      );
      expect(storedInBox, isNotNull);
      expect(storedInBox!.syncStatus, equals('pending'));
      expect(storedInBox.localId, equals('LOCAL-2026-000101'));

      // Check pending sync queue in Hive
      final syncItem = await storageService.get<PendingSyncLocalModel>(
        HiveBoxes.pendingSync,
        'sync_cmp_offline_001',
      );
      expect(syncItem, isNotNull);
      expect(syncItem!.action, equals('create'));
      expect(syncItem.entityType, equals('complaint'));
      expect(syncItem.syncStatus, equals('pending'));
    });

    test('App restart simulation preserves offline complaints and pending queue', () async {
      final complaint = ComplaintModel(
        id: 'cmp_restart_test',
        ticketNumber: 'LOCAL-2026-000102',
        localId: 'LOCAL-2026-000102',
        title: 'Open Manhole',
        description: 'Hazardous uncovered drain',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(latitude: 12.95, longitude: 77.58, address: 'Corner Rd'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isHazard: true,
      );

      await repository.saveOfflineComplaint(complaint);

      // SIMULATE APP KILL / RESTART: Close all boxes
      await storageService.closeAll();

      // SIMULATE APP RE-OPENING: Re-initialize storage
      final newStorageService = HiveStorageService.instance;
      await newStorageService.init(subDir: tempDir.path, isTest: true);
      final newRepository = HiveComplaintRepository(storage: newStorageService);

      final fetchedList = await newRepository.getCitizenComplaints('user_citizen_001');
      expect(fetchedList.any((c) => c.id == 'cmp_restart_test'), isTrue);

      final fetchedComplaint = await newRepository.getComplaintById('cmp_restart_test');
      expect(fetchedComplaint, isNotNull);
      expect(fetchedComplaint!.title, equals('Open Manhole'));
      expect(fetchedComplaint.syncStatus, equals(SyncStatus.pending));
      expect(fetchedComplaint.localId, equals('LOCAL-2026-000102'));

      final pendingList = await newRepository.getPendingComplaints();
      expect(pendingList.any((c) => c.id == 'cmp_restart_test'), isTrue);
    });

    test('updateSyncStatus transitions status and cleans up pending sync queue', () async {
      final complaint = ComplaintModel(
        id: 'cmp_sync_test',
        ticketNumber: 'LOCAL-2026-000103',
        localId: 'LOCAL-2026-000103',
        title: 'Garbage Dump',
        description: 'Piles of uncollected waste',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.92, longitude: 77.56, address: 'Market Lane'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveOfflineComplaint(complaint);
      expect((await repository.getPendingComplaints()).length, greaterThanOrEqualTo(1));

      // Transition to synced with serverId
      await repository.updateSyncStatus(
        'cmp_sync_test',
        SyncStatus.synced,
        serverId: 'srv_remote_999',
      );

      final updated = await repository.getComplaintById('cmp_sync_test');
      expect(updated, isNotNull);
      expect(updated!.syncStatus, equals(SyncStatus.synced));
      expect(updated.serverId, equals('srv_remote_999'));

      // Pending queue should no longer contain this item
      final pendingItem = await storageService.get<PendingSyncLocalModel>(
        HiveBoxes.pendingSync,
        'sync_cmp_sync_test',
      );
      expect(pendingItem, isNull);
    });
  });

  group('MockComplaintService Offline Flow Tests', () {
    test('Offline submission generates local ID and pending sync status', () async {
      connectivityService.setOnline(false);

      final draft = ComplaintDraft(
        title: 'Broken Traffic Light',
        category: CivicCategory.defaultCategories[2],
        description: 'Signals blinking red continuously causing traffic jam.',
        location: const CivicLocation(
          latitude: 12.97,
          longitude: 77.59,
          address: 'MG Road Junction',
          ward: 'Ward 14',
        ),
      );

      final result = await complaintService.submitComplaint(draft);

      expect(result.syncStatus, equals(SyncStatus.pending));
      expect(result.isOfflineDraft, isTrue);
      expect(result.ticketNumber.startsWith('LOCAL-'), isTrue);
      expect(result.localId, equals(result.ticketNumber));
      expect(result.status, equals(ComplaintStatus.reported));
      expect(result.timeline.first.title, equals('Saved Locally'));

      // Verify persisted in Hive
      final stored = await storageService.get<ComplaintLocalModel>(HiveBoxes.complaints, result.id);
      expect(stored, isNotNull);
      expect(stored!.syncStatus, equals('pending'));
    });

    test('Online submission generates server ID and synced status', () async {
      connectivityService.setOnline(true);

      final draft = ComplaintDraft(
        title: 'Road Pothole',
        category: CivicCategory.defaultCategories[0],
        description: 'Large trench near bus stop.',
        location: const CivicLocation(
          latitude: 12.97,
          longitude: 77.59,
          address: 'Bus Stand Road',
          ward: 'Ward 14',
        ),
      );

      final result = await complaintService.submitComplaint(draft);

      expect(result.syncStatus, equals(SyncStatus.synced));
      expect(result.isOfflineDraft, isFalse);
      expect(result.ticketNumber.startsWith('CF-'), isTrue);
    });
  });

  group('Offline UI Presentation Tests', () {
    testWidgets('ComplaintSubmittedScreen displays offline confirmation for pending complaints', (tester) async {
      final offlineComplaint = ComplaintModel(
        id: 'cmp_ui_test',
        ticketNumber: 'LOCAL-2026-000042',
        localId: 'LOCAL-2026-000042',
        title: 'Tree Fallen',
        description: 'Tree blocking driveway',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Garden Road'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintSubmittedScreen(complaint: offlineComplaint),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complaint Saved Offline'), findsOneWidget);
      expect(
        find.text("Complaint saved. It will be submitted when you're back online."),
        findsOneWidget,
      );
      expect(find.text('Local Reference'), findsOneWidget);
      expect(find.text('LOCAL-2026-000042'), findsOneWidget);
      expect(find.text('Pending Sync'), findsOneWidget);
    });

    testWidgets('ComplaintCard renders Pending Sync badge when complaint is offline draft', (tester) async {
      final offlineComplaint = ComplaintModel(
        id: 'cmp_card_test',
        ticketNumber: 'LOCAL-2026-000043',
        localId: 'LOCAL-2026-000043',
        title: 'Overflowing Waste Bin',
        description: 'Bins not collected for 3 days',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Park Avenue'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(
              complaint: offlineComplaint,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Sync'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('LOCAL-2026-000043'), findsOneWidget);
    });

    testWidgets('ComplaintPreviewCard renders Pending pill when complaint is offline draft', (tester) async {
      final offlineComplaint = ComplaintModel(
        id: 'cmp_preview_test',
        ticketNumber: 'LOCAL-2026-000044',
        localId: 'LOCAL-2026-000044',
        title: 'Damaged Footpath',
        description: 'Broken pavement tiles',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.low,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Mall Road'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintPreviewCard(
              complaint: offlineComplaint,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('ComplaintDetailsScreen renders waiting for connection banner when offline', (tester) async {
      final offlineComplaint = ComplaintModel(
        id: 'cmp_details_test',
        ticketNumber: 'LOCAL-2026-000045',
        localId: 'LOCAL-2026-000045',
        title: 'Street Waterlogging',
        description: 'Stagnant water accumulation',
        category: CivicCategory.defaultCategories[3],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Lower Cross'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailsScreen(
            complaint: offlineComplaint,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waiting for connection'), findsOneWidget);
      expect(
        find.text('Your complaint is stored securely on this device and will be submitted once internet is available.'),
        findsOneWidget,
      );
      expect(find.text('Pending Sync'), findsOneWidget);
    });
  });
}
