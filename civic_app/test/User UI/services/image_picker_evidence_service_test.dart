import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/evidence_model.dart';
import 'package:civic_app/User UI/services/evidence_service.dart';
import 'package:civic_app/User UI/services/image_picker_evidence_service.dart';

class FakeImagePicker extends ImagePicker {
  XFile? pickImageResult;
  bool shouldThrowPlatformException = false;
  String platformErrorCode = 'camera_access_denied';
  bool shouldThrowGenericException = false;

  ImageSource? lastSource;
  double? lastMaxWidth;
  double? lastMaxHeight;
  int? lastImageQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    lastMaxWidth = maxWidth;
    lastMaxHeight = maxHeight;
    lastImageQuality = imageQuality;

    if (shouldThrowPlatformException) {
      throw PlatformException(code: platformErrorCode, message: 'Platform error for $source');
    }
    if (shouldThrowGenericException) {
      throw Exception('Generic error during capture');
    }
    return pickImageResult;
  }
}

void main() {
  group('ImagePickerEvidenceService Unit Tests', () {
    late FakeImagePicker fakePicker;
    late ImagePickerEvidenceService service;

    setUp(() {
      fakePicker = FakeImagePicker();
      service = ImagePickerEvidenceService(picker: fakePicker);
    });

    test('Satisfies EvidenceService interface contract', () {
      expect(service, isA<EvidenceService>());
    });

    test('Permissions check and request return granted on modern image_picker', () async {
      final checkCam = await service.checkPermission(EvidenceSource.camera);
      final checkGal = await service.checkPermission(EvidenceSource.gallery);
      final reqCam = await service.requestPermission(EvidenceSource.camera);
      final reqGal = await service.requestPermission(EvidenceSource.gallery);

      expect(checkCam, equals(CivicPermissionStatus.granted));
      expect(checkGal, equals(CivicPermissionStatus.granted));
      expect(reqCam, equals(CivicPermissionStatus.granted));
      expect(reqGal, equals(CivicPermissionStatus.granted));
    });

    test('captureFromCamera returns EvidenceItem on successful photo capture', () async {
      fakePicker.pickImageResult = XFile('/tmp/camera_sample.jpg', name: 'camera_sample.jpg');

      final result = await service.captureFromCamera();

      expect(result, isNotNull);
      expect(result!.filePath, equals('/tmp/camera_sample.jpg'));
      expect(result.fileName, equals('camera_sample.jpg'));
      expect(result.source, equals(EvidenceSource.camera));
      expect(result.id.startsWith('evidence_cam_'), isTrue);
      expect(fakePicker.lastSource, equals(ImageSource.camera));
      expect(fakePicker.lastMaxWidth, equals(1920));
      expect(fakePicker.lastMaxHeight, equals(1080));
      expect(fakePicker.lastImageQuality, equals(85));
    });

    test('captureFromCamera returns null when user cancels camera capture', () async {
      fakePicker.pickImageResult = null;

      final result = await service.captureFromCamera();

      expect(result, isNull);
      expect(fakePicker.lastSource, equals(ImageSource.camera));
    });

    test('pickFromGallery returns EvidenceItem on successful gallery selection', () async {
      fakePicker.pickImageResult = XFile('/tmp/gallery_sample.png', name: 'gallery_sample.png');

      final result = await service.pickFromGallery();

      expect(result, isNotNull);
      expect(result!.filePath, equals('/tmp/gallery_sample.png'));
      expect(result.fileName, equals('gallery_sample.png'));
      expect(result.source, equals(EvidenceSource.gallery));
      expect(result.id.startsWith('evidence_gal_'), isTrue);
      expect(fakePicker.lastSource, equals(ImageSource.gallery));
    });

    test('pickFromGallery returns null when user cancels gallery selection', () async {
      fakePicker.pickImageResult = null;

      final result = await service.pickFromGallery();

      expect(result, isNull);
      expect(fakePicker.lastSource, equals(ImageSource.gallery));
    });

    test('Throws informative exception when camera permission denied', () async {
      fakePicker.shouldThrowPlatformException = true;
      fakePicker.platformErrorCode = 'camera_access_denied';

      expect(
        () => service.captureFromCamera(),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Camera permission was denied'))),
      );
    });

    test('Throws informative exception when gallery permission denied', () async {
      fakePicker.shouldThrowPlatformException = true;
      fakePicker.platformErrorCode = 'photo_access_denied';

      expect(
        () => service.pickFromGallery(),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Photo gallery permission was denied'))),
      );
    });

    test('Throws wrapped exception on generic capture failure', () async {
      fakePicker.shouldThrowGenericException = true;

      expect(
        () => service.captureFromCamera(),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Failed to capture photo from camera'))),
      );
    });
  });
}
