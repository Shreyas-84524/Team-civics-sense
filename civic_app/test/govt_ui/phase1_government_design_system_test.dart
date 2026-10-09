import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_routing_ticket_model.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/core/theme/civicfix_design_tokens.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/navigation/govt_navigation_config.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/theme/govt_responsive.dart';
import 'package:civic_app/Govt UI/theme/govt_theme_tokens.dart';
import 'package:civic_app/Govt UI/theme/govt_typography.dart';
import 'package:civic_app/Govt UI/widgets/common/government_alert.dart';
import 'package:civic_app/Govt UI/widgets/common/government_app_shell.dart';
import 'package:civic_app/Govt UI/widgets/common/government_confirmation_dialog.dart';
import 'package:civic_app/Govt UI/widgets/common/government_data_table.dart';
import 'package:civic_app/Govt UI/widgets/common/government_error_state.dart';
import 'package:civic_app/Govt UI/widgets/common/government_filter_bar.dart';
import 'package:civic_app/Govt UI/widgets/common/government_kpi_card.dart';
import 'package:civic_app/Govt UI/widgets/common/government_page_header.dart';
import 'package:civic_app/Govt UI/widgets/common/government_section_header.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_breadcrumbs.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_card.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_empty_state.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_jurisdiction_badge.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_loading_states.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_notification_panel.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_priority_badge.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_role_visibility.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_search_field.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_sidebar.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_sla_badge.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_status_badge.dart';

Widget _buildTestApp(Widget child, {Size size = const Size(1280, 800)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Material(child: child),
    ),
  );
}

