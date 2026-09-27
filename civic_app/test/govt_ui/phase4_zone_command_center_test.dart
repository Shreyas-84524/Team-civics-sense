import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/auth/government_access_denied_screen.dart';
import 'package:civic_app/Govt UI/screens/dashboard/zone_command_center_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_critical_complaints_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_cross_ward_issues_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_department_performance_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_department_ward_matrix_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_escalation_center_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_kpi_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_operations_map_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_operations_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_personnel_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_recent_activity_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_routing_requests_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_sla_monitoring_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_ward_drilldown_dialog.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_ward_officer_directory_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/zone/zone_ward_performance_section.dart';

Widget _buildScreenTestHarness(GovtUserModel user, {Size size = const Size(1440, 900)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: ZoneCommandCenterScreen(user: user),
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

  group('Phase 4 - Section 1: Strict Zonal DMC RBAC Gate Tests', () {
    testWidgets('Zonal DMC is granted full access to Zone Command Center', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(ZoneCommandCenterScreen), findsOneWidget);
      expect(find.textContaining('Command Center'), findsWidgets);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
    });

    testWidgets('Municipal Commissioner / Super Admin is denied access to Zone Command Center', (tester) async {
      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Central Department HOD is denied access to Zone Command Center', (tester) async {
      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Officer is denied access to Zone Command Center', (tester) async {
      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Department Lead is denied access to Zone Command Center', (tester) async {
      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Department Crew is denied access to Zone Command Center', (tester) async {
      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('Phase 4 - Section 2: Command Center Visual Sections Rendering Tests', () {
    testWidgets('Renders all modular dashboard sections for Zonal DMC on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1440, 4500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 4500)));
      await tester.pumpAndSettle();

      // Header & Zone Identification
      expect(find.textContaining('Command Center'), findsWidgets);
      expect(find.textContaining('ZONE'), findsWidgets);

      // Section 1: KPI Grid
      expect(find.byType(ZoneKpiSection), findsOneWidget);
      expect(find.text('Open Grievances'), findsWidgets);

      // Section 2: Operations Funnel Overview
      expect(find.byType(ZoneOperationsOverviewSection), findsOneWidget);

      // Section 3: Ward Health & Performance
      expect(find.byType(ZoneWardPerformanceSection), findsOneWidget);

      // Section 4: Department Performance Breakdown
      expect(find.byType(ZoneDepartmentPerformanceSection), findsOneWidget);

      // Section 5: 18 Depts x Zone Wards Matrix
      expect(find.byType(ZoneDepartmentWardMatrixSection), findsOneWidget);

      // Section 6: Critical Complaints
      expect(find.byType(ZoneCriticalComplaintsSection), findsOneWidget);

      // Section 7: SLA Monitoring
      expect(find.byType(ZoneSlaMonitoringSection), findsOneWidget);

      // Section 8: Routing Requests
      expect(find.byType(ZoneRoutingRequestsSection), findsOneWidget);

      // Section 9: Escalations
      expect(find.byType(ZoneEscalationCenterSection), findsOneWidget);

      // Section 10: Cross-Ward Issues
      expect(find.byType(ZoneCrossWardIssuesSection), findsOneWidget);

      // Section 11: Personnel Distribution
      expect(find.byType(ZonePersonnelOverviewSection), findsOneWidget);

      // Section 12: Ward Officer Directory
      expect(find.byType(ZoneWardOfficerDirectorySection), findsOneWidget);

      // Section 13: Operations Map
      expect(find.byType(ZoneOperationsMapSection), findsOneWidget);

      // Section 14: Audit Logs
      expect(find.byType(ZoneRecentActivitySection), findsOneWidget);
    });
  });

  group('Phase 4 - Section 3: Matrix Mode Switching Interactivity Tests', () {
    testWidgets('Toggles matrix mode between Volume, SLA %, and Critical', (tester) async {
      tester.view.physicalSize = const Size(1440, 4500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 4500)));
      await tester.pumpAndSettle();

      // Find SLA Compliance % button in Matrix section and tap it
      final slaButton = find.widgetWithText(ChoiceChip, 'SLA Compliance %').first;
      expect(slaButton, findsOneWidget);
      await tester.tap(slaButton);
      await tester.pumpAndSettle();

      // Find Critical Grievances button and tap it
      final critButton = find.widgetWithText(ChoiceChip, 'Critical Grievances').first;
      expect(critButton, findsOneWidget);
      await tester.tap(critButton);
      await tester.pumpAndSettle();

      // Switch back to Complaint Volume
      final volButton = find.widgetWithText(ChoiceChip, 'Complaint Volume').first;
      expect(volButton, findsOneWidget);
      await tester.tap(volButton);
      await tester.pumpAndSettle();
    });
  });

  group('Phase 4 - Section 4: Ward Drill-Down Dialog Interactivity Tests', () {
    testWidgets('Launches and dismisses Ward Drilldown Dialog upon selecting a ward', (tester) async {
      tester.view.physicalSize = const Size(2500, 4500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(2500, 4500)));
      await tester.pumpAndSettle();

      // Find 'Drill Down' button on a ward row
      final viewWardButton = find.widgetWithText(ElevatedButton, 'Drill Down').first;
      expect(viewWardButton, findsOneWidget);
      await tester.tap(viewWardButton);
      await tester.pumpAndSettle();

      // Verify Ward Drilldown dialog is mounted
      expect(find.byType(ZoneWardDrilldownDialog), findsOneWidget);
      expect(find.textContaining('Comprehensive Ward Administrative'), findsWidgets);

      // Dismiss dialog
      final closeButton = find.text('Close Overview');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify Dialog is dismissed
      expect(find.byType(ZoneWardDrilldownDialog), findsNothing);
    });
  });

  group('Phase 4 - Section 5: Responsive Layout Form Factor Tests', () {
    testWidgets('Renders gracefully on Mobile viewport (390 x 844)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(ZoneCommandCenterScreen), findsOneWidget);
      expect(find.byType(ZoneKpiSection), findsOneWidget);
    });

    testWidgets('Renders gracefully on Tablet viewport (768 x 1024)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      expect(find.byType(ZoneCommandCenterScreen), findsOneWidget);
      expect(find.byType(ZoneKpiSection), findsOneWidget);
    });

    testWidgets('Renders gracefully on Desktop viewport (1440 x 900)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(ZoneCommandCenterScreen), findsOneWidget);
      expect(find.byType(ZoneKpiSection), findsOneWidget);
    });
  });
}
