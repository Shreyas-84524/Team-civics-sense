import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/auth/govt_login_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/User UI/screens/login_screen.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/routing/app_router.dart';
import 'package:civic_app/core/routing/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGovtAuthGatewayService implements GovtAuthService {
  GovtUserModel? _currentUser;
  GovtAuthState _authState = GovtAuthState.unauthenticated;
  final ValueNotifier<GovtUserModel?> _userNotifier = ValueNotifier<GovtUserModel?>(null);
  final ValueNotifier<GovtAuthState> _authStateNotifier =
      ValueNotifier<GovtAuthState>(GovtAuthState.unauthenticated);

  bool shouldSucceed = true;
  String? failureErrorMessage;

  @override
  GovtUserModel? get currentUser => _currentUser;

  @override
  GovtAuthState get currentAuthState => _authState;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  ValueListenable<GovtUserModel?> get userListenable => _userNotifier;

  @override
  ValueListenable<GovtAuthState> get authStateListenable => _authStateNotifier;

  @override
  Future<bool> checkAuthState() async => _currentUser != null;

  @override
  Future<GovtUserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<GovtAuthResult> login({
    required String emailOrEmployeeId,
    required String password,
    String? departmentId,
    bool rememberMe = false,
  }) async {
    if (!shouldSucceed) {
      _authState = GovtAuthState.authenticationError;
      _authStateNotifier.value = _authState;
      return GovtAuthResult.failure(
        failureErrorMessage ?? 'Invalid email or password.',
      );
    }

    _currentUser = const GovtUserModel(
      id: 'mock_firebase_uid_001',
      fullName: 'Dr. Bhushan Gagrani, IAS',
      email: 'commissioner@civicfix.dev',
      employeeId: 'GOV-SA-001',
      role: 'government_super_admin',
    );
    _authState = GovtAuthState.authenticated;
    _userNotifier.value = _currentUser;
    _authStateNotifier.value = _authState;

    return GovtAuthResult.success(
      _currentUser!,
      'Welcome, ${_currentUser!.fullName}. Municipal console active.',
    );
  }

  @override
  Future<GovtAuthResult> loginWithGovernmentId({
    required String governmentId,
    required String password,
  }) =>
      login(emailOrEmployeeId: governmentId, password: password);

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authState = GovtAuthState.unauthenticated;
    _userNotifier.value = null;
    _authStateNotifier.value = _authState;
  }

  @override
  Future<GovtAuthResult> requestPasswordReset({required String email}) async {
    return const GovtAuthResult.success(null, 'Reset email sent.');
  }

  @override
  void switchDepartment(String departmentId, String departmentName) {}

  @override
  void updateUser(GovtUserModel updatedUser) {
    _currentUser = updatedUser;
    _userNotifier.value = updatedUser;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3: Government Officer Login Gateway & Widget Tests', () {
    late MockGovtAuthGatewayService mockGovtAuth;

    setUp(() {
      mockGovtAuth = MockGovtAuthGatewayService();
      AuthServiceLocator.useMockServices();
    });

    testWidgets('Citizen Login Screen contains Government Officer Login switcher button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.generateRoute,
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final govtButton = find.byKey(const Key('govt_officer_login_button'));
      expect(govtButton, findsOneWidget);
      expect(find.text('Government Officer Login'), findsOneWidget);
    });

    testWidgets('Tapping Government Officer Login navigates to GovtLoginScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.login,
          routes: {
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.govtLogin: (context) => GovtLoginScreen(authService: mockGovtAuth),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap the government login button
      await tester.ensureVisible(find.byKey(const Key('govt_officer_login_button')));
      await tester.tap(find.byKey(const Key('govt_officer_login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(GovtLoginScreen), findsOneWidget);
      expect(find.text('CivicFix Government'), findsOneWidget);
    });

    testWidgets('GovtLoginScreen renders email, password masked, show/hide toggle, and no OTP elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GovtLoginScreen(authService: mockGovtAuth),
        ),
      );
      await tester.pumpAndSettle();

      // Form Elements Verification
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.byKey(const Key('back_to_citizen_login_button')), findsOneWidget);

      // STRICT ZERO OTP/SMS VERIFICATION: Government gateway must NOT render OTP or SMS
      expect(find.textContaining('OTP'), findsNothing);
      expect(find.textContaining('SMS'), findsNothing);
      expect(find.textContaining('Resend'), findsNothing);
      expect(find.textContaining('Phone Number'), findsNothing);

      // Password Obscurity & Visibility Toggle Verification
      final passwordFieldFinder = find.byType(TextFormField).last;
      expect(passwordFieldFinder, findsOneWidget);

      // Find visibility toggle icon
      final toggleButton = find.byTooltip('Show password');
      expect(toggleButton, findsOneWidget);

      // Toggle to visible
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('GovtLoginScreen validates empty input fields with error messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GovtLoginScreen(authService: mockGovtAuth),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Login with empty fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your government email.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('GovtLoginScreen handles failed authentication by showing error message', (tester) async {
      mockGovtAuth.shouldSucceed = false;
      mockGovtAuth.failureErrorMessage = 'Invalid Government ID or password. Please verify your municipal credentials.';

      await tester.pumpWidget(
        MaterialApp(
          home: GovtLoginScreen(authService: mockGovtAuth),
        ),
      );
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'invalid@civicfix.dev');
      await tester.enterText(find.byType(TextFormField).last, 'wrong_pass');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Government ID or password. Please verify your municipal credentials.'), findsOneWidget);
    });

    testWidgets('GovtLoginScreen handles successful login and navigates to destination dashboard', (tester) async {
      mockGovtAuth.shouldSucceed = true;

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.govtLogin,
          routes: {
            AppRoutes.govtLogin: (context) => GovtLoginScreen(authService: mockGovtAuth),
            AppRoutes.governmentDashboard: (context) => const Scaffold(
                  body: Text('Government Super Admin Dashboard Content'),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'commissioner@civicfix.dev');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Government Super Admin Dashboard Content'), findsOneWidget);
    });

    testWidgets('Back to Citizen Login button navigates back to citizen portal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.login,
          routes: {
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.govtLogin: (context) => GovtLoginScreen(authService: mockGovtAuth),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Go to govt login
      await tester.ensureVisible(find.byKey(const Key('govt_officer_login_button')));
      await tester.tap(find.byKey(const Key('govt_officer_login_button')));
      await tester.pumpAndSettle();
      expect(find.byType(GovtLoginScreen), findsOneWidget);

      // Tap back to citizen login
      await tester.ensureVisible(find.byKey(const Key('back_to_citizen_login_button')));
      await tester.tap(find.byKey(const Key('back_to_citizen_login_button')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
