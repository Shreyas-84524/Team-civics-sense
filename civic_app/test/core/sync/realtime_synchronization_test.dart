import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/firestore/firebase_complaint_data_source.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';
import 'package:civic_app/core/repositories/offline_first_complaint_repository.dart';
import 'package:civic_app/core/sync/realtime_subscription_manager.dart';
import 'package:civic_app/User UI/screens/complaint_tracker_screen.dart';

/// Test double for ConnectivityService
class FakeConnectivityService implements ConnectivityService {
  bool _online;
  FakeConnectivityService({bool isOnline = true}) : _online = isOnline;

  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _online;

  @override
  bool get isOffline => !_online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }
}



/// Fake stream-enabled remote data source for testing real-time synchronization.
class FakeStreamComplaintDataSource extends FirebaseComplaintDataSource {
  final Map<String, ComplaintModel> remoteStore = {};
  final Map<String, StreamController<ComplaintModel?>> docControllers = {};
  final Map<String, StreamController<List<ComplaintModel>>> citizenControllers = {};
  final StreamController<List<ComplaintModel>> govtController =
      StreamController<List<ComplaintModel>>.broadcast();

  FakeStreamComplaintDataSource() : super(firestore: null);

  void emitDocUpdate(String id, ComplaintModel? model) {
    if (model != null) {
      remoteStore[id] = model;
    } else {
      remoteStore.remove(id);
    }
    if (docControllers.containsKey(id) && !docControllers[id]!.isClosed) {
      docControllers[id]!.add(model);
    }
  }

  void emitCitizenUpdate(String citizenId, List<ComplaintModel> list) {
    if (citizenControllers.containsKey(citizenId) && !citizenControllers[citizenId]!.isClosed) {
      citizenControllers[citizenId]!.add(list);
    }
  }

  @override
  Stream<ComplaintModel?> watchComplaint(String id) {
    if (!docControllers.containsKey(id)) {
      docControllers[id] = StreamController<ComplaintModel?>.broadcast();
    }
    return docControllers[id]!.stream;
  }

  @override
  Stream<List<ComplaintModel>> watchCitizenComplaints({
    required String citizenId,
    int limit = 50,
  }) {
    if (!citizenControllers.containsKey(citizenId)) {
      citizenControllers[citizenId] = StreamController<List<ComplaintModel>>.broadcast();
    }
    return citizenControllers[citizenId]!.stream;
  }

  @override
  Stream<List<ComplaintModel>> watchGovernmentComplaints({
    String? departmentId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    int limit = 50,
  }) {
    return govtController.stream;
  }

  void dispose() {
    for (final c in docControllers.values) {
      c.close();
    }
    for (final c in citizenControllers.values) {
      c.close();
    }
    govtController.close();
  }
}

