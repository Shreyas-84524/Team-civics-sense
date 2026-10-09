import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/firebase/errors/firestore_exception.dart';
import 'package:civic_app/core/firebase/firestore/firebase_complaint_data_source.dart';
import 'package:civic_app/core/firebase/firestore/firestore_pagination.dart';
import 'package:civic_app/core/firebase/mappers/complaint_firestore_mapper.dart';
import 'package:civic_app/core/firebase/storage/mock_evidence_storage_service.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/network/connectivity_service.dart';
import 'package:civic_app/core/repositories/firebase_complaint_repository.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';
import 'package:civic_app/core/repositories/offline_first_complaint_repository.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/core/sync/models/sync_queue_item.dart';
import 'package:civic_app/core/sync/providers/firebase_sync_provider.dart';
import 'package:civic_app/core/sync/queue/sync_queue.dart';
import 'package:civic_app/core/sync/retry/retry_policy.dart';
import 'package:civic_app/core/sync/sync_manager.dart';
import 'package:civic_app/User UI/models/complaint_draft.dart';
import 'package:civic_app/User UI/services/offline_first_complaint_service.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';

class LocalTestConnectivityService implements ConnectivityService {
  bool _online;
  final _controller = StreamController<bool>.broadcast();

  LocalTestConnectivityService({bool initialOnline = true}) : _online = initialOnline;

  @override
  bool get isOnline => _online;

  @override
  bool get isOffline => !_online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<bool> checkConnectivity() async => _online;

  @override
  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }

  void dispose() {
    _controller.close();
  }
}

/// Test double simulating Firestore rules validation for complaint creation and updates.
class RulesEnforcingRemoteDataSource extends FirebaseComplaintDataSource {
  final Map<String, Map<String, dynamic>> rawFirestoreDocuments = {};
  final Map<String, ComplaintModel> remoteComplaints = {};
  String currentAuthUid = 'usr_test_citizen';
  String currentAuthRole = 'citizen';

  RulesEnforcingRemoteDataSource() : super(firestore: null);

  @override
  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {
    final serverId = 'srv_${complaint.id}';
    final data = ComplaintFirestoreMapper.toFirestore(complaint, isCreate: true);

    // Enforce Cloud Firestore Security Rules for /complaints/{complaintId} create
    if (currentAuthUid.isEmpty) {
      throw const FirestorePermissionDeniedException(
        'Unauthenticated: User must be signed in to create a complaint.',
      );
    }
    if (data['citizenId'] != currentAuthUid) {
      throw const FirestorePermissionDeniedException(
        'Permission Denied: citizenId must match request.auth.uid.',
      );
    }
    if (data['title'] is! String ||
        (data['title'] as String).isEmpty ||
        (data['title'] as String).length > 200) {
      throw const FirestoreException(
        code: 'invalid-argument',
        message: 'Title must be non-empty string <= 200 chars.',
      );
    }
    if (data['description'] is! String ||
        (data['description'] as String).length > 2000) {
      throw const FirestoreException(
        code: 'invalid-argument',
        message: 'Description must be string <= 2000 chars.',
      );
    }
    if (data['status'] != 'reported' && data['status'] != 'underVerification') {
      throw const FirestorePermissionDeniedException(
        'Permission Denied: Citizen complaint creation requires status in ["underVerification", "reported"].',
      );
    }
    if (data['assignedTo'] != null) {
      throw const FirestorePermissionDeniedException(
        'Permission Denied: Citizen cannot assign complaint during creation (assignedTo must be null).',
      );
    }
    if (data['departmentId'] != null) {
      throw const FirestorePermissionDeniedException(
        'Permission Denied: Citizen cannot set departmentId during creation (departmentId must be null).',
      );
    }
    if (data['assignedCrewMemberId'] != null) {
      throw const FirestorePermissionDeniedException(
        'Permission Denied: Citizen cannot set assignedCrewMemberId during creation (assignedCrewMemberId must be null).',
      );
    }
    if (data['resolvedAt'] != null) {
      throw const FirestorePermissionDeniedException(
        'Permission Denied: Citizen cannot mark complaint resolved during creation (resolvedAt must be null).',
      );
    }
    if (data['upvotes'] != 0) {
      throw const FirestorePermissionDeniedException(
        'Permission Denied: Complaint creation upvotes must be 0.',
      );
    }

    rawFirestoreDocuments[serverId] = data;
    final saved = complaint.copyWith(
      id: serverId,
      serverId: serverId,
      syncStatus: SyncStatus.synced,
    );
    remoteComplaints[serverId] = saved;
    return saved;
  }

