import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../firebase/firestore/firebase_user_data_source.dart';
import '../models/user_model.dart';
import '../notifications/notification_service_locator.dart';
import '../repositories/hive_user_repository.dart';
import '../sync/realtime_subscription_manager.dart';
import 'auth_error_handler.dart';
import 'auth_service.dart';
import 'phone_normalizer.dart';

/// Firebase-backed production implementation of Citizen Authentication [AuthService].
///
/// Integrates Firebase Authentication (Email/Password & Google Sign-In), Cloud Firestore profile persistence (`users/{uid}`),
/// and Hive local cache storage with offline resilience.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth? _auth;
  final FirebaseUserDataSource _userDataSource;
  final HiveUserRepository _userRepository;
  final GoogleSignIn? _googleSignIn;
  final http.Client _httpClient;

  UserModel? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseUserDataSource? userDataSource,
    HiveUserRepository? userRepository,
    GoogleSignIn? googleSignIn,
    http.Client? httpClient,
  })  : _auth = auth,
        _userDataSource = userDataSource ?? FirebaseUserDataSource(),
        _userRepository = userRepository ?? HiveUserRepository(),
        _googleSignIn = googleSignIn,
        _httpClient = httpClient ?? http.Client() {
    _initAuthStateListener();
  }

  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignInInstance => _googleSignIn ?? GoogleSignIn(scopes: ['email']);

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
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return const AuthResult.failure('Please enter your email.');
    }
    if (password.isEmpty) {
      return const AuthResult.failure('Please enter your password.');
    }

    try {
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
      } else if (profile.role == 'government' || profile.role == 'admin') {
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
  Future<AuthResult> signInWithGoogle() async {
    try {
      // 1. Trigger Google Account selection
      final GoogleSignInAccount? googleUser = await _googleSignInInstance.signIn();
      if (googleUser == null) {
        // User dismissed or cancelled the Google Account picker
        return const AuthResult.cancelled();
      }

      // 2. Obtain OAuth authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Authenticate with Firebase Auth
      final UserCredential userCredential = await _authInstance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const AuthResult.failure('Google authentication failed. No user profile returned.');
      }

      // 4. Retrieve or create Firestore citizen profile
      UserModel? profile = await _userDataSource.getUserById(firebaseUser.uid);

      if (profile != null) {
        // Existing user profile: verify role isolation
        if (profile.role == 'government' || profile.role == 'admin') {
          await _authInstance.signOut();
          return const AuthResult.failure(
            'This account is registered for Municipal Government Officers. Please sign in via the Government Portal.',
          );
        }
      } else {
        // New Google user: Create citizen profile
        final displayName = (firebaseUser.displayName?.trim().isNotEmpty == true)
            ? firebaseUser.displayName!.trim()
            : (googleUser.displayName?.trim().isNotEmpty == true)
                ? googleUser.displayName!.trim()
                : 'Civic Citizen';
        final email = (firebaseUser.email?.trim().isNotEmpty == true)
            ? firebaseUser.email!.trim().toLowerCase()
            : googleUser.email.trim().toLowerCase();
        final avatar = firebaseUser.photoURL ?? googleUser.photoUrl;

        profile = UserModel(
          id: firebaseUser.uid,
          fullName: displayName,
          email: email,
          phone: firebaseUser.phoneNumber ?? '', // Phase 4 concern: do NOT invent phone number
          avatarUrl: avatar,
          civicPoints: 20, // Welcome points
          reportsSubmitted: 0,
          reportsResolved: 0,
          wardNumber: 'Ward 14 (Central)',
          languageCode: 'en',
          role: 'citizen', // STRICT SECURITY INVARIANT: Client cannot self-grant govt role
          badges: const ['New Citizen'],
        );

        try {
          await _userDataSource.createCitizenProfile(profile);
        } catch (e) {
          debugPrint('[FirebaseAuthService] Firestore Google citizen profile write notice: $e');
        }
      }

      // 5. Store in Hive local cache
      await _userRepository.cacheUser(profile);
      _currentUser = profile;

      // 6. Register device token for push notifications
      try {
        await NotificationServiceLocator.instance.registerDeviceToken(profile.id);
      } catch (e) {
        debugPrint('[FirebaseAuthService] Device token registration notice: $e');
      }

      return AuthResult.success(
        user: profile,
        successMessage: 'Welcome, ${profile.fullName}!',
      );
    } catch (e) {
      debugPrint('[FirebaseAuthService] Google Sign-In error: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'account-exists-with-different-credential') {
          return const AuthResult.failure(
            'An account already exists with this email using a different sign-in method. Please sign in with your email and password.',
          );
        }
        return AuthResult.failure(FirebaseAuthErrorHandler.getMessage(e));
      }
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
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      return const AuthResult.failure('Please enter your full name.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return const AuthResult.failure('Please enter your email.');
    }
    if (password.isEmpty) {
      return const AuthResult.failure('Please enter a password.');
    }
    if (password.length < 8) {
      return const AuthResult.failure('Password must be at least 8 characters.');
    }

    try {
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
        await firebaseUser.updateDisplayName(trimmedName);
      } catch (_) {}

      // 2. Build Citizen UserModel (Strictly enforces role = 'citizen')
      final newUser = UserModel(
        id: firebaseUser.uid,
        fullName: trimmedName,
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
  Future<AuthResult> markPhoneVerified({
    required String phoneNumber,
    String? accessToken,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const AuthResult.failure('No active user session found. Please sign in again.');
    }

    try {
      final normalizedPhone = PhoneNormalizer.toE164(phoneNumber);
      final now = DateTime.now();

      // 1. If active Firebase Auth user is present, invoke server-authoritative Cloud Function
      // to atomically enforce phone uniqueness in /phoneIndex and update /users/{uid}.
      final firebaseUser = _authInstance.currentUser;
      if (firebaseUser != null) {
        try {
          final idToken = await firebaseUser.getIdToken();
          final callableUri = Uri.parse(
            'https://us-central1-civicfix-38d53.cloudfunctions.net/verifyCitizenPhoneMsg91',
          );

          final response = await _httpClient.post(
            callableUri,
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null) 'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'data': {
                'phone': normalizedPhone,
                if (accessToken != null && accessToken.isNotEmpty) 'accessToken': accessToken,
              },
            }),
          );

          if (response.statusCode != 200) {
            try {
              final decoded = jsonDecode(response.body);
              final errorObj = decoded['error'];
              final status = errorObj?['status'];
              final message = errorObj?['message'] as String?;

              if (status == 'ALREADY_EXISTS' || (message != null && message.contains('already associated'))) {
                return const AuthResult.failure(
                  'This phone number is already associated with another CivicFix account.',
                );
              }
              if (message != null && message.isNotEmpty) {
                return AuthResult.failure(message);
              }
            } catch (_) {}
            return const AuthResult.failure('Failed to verify phone number. Please try again.');
          }

          // Check if response contains nested error
          final decoded = jsonDecode(response.body);
          if (decoded['error'] != null) {
            final msg = decoded['error']['message'] as String?;
            if (msg != null && msg.contains('already associated')) {
              return const AuthResult.failure(
                'This phone number is already associated with another CivicFix account.',
              );
            }
            return AuthResult.failure(msg ?? 'Failed to verify phone number.');
          }
        } catch (callErr) {
          debugPrint('[FirebaseAuthService] Cloud Function invocation notice: $callErr');
          if (callErr.toString().contains('already associated')) {
            return const AuthResult.failure(
              'This phone number is already associated with another CivicFix account.',
            );
          }
          // If offline or function error, fallback to data source update
        }
      }

      // 2. Fetch or update user profile and cache locally
      UserModel? updatedUser;
      try {
        updatedUser = await _userDataSource.getUserById(uid);
      } catch (_) {}

      if (updatedUser == null || updatedUser.phone != normalizedPhone || !updatedUser.phoneVerified) {
        updatedUser = await _userDataSource.updatePhoneVerification(
          userId: uid,
          phone: normalizedPhone,
          phoneVerified: true,
          phoneVerifiedAt: now,
        );
      }

      await _userRepository.cacheUser(updatedUser);
      _currentUser = updatedUser;

      return AuthResult.success(
        user: updatedUser,
        successMessage: 'Phone number verified successfully.',
      );
    } catch (e) {
      debugPrint('[FirebaseAuthService] markPhoneVerified error: $e');
      if (e.toString().contains('already associated')) {
        return const AuthResult.failure(
          'This phone number is already associated with another CivicFix account.',
        );
      }
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
      try {
        await _googleSignInInstance.signOut();
      } catch (_) {}
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
