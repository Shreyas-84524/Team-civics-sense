import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_constants.dart';
import 'evidence_storage_models.dart';
import 'evidence_storage_service.dart';
import 'storage_error_handler.dart';

/// Production implementation of [EvidenceStorageService] utilizing Firebase Cloud Storage.
class FirebaseEvidenceStorageService implements EvidenceStorageService {
  final FirebaseStorage? _storage;

  FirebaseEvidenceStorageService({FirebaseStorage? storage})
      : _storage = storage;

  FirebaseStorage get _storageInstance => _storage ?? FirebaseStorage.instance;

  @override
  EvidenceFileValidation validateBytes({
    required Uint8List bytes,
    required String fileName,
    int maxSizeBytes = FirebaseStoragePaths.maxEvidenceFileSize,
    int minSizeBytes = FirebaseStoragePaths.minValidFileSize,
  }) {
    return EvidenceFileValidation.validateBytes(
      bytes: bytes,
      fileName: fileName,
      maxSizeBytes: maxSizeBytes,
      minSizeBytes: minSizeBytes,
    );
  }

  @override
  Future<EvidenceUploadResult> uploadComplaintEvidence({
    required String complaintId,
    required String fileName,
    required Uint8List fileBytes,
    EvidenceMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    final validation = validateBytes(bytes: fileBytes, fileName: fileName);
    if (!validation.isValid) {
      throw StorageException(
        code: 'invalid-file',
        message: 'File failed validation checks: ${validation.errors.join("; ")}',
        userMessage: validation.errors.first,
        isRecoverable: false,
      );
    }

    final path = FirebaseStoragePaths.complaintEvidencePath(complaintId, fileName);
    final ref = _storageInstance.ref(path);

    try {
      final settableMetadata = SettableMetadata(
        contentType: validation.mimeType ?? 'image/jpeg',
        customMetadata: metadata?.toCustomMetadataMap() ??
            {
              'complaintId': complaintId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
      );

      final uploadTask = ref.putData(fileBytes, settableMetadata);

      StreamSubscription? subscription;
      if (onProgress != null) {
        subscription = uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final fraction = (event.bytesTransferred / event.totalBytes).clamp(0.0, 1.0);
            onProgress(fraction);
          }
        });
      }

      await uploadTask;
      await subscription?.cancel();

      final downloadUrl = await ref.getDownloadURL();

      return EvidenceUploadResult(
        storagePath: path,
        downloadUrl: downloadUrl,
        fileName: FirebaseStoragePaths.sanitizeFileName(fileName),
        mimeType: validation.mimeType ?? 'image/jpeg',
        sizeInBytes: fileBytes.lengthInBytes,
        metadata: metadata,
        uploadedAt: DateTime.now(),
      );
    } catch (e, st) {
      throw StorageErrorHandler.handle(e, st);
    }
  }

  @override
  Future<List<EvidenceUploadResult>> uploadMultipleEvidence({
    required String complaintId,
    required List<EvidenceUploadInput> items,
    void Function(int itemIndex, double progress)? onProgress,
  }) async {
    final List<EvidenceUploadResult> results = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final result = await uploadComplaintEvidence(
        complaintId: complaintId,
        fileName: item.fileName,
        fileBytes: item.fileBytes,
        metadata: item.metadata,
        onProgress: onProgress != null ? (p) => onProgress(i, p) : null,
      );
      results.add(result);
    }

    return results;
  }

  @override
  Future<EvidenceUploadResult> uploadAvatar({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
    bool isGovtUser = false,
    void Function(double progress)? onProgress,
  }) async {
    final validation = validateBytes(
      bytes: fileBytes,
      fileName: fileName,
      maxSizeBytes: FirebaseStoragePaths.maxAvatarFileSize,
    );
    if (!validation.isValid) {
      throw StorageException(
        code: 'invalid-file',
        message: 'Avatar file failed validation: ${validation.errors.join("; ")}',
        userMessage: validation.errors.first,
        isRecoverable: false,
      );
    }

    final path = isGovtUser
        ? FirebaseStoragePaths.govtAvatarPath(userId, fileName)
        : FirebaseStoragePaths.userAvatarPath(userId, fileName);

    final ref = _storageInstance.ref(path);

    try {
      final settableMetadata = SettableMetadata(
        contentType: validation.mimeType ?? 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'isGovtUser': isGovtUser.toString(),
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(fileBytes, settableMetadata);

      StreamSubscription? subscription;
      if (onProgress != null) {
        subscription = uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final fraction = (event.bytesTransferred / event.totalBytes).clamp(0.0, 1.0);
            onProgress(fraction);
          }
        });
      }

      await uploadTask;
      await subscription?.cancel();

      final downloadUrl = await ref.getDownloadURL();

      return EvidenceUploadResult(
        storagePath: path,
        downloadUrl: downloadUrl,
        fileName: FirebaseStoragePaths.sanitizeFileName(fileName),
        mimeType: validation.mimeType ?? 'image/jpeg',
        sizeInBytes: fileBytes.lengthInBytes,
        uploadedAt: DateTime.now(),
      );
    } catch (e, st) {
      throw StorageErrorHandler.handle(e, st);
    }
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      return await _storageInstance.ref(storagePath).getDownloadURL();
    } catch (e, st) {
      throw StorageErrorHandler.handle(e, st);
    }
  }

  @override
  Future<void> deleteEvidence(String storagePath) async {
    try {
      await _storageInstance.ref(storagePath).delete();
    } catch (e, st) {
      throw StorageErrorHandler.handle(e, st);
    }
  }

  @override
  Future<List<String>> listEvidenceForComplaint(String complaintId) async {
    try {
      final prefix = '${FirebaseStoragePaths.complaintEvidence}/$complaintId';
      final listResult = await _storageInstance.ref(prefix).listAll();
      return listResult.items.map((ref) => ref.fullPath).toList();
    } catch (e, st) {
      throw StorageErrorHandler.handle(e, st);
    }
  }
}