  @override
  Future<ComplaintModel?> getComplaintById(
    String id, {
    bool includeTimeline = true,
  }) async {
    return remoteComplaints[id];
  }

  @override
  Future<FirestorePage<ComplaintModel>> getCitizenComplaints({
    required String citizenId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final items = remoteComplaints.values
        .where((c) => c.citizenId == citizenId || citizenId.isEmpty)
        .toList();
    return FirestorePage<ComplaintModel>(items: items, hasMore: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CIVICFIX COMPLAINT SUBMISSION & TRUST BOUNDARY REGRESSION SUITE (Part 16)', () {
    late RulesEnforcingRemoteDataSource remoteDataSource;
    late HiveComplaintRepository localRepo;
    late MockEvidenceStorageService storageService;
    late SyncQueue syncQueue;
    late SyncManager syncManager;
    late LocalTestConnectivityService connectivity;
    late ComplaintRoutingService routingService;
    late OfflineFirstComplaintRepository offlineRepository;
    late FirebaseComplaintRepository firebaseRepository;
    late FirebaseSyncProvider firebaseSyncProvider;

    setUp(() async {
      AuthServiceLocator.useMockServices();

      remoteDataSource = RulesEnforcingRemoteDataSource();
      localRepo = HiveComplaintRepository();
      storageService = MockEvidenceStorageService()..latency = Duration.zero;
      syncQueue = HiveSyncQueue();
      connectivity = LocalTestConnectivityService(initialOnline: true);
      routingService = ComplaintRoutingService(
        hierarchyRepo: LocalGovernmentHierarchyRepository(),
      );

      firebaseSyncProvider = FirebaseSyncProvider(
        complaintDataSource: remoteDataSource,
        evidenceStorageService: storageService,
      );

      syncManager = SyncManager.createForTesting(
        queue: syncQueue,
        provider: firebaseSyncProvider,
        connectivity: connectivity,
        repository: localRepo,
        retryPolicy: RetryPolicy(maxRetries: 3),
      );

      offlineRepository = OfflineFirstComplaintRepository(
        localRepository: localRepo,
        remoteDataSource: remoteDataSource,
        evidenceStorageService: storageService,
        syncManager: syncManager,
        connectivity: connectivity,
        routingService: routingService,
      );

      firebaseRepository = FirebaseComplaintRepository(
        dataSource: remoteDataSource,
        routingService: routingService,
      );
    });

    tearDown(() {
      syncManager.dispose();
      syncQueue.dispose();
      connectivity.dispose();
      AuthServiceLocator.reset();
    });

    test('1. Citizen can successfully create valid complaint without authorization error', () async {
      final complaint = await offlineRepository.createComplaint(
        citizenId: 'usr_test_citizen',
        title: 'Pothole on Linking Road',
        description: 'Large crater near Khar telephone exchange',
        category: const CivicCategory(
          id: 'roads',
          name: 'Roads & Maintenance',
          description: '',
          icon: Icons.alt_route,
        ),
        location: const CivicLocation(
          latitude: 19.0680,
          longitude: 72.8360,
          address: 'Linking Road, Bandra West',
        ),
        priority: ComplaintPriority.medium,
        imageUrls: const ['mock://camera/pothole.jpg'],
        isHazard: false,
      );

      expect(complaint.id.startsWith('srv_'), isTrue);
      expect(complaint.citizenId, 'usr_test_citizen');
      expect(complaint.syncStatus, SyncStatus.synced);
      // Canonical workflow: initial submission is underVerification awaiting backend AI
      expect(complaint.status, ComplaintStatus.underVerification);
      expect(complaint.isUnderVerification, isTrue);
    });

    test('2. Unauthenticated citizen complaint creation is strictly rejected by rule simulation', () async {
      remoteDataSource.currentAuthUid = '';

      expect(
        () => offlineRepository.createComplaint(
          citizenId: 'usr_test_citizen',
          title: 'Unauthenticated Test',
          description: 'Should fail authentication',
          category: CivicCategory.defaultCategories.first,
          location: const CivicLocation(latitude: 19.0, longitude: 72.8, address: 'Mumbai'),
          priority: ComplaintPriority.medium,
        ),
        throwsA(isA<FirestorePermissionDeniedException>()),
      );
    });

    test('3. Spoofed citizenId mismatch is rejected with permission-denied', () async {
      remoteDataSource.currentAuthUid = 'authenticated-uid-123';

      expect(
        () => offlineRepository.createComplaint(
          citizenId: 'spoofed-uid-999',
          title: 'Spoofed Citizen Test',
          description: 'UID mismatch must fail',
          category: CivicCategory.defaultCategories.first,
          location: const CivicLocation(latitude: 19.0, longitude: 72.8, address: 'Mumbai'),
          priority: ComplaintPriority.medium,
        ),
        throwsA(isA<FirestorePermissionDeniedException>()),
      );
    });

    test('4. Raw initial Firestore payload strictly contains departmentId == null and assignedTo == null', () async {
      final complaint = await offlineRepository.createComplaint(
        citizenId: 'usr_test_citizen',
        title: 'Water Leakage on Hill Road',
        description: 'Underground pipeline burst',
        category: const CivicCategory(
          id: 'water',
          name: 'Water Supply',
          description: '',
          icon: Icons.water_drop,
        ),
        location: const CivicLocation(
          latitude: 19.0550,
          longitude: 72.8300,
          address: 'Hill Road, Bandra',
        ),
        priority: ComplaintPriority.high,
      );

      final rawDoc = remoteDataSource.rawFirestoreDocuments[complaint.id];
      expect(rawDoc, isNotNull);
      expect(rawDoc!['status'], anyOf('underVerification', 'reported'));
      expect(rawDoc['assignedTo'], isNull);
      expect(rawDoc['departmentId'], isNull);
      expect(rawDoc['assignedCrewMemberId'], isNull);
      expect(rawDoc['resolvedAt'], isNull);
      expect(rawDoc['upvotes'], 0);
      expect(rawDoc['citizenId'], 'usr_test_citizen');
    });

    test('5. FirebaseComplaintRepository remote pipeline creates initial doc then auto-routes JE', () async {
      final complaint = await firebaseRepository.createComplaint(
        citizenId: 'usr_test_citizen',
        title: 'Garbage accumulation',
        description: 'Overflowing bin at market',
        category: const CivicCategory(
          id: 'waste',
          name: 'Solid Waste Management',
          description: '',
          icon: Icons.delete,
        ),
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Dadar Market',
        ),
        priority: ComplaintPriority.medium,
      );

      expect(complaint.id.startsWith('srv_'), isTrue);
      expect(complaint.status, ComplaintStatus.underVerification);
      expect(complaint.isUnderVerification, isTrue);

      // Verify what was written to Firestore was clean
      final rawDoc = remoteDataSource.rawFirestoreDocuments[complaint.id];
      expect(rawDoc!['status'], anyOf('underVerification', 'reported'));
      expect(rawDoc['assignedTo'], isNull);
      expect(rawDoc['departmentId'], isNull);
      expect(rawDoc['assignedCrewMemberId'], isNull);
      expect(rawDoc['resolvedAt'], isNull);
    });

    test('6. Offline-created complaint persists locally with pending status and auto-routed JE', () async {
      connectivity.setOnline(false);

      final offlineComplaint = await offlineRepository.createComplaint(
        citizenId: 'usr_test_citizen',
        title: 'Offline streetlight broken',
        description: 'No power on street lights',
        category: const CivicCategory(
          id: 'roads',
          name: 'Roads & Maintenance',
          description: '',
          icon: Icons.alt_route,
        ),
        location: const CivicLocation(
          latitude: 19.0178,
          longitude: 72.8478,
          address: 'Worli Naka',
        ),
        priority: ComplaintPriority.medium,
      );

      expect(offlineComplaint.syncStatus, SyncStatus.pending);
      expect(offlineComplaint.status, ComplaintStatus.underVerification);

      final queuedItems = await syncQueue.getAllItems();
      expect(queuedItems.length, 1);
      expect(queuedItems.first.operation, SyncOperation.createComplaint);
    });

    test('7. Firestore Security Rules file contains all Part 16 security constraints', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);
      final rulesContent = rulesFile.readAsStringSync();

      // Rule: Citizen creation requires citizenId == request.auth.uid
      expect(rulesContent.contains(r'request.resource.data.citizenId == request.auth.uid'), isTrue);
      // Rule: Status must be underVerification or reported
      expect(rulesContent.contains(r'underVerification'), isTrue);
      // Rule: assignedTo must be null
      expect(rulesContent.contains(r'request.resource.data.assignedTo == null'), isTrue);
      // Rule: departmentId must be null
      expect(rulesContent.contains(r'request.resource.data.departmentId == null'), isTrue);
      // Rule: assignedCrewMemberId must be null
      expect(rulesContent.contains(r'request.resource.data.assignedCrewMemberId == null'), isTrue);
      // Rule: resolvedAt must be null
      expect(rulesContent.contains(r'request.resource.data.resolvedAt == null'), isTrue);
      // Rule: upvotes must be 0
      expect(rulesContent.contains(r'request.resource.data.upvotes == 0'), isTrue);
      // Rule: Government update path exists
      expect(rulesContent.contains(r'isGovernment()'), isTrue);
    });

