/// Domain-level exception representing a failure in Firebase Firestore operations.
class FirestoreException implements Exception {
  final String message;
  final String code;
  final dynamic cause;
  final StackTrace? stackTrace;

  const FirestoreException({
    required this.message,
    this.code = 'unknown',
    this.cause,
    this.stackTrace,
  });

  String get userMessage => message;

  bool get isRecoverable =>
      code == 'unavailable' ||
      code == 'network-request-failed' ||
      code == 'deadline-exceeded' ||
      code == 'timeout';

  @override
  String toString() => 'FirestoreException [$code]: $message';
}

/// Specific Firestore failure types
class FirestorePermissionDeniedException extends FirestoreException {
  const FirestorePermissionDeniedException([String message = 'Access denied by Firestore security rules.'])
      : super(message: message, code: 'permission-denied');
}

class FirestoreNotFoundException extends FirestoreException {
  const FirestoreNotFoundException([String message = 'Requested document was not found in Firestore.'])
      : super(message: message, code: 'not-found');
}

class FirestoreUnavailableException extends FirestoreException {
  const FirestoreUnavailableException([String message = 'Firestore service is temporarily unavailable or device is offline.'])
      : super(message: message, code: 'unavailable');
}

class FirestoreAlreadyExistsException extends FirestoreException {
  const FirestoreAlreadyExistsException([String message = 'Document already exists in Firestore.'])
      : super(message: message, code: 'already-exists');
}

class FirestoreTimeoutException extends FirestoreException {
  const FirestoreTimeoutException([String message = 'Firestore operation timed out.'])
      : super(message: message, code: 'deadline-exceeded');
}
