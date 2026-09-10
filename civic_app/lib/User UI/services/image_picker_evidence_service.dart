import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/location/location_model.dart';
import '../../core/models/evidence_model.dart';
import 'evidence_service.dart';

/// Production implementation of [EvidenceService] utilizing device camera and photo gallery via [ImagePicker].
class ImagePickerEvidenceService implements EvidenceService {
  final ImagePicker _picker;

  ImagePickerEvidenceService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<CivicPermissionStatus> checkPermission(EvidenceSource source) async {
    // image_picker automatically negotiates platform permissions at runtime
    return CivicPermissionStatus.granted;
  }

  @override
  Future<CivicPermissionStatus> requestPermission(EvidenceSource source) async {
    // Platform permission dialogue triggered on-demand by image_picker
    return CivicPermissionStatus.granted;
  }

  @override
  Future<EvidenceItem?> captureFromCamera({
    double? maxWidth = 1920,
    double? maxHeight = 1080,
    int? imageQuality = 85,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (photo == null) {
        return null; // User cancelled capture
      }

      final timestamp = DateTime.now();
      final id = 'evidence_cam_${timestamp.millisecondsSinceEpoch}';
      final rawName = photo.name.isNotEmpty ? photo.name : photo.path;
      final fileName = rawName.contains('/') || rawName.contains('\\')
          ? rawName.split(RegExp(r'[/\\]')).last
          : (rawName.isNotEmpty ? rawName : 'camera_capture_${timestamp.millisecondsSinceEpoch}.jpg');

      return EvidenceItem(
        id: id,
        filePath: photo.path,
        fileName: fileName,
        source: EvidenceSource.camera,
        capturedAt: timestamp,
      );
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' ||
          e.code == 'permission_denied' ||
          e.code == 'photo_access_denied') {
        throw Exception('Camera permission was denied. Please grant camera access in your device settings.');
      }
      debugPrint('[ImagePickerEvidenceService] Camera PlatformException: ${e.code} - ${e.message}');
      throw Exception('Camera capture error: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('[ImagePickerEvidenceService] Camera capture failed: $e');
      throw Exception('Failed to capture photo from camera: $e');
    }
  }

  @override
  Future<EvidenceItem?> pickFromGallery({
    double? maxWidth = 1920,
    double? maxHeight = 1080,
    int? imageQuality = 85,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (photo == null) {
        return null; // User cancelled photo selection
      }

      final timestamp = DateTime.now();
      final id = 'evidence_gal_${timestamp.millisecondsSinceEpoch}';
      final rawName = photo.name.isNotEmpty ? photo.name : photo.path;
      final fileName = rawName.contains('/') || rawName.contains('\\')
          ? rawName.split(RegExp(r'[/\\]')).last
          : (rawName.isNotEmpty ? rawName : 'gallery_photo_${timestamp.millisecondsSinceEpoch}.jpg');

      return EvidenceItem(
        id: id,
        filePath: photo.path,
        fileName: fileName,
        source: EvidenceSource.gallery,
        capturedAt: timestamp,
      );
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' ||
          e.code == 'permission_denied' ||
          e.code == 'camera_access_denied') {
        throw Exception('Photo gallery permission was denied. Please grant gallery access in your device settings.');
      }
      debugPrint('[ImagePickerEvidenceService] Gallery PlatformException: ${e.code} - ${e.message}');
      throw Exception('Gallery photo selection error: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('[ImagePickerEvidenceService] Gallery selection failed: $e');
      throw Exception('Failed to pick photo from gallery: $e');
    }
  }
}
