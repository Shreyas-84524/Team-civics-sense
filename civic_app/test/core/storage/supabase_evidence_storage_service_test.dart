import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:civic_app/core/firebase/storage/storage_error_handler.dart';
import 'package:civic_app/core/storage/supabase_evidence_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseEvidenceStorageService Tests', () {
    late Uint8List validJpegBytes;

    setUp(() {
      // Valid JPEG header
      final dummy = List<int>.filled(512, 0);
      dummy[0] = 0xFF;
      dummy[1] = 0xD8;
      dummy[2] = 0xFF;
      dummy[3] = 0xE0;
      validJpegBytes = Uint8List.fromList(dummy);
    });

    test('validateBytes accepts valid JPEG within size limit', () {
      final service = SupabaseEvidenceStorageService(
        tokenProvider: () async => 'test_token',
      );

      final result = service.validateBytes(
        bytes: validJpegBytes,
        fileName: 'pothole_photo.jpg',
      );

      expect(result.isValid, isTrue);
      expect(result.mimeType, 'image/jpeg');
    });

    test('validateBytes rejects unsupported file extensions', () {
      final service = SupabaseEvidenceStorageService(
        tokenProvider: () async => 'test_token',
      );

      final result = service.validateBytes(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'malicious_script.exe',
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('not supported')), isTrue);
    });

    test('uploadComplaintEvidence sends deterministic ticket path & bearer token', () async {
      final mockClient = MockClient((request) async {
        final reqBody = jsonDecode(request.body) as Map<String, dynamic>;

        expect(reqBody['ticketNumber'], 'CF-2026-000026');
        expect(reqBody['evidenceIndex'], 1);
        expect(reqBody['mimeType'], 'image/jpeg');
        expect(request.headers['Authorization'], 'Bearer mock_firebase_token_xyz');

        return http.Response(
          jsonEncode({
            'success': true,
            'bucket': 'complaint-evidence',
            'storagePath': 'CF-2026-000026/CF-2026-000026_evidence_01.jpg',
            'originalFileName': 'pothole.jpg',
            'mimeType': 'image/jpeg',
            'evidenceIndex': 1,
            'sizeInBytes': validJpegBytes.length,
            'signedUrl': 'https://hkgwsqasmboadvpjckbj.supabase.co/storage/v1/object/sign/complaint-evidence/CF-2026-000026/CF-2026-000026_evidence_01.jpg?token=abc',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseEvidenceStorageService(
        client: mockClient,
        tokenProvider: () async => 'mock_firebase_token_xyz',
      );

      final result = await service.uploadComplaintEvidence(
        complaintId: 'cmp_12345',
        ticketNumber: 'CF-2026-000026',
        evidenceIndex: 1,
        fileName: 'pothole.jpg',
        fileBytes: validJpegBytes,
      );

      expect(result.storagePath, 'CF-2026-000026/CF-2026-000026_evidence_01.jpg');
      expect(result.downloadUrl, result.storagePath);
      expect(await service.getDownloadUrl(result.downloadUrl), contains('https://hkgwsqasmboadvpjckbj.supabase.co'));
      expect(result.mimeType, 'image/jpeg');
    });

    test('getDownloadUrl generates and caches signed URL', () async {
      int callCount = 0;

      final mockClient = MockClient((request) async {
        callCount++;
        final reqBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(reqBody['storagePath'], 'CF-2026-000026/CF-2026-000026_evidence_01.jpg');

        return http.Response(
          jsonEncode({
            'success': true,
            'bucket': 'complaint-evidence',
            'storagePath': 'CF-2026-000026/CF-2026-000026_evidence_01.jpg',
            'signedUrl': 'https://hkgwsqasmboadvpjckbj.supabase.co/signed-url-for-cf',
            'expiresIn': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseEvidenceStorageService(
        client: mockClient,
        tokenProvider: () async => 'mock_firebase_token_xyz',
      );

      // First call -> triggers network call
      final url1 = await service.getDownloadUrl('CF-2026-000026/CF-2026-000026_evidence_01.jpg');
      expect(url1, 'https://hkgwsqasmboadvpjckbj.supabase.co/signed-url-for-cf');
      expect(callCount, 1);

      // Second call for same path -> retrieved from memory cache
      final url2 = await service.getDownloadUrl('CF-2026-000026/CF-2026-000026_evidence_01.jpg');
      expect(url2, 'https://hkgwsqasmboadvpjckbj.supabase.co/signed-url-for-cf');
      expect(callCount, 1);
    });

    test('deleteEvidence sends delete action to Edge Function', () async {
      bool deleteCalled = false;

      final mockClient = MockClient((request) async {
        final reqBody = jsonDecode(request.body) as Map<String, dynamic>;
        if (reqBody['action'] == 'delete') {
          deleteCalled = true;
          expect(reqBody['storagePath'], 'CF-2026-000026/CF-2026-000026_evidence_01.jpg');
          return http.Response(jsonEncode({'success': true}), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('not found', 404);
      });

      final service = SupabaseEvidenceStorageService(
        client: mockClient,
        tokenProvider: () async => 'mock_firebase_token_xyz',
      );

      await service.deleteEvidence('CF-2026-000026/CF-2026-000026_evidence_01.jpg');
      expect(deleteCalled, isTrue);
    });

    test('uploadComplaintEvidence throws StorageException on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'error': 'FILE_TOO_LARGE', 'message': 'File size exceeds limit.'}),
          413,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabaseEvidenceStorageService(
        client: mockClient,
        tokenProvider: () async => 'mock_token',
      );

      expect(
        () => service.uploadComplaintEvidence(
          complaintId: 'cmp_123',
          fileName: 'large.jpg',
          fileBytes: validJpegBytes,
        ),
        throwsA(isA<StorageException>()),
      );
    });
  });
}
