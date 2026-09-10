import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

/// Typed domain exception representing Firebase Storage failures with user-friendly messages.
class StorageException implements Exception {
  final String code;
  final String message;
  final String userMessage;
  final bool isRecoverable;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const StorageException({
    required this.code,
    required this.message,
    required this.userMessage,
    this.isRecoverable = false,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'StorageException[$code]: $message (userMessage: "$userMessage")';
}

/// Centralized error translation utility for Firebase Cloud Storage.
class StorageErrorHandler {
  StorageErrorHandler._();

  /// Converts any thrown error or FirebaseException into a strongly-typed [StorageException].
  static StorageException handle(dynamic error, [StackTrace? stackTrace]) {
    if (error is StorageException) {
      return error;
    }

    if (error is FirebaseException) {
      return _handleFirebaseException(error, stackTrace);
    }

    if (error is SocketException || error is HttpException) {
      return StorageException(
        code: 'network-unavailable',
        message: 'Network connection failed during storage operation: ${error.toString()}',
        userMessage: 'Unable to reach the server. Please check your internet connection and try again.',
        isRecoverable: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException) {
      return StorageException(
        code: 'timeout',
        message: 'Storage operation timed out after ${error.duration?.inSeconds ?? 0} seconds.',
        userMessage: 'The upload timed out. Please check your connection and try again.',
        isRecoverable: true,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return StorageException(
        code: 'invalid-format',
        message: 'File format or URL structure invalid: ${error.message}',
        userMessage: 'The selected file format is invalid. Please choose a valid image file.',
        isRecoverable: false,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return StorageException(
      code: 'unknown',
      message: 'Unexpected storage error occurred: ${error.toString()}',
      userMessage: 'An unexpected error occurred while processing the image. Please try again.',
      isRecoverable: false,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static StorageException _handleFirebaseException(FirebaseException error, StackTrace? stackTrace) {
    final code = error.code.toLowerCase().replaceAll('storage/', '');

    switch (code) {
      case 'object-not-found':
        return StorageException(
          code: 'object-not-found',
          message: 'The requested storage object does not exist at the specified path.',
          userMessage: 'The requested image could not be found.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'unauthenticated':
        return StorageException(
          code: 'unauthenticated',
          message: 'User is not authenticated. A valid session is required for Storage operations.',
          userMessage: 'Please sign in to upload or access evidence photos.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'unauthorized':
      case 'permission-denied':
        return StorageException(
          code: 'unauthorized',
          message: 'Security rules rejected the storage request (insufficient permissions).',
          userMessage: 'You do not have permission to perform this media action.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'quota-exceeded':
        return StorageException(
          code: 'quota-exceeded',
          message: 'Cloud Storage project quota exceeded.',
          userMessage: 'Storage capacity temporarily exceeded. Please try again later.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'retry-limit-exceeded':
        return StorageException(
          code: 'retry-limit-exceeded',
          message: 'Maximum retry duration limit exceeded during upload/download.',
          userMessage: 'Upload connection was unstable. Please check your network and retry.',
          isRecoverable: true,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'invalid-checksum':
        return StorageException(
          code: 'invalid-checksum',
          message: 'Uploaded file checksum mismatch with remote server.',
          userMessage: 'Image integrity verification failed during upload. Please retry.',
          isRecoverable: true,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'canceled':
        return StorageException(
          code: 'canceled',
          message: 'Storage upload or download was canceled by user or runtime.',
          userMessage: 'Upload was canceled.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'cannot-slice-blob':
      case 'server-file-wrong-size':
        return StorageException(
          code: 'file-read-error',
          message: 'Local or remote file stream corrupted or size mismatch.',
          userMessage: 'Could not read the selected image file. Please reselect the image.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'bucket-not-found':
      case 'no-default-bucket':
        return StorageException(
          code: 'bucket-not-configured',
          message: 'Firebase Storage bucket configuration is missing or invalid.',
          userMessage: 'Cloud storage is currently unavailable.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );

      default:
        return StorageException(
          code: code.isEmpty ? 'storage-error' : code,
          message: error.message ?? 'Storage operation failed with code "$code".',
          userMessage: 'Unable to complete image operation. Please try again.',
          isRecoverable: false,
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }
}
