import 'package:civic_app/User UI/screens/login_screen.dart';
import 'package:civic_app/User UI/screens/phone_verification_screen.dart';
import 'package:civic_app/User UI/screens/registration_screen.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/auth/mock_phone_verification_service.dart';
import 'package:civic_app/core/auth/phone_verification_service_locator.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/routing/app_router.dart';
import 'package:civic_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestableWidget(Widget child, {String initialRoute = '/'}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    onGenerateRoute: AppRouter.generateRoute,
    initialRoute: initialRoute,
    home: child,
  );
}

void main() {
  late MockAuthService mockAuth;
  late MockPhoneVerificationService mockPhoneService;

  setUp(() {
    AuthServiceLocator.useMockServices();
    mockAuth = MockAuthService();
    mockAuth.resetForTesting(authenticated: false);

    mockPhoneService = PhoneVerificationServiceLocator.useMockService(expectedOtp: '123456');
    mockPhoneService.reset();
  });

  group('PhoneVerificationScreen UI & Step Transition Tests', () {
    testWidgets('Renders phone input form and pre-populates initial phone', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(initialPhone: '9876543210'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Phone'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('Validates required and invalid mobile numbers on submit', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(),
      ));
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();

      expect(find.text('Please enter your mobile phone number.'), findsOneWidget);

      final phoneField = find.byType(TextFormField).first;
      await tester.enterText(phoneField, '5123456789'); // Invalid starting digit in India
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();

      expect(find.text('Indian mobile numbers must begin with 6, 7, 8, or 9.'), findsOneWidget);
    });

    testWidgets('Entering valid phone and tapping Send dispatches OTP and shows Step 2', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(initialPhone: '9876543210'),
      ));
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(mockPhoneService.otpSendCount, 1);
      expect(find.text('Verification Code'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets('Tapping Change button resets back to Step 1', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(initialPhone: '9876543210'),
      ));
      await tester.pumpAndSettle();

      // Go to step 2
      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Verification Code'), findsOneWidget);

      // Tap Change
      final changeBtn = find.text('Change');
      await tester.ensureVisible(changeBtn);
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });
  });

  group('OTP Verification & Completion Tests', () {
    testWidgets('Entering invalid OTP displays error banner', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(initialPhone: '9876543210'),
      ));
      await tester.pumpAndSettle();

      // Send OTP
      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Enter wrong OTP
      final otpField = find.byType(TextFormField).first;
      await tester.enterText(otpField, '999999');

      final verifyBtn = find.text('Verify & Continue');
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Incorrect verification code. Please check and try again.'), findsOneWidget);
    });

    testWidgets('Entering valid OTP marks profile verified and routes to Home', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Set unverified user in active mock session
      const unverifiedUser = UserModel(
        id: 'u_test_unverified',
        fullName: 'Sneha Rao',
        email: 'sneha@civicfix.test',
        phone: '9876512345',
        phoneVerified: false,
      );
      mockAuth.setMockUser(unverifiedUser);

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(initialPhone: '9876512345'),
      ));
      await tester.pumpAndSettle();

      // Send OTP
      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Enter valid OTP (123456)
      final otpField = find.byType(TextFormField).first;
      await tester.enterText(otpField, '123456');

      final verifyBtn = find.text('Verify & Continue');
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pump(); // Starts verification
      await tester.pump(const Duration(milliseconds: 700)); // Finish success banner & delay
      await tester.pumpAndSettle();

      expect(mockAuth.currentUser?.phoneVerified, isTrue);
      expect(mockAuth.currentUser?.phone, '+919876512345');
      // Successfully routed past verification
      expect(find.byType(PhoneVerificationScreen), findsNothing);
    });

    testWidgets('Resend OTP allows requesting new code after cooldown expires', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(initialPhone: '9876543210'),
      ));
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Resend code in'), findsOneWidget);

      // Advance periodic timer past 30 seconds
      mockPhoneService.clearCooldown();
      for (int i = 0; i < 31; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      final resendBtn = find.text('Resend Verification Code');
      expect(resendBtn, findsOneWidget);

      await tester.ensureVisible(resendBtn);
      await tester.tap(resendBtn);
      await tester.pumpAndSettle();

      expect(mockPhoneService.resendCount, 1);
      expect(find.text('A new verification code has been dispatched.'), findsOneWidget);
    });

    testWidgets('Attempting to verify already associated phone displays collision error banner', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Current user is a new unverified citizen
      const newUser = UserModel(
        id: 'u_second_citizen_999',
        fullName: 'Second Citizen',
        email: 'second@civicfix.test',
        phone: '9876543210',
        phoneVerified: false,
      );
      mockAuth.setMockUser(newUser);

      // +919876543210 is already owned by user_citizen_001 in MockAuthService default seed
      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(initialPhone: '9876543210'),
      ));
      await tester.pumpAndSettle();

      // Send OTP
      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Enter valid OTP (123456)
      final otpField = find.byType(TextFormField).first;
      await tester.enterText(otpField, '123456');

      final verifyBtn = find.text('Verify & Continue');
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Expect collision error banner
      expect(
        find.text('This phone number is already associated with another CivicFix account.'),
        findsOneWidget,
      );
      // User must not be verified and stays on PhoneVerificationScreen
      expect(mockAuth.currentUser?.phoneVerified, isFalse);
      expect(find.byType(PhoneVerificationScreen), findsOneWidget);
    });
  });

  group('Citizen Auth Flow Redirection Tests', () {
    testWidgets('Unverified citizen on login is redirected to PhoneVerificationScreen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Seed an unverified account in MockAuthService
      mockAuth.setMockUser(const UserModel(
        id: 'u_unverified',
        fullName: 'Vikram Singh',
        email: 'vikram@civicfix.test',
        phone: '9876543210',
        phoneVerified: false,
      ));

      await tester.pumpWidget(_buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'vikram@civicfix.test');
      await tester.enterText(fields.at(1), 'AnyPass123');

      final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      // Verifies navigation to PhoneVerificationScreen
      expect(find.byType(PhoneVerificationScreen), findsOneWidget);
      expect(find.text('Verify Your Phone'), findsOneWidget);
    });

    testWidgets('Unverified citizen registration is redirected to PhoneVerificationScreen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Configure mockAuth to produce unverified accounts on register
      mockAuth.defaultPhoneVerified = false;

      await tester.pumpWidget(_buildTestableWidget(const RegistrationScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Kavita Joshi');
      await tester.enterText(fields.at(1), 'kavita@civicfix.test');
      await tester.enterText(fields.at(2), '9876543210');
      await tester.enterText(fields.at(3), 'SecurePass123');
      await tester.enterText(fields.at(4), 'SecurePass123');

      final createBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800)); // Finish mock registration delay
      await tester.pump(const Duration(milliseconds: 900)); // Finish success delay
      await tester.pumpAndSettle();

      // Verifies navigation to PhoneVerificationScreen
      expect(find.byType(PhoneVerificationScreen), findsOneWidget);
      expect(find.text('Verify Your Phone'), findsOneWidget);
    });
  });
}
