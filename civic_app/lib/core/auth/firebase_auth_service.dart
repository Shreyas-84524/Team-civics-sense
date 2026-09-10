import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firestore/firebase_user_data_source.dart';
import '../models/user_model.dart';
import '../notifications/notification_service_locator.dart';
import '../repositories/hive_user_repository.dart';
import '../sync/realtime_subscription_manager.dart';
import 'auth_error_handler.dart';
import 'auth_service.dart';

/// Firebase-backed production implementation of Citizen Authentication [AuthService].
///
/// Integrates Firebase Authentication (Email/Password), Cloud Firestore profile persistence (`users/{uid}`),
/// and Hive local cache storage with offline resilience.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth? _auth;
  final FirebaseUserDataSource _userDataSource;
  final HiveUserRepository _userRepository;

  UserModel? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseUserDataSource? userDataSource,
    HiveUserRepository? userRepository,
  })  : _auth = auth,
        _userDataSource = userDataSource ?? FirebaseUserDataSource(),
        _userRepository = userRepository ?? HiveUserRepository() {
    _initAuthStateListener();
  }

  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  void _initAuthStateListener() {
    try {
      _authSubscription = _authInstance.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          _currentUser = null;
        } else if (_currentUser == null || _currentUser!.id != firebaseUser.uid) {
          await _restoreUserProfile(firebaseUser.uid);
        }
      });
    } catch (e) {
      debugPrint('[FirebaseAuthService] Notice: authStateListener skipped ($e)');
    }
  }

  @override
  bool get isAuthenticated {
    try {
      return _authInstance.currentUser != null && _currentUser != null;
    } catch (_) {
      return _currentUser != null;
    }
  }

  @override
  UserModel? get currentUser => _currentUser;

  /// Underlying Firebase Auth User UID if authenticated.
  @override
  String? get currentUid {
    try {
      return _authInstance.currentUser?.uid;
    } catch (_) {
      return _currentUser?.id;
    }
  }

  /// Stream of user profile changes for reactive state binding.
  Stream<UserModel?> get authStateChanges {
    try {
      return _authInstance.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        if (_currentUser != null && _currentUser!.id == firebaseUser.uid) {
          return _currentUser;
        }
        await _restoreUserProfile(firebaseUser.uid);
        return _currentUser;
      });
    } catch (_) {
      return Stream.value(_currentUser);
    }
  }

  @override
  Future<bool> checkAuthState() async {
    try {
      final firebaseUser = _authInstance.currentUser;
      if (firebaseUser == null) {
        _currentUser = null;
        return false;
      }

      await _restoreUserProfile(firebaseUser.uid);
      return _currentUser != null;
    } catch (e) {
      debugPrint('[FirebaseAuthService] checkAuthState error: $e');
      return false;
    }
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final credential = await _authInstance.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthResult.failure('Authentication failed. No user profile returned.');
      }

      // Fetch Firestore profile or initialize
      UserModel? profile = await _userDataSource.getUserById(firebaseUser.uid);

      if (profile == null) {
        // Build fallback profile if Firestore document does not exist yet
        profile = UserModel(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? 'Civic Citizen',
          email: firebaseUser.email ?? normalizedEmail,
          phone: firebaseUser.phoneNumber ?? '',
          role: 'citizen',
          civicPoints: 20,
          reportsSubmitted: 0,
          reportsResolved: 0,
          wardNumber: 'Ward 14 (Central)',
          languageCode: 'en',
        );

        try {
          await _userDataSource.createCitizenProfile(profile);
        } catch (e) {
          debugPrint('[FirebaseAuthService] Initial profile write notice: $e');
        }
      } else if (profile.role == 'government') {
        // Sign out to prevent role cross-access
        await _authInstance.signOut();
        return const AuthResult.failure(
          'This account is registered for Municipal Government Officers. Please sign in via the Government Portal.',
        );
      }

      // Store in Hive local cache for offline persistence
      await _userRepository.cacheUser(profile);
      _currentUser = profile;

      // Register device token for push notifications
      try {
        await NotificationServiceLocator.instance.registerDeviceToken(profile.id);
      } catch (e) {
        debugPrint('[FirebaseAuthService] Device token registration notice: $e');
      }

      return AuthResult.success(
        user: profile,
        successMessage: 'Welcome back, ${profile.fullName}!',
      );
    } catch (e) {
      debugPrint('[FirebaseAuthService] Login failed: $e');
      return AuthResult.failure(FirebaseAuthErrorHandler.getMessage(e));
    }
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String language,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 1. Create Firebase Auth account
      final credential = await _authInstance.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthResult.failure('Account creation failed. Please try again.');
      }

      // Update Firebase display name
      try {
        await firebaseUser.updateDisplayName(fullName.trim());
      } catch (_) {}

      // 2. Build Citizen UserModel (Strictly enforces role = 'citizen')
      final newUser = UserModel(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        phone: phone?.trim() ?? '',
        civicPoints: 20, // Welcome bonus matching rules
        reportsSubmitted: 0,
        reportsResolved: 0,
        wardNumber: 'Ward 14 (Central)',
        languageCode: language,
        role: 'citizen', // Enforced citizen role; client cannot self-grant govt role
        badges: const ['New Citizen'],
      );

      // 3. Persist to Firestore remote data source
      try {
        await _userDataSource.createCitizenProfile(newUser);
      } catch (e) {
        debugPrint('[FirebaseAuthService] Remote Firestore profile write error: $e');
      }

      // 4. Cache in Hive for offline access
      await _userRepository.cacheUser(newUser);
      _currentUser = newUser;

      // Register device token for push notifications
      try {
        await NotificationServiceLocator.instance.registerDeviceToken(newUser.id);
      } catch (e) {
        debugPrint('[FirebaseAuthService] Device token registration notice: $e');
      }

      return AuthResult.success(
        user: newUser,
        successMessage: 'Account created successfully.',
      );
    } catch (e) {
      debugPrint('[FirebaseAuthService] Registration failed: $e');
      return AuthResult.failure(FirebaseAuthErrorHandler.getMessage(e));
    }
  }

  @override
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
        return const AuthResult.failure('Please enter a valid email address.');
      }

      await _authInstance.sendPasswordResetEmail(email: normalizedEmail);

      return const AuthResult.success(
        successMessage: 'Password reset instructions have been sent to your email.',
      );
    } catch (e) {
      debugPrint('[FirebaseAuthService] Password reset failed: $e');
      return AuthResult.failure(FirebaseAuthErrorHandler.getMessage(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      final uid = currentUid;
      if (uid != null && uid.isNotEmpty) {
        try {
          await NotificationServiceLocator.instance.unregisterDeviceToken(uid);
        } catch (e) {
          debugPrint('[FirebaseAuthService] Device token unregister notice: $e');
        }
      }
      await RealtimeSubscriptionManager.instance.cancelAll();
      await _authInstance.signOut();
    } catch (e) {
      debugPrint('[FirebaseAuthService] SignOut warning: $e');
    } finally {
      _currentUser = null;
      try {
        await _userRepository.clearUserCache();
      } catch (_) {}
    }
  }

  Future<void> _restoreUserProfile(String uid) async {
    try {
      final remoteUser = await _userDataSource.getUserById(uid);
      if (remoteUser != null) {
        _currentUser = remoteUser;
        await _userRepository.cacheUser(remoteUser);
        try {
          await NotificationServiceLocator.instance.registerDeviceToken(uid);
        } catch (_) {}
        return;
      }
    } catch (e) {
      debugPrint('[FirebaseAuthService] Error fetching remote profile: $e');
    }

    // Fallback to Hive cache if ID matches authenticated UID
    try {
      final cachedUser = await _userRepository.getCurrentUser();
      if (cachedUser.id == uid) {
        _currentUser = cachedUser;
        try {
          await NotificationServiceLocator.instance.registerDeviceToken(uid);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Disposes internal listeners when tearing down service.
  void dispose() {
    _authSubscription?.cancel();
  }
}
