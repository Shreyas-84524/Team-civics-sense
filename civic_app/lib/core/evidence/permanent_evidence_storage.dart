import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for managing permanent local storage for complaint evidence photos.
///
/// Fixes the temporary cache bug where image_picker cache paths are cleared by the OS
/// before complaints can be synchronized.
class PermanentEvidenceStorage {
  final Directory? _baseDirectory;

  PermanentEvidenceStorage({Directory? baseDirectory}) : _baseDirectory = baseDirectory;

  /// Resolves the permanent application evidence directory.
  Future<Directory> getEvidenceDirectory() async {
    final base = _baseDirectory ?? await getApplicationDocumentsDirectory();
    final evidenceDir = Directory(p.join(base.path, 'evidence'));
    if (!await evidenceDir.exists()) {
      await evidenceDir.create(recursive: true);
    }
    return evidenceDir;
  }

  /// Copies an image from a temporary/cache path to permanent app storage.
  ///
  /// If [sourceFilePath] is already in the permanent evidence directory, it returns
  /// the path immediately without re-copying (idempotent; prevents duplicate files on retries).
  ///
  /// Naming convention:
  /// `evidence_{complaintId}_{index}{ext}`
  Future<String> persistEvidenceFile(
    String sourceFilePath, {
    String? complaintId,
    int index = 0,
  }) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      debugPrint('[PermanentEvidenceStorage] Warning: Source file does not exist: $sourceFilePath');
      return sourceFilePath;
    }

    final evidenceDir = await getEvidenceDirectory();
    final sourceDirNormalized = p.normalize(sourceFile.parent.path);
    final targetDirNormalized = p.normalize(evidenceDir.path);

    // Idempotency: If already in evidence directory, do not create duplicate
    if (sourceDirNormalized == targetDirNormalized) {
      debugPrint('[PermanentEvidenceStorage] File is already in permanent storage: $sourceFilePath');
      return sourceFilePath;
    }

    final ext = p.extension(sourceFilePath).isNotEmpty
        ? p.extension(sourceFilePath).toLowerCase()
        : '.jpg';

    final safeComplaintId = (complaintId != null && complaintId.isNotEmpty)
        ? complaintId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'draft_${DateTime.now().millisecondsSinceEpoch}';

    final targetFileName = 'evidence_${safeComplaintId}_$index$ext';
    final targetPath = p.join(evidenceDir.path, targetFileName);
    final targetFile = File(targetPath);

    // If destination already exists with same size, return existing to avoid duplicate IO
    if (await targetFile.exists()) {
      final sourceLen = await sourceFile.length();
      final targetLen = await targetFile.length();
      if (sourceLen == targetLen) {
        debugPrint('[PermanentEvidenceStorage] Permanent file already exists with matching size: $targetPath');
        return targetPath;
      }
    }

    await sourceFile.copy(targetPath);
    debugPrint('[PermanentEvidenceStorage] Copied temporary evidence to permanent storage: $targetPath');
    return targetPath;
  }

  /// Checks if a file path is located in the permanent evidence storage directory.
  Future<bool> isPermanentPath(String filePath) async {
    try {
      final evidenceDir = await getEvidenceDirectory();
      final targetDir = p.normalize(File(filePath).parent.path);
      return targetDir == p.normalize(evidenceDir.path);
    } catch (_) {
      return false;
    }
  }
}
