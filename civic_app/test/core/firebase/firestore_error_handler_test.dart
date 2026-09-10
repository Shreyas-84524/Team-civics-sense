import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/errors/firestore_error_handler.dart';
import 'package:civic_app/core/firebase/errors/firestore_exception.dart';

void main() {
  group('FirestoreErrorHandler Unit Tests', () {
    test('Translates permission-denied to FirestorePermissionDeniedException', () {
      final fbError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      final result = FirestoreErrorHandler.handle(fbError);
      expect(result, isA<FirestorePermissionDeniedException>());
      expect(result.code, equals('permission-denied'));
    });

    test('Translates not-found to FirestoreNotFoundException', () {
      final fbError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'No document to update.',
      );

      final result = FirestoreErrorHandler.handle(fbError);
      expect(result, isA<FirestoreNotFoundException>());
      expect(result.code, equals('not-found'));
    });

    test('Translates unavailable and network-request-failed to FirestoreUnavailableException', () {
      final fbError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'The service is currently unavailable.',
      );

      final result = FirestoreErrorHandler.handle(fbError);
      expect(result, isA<FirestoreUnavailableException>());
    });

    test('Passes through existing FirestoreException unchanged', () {
      const custom = FirestoreTimeoutException('Custom timeout');
      final result = FirestoreErrorHandler.handle(custom);
      expect(result, same(custom));
    });

    test('Handles generic errors gracefully', () {
      final generic = Exception('Unexpected disk failure');
      final result = FirestoreErrorHandler.handle(generic);
      expect(result, isA<FirestoreException>());
      expect(result.code, equals('unknown'));
    });
  });
}
