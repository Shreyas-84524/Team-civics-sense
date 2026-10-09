import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../Govt UI/models/govt_user_model.dart';
import '../../Govt UI/services/government_account_validator.dart';
import '../../Govt UI/services/govt_auth_service.dart';
import '../firebase/firestore/firebase_user_data_source.dart';
import '../notifications/notification_service_locator.dart';
import '../services/government_hierarchy_repository.dart';
import '../sync/realtime_subscription_manager.dart';
import 'auth_error_handler.dart';

/// Production Firebase-backed Government Authentication Service.
///
/// Enforces strict role verification for Municipal Government Officers and Administrators.
/// Authenticates against Firebase Authentication Email/Password on project `civicfix-38d53`.
/// Prevents unauthorized citizen accounts or unverified users from gaining access
/// to administrative dashboards and control desks.
class FirebaseGovtAuthService implements GovtAuthService {
  final FirebaseAuth? _auth;
  final FirebaseUserDataSource _userDataSource;
  final GovernmentHierarchyRepository _hierarchyRepository;

  final ValueNotifier<GovtUserModel?> _userNotifier;
  final ValueNotifier<GovtAuthState> _authStateNotifier;
  StreamSubscription<User?>? _authSubscription;

  FirebaseGovtAuthService({
    FirebaseAuth? auth,
    FirebaseUserDataSource? userDataSource,
    GovernmentHierarchyRepository? hierarchyRepository,
    GovtUserModel? initialUser,
    GovtAuthState initialAuthState = GovtAuthState.unauthenticated,
  })  : _auth = auth,
        _userDataSource = userDataSource ?? FirebaseUserDataSource(),
        _hierarchyRepository = hierarchyRepository ?? LocalGovernmentHierarchyRepository(),
        _userNotifier = ValueNotifier<GovtUserModel?>(initialUser),
        _authStateNotifier = ValueNotifier<GovtAuthState>(initialAuthState) {
    _initAuthStateListener();
  }

  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  void _initAuthStateListener() {
    try {
      _authSubscription = _authInstance.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          _userNotifier.value = null;
          _authStateNotifier.value = GovtAuthState.unauthenticated;
        }
      });
    } catch (e) {
      debugPrint('[FirebaseGovtAuthService] Notice: authStateListener skipped ($e)');
    }
  }

  @override
  ValueListenable<GovtUserModel?> get userListenable => _userNotifier;

  @override
  ValueListenable<GovtAuthState> get authStateListenable => _authStateNotifier;

  @override
  GovtUserModel? get currentUser => _userNotifier.value;

  @override
  bool get isAuthenticated {
    try {
      return _userNotifier.value != null && _authInstance.currentUser != null;
    } catch (_) {
      return _userNotifier.value != null;
    }
  }

  @override
  GovtAuthState get currentAuthState => _authStateNotifier.value;

  @override
  Future<GovtUserModel?> getCurrentUser() async {
    if (_userNotifier.value != null) {
      return _userNotifier.value;
    }
    await checkAuthState();
    return _userNotifier.value;
  }

  @override
  Future<bool> checkAuthState() async {
    try {
      User? firebaseUser = _authInstance.currentUser;
      if (firebaseUser == null) {
        try {
          firebaseUser = await _authInstance
              .authStateChanges()
              .firstWhere((user) => user != null)
              .timeout(const Duration(milliseconds: 1500));
        } catch (_) {
          try {
            firebaseUser = _authInstance.currentUser;
          } catch (_) {}
        }
      }

      if (firebaseUser == null) {
        _userNotifier.value = null;
        _authStateNotifier.value = GovtAuthState.unauthenticated;
        return false;
      }

      try {
        await firebaseUser.getIdToken();
      } catch (_) {}

      final isAuthorized = await _verifyAndRestoreOfficerProfile(firebaseUser);
      if (isAuthorized) {
        _authStateNotifier.value = GovtAuthState.authenticated;
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('[FirebaseGovtAuthService] checkAuthState error: $e');
      return _userNotifier.value != null;
    }
  }

  @override
  Future<GovtAuthResult> loginWithGovernmentId({
    required String governmentId,
    required String password,
  }) async {
    return login(
      emailOrEmployeeId: governmentId,
      password: password,
    );
  }

  @override
  Future<GovtAuthResult> login({
    required String emailOrEmployeeId,
    required String password,
    String? departmentId,
    bool rememberMe = false,
  }) async {
    _authStateNotifier.value = GovtAuthState.authenticating;

    final rawInput = emailOrEmployeeId.trim();
    if (rawInput.isEmpty || password.isEmpty) {
      _authStateNotifier.value = GovtAuthState.authenticationError;
      return const GovtAuthResult.failure('Please enter your government email and password.');
    }

    final trimmedInput = rawInput.toLowerCase();

    // Normalize email: append @civicfix.dev domain if only username or ID is provided
    String email = trimmedInput;
    if (!email.contains('@')) {
      email = '$trimmedInput@civicfix.dev';
    }

    try {
      // 1. Authenticate with Firebase Auth
      final credential = await _authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _authStateNotifier.value = GovtAuthState.authenticationError;
        return const GovtAuthResult.failure('Authentication failed. No user record found.');
      }

      // 2. Resolve CivicFix Government Profile by Firebase UID
      GovtUserModel? officer;
      try {
        officer = await _userDataSource.getGovtUserById(firebaseUser.uid);
      } catch (e) {
        debugPrint('[FirebaseGovtAuthService] Firestore profile lookup note: $e');
      }

      // Fallback to local hierarchy repository by UID or Email
      if (officer == null) {
        await _hierarchyRepository.initialize();
        officer = await _hierarchyRepository.getUserById(firebaseUser.uid) ??
            (firebaseUser.email != null
                ? await _hierarchyRepository.getUserByEmail(firebaseUser.email!)
                : null) ??
            await _hierarchyRepository.getUserByEmail(email);
      }

      // SECURITY INVARIANT: Fail-Closed. Reject non-government accounts or unconfigured UIDs
      if (officer == null) {
        await _authInstance.signOut();
        _userNotifier.value = null;
        _authStateNotifier.value = GovtAuthState.authenticationError;
        return const GovtAuthResult.failure(
          'Your account is authenticated but is not configured for CivicFix Government access.',
        );
      }

      // If user ID needs mapping to the active Firebase UID
      if (officer.id != firebaseUser.uid) {
        officer = officer.copyWith(id: firebaseUser.uid);
      }

      if (departmentId != null && departmentId.isNotEmpty) {
        officer = officer.copyWith(departmentId: departmentId);
      }

      // 3. Validate Account Integrity (active, canonical role, jurisdiction requirements)
      final validation = GovernmentAccountValidator.validate(officer);
      if (!validation.isValid) {
        await _authInstance.signOut();
        _userNotifier.value = null;
        _authStateNotifier.value = GovtAuthState.authenticationError;
        return GovtAuthResult.failure(
          validation.message ?? 'Government account validation failed.',
        );
      }

      _userNotifier.value = officer;
      _authStateNotifier.value = GovtAuthState.authenticated;

      // 4. Register device token for government push alerts
      try {
        await NotificationServiceLocator.instance.registerDeviceToken(officer.id);
      } catch (e) {
        debugPrint('[FirebaseGovtAuthService] Device token registration notice: $e');
      }

      return GovtAuthResult.success(
        officer,
        'Welcome, ${officer.fullName}. Municipal console active.',
      );
    } catch (e) {
      debugPrint('[FirebaseGovtAuthService] Login error: $e');
      _authStateNotifier.value = GovtAuthState.authenticationError;

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
          case 'invalid-email':
            return const GovtAuthResult.failure(
              'Invalid Government ID or password. Please verify your municipal credentials.',
            );
          case 'user-disabled':
            return const GovtAuthResult.failure(
              'This government officer account has been disabled. Please contact municipal administration.',
            );
          case 'too-many-requests':
            return const GovtAuthResult.failure(
              'Too many unsuccessful attempts. Access has been temporarily locked. Please try again later.',
            );
          case 'network-request-failed':
            return const GovtAuthResult.failure(
              'Network connection unavailable. Please check your internet connection and try again.',
            );
          default:
            return const GovtAuthResult.failure(
              'Authentication failed. Please verify your municipal credentials.',
            );
        }
      }
      return const GovtAuthResult.failure(
        'Authentication failed. Please verify your municipal credentials.',
      );
    }
  }

  @override
  Future<GovtAuthResult> requestPasswordReset({required String email}) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return const GovtAuthResult.failure('Please enter a valid government email address.');
    }

    try {
      await _authInstance.sendPasswordResetEmail(email: trimmedEmail);
      return GovtAuthResult.success(
        null,
        'A secure password reset link and authorization token have been sent to $trimmedEmail.',
      );
    } catch (e) {
      debugPrint('[FirebaseGovtAuthService] Password reset error: $e');
      return GovtAuthResult.failure(FirebaseAuthErrorHandler.getMessage(e));
    }
  }

  @override
  Future<void> logout() async {
    _authStateNotifier.value = GovtAuthState.authenticating;
    try {
      final uid = _userNotifier.value?.id ?? _authInstance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        try {
          await NotificationServiceLocator.instance.unregisterDeviceToken(uid);
        } catch (e) {
          debugPrint('[FirebaseGovtAuthService] Device token unregister notice: $e');
        }
      }
      await RealtimeSubscriptionManager.instance.cancelAll();
      await _authInstance.signOut();
    } catch (e) {
      debugPrint('[FirebaseGovtAuthService] Logout warning: $e');
    } finally {
      _userNotifier.value = null;
      _authStateNotifier.value = GovtAuthState.unauthenticated;
    }
  }

  @override
  void switchDepartment(String departmentId, String departmentName) {
    if (_userNotifier.value != null) {
      _userNotifier.value = _userNotifier.value!.copyWith(
        departmentId: departmentId,
        departmentName: departmentName,
      );
    }
  }

  @override
  void updateUser(GovtUserModel updatedUser) {
    _userNotifier.value = updatedUser;
  }

  Future<bool> _verifyAndRestoreOfficerProfile(User firebaseUser) async {
    GovtUserModel? officer;
    try {
      officer = await _userDataSource.getGovtUserById(firebaseUser.uid);
    } catch (_) {}

    if (officer == null) {
      await _hierarchyRepository.initialize();
      officer = await _hierarchyRepository.getUserById(firebaseUser.uid) ??
          (firebaseUser.email != null
              ? await _hierarchyRepository.getUserByEmail(firebaseUser.email!)
              : null);
    }

    if (officer == null) return false;

    if (officer.id != firebaseUser.uid) {
      officer = officer.copyWith(id: firebaseUser.uid);
    }

    final validation = GovernmentAccountValidator.validate(officer);
    if (!validation.isValid) return false;

    _userNotifier.value = officer;

    try {
      await NotificationServiceLocator.instance.registerDeviceToken(firebaseUser.uid);
    } catch (_) {}

    return true;
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
