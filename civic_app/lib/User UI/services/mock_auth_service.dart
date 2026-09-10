import 'dart:async';
import '../../core/auth/auth_service.dart';
import '../../core/models/user_model.dart';

/// Test-isolated Mock Authentication Service for automated widget and unit tests.
///
/// NOTE: This class is NOT used in production runtime. Production strictly uses
/// [FirebaseAuthService].
class MockAuthService implements AuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal() {
    _seedDefaultAccounts();
  }

  UserModel? _currentUser;
  bool _isAuthenticated = false;

  final Map<String, _MockAccount> _mockAccounts = {};

  void _seedDefaultAccounts() {
    const defaultUser = UserModel(
      id: 'user_citizen_001',
      fullName: 'Rahul Sharma',
      email: 'citizen@civicfix.test',
      phone: '+91 98765 43210',
      civicPoints: 850,
      reportsSubmitted: 12,
      reportsResolved: 8,
      wardNumber: 'Ward 14 (Central Ward)',
      languageCode: 'en',
      badges: ['First Report', 'Civic Contributor', 'Community Helper'],
    );
    _mockAccounts['citizen@civicfix.test'] = const _MockAccount(
      password: 'CivicFix123',
      user: defaultUser,
    );
  }

  /// Resets mock auth state for testing suites.
  void resetForTesting() {
    _currentUser = null;
    _isAuthenticated = false;
    _mockAccounts.clear();
    _seedDefaultAccounts();
  }

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  String? get currentUid => _currentUser?.id;

  /// Synchronously set mock user for tests without simulated delays.
  void setMockUser(UserModel? user) {
    _currentUser = user;
    _isAuthenticated = user != null;
  }

  @override
  Future<bool> checkAuthState() async {
    return _isAuthenticated;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final account = _mockAccounts[normalizedEmail];

    if (account != null && account.password == password) {
      _currentUser = account.user;
      _isAuthenticated = true;
      return AuthResult.success(user: _currentUser);
    }

    if (_currentUser != null && _currentUser!.email.toLowerCase() == normalizedEmail) {
      _isAuthenticated = true;
      return AuthResult.success(user: _currentUser);
    }

    return const AuthResult.failure('Incorrect email or password.');
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String language,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_mockAccounts.containsKey(normalizedEmail)) {
      return const AuthResult.failure('An account with this email already exists.');
    }

    final newUser = UserModel(
      id: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: normalizedEmail,
      phone: phone?.trim() ?? '',
      civicPoints: 20,
      reportsSubmitted: 0,
      reportsResolved: 0,
      wardNumber: 'Ward 14 (Central Ward)',
      languageCode: language,
      badges: const ['New Citizen'],
    );

    _mockAccounts[normalizedEmail] = _MockAccount(
      password: password,
      user: newUser,
    );

    _currentUser = newUser;
    _isAuthenticated = true;

    return AuthResult.success(
      user: newUser,
      successMessage: 'Account created successfully.',
    );
  }

  @override
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return const AuthResult.failure('Please enter a valid email address.');
    }

    return const AuthResult.success(
      successMessage: 'Password reset instructions have been sent.',
    );
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
  }
}

class _MockAccount {
  final String password;
  final UserModel user;

  const _MockAccount({
    required this.password,
    required this.user,
  });
}
