import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/firebase_constants.dart';
import 'package:civic_app/core/firebase/storage/evidence_storage_models.dart';
import 'package:civic_app/core/firebase/storage/evidence_storage_service.dart';
import 'package:civic_app/core/firebase/storage/mock_evidence_storage_service.dart';
import 'package:civic_app/core/firebase/storage/storage_error_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseStoragePaths Unit Tests', () {
    test('Formats complaint and avatar paths correctly', () {
      expect(
        FirebaseStoragePaths.complaintEvidencePath('cmp_001', 'photo.jpg'),
        equals('complaint_evidence/cmp_001/photo.jpg'),
      );

      expect(
        FirebaseStoragePaths.complaintImagePath('cmp_001', 'photo.png'),
        equals('complaints/cmp_001/images/photo.png'),
      );

      expect(
        FirebaseStoragePaths.userAvatarPath('usr_001', 'avatar.jpg'),
        equals('user_avatars/usr_001/avatar.jpg'),
      );

      expect(
        FirebaseStoragePaths.govtAvatarPath('gov_001', 'avatar.jpg'),
        equals('govt_avatars/gov_001/avatar.jpg'),
      );
    });

    test('Sanitizes file names to prevent directory traversal and invalid chars', () {
      expect(
        FirebaseStoragePaths.sanitizeFileName('../../secret/file.jpg'),
        equals('file.jpg'),
      );

      expect(
        FirebaseStoragePaths.sanitizeFileName(r'C:\Windows\temp\test photo (1).jpg'),
        equals('test_photo__1_.jpg'),
      );

      expect(
        FirebaseStoragePaths.sanitizeFileName('.hidden.png'),
        equals('file.hidden.png'),
      );

      final emptySanitized = FirebaseStoragePaths.sanitizeFileName('');
      expect(emptySanitized.startsWith('upload_'), isTrue);
      expect(emptySanitized.endsWith('.jpg'), isTrue);
    });
  });

  group('EvidenceFileValidation Unit Tests', () {
    Uint8List createDummyJpeg({int size = 200}) {
      final list = List<int>.filled(size, 0);
      list[0] = 0xFF;
      list[1] = 0xD8;
      list[2] = 0xFF;
      return Uint8List.fromList(list);
    }

    Uint8List createDummyPng({int size = 200}) {
      final list = List<int>.filled(size, 0);
      list[0] = 0x89;
      list[1] = 0x50;
      list[2] = 0x4E;
      list[3] = 0x47;
      list[4] = 0x0D;
      list[5] = 0x0A;
      list[6] = 0x1A;
      list[7] = 0x0A;
      return Uint8List.fromList(list);
    }

    Uint8List createDummyWebp({int size = 200}) {
      final list = List<int>.filled(size, 0);
      list[0] = 0x52; // R
      list[1] = 0x49; // I
      list[2] = 0x46; // F
      list[3] = 0x46; // F
      list[8] = 0x57; // W
      list[9] = 0x45; // E
      list[10] = 0x42; // B
      list[11] = 0x50; // P
      return Uint8List.fromList(list);
    }

    test('Validates valid JPEG bytes and filename successfully', () {
      final bytes = createDummyJpeg(size: 1024);
      final validation = EvidenceFileValidation.validateBytes(
        bytes: bytes,
        fileName: 'evidence.jpg',
      );

      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
      expect(validation.mimeType, equals('image/jpeg'));
      expect(validation.fileExtension, equals('.jpg'));
      expect(validation.sizeInBytes, equals(1024));
    });

    test('Validates valid PNG bytes and filename successfully', () {
      final bytes = createDummyPng(size: 2048);
      final validation = EvidenceFileValidation.validateBytes(
        bytes: bytes,
        fileName: 'evidence.png',
      );

      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
      expect(validation.mimeType, equals('image/png'));
      expect(validation.fileExtension, equals('.png'));
    });

    test('Validates valid WEBP bytes and filename successfully', () {
      final bytes = createDummyWebp(size: 512);
      final validation = EvidenceFileValidation.validateBytes(
        bytes: bytes,
        fileName: 'evidence.webp',
      );

      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
      expect(validation.mimeType, equals('image/webp'));
      expect(validation.fileExtension, equals('.webp'));
    });

    test('Rejects file smaller than minValidFileSize', () {
      final bytes = Uint8List(50); // < 100 bytes
      final validation = EvidenceFileValidation.validateBytes(
        bytes: bytes,
        fileName: 'tiny.jpg',
      );

      expect(validation.isValid, isFalse);
      expect(validation.errors.any((e) => e.contains('too small')), isTrue);
    });

    test('Rejects file exceeding maxEvidenceFileSize (10MB)', () {
      final bytes = createDummyJpeg(size: 100);
      final validation = EvidenceFileValidation.validateBytes(
        bytes: bytes,
        fileName: 'huge.jpg',
        maxSizeBytes: 50, // artificially lowered for test
      );

      expect(validation.isValid, isFalse);
      expect(validation.errors.any((e) => e.contains('exceeds maximum allowed limit')), isTrue);
    });

    test('Rejects unsupported file extensions', () {
      final bytes = createDummyJpeg(size: 200);
      final validation = EvidenceFileValidation.validateBytes(
        bytes: bytes,
        fileName: 'malicious.exe',
      );

      expect(validation.isValid, isFalse);
      expect(validation.errors.any((e) => e.contains('not supported')), isTrue);
    });
  });

  group('EvidenceMetadata & UploadResult Serialization Tests', () {
    test('EvidenceMetadata serializes and deserializes cleanly', () {
      final metadata = EvidenceMetadata(
        complaintId: 'cmp_100',
        uploaderId: 'usr_200',
        category: 'cat_roads',
        isHazard: true,
        latitude: 12.9716,
        longitude: 77.5946,
        uploadedAt: DateTime(2026, 9, 8, 12, 0),
        contentType: 'image/jpeg',
        customMetadata: {'source': 'camera'},
      );

      final map = metadata.toCustomMetadataMap();
      expect(map['complaintId'], equals('cmp_100'));
      expect(map['uploaderId'], equals('usr_200'));
      expect(map['category'], equals('cat_roads'));
      expect(map['isHazard'], equals('true'));
      expect(map['latitude'], equals('12.9716'));
      expect(map['longitude'], equals('77.5946'));
      expect(map['source'], equals('camera'));

      final fromMap = EvidenceMetadata.fromMap(map);
      expect(fromMap.complaintId, equals('cmp_100'));
      expect(fromMap.uploaderId, equals('usr_200'));
      expect(fromMap.isHazard, isTrue);
      expect(fromMap.latitude, equals(12.9716));
    });

    test('EvidenceUploadResult serializes and deserializes accurately', () {
      final result = EvidenceUploadResult(
        storagePath: 'complaint_evidence/cmp_100/photo.jpg',
        downloadUrl: 'https://firebasestorage.googleapis.com/.../photo.jpg',
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeInBytes: 15420,
        uploadedAt: DateTime(2026, 9, 8, 12, 0),
      );

      final map = result.toMap();
      expect(map['storagePath'], equals('complaint_evidence/cmp_100/photo.jpg'));
      expect(map['sizeInBytes'], equals(15420));
      expect(map['mimeType'], equals('image/jpeg'));

      final reconstituted = EvidenceUploadResult.fromMap(map);
      expect(reconstituted.storagePath, equals(result.storagePath));
      expect(reconstituted.downloadUrl, equals(result.downloadUrl));
      expect(reconstituted.sizeInBytes, equals(15420));
    });

    test('EvidenceUploadProgress computes fraction and handles states correctly', () {
      final initial = EvidenceUploadProgress.initial();
      expect(initial.progress, equals(0.0));
      expect(initial.status, equals(EvidenceUploadStatus.idle));

      final running = EvidenceUploadProgress.running(transferred: 50, total: 100);
      expect(running.progress, equals(0.5));
      expect(running.status, equals(EvidenceUploadStatus.uploading));

      final completed = EvidenceUploadProgress.completed(total: 100);
      expect(completed.progress, equals(1.0));
      expect(completed.status, equals(EvidenceUploadStatus.success));

      final failed = EvidenceUploadProgress.failed('Network error');
      expect(failed.progress, equals(0.0));
      expect(failed.status, equals(EvidenceUploadStatus.failed));
      expect(failed.error, equals('Network error'));
    });
  });

  group('StorageErrorHandler Unit Tests', () {
    test('Maps FirebaseException codes to typed StorageException', () {
      final notFound = StorageErrorHandler.handle(
        FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'),
      );
      expect(notFound.code, equals('object-not-found'));
      expect(notFound.isRecoverable, isFalse);

      final unauthorized = StorageErrorHandler.handle(
        FirebaseException(plugin: 'firebase_storage', code: 'unauthorized'),
      );
      expect(unauthorized.code, equals('unauthorized'));
      expect(unauthorized.isRecoverable, isFalse);

      final quota = StorageErrorHandler.handle(
        FirebaseException(plugin: 'firebase_storage', code: 'quota-exceeded'),
      );
      expect(quota.code, equals('quota-exceeded'));
      expect(quota.isRecoverable, isFalse);

      final retryLimit = StorageErrorHandler.handle(
        FirebaseException(plugin: 'firebase_storage', code: 'retry-limit-exceeded'),
      );
      expect(retryLimit.code, equals('retry-limit-exceeded'));
      expect(retryLimit.isRecoverable, isTrue);

      final checksum = StorageErrorHandler.handle(
        FirebaseException(plugin: 'firebase_storage', code: 'invalid-checksum'),
      );
      expect(checksum.code, equals('invalid-checksum'));
      expect(checksum.isRecoverable, isTrue);
    });

    test('Maps SocketException to recoverable network-unavailable exception', () {
      final netEx = StorageErrorHandler.handle(
        const SocketException('Failed host lookup: firebasestorage.googleapis.com'),
      );
      expect(netEx.code, equals('network-unavailable'));
      expect(netEx.isRecoverable, isTrue);
    });
  });

  group('MockEvidenceStorageService Lifecycle Tests', () {
    late MockEvidenceStorageService mockStorage;

    Uint8List createSampleJpeg() {
      final list = List<int>.filled(300, 0);
      list[0] = 0xFF;
      list[1] = 0xD8;
      list[2] = 0xFF;
      return Uint8List.fromList(list);
    }

    setUp(() {
      mockStorage = MockEvidenceStorageService();
      mockStorage.latency = Duration.zero;
    });

    test('Validates, uploads complaint evidence, and emits progress', () async {
      final progressValues = <double>[];
      final bytes = createSampleJpeg();

      final result = await mockStorage.uploadComplaintEvidence(
        complaintId: 'cmp_test_01',
        fileName: 'damage_photo.jpg',
        fileBytes: bytes,
        metadata: EvidenceMetadata(
          complaintId: 'cmp_test_01',
          uploaderId: 'usr_01',
          isHazard: true,
        ),
        onProgress: (p) => progressValues.add(p),
      );

      expect(result.storagePath, equals('complaint_evidence/cmp_test_01/damage_photo.jpg'));
      expect(result.downloadUrl.contains('civicfix-38d53.appspot.com'), isTrue);
      expect(result.sizeInBytes, equals(300));
      expect(progressValues.isNotEmpty, isTrue);
      expect(progressValues.last, equals(1.0));
      expect(mockStorage.storedFileCount, equals(1));
    });

    test('Uploads multiple evidence files in batch', () async {
      final bytes1 = createSampleJpeg();
      final bytes2 = createSampleJpeg();

      final results = await mockStorage.uploadMultipleEvidence(
        complaintId: 'cmp_multi',
        items: [
          EvidenceUploadInput(fileName: 'photo_1.jpg', fileBytes: bytes1),
          EvidenceUploadInput(fileName: 'photo_2.jpg', fileBytes: bytes2),
        ],
      );

      expect(results.length, equals(2));
      expect(mockStorage.storedFileCount, equals(2));
    });

    test('Uploads citizen and government avatars with correct pathing', () async {
      final bytes = createSampleJpeg();

      final citizenResult = await mockStorage.uploadAvatar(
        userId: 'citizen_1',
        fileName: 'profile.jpg',
        fileBytes: bytes,
        isGovtUser: false,
      );
      expect(citizenResult.storagePath, equals('user_avatars/citizen_1/profile.jpg'));

      final govtResult = await mockStorage.uploadAvatar(
        userId: 'officer_9',
        fileName: 'officer.jpg',
        fileBytes: bytes,
        isGovtUser: true,
      );
      expect(govtResult.storagePath, equals('govt_avatars/officer_9/officer.jpg'));
    });

    test('Retrieves download URL, lists, and deletes stored items', () async {
      final bytes = createSampleJpeg();
      final upload = await mockStorage.uploadComplaintEvidence(
        complaintId: 'cmp_del',
        fileName: 'temp.jpg',
        fileBytes: bytes,
      );

      final url = await mockStorage.getDownloadUrl(upload.storagePath);
      expect(url, isNotEmpty);

      final list = await mockStorage.listEvidenceForComplaint('cmp_del');
      expect(list.length, equals(1));
      expect(list.first, equals(upload.storagePath));

      await mockStorage.deleteEvidence(upload.storagePath);
      expect(mockStorage.storedFileCount, equals(0));

      expect(
        () => mockStorage.getDownloadUrl(upload.storagePath),
        throwsA(isA<StorageException>()),
      );
    });

    test('Simulates network, quota, and unauthorized errors accurately', () async {
      final bytes = createSampleJpeg();

      mockStorage.simulateNetworkError = true;
      expect(
        () => mockStorage.uploadComplaintEvidence(
          complaintId: 'cmp_err',
          fileName: 'photo.jpg',
          fileBytes: bytes,
        ),
        throwsA(predicate<StorageException>((e) => e.code == 'network-unavailable' && e.isRecoverable)),
      );

      mockStorage.simulateNetworkError = false;
      mockStorage.simulateQuotaExceeded = true;
      expect(
        () => mockStorage.uploadComplaintEvidence(
          complaintId: 'cmp_err',
          fileName: 'photo.jpg',
          fileBytes: bytes,
        ),
        throwsA(predicate<StorageException>((e) => e.code == 'quota-exceeded')),
      );

      mockStorage.simulateQuotaExceeded = false;
      mockStorage.simulateUnauthorized = true;
      expect(
        () => mockStorage.uploadComplaintEvidence(
          complaintId: 'cmp_err',
          fileName: 'photo.jpg',
          fileBytes: bytes,
        ),
        throwsA(predicate<StorageException>((e) => e.code == 'unauthorized')),
      );
    });
  });

  group('Storage Rules File Integrity Test', () {
    test('storage.rules contains expected security declarations and constraints', () {
      final rulesFile = File('storage.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();
      expect(content.contains("rules_version = '2';"), isTrue);
      expect(content.contains('service firebase.storage'), isTrue);
      expect(content.contains('match /complaint_evidence/'), isTrue);
      expect(content.contains('match /user_avatars/'), isTrue);
      expect(content.contains('match /govt_avatars/'), isTrue);
      expect(content.contains('10 * 1024 * 1024'), isTrue);
      expect(content.contains('5 * 1024 * 1024'), isTrue);
      expect(content.contains("image/(jpeg|jpg|png|webp)"), isTrue);
      expect(content.contains('allow read, write: if false;'), isTrue);
    });
  });
}
