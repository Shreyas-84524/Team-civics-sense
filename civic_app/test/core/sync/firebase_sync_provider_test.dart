import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/errors/firestore_exception.dart';
import 'package:civic_app/core/firebase/firestore/firebase_complaint_data_source.dart';
import 'package:civic_app/core/firebase/storage/mock_evidence_storage_service.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/sync/models/sync_queue_item.dart';
import 'package:civic_app/core/sync/providers/firebase_sync_provider.dart';
import 'package:civic_app/core/sync/providers/mock_sync_provider.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';
import 'package:civic_app/core/sync/retry/retry_policy.dart';
import 'package:civic_app/core/sync/sync_manager.dart';

/// Test double for FirebaseComplaintDataSource to run in headless test environments.
class FakeFirebaseComplaintDataSource extends FirebaseComplaintDataSource {
  final Map<String, ComplaintModel> createdComplaints = {};
  final List<String> upvotedComplaintIds = [];
  final Map<String, List<String>> updatedImageUrls = {};
  bool simulateFirestoreError = false;
  bool isRecoverableError = true;

  FakeFirebaseComplaintDataSource() : super(firestore: null);

  @override
  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {
    if (simulateFirestoreError) {
      throw FirestoreException(
        code: isRecoverableError ? 'unavailable' : 'permission-denied',
        message: 'Simulated Firestore create failure',
      );
    }

    final serverId = 'srv_${complaint.id}';
    final saved = complaint.copyWith(
      id: serverId,
      serverId: serverId,
      syncStatus: SyncStatus.synced,
    );
    createdComplaints[complaint.id] = saved;
    createdComplaints[serverId] = saved;
    return saved;
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id, {bool includeTimeline = true}) async {
    return createdComplaints[id];
  }

  @override
  Future<void> updateCitizenComplaint(
    String complaintId, {
    String? title,
    String? description,
    List<String>? imageUrls,
    CivicLocation? location,
  }) async {
    if (simulateFirestoreError) {
      throw FirestoreException(
        code: isRecoverableError ? 'unavailable' : 'permission-denied',
        message: 'Simulated update failure',
      );
    }

    if (imageUrls != null) {
      updatedImageUrls[complaintId] = imageUrls;
    }
  }

  @override
  Future<void> upvoteComplaint(String complaintId, {String? userId}) async {
    if (simulateFirestoreError) {
      throw const FirestoreException(
        code: 'unavailable',
        message: 'Simulated upvote failure',
      );
    }
    upvotedComplaintIds.add(complaintId);
  }
}

/// Fake connectivity service for test control.
class FakeConnectivityService implements ConnectivityService {
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

