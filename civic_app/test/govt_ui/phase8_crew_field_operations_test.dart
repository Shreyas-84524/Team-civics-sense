import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/theme/app_theme.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/auth/government_access_denied_screen.dart';
import 'package:civic_app/Govt UI/screens/dashboard/crew_field_operations_screen.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/Govt UI/services/government_department_lead_dashboard_service.dart';
import 'package:civic_app/Govt UI/services/government_crew_work_service.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/crew/crew_activity_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/crew/crew_awaiting_review_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/crew/crew_completed_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/crew/crew_field_header.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/crew/crew_job_queue_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/crew/crew_kpi_summary_section.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/sections/crew/crew_map_section.dart';

Widget _buildScreenTestHarness(
  GovtUserModel user, {
  Size size = const Size(390, 844),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: CrewFieldOperationsScreen(user: user),
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

  group('Phase 8 - Section 1: Strict RBAC Access Gates', () {
    testWidgets(
      'Department Crew is granted full access to Crew Field Operations',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final user = MockGovtAuthService.mockDepartmentCrew;
        await tester.pumpWidget(_buildScreenTestHarness(user));
        await tester.pumpAndSettle();

        expect(find.byType(CrewFieldOperationsScreen), findsOneWidget);
        expect(find.byType(GovernmentAccessDeniedScreen), findsNothing);
        expect(find.text('My Work'), findsOneWidget);
        expect(find.textContaining('N Ward'), findsWidgets);
      },
    );

    testWidgets('Zonal DMC is denied access to Crew Field Operations', (
      tester,
    ) async {
      final user = MockGovtAuthService.mockZonalDmc;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets(
      'Central Department HOD is denied access to Crew Field Operations',
      (tester) async {
        final user = MockGovtAuthService.mockCentralHod;
        await tester.pumpWidget(_buildScreenTestHarness(user));
        await tester.pumpAndSettle();

        expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
        expect(find.text('Access Restricted'), findsOneWidget);
      },
    );

    testWidgets('Ward Officer is denied access to Crew Field Operations', (
      tester,
    ) async {
      final user = MockGovtAuthService.mockWardOfficer;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Ward Department Lead is denied access from crew-only screen', (
      tester,
    ) async {
      final user = MockGovtAuthService.mockWardLead;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(GovernmentAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('Phase 8 - Section 2: Header Badges & Contextual Display', () {
    testWidgets('Displays clean header title and subtitle without redundant badges', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(CrewFieldHeader), findsOneWidget);
      expect(find.text('My Work'), findsWidgets);
    });
  });

  group('Phase 8 - Section 3: Modular Field Sections & Tab Navigation', () {
    testWidgets('Renders KPI summary grid and Job Queue on initial load', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      expect(find.byType(CrewKpiSummarySection), findsOneWidget);
      expect(find.byType(CrewJobQueueSection), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
    });

    testWidgets('Tapping Review tab switches to CrewAwaitingReviewSection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      // Tap 'Review' on bottom navigation
      final reviewTab = find.text('Review');
      expect(reviewTab, findsOneWidget);
      await tester.tap(reviewTab);
      await tester.pumpAndSettle();

      expect(find.byType(CrewAwaitingReviewSection), findsOneWidget);
    });

    testWidgets('Tapping Completed tab switches to CrewCompletedSection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      // Tap 'Completed' on bottom navigation
      final completedTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Completed'),
      );
      expect(completedTab, findsOneWidget);
      await tester.tap(completedTab);
      await tester.pumpAndSettle();

      expect(find.byType(CrewCompletedSection), findsOneWidget);
    });

    testWidgets('Tapping Map tab switches to CrewMapSection', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      // Tap 'Map' on bottom navigation
      final mapTab = find.text('Map');
      expect(mapTab, findsOneWidget);
      await tester.tap(mapTab);
      await tester.pumpAndSettle();

      expect(find.byType(CrewMapSection), findsOneWidget);
    });

    testWidgets('Tapping Activity tab switches to CrewActivitySection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final user = MockGovtAuthService.mockDepartmentCrew;
      await tester.pumpWidget(_buildScreenTestHarness(user));
      await tester.pumpAndSettle();

      // Tap 'Activity' on bottom navigation
      final activityTab = find.text('Activity');
      expect(activityTab, findsOneWidget);
      await tester.tap(activityTab);
      await tester.pumpAndSettle();

      expect(find.byType(CrewActivitySection), findsOneWidget);
    });
  });

  group('Phase 8 - Section 4: Responsive Viewport Adaptation', () {
    testWidgets(
      'Renders cleanly on compact mobile (390x844) without unhandled exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final user = MockGovtAuthService.mockDepartmentCrew;
        await tester.pumpWidget(
          _buildScreenTestHarness(user, size: const Size(390, 844)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CrewFieldOperationsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Renders cleanly on large mobile (430x932) without unhandled exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final user = MockGovtAuthService.mockDepartmentCrew;
        await tester.pumpWidget(
          _buildScreenTestHarness(user, size: const Size(430, 932)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CrewFieldOperationsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Renders cleanly on Desktop (1440x900) wrapped in GovernmentAppShell',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final user = MockGovtAuthService.mockDepartmentCrew;
        await tester.pumpWidget(
          _buildScreenTestHarness(user, size: const Size(1440, 900)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CrewFieldOperationsScreen), findsOneWidget);
        expect(find.byType(CrewKpiSummarySection), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Renders CrewJobQueueSection with 1 assigned job item', (
      tester,
    ) async {
      final job = CrewJobItem(
        complaint: ComplaintModel(
          id: 'cmp_test_01',
          ticketNumber: 'CF-2026-TEST-001',
          title: 'Overflowing garbage bin at Market Road',
          description: 'Large municipal bin overflowing with solid waste',
          category: CivicCategory.defaultCategories[3],
          priority: ComplaintPriority.emergency,
          status: ComplaintStatus.assigned,
          location: const CivicLocation(
            latitude: 19.0760,
            longitude: 72.8777,
            address: 'Market Road, Dadar',
            ward: 'N',
          ),
          citizenId: 'cit_01',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          assignedCrewMemberId: 'GOV-CRW-W14-RDS-01',
        ),
        slaState: SlaHealthState.healthy,
        remainingHours: 21.0,
        overdueHours: 0.0,
        elapsedHours: 3.0,
        assignedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

      var viewed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  CrewJobQueueSection(
                    jobs: [job],
                    activeTab: 'all',
                    searchQuery: '',
                    onTabChanged: (_) {},
                    onPriorityChanged: (_) {},
                    onStatusChanged: (_) {},
                    onSlaChanged: (_) {},
                    onSearchChanged: (_) {},
                    onResetFilters: () {},
                    onViewDetails: (_) => viewed = true,
                    onStartJob: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('CF-2026-TEST-001'), findsOneWidget);
      await tester.tap(find.text('View Job'));
      await tester.pump();
      expect(viewed, isTrue);
    });
  });
}
