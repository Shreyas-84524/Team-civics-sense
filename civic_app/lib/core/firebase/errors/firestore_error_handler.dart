import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_exception.dart';

/// Translates raw Firebase exceptions and errors into application-level [FirestoreException]s.
class FirestoreErrorHandler {
  FirestoreErrorHandler._();

  /// Converts any exception into a typed [FirestoreException].
  static FirestoreException handle(dynamic error, [StackTrace? stackTrace]) {
    if (error is FirestoreException) {
      return error;
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return FirestorePermissionDeniedException(
            error.message ?? 'Permission denied to perform this Firestore operation.',
          );
        case 'not-found':
          return FirestoreNotFoundException(
            error.message ?? 'The requested document does not exist.',
          );
        case 'unavailable':
        case 'network-request-failed':
          return FirestoreUnavailableException(
            error.message ?? 'Firestore is currently unavailable or device is offline.',
          );
        case 'already-exists':
          return FirestoreAlreadyExistsException(
            error.message ?? 'Document already exists in Firestore.',
          );
        case 'deadline-exceeded':
          return FirestoreTimeoutException(
            error.message ?? 'Firestore operation exceeded deadline.',
          );
        case 'cancelled':
          return FirestoreException(
            message: 'Firestore operation was cancelled.',
            code: 'cancelled',
            cause: error,
            stackTrace: stackTrace,
          );
        case 'failed-precondition':
          return FirestoreException(
            message: error.message ?? 'Operation failed precondition check.',
            code: 'failed-precondition',
            cause: error,
            stackTrace: stackTrace,
          );
        default:
          return FirestoreException(
            message: error.message ?? 'An unexpected Firestore error occurred (${error.code}).',
            code: error.code,
            cause: error,
            stackTrace: stackTrace,
          );
      }
    }

    return FirestoreException(
      message: error.toString(),
      code: 'unknown',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
