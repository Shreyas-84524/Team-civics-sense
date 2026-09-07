import 'dart:async';
import '../../core/location/location_model.dart';
import '../../core/models/evidence_model.dart';

/// Abstract service interface defining photo evidence operations.
abstract class EvidenceService {
  /// Captures a new photo using the device camera.
  /// Returns `null` if the user cancels capture without error.
  Future<EvidenceItem?> captureFromCamera();

  /// Picks a photo from the device image gallery.
  /// Returns `null` if the user cancels selection without error.
  Future<EvidenceItem?> pickFromGallery();

  /// Checks the current permission status for the specified evidence source.
  Future<CivicPermissionStatus> checkPermission(EvidenceSource source);

  /// Requests permission from the user for the specified evidence source.
  Future<CivicPermissionStatus> requestPermission(EvidenceSource source);
}

/// In-memory mock implementation of EvidenceService for development and testing.
class MockEvidenceService implements EvidenceService {
  CivicPermissionStatus cameraPermission;
  CivicPermissionStatus galleryPermission;
  bool simulateError;
  bool simulateCancellation;
  int _counter = 0;

  MockEvidenceService({
    this.cameraPermission = CivicPermissionStatus.granted,
    this.galleryPermission = CivicPermissionStatus.granted,
    this.simulateError = false,
    this.simulateCancellation = false,
  });

  @override
  Future<CivicPermissionStatus> checkPermission(EvidenceSource source) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return source == EvidenceSource.camera ? cameraPermission : galleryPermission;
  }

  @override
  Future<CivicPermissionStatus> requestPermission(EvidenceSource source) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (source == EvidenceSource.camera) {
      if (cameraPermission == CivicPermissionStatus.notDetermined ||
          cameraPermission == CivicPermissionStatus.denied) {
        cameraPermission = CivicPermissionStatus.granted;
      }
      return cameraPermission;
    } else {
      if (galleryPermission == CivicPermissionStatus.notDetermined ||
          galleryPermission == CivicPermissionStatus.denied) {
        galleryPermission = CivicPermissionStatus.granted;
      }
      return galleryPermission;
    }
  }

  @override
  Future<EvidenceItem?> captureFromCamera() async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (cameraPermission != CivicPermissionStatus.granted) {
      final requested = await requestPermission(EvidenceSource.camera);
      if (requested != CivicPermissionStatus.granted) {
        throw Exception('Camera permission denied.');
      }
    }

    if (simulateError) {
      throw Exception('Camera device failure. Unable to capture photo.');
    }

    if (simulateCancellation) {
      return null;
    }

    _counter++;
    final timestamp = DateTime.now();
    return EvidenceItem(
      id: 'evidence_cam_${timestamp.millisecondsSinceEpoch}_$_counter',
      filePath: 'mock://camera/captured_photo_$_counter.jpg',
      fileName: 'camera_capture_$_counter.jpg',
      source: EvidenceSource.camera,
      capturedAt: timestamp,
    );
  }

  @override
  Future<EvidenceItem?> pickFromGallery() async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (galleryPermission != CivicPermissionStatus.granted) {
      final requested = await requestPermission(EvidenceSource.gallery);
      if (requested != CivicPermissionStatus.granted) {
        throw Exception('Gallery permission denied.');
      }
    }

    if (simulateError) {
      throw Exception('Gallery storage failure. Unable to read photo.');
    }

    if (simulateCancellation) {
      return null;
    }

    _counter++;
    final timestamp = DateTime.now();
    return EvidenceItem(
      id: 'evidence_gal_${timestamp.millisecondsSinceEpoch}_$_counter',
      filePath: 'mock://gallery/selected_photo_$_counter.jpg',
      fileName: 'gallery_photo_$_counter.jpg',
      source: EvidenceSource.gallery,
      capturedAt: timestamp,
    );
  }

  /// Helper to reset mock counters and simulation flags.
  void reset() {
    _counter = 0;
    cameraPermission = CivicPermissionStatus.granted;
    galleryPermission = CivicPermissionStatus.granted;
    simulateError = false;
    simulateCancellation = false;
  }
}
