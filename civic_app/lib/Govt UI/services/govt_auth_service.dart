import 'package:flutter/foundation.dart';
import '../models/govt_user_model.dart';

/// Distinct authentication lifecycle states for the Government Portal.
enum GovtAuthState {
  unauthenticated,
  authenticating,
  authenticated,
  authenticationError,
}

/// Result wrapper for government authentication actions.
class GovtAuthResult {
  final bool isSuccess;
  final GovtUserModel? user;
  final String? errorMessage;
  final String? successMessage;

  const GovtAuthResult.success([this.user, this.successMessage])
      : isSuccess = true,
        errorMessage = null;

  const GovtAuthResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null,
        successMessage = null;
}

/// Abstract contract for Government Authentication.
abstract class GovtAuthService {
  Future<GovtUserModel?> getCurrentUser();
  GovtUserModel? get currentUser;
  bool get isAuthenticated;
  GovtAuthState get currentAuthState;
  ValueListenable<GovtUserModel?> get userListenable;
  ValueListenable<GovtAuthState> get authStateListenable;

  Future<GovtAuthResult> loginWithGovernmentId({
    required String governmentId,
    required String password,
  });

  Future<GovtAuthResult> login({
    required String emailOrEmployeeId,
    required String password,
    String? departmentId,
    bool rememberMe = false,
  });

  Future<GovtAuthResult> requestPasswordReset({required String email});

  Future<void> logout();
  Future<bool> checkAuthState();
  void switchDepartment(String departmentId, String departmentName);
  void updateUser(GovtUserModel updatedUser);
}

/// Test-isolated mock implementation of Government Authentication.
///
/// NOTE: In production runtime, [FirebaseGovtAuthService] is strictly used.
class MockGovtAuthService implements GovtAuthService {
  static final MockGovtAuthService _instance = MockGovtAuthService._internal();
  factory MockGovtAuthService() => _instance;

  MockGovtAuthService._internal() {
    _userNotifier = ValueNotifier<GovtUserModel?>(_defaultOfficer);
    _authStateNotifier = ValueNotifier<GovtAuthState>(GovtAuthState.authenticated);
  }

  // Canonical Mock Government Officer for testing
  static const GovtUserModel _defaultOfficer = GovtUserModel(
    id: 'govt_off_001',
    fullName: 'Shreyas S. (Executive Officer)',
    email: 'officer@civicfix.gov.in',
    employeeId: 'MC-2026-ENG-842',
    phone: '+91 98765 43210',
    organization: 'Municipal Civic Administration',
    departmentId: 'dept_roads',
    departmentName: 'Roads & Infrastructure',
    designation: 'Senior Municipal Nodal Officer',
    assignedWard: 'Ward 14 (Central Zone)',
    permissions: [
      'view_complaints',
      'update_status',
      'assign_officer',
      'view_analytics',
      'view_hazard_map',
    ],
  );

  late final ValueNotifier<GovtUserModel?> _userNotifier;
  late final ValueNotifier<GovtAuthState> _authStateNotifier;

  @override
  ValueListenable<GovtUserModel?> get userListenable => _userNotifier;

  @override
  ValueListenable<GovtAuthState> get authStateListenable => _authStateNotifier;

  @override
  GovtUserModel? get currentUser => _userNotifier.value;

  @override
  bool get isAuthenticated => _userNotifier.value != null;

  @override
  GovtAuthState get currentAuthState => _authStateNotifier.value;

  @override
  Future<GovtUserModel?> getCurrentUser() async {
    return _userNotifier.value;
  }

  @override
  Future<bool> checkAuthState() async {
    return _userNotifier.value != null;
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
      return const GovtAuthResult.failure('Please enter your Government ID and password.');
    }

    final trimmedInput = rawInput.toLowerCase();

    if (password == 'WrongPassword' ||
        password == 'wrongpassword' ||
        trimmedInput.contains('invalid') ||
        trimmedInput.contains('bad_officer')) {
      _authStateNotifier.value = GovtAuthState.authenticationError;
      return const GovtAuthResult.failure(
        'Invalid Government ID or password. Please verify your municipal credentials.',
      );
    }

    final user = _defaultOfficer.copyWith(
      employeeId: rawInput.toUpperCase(),
      email: trimmedInput.contains('@') ? trimmedInput : '$trimmedInput@civicfix.gov.in',
      departmentId: departmentId ?? _defaultOfficer.departmentId,
    );

    _userNotifier.value = user;
    _authStateNotifier.value = GovtAuthState.authenticated;
    return GovtAuthResult.success(user);
  }

  @override
  Future<GovtAuthResult> requestPasswordReset({required String email}) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail.isEmpty) {
      return const GovtAuthResult.failure('Please enter your official government email address.');
    }

    // Basic email format check
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return const GovtAuthResult.failure('Please enter a valid government email address (e.g. officer@civicfix.gov.in).');
    }

    return GovtAuthResult.success(
      null,
      'A secure password reset link and authorization token have been sent to $trimmedEmail.',
    );
  }

  @override
  Future<void> logout() async {
    _authStateNotifier.value = GovtAuthState.authenticating;
    _userNotifier.value = null;
    _authStateNotifier.value = GovtAuthState.unauthenticated;
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

  void resetForTesting({bool authenticated = true}) {
    _userNotifier.value = authenticated ? _defaultOfficer : null;
    _authStateNotifier.value = authenticated ? GovtAuthState.authenticated : GovtAuthState.unauthenticated;
  }
}
