import 'package:civic_app/core/auth/auth_error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseAuthErrorHandler Tests', () {
    test('maps credential and login failure codes', () {
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('user-not-found'),
        contains('Incorrect email or password'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('wrong-password'),
        contains('Incorrect email or password'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('invalid-credential'),
        contains('Incorrect email or password'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('INVALID_LOGIN_CREDENTIALS'),
        contains('Incorrect email or password'),
      );
    });

    test('maps account existence and collision codes', () {
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('email-already-in-use'),
        contains('already exists'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('account-exists-with-different-credential'),
        contains('already exists'),
      );
    });

    test('maps validation, weak password, and disabled accounts', () {
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('invalid-email'),
        contains('valid email address format'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('weak-password'),
        contains('password is too weak'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('user-disabled'),
        contains('account has been disabled'),
      );
    });

    test('maps rate limiting, network, and token lifecycle errors', () {
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('too-many-requests'),
        contains('Too many unsuccessful attempts'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('network-request-failed'),
        contains('Network connection unavailable'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('user-token-expired'),
        contains('session has expired'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('requires-recent-login'),
        contains('requires recent authentication'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('invalid-action-code'),
        contains('link is invalid or has already been used'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('expired-action-code'),
        contains('link has expired'),
      );
    });

    test('maps CivicFix specific role authorization codes', () {
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('government-access-denied'),
        contains('Access denied. This account does not possess authorized Municipal Government Officer credentials.'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('role-unauthorized'),
        contains('Access denied'),
      );
      expect(
        FirebaseAuthErrorHandler.getMessageForCode('citizen-access-denied'),
        contains('reserved for registered Citizen accounts'),
      );
    });

    test('handles unknown error code gracefully with fallback', () {
      final msg = FirebaseAuthErrorHandler.getMessageForCode('unknown-error-code');
      expect(msg, contains('Authentication failed (unknown-error-code)'));
    });

    test('getMessage parses FirebaseAuthException and standard exceptions', () {
      final authEx = FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password provided.',
      );
      expect(
        FirebaseAuthErrorHandler.getMessage(authEx),
        contains('Incorrect email or password'),
      );

      final standardEx = Exception('Custom authentication failed');
      expect(
        FirebaseAuthErrorHandler.getMessage(standardEx),
        equals('Custom authentication failed'),
      );

      expect(
        FirebaseAuthErrorHandler.getMessage(12345),
        contains('unexpected authentication error occurred'),
      );
    });
  });
}
