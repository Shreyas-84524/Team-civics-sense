import 'dart:typed_data';
import '../firebase_constants.dart';

/// Represents the validation state of an evidence file before upload.
class EvidenceFileValidation {
  final bool isValid;
  final List<String> errors;
  final String? mimeType;
  final int sizeInBytes;
  final String fileExtension;

  const EvidenceFileValidation({
    required this.isValid,
    required this.errors,
    required this.sizeInBytes,
    required this.fileExtension,
    this.mimeType,
  });

  /// Creates a successful validation instance.
  factory EvidenceFileValidation.success({
    required int sizeInBytes,
    required String fileExtension,
    required String mimeType,
  }) {
    return EvidenceFileValidation(
      isValid: true,
      errors: const [],
      sizeInBytes: sizeInBytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
  }

  /// Creates a failed validation instance.
  factory EvidenceFileValidation.failure({
    required List<String> errors,
    int sizeInBytes = 0,
    String fileExtension = '',
    String? mimeType,
  }) {
    return EvidenceFileValidation(
      isValid: false,
      errors: List.unmodifiable(errors),
      sizeInBytes: sizeInBytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
  }

  /// Inspects bytes and file name to validate size, extension, and MIME format.
  factory EvidenceFileValidation.validateBytes({
    required Uint8List bytes,
    required String fileName,
    int maxSizeBytes = FirebaseStoragePaths.maxEvidenceFileSize,
    int minSizeBytes = FirebaseStoragePaths.minValidFileSize,
  }) {
    final List<String> validationErrors = [];
    final size = bytes.lengthInBytes;
    final extension = _extractExtension(fileName);
    final detectedMime = _detectMimeFromBytesOrExtension(bytes, extension);

    if (size < minSizeBytes) {
      validationErrors.add(
        'File size ($size bytes) is too small. Minimum required is $minSizeBytes bytes.',
      );
    }

    if (size > maxSizeBytes) {
      final maxMb = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      final fileMb = (size / (1024 * 1024)).toStringAsFixed(2);
      validationErrors.add(
        'File size ($fileMb MB) exceeds maximum allowed limit ($maxMb MB).',
      );
    }

    if (!FirebaseStoragePaths.allowedImageExtensions.contains(extension.toLowerCase())) {
      validationErrors.add(
        'File extension "$extension" is not supported. Allowed: ${FirebaseStoragePaths.allowedImageExtensions.join(', ')}.',
      );
    }

    if (detectedMime == null || !FirebaseStoragePaths.allowedEvidenceMimeTypes.contains(detectedMime)) {
      validationErrors.add(
        'MIME type "${detectedMime ?? 'unknown'}" is not supported. Allowed: ${FirebaseStoragePaths.allowedEvidenceMimeTypes.join(', ')}.',
      );
    }

    if (validationErrors.isNotEmpty) {
      return EvidenceFileValidation.failure(
        errors: validationErrors,
        sizeInBytes: size,
        fileExtension: extension,
        mimeType: detectedMime,
      );
    }

    return EvidenceFileValidation.success(
      sizeInBytes: size,
      fileExtension: extension,
      mimeType: detectedMime!,
    );
  }

  static String _extractExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex).toLowerCase();
  }

  /// Detects MIME type using magic header bytes (JPEG, PNG, WEBP) or falls back to extension.
  static String? _detectMimeFromBytesOrExtension(Uint8List bytes, String extension) {
    if (bytes.length >= 3) {
      // JPEG magic numbers: 0xFF 0xD8 0xFF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      // PNG magic numbers: 0x89 0x50 0x4E 0x47 (89 50 4E 47 0D 0A 1A 0A)
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      // WEBP magic numbers: RIFF....WEBP
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
    }

    // Fallback based on extension
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  @override
  String toString() =>
      'EvidenceFileValidation(isValid: $isValid, size: $sizeInBytes, mime: $mimeType, errors: $errors)';
}

/// Lifecycle status for an evidence upload task.
enum EvidenceUploadStatus {
  idle,
  uploading,
  paused,
  success,
  failed,
  canceled,
}

/// Progress event emitted during media uploads.
class EvidenceUploadProgress {
  final int bytesTransferred;
  final int totalBytes;
  final double progress;
  final EvidenceUploadStatus status;
  final String? error;