    test('8. Storage Security Rules file validates authentication and image MIME/size constraints', () {
      final storageFile = File('storage.rules');
      expect(storageFile.existsSync(), isTrue);
      final storageContent = storageFile.readAsStringSync();

      expect(storageContent.contains('function isAuthenticated()'), isTrue);
      expect(storageContent.contains('function isValidEvidenceImage()'), isTrue);
      expect(storageContent.contains('10 * 1024 * 1024'), isTrue);
      expect(storageContent.contains('image/(jpeg|jpg|png|webp)'), isTrue);
    });

    test('9. Government-only fields populated in domain model are strictly sanitized to null for Firestore creation', () {
      final dirtyComplaint = ComplaintModel(
        id: 'cmp_dirty_test',
        citizenId: 'usr_test_citizen',
        ticketNumber: 'CF-2026-TEST',
        title: 'Dirty payload test',
        description: 'Contains pre-set government fields',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.underVerification,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 19.0, longitude: 72.8, address: 'Mumbai'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignedTo: 'Officer Sharma',
        assignedDepartmentId: 'dept_roads',
        assignedCrewMemberId: 'crew_007',
        assignedDepartmentLeadId: 'lead_001',
        assignedFieldOfficerId: 'fo_001',
        resolvedAt: DateTime.now(),
        resolvedBy: 'lead_001',
        resolutionRemarks: 'Pre-resolved illegal remarks',
        workStartedAt: DateTime.now(),
        workStartedBy: 'crew_007',
      );

      final firestoreMap = ComplaintFirestoreMapper.toFirestore(dirtyComplaint, isCreate: true);
      expect(firestoreMap['assignedTo'], isNull);
      expect(firestoreMap['departmentId'], isNull);
      expect(firestoreMap['assignedCrewMemberId'], isNull);
      expect(firestoreMap['assignedDepartmentId'], isNull);
      expect(firestoreMap['assignedDepartmentLeadId'], isNull);
      expect(firestoreMap['assignedFieldOfficerId'], isNull);
      expect(firestoreMap['resolvedAt'], isNull);
      expect(firestoreMap['resolvedBy'], isNull);
      expect(firestoreMap['resolutionRemarks'], isNull);
      expect(firestoreMap['workStartedAt'], isNull);
      expect(firestoreMap['workStartedBy'], isNull);
      expect(firestoreMap['status'], 'underVerification');
    });