void main() {
  group('RealtimeSubscriptionManager Tests', () {
    late RealtimeSubscriptionManager manager;

    setUp(() {
      manager = RealtimeSubscriptionManager();
    });

    tearDown(() async {
      await manager.cancelAll();
    });

    test('registers and cancels individual subscriptions', () async {
      final controller = StreamController<int>();

      final sub = controller.stream.listen((_) {});

      manager.register('sub_1', sub);
      expect(manager.contains('sub_1'), isTrue);
      expect(manager.activeSubscriptionCount, 1);
      expect(manager.activeKeys, contains('sub_1'));

      await manager.cancel('sub_1');
      expect(manager.contains('sub_1'), isFalse);
      expect(manager.activeSubscriptionCount, 0);

      await controller.close();
    });


    test('replaces existing subscription with duplicate key', () async {
      final controller1 = StreamController<int>();
      final controller2 = StreamController<int>();

      final sub1 = controller1.stream.listen((_) {});
      final sub2 = controller2.stream.listen((_) {});

      manager.register('key_dup', sub1);
      expect(manager.activeSubscriptionCount, 1);

      manager.register('key_dup', sub2);
      expect(manager.activeSubscriptionCount, 1);

      await manager.cancelAll();
      await controller1.close();
      await controller2.close();
    });

    test('cancels subscriptions by group tag', () async {
      final c1 = StreamController<int>();
      final c2 = StreamController<int>();
      final c3 = StreamController<int>();

      manager.register('u1_complaints', c1.stream.listen((_) {}), group: 'user_123');
      manager.register('u1_notifications', c2.stream.listen((_) {}), group: 'user_123');
      manager.register('hazards_public', c3.stream.listen((_) {}), group: 'public');

      expect(manager.activeSubscriptionCount, 3);

      await manager.cancelGroup('user_123');
      expect(manager.activeSubscriptionCount, 1);
      expect(manager.contains('hazards_public'), isTrue);
      expect(manager.contains('u1_complaints'), isFalse);

      await manager.cancelAll();
      await c1.close();
      await c2.close();
      await c3.close();
    });

    test('cancelAll cleanly terminates all active subscriptions', () async {
      final c1 = StreamController<int>();
      final c2 = StreamController<int>();

      manager.register('s1', c1.stream.listen((_) {}));
      manager.register('s2', c2.stream.listen((_) {}));
      expect(manager.activeSubscriptionCount, 2);

      await manager.cancelAll();
      expect(manager.activeSubscriptionCount, 0);

      await c1.close();
      await c2.close();
    });
  });

  group('OfflineFirstComplaintRepository Real-Time Stream Tests', () {
    late HiveComplaintRepository localRepo;
    late FakeStreamComplaintDataSource fakeRemote;
    late FakeConnectivityService fakeConnectivity;
    late OfflineFirstComplaintRepository repository;

    final testLocation = const CivicLocation(
      latitude: 12.9716,
      longitude: 77.5946,
      address: 'MG Road, Ward 14',
      ward: 'Ward 14 (Central)',
    );

    setUp(() {
      localRepo = HiveComplaintRepository();
      fakeRemote = FakeStreamComplaintDataSource();
      fakeConnectivity = FakeConnectivityService(isOnline: true);

      repository = OfflineFirstComplaintRepository(
        localRepository: localRepo,
        remoteDataSource: fakeRemote,
        connectivity: fakeConnectivity,
      );
    });

    tearDown(() {
      fakeRemote.dispose();
    });

    test('watchComplaint immediately yields cached local data then live remote status', () async {
      // 1. Create complaint locally
      final local = ComplaintModel(
        id: 'cmp_live_001',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000100',
        title: 'Water Pipe Leakage',
        description: 'Main pipe burst on 4th cross',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.high,
        location: testLocation,
        imageUrls: const ['https://storage.civicfix.org/leak.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      await localRepo.saveOfflineComplaint(local);

      final stream = repository.watchComplaint('cmp_live_001');
      final emissions = <ComplaintModel?>[];

      final sub = stream.listen((item) {
        emissions.add(item);
      });

      // Allow microtasks to process initial cache read
      await Future.delayed(const Duration(milliseconds: 50));

      expect(emissions.isNotEmpty, isTrue);
      expect(emissions.first?.status, ComplaintStatus.reported);

      // 2. Server transitions status to inProgress with officer notes
      final remoteUpdated = local.copyWith(
        status: ComplaintStatus.inProgress,
        officerNotes: 'Plumbing crew dispatched to site.',
        assignedTo: 'Officer Vikram Rao',
        timeline: [
          TimelineEvent(
            title: 'Reported',
            description: 'Created by citizen',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            status: ComplaintStatus.reported,
          ),
          TimelineEvent(
            title: 'Crew Dispatched',
            description: 'Plumbing crew dispatched to site.',
            timestamp: DateTime.now(),
            status: ComplaintStatus.inProgress,
            updatedBy: 'Officer Vikram Rao',
          ),
        ],
      );

      fakeRemote.emitDocUpdate('cmp_live_001', remoteUpdated);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(emissions.length, greaterThanOrEqualTo(2));
      final latest = emissions.last!;
      expect(latest.status, ComplaintStatus.inProgress);
      expect(latest.assignedTo, 'Officer Vikram Rao');
      expect(latest.officerNotes, 'Plumbing crew dispatched to site.');

      // Check Hive cache was updated with server status
      final cached = await localRepo.getComplaintById('cmp_live_001');
      expect(cached?.status, ComplaintStatus.inProgress);

      await sub.cancel();
    });

    test('watchCitizenComplaints protects pending offline drafts during remote merge', () async {
      // 1. Pending draft created offline
      final pendingDraft = ComplaintModel(
        id: 'cmp_offline_draft_001',
        localId: 'LOCAL-2026-000099',
        citizenId: 'user_citizen_001',
        ticketNumber: 'LOCAL-2026-000099',
        title: 'Pothole near park',
        description: 'Large crater in road',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: testLocation,
        imageUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await localRepo.saveOfflineComplaint(pendingDraft);

      final stream = repository.watchCitizenComplaints('user_citizen_001');
      final emissions = <List<ComplaintModel>>[];

      final sub = stream.listen((list) {
        emissions.add(list);
      });

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.first.any((c) => c.id == 'cmp_offline_draft_001'), isTrue);

      // 2. Server emits list of remote complaints that does NOT contain our pending draft
      final remoteSynced = ComplaintModel(
        id: 'srv_cmp_200',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000200',
        title: 'Streetlight Broken',
        description: 'Pole #42 dark',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.verified,
        priority: ComplaintPriority.low,
        location: testLocation,
        imageUrls: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        syncStatus: SyncStatus.synced,
      );

      fakeRemote.emitCitizenUpdate('user_citizen_001', [remoteSynced]);
      await Future.delayed(const Duration(milliseconds: 50));

      final latestList = emissions.last;
      // Pending draft MUST survive and be present at top of list
      expect(latestList.any((c) => c.id == 'cmp_offline_draft_001'), isTrue);
      expect(latestList.any((c) => c.id == 'srv_cmp_200'), isTrue);
      expect(latestList.first.id, 'cmp_offline_draft_001');

      await sub.cancel();
    });
  });

  group('Reactive UI Widget Tests', () {
    testWidgets('ComplaintTrackerScreen updates 5-stage tracker dynamically on stream event', (tester) async {
      final initialComplaint = ComplaintModel(
        id: 'cmp_tracker_001',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000555',
        title: 'Open Manhole',
        description: 'Dangerous manhole cover missing',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Brigade Road',
          ward: 'Ward 14 (Central)',
        ),
        imageUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        timeline: [
          TimelineEvent(
            title: 'Reported',
            description: 'Issue reported by citizen',
            timestamp: DateTime.now(),
            status: ComplaintStatus.reported,
          ),
        ],
      );

      final localRepo = HiveComplaintRepository();
      final fakeRemote = FakeStreamComplaintDataSource();
      final fakeConnectivity = FakeConnectivityService(isOnline: true);

      final repository = OfflineFirstComplaintRepository(
        localRepository: localRepo,
        remoteDataSource: fakeRemote,
        connectivity: fakeConnectivity,
      );

      await localRepo.saveOfflineComplaint(initialComplaint);

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintTrackerScreen(
            complaint: initialComplaint,
            repository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially shows Ticket reference & Reported status
      expect(find.text('CF-2026-000555'), findsOneWidget);
      expect(find.text('Reported'), findsWidgets);

      // Now stream an update transitioning status to inProgress with officer notes
      final updatedComplaint = initialComplaint.copyWith(
        status: ComplaintStatus.inProgress,
        officerNotes: 'Barricades placed. Repair crew on site.',
        timeline: [
          TimelineEvent(
            title: 'Reported',
            description: 'Issue reported by citizen',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            status: ComplaintStatus.reported,
          ),
          TimelineEvent(
            title: 'Work in Progress',
            description: 'Barricades placed. Repair crew on site.',
            timestamp: DateTime.now(),
            status: ComplaintStatus.inProgress,
            updatedBy: 'Chief Engineer',
          ),
        ],
      );

      fakeRemote.emitDocUpdate('cmp_tracker_001', updatedComplaint);

      await tester.pump();
      await tester.pumpAndSettle();

      // Verify that the UI reactively displays the new status and notes
      expect(find.text('Work in Progress'), findsWidgets);
      expect(find.text('Barricades placed. Repair crew on site.'), findsWidgets);

      fakeRemote.dispose();
    });
  });
}
