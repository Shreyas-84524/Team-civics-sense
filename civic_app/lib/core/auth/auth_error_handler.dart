import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

/// Centralized error handler that translates Firebase Authentication error codes
/// and platform-level Google Sign-In errors into user-friendly and actionable feedback messages.
class FirebaseAuthErrorHandler {
  FirebaseAuthErrorHandler._();

  /// Converts any exception into a user-friendly error string.
  static String getMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getMessageForCode(error.code);
    }
    if (error is PlatformException) {
      final message = error.message ?? '';
      final details = error.details?.toString() ?? '';
      final combined = '$message $details ${error.code}'.toLowerCase();

      if (combined.contains('12501') || combined.contains('canceled') || combined.contains('cancelled')) {
        return 'Google Sign-In was cancelled.';
      }
      if (combined.contains('api_exception: 10') || combined.contains('developer_error') || combined.contains('code: 10')) {
        return 'Google Sign-In configuration error: Please verify that the SHA-1 fingerprint and Google provider are enabled in Firebase Console.';
      }
      if (combined.contains('api_exception: 12500') || combined.contains('12500')) {
        return 'Google Sign-In failed (Code 12500). Please ensure Google Sign-In and a project support email are enabled in Firebase Console.';
      }
      if (combined.contains('api_exception: 7') || combined.contains('network_error') || combined.contains('network')) {
        return 'Google Sign-In network error: Unable to connect to Google Play Services. Please check your internet connection.';
      }
      if (error.code == 'sign_in_failed') {
        return 'Google Sign-In could not be completed. Please check your Google account on this device and try again.';
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    if (error is Exception) {
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    }
    return 'An unexpected authentication error occurred. Please try again.';
  }

  /// Maps specific Firebase Authentication error codes to clean user-facing messages.
  static String getMessageForCode(String code) {
    switch (code) {
      // Credential & Account Existence Errors
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password. Please verify your credentials.';

      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return 'An account with this email address already exists. Please login instead.';

      case 'invalid-email':
        return 'Please enter a valid email address format.';

      case 'weak-password':
        return 'The password is too weak. Please use at least 8 characters with letters and numbers.';

      case 'user-disabled':
        return 'This account has been disabled. Please contact municipal support.';

      // Throttling & Network Errors
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Access has been temporarily locked. Please try again later.';

      case 'network-request-failed':
        return 'Network connection unavailable. Please check your internet connection and try again.';

      // Operation & Token Errors
      case 'operation-not-allowed':
        return 'This authentication method is currently disabled. Please contact the administrator.';

      case 'requires-recent-login':
        return 'This sensitive operation requires recent authentication. Please sign in again.';

      case 'user-token-expired':
        return 'Your session has expired. Please log in again to continue.';

      case 'invalid-action-code':
        return 'The password reset link is invalid or has already been used.';

      case 'expired-action-code':
        return 'The password reset link has expired. Please request a new one.';

      // Custom CivicFix Authorization Errors
      case 'role-unauthorized':
      case 'government-access-denied':
        return 'Access denied. This account does not possess authorized Municipal Government Officer credentials.';

      case 'citizen-access-denied':
        return 'Access denied. This portal is reserved for registered Citizen accounts.';

      default:
        return 'Authentication failed ($code). Please try again or contact support.';
    }
  }
}
