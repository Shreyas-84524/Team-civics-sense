import 'dart:async';
import '../../core/auth/auth_service.dart';
import '../../core/auth/phone_normalizer.dart';
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
    _currentUser = _mockAccounts['citizen@civicfix.test']?.user;
    _isAuthenticated = _currentUser != null;
  }

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool defaultPhoneVerified = true;

  final Map<String, _MockAccount> _mockAccounts = {};
  final Map<String, String> _phoneToUidIndex = {};

  /// Read-only snapshot of the phone-to-UID index for test assertions.
  Map<String, String> get phoneIndex => Map.unmodifiable(_phoneToUidIndex);

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
      phoneVerified: true,
    );
    _mockAccounts['citizen@civicfix.test'] = const _MockAccount(
      password: 'CivicFix123',
      user: defaultUser,
    );
    _phoneToUidIndex['+919876543210'] = 'user_citizen_001';
  }

  /// Resets mock auth state for testing suites.
  void resetForTesting({bool authenticated = true}) {
    defaultPhoneVerified = true;
    _mockAccounts.clear();
    _phoneToUidIndex.clear();
    _seedDefaultAccounts();
    if (authenticated) {
      _currentUser = _mockAccounts['citizen@civicfix.test']?.user;
      _isAuthenticated = _currentUser != null;
    } else {
      _currentUser = null;
      _isAuthenticated = false;
    }
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
  Future<AuthResult> signInWithGoogle() async {
    const googleUser = UserModel(
      id: 'user_google_001',
      fullName: 'Rahul Sharma',
      email: 'rahul.google@civicfix.test',
      phone: '',
      avatarUrl: 'https://lh3.googleusercontent.com/a/default-user',
      civicPoints: 20,
      reportsSubmitted: 0,
      reportsResolved: 0,
      wardNumber: 'Ward 14 (Central Ward)',
      languageCode: 'en',
      role: 'citizen',
      badges: ['New Citizen'],
      phoneVerified: true,
    );
    _currentUser = googleUser;
    _isAuthenticated = true;
    return const AuthResult.success(
      user: googleUser,
      successMessage: 'Signed in with Google successfully.',
    );
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
      phoneVerified: defaultPhoneVerified,
      phoneVerifiedAt: defaultPhoneVerified ? DateTime.now() : null,
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
  Future<AuthResult> markPhoneVerified({
    required String phoneNumber,
    String? accessToken,
  }) async {
    if (_currentUser == null) {
      return const AuthResult.failure('No active session.');
    }

    final String normalized;
    try {
      normalized = PhoneNormalizer.toE164(phoneNumber);
    } catch (_) {
      return const AuthResult.failure('Please enter a valid 10-digit Indian mobile number.');
    }

    // Check collision against simulated server-authoritative phone index
    final existingOwnerUid = _phoneToUidIndex[normalized];
    if (existingOwnerUid != null && existingOwnerUid != _currentUser!.id) {
      return const AuthResult.failure(
        'This phone number is already associated with another CivicFix account.',
      );
    }

    // If changing phone number from a previously verified phone, release old phone
    final oldPhone = _currentUser!.phone;
    if (oldPhone.isNotEmpty && _currentUser!.phoneVerified) {
      try {
        final oldE164 = PhoneNormalizer.toE164(oldPhone);
        if (oldE164 != normalized && _phoneToUidIndex[oldE164] == _currentUser!.id) {
          _phoneToUidIndex.remove(oldE164);
        }
      } catch (_) {}
    }

    _phoneToUidIndex[normalized] = _currentUser!.id;

    final updated = _currentUser!.copyWith(
      phone: normalized,
      phoneVerified: true,
      phoneVerifiedAt: DateTime.now(),
    );
    _currentUser = updated;
    return AuthResult.success(
      user: updated,
      successMessage: 'Phone verified successfully.',
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
