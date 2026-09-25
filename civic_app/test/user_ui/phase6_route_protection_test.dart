import 'package:civic_app/Govt UI/screens/auth/govt_login_screen.dart';
import 'package:civic_app/Govt UI/screens/govt_shell_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/User UI/screens/login_screen.dart';
import 'package:civic_app/User UI/screens/main_navigation_screen.dart';
import 'package:civic_app/User UI/screens/phone_verification_screen.dart';
import 'package:civic_app/User UI/screens/profile_screen.dart';
import 'package:civic_app/User UI/screens/report_issue_screen.dart';
import 'package:civic_app/User UI/screens/splash_screen.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/User UI/services/mock_home_service.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/auth/mock_phone_verification_service.dart';
import 'package:civic_app/core/auth/phone_verification_service_locator.dart';
import 'package:civic_app/core/local/mock_data_source.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/routing/app_router.dart';
import 'package:civic_app/core/routing/app_routes.dart';
import 'package:civic_app/core/theme/app_theme.dart';
import 'package:civic_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthServiceLocator.useMockServices();
    MockAuthService().resetForTesting(authenticated: false);
    MockGovtAuthService().resetForTesting(authenticated: false);
    MockHomeService().resetMockData();
    MockDataSource().resetMockData();
    PhoneVerificationServiceLocator.useMockService(expectedOtp: '123456');
  });

  tearDown(() {
    PhoneVerificationServiceLocator.reset();
  });

  group('Phase 6: Splash Screen 4-State Restoration Routing Tests', () {
    testWidgets('1. No logged-in user routes from Splash to LoginScreen', (tester) async {
      MockAuthService().resetForTesting(authenticated: false);
      MockGovtAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.splash));

      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('2. Verified citizen routes from Splash to Citizen Home (MainNavigationScreen)', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'verified_citizen_1',
          fullName: 'Verified Citizen',
          email: 'verified@civicfix.test',
          phone: '+919876543210',
          phoneVerified: true,
        ),
      );
      MockGovtAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.splash));

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('3. Unverified citizen routes from Splash to PhoneVerificationScreen', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'unverified_citizen_1',
          fullName: 'Unverified Citizen',
          email: 'unverified@civicfix.test',
          phone: '9876543210',
          phoneVerified: false,
        ),
      );
      MockGovtAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.splash));

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(PhoneVerificationScreen), findsOneWidget);
    });

    testWidgets('4. Government officer routes from Splash to GovtShellScreen (Govt Console)', (tester) async {
      MockAuthService().resetForTesting(authenticated: false);
      MockGovtAuthService().resetForTesting(authenticated: true);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.splash));

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(GovtShellScreen), findsOneWidget);
    });
  });

  group('Phase 6: Citizen Route Protection (_protectedCitizenRoute) Tests', () {
    testWidgets('Unauthenticated user attempting to open /home is redirected to LoginScreen', (tester) async {
      MockAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
    });

    testWidgets('Unauthenticated user attempting to open /report-issue is redirected to LoginScreen', (tester) async {
      MockAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.reportIssue));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ReportIssueScreen), findsNothing);
    });

    testWidgets('Unverified citizen attempting to open /home is redirected to PhoneVerificationScreen', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'unverified_01',
          fullName: 'Unverified Citizen',
          email: 'unverified@civicfix.test',
          phone: '9123456789',
          phoneVerified: false,
        ),
      );

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle();

      expect(find.byType(PhoneVerificationScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
    });

    testWidgets('Unverified citizen attempting to open /profile is redirected to PhoneVerificationScreen', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'unverified_02',
          fullName: 'Unverified Citizen',
          email: 'unverified2@civicfix.test',
          phone: '9123456789',
          phoneVerified: false,
        ),
      );

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.profile));
      await tester.pumpAndSettle();

      expect(find.byType(PhoneVerificationScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('Verified citizen is allowed to access protected routes (/profile)', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'verified_01',
          fullName: 'Verified Citizen',
          email: 'verified@civicfix.test',
          phone: '+919123456789',
          phoneVerified: true,
        ),
      );

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.profile));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('Phase 6: Verify Phone Route Guard (_protectedVerifyPhoneRoute) Tests', () {
    testWidgets('Unauthenticated user accessing /verify-phone is redirected to LoginScreen', (tester) async {
      MockAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.verifyPhone));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Already verified citizen accessing /verify-phone is redirected to Citizen Home', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'verified_01',
          fullName: 'Verified Citizen',
          email: 'verified@civicfix.test',
          phone: '+919123456789',
          phoneVerified: true,
        ),
      );

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.verifyPhone));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });
  });

  group('Phase 6: Government Route Protection & Isolation Tests', () {
    testWidgets('Unauthenticated user accessing /govt/dashboard is redirected to GovtLoginScreen', (tester) async {
      MockGovtAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.govtDashboard));
      await tester.pumpAndSettle();

      expect(find.byType(GovtLoginScreen), findsOneWidget);
      expect(find.byType(GovtShellScreen), findsNothing);
    });

    testWidgets('Citizen logged in without Government session cannot access /govt/dashboard', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'verified_01',
          fullName: 'Verified Citizen',
          email: 'verified@civicfix.test',
          phone: '+919123456789',
          phoneVerified: true,
        ),
      );
      MockGovtAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.govtDashboard));
      await tester.pumpAndSettle();

      expect(find.byType(GovtLoginScreen), findsOneWidget);
      expect(find.byType(GovtShellScreen), findsNothing);
    });
  });

  group('Phase 6: PhoneVerificationScreen PopScope Back Button Guard Tests', () {
    testWidgets('Hardware back button on PhoneVerificationScreen signs out to LoginScreen instead of bypassing', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'unverified_back_test',
          fullName: 'Back Test User',
          email: 'back@civicfix.test',
          phone: '9876543210',
          phoneVerified: false,
        ),
      );

      await tester.pumpWidget(const CivicFixApp(initialRoute: AppRoutes.verifyPhone));
      await tester.pumpAndSettle();

      expect(find.byType(PhoneVerificationScreen), findsOneWidget);

      // Simulate Android system back button
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Should have signed out and navigated to LoginScreen
      expect(MockAuthService().isAuthenticated, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Hardware back button when OTP is sent returns to phone entry step', (tester) async {
      MockAuthService().setMockUser(
        const UserModel(
          id: 'unverified_otp_back',
          fullName: 'OTP Back User',
          email: 'otpback@civicfix.test',
          phone: '9876543210',
          phoneVerified: false,
        ),
      );
      final mockVerify = MockPhoneVerificationService(expectedOtp: '123456');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRouter.generateRoute,
          home: PhoneVerificationScreen(
            authService: MockAuthService(),
            verificationService: mockVerify,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send OTP to enter OTP step
      final sendBtn = find.text('Send Verification Code');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Verify & Continue'), findsOneWidget);

      // Simulate Android system back button
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Should be back on phone entry step, still on PhoneVerificationScreen
      expect(find.byType(PhoneVerificationScreen), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });
  });
}