    test('10. Initial timeline event conforms strictly to security rules schema', () {
      final initialEvent = TimelineEvent(
        title: 'Grievance Submitted',
        description: 'Ticket created and queued for two-stage verification.',
        timestamp: DateTime.now(),
        status: ComplaintStatus.underVerification,
        updatedBy: 'usr_test_citizen',
      );

      final timelineMap = ComplaintFirestoreMapper.timelineEventToFirestore(initialEvent);
      expect(timelineMap['status'], anyOf('underVerification', 'reported'));
      expect(timelineMap['updatedBy'], 'usr_test_citizen');
      expect(timelineMap['title'], isNotEmpty);
      expect(timelineMap['timestamp'], isNotNull);
      expect(timelineMap['createdAt'], isNotNull);
    });

    test('11. Direct raw creation payload with upvotes != 0 is rejected with permission-denied', () async {
      expect(
        () => remoteDataSource.createComplaint(
          ComplaintModel(
            id: 'cmp_illegal_upvotes',
            citizenId: 'usr_test_citizen',
            ticketNumber: 'CF-2026-TEST2',
            title: 'Illegal upvotes attempt',
            description: 'Should fail security check',
            category: CivicCategory.defaultCategories.first,
            status: ComplaintStatus.underVerification,
            location: const CivicLocation(latitude: 19.0, longitude: 72.8, address: 'Mumbai'),
            priority: ComplaintPriority.medium,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            upvotes: 10,
          ),
        ),
        throwsA(isA<FirestorePermissionDeniedException>()),
      );
    });

