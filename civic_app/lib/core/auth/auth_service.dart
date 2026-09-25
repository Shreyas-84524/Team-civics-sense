import 'dart:async';
import '../models/user_model.dart';

/// Standard result wrapper for Citizen Authentication operations.
class AuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;
  final String? successMessage;
  final UserModel? user;

  const AuthResult.success({this.user, this.successMessage})
      : isSuccess = true,
        isCancelled = false,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        isCancelled = false,
        successMessage = null,
        user = null;

  const AuthResult.cancelled()
      : isSuccess = false,
        isCancelled = true,
        errorMessage = null,
        successMessage = null,
        user = null;
}

/// Abstract contract for Citizen Authentication services.
abstract class AuthService {
  /// Checks active session with Firebase Auth and restores user profile.
  Future<bool> checkAuthState();

  /// Authenticates citizen using Firebase Auth email/password.
  Future<AuthResult> login({required String email, required String password});

  /// Authenticates citizen using Google OAuth credentials via Firebase Auth.
  Future<AuthResult> signInWithGoogle();

  /// Registers a new citizen account on Firebase Auth and creates Firestore profile.
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String language,
  });

  /// Triggers a password reset email via Firebase Auth.
  Future<AuthResult> sendPasswordResetEmail({required String email});

  /// Marks the citizen's phone number as verified in Firestore, local cache, and active session.
  Future<AuthResult> markPhoneVerified({
    required String phoneNumber,
    String? accessToken,
  });

  /// Safely signs out the citizen and cleans transient session state.
  Future<void> logout();

  /// Currently authenticated domain user profile.
  UserModel? get currentUser;

  /// Underlying Firebase Auth UID if authenticated.
  String? get currentUid;

  /// Whether a valid authenticated user session is active.
  bool get isAuthenticated;
}
