import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/errors/firestore_exception.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/firebase/firestore/firebase_complaint_data_source.dart';
import 'package:civic_app/core/firebase/firestore/firestore_pagination.dart';
import 'package:civic_app/core/firebase/storage/mock_evidence_storage_service.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_upvote_result.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';
import 'package:civic_app/core/repositories/offline_first_complaint_repository.dart';
import 'package:civic_app/core/sync/providers/firebase_sync_provider.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';
import 'package:civic_app/core/sync/retry/retry_policy.dart';
import 'package:civic_app/core/sync/sync_manager.dart';

/// Test double for FirebaseComplaintDataSource in repository tests.
class FakeRemoteComplaintDataSource extends FirebaseComplaintDataSource {
  final Map<String, ComplaintModel> remoteComplaints = {};
  final List<String> upvotedIds = [];
  final Set<String> userUpvotes = {};
  bool simulateError = false;

  FakeRemoteComplaintDataSource() : super(firestore: null);

  @override
  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {
    if (simulateError) {
      throw const FirestoreException(
        code: 'unavailable',
        message: 'Simulated remote create error',
      );
    }
    final serverId = 'srv_${complaint.id}';
    final saved = complaint.copyWith(
      id: serverId,
      serverId: serverId,
      ticketNumber: complaint.ticketNumber.startsWith('LOCAL-')
          ? 'CF-2026-${complaint.id.hashCode.abs().toString().padLeft(6, '0')}'
          : complaint.ticketNumber,
      syncStatus: SyncStatus.synced,
    );
    remoteComplaints[complaint.id] = saved;
    remoteComplaints[serverId] = saved;
    return saved;
  }

