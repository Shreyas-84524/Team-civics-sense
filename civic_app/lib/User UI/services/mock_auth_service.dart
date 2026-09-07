import 'dart:async';
import '../../core/models/user_model.dart';

/// Result object for authentication actions.
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;
  final UserModel? user;

  const AuthResult.success({this.user, this.successMessage})
      : isSuccess = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        successMessage = null,
        user = null;
}

/// Abstract contract for authentication service.
abstract class AuthService {
  Future<bool> checkAuthState();
  Future<AuthResult> login({required String email, required String password});
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String language,
  });
  Future<AuthResult> sendPasswordResetEmail({required String email});
  Future<void> logout();
  UserModel? get currentUser;
  bool get isAuthenticated;
}

/// In-memory Mock Authentication Service for User UI development.
class MockAuthService implements AuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  UserModel? _currentUser;
  bool _isAuthenticated = false;

  // Development mock user database in memory
  final Map<String, _MockAccount> _mockAccounts = {
    'citizen@civicfix.test': _MockAccount(
      password: 'CivicFix123',
      user: const UserModel(
        id: 'user_citizen_001',
        fullName: 'Rahul Sharma',
        email: 'citizen@civicfix.test',
        phone: '+91 98765 43210',
        civicPoints: 480,
        reportsSubmitted: 8,
        reportsResolved: 6,
        wardNumber: 'Ward 14 (Central Ward)',
        languageCode: 'en',
      ),
    ),
  };

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  UserModel? get currentUser => _currentUser;

  /// Synchronously set mock user for tests without simulated delays.
  void setMockUser(UserModel? user) {
    _currentUser = user;
    _isAuthenticated = user != null;
  }

  @override
  Future<bool> checkAuthState() async {
    // Simulate brief asynchronous token check
    await Future.delayed(const Duration(milliseconds: 300));
    return _isAuthenticated;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();
    final account = _mockAccounts[normalizedEmail];

    if (account != null && account.password == password) {
      _currentUser = account.user;
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
    await Future.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim().toLowerCase();

    if (_mockAccounts.containsKey(normalizedEmail)) {
      return const AuthResult.failure('An account with this email already exists.');
    }

    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: normalizedEmail,
      phone: phone?.trim() ?? '',
      civicPoints: 20, // Welcome bonus
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
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();

    // User-friendly response regardless of whether email exists for privacy
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
