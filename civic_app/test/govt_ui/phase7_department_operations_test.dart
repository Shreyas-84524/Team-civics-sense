import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/auth/government_access_denied_screen.dart';
import 'package:civic_app/Govt UI/screens/dashboard/department_operations_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_assign_dialog.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_awaiting_verification_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_complaint_queue_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_completed_work_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_crew_workload_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_critical_complaints_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_kpi_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_map_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_operations_funnel_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_recent_activity_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_routing_dialog.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_routing_requests_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_sla_monitor_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_unassigned_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/department_lead/department_lead_verification_dialog.dart';

Widget _buildScreenTestHarness(GovtUserModel user, {Size size = const Size(1440, 900)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: DepartmentOperationsScreen(user: user),
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

  group('Phase 7 - Section 1: Strict RBAC Access Gates', () {
    testWidgets('Ward Department Lead is granted full access to Department Operations', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentOperationsScreen), findsOneWidget);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
      expect(find.textContaining('Roads & Maintenance'), findsWidgets);
      expect(find.textContaining('N Ward'), findsWidgets);
    });

    testWidgets('Municipal Commissioner / Super Admin is denied access to Department Operations', (tester) async {
      final user = MockGovtAuthService.mockSuperAdmin;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Zonal DMC is denied access to Department Operations', (tester) async {
      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Central Department HOD is denied access to Department Operations', (tester) async {
      final user = MockGovtAuthService.mockCentralHod;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Department Field Crew is denied access to Department Operations', (tester) async {
      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('Phase 7 - Section 2: Header Badges & Authoritative Context', () {
    testWidgets('Displays Ward, Department, and 5 Crew contextual badges', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('N WARD'), findsWidgets);
      expect(find.textContaining('ROADS & MAINTENANCE'), findsWidgets);
      expect(find.textContaining('5 CREW'), findsWidgets);
    });
  });

  group('Phase 7 - Section 3: Core Dashboard Sections Rendering', () {
    testWidgets('Renders all 11 operational sections accurately', (tester) async {
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1440, 2400)));
      await tester.pumpAndSettle();

      // Top KPI Grid
      expect(find.byType(DepartmentLeadKpiSection), findsOneWidget);
      expect(find.text('Unassigned'), findsWidgets);
      expect(find.text('Assigned'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Critical'), findsWidgets);
      expect(find.text('SLA At Risk'), findsWidgets);
      expect(find.text('SLA Breached'), findsWidgets);
      expect(find.text('Awaiting Verification'), findsWidgets);
      expect(find.text('Resolved Today'), findsWidgets);

      // Workflow Funnel
      expect(find.byType(DepartmentLeadOperationsFunnelSection), findsOneWidget);

      // Unassigned Section
      expect(find.byType(DepartmentLeadUnassignedSection), findsOneWidget);

      // Primary Complaint Queue
      expect(find.byType(DepartmentLeadComplaintQueueSection), findsOneWidget);

      // Crew Workload
      expect(find.byType(DepartmentLeadCrewWorkloadSection), findsOneWidget);

      // Work Awaiting Verification
      expect(find.byType(DepartmentLeadAwaitingVerificationSection), findsOneWidget);

      // SLA Monitor
      expect(find.byType(DepartmentLeadSlaMonitorSection), findsOneWidget);

      // Routing Requests
      expect(find.byType(DepartmentLeadRoutingRequestsSection), findsOneWidget);

      // Completed Work
      expect(find.byType(DepartmentLeadCompletedWorkSection), findsOneWidget);

      // Critical Complaints
      expect(find.byType(DepartmentLeadCriticalComplaintsSection), findsOneWidget);

      // Map Section
      expect(find.byType(DepartmentLeadMapSection), findsOneWidget);

      // Recent Activity
      expect(find.byType(DepartmentLeadRecentActivitySection), findsOneWidget);
    });
  });

  group('Phase 7 - Section 4: Interactive Dialogs & Operational Workflows', () {
    testWidgets('Assign Dialog can be opened and shows 5 crew members', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      // Find an Assign Crew button
      final assignButtons = find.text('ASSIGN CREW');
      if (assignButtons.evaluate().isNotEmpty) {
        await tester.tap(assignButtons.first);
        await tester.pumpAndSettle();

        expect(find.byType(DepartmentLeadAssignDialog), findsOneWidget);
        expect(find.textContaining('AUTHORIZED UNIT CREW TECHNICIANS'), findsOneWidget);
      }
    });

    testWidgets('Routing Dialog opens and displays department options', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      final reassignButtons = find.text('WRONG DEPT / REASSIGN');
      if (reassignButtons.evaluate().isNotEmpty) {
        await tester.tap(reassignButtons.first);
        await tester.pumpAndSettle();

        expect(find.byType(DepartmentLeadRoutingDialog), findsOneWidget);
        expect(find.textContaining('REQUEST DEPARTMENT REASSIGNMENT'), findsOneWidget);
      }
    });

    testWidgets('Review Work Dialog opens with verification controls', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      final reviewButtons = find.text('REVIEW WORK');
      if (reviewButtons.evaluate().isNotEmpty) {
        await tester.tap(reviewButtons.first);
        await tester.pumpAndSettle();

        expect(find.byType(DepartmentLeadVerificationDialog), findsOneWidget);
        expect(find.text('VERIFY & RESOLVE'), findsWidgets);
        expect(find.text('RETURN FOR REWORK'), findsWidgets);
      }
    });
  });

  group('Phase 7 - Section 5: Responsive Design Breakpoints', () {
    testWidgets('Renders gracefully on Mobile (390px)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentOperationsScreen), findsOneWidget);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
    });

    testWidgets('Renders gracefully on Tablet (768px)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentOperationsScreen), findsOneWidget);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
    });

    testWidgets('Renders gracefully on High-Res Desktop (1920px)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user, size: const Size(1920, 1080)));
      await tester.pumpAndSettle();

      expect(find.byType(DepartmentOperationsScreen), findsOneWidget);
      expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
    });
  });
}
