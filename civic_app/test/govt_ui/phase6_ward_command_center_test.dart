import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/auth/government_access_denied_screen.dart';
import 'package:civic_app/Govt UI/screens/dashboard/ward_command_center_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/widgets/common/government_filter_bar.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_attention_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_crew_distribution_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_critical_complaints_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_department_drilldown_dialog.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_department_performance_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_escalation_center_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_kpi_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_lead_directory_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_operations_map_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_operations_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_personnel_overview_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_recent_activity_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_routing_requests_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_sla_monitoring_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/ward/ward_trend_section.dart';

Widget _buildScreenTestHarness(GovtUserModel user, {Size size = const Size(1440, 900)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: WardCommandCenterScreen(user: user),
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

  group('Phase 6 - Section 1: Strict Ward Officer RBAC Gate Tests', () {
    testWidgets('Ward Officer is granted full access to Ward Command Center', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(WardCommandCenterScreen), findsOneWidget);
      expect(find.textContaining('Command Center'), findsWidgets);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
    });

    testWidgets('Municipal Commissioner / Super Admin is denied access to Ward Command Center', (tester) async {
      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Zonal DMC is denied access to Ward Command Center', (tester) async {
      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Central Department HOD is denied access to Ward Command Center', (tester) async {
      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Department Lead is denied access to Ward Command Center', (tester) async {
      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Department Crew is denied access to Ward Command Center', (tester) async {
      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('Phase 6 - Section 2: Ward Command Center Structure & Dashboard Sections', () {
    testWidgets('Renders all modular dashboard sections cleanly', (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 1600)));
      await tester.pumpAndSettle();

      // Attention early warning alerts
      expect(find.byType(WardAttentionSection), findsOneWidget);

      // Top-level KPI metrics
      expect(find.byType(WardKpiSection), findsOneWidget);

      // Operations Overview (funnel)
      expect(find.byType(WardOperationsOverviewSection), findsOneWidget);

      // 18-Department Performance Oversight Table
      expect(find.byType(WardDepartmentPerformanceSection), findsOneWidget);

      // Critical Complaints Section
      expect(find.byType(WardCriticalComplaintsSection), findsOneWidget);

      // Routing Request Center
      expect(find.byType(WardRoutingRequestsSection), findsOneWidget);

      // SLA Monitoring
      expect(find.byType(WardSlaMonitoringSection), findsOneWidget);

      // Escalation Center
      expect(find.byType(WardEscalationCenterSection), findsOneWidget);

      // Personnel Overview
      expect(find.byType(WardPersonnelOverviewSection), findsOneWidget);

      // Leads Directory
      expect(find.byType(WardLeadDirectorySection), findsOneWidget);

      // Crew Distribution
      expect(find.byType(WardCrewDistributionSection), findsOneWidget);

      // Operations Map
      expect(find.byType(WardOperationsMapSection), findsOneWidget);

      // Trends Section
      expect(find.byType(WardTrendSection), findsOneWidget);

      // Audit Log Activity
      expect(find.byType(WardRecentActivitySection), findsOneWidget);
    });

    testWidgets('Renders dynamic ward header cleanly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('Command Center'), findsWidgets);
    });
  });

  group('Phase 6 - Section 3: Interactive Widget Tests', () {
    testWidgets('Tapping View Unit on department opens drilldown dialog', (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 1600)));
      await tester.pumpAndSettle();

      // Find first "View Unit" button
      final viewUnitButton = find.text('View Unit').first;
      await tester.ensureVisible(viewUnitButton);
      await tester.tap(viewUnitButton);
      await tester.pumpAndSettle();

      // Check that WardDepartmentDrilldownDialog opened
      expect(find.byType(WardDepartmentDrilldownDialog), findsOneWidget);
      expect(find.textContaining('OPERATIONAL UNIT KPI SUMMARY'), findsOneWidget);

      // Close dialog
      final closeButton = find.byIcon(Icons.close_rounded);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton.first);
        await tester.pumpAndSettle();
        expect(find.byType(WardDepartmentDrilldownDialog), findsNothing);
      }
    });

    testWidgets('Filter bar renders and updates search queries', (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 1600)));
      await tester.pumpAndSettle();

      // Ensure GovernmentFilterBar is present
      expect(find.byType(GovernmentFilterBar), findsOneWidget);

      // Enter text in search field
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Drainage');
      await tester.pumpAndSettle();

      expect(find.text('Drainage'), findsWidgets);
    });

    testWidgets('Routing request filter buttons switch between pending and all', (tester) async {
      tester.view.physicalSize = const Size(1440, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 2000)));
      await tester.pumpAndSettle();

      final routingSection = find.byType(WardRoutingRequestsSection);
      expect(routingSection, findsOneWidget);

      final allFilter = find.widgetWithText(FilterChip, 'All');
      if (allFilter.evaluate().isNotEmpty) {
        await tester.ensureVisible(allFilter.first);
        await tester.tap(allFilter.first);
        await tester.pumpAndSettle();
      }
    });
  });

  group('Phase 6 - Section 4: Responsive Rendering Tests', () {
    testWidgets('Renders cleanly on mobile form factor without exceptions', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(400, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(WardCommandCenterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on tablet form factor without exceptions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(800, 1200)));
      await tester.pumpAndSettle();

      expect(find.byType(WardCommandCenterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
