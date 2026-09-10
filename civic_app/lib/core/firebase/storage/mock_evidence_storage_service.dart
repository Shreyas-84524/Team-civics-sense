import 'dart:async';
import 'dart:typed_data';
import '../firebase_constants.dart';
import 'evidence_storage_models.dart';
import 'evidence_storage_service.dart';
import 'storage_error_handler.dart';

/// In-memory mock implementation of [EvidenceStorageService] for local testing,
/// offline simulations, and automated unit/widget test suites.
class MockEvidenceStorageService implements EvidenceStorageService {
  final Map<String, Uint8List> _storage = {};
  final Map<String, EvidenceMetadata?> _metadataStorage = {};

  bool simulateNetworkError = false;
  bool simulateQuotaExceeded = false;
  bool simulateUnauthorized = false;
  Duration latency = const Duration(milliseconds: 10);

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
    await _applySimulation();

    final validation = validateBytes(bytes: fileBytes, fileName: fileName);
    if (!validation.isValid) {
      throw StorageException(
        code: 'invalid-file',
        message: 'File failed validation: ${validation.errors.join("; ")}',
        userMessage: validation.errors.first,
        isRecoverable: false,
      );
    }

    // Simulate progress ticks
    if (onProgress != null) {
      onProgress(0.25);
      await Future.delayed(const Duration(milliseconds: 5));
      onProgress(0.75);
      await Future.delayed(const Duration(milliseconds: 5));
      onProgress(1.0);
    }

    final path = FirebaseStoragePaths.complaintEvidencePath(complaintId, fileName);
    _storage[path] = Uint8List.fromList(fileBytes);
    _metadataStorage[path] = metadata;

    final downloadUrl =
        'https://firebasestorage.googleapis.com/v0/b/civicfix-38d53.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';

    return EvidenceUploadResult(
      storagePath: path,
      downloadUrl: downloadUrl,
      fileName: FirebaseStoragePaths.sanitizeFileName(fileName),
      mimeType: validation.mimeType ?? 'image/jpeg',
      sizeInBytes: fileBytes.lengthInBytes,
      metadata: metadata,
      uploadedAt: DateTime.now(),
    );
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
    await _applySimulation();

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

    if (onProgress != null) {
      onProgress(0.5);
      await Future.delayed(const Duration(milliseconds: 5));
      onProgress(1.0);
    }

    final path = isGovtUser
        ? FirebaseStoragePaths.govtAvatarPath(userId, fileName)
        : FirebaseStoragePaths.userAvatarPath(userId, fileName);

    _storage[path] = Uint8List.fromList(fileBytes);

    final downloadUrl =
        'https://firebasestorage.googleapis.com/v0/b/civicfix-38d53.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';

    return EvidenceUploadResult(
      storagePath: path,
      downloadUrl: downloadUrl,
      fileName: FirebaseStoragePaths.sanitizeFileName(fileName),
      mimeType: validation.mimeType ?? 'image/jpeg',
      sizeInBytes: fileBytes.lengthInBytes,
      uploadedAt: DateTime.now(),
    );
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    await _applySimulation();

    if (!_storage.containsKey(storagePath)) {
      throw const StorageException(
        code: 'object-not-found',
        message: 'No mock storage object exists at the specified path.',
        userMessage: 'The requested image could not be found.',
      );
    }

    return 'https://firebasestorage.googleapis.com/v0/b/civicfix-38d53.appspot.com/o/${Uri.encodeComponent(storagePath)}?alt=media';
  }

  @override
  Future<void> deleteEvidence(String storagePath) async {
    await _applySimulation();

    if (!_storage.containsKey(storagePath)) {
      throw const StorageException(
        code: 'object-not-found',
        message: 'Cannot delete non-existent object.',
        userMessage: 'The file to delete was not found.',
      );
    }

    _storage.remove(storagePath);
    _metadataStorage.remove(storagePath);
  }

  @override
  Future<List<String>> listEvidenceForComplaint(String complaintId) async {
    await _applySimulation();

    final prefix = '${FirebaseStoragePaths.complaintEvidence}/$complaintId/';
    return _storage.keys.where((path) => path.startsWith(prefix)).toList();
  }

  Future<void> _applySimulation() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }

    if (simulateNetworkError) {
      throw const StorageException(
        code: 'network-unavailable',
        message: 'Simulated network connection failure.',
        userMessage: 'Unable to reach the server. Please check your internet connection.',
        isRecoverable: true,
      );
    }

    if (simulateQuotaExceeded) {
      throw const StorageException(
        code: 'quota-exceeded',
        message: 'Simulated cloud storage quota limit exceeded.',
        userMessage: 'Storage capacity temporarily exceeded. Please try again later.',
        isRecoverable: false,
      );
    }

    if (simulateUnauthorized) {
      throw const StorageException(
        code: 'unauthorized',
        message: 'Simulated permission denied by storage security rules.',
        userMessage: 'You do not have permission to perform this media action.',
        isRecoverable: false,
      );
    }
  }

  /// Inspect stored data (for assertions in unit tests).
  int get storedFileCount => _storage.length;

  bool containsPath(String path) => _storage.containsKey(path);

  Uint8List? getBytes(String path) => _storage[path];

  EvidenceMetadata? getMetadata(String path) => _metadataStorage[path];

  /// Resets mock storage and error flags.
  void reset() {
    _storage.clear();
    _metadataStorage.clear();
    simulateNetworkError = false;
    simulateQuotaExceeded = false;
    simulateUnauthorized = false;
    latency = const Duration(milliseconds: 10);
  }
}