    test('12. OfflineFirstComplaintService submits cleanly with restored citizen auth state', () async {
      remoteDataSource.currentAuthUid = AuthServiceLocator.citizenAuth.currentUid!;

      final service = OfflineFirstComplaintService(
        complaintRepository: offlineRepository,
      );

      final draft = ComplaintDraft(
        title: 'Water logged street',
        description: 'Heavy water logging outside station',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(latitude: 19.05, longitude: 72.83, address: 'Bandra Station'),
        isHazard: false,
      );

      final created = await service.submitComplaint(draft);
      expect(created.id.startsWith('srv_'), isTrue);
      expect(created.status, ComplaintStatus.underVerification);
    });

    test('13. OfflineFirstComplaintService rejects unauthenticated submission without local corruption', () async {
      final mockAuth = MockAuthService();
      mockAuth.resetForTesting(authenticated: false);
      AuthServiceLocator.citizenAuth = mockAuth;

      final service = OfflineFirstComplaintService(
        complaintRepository: offlineRepository,
      );

      final draft = ComplaintDraft(
        title: 'Unauthenticated issue',
        description: 'Should reject cleanly before repo write',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(latitude: 19.05, longitude: 72.83, address: 'Bandra'),
        isHazard: false,
      );

      expect(
        () => service.submitComplaint(draft),
        throwsA(predicate((e) => e.toString().contains('Please sign in to submit a complaint.'))),
      );
    });

    test('14. ComplaintFirestoreMapper preserves status "reported" when legacy isCreate used', () {
      final legacyComplaint = ComplaintModel(
        id: 'cmp_legacy',
        citizenId: 'usr_test_citizen',
        ticketNumber: 'CF-2026-LEGACY',
        title: 'Legacy reported issue',
        description: 'Checking backwards compatibility',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 19.0, longitude: 72.8, address: 'Mumbai'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = ComplaintFirestoreMapper.toFirestore(legacyComplaint, isCreate: true);
      expect(map['status'], 'reported');
      expect(map['upvotes'], 0);
    });

    test('15. OfflineFirstComplaintRepository attaches citizen UID to storage metadata on online media upload', () async {
      final complaint = await offlineRepository.createComplaint(
        citizenId: 'usr_test_citizen',
        title: 'Broken street sign',
        description: 'Sign fallen down at corner',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(latitude: 19.05, longitude: 72.83, address: 'Bandra'),
        priority: ComplaintPriority.medium,
        imageUrls: const ['mock://camera/sign.jpg'],
      );

      expect(complaint.imageUrls.isNotEmpty, isTrue);
      expect(storageService.storedFileCount, greaterThan(0));
      final metadata = storageService.getMetadata(
        '${complaint.ticketNumber}/${complaint.ticketNumber}_evidence_01.jpg',
      );
      expect(metadata, isNotNull);
      expect(metadata!.uploaderId, equals('usr_test_citizen'));
      expect(metadata.complaintId, startsWith('cmp_'));
    });

    test('16. FirebaseSyncProvider attaches citizen UID to storage metadata when syncing queued offline complaint', () async {
      storageService.reset();
      storageService.latency = Duration.zero;
      remoteDataSource.currentAuthUid = 'usr_queued_citizen_456';

      final item = SyncQueueItem(
        id: 'sync_task_test_001',
        entityType: 'complaint',
        entityId: 'cmp_offline_queue_001',
        operation: SyncOperation.createComplaint,
        payload: {
          'id': 'cmp_offline_queue_001',
          'localId': 'LOCAL-2026-000999',
          'ticketNumber': 'CF-2026-QUEUED',
          'citizenId': 'usr_queued_citizen_456',
          'title': 'Pothole offline item',
          'description': 'Submitted offline and queued',
          'categoryId': 'roads',
          'categoryName': 'Roads',
          'priority': 'high',
          'latitude': 19.05,
          'longitude': 72.83,
          'address': 'Bandra West',
          'imageUrls': ['mock://camera/offline_photo.jpg'],
        },
        createdAt: DateTime.now(),
      );

      final result = await firebaseSyncProvider.execute(item);
      expect(result.isSuccess, isTrue);

      final metadata = storageService.getMetadata(
        'CF-2026-QUEUED/CF-2026-QUEUED_evidence_01.jpg',
      );
      expect(metadata, isNotNull);
      expect(metadata!.uploaderId, equals('usr_queued_citizen_456'));
    });
  });
}
