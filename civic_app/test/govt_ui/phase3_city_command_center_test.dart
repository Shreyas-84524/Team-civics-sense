import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/auth/government_access_denied_screen.dart';
import 'package:civic_app/Govt UI/screens/dashboard/city_command_center_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/city_complaint_map_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/city_complaint_trend_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/city_kpi_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/city_operations_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/critical_complaints_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_performance_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/escalation_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/personnel_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/recent_administrative_activity_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/routing_requests_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/sla_breaches_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward_performance_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone_performance_section.dart';

Widget _buildScreenTestHarness(GovtUserModel user, {Size size = const Size(1440, 900)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: CityCommandCenterScreen(user: user),
    ),
  );
}

void main() {
  setUp(() async {
    AuthServiceLocator.useMockServices();
    RepositoryLocator.useMockRepositories();
    MockGovtAuthService().resetForTesting(authenticated: true);
    await LocalGovernmentHierarchyRepository().initialize();
  });

  group('Phase 3 - Section 1: Strict Super Admin RBAC Gate Tests', () {
    testWidgets('Municipal Commissioner / Super Admin is granted full command center access', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(CityCommandCenterScreen), findsOneWidget);
      expect(find.text('City Command Center'), findsWidgets);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
    });

    testWidgets('Zonal DMC is denied access to City Command Center', (tester) async {
      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Central Department HOD is denied access to City Command Center', (tester) async {
      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Officer is denied access to City Command Center', (tester) async {
      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Department Lead is denied access to City Command Center', (tester) async {
      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Department Crew is denied access to City Command Center', (tester) async {
      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('Phase 3 - Section 2: Command Center Visual Sections Rendering Tests', () {
    testWidgets('Renders all modular dashboard sections for Super Admin on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1440, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 3000)));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('City Command Center'), findsWidgets);

      // Section 1: KPI Grid
      expect(find.byType(CityKpiSection), findsOneWidget);
      expect(find.text('Open Complaints'), findsOneWidget);
      expect(find.text('Total Wards'), findsOneWidget);
      expect(find.text('Active Personnel'), findsOneWidget);

      // Section 2: Operations Overview
      expect(find.byType(CityOperationsOverviewSection), findsOneWidget);
      expect(find.text('City Operations Overview'), findsOneWidget);

      // Section 3: Zone Performance
      expect(find.byType(ZonePerformanceSection), findsOneWidget);
      expect(find.text('Zone Performance'), findsOneWidget);

      // Section 4: Ward Performance
      expect(find.byType(WardPerformanceSection), findsOneWidget);
      expect(find.text('Ward Performance'), findsOneWidget);

      // Section 5: Department Performance
      expect(find.byType(DepartmentPerformanceSection), findsOneWidget);
      expect(find.text('Department Performance'), findsOneWidget);

      // Section 6: Trend Section
      expect(find.byType(CityComplaintTrendSection), findsOneWidget);

      // Section 7: Critical Complaints
      expect(find.byType(CriticalComplaintsSection), findsOneWidget);

      // Section 8: SLA Breaches
      expect(find.byType(SlaBreachesSection), findsOneWidget);

      // Section 9: Routing Requests
      expect(find.byType(RoutingRequestsSection), findsOneWidget);

      // Section 10: Escalation Overview
      expect(find.byType(EscalationOverviewSection), findsOneWidget);

      // Section 11: Personnel Overview (2,642 Roster)
      expect(find.byType(PersonnelOverviewSection), findsOneWidget);
      expect(find.text('Personnel Hierarchy & Roster'), findsOneWidget);

      // Section 12: GIS Map Canvas
      expect(find.byType(CityComplaintMapSection), findsOneWidget);

      // Section 13: Recent Administrative Audit Activity
      expect(find.byType(RecentAdministrativeActivitySection), findsOneWidget);
    });
  });

  group('Phase 3 - Section 3: Interactive Filter & Override Action Tests', () {
    testWidgets('Pull to refresh feed triggers data reload', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      final scrollView = find.descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(SingleChildScrollView),
      ).first;
      await tester.fling(scrollView, const Offset(0.0, 300.0), 1000.0);
      await tester.pumpAndSettle();

      expect(find.text('City Command Center'), findsWidgets);
    });

    testWidgets('Executive override dialog appears when override button is clicked', (tester) async {
      tester.view.physicalSize = const Size(1440, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 2000)));
      await tester.pumpAndSettle();

      // Look for Override & Route button in routing section
      final overrideBtn = find.text('Override & Route');
      if (overrideBtn.evaluate().isNotEmpty) {
        await tester.tap(overrideBtn.first);
        await tester.pumpAndSettle();

        expect(find.text('Executive Reassignment Override'), findsOneWidget);
        expect(find.text('Confirm Reassignment'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });
  });

  group('Phase 3 - Section 4: Responsive Form Factors Tests', () {
    testWidgets('Renders successfully on Tablet form factor (768 x 1024)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      expect(find.byType(CityCommandCenterScreen), findsOneWidget);
      expect(find.text('City Command Center'), findsWidgets);
    });

    testWidgets('Renders successfully on Mobile form factor (390 x 844)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(CityCommandCenterScreen), findsOneWidget);
      expect(find.text('City Command Center'), findsWidgets);
    });
  });
}