  group('FirebaseSyncProvider Unit Tests', () {
    late FakeFirebaseComplaintDataSource fakeDataSource;
    late MockEvidenceStorageService mockStorageService;
    late FirebaseSyncProvider syncProvider;

    setUp(() {
      fakeDataSource = FakeFirebaseComplaintDataSource();
      mockStorageService = MockEvidenceStorageService();
      mockStorageService.latency = Duration.zero;

      syncProvider = FirebaseSyncProvider(
        complaintDataSource: fakeDataSource,
        evidenceStorageService: mockStorageService,
      );
    });

    test('CREATE_COMPLAINT succeeds and maps remote serverId accurately', () async {
      final item = SyncQueueItem(
        id: 'sync_cmp_101',
        entityType: 'complaint',
        entityId: 'cmp_101',
        operation: SyncOperation.createComplaint,
        payload: {
          'id': 'cmp_101',
          'localId': 'cmp_101',
          'citizenId': 'usr_citizen_001',
          'ticketNumber': 'CF-2026-000101',
          'title': 'Broken Pavement',
          'description': 'Deep crater on pedestrian walkway',
          'categoryId': 'roads',
          'categoryName': 'Roads & Footpaths',
          'priority': 'high',
          'latitude': 12.9716,
          'longitude': 77.5946,
          'imageUrls': ['https://firebasestorage.googleapis.com/.../pothole.jpg'],
        },
        createdAt: DateTime.now(),
      );

      final result = await syncProvider.execute(item);

      expect(result.isSuccess, isTrue);
      expect(result.serverId, equals('srv_cmp_101'));
      expect(result.isPartialFailure, isFalse);
      expect(fakeDataSource.createdComplaints.containsKey('cmp_101'), isTrue);
    });

    test('CREATE_COMPLAINT is idempotent and returns existing serverId without duplicates', () async {
      final item = SyncQueueItem(
        id: 'sync_cmp_102',
        entityType: 'complaint',
        entityId: 'cmp_102',
        operation: SyncOperation.createComplaint,
        payload: {
          'id': 'cmp_102',
          'localId': 'cmp_102',
          'title': 'Streetlight Broken',
          'ticketNumber': 'CF-2026-000102',
          'imageUrls': <String>[],
        },
        createdAt: DateTime.now(),
      );

      // First run: Creates remote document
      final firstResult = await syncProvider.execute(item);
      expect(firstResult.isSuccess, isTrue);
      expect(firstResult.serverId, equals('srv_cmp_102'));

      // Second run (simulated retry): Hits idempotency check
      final secondResult = await syncProvider.execute(item);
      expect(secondResult.isSuccess, isTrue);
      expect(secondResult.serverId, equals('srv_cmp_102'));
      expect(secondResult.responseData?['idempotent'], isTrue);
    });

    test('CREATE_COMPLAINT handles mock media upload and reports success', () async {
      final item = SyncQueueItem(
        id: 'sync_cmp_103',
        entityType: 'complaint',
        entityId: 'cmp_103',
        operation: SyncOperation.createComplaint,
        payload: {
          'id': 'cmp_103',
          'localId': 'cmp_103',
          'title': 'Garbage Overflow',
          'ticketNumber': 'CF-2026-000103',
          'imageUrls': ['mock://camera/captured_photo_1.jpg'],
        },
        createdAt: DateTime.now(),
      );

      final result = await syncProvider.execute(item);

      expect(result.isSuccess, isTrue);
      expect(result.serverId, equals('srv_cmp_103'));
      expect(result.uploadedImageUrls.length, equals(1));
      expect(result.uploadedImageUrls.first.contains('civicfix-38d53.appspot.com'), isTrue);
    });

    test('UPLOAD_EVIDENCE updates Firestore complaint with resolved download URLs', () async {
      // Seed an existing complaint in fake data source
      fakeDataSource.createdComplaints['srv_cmp_104'] = ComplaintModel(
        id: 'srv_cmp_104',
        ticketNumber: 'CF-2026-000104',
        title: 'Water Leak',
        description: 'Pipe leaking',
        category: const CivicCategory(
          id: 'water',
          name: 'Water Supply',
          description: '',
          icon: Icons.water_drop,
        ),
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 12.0, longitude: 77.0, address: 'Main Street'),
        imageUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item = SyncQueueItem(
        id: 'sync_ev_104',
        entityType: 'evidence',
        entityId: 'cmp_104',
        operation: SyncOperation.uploadEvidence,
        payload: {
          'complaintId': 'cmp_104',
          'serverId': 'srv_cmp_104',
          'imageUrls': ['mock://camera/leak_photo.jpg'],
        },
        createdAt: DateTime.now(),
      );

      final result = await syncProvider.execute(item);

      expect(result.isSuccess, isTrue);
      expect(result.uploadedImageUrls.length, equals(1));
      expect(fakeDataSource.updatedImageUrls.containsKey('srv_cmp_104'), isTrue);
    });

    test('UPVOTE_COMPLAINT executes remote atomic upvote', () async {
      final item = SyncQueueItem(
        id: 'sync_upvote_105',
        entityType: 'upvote',
        entityId: 'cmp_105',
        operation: SyncOperation.upvoteComplaint,
        createdAt: DateTime.now(),
      );

      final result = await syncProvider.execute(item);

      expect(result.isSuccess, isTrue);
      expect(fakeDataSource.upvotedComplaintIds.contains('cmp_105'), isTrue);
    });

    test('UPDATE_COMPLAINT updates remote title, description, and location', () async {
      final item = SyncQueueItem(
        id: 'sync_update_106',
        entityType: 'complaint',
        entityId: 'srv_cmp_106',
        operation: SyncOperation.updateComplaint,
        payload: {
          'serverId': 'srv_cmp_106',
          'title': 'Updated Title',
          'description': 'Updated Description',
        },
        createdAt: DateTime.now(),
      );

      final result = await syncProvider.execute(item);

      expect(result.isSuccess, isTrue);
      expect(result.serverId, equals('srv_cmp_106'));
    });

    test('Classifies recoverable Firestore exceptions and preserves retry flag', () async {
      fakeDataSource.simulateFirestoreError = true;
      fakeDataSource.isRecoverableError = true;

      final item = SyncQueueItem(
        id: 'sync_err_107',
        entityType: 'complaint',
        entityId: 'cmp_107',
        operation: SyncOperation.createComplaint,
        payload: {'id': 'cmp_107'},
        createdAt: DateTime.now(),
      );

      final result = await syncProvider.execute(item);

      expect(result.isSuccess, isFalse);
      expect(result.isRecoverable, isTrue);
    });

    test('Classifies non-recoverable Firestore exceptions (permission denied)', () async {
      fakeDataSource.simulateFirestoreError = true;
      fakeDataSource.isRecoverableError = false;

      final item = SyncQueueItem(
        id: 'sync_err_108',
        entityType: 'complaint',
        entityId: 'cmp_108',
        operation: SyncOperation.createComplaint,
        payload: {'id': 'cmp_108'},
        createdAt: DateTime.now(),
      );

      final result = await syncProvider.execute(item);

      expect(result.isSuccess, isFalse);
      expect(result.isRecoverable, isFalse);
    });
  });