  const EvidenceUploadProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.progress,
    required this.status,
    this.error,
  });

  factory EvidenceUploadProgress.initial() {
    return const EvidenceUploadProgress(
      bytesTransferred: 0,
      totalBytes: 0,
      progress: 0.0,
      status: EvidenceUploadStatus.idle,
    );
  }

  factory EvidenceUploadProgress.running({
    required int transferred,
    required int total,
  }) {
    final double fraction = total > 0 ? (transferred / total).clamp(0.0, 1.0) : 0.0;
    return EvidenceUploadProgress(
      bytesTransferred: transferred,
      totalBytes: total,
      progress: fraction,
      status: EvidenceUploadStatus.uploading,
    );
  }

  factory EvidenceUploadProgress.completed({required int total}) {
    return EvidenceUploadProgress(
      bytesTransferred: total,
      totalBytes: total,
      progress: 1.0,
      status: EvidenceUploadStatus.success,
    );
  }

  factory EvidenceUploadProgress.failed(String errorMessage) {
    return EvidenceUploadProgress(
      bytesTransferred: 0,
      totalBytes: 0,
      progress: 0.0,
      status: EvidenceUploadStatus.failed,
      error: errorMessage,
    );
  }

  @override
  String toString() =>
      'EvidenceUploadProgress(${(progress * 100).toStringAsFixed(1)}% - status: $status)';
}

/// Metadata attached to Cloud Storage objects for auditing, classification, and security.
class EvidenceMetadata {
  final String complaintId;
  final String uploaderId;
  final String? category;
  final bool isHazard;
  final double? latitude;
  final double? longitude;
  final DateTime uploadedAt;
  final String contentType;
  final Map<String, String> customMetadata;

  EvidenceMetadata({
    required this.complaintId,
    required this.uploaderId,
    this.category,
    this.isHazard = false,
    this.latitude,
    this.longitude,
    DateTime? uploadedAt,
    this.contentType = 'image/jpeg',
    this.customMetadata = const {},
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  /// Const constructor when explicit uploadedAt timestamp is provided.
  const EvidenceMetadata.withTimestamp({
    required this.complaintId,
    required this.uploaderId,
    required this.uploadedAt,
    this.category,
    this.isHazard = false,
    this.latitude,
    this.longitude,
    this.contentType = 'image/jpeg',
    this.customMetadata = const {},
  });

  /// Converts this metadata into a key-value map for Firebase Storage customMetadata.
  Map<String, String> toCustomMetadataMap() {
    final cat = category;
    final lat = latitude;
    final lng = longitude;
    return {
      'complaintId': complaintId,
      'uploaderId': uploaderId,
      'category': ?cat,
      'isHazard': isHazard.toString(),
      if (lat != null) 'latitude': lat.toString(),
      if (lng != null) 'longitude': lng.toString(),
      'uploadedAt': uploadedAt.toIso8601String(),
      ...customMetadata,
    };
  }

  factory EvidenceMetadata.fromMap(Map<String, dynamic> map) {
    return EvidenceMetadata(
      complaintId: map['complaintId'] as String? ?? '',
      uploaderId: map['uploaderId'] as String? ?? '',
      category: map['category'] as String?,
      isHazard: map['isHazard'] == true || map['isHazard'] == 'true',
      latitude: (map['latitude'] is num)
          ? (map['latitude'] as num).toDouble()
          : double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: (map['longitude'] is num)
          ? (map['longitude'] as num).toDouble()
          : double.tryParse(map['longitude']?.toString() ?? ''),
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.tryParse(map['uploadedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      contentType: map['contentType'] as String? ?? 'image/jpeg',
      customMetadata: (map['customMetadata'] as Map?)?.cast<String, String>() ?? const {},
    );
  }
}

/// Immutable record returned after a successful media upload to Firebase Storage.
class EvidenceUploadResult {
  final String storagePath;
  final String downloadUrl;
  final String fileName;
  final String mimeType;
  final int sizeInBytes;
  final EvidenceMetadata? metadata;
  final DateTime uploadedAt;

  EvidenceUploadResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.fileName,
    required this.mimeType,
    required this.sizeInBytes,
    this.metadata,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  /// Const constructor when explicit uploadedAt timestamp is provided.
  const EvidenceUploadResult.withTimestamp({
    required this.storagePath,
    required this.downloadUrl,
    required this.fileName,
    required this.mimeType,
    required this.sizeInBytes,
    required this.uploadedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeInBytes': sizeInBytes,
      'uploadedAt': uploadedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata!.toCustomMetadataMap(),
    };
  }

  factory EvidenceUploadResult.fromMap(Map<String, dynamic> map) {
    return EvidenceUploadResult(
      storagePath: map['storagePath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? 'image/jpeg',
      sizeInBytes: (map['sizeInBytes'] as num?)?.toInt() ?? 0,
      metadata: map['metadata'] != null
          ? EvidenceMetadata.fromMap((map['metadata'] as Map).cast<String, dynamic>())
          : null,
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.tryParse(map['uploadedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'EvidenceUploadResult(path: $storagePath, size: $sizeInBytes, url: $downloadUrl)';
}