void main() {
  group('Phase 1: Government Theme Tokens & Typography Tests', () {
    test('Tokens contain authoritative municipal color palette specifications', () {
      expect(GovtThemeTokens.primaryDark, CivicFixColors.secondaryAuthority);
      expect(GovtThemeTokens.secondary, CivicFixColors.secondary);
      expect(GovtThemeTokens.accent, CivicFixColors.primaryAccent);
      expect(GovtThemeTokens.background, CivicFixColors.canvas);
      expect(GovtThemeTokens.surface, CivicFixColors.surfaceContainerLowest);
      expect(GovtThemeTokens.border, CivicFixColors.border);
      expect(GovtThemeTokens.critical, CivicFixColors.onErrorContainer);
      expect(GovtThemeTokens.sidebarWidth, 260.0);
      expect(GovtThemeTokens.sidebarCollapsedWidth, 72.0);
      expect(GovtThemeTokens.topBarHeight, 68.0);
    });

    test('GovtTypography specifies complete hierarchical scale', () {
      expect(GovtTypography.displayLarge.fontSize, 32);
      expect(GovtTypography.pageTitle.fontSize, 24);
      expect(GovtTypography.sectionTitle.fontSize, 18);
      expect(GovtTypography.cardTitle.fontSize, 16);
      expect(GovtTypography.bodyLarge.fontSize, 16);
      expect(GovtTypography.body.fontSize, 14);
      expect(GovtTypography.bodySmall.fontSize, 12);
      expect(GovtTypography.label.fontSize, 12);
      expect(GovtTypography.caption.fontSize, 11);
      expect(GovtTypography.metricLarge.fontSize, 28);
      expect(GovtTypography.metricSmall.fontSize, 20);
    });
  });

  group('Phase 1: Responsive Breakpoints & Utilities Tests', () {
    testWidgets('GovtResponsive correctly identifies mobile (< 640px)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (context) {
          expect(GovtResponsive.isMobile(context), isTrue);
          expect(GovtResponsive.isTablet(context), isFalse);
          expect(GovtResponsive.isDesktop(context), isFalse);
          expect(GovtResponsive.getDeviceType(context), GovtDeviceType.mobile);
          return const SizedBox.shrink();
        }),
        size: const Size(390, 844),
      ));
    });

    testWidgets('GovtResponsive correctly identifies tablet (640px - 959px)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (context) {
          expect(GovtResponsive.isMobile(context), isFalse);
          expect(GovtResponsive.isTablet(context), isTrue);
          expect(GovtResponsive.isDesktop(context), isFalse);
          expect(GovtResponsive.getDeviceType(context), GovtDeviceType.tablet);
          return const SizedBox.shrink();
        }),
        size: const Size(768, 1024),
      ));
    });

    testWidgets('GovtResponsive correctly identifies desktop (960px - 1439px)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (context) {
          expect(GovtResponsive.isMobile(context), isFalse);
          expect(GovtResponsive.isTablet(context), isFalse);
          expect(GovtResponsive.isDesktop(context), isTrue);
          expect(GovtResponsive.getDeviceType(context), GovtDeviceType.desktop);
          return const SizedBox.shrink();
        }),
        size: const Size(1280, 800),
      ));
    });

    testWidgets('GovtResponsive correctly identifies largeDesktop (>= 1440px)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (context) {
          expect(GovtResponsive.isLargeDesktop(context), isTrue);
          expect(GovtResponsive.isDesktopOrLarger(context), isTrue);
          expect(GovtResponsive.getDeviceType(context), GovtDeviceType.largeDesktop);
          return const SizedBox.shrink();
        }),
        size: const Size(1920, 1080),
      ));
    });

    testWidgets('GovtResponsive.value selects correct responsive value', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (context) {
          final val = GovtResponsive.value<int>(
            context,
            mobile: 1,
            tablet: 2,
            desktop: 3,
            largeDesktop: 4,
          );
          expect(val, 3);
          return const SizedBox.shrink();
        }),
        size: const Size(1024, 768),
      ));
    });
  });

  group('Phase 1: Navigation Model & Role Filtering Tests', () {
    test('GovtNavItem isVisibleFor evaluates role and permission rules', () {
      const superAdminOnly = GovtNavItem(
        title: 'Audit Logs',
        icon: Icons.receipt_long,
        routeName: '/government/audit',
        allowedRoles: [GovernmentRole.governmentSuperAdmin],
      );

      expect(
        superAdminOnly.isVisibleFor(role: GovernmentRole.governmentSuperAdmin),
        isTrue,
      );
      expect(
        superAdminOnly.isVisibleFor(role: GovernmentRole.wardDepartmentLead),
        isFalse,
      );

      const permissionProtected = GovtNavItem(
        title: 'Analytics',
        icon: Icons.bar_chart,
        routeName: '/government/analytics',
        requiredPermission: 'view_analytics',
      );

      expect(
        permissionProtected.isVisibleFor(permissions: ['view_analytics', 'view_complaints']),
        isTrue,
      );
      expect(
        permissionProtected.isVisibleFor(permissions: ['view_complaints']),
        isFalse,
      );
      expect(
        permissionProtected.isVisibleFor(permissions: ['all']),
        isTrue,
      );
    });

    test('GovtNavigationConfig filters items for each government role', () {
      const superAdmin = GovtUserModel(
        id: 'user_1',
        fullName: 'Super Admin',
        email: 'admin@civicfix.gov.in',
        employeeId: 'ADM-01',
        role: GovernmentRole.superAdminId,
        permissions: ['all'],
      );

      const crewUser = GovtUserModel(
        id: 'user_2',
        fullName: 'Ground Crew',
        email: 'crew@civicfix.gov.in',
        employeeId: 'CRW-01',
        role: GovernmentRole.departmentCrewId,
        permissions: ['view_complaints'],
      );

      final adminItems = GovtNavigationConfig.getItemsForUser(superAdmin, useExtended: true);
      final crewItems = GovtNavigationConfig.getItemsForUser(crewUser, useExtended: true);

      expect(adminItems.any((i) => i.title == 'Audit Logs'), isTrue);
      expect(crewItems.any((i) => i.title == 'Audit Logs'), isFalse);
      expect(crewItems.any((i) => i.title == 'Operations'), isTrue);
    });
  });

  group('Phase 1: Status & Context Badges Widget Tests', () {
    testWidgets('GovtStatusBadge renders complaint statuses correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Column(
          children: [
            GovtStatusBadge.complaint(ComplaintStatus.reported),
            GovtStatusBadge.complaint(ComplaintStatus.verified),
            GovtStatusBadge.complaint(ComplaintStatus.assigned),
            GovtStatusBadge.complaint(ComplaintStatus.inProgress),
            GovtStatusBadge.fromComplaintStatusString('awaiting_verification'),
            GovtStatusBadge.complaint(ComplaintStatus.resolved),
            GovtStatusBadge.complaint(ComplaintStatus.rejected),
          ],
        ),
      ));

      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.textContaining('In Progress'), findsOneWidget);
      expect(find.text('Awaiting Verification'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('GovtStatusBadge renders routing and ticket statuses correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Column(
          children: [
            GovtStatusBadge.routing(ComplaintRoutingStatus.reassignmentRequested),
            GovtStatusBadge.ticket(RoutingTicketStatus.pending),
            GovtStatusBadge.ticket(RoutingTicketStatus.approved),
            GovtStatusBadge.ticket(RoutingTicketStatus.rejected),
            GovtStatusBadge.ticket(RoutingTicketStatus.cancelled),
          ],
        ),
      ));

      expect(find.text('Reassignment Requested'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('GovtPriorityBadge renders all 4 priority tiers', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Column(
          children: [
            GovtPriorityBadge.fromPriority(ComplaintPriority.low),
            GovtPriorityBadge.fromPriority(ComplaintPriority.medium),
            GovtPriorityBadge.fromPriority(ComplaintPriority.high),
            GovtPriorityBadge.fromPriority(ComplaintPriority.emergency),
          ],
        ),
      ));

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('GovtSlaBadge renders healthy, warning, and breached states', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Column(
          children: [
            GovtSlaBadge.healthy(remainingText: '36h remaining'),
            GovtSlaBadge.warning(remainingText: '< 3h remaining'),
            GovtSlaBadge.breached(overdueText: 'Breached (+6h)'),
          ],
        ),
      ));

      expect(find.text('36h remaining'), findsOneWidget);
      expect(find.text('< 3h remaining'), findsOneWidget);
      expect(find.text('Breached (+6h)'), findsOneWidget);
    });

    testWidgets('GovtJurisdictionBadge renders Zone, Ward, Department, and Role badges', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Column(
          children: [
            GovtJurisdictionBadge.zone('Zone 4'),
            GovtJurisdictionBadge.ward('N Ward'),
            GovtJurisdictionBadge.department('Maintenance'),
            GovtJurisdictionBadge.role('Ward Officer'),
          ],
        ),
      ));

      expect(find.text('[ZONE 4]'), findsOneWidget);
      expect(find.text('[N WARD]'), findsOneWidget);
      expect(find.text('[MAINTENANCE]'), findsOneWidget);
      expect(find.text('[WARD OFFICER]'), findsOneWidget);
    });
  });

  group('Phase 1: GovernmentKpiCard Widget Tests', () {
    testWidgets('GovernmentKpiCard renders metric, title, icon, and positive trend', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const GovernmentKpiCard(
          title: 'Open Complaints',
          metric: '487',
          icon: Icons.assignment_outlined,
          percentageChange: 12.4,
          percentageLabel: 'vs last week',
        ),
      ));

      expect(find.text('Open Complaints'), findsOneWidget);
      expect(find.text('487'), findsOneWidget);
      expect(find.text('+12.4%'), findsOneWidget);
      expect(find.text('vs last week'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('GovernmentKpiCard renders skeleton loading state', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const GovernmentKpiCard(
          title: 'Open Complaints',
          metric: '487',
          icon: Icons.assignment_outlined,
          isLoading: true,
        ),
      ));

      expect(find.byType(GovtKpiSkeleton), findsOneWidget);
      expect(find.text('487'), findsNothing);
    });

    testWidgets('GovernmentKpiCard renders error state and triggers retry', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_buildTestApp(
        GovernmentKpiCard(
          title: 'Open Complaints',
          metric: '487',
          icon: Icons.assignment_outlined,
          errorMessage: 'Failed to fetch',
          onRetry: () => retried = true,
        ),
      ));

      expect(find.text('Failed to fetch'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('Phase 1: Empty, Error, and Loading States Widget Tests', () {
    testWidgets('GovtEmptyState renders title, explanation, and action button', (tester) async {
      bool actionTapped = false;
      await tester.pumpWidget(_buildTestApp(
        GovtEmptyState.noComplaints(
          actionLabel: 'Reset Filters',
          onAction: () => actionTapped = true,
        ),
      ));

      expect(find.text('No complaints found'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      await tester.tap(find.text('Reset Filters'));
      expect(actionTapped, isTrue);
    });

    testWidgets('GovernmentErrorState renders details and toggles expandable diagnostics', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_buildTestApp(
        GovernmentErrorState(
          title: 'Database Gateway Timeout',
          message: 'Could not connect to BMC municipal service.',
          errorCode: 'ERR_504_GW',
          technicalDetails: 'Connection refused at 10.0.0.1:8080',
          onRetry: () => retried = true,
        ),
      ));

      expect(find.text('Database Gateway Timeout'), findsOneWidget);
      expect(find.text('Code: ERR_504_GW'), findsOneWidget);

      await tester.tap(find.text('Retry Request'));
      expect(retried, isTrue);

      // Expand diagnostics
      expect(find.text('Connection refused at 10.0.0.1:8080'), findsNothing);
      await tester.tap(find.text('Show Diagnostics'));
      await tester.pump();
      expect(find.text('Connection refused at 10.0.0.1:8080'), findsOneWidget);
    });

    testWidgets('GovtLoadingStates widgets render without crash', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const Column(
          children: [
            GovtInlineLoader(),
            GovtButtonLoader(),
            GovtPageLoader(message: 'Loading records...'),
          ],
        ),
      ));

      expect(find.text('Loading records...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
    });
  });

  group('Phase 1: GovernmentConfirmationDialog Widget Tests', () {
    testWidgets('GovernmentConfirmationDialog executes onConfirm callback', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () {
              GovernmentConfirmationDialog.show(
                context,
                title: 'Confirm Work Verification',
                message: 'Mark this pothole repair as verified?',
                confirmLabel: 'Verify Work',
                type: GovtDialogType.confirmation,
                onConfirm: () => confirmed = true,
              );
            },
            child: const Text('Open Modal'),
          );
        }),
      ));

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Work Verification'), findsOneWidget);
      expect(find.text('Verify Work'), findsOneWidget);

      await tester.tap(find.text('Verify Work'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });

  group('Phase 1: Page Header, Breadcrumbs & Alerts Widget Tests', () {
    testWidgets('GovernmentPageHeader renders title, badges, actions, and breadcrumbs', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        GovernmentPageHeader(
          title: 'N Ward Operations Center',
          subtitle: 'Administrative overview of grievances',
          breadcrumbs: const [
            GovtBreadcrumbItem(label: 'Home'),
            GovtBreadcrumbItem(label: 'N Ward'),
          ],
          jurisdictionBadge: GovtJurisdictionBadge.ward('N Ward'),
          primaryAction: ElevatedButton(
            onPressed: () {},
            child: const Text('New Dispatch'),
          ),
        ),
      ));

      expect(find.text('N Ward Operations Center'), findsOneWidget);
      expect(find.text('Administrative overview of grievances'), findsOneWidget);
      expect(find.text('[N WARD]'), findsOneWidget);
      expect(find.text('New Dispatch'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('N Ward'), findsWidgets);
    });

    testWidgets('GovernmentAlert renders message, title, and action', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(_buildTestApp(
        GovernmentAlert.warning(
          title: 'SLA Threshold Warning',
          message: '7 routing requests require your review.',
          action: TextButton(
            onPressed: () => actionTriggered = true,
            child: const Text('Review Now'),
          ),
        ),
      ));

      expect(find.text('SLA Threshold Warning'), findsOneWidget);
      expect(find.text('7 routing requests require your review.'), findsOneWidget);
      await tester.tap(find.text('Review Now'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('GovernmentSectionHeader renders title, subtitle, and counter', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const GovernmentSectionHeader(
          title: 'Ward Performance',
          subtitle: 'Real-time metrics',
          count: 14,
        ),
      ));

      expect(find.text('Ward Performance'), findsOneWidget);
      expect(find.text('Real-time metrics'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    });
  });

  group('Phase 1: Search Field & Filter Bar Widget Tests', () {
    testWidgets('GovtSearchField triggers debounced onChanged and clear', (tester) async {
      String searched = '';
      await tester.pumpWidget(_buildTestApp(
        GovtSearchField(
          debounceDuration: const Duration(milliseconds: 100),
          onChanged: (val) => searched = val,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'pothole');
      await tester.pump(const Duration(milliseconds: 50));
      // Before debounce fires
      expect(searched, '');

      // After debounce fires
      await tester.pump(const Duration(milliseconds: 120));
      expect(searched, 'pothole');

      // Clear button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(searched, '');
    });

    testWidgets('GovernmentFilterBar renders search and dropdown filters', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        GovernmentFilterBar(
          searchHint: 'Filter complaints...',
          dropdownFilters: [
            GovtDropdownFilterConfig<String>(
              label: 'Ward',
              selectedValue: 'N Ward',
              items: const [
                DropdownMenuItem(value: 'N Ward', child: Text('N Ward')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
      ));

      expect(find.byType(GovtSearchField), findsOneWidget);
      expect(find.text('N Ward'), findsOneWidget);
    });
  });

  group('Phase 1: GovernmentDataTable Widget Tests', () {
    testWidgets('GovernmentDataTable renders columns, rows, and pagination', (tester) async {
      int prevTapped = 0;
      int nextTapped = 0;

      await tester.pumpWidget(_buildTestApp(
        GovernmentDataTable(
          title: 'Municipal Complaints Queue',
          currentPage: 2,
          totalCount: 30,
          pageSize: 10,
          onPreviousPage: () => prevTapped++,
          onNextPage: () => nextTapped++,
          columns: const [
            GovtDataColumn(label: 'ID', width: 80, isSortable: true),
            GovtDataColumn(label: 'Category', width: 140),
            GovtDataColumn(label: 'Status', width: 120),
          ],
          rows: const [
            [Text('CF-01'), Text('Roads'), Text('In Progress')],
            [Text('CF-02'), Text('Water'), Text('Resolved')],
          ],
        ),
      ));

      expect(find.text('Municipal Complaints Queue'), findsOneWidget);
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('CF-01'), findsOneWidget);
      expect(find.text('CF-02'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      expect(prevTapped, 1);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(nextTapped, 1);
    });

    testWidgets('GovernmentDataTable supports row selection and sorting', (tester) async {
      int sortedCol = -1;
      bool sortAsc = false;
      final Set<int> selected = {};

      await tester.pumpWidget(_buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            return GovernmentDataTable(
              selectable: true,
              selectedRows: selected,
              onSelectRow: (r, isSel) {
                setState(() {
                  if (isSel) {
                    selected.add(r);
                  } else {
                    selected.remove(r);
                  }
                });
              },
              columns: const [
                GovtDataColumn(label: 'ID', isSortable: true),
              ],
              onSort: (col, asc) {
                sortedCol = col;
                sortAsc = asc;
              },
              rows: const [
                [Text('CF-101')],
                [Text('CF-102')],
              ],
            );
          },
        ),
      ));

      expect(find.byType(Checkbox), findsWidgets);
      // Tap checkbox for row 0
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();
      expect(selected.contains(0), isTrue);

      // Tap sortable header
      await tester.tap(find.text('ID'));
      await tester.pump();
      expect(sortedCol, 0);
      expect(sortAsc, isTrue);
    });
  });

  group('Phase 1: GovernmentAppShell & Sidebar Responsive Tests', () {
    testWidgets('GovernmentAppShell renders persistent sidebar on desktop (1280px)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        GovernmentAppShell(
          title: 'Command Dashboard',
          authService: MockGovtAuthService(),
          body: const Text('Dashboard Main Content'),
        ),
        size: const Size(1280, 800),
      ));
      await tester.pump();

      expect(find.byType(GovtSidebar), findsOneWidget);
      expect(find.text('Dashboard Main Content'), findsOneWidget);
      expect(find.text('GOVERNMENT PORTAL'), findsWidgets);
    });

    testWidgets('GovernmentAppShell renders collapsed sidebar on tablet (768px)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        GovernmentAppShell(
          title: 'Command Dashboard',
          authService: MockGovtAuthService(),
          body: const Text('Tablet Content'),
        ),
        size: const Size(768, 1024),
      ));
      await tester.pump();

      final sidebar = tester.widget<GovtSidebar>(find.byType(GovtSidebar));
      expect(sidebar.isCollapsed, isTrue);
    });

    testWidgets('GovernmentAppShell renders drawer trigger on mobile (390px)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(
        GovernmentAppShell(
          title: 'Mobile Operations',
          authService: MockGovtAuthService(),
          body: const Text('Mobile Content'),
        ),
        size: const Size(390, 844),
      ));
      await tester.pump();

      // Sidebar is not placed directly in row on mobile
      expect(find.byType(GovtSidebar), findsNothing);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Open Drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byType(GovtSidebar), findsOneWidget);
    });
  });

  group('Phase 1: Role-Aware Visibility Widget Tests', () {
    testWidgets('GovtRoleVisibility renders child only when role matches', (tester) async {
      const superAdminUser = GovtUserModel(
        id: 'adm_1',
        fullName: 'Super Admin',
        email: 'adm@civicfix.gov.in',
        employeeId: 'ADM-1',
        role: GovernmentRole.superAdminId,
      );

      const crewUser = GovtUserModel(
        id: 'crw_1',
        fullName: 'Crew Member',
        email: 'crw@civicfix.gov.in',
        employeeId: 'CRW-1',
        role: GovernmentRole.departmentCrewId,
      );

      await tester.pumpWidget(_buildTestApp(
        Column(
          children: [
            GovtRoleVisibility(
              user: superAdminUser,
              allowedRoles: const [GovernmentRole.governmentSuperAdmin],
              child: const Text('Super Admin Protected Action'),
            ),
            GovtRoleVisibility(
              user: crewUser,
              allowedRoles: const [GovernmentRole.governmentSuperAdmin],
              fallback: const Text('Access Restricted'),
              child: const Text('Should Not Appear'),
            ),
          ],
        ),
      ));

      expect(find.text('Super Admin Protected Action'), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Should Not Appear'), findsNothing);
    });
  });

  group('Phase 1: Government Cards & Surfaces Tests', () {
    testWidgets('GovtCard renders standard, info, and interactive variants', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_buildTestApp(
        Column(
          children: [
            const GovtCard(
              title: 'Standard Municipal Card',
              subtitle: 'Operational details',
              child: Text('Card Content'),
            ),
            GovtCard.info(
              title: 'Informational Notice',
              child: const Text('Info Content'),
            ),
            GovtCard(
              onTap: () => tapped = true,
              child: const Text('Clickable Action Card'),
            ),
          ],
        ),
      ));

      expect(find.text('Standard Municipal Card'), findsOneWidget);
      expect(find.text('Operational details'), findsOneWidget);
      expect(find.text('Informational Notice'), findsOneWidget);
      expect(find.text('Clickable Action Card'), findsOneWidget);

      await tester.tap(find.text('Clickable Action Card'));
      expect(tapped, isTrue);
    });
  });

  group('Phase 1: Notification Panel Shell Tests', () {
    testWidgets('GovtNotificationPanel renders notification items and triggers tap', (tester) async {
      GovtNotificationItem? tappedItem;
      final testItems = [
        GovtNotificationItem(
          id: 'n_1',
          title: 'SLA Warning on CF-10291',
          description: 'Pothole complaint expiring in 2 hours',
          category: GovtNotificationCategory.slaWarning,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        GovtNotificationPanel(
          notifications: testItems,
          onNotificationTap: (item) => tappedItem = item,
        ),
      ));

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('SLA Warning on CF-10291'), findsOneWidget);
      expect(find.text('Pothole complaint expiring in 2 hours'), findsOneWidget);

      await tester.tap(find.text('SLA Warning on CF-10291'));
      expect(tappedItem?.id, 'n_1');
    });

    testWidgets('GovtNotificationPanel renders empty state when list is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const GovtNotificationPanel(
          notifications: [],
        ),
      ));

      expect(find.text('No operational alerts'), findsOneWidget);
    });
  });
}