  group('SyncManager with FirebaseSyncProvider End-to-End Tests', () {
    late HiveSyncQueue queue;
    late FakeConnectivityService connectivity;
    late MockComplaintRepository repository;
    late FakeFirebaseComplaintDataSource fakeDataSource;
    late MockEvidenceStorageService mockStorageService;
    late FirebaseSyncProvider firebaseProvider;
    late SyncManager syncManager;

    setUp(() {
      queue = HiveSyncQueue();
      connectivity = FakeConnectivityService();
      repository = MockComplaintRepository();
      fakeDataSource = FakeFirebaseComplaintDataSource();
      mockStorageService = MockEvidenceStorageService();
      mockStorageService.latency = Duration.zero;

      firebaseProvider = FirebaseSyncProvider(
        complaintDataSource: fakeDataSource,
        evidenceStorageService: mockStorageService,
      );

      syncManager = SyncManager.createForTesting(
        queue: queue,
        provider: firebaseProvider,
        connectivity: connectivity,
        repository: repository,
        retryPolicy: RetryPolicy(maxRetries: 3),
      );
    });

    tearDown(() {
      syncManager.dispose();
      queue.dispose();
      connectivity.dispose();
    });

    test('Successfully synchronizes offline complaint to Firebase and transitions local state', () async {
      // 1. Create offline complaint
      final localComplaint = ComplaintModel(
        id: 'cmp_offline_201',
        citizenId: 'usr_citizen_001',
        ticketNumber: 'CF-2026-000201',
        title: 'Fallen Tree on Road',
        description: 'Blocking 2nd Main Road traffic',
        category: const CivicCategory(
          id: 'trees',
          name: 'Fallen Trees',
          description: '',
          icon: Icons.park,
        ),
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(latitude: 12.9716, longitude: 77.5946, address: '2nd Main Road'),
        imageUrls: const ['https://firebasestorage.googleapis.com/.../tree.jpg'],
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveOfflineComplaint(localComplaint);
      expect(repository.getPendingComplaints(), completion(hasLength(1)));

      // 2. Queue complaint in SyncManager
      await syncManager.queueComplaintCreation(localComplaint);

      // 3. Verify queue is drained and local complaint is synced with remote serverId
      final allQueueItems = await queue.getAllItems();
      expect(allQueueItems, isEmpty);

      final updatedComplaint = await repository.getComplaintById('cmp_offline_201');
      expect(updatedComplaint, isNotNull);
      expect(updatedComplaint!.syncStatus, equals(SyncStatus.synced));
      expect(updatedComplaint.serverId, equals('srv_cmp_offline_201'));
    });

    test('SyncManager setProvider dynamically updates synchronization provider', () {
      expect(syncManager.provider, equals(firebaseProvider));

      final mockProvider = MockSyncProvider();
      syncManager.setProvider(mockProvider);

      expect(syncManager.provider, equals(mockProvider));
    });
  });
}
