import 'dart:typed_data';
import 'evidence_storage_models.dart';

/// Item descriptor for batch media uploads.
class EvidenceUploadInput {
  final String fileName;
  final Uint8List fileBytes;
  final EvidenceMetadata? metadata;

  const EvidenceUploadInput({
    required this.fileName,
    required this.fileBytes,
    this.metadata,
  });
}

/// Abstract contract defining cloud evidence storage and media handling operations.
abstract class EvidenceStorageService {
  /// Validates raw image bytes and file name against system size and format constraints.
  EvidenceFileValidation validateBytes({
    required Uint8List bytes,
    required String fileName,
    int maxSizeBytes,
    int minSizeBytes,
  });

  /// Uploads a single complaint photo evidence to Firebase Storage.
  /// Emits progress ratio (0.0 to 1.0) via [onProgress] if provided.
  Future<EvidenceUploadResult> uploadComplaintEvidence({
    required String complaintId,
    required String fileName,
    required Uint8List fileBytes,
    EvidenceMetadata? metadata,
    void Function(double progress)? onProgress,
  });

  /// Uploads multiple complaint photos sequentially or in batch.
  /// Emits individual progress via [onProgress(itemIndex, progress)].
  Future<List<EvidenceUploadResult>> uploadMultipleEvidence({
    required String complaintId,
    required List<EvidenceUploadInput> items,
    void Function(int itemIndex, double progress)? onProgress,
  });

  /// Uploads a citizen or government profile avatar.
  Future<EvidenceUploadResult> uploadAvatar({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
    bool isGovtUser = false,
    void Function(double progress)? onProgress,
  });

  /// Retrieves a publicly accessible or authenticated download URL for a storage path.
  Future<String> getDownloadUrl(String storagePath);

  /// Deletes a file from Cloud Storage by path.
  Future<void> deleteEvidence(String storagePath);

  /// Lists all stored storage reference paths or URLs for a given complaint.
  Future<List<String>> listEvidenceForComplaint(String complaintId);
}
