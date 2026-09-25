import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/core/auth/auth_service.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/auth/firebase_auth_service.dart';
import 'package:civic_app/core/auth/firebase_govt_auth_service.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class CustomTestAuthService implements AuthService {
  final UserModel? testUser;
  CustomTestAuthService({this.testUser});

  @override
  bool get isAuthenticated => testUser != null;

  @override
  UserModel? get currentUser => testUser;

  @override
  String? get currentUid => testUser?.id;

  @override
  Future<bool> checkAuthState() async => isAuthenticated;

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    return AuthResult.success(user: testUser);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return AuthResult.success(user: testUser);
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String language,
  }) async {
    return AuthResult.success(user: testUser);
  }

  @override
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> markPhoneVerified({required String phoneNumber, String? accessToken}) async {
    return AuthResult.success(user: testUser);
  }

  @override
  Future<void> logout() async {}
}

class CustomTestGovtAuthService implements GovtAuthService {
  final GovtUserModel? testGovtUser;
  final ValueNotifier<GovtUserModel?> _userNotifier;
  final ValueNotifier<GovtAuthState> _authStateNotifier;

  CustomTestGovtAuthService({this.testGovtUser})
      : _userNotifier = ValueNotifier<GovtUserModel?>(testGovtUser),
        _authStateNotifier = ValueNotifier<GovtAuthState>(
          testGovtUser != null ? GovtAuthState.authenticated : GovtAuthState.unauthenticated,
        );

  @override
  GovtUserModel? get currentUser => _userNotifier.value;

  @override
  bool get isAuthenticated => _userNotifier.value != null;

  @override
  GovtAuthState get currentAuthState => _authStateNotifier.value;

  @override
  ValueListenable<GovtUserModel?> get userListenable => _userNotifier;

  @override
  ValueListenable<GovtAuthState> get authStateListenable => _authStateNotifier;

  @override
  Future<GovtUserModel?> getCurrentUser() async => _userNotifier.value;

  @override
  Future<bool> checkAuthState() async => isAuthenticated;

  @override
  Future<GovtAuthResult> loginWithGovernmentId({
    required String governmentId,
    required String password,
  }) async {
    return GovtAuthResult.success(testGovtUser);
  }

  @override
  Future<GovtAuthResult> login({
    required String emailOrEmployeeId,
    required String password,
    String? departmentId,
    bool rememberMe = false,
  }) async {
    return GovtAuthResult.success(testGovtUser);
  }

  @override
  Future<GovtAuthResult> requestPasswordReset({required String email}) async {
    return const GovtAuthResult.success();
  }

  @override
  Future<void> logout() async {
    _userNotifier.value = null;
    _authStateNotifier.value = GovtAuthState.unauthenticated;
  }

  @override
  void switchDepartment(String departmentId, String departmentName) {}

  @override
  void updateUser(GovtUserModel updatedUser) {
    _userNotifier.value = updatedUser;
  }
}

void main() {
  setUp(() {
    AuthServiceLocator.reset();
  });

  tearDown(() {
    AuthServiceLocator.reset();
  });

  group('AuthServiceLocator Tests', () {
    test('provides default FirebaseAuthService and FirebaseGovtAuthService in production mode', () {
      final citizenAuth = AuthServiceLocator.citizenAuth;
      expect(citizenAuth, isA<FirebaseAuthService>());

      final govtAuth = AuthServiceLocator.govtAuth;
      expect(govtAuth, isA<FirebaseGovtAuthService>());
    });

    test('allows explicit override of citizen and government auth services', () {
      const customUser = UserModel(
        id: 'test_override_user',
        fullName: 'Custom Citizen',
        email: 'custom@civicfix.test',
        phone: '1234567890',
      );

      final customCitizen = CustomTestAuthService(testUser: customUser);
      AuthServiceLocator.citizenAuth = customCitizen;

      expect(AuthServiceLocator.citizenAuth.currentUser?.id, equals('test_override_user'));
      expect(AuthServiceLocator.citizenAuth.isAuthenticated, isTrue);

      const customGovtUser = GovtUserModel(
        id: 'govt_override_001',
        fullName: 'Custom Officer',
        email: 'officer@civicfix.gov.in',
        employeeId: 'OFF-001',
        departmentId: 'dept_roads',
        departmentName: 'Roads & Infrastructure',
        designation: 'Officer',
        assignedWard: 'Ward 1',
      );

      final customGovt = CustomTestGovtAuthService(testGovtUser: customGovtUser);
      AuthServiceLocator.govtAuth = customGovt;

      expect(AuthServiceLocator.govtAuth.currentUser?.id, equals('govt_override_001'));
      expect(AuthServiceLocator.govtAuth.isAuthenticated, isTrue);
    });

    test('useMockServices resets providers to in-memory mock implementations', () {
      AuthServiceLocator.citizenAuth = CustomTestAuthService();
      expect(AuthServiceLocator.citizenAuth, isA<CustomTestAuthService>());

      AuthServiceLocator.useMockServices();
      expect(AuthServiceLocator.citizenAuth, isA<MockAuthService>());
      expect(AuthServiceLocator.govtAuth, isA<MockGovtAuthService>());
    });

    test('reset clears cached instances to default production services', () {
      AuthServiceLocator.citizenAuth = CustomTestAuthService();
      AuthServiceLocator.reset();
      expect(AuthServiceLocator.citizenAuth, isA<FirebaseAuthService>());
      expect(AuthServiceLocator.govtAuth, isA<FirebaseGovtAuthService>());
    });
  });
}
