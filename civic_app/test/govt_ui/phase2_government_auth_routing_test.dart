import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/routing/app_router.dart';
import 'package:civic_app/core/routing/app_routes.dart';
import 'package:civic_app/Govt UI/models/government_session.dart';
import 'package:civic_app/Govt UI/navigation/govt_navigation_config.dart';
import 'package:civic_app/Govt UI/screens/auth/government_access_denied_screen.dart';
import 'package:civic_app/Govt UI/screens/auth/government_auth_loading_screen.dart';
import 'package:civic_app/Govt UI/screens/auth/govt_login_screen.dart';
import 'package:civic_app/Govt UI/screens/landing/government_role_landing_screens.dart';
import 'package:civic_app/Govt UI/services/government_account_validator.dart';
import 'package:civic_app/Govt UI/services/government_jurisdiction_resolver.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_app_bar.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_profile_menu.dart';

Widget _buildRoutingTestHarness(String targetRoute) {
  return MaterialApp(
    onGenerateRoute: AppRouter.generateRoute,
    home: Builder(
      builder: (context) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, targetRoute),
            child: const Text('Navigate'),
          ),
        );
      },
    ),
  );
}

void main() {
  setUp(() {
    AuthServiceLocator.useMockServices();
    RepositoryLocator.useMockRepositories();
    MockGovtAuthService().resetForTesting(authenticated: true);
  });

  group('Phase 2 - Section 36: Authentication & Account Validation Tests', () {
    test('Successful government login with Government ID resolves account & updates auth state', () async {
      final auth = MockGovtAuthService();
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);

      final result = await auth.loginWithGovernmentId(
        governmentId: 'MUMHQ00001',
        password: 'CivicFix123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user, isNotNull);
      expect(result.user?.employeeId, 'MUMHQ00001');
      expect(result.user?.govtRole, GovernmentRole.governmentSuperAdmin);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentAuthState, GovtAuthState.authenticated);
    });

    test('Invalid credentials return human-readable failure and update auth state', () async {
      final auth = MockGovtAuthService();
      final result = await auth.loginWithGovernmentId(
        governmentId: 'bad_officer',
        password: 'WrongPassword',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Invalid Government ID or password'));
      expect(auth.currentAuthState, GovtAuthState.authenticationError);
    });

    test('Missing government user profile returns human-readable failure', () async {
      final auth = MockGovtAuthService();
      final result = await auth.loginWithGovernmentId(
        governmentId: 'missing_user_001',
        password: 'ValidPassword123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Government profile could not be found'));
    });

    test('Inactive government account is blocked by GovernmentAccountValidator', () async {
      final validation = GovernmentAccountValidator.validate(MockGovtAuthService.mockInactiveOfficer);
      expect(validation.isValid, isFalse);
      expect(validation.error, GovernmentValidationError.accountInactive);
      expect(validation.message, contains('account is currently inactive'));
    });

    test('Missing zone for Zonal DMC fails validation', () {
      final invalidDmc = MockGovtAuthService.mockZonalDmc.copyWith(zoneId: '');
      final validation = GovernmentAccountValidator.validate(invalidDmc);
      expect(validation.isValid, isFalse);
      expect(validation.error, GovernmentValidationError.missingZone);
      expect(validation.message, contains('Missing assigned Zone'));
    });

    test('Missing department for Central HOD fails validation', () {
      final validation = GovernmentAccountValidator.validate(MockGovtAuthService.mockMissingDepartmentHod);
      expect(validation.isValid, isFalse);
      expect(validation.error, GovernmentValidationError.missingDepartment);
      expect(validation.message, contains('Missing assigned Department'));
    });

    test('Missing ward for Ward Officer fails validation', () {
      final validation = GovernmentAccountValidator.validate(MockGovtAuthService.mockMissingWardOfficer);
      expect(validation.isValid, isFalse);
      expect(validation.error, GovernmentValidationError.missingWard);
      expect(validation.message, contains('Missing assigned Ward'));
    });

    test('Department Crew without supervisor fails validation', () {
      final validation = GovernmentAccountValidator.validate(MockGovtAuthService.mockMissingSupervisorCrew);
      expect(validation.isValid, isFalse);
      expect(validation.error, GovernmentValidationError.missingSupervisor);
      expect(validation.message, contains('Missing supervisor assignment'));
    });

    test('Citizen attempting government login is strictly rejected', () async {
      final auth = MockGovtAuthService();
      final result = await auth.loginWithGovernmentId(
        governmentId: 'citizen_user',
        password: 'Password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Access denied'));
    });

    test('Logout clears authenticated session and sensitive user reference', () async {
      final auth = MockGovtAuthService();
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.currentAuthState, GovtAuthState.unauthenticated);
    });
  });

  group('Phase 2 - Section 37: Role-Based Landing Route Resolution Tests', () {
    test('government_super_admin maps to /government/dashboard', () {
      final session = GovernmentSession.fromUser(MockGovtAuthService.mockSuperAdmin);
      expect(session.landingRoute, AppRoutes.governmentDashboard);
      expect(session.landingRoute, '/government/dashboard');
    });

    test('zonal_dmc maps to /government/zone', () {
      final session = GovernmentSession.fromUser(MockGovtAuthService.mockZonalDmc);
      expect(session.landingRoute, AppRoutes.governmentZone);
      expect(session.landingRoute, '/government/zone');
    });

    test('central_department_hod maps to /government/department', () {
      final session = GovernmentSession.fromUser(MockGovtAuthService.mockCentralHod);
      expect(session.landingRoute, AppRoutes.governmentDepartment);
      expect(session.landingRoute, '/government/department');
    });

    test('ward_officer maps to /government/ward', () {
      final session = GovernmentSession.fromUser(MockGovtAuthService.mockWardOfficer);
      expect(session.landingRoute, AppRoutes.governmentWard);
      expect(session.landingRoute, '/government/ward');
    });

    test('ward_department_lead maps to /government/department-operations', () {
      final session = GovernmentSession.fromUser(MockGovtAuthService.mockWardLead);
      expect(session.landingRoute, AppRoutes.governmentDepartmentOperations);
      expect(session.landingRoute, '/government/department-operations');
    });

    test('department_crew maps to /government/work', () {
      final session = GovernmentSession.fromUser(MockGovtAuthService.mockDepartmentCrew);
      expect(session.landingRoute, AppRoutes.governmentWork);
      expect(session.landingRoute, '/government/work');
    });
  });

  group('Phase 2 - Section 38: Route Guards & Negative Permission Tests', () {
    testWidgets('Unauthenticated user navigating directly to /government/dashboard is redirected to GovtLoginScreen', (tester) async {
      final auth = MockGovtAuthService();
      auth.resetForTesting(authenticated: false);

      await tester.pumpWidget(_buildRoutingTestHarness(AppRoutes.governmentDashboard));
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.byType(GovtLoginScreen), findsOneWidget);
      expect(find.text('CivicFix Government'), findsOneWidget);
    });

    testWidgets('Department Crew attempting to access Ward Dashboard receives Access Denied', (tester) async {
      final auth = MockGovtAuthService();
      auth.setCurrentUser(MockGovtAuthService.mockDepartmentCrew);

      await tester.pumpWidget(_buildRoutingTestHarness(AppRoutes.governmentWard));
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.textContaining('You do not have permission'), findsOneWidget);
    });

    testWidgets('Ward Department Lead attempting to access HOD Department route receives Access Denied', (tester) async {
      final auth = MockGovtAuthService();
      auth.setCurrentUser(MockGovtAuthService.mockWardLead);

      await tester.pumpWidget(_buildRoutingTestHarness(AppRoutes.governmentDepartment));
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Zonal DMC attempting to access Crew Work route receives Access Denied', (tester) async {
      final auth = MockGovtAuthService();
      auth.setCurrentUser(MockGovtAuthService.mockZonalDmc);

      await tester.pumpWidget(_buildRoutingTestHarness(AppRoutes.governmentWork));
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Super Admin has access to all government routes', (tester) async {
      final auth = MockGovtAuthService();
      auth.setCurrentUser(MockGovtAuthService.mockSuperAdmin);

      await tester.pumpWidget(_buildRoutingTestHarness(AppRoutes.governmentDashboard));
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.byType(CityCommandCenterLanding), findsOneWidget);
      expect(find.text('City Command Center'), findsWidgets);
    });

    testWidgets('GovernmentAccessDeniedScreen renders role context and Return to Dashboard button', (tester) async {
      final crewUser = MockGovtAuthService.mockDepartmentCrew;

      await tester.pumpWidget(MaterialApp(
        home: GovernmentAccessDeniedScreen(user: crewUser),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Return to Dashboard'), findsOneWidget);
      expect(find.text(crewUser.displayDesignation), findsOneWidget);
    });
  });

  group('Phase 2 - Section 39: Jurisdiction & Context Resolver Tests', () {
    test('Zonal DMC resolves Zone context', () {
      final summary = GovernmentJurisdictionResolver.resolveContextSummary(MockGovtAuthService.mockZonalDmc);
      expect(summary, 'Zone 4');
    });

    test('Central Department HOD resolves Department and Citywide context', () {
      final summary = GovernmentJurisdictionResolver.resolveContextSummary(MockGovtAuthService.mockCentralHod);
      expect(summary, contains('Solid Waste Management'));
      expect(summary, contains('Citywide'));
    });

    test('Ward Officer resolves Ward context', () {
      final summary = GovernmentJurisdictionResolver.resolveContextSummary(MockGovtAuthService.mockWardOfficer);
      expect(summary, contains('N Ward'));
    });

    test('Ward Department Lead resolves Ward and Department context', () {
      final summary = GovernmentJurisdictionResolver.resolveContextSummary(MockGovtAuthService.mockWardLead);
      expect(summary, contains('N Ward'));
      expect(summary, contains('Roads'));
    });

    test('Department Crew resolves Ward and Department context', () {
      final summary = GovernmentJurisdictionResolver.resolveContextSummary(MockGovtAuthService.mockDepartmentCrew);
      expect(summary, contains('N Ward'));
      expect(summary, contains('Roads'));
    });

    test('Super Admin resolves Mumbai Citywide context', () {
      final summary = GovernmentJurisdictionResolver.resolveContextSummary(MockGovtAuthService.mockSuperAdmin);
      expect(summary, 'Mumbai Citywide');
    });
  });

  group('Phase 2 - Section 19 & 20: Role-Aware Navigation Configuration Tests', () {
    test('Department Crew is blocked from executive and admin navigation items', () {
      final crew = MockGovtAuthService.mockDepartmentCrew;
      final visibleItems = GovtNavigationConfig.getItemsForUser(crew, useExtended: true);

      expect(visibleItems.any((i) => i.title == 'Audit Logs'), isFalse);
      expect(visibleItems.any((i) => i.title == 'Escalations'), isFalse);
      expect(visibleItems.any((i) => i.title == 'Analytics'), isFalse);
      expect(visibleItems.any((i) => i.title == 'Staff'), isFalse);
      expect(visibleItems.any((i) => i.title == 'Operations'), isTrue);
    });

    test('Ward Officer navigation includes escalations, staff, and audit logs', () {
      final wo = MockGovtAuthService.mockWardOfficer;
      final visibleItems = GovtNavigationConfig.getItemsForUser(wo, useExtended: true);

      expect(visibleItems.any((i) => i.title == 'Escalations'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Staff'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Audit Logs'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Analytics'), isTrue);
    });

    test('Central HOD navigation includes department oversight and analytics', () {
      final hod = MockGovtAuthService.mockCentralHod;
      final visibleItems = GovtNavigationConfig.getItemsForUser(hod, useExtended: true);

      expect(visibleItems.any((i) => i.title == 'Analytics'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Escalations'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Staff'), isTrue);
    });

    test('Super Admin navigation includes all apex sections', () {
      final sa = MockGovtAuthService.mockSuperAdmin;
      final visibleItems = GovtNavigationConfig.getItemsForUser(sa, useExtended: true);

      expect(visibleItems.any((i) => i.title == 'Dashboard'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Operations'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Analytics'), isTrue);
      expect(visibleItems.any((i) => i.title == 'Audit Logs'), isTrue);
    });
  });

  group('Phase 2 - Section 17 & 18: Profile Menu & App Bar Integration Tests', () {
    testWidgets('GovtProfileMenu renders real user information from session', (tester) async {
      final testOfficer = MockGovtAuthService.mockWardOfficer;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GovtProfileMenu(user: testOfficer, isCompact: false),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(testOfficer.fullName), findsOneWidget);
      expect(find.text(testOfficer.displayDesignation), findsOneWidget);
    });

    testWidgets('GovtAppBar renders cleanly for active officer session without overflowing', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final officer = MockGovtAuthService.mockZonalDmc;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GovtAppBar(
            title: 'Zonal Command Desk',
            user: officer,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Zonal Command Desk'), findsWidgets);
    });

    testWidgets('GovernmentAuthLoadingScreen renders municipal loading indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: GovernmentAuthLoadingScreen(),
        ),
      ));
      await tester.pump();

      expect(find.text('CivicFix Government Portal'), findsOneWidget);
      expect(find.text('Verifying government credentials...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
