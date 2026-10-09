import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/auth/government_access_denied_screen.dart';
import 'package:civic_app/Govt UI/screens/dashboard/department_command_center_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_attention_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_crew_distribution_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_critical_complaints_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_escalation_center_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_kpi_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_lead_directory_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_operations_map_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_operations_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_personnel_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_recent_activity_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_routing_requests_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_sla_monitoring_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_trend_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_ward_performance_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_ward_unit_drilldown_dialog.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department/department_zone_breakdown_section.dart';

Widget _buildScreenTestHarness(GovtUserModel user, {Size size = const Size(1440, 900)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: DepartmentCommandCenterScreen(user: user),
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

  group('Phase 5 - Section 1: Strict Central Department HOD RBAC Gate Tests', () {
    testWidgets('Central Department HOD is granted full access to Department Command Center', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentCommandCenterScreen), findsOneWidget);
      expect(find.textContaining('Command Center'), findsWidgets);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
    });

    testWidgets('Municipal Commissioner / Super Admin is denied access to Department Command Center', (tester) async {
      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Zonal DMC is denied access to Department Command Center', (tester) async {
      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Officer is denied access to Department Command Center', (tester) async {
      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Department Lead is denied access to Department Command Center', (tester) async {
      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Department Crew is denied access to Department Command Center', (tester) async {
      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('Phase 5 - Section 2: Header Verification', () {
    testWidgets('Renders authoritative department name cleanly without badges', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.text('Solid Waste Management Command Center'), findsWidgets);
    });
  });

  group('Phase 5 - Section 3: Modular Dashboard Sections Rendering Verification', () {
    testWidgets('Renders all modular dashboard sections seamlessly on Desktop (1440px)', (tester) async {
      tester.view.physicalSize = const Size(1440, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 5000)));
      await tester.pumpAndSettle();

      // Verify presence of modular section widgets
      expect(find.byType(DepartmentKpiSection), findsOneWidget);
      expect(find.byType(DepartmentAttentionSection), findsOneWidget);
      expect(find.byType(DepartmentOperationsOverviewSection), findsOneWidget);
      expect(find.byType(DepartmentWardPerformanceSection), findsOneWidget);
      expect(find.byType(DepartmentZoneBreakdownSection), findsOneWidget);
      expect(find.byType(DepartmentCriticalComplaintsSection), findsOneWidget);
      expect(find.byType(DepartmentSlaMonitoringSection), findsOneWidget);
      expect(find.byType(DepartmentRoutingRequestsSection), findsOneWidget);
      expect(find.byType(DepartmentEscalationCenterSection), findsOneWidget);
      expect(find.byType(DepartmentPersonnelOverviewSection), findsOneWidget);
      expect(find.byType(DepartmentLeadDirectorySection), findsOneWidget);
      expect(find.byType(DepartmentCrewDistributionSection), findsOneWidget);
      expect(find.byType(DepartmentOperationsMapSection), findsOneWidget);
      expect(find.byType(DepartmentTrendSection), findsOneWidget);
      expect(find.byType(DepartmentRecentActivitySection), findsOneWidget);
    });
  });

  group('Phase 5 - Section 4: Ward Unit Drilldown Dialog Interaction', () {
    testWidgets('Opens and dismisses Ward Department Unit Drill-down Dialog', (tester) async {
      tester.view.physicalSize = const Size(2000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(2000, 4000)));
      await tester.pumpAndSettle();

      // Find "View Ward Unit" button on the first ward row
      final viewUnitButtons = find.widgetWithText(ElevatedButton, 'View Ward Unit');
      expect(viewUnitButtons, findsWidgets);

      await tester.ensureVisible(viewUnitButtons.first);
      await tester.tap(viewUnitButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentWardUnitDrilldownDialog), findsOneWidget);
      expect(find.textContaining('OPERATIONAL UNIT'), findsWidgets);

      // Dismiss dialog
      final closeButton = find.text('Close Overview');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(find.byType(DepartmentWardUnitDrilldownDialog), findsNothing);
    });
  });

  group('Phase 5 - Section 5: Responsive Viewport Adaptation Tests', () {
    testWidgets('Renders without unhandled exceptions on Mobile viewport (390x844)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentCommandCenterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without unhandled exceptions on Tablet viewport (768x1024)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentCommandCenterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without unhandled exceptions on Desktop viewport (1440x900)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentCommandCenterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