  @override
  Future<FirestorePage<ComplaintModel>> getCitizenComplaints({
    required String citizenId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (simulateError) {
      throw const FirestoreException(
        code: 'unavailable',
        message: 'Simulated fetch error',
      );
    }
    final items = remoteComplaints.values
        .where((c) => c.citizenId == citizenId || citizenId.isEmpty)
        .toList();
    return FirestorePage<ComplaintModel>(items: items, hasMore: false);
  }

  @override
  Future<FirestorePage<ComplaintModel>> getGovernmentComplaints({
    String? departmentId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (simulateError) {
      throw const FirestoreException(
        code: 'unavailable',
        message: 'Simulated fetch error',
      );
    }
    return FirestorePage<ComplaintModel>(
      items: remoteComplaints.values.toList(),
      hasMore: false,
    );
  }

  @override
  Future<ComplaintModel?> getComplaintById(
    String id, {
    bool includeTimeline = true,
  }) async {
    return remoteComplaints[id];
  }

  @override
  Future<ComplaintModel?> getComplaintByTicketNumber(
    String ticketNumber,
  ) async {
    try {
      return remoteComplaints.values.firstWhere(
        (c) => c.ticketNumber == ticketNumber,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ComplaintModel>> getNearbyHazards({int limit = 50}) async {
    return remoteComplaints.values
        .where(
          (c) =>
              c.isHazard ||
              c.priority == ComplaintPriority.emergency ||
              c.priority == ComplaintPriority.high,
        )
        .toList();
  }

  @override
  Future<ComplaintUpvoteResult> upvoteComplaint(
    String complaintId, {
    required String userId,
  }) async {
    final current = remoteComplaints[complaintId];
    final currentCount = current?.upvotes ?? 0;
    if (!userUpvotes.add('$userId::$complaintId')) {
      return ComplaintUpvoteResult(added: false, upvotes: currentCount);
    }
    upvotedIds.add(complaintId);
    final updatedCount = currentCount + 1;
    if (current != null) {
      remoteComplaints[complaintId] = current.copyWith(upvotes: updatedCount);
    }
    return ComplaintUpvoteResult(added: true, upvotes: updatedCount);
  }
}

/// Fake connectivity service for deterministic test control.
class TestConnectivityService implements ConnectivityService {
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

/// Fake data source throwing a non-recoverable permission-denied error.
class _PermissionDeniedRemoteComplaintDataSource
    extends FakeRemoteComplaintDataSource {
  @override
  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {
    throw const FirestorePermissionDeniedException(
      'Permission denied by Firestore security rules.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineFirstComplaintRepository Unit & Integration Tests', () {
    late HiveComplaintRepository localRepo;
    late FakeRemoteComplaintDataSource remoteDataSource;
    late MockEvidenceStorageService mockStorage;
    late TestConnectivityService connectivity;
    late HiveSyncQueue syncQueue;
    late FirebaseSyncProvider firebaseSyncProvider;
    late SyncManager syncManager;
    late OfflineFirstComplaintRepository repository;

    setUp(() {
      AuthServiceLocator.useMockServices();
      localRepo = HiveComplaintRepository();
      remoteDataSource = FakeRemoteComplaintDataSource();
      mockStorage = MockEvidenceStorageService()..latency = Duration.zero;
      connectivity = TestConnectivityService();
      syncQueue = HiveSyncQueue();

      firebaseSyncProvider = FirebaseSyncProvider(
        complaintDataSource: remoteDataSource,
        evidenceStorageService: mockStorage,
      );

      syncManager = SyncManager.createForTesting(
        queue: syncQueue,
        provider: firebaseSyncProvider,
        connectivity: connectivity,
        repository: localRepo,
        retryPolicy: RetryPolicy(maxRetries: 3),
      );

      repository = OfflineFirstComplaintRepository(
        localRepository: localRepo,
        remoteDataSource: remoteDataSource,
        evidenceStorageService: mockStorage,
        syncManager: syncManager,
        connectivity: connectivity,
      );
    });

    tearDown(() {
      syncManager.dispose();
      syncQueue.dispose();
      connectivity.dispose();
      AuthServiceLocator.reset();
    });

    test(
      'READ: Returns instantly from Hive local cache when offline',
      () async {
        connectivity.setOnline(false);

        // Seed a complaint in local repo
        final seed = ComplaintModel(
          id: 'cmp_offline_001',
          citizenId: 'user_001',
          ticketNumber: 'LOCAL-2026-000001',
          title: 'Offline Water Leak',
          description: 'Pipe broken near bus stop',
          category: const CivicCategory(
            id: 'water',
            name: 'Water Supply',
            description: '',
            icon: Icons.water_drop,
          ),
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(
            latitude: 12.0,
            longitude: 77.0,
            address: 'Bus Stop',
          ),
          imageUrls: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pending,
        );

        await localRepo.saveOfflineComplaint(seed);

        final results = await repository.getCitizenComplaints('user_001');
        expect(results, isNotEmpty);
        expect(results.first.id, equals('cmp_offline_001'));
        expect(results.first.syncStatus, equals(SyncStatus.pending));
      },
    );

    test(
      'READ: Online query triggers remote refresh and merges into local cache',
      () async {
        connectivity.setOnline(true);

        // Seed a remote complaint
        final remoteDoc = ComplaintModel(
          id: 'srv_cmp_remote_002',
          citizenId: 'user_001',
          ticketNumber: 'CF-2026-000002',
          title: 'Pothole on Ring Road',
          description: 'Large crater in middle lane',
          category: const CivicCategory(
            id: 'roads',
            name: 'Roads & Footpaths',
            description: '',
            icon: Icons.alt_route,
          ),
          status: ComplaintStatus.verified,
          priority: ComplaintPriority.high,
          location: const CivicLocation(
            latitude: 12.5,
            longitude: 77.5,
            address: 'Ring Road',
          ),
          imageUrls: const [
            'https://firebasestorage.googleapis.com/.../pothole.jpg',
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        );
        remoteDataSource.remoteComplaints['srv_cmp_remote_002'] = remoteDoc;

        final results = await repository.getCitizenComplaints('user_001');

        expect(results.any((c) => c.id == 'srv_cmp_remote_002'), isTrue);
        final mergedItem = results.firstWhere(
          (c) => c.id == 'srv_cmp_remote_002',
        );
        expect(mergedItem.status, equals(ComplaintStatus.verified));
        expect(mergedItem.syncStatus, equals(SyncStatus.synced));
      },
    );

    test('Browser data URI photos upload and tickets stay unique across sessions', () async {
      final bytes = List<int>.filled(512, 0);
      bytes.setRange(0, 4, [0x89, 0x50, 0x4e, 0x47]);
      final photo = Uri.dataFromBytes(bytes, mimeType: 'image/png').toString();
      Future<ComplaintModel> submit(OfflineFirstComplaintRepository repo) => repo.createComplaint(
        citizenId: 'user_001', title: 'Browser photo', description: 'Photo regression',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(latitude: 19, longitude: 72, address: 'Mumbai'),
        priority: ComplaintPriority.medium, imageUrls: [photo],
      );
      final first = await submit(repository);
      final second = await submit(OfflineFirstComplaintRepository(
        localRepository: localRepo, remoteDataSource: remoteDataSource,
        evidenceStorageService: mockStorage, syncManager: syncManager,
        connectivity: connectivity,
      ));
      expect(first.syncStatus, SyncStatus.synced);
      expect(first.imageUrls.single, isNot(startsWith('data:')));
      expect(first.ticketNumber, isNot(second.ticketNumber));
      expect(await syncQueue.getAllItems(), isEmpty);
    });

    test(
      'REMOTE-FIRST: Online create saves directly to Firestore, sets synced status, and does NOT enqueue in SyncManager',
      () async {
        connectivity.setOnline(true);

        final complaint = await repository.createComplaint(
          citizenId: 'user_online_001',
          title: 'Dangerous Manhole Cover',
          description: 'Broken metal lid on pedestrian footpath',
          category: const CivicCategory(
            id: 'roads',
            name: 'Roads & Footpaths',
            description: '',
            icon: Icons.alt_route,
          ),
          location: const CivicLocation(
            latitude: 12.93,
            longitude: 77.63,
            address: '100ft Road, Indiranagar',
          ),
          priority: ComplaintPriority.high,
          imageUrls: const ['mock://camera/manhole.jpg'],
          isHazard: true,
        );

        // 1. Authoritative real ticket assigned immediately
        expect(complaint.syncStatus, equals(SyncStatus.synced));
        expect(complaint.ticketNumber.startsWith('CF-2026-'), isTrue);
        expect(complaint.imageUrls.first, contains('supabase.co'));

        // 2. Created in remote Firestore
        expect(
          remoteDataSource.remoteComplaints.containsKey(complaint.id),
          isTrue,
        );

        // 3. Stored in Hive cache as SYNCED
        final cached = await localRepo.getComplaintById(complaint.id);
        expect(cached, isNotNull);
        expect(cached!.syncStatus, equals(SyncStatus.synced));

        // 4. Critical Invariant: Zero items enqueued in SyncQueue!
        final queueItems = await syncQueue.getAllItems();
        expect(queueItems, isEmpty);
      },
    );

    test(
      'OFFLINE FALLBACK: Offline create stores in Hive with pending status, LOCAL- ticket, and enqueues to SyncManager',
      () async {
        connectivity.setOnline(false);

        final newComplaint = await repository.createComplaint(
          citizenId: 'user_001',
          title: 'Broken Streetlight',
          description: 'Dark corner at 5th cross',
          category: const CivicCategory(
            id: 'electricity',
            name: 'Electricity',
            description: '',
            icon: Icons.electric_bolt,
          ),
          location: const CivicLocation(
            latitude: 12.9,
            longitude: 77.6,
            address: '5th Cross',
          ),
          priority: ComplaintPriority.medium,
          imageUrls: const ['mock://camera/photo1.jpg'],
          isHazard: false,
        );

        expect(newComplaint.syncStatus, equals(SyncStatus.pending));
        expect(newComplaint.ticketNumber.startsWith('LOCAL-2026-'), isTrue);
        expect(newComplaint.upvotes, equals(0));

        // Verify stored in local repo
        final pendingList = await repository.getPendingComplaints();
        expect(pendingList.any((c) => c.id == newComplaint.id), isTrue);

        // Verify enqueued in SyncQueue
        final queueItems = await syncQueue.getAllItems();
        expect(queueItems.any((i) => i.entityId == newComplaint.id), isTrue);
      },
    );

    test(
      'TRANSIENT ERROR FALLBACK: Online creation encountering recoverable Firestore error falls back to Hive offline queue',
      () async {
        connectivity.setOnline(true);
        remoteDataSource.simulateError =
            true; // Simulates FirestoreException('unavailable')

        final fallbackComplaint = await repository.createComplaint(
          citizenId: 'user_transient_001',
          title: 'Fallen Tree Branch',
          description: 'Blocking arterial roadway after heavy storm',
          category: const CivicCategory(
            id: 'trees',
            name: 'Parks & Trees',
            description: '',
            icon: Icons.park,
          ),
          location: const CivicLocation(
            latitude: 12.95,
            longitude: 77.60,
            address: 'Outer Ring Rd',
          ),
          priority: ComplaintPriority.high,
          imageUrls: const ['mock://camera/branch.jpg'],
          isHazard: true,
        );

        // Gracefully falls back to offline model
        expect(fallbackComplaint.syncStatus, equals(SyncStatus.pending));
        expect(
          fallbackComplaint.ticketNumber.startsWith('LOCAL-2026-'),
          isTrue,
        );

        // Enqueued in SyncManager queue for retry
        final queueItems = await syncQueue.getAllItems();
        expect(
          queueItems.any((i) => i.entityId == fallbackComplaint.id),
          isTrue,
        );
      },
    );

    test(
      'PERMANENT ERROR REJECTION: Online creation encountering non-recoverable error rethrows and does NOT enqueue zombie item',
      () async {
        connectivity.setOnline(true);

        // Construct a fake data source that throws a non-recoverable permission-denied error
        final permissionDeniedDataSource =
            _PermissionDeniedRemoteComplaintDataSource();
        final permDeniedRepo = OfflineFirstComplaintRepository(
          localRepository: localRepo,
          remoteDataSource: permissionDeniedDataSource,
          evidenceStorageService: mockStorage,
          syncManager: syncManager,
          connectivity: connectivity,
        );

        expect(
          () => permDeniedRepo.createComplaint(
            citizenId: 'unauthorized_user',
            title: 'Unauthorized Ticket',
            description: 'Should fail immediately',
            category: const CivicCategory(
              id: 'general',
              name: 'General',
              description: '',
              icon: Icons.info,
            ),
            location: const CivicLocation(
              latitude: 12.0,
              longitude: 77.0,
              address: 'Restricted Area',
            ),
            priority: ComplaintPriority.low,
          ),
          throwsA(isA<FirestorePermissionDeniedException>()),
        );

        // Invariant: No zombie items queued in SyncQueue!
        final queueItems = await syncQueue.getAllItems();
        expect(queueItems, isEmpty);
      },
    );

    test('LOCAL-PATH DATA LOSS PROTECTION: '
        'When evidence upload fails (recoverable), raw local path must NOT be written to Firestore. '
        'Complaint must fall back to Hive offline queue.', () async {
      // Use an isolated remoteDataSource for this test so background SyncManager
      // drains from prior tests do not contaminate the assertion.
      final isolatedRemote = FakeRemoteComplaintDataSource();
      final isolatedStorage = MockEvidenceStorageService()
        ..latency = Duration.zero
        ..simulateNetworkError = true; // Simulate transient Supabase failure.

      final isolatedRepo = OfflineFirstComplaintRepository(
        localRepository: localRepo,
        remoteDataSource: isolatedRemote,
        evidenceStorageService: isolatedStorage,
        syncManager: syncManager,
        connectivity: connectivity,
      );

      connectivity.setOnline(true);

      // Submit with a mock:// evidence reference (local media file).
      final result = await isolatedRepo.createComplaint(
        citizenId: 'citizen_storage_fail',
        title: 'Storage Fail Test',
        description: 'Evidence upload will fail transiently',
        category: const CivicCategory(
          id: 'roads',
          name: 'Roads',
          description: '',
          icon: Icons.alt_route,
        ),
        location: const CivicLocation(
          latitude: 19.24,
          longitude: 72.86,
          address: 'Test Location',
        ),
        priority: ComplaintPriority.medium,
        imageUrls: const ['mock://evidence_photo_01.jpg'],
      );

      // Must have fallen back to offline queue — LOCAL-* ticket.
      expect(
        result.ticketNumber,
        startsWith('LOCAL-'),
        reason: 'Complaint must be saved offline when upload fails.',
      );
      expect(
        result.syncStatus,
        equals(SyncStatus.pending),
        reason: 'Offline fallback must be pending sync.',
      );

      // Firestore must NOT have received a createComplaint call from this test.
      expect(
        isolatedRemote.remoteComplaints,
        isEmpty,
        reason: 'Firestore must not be called when evidence upload fails.',
      );

      // The LOCAL-* complaint must be persisted in Hive with pending status.
      // Verify directly from the returned model — this is the state at save time,
      // unaffected by background SyncManager drains from other tests.
      expect(
        result.id,
        startsWith('cmp_local_'),
        reason: 'Local offline complaint must have a cmp_local_ id prefix.',
      );

      // CRITICAL: No entry that this test submitted may contain a raw local filesystem path.
      for (final complaint in isolatedRemote.remoteComplaints.values) {
        for (final url in complaint.imageUrls) {
          expect(
            url.startsWith('http://') ||
                url.startsWith('https://') ||
                url.startsWith('mock://'),
            isTrue,
            reason:
                'Firestore imageUrls must never contain raw local filesystem paths. Found: $url',
          );
        }
      }
    });

    test(
      'SYNC: Reconnecting online automatically drains queue and marks complaint as synced',
      () async {
        connectivity.setOnline(false);

        final complaint = await repository.createComplaint(
          citizenId: 'user_001',
          title: 'Overflowing Dustbin',
          description: 'Garbage spilling onto pavement',
          category: const CivicCategory(
            id: 'garbage',
            name: 'Solid Waste',
            description: '',
            icon: Icons.delete,
          ),
          location: const CivicLocation(
            latitude: 12.92,
            longitude: 77.62,
            address: 'Market Road',
          ),
          priority: ComplaintPriority.high,
          imageUrls: const ['mock://camera/bin.jpg'],
        );

        expect(complaint.syncStatus, equals(SyncStatus.pending));

        // Reconnect online
        connectivity.setOnline(true);
        await syncManager.processQueue();

        // Verify queue drained
        final remainingQueue = await syncQueue.getAllItems();
        expect(remainingQueue, isEmpty);

        // Verify local complaint status transitioned to synced with remote serverId
        final syncedLocal = await repository.getComplaintById(complaint.id);
        expect(syncedLocal, isNotNull);
        expect(syncedLocal!.syncStatus, equals(SyncStatus.synced));
        expect(syncedLocal.serverId, startsWith('srv_'));
      },
    );

    test(
      'CONFLICT RESOLUTION: Server status updates merge into local cache without clobbering pending local drafts',
      () async {
        connectivity.setOnline(false);

        // 1. User files complaint offline
        final localPending = await repository.createComplaint(
          citizenId: 'user_001',
          title: 'Pending Draft Title',
          description: 'Pending Draft Description',
          category: const CivicCategory(
            id: 'roads',
            name: 'Roads',
            description: '',
            icon: Icons.alt_route,
          ),
          location: const CivicLocation(
            latitude: 12.0,
            longitude: 77.0,
            address: 'Road 1',
          ),
          priority: ComplaintPriority.medium,
        );

        // 2. Server has an updated version with officer notes & verified status
        final serverVersion = ComplaintModel(
          id: localPending.id,
          serverId: 'srv_${localPending.id}',
          citizenId: 'user_001',
          ticketNumber: 'CF-2026-999888',
          title: 'Old Server Title',
          description: 'Old Server Description',
          category: localPending.category,
          status: ComplaintStatus.verified,
          priority: ComplaintPriority.high,
          location: localPending.location,
          imageUrls: const [],
          assignedTo: 'Officer Sharma',
          departmentName: 'Roads & Infrastructure',
          officerNotes: 'Verified during site inspection.',
          createdAt: localPending.createdAt,
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        );
        remoteDataSource.remoteComplaints[localPending.id] = serverVersion;

        // 3. Reconnect and fetch
        connectivity.setOnline(true);
        final mergedList = await repository.getCitizenComplaints('user_001');

        final merged = mergedList.firstWhere(
          (c) =>
              c.id == localPending.id || c.serverId == 'srv_${localPending.id}',
        );

        // Invariant: Pending local user edits are preserved!
        expect(merged.title, equals('Pending Draft Title'));
        expect(merged.description, equals('Pending Draft Description'));

        // Invariant: Server-authoritative workflow status and officer notes are merged!
        expect(merged.status, equals(ComplaintStatus.verified));
        expect(merged.assignedTo, equals('Officer Sharma'));
        expect(merged.departmentName, equals('Roads & Infrastructure'));
        expect(merged.officerNotes, equals('Verified during site inspection.'));
      },
    );

    test(
      'OPTI-UPVOTE: Optimistically increments locally and pushes remote upvote',
      () async {
        // Seed a complaint
        final complaint = ComplaintModel(
          id: 'cmp_upvote_001',
          citizenId: 'user_002',
          ticketNumber: 'CF-2026-000555',
          title: 'Traffic Signal Malfunction',
          description: 'Signal stuck on red',
          category: const CivicCategory(
            id: 'traffic',
            name: 'Traffic',
            description: '',
            icon: Icons.traffic,
          ),
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.emergency,
          location: const CivicLocation(
            latitude: 12.9,
            longitude: 77.5,
            address: 'Crossroad',
          ),
          imageUrls: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          upvotes: 5,
          syncStatus: SyncStatus.synced,
        );

        await localRepo.saveOfflineComplaint(complaint);
        remoteDataSource.remoteComplaints['cmp_upvote_001'] = complaint;

        connectivity.setOnline(true);
        final firstResult = await repository.upvoteComplaint('cmp_upvote_001');

        final updatedLocal = await repository.getComplaintById(
          'cmp_upvote_001',
        );
        expect(firstResult.added, isTrue);
        expect(firstResult.upvotes, equals(6));
        expect(updatedLocal!.upvotes, equals(6));
        expect(remoteDataSource.upvotedIds.contains('cmp_upvote_001'), isTrue);

        final duplicateResult = await repository.upvoteComplaint(
          'cmp_upvote_001',
        );
        final afterDuplicate = await repository.getComplaintById(
          'cmp_upvote_001',
        );
        expect(duplicateResult.added, isFalse);
        expect(duplicateResult.upvotes, equals(6));
        expect(afterDuplicate!.upvotes, equals(6));
        expect(
          remoteDataSource.upvotedIds.where((id) => id == 'cmp_upvote_001'),
          hasLength(1),
        );
      },
    );

    test(
      'DATA LOSS PROTECTION: clearStaleComplaints strictly preserves pending sync items',
      () async {
        // 1. Save old resolved complaint (synced)
        final oldResolved = ComplaintModel(
          id: 'cmp_old_resolved',
          citizenId: 'user_001',
          ticketNumber: 'CF-2026-000001',
          title: 'Old Pothole Fixed',
          description: 'Fixed last month',
          category: const CivicCategory(
            id: 'roads',
            name: 'Roads',
            description: '',
            icon: Icons.alt_route,
          ),
          status: ComplaintStatus.resolved,
          priority: ComplaintPriority.low,
          location: const CivicLocation(
            latitude: 12.0,
            longitude: 77.0,
            address: 'Old St',
          ),
          imageUrls: const [],
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
          syncStatus: SyncStatus.synced,
        );

        // 2. Save old pending complaint (un-synced)
        final oldPending = ComplaintModel(
          id: 'cmp_old_pending',
          citizenId: 'user_001',
          ticketNumber: 'LOCAL-2026-000002',
          title: 'Old Offline Issue Not Yet Synced',
          description: 'Filed offline during power outage',
          category: const CivicCategory(
            id: 'roads',
            name: 'Roads',
            description: '',
            icon: Icons.alt_route,
          ),
          status: ComplaintStatus.resolved,
          priority: ComplaintPriority.low,
          location: const CivicLocation(
            latitude: 12.0,
            longitude: 77.0,
            address: 'Old St',
          ),
          imageUrls: const [],
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
          syncStatus: SyncStatus.pending,
        );

        await localRepo.cacheComplaints([oldResolved]);
        await localRepo.saveOfflineComplaint(oldPending);

        // Run stale purge
        await repository.clearStaleComplaints(maxAge: const Duration(days: 14));

        // Verify: Synced old resolved is purged
        expect(await repository.getComplaintById('cmp_old_resolved'), isNull);

        // Verify: Pending un-synced complaint is PROTECTED and NOT purged!
        final pendingComplaint = await repository.getComplaintById(
          'cmp_old_pending',
        );
        expect(pendingComplaint, isNotNull);
        expect(pendingComplaint!.syncStatus, equals(SyncStatus.pending));
      },
    );
  });
}
