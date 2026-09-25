import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:civic_app/core/ai/models/ai_analysis_status.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_enums.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_result.dart';
import 'package:civic_app/core/evidence/permanent_evidence_storage.dart';
import 'package:civic_app/core/firebase/mappers/complaint_firestore_mapper.dart';
import 'package:civic_app/core/local/hive/hive_adapters/complaint_hive_adapter.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/local/hive/hive_storage_service.dart';
import 'package:civic_app/core/local/models/complaint_local_model.dart';
import 'package:civic_app/core/local/models/location_local_model.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveStorageService storageService;
  late HiveComplaintRepository repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('phase4_test_hive_');
    Hive.init(tempDir.path);
    HiveInitializer.registerAdapters();
  });

  setUp(() async {
    storageService = HiveStorageService.instance;
    await storageService.init(subDir: tempDir.path, isTest: true);
    repository = HiveComplaintRepository(storage: storageService);
  });

  tearDown(() async {
    await storageService.clear(HiveBoxes.complaints);
    await storageService.clear(HiveBoxes.pendingSync);
    await storageService.clear(HiveBoxes.hazards);
  });

  tearDownAll(() async {
    await storageService.closeAll();
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  ComplaintModel createBaseComplaint({
    String id = 'cmp_phase4_001',
    AiAuthenticityResult? aiAuthenticity,
    AiAnalysisStatus aiAnalysisStatus = AiAnalysisStatus.pending,
    SyncStatus syncStatus = SyncStatus.pending,
  }) {
    final now = DateTime.now();
    return ComplaintModel(
      id: id,
      citizenId: 'usr_phase4',
      ticketNumber: 'CF-2026-P4001',
      title: 'Pothole on Main Road',
      description: 'Dangerous pothole near the bus stop',
      category: CivicCategory.defaultCategories[0],
      status: ComplaintStatus.reported,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Main Road, Ward 12',
      ),
      imageUrls: ['/storage/evidence/pothole_1.jpg'],
      createdAt: now,
      updatedAt: now,
      syncStatus: syncStatus,
      aiAuthenticity: aiAuthenticity,
      aiAnalysisStatus: aiAnalysisStatus,
    );
  }

  group('Phase 4: Gemini AI Authenticity Persistence & Offline Integration Tests', () {
    // -------------------------------------------------------------------------
    // Test 1: Complaint without AI result
    // -------------------------------------------------------------------------
    test('Test 1: Complaint without AI result defaults safely', () async {
      final complaint = createBaseComplaint(
        id: 'cmp_no_ai',
        aiAuthenticity: null,
        aiAnalysisStatus: AiAnalysisStatus.pending,
      );

      expect(complaint.hasAiAuthenticity, isFalse);
      expect(complaint.aiAuthenticity, isNull);
      expect(complaint.aiAnalysisStatus, equals(AiAnalysisStatus.pending));

      // Local model roundtrip
      final local = ComplaintLocalModel.fromDomain(complaint);
      expect(local.aiAuthenticityJson, isNull);
      expect(local.aiAnalysisStatus, equals('pending'));

      final fromLocal = local.toDomain();
      expect(fromLocal.hasAiAuthenticity, isFalse);
      expect(fromLocal.aiAuthenticity, isNull);
      expect(fromLocal.aiAnalysisStatus, equals(AiAnalysisStatus.pending));

      // Hive persistence roundtrip
      await repository.saveOfflineComplaint(complaint);
      final fetched = await repository.getComplaintById('cmp_no_ai');
      expect(fetched, isNotNull);
      expect(fetched!.hasAiAuthenticity, isFalse);
      expect(fetched.aiAuthenticity, isNull);
      expect(fetched.aiAnalysisStatus, equals(AiAnalysisStatus.pending));
    });

    // -------------------------------------------------------------------------
    // Test 2: Complaint with likely_real roundtrip Hive
    // -------------------------------------------------------------------------
    test('Test 2: Complaint with likely_real roundtrip Hive and domain', () async {
      final analyzedTime = DateTime(2026, 9, 25, 10, 30, 0);
      final authResult = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.88,
        reasoning: 'Authentic camera noise pattern with standard Bayer sensor demosaicing artifacts.',
        indicators: ['natural_sensor_noise', 'consistent_directional_lighting'],
        model: 'gemini-3.6-flash',
        analyzedAt: analyzedTime,
        isSuccess: true,
      );

      final complaint = createBaseComplaint(
        id: 'cmp_likely_real',
        aiAuthenticity: authResult,
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      expect(complaint.hasAiAuthenticity, isTrue);

      await repository.saveOfflineComplaint(complaint);
      final fetched = await repository.getComplaintById('cmp_likely_real');

      expect(fetched, isNotNull);
      expect(fetched!.hasAiAuthenticity, isTrue);
      expect(fetched.aiAnalysisStatus, equals(AiAnalysisStatus.completed));

      final ai = fetched.aiAuthenticity!;
      expect(ai.status, equals(AiAuthenticityStatus.likelyReal));
      expect(ai.confidence, closeTo(0.88, 0.001));
      expect(ai.reasoning, contains('sensor demosaicing'));
      expect(ai.indicators, contains('natural_sensor_noise'));
      expect(ai.isSuccess, isTrue);
      expect(ai.analyzedAt, equals(analyzedTime));
      expect(ai.model, equals('gemini-3.6-flash'));
    });

    // -------------------------------------------------------------------------
    // Test 3: Complaint with likely_ai_generated roundtrip Hive
    // -------------------------------------------------------------------------
    test('Test 3: Complaint with likely_ai_generated roundtrip Hive and domain', () async {
      final authResult = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyAiGenerated,
        confidence: 0.94,
        reasoning: 'Smooth texture diffusion without physical sensor noise; synthetic edge blending detected.',
        indicators: ['unnatural_smoothing', 'diffusion_frequency_signature'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime.now(),
        isSuccess: true,
      );

      final complaint = createBaseComplaint(
        id: 'cmp_likely_ai',
        aiAuthenticity: authResult,
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      await repository.saveOfflineComplaint(complaint);
      final fetched = await repository.getComplaintById('cmp_likely_ai');

      expect(fetched, isNotNull);
      expect(fetched!.hasAiAuthenticity, isTrue);
      expect(fetched.aiAuthenticity!.status, equals(AiAuthenticityStatus.likelyAiGenerated));
      expect(fetched.aiAuthenticity!.confidence, closeTo(0.94, 0.001));
      expect(fetched.aiAuthenticity!.indicators, contains('unnatural_smoothing'));
    });

    // -------------------------------------------------------------------------
    // Test 4: Complaint with uncertain roundtrip Hive
    // -------------------------------------------------------------------------
    test('Test 4: Complaint with uncertain roundtrip Hive and domain', () async {
      final authResult = AiAuthenticityResult(
        status: AiAuthenticityStatus.uncertain,
        confidence: 0.35,
        reasoning: 'Image is heavily compressed and blurry; insufficient frequency detail to determine authenticity.',
        indicators: ['heavy_jpeg_compression'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime.now(),
        isSuccess: true,
      );

      final complaint = createBaseComplaint(
        id: 'cmp_uncertain',
        aiAuthenticity: authResult,
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      await repository.saveOfflineComplaint(complaint);
      final fetched = await repository.getComplaintById('cmp_uncertain');

      expect(fetched, isNotNull);
      expect(fetched!.hasAiAuthenticity, isTrue);
      expect(fetched.aiAuthenticity!.status, equals(AiAuthenticityStatus.uncertain));
      expect(fetched.aiAuthenticity!.confidence, closeTo(0.35, 0.001));
      expect(fetched.aiAuthenticity!.reasoning, contains('heavily compressed'));
    });

    // -------------------------------------------------------------------------
    // Test 5: Failed analysis (aiAnalysisStatus == failed)
    // -------------------------------------------------------------------------
    test('Test 5: Failed analysis marks aiAnalysisStatus = failed and preserves failure result', () async {
      final failedResult = AiAuthenticityResult.failure(
        'Gemini quota exceeded or server unavailable (503)',
      );

      final complaint = createBaseComplaint(
        id: 'cmp_failed_ai',
        aiAuthenticity: failedResult,
        aiAnalysisStatus: AiAnalysisStatus.failed,
      );

      await repository.saveOfflineComplaint(complaint);
      final fetched = await repository.getComplaintById('cmp_failed_ai');

      expect(fetched, isNotNull);
      expect(fetched!.aiAnalysisStatus, equals(AiAnalysisStatus.failed));
      expect(fetched.aiAuthenticity, isNotNull);
      expect(fetched.aiAuthenticity!.isSuccess, isFalse);
      expect(fetched.aiAuthenticity!.status, equals(AiAuthenticityStatus.uncertain));
      expect(fetched.aiAuthenticity!.errorMessage, contains('Gemini quota exceeded'));
    });

    // -------------------------------------------------------------------------
    // Test 6: Backward compatibility with legacy records
    // -------------------------------------------------------------------------
    test('Test 6: Backward compatibility with legacy records missing AI fields', () async {
      // Simulate legacy record with null aiAuthenticityJson and default/missing status
      const legacyLocal = ComplaintLocalModel(
        id: 'cmp_legacy_001',
        citizenId: 'usr_legacy',
        ticketNumber: 'CF-2025-000001',
        title: 'Legacy Pothole',
        description: 'Reported in 2025 before AI feature existed',
        categoryId: 'roads',
        categoryName: 'Roads & Footpaths',
        categoryDescription: 'Road damages',
        status: 'reported',
        priority: 'medium',
        location: LocationLocalModel(
          latitude: 19.0,
          longitude: 72.8,
          address: 'Old Road',
        ),
        imageUrls: ['/storage/legacy_1.jpg'],
        createdAtEpochMs: 1735689600000,
        updatedAtEpochMs: 1735689600000,
        timeline: [],
        syncStatus: 'synced',
        aiAuthenticityJson: null,
        aiAnalysisStatus: 'pending',
      );

      final domain = legacyLocal.toDomain();
      expect(domain.hasAiAuthenticity, isFalse);
      expect(domain.aiAuthenticity, isNull);
      expect(domain.aiAnalysisStatus, equals(AiAnalysisStatus.pending));

      // Test legacy Firestore map without aiAuthenticity key
      final legacyFirestoreMap = <String, dynamic>{
        'citizenId': 'usr_legacy',
        'ticketNumber': 'CF-2025-000001',
        'title': 'Legacy Pothole',
        'description': 'Reported before AI',
        'category': {'id': 'roads', 'name': 'Roads'},
        'status': 'reported',
        'priority': 'medium',
        'location': {'latitude': 19.0, 'longitude': 72.8, 'address': 'Old Road'},
        'imageUrls': ['https://storage.civicfix.com/legacy.jpg'],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'upvotes': 0,
        'isHazard': false,
        // Notice 'aiAuthenticity' and 'aiAnalysisStatus' are completely absent!
      };

      final fromFirestore = ComplaintFirestoreMapper.fromFirestore(
        documentId: 'doc_legacy_001',
        data: legacyFirestoreMap,
      );

      expect(fromFirestore.hasAiAuthenticity, isFalse);
      expect(fromFirestore.aiAuthenticity, isNull);
      expect(fromFirestore.aiAnalysisStatus, equals(AiAnalysisStatus.pending));
    });

    // -------------------------------------------------------------------------
    // Test 7: Hive field index integrity (0..25 preserved)
    // -------------------------------------------------------------------------
    test('Test 7: Hive field index integrity (typeId: 0, fields 0..25)', () async {
      final adapter = ComplaintHiveAdapter();
      expect(adapter.typeId, equals(0));

      final box = await Hive.openBox<ComplaintLocalModel>('test_index_integrity');
      final localModel = ComplaintLocalModel(
        id: 'cmp_adapter_check',
        citizenId: 'usr_adapter',
        ticketNumber: 'CF-2026-ADAPTER',
        title: 'Adapter Integrity Test',
        description: 'Verify field indices 24 and 25 write and read faithfully',
        categoryId: 'roads',
        categoryName: 'Roads',
        categoryDescription: 'Road issues',
        status: 'reported',
        priority: 'high',
        location: const LocationLocalModel(
          latitude: 19.1,
          longitude: 72.9,
          address: 'Test Boulevard',
        ),
        imageUrls: const ['img_1.jpg'],
        createdAtEpochMs: 1727200000000,
        updatedAtEpochMs: 1727200000000,
        timeline: const [],
        serverId: 'srv_adapter_999',
        aiAuthenticityJson: '{"status":"likely_real","confidence":0.91}',
        aiAnalysisStatus: 'completed',
      );

      await box.put(localModel.id, localModel);
      final retrieved = box.get(localModel.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('cmp_adapter_check'));
      expect(retrieved.serverId, equals('srv_adapter_999')); // field 23
      expect(retrieved.aiAuthenticityJson, equals('{"status":"likely_real","confidence":0.91}')); // field 24
      expect(retrieved.aiAnalysisStatus, equals('completed')); // field 25

      await box.close();
    });

    // -------------------------------------------------------------------------
    // Test 8: Firestore mapper serialization roundtrip
    // -------------------------------------------------------------------------
    test('Test 8: Firestore mapper serialization roundtrip with aiAuthenticity', () {
      final now = DateTime(2026, 9, 25, 12, 0, 0);
      final authResult = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.92,
        reasoning: 'Continuous shadows and optical depth consistency.',
        indicators: ['consistent_lighting', 'authentic_lens_geometry'],
        model: 'gemini-3.6-flash',
        analyzedAt: now,
        isSuccess: true,
      );

      final complaint = createBaseComplaint(
        id: 'cmp_mapper_test',
        aiAuthenticity: authResult,
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      // Serialize to Firestore Map
      final firestoreMap = ComplaintFirestoreMapper.toFirestore(complaint, isCreate: true);

      expect(firestoreMap.containsKey('aiAuthenticity'), isTrue);
      expect(firestoreMap['aiAnalysisStatus'], equals('completed'));

      final aiMap = firestoreMap['aiAuthenticity'] as Map<String, dynamic>;
      expect(aiMap['status'], equals('likely_real'));
      expect(aiMap['confidence'], closeTo(0.92, 0.001));
      expect(aiMap['reasoning'], equals('Continuous shadows and optical depth consistency.'));
      expect(aiMap['indicators'], equals(['consistent_lighting', 'authentic_lens_geometry']));
      expect(aiMap['isSuccess'], isTrue);

      // Deserialize back from Firestore Map
      final restored = ComplaintFirestoreMapper.fromFirestore(
        documentId: 'doc_mapper_test',
        data: firestoreMap,
      );

      expect(restored.id, equals('doc_mapper_test'));
      expect(restored.hasAiAuthenticity, isTrue);
      expect(restored.aiAnalysisStatus, equals(AiAnalysisStatus.completed));
      expect(restored.aiAuthenticity!.status, equals(AiAuthenticityStatus.likelyReal));
      expect(restored.aiAuthenticity!.confidence, closeTo(0.92, 0.001));
      expect(restored.aiAuthenticity!.indicators.length, equals(2));
      expect(restored.aiAuthenticity!.analyzedAt, equals(now));
    });

    // -------------------------------------------------------------------------
    // Test 9: Offline complaint creation (saves to Hive without invoking Gemini)
    // -------------------------------------------------------------------------
    test('Test 9: Offline complaint creation saves to Hive without invoking Gemini', () async {
      final offlineComplaint = createBaseComplaint(
        id: 'cmp_offline_draft',
        aiAuthenticity: null,
        aiAnalysisStatus: AiAnalysisStatus.pending,
        syncStatus: SyncStatus.pending,
      );

      // Saving offline MUST succeed instantly without requiring network or Gemini AI
      final saved = await repository.saveOfflineComplaint(offlineComplaint);
      expect(saved.syncStatus, equals(SyncStatus.pending));
      expect(saved.aiAnalysisStatus, equals(AiAnalysisStatus.pending));
      expect(saved.aiAuthenticity, isNull);

      final pendingList = await repository.getPendingComplaints();
      expect(pendingList.any((c) => c.id == 'cmp_offline_draft'), isTrue);
    });

    // -------------------------------------------------------------------------
    // Test 10: Gemini failure isolation (complaint sync succeeds when AI fails)
    // -------------------------------------------------------------------------
    test('Test 10: Gemini failure isolation: complaint sync succeeds with aiAnalysisStatus = failed', () async {
      final complaint = createBaseComplaint(
        id: 'cmp_isolated_fail',
        aiAuthenticity: null,
        aiAnalysisStatus: AiAnalysisStatus.pending,
      );

      await repository.saveOfflineComplaint(complaint);

      // Simulate synchronization where backend creates complaint (synced) but AI fails
      final aiFailure = AiAuthenticityResult.failure('500 Demand Spike: Resource busy');
      await repository.updateSyncStatus(
        'cmp_isolated_fail',
        SyncStatus.synced,
        serverId: 'cloud_cmp_1001',
        aiAuthenticity: aiFailure,
        aiAnalysisStatus: AiAnalysisStatus.failed,
      );

      final updated = await repository.getComplaintById('cmp_isolated_fail');
      expect(updated, isNotNull);
      // The complaint IS successfully synced!
      expect(updated!.syncStatus, equals(SyncStatus.synced));
      expect(updated.serverId, equals('cloud_cmp_1001'));
      // The AI analysis failed in isolation without breaking the complaint sync
      expect(updated.aiAnalysisStatus, equals(AiAnalysisStatus.failed));
      expect(updated.aiAuthenticity, isNotNull);
      expect(updated.aiAuthenticity!.status, equals(AiAuthenticityStatus.uncertain));
      expect(updated.aiAuthenticity!.isSuccess, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 11: Permanent local storage cache survival and idempotency
    // -------------------------------------------------------------------------
    test('Test 11: PermanentEvidenceStorage copies temp file and is idempotent', () async {
      final storageDir = await Directory.systemTemp.createTemp('civic_evidence_test_');
      final tempCacheDir = await Directory.systemTemp.createTemp('civic_picker_cache_');

      try {
        final evidenceService = PermanentEvidenceStorage(baseDirectory: storageDir);

        // Create a simulated temporary image from image_picker
        final tempPickerFile = File('${tempCacheDir.path}/scaled_image_picker_12345.jpg');
        await tempPickerFile.writeAsBytes(List.generate(1024, (i) => i % 256));

        // 1. Check path before persist
        expect(await evidenceService.isPermanentPath(tempPickerFile.path), isFalse);

        // 2. Persist evidence
        final permanentPath = await evidenceService.persistEvidenceFile(
          tempPickerFile.path,
          complaintId: 'cmp_p4_photo',
          index: 0,
        );

        expect(permanentPath, contains('evidence_cmp_p4_photo_0.jpg'));
        expect(File(permanentPath).existsSync(), isTrue);
        expect(await evidenceService.isPermanentPath(permanentPath), isTrue);

        // Verify content preserved
        final permBytes = await File(permanentPath).readAsBytes();
        expect(permBytes.length, equals(1024));

        // 3. Idempotency: Calling persist on the permanent file returns the same path without re-copying
        final repeatPath = await evidenceService.persistEvidenceFile(
          permanentPath,
          complaintId: 'cmp_p4_photo',
          index: 0,
        );
        expect(repeatPath, equals(permanentPath));

        // 4. Duplicate prevention: Calling persist again with the source file when target exists with same size
        final duplicateCheckPath = await evidenceService.persistEvidenceFile(
          tempPickerFile.path,
          complaintId: 'cmp_p4_photo',
          index: 0,
        );
        expect(duplicateCheckPath, equals(permanentPath));
      } finally {
        if (storageDir.existsSync()) await storageDir.delete(recursive: true);
        if (tempCacheDir.existsSync()) await tempCacheDir.delete(recursive: true);
      }
    });

    // -------------------------------------------------------------------------
    // Test 12: Sync retry idempotency
    // -------------------------------------------------------------------------
    test('Test 12: Sync retry idempotency preserves existing authenticity record', () async {
      final authResult = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.89,
        reasoning: 'Verified photo with sensor noise.',
        indicators: ['natural_noise'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime.now(),
        isSuccess: true,
      );

      final complaint = createBaseComplaint(
        id: 'cmp_retry_idempotent',
        aiAuthenticity: authResult,
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      // Initial save
      await repository.saveOfflineComplaint(complaint);

      // Sync completed
      await repository.updateSyncStatus(
        'cmp_retry_idempotent',
        SyncStatus.synced,
        serverId: 'srv_cmp_idempotent_1',
        aiAuthenticity: authResult,
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      // Verify state
      var retrieved = await repository.getComplaintById('cmp_retry_idempotent');
      expect(retrieved!.syncStatus, equals(SyncStatus.synced));
      expect(retrieved.serverId, equals('srv_cmp_idempotent_1'));
      expect(retrieved.aiAuthenticity!.status, equals(AiAuthenticityStatus.likelyReal));

      // Re-trigger updateSyncStatus (simulating idempotent queue retry)
      await repository.updateSyncStatus(
        'cmp_retry_idempotent',
        SyncStatus.synced,
        serverId: 'srv_cmp_idempotent_1',
        aiAuthenticity: authResult,
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      retrieved = await repository.getComplaintById('cmp_retry_idempotent');
      expect(retrieved!.syncStatus, equals(SyncStatus.synced));
      expect(retrieved.serverId, equals('srv_cmp_idempotent_1'));
      expect(retrieved.aiAuthenticity!.status, equals(AiAuthenticityStatus.likelyReal));

      // Verify no duplicate complaints in repository
      final all = await repository.getComplaints();
      final matches = all.where((c) => c.id == 'cmp_retry_idempotent').toList();
      expect(matches.length, equals(1));
    });
  });
}
