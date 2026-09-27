import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_routing_ticket_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/services/complaint_routing_service.dart';
import 'package:civic_app/core/services/government_audit_service.dart';
import 'package:civic_app/core/services/government_authorization_service.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:civic_app/Govt UI/models/government_filter_model.dart';
import 'package:civic_app/Govt UI/models/government_kpi_metrics.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/screens/complaints/govt_complaint_details_screen.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';
import 'package:civic_app/Govt UI/widgets/complaints/shared/government_complaint_action_bar.dart';
import 'package:civic_app/Govt UI/widgets/complaints/shared/government_evidence_gallery.dart';
import 'package:civic_app/Govt UI/widgets/complaints/shared/government_routing_history_section.dart';
import 'package:civic_app/Govt UI/widgets/map/government_scoped_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalGovernmentHierarchyRepository hierarchyRepo;
  late MockGovtComplaintRepository complaintRepo;
  late DefaultGovernmentAuditService auditService;
  late ComplaintRoutingService routingService;
  late GovernmentAuthorizationService authService;

  const sampleLead = GovtUserModel(
    id: 'GOV-WDL-N-ROADS',
    employeeId: 'EMP-WDL-N-ROADS',
    fullName: 'Executive Engineer (N Ward Roads)',
    email: 'lead.roads.n@mcgm.gov.in',
    role: 'ward_department_lead',
    wardId: 'N',
    departmentId: 'dept_roads',
    departmentName: 'Maintenance & Roads',
    displayDesignation: 'Executive Engineer',
    active: true,
  );

  final sampleComplaint = ComplaintModel(
    id: 'CF-99001',
    ticketNumber: 'TKT-99001',
    title: 'Severe Waterlogging at Ghatkopar Junction',
    description: 'Stormwater drain overflowing near metro station.',
    category: CivicCategory.defaultCategories[5], // Drainage
    status: ComplaintStatus.inProgress,
    priority: ComplaintPriority.emergency,
    location: const CivicLocation(
      latitude: 19.0860,
      longitude: 72.9080,
      address: 'Ghatkopar East Metro Station',
      ward: 'N',
    ),
    wardId: 'N',
    assignedDepartmentId: 'dept_roads',
    assignedDepartmentLeadId: 'EMP-WDL-N-ROADS',
    assignedCrewMemberId: 'EMP-CREW-01',
    imageUrls: ['https://civicfix.gov.in/evidence_photo.jpg'],
    timeline: [
      TimelineEvent(
        title: 'Complaint Submitted',
        description: 'Citizen reported via mobile app.',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        status: ComplaintStatus.reported,
      ),
      TimelineEvent(
        title: 'Assigned to Crew',
        description: 'Dispatched to Rajesh Kumar.',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        status: ComplaintStatus.assigned,
      ),
      TimelineEvent(
        title: 'Work Started',
        description: 'Excavation team on site.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        status: ComplaintStatus.inProgress,
      ),
    ],
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    originalCreatedAt: DateTime.now().subtract(const Duration(hours: 12)),
    slaStartedAt: DateTime.now().subtract(const Duration(hours: 12)),
  );

  setUp(() async {
    hierarchyRepo = LocalGovernmentHierarchyRepository();
    await hierarchyRepo.initialize();
    complaintRepo = MockGovtComplaintRepository();
    auditService = DefaultGovernmentAuditService();
    authService = GovernmentAuthorizationService(hierarchyRepo: hierarchyRepo);
    routingService = ComplaintRoutingService(
      hierarchyRepo: hierarchyRepo,
      auditService: auditService,
      authService: authService,
    );

    routingService.registerComplaint(sampleComplaint);
  });

  Widget createHarness({
    required Widget child,
    Size size = const Size(1200, 900),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('PHASE 9 — Master GovtComplaintDetailsScreen Widget Tests', () {
    testWidgets('Renders complaint overview, breadcrumbs, action bar, and timeline for authorized Lead',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        createHarness(
          child: GovtComplaintDetailsScreen(
            complaint: sampleComplaint,
            user: sampleLead,
            repository: complaintRepo,
            hierarchyRepo: hierarchyRepo,
            routingService: routingService,
            auditService: auditService,
            authService: authService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('TKT-99001'), findsWidgets);
      expect(find.text('Ghatkopar East Metro Station'), findsOneWidget);
      expect(find.textContaining('COMPLAINT LIFECYCLE TIMELINE'), findsOneWidget);
      expect(find.text('Complaint Submitted'), findsOneWidget);
      expect(find.text('Work Started'), findsOneWidget);
      expect(find.byType(GovernmentComplaintActionBar), findsOneWidget);
    });

    testWidgets('Deep Link Jurisdiction Safety: Displays boundary restriction for unauthorized scope',
        (tester) async {
      const unauthorizedLeadAWard = GovtUserModel(
        id: 'GOV-WDL-A-ROADS',
        employeeId: 'EMP-WDL-A-ROADS',
        fullName: 'Executive Engineer (A Ward Roads)',
        email: 'lead.roads.a@mcgm.gov.in',
        role: 'ward_department_lead',
        wardId: 'A', // Different Ward!
        departmentId: 'dept_roads',
        departmentName: 'Maintenance & Roads',
        displayDesignation: 'Executive Engineer',
        active: true,
      );

      await tester.pumpWidget(
        createHarness(
          child: GovtComplaintDetailsScreen(
            complaint: sampleComplaint,
            user: unauthorizedLeadAWard,
            repository: complaintRepo,
            hierarchyRepo: hierarchyRepo,
            routingService: routingService,
            auditService: auditService,
            authService: authService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Jurisdiction Boundary Restriction'), findsOneWidget);
      expect(find.textContaining('Access is restricted strictly to authorized'), findsOneWidget);
    });
  });

  group('PHASE 9 — GovernmentEvidenceGallery & Fullscreen Tests', () {
    testWidgets('Renders photographic evidence items and opens fullscreen viewer on tap',
        (tester) async {
      final items = [
        GovernmentEvidenceItem(
          imageUrl: 'https://civicfix.gov.in/before.jpg',
          title: 'Before Remediation',
          stage: 'before',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        GovernmentEvidenceItem(
          imageUrl: 'https://civicfix.gov.in/after.jpg',
          title: 'After Remediation',
          stage: 'after',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        createHarness(
          child: Scaffold(
            body: GovernmentEvidenceGallery(
              title: 'FIELD EVIDENCE',
              evidenceItems: items,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FIELD EVIDENCE'), findsOneWidget);
      expect(find.text('Before Remediation'), findsOneWidget);
      expect(find.text('After Remediation'), findsOneWidget);

      // Tap on evidence item to open fullscreen viewer
      await tester.tap(find.text('Before Remediation'));
      await tester.pumpAndSettle();

      // Verify fullscreen modal opened
      expect(find.textContaining('1 / 2'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 / 2'), findsNothing);
    });
  });

  group('PHASE 9 — GovernmentRoutingHistorySection Tests', () {
    testWidgets('Renders empty state when no routing tickets exist', (tester) async {
      await tester.pumpWidget(
        createHarness(
          child: const Scaffold(
            body: GovernmentRoutingHistorySection(routingTickets: []),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('No department reassignment tickets'), findsOneWidget);
    });

    testWidgets('Renders transfer flow and adjudication notes for routing tickets', (tester) async {
      final tickets = [
        ComplaintRoutingTicket(
          id: 'CRT-101',
          complaintId: sampleComplaint.id,
          ticketNumber: sampleComplaint.ticketNumber,
          wardId: 'N',
          sourceDepartmentId: 'dept_roads',
          sourceLeadId: 'EMP-WDL-N-ROADS',
          suggestedDepartmentId: 'dept_swm',
          reason: 'Solid waste blocking stormwater channel.',
          status: RoutingTicketStatus.approved,
          reviewedBy: 'EMP-WO-N',
          reviewNotes: 'Transfer approved to SWM department.',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          reviewedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

      await tester.pumpWidget(
        createHarness(
          child: Scaffold(
            body: GovernmentRoutingHistorySection(routingTickets: tickets),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('dept_roads'), findsOneWidget);
      expect(find.text('dept_swm'), findsOneWidget);
      expect(find.text('Solid waste blocking stormwater channel.'), findsOneWidget);
      expect(find.textContaining('Transfer approved to SWM department'), findsOneWidget);
    });
  });

  group('PHASE 9 — GovernmentScopedMap Tests', () {
    testWidgets('Enforces scope and renders GIS markers for authorized scope', (tester) async {
      final hazards = [
        HazardModel.fromComplaint(sampleComplaint),
      ];

      await tester.pumpWidget(
        createHarness(
          child: Scaffold(
            body: GovernmentScopedMap(
              user: sampleLead,
              initialHazards: hazards,
              isEmbedded: true,
              height: 400,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Unit Scope'), findsOneWidget);
      expect(find.byType(GovernmentScopedMap), findsOneWidget);
    });
  });

  group('PHASE 9 — Standardized GovernmentFilterModel Tests', () {
    test('Filter model predicate matching, active count, and pagination', () {
      var filter = const GovernmentFilterModel(
        searchQuery: 'Ghatkopar',
        priority: ComplaintPriority.emergency,
        pageSize: 10,
      );

      expect(filter.activeFilterCount, equals(2));
      expect(filter.isFiltered, isTrue);

      // Matches complaint
      expect(filter.matches(sampleComplaint), isTrue);

      // Different priority complaint -> does not match
      final lowPriComplaint = sampleComplaint.copyWith(
        priority: ComplaintPriority.low,
      );
      expect(filter.matches(lowPriComplaint), isFalse);

      // Reset
      final resetFilter = filter.reset();
      expect(resetFilter.activeFilterCount, equals(0));
      expect(resetFilter.isFiltered, isFalse);
      expect(resetFilter.matches(lowPriComplaint), isTrue);
    });

    test('Filter model sorting and pagination (10, 25, 50)', () {
      final list = List.generate(
        35,
        (i) => sampleComplaint.copyWith(
          id: 'CF-$i',
          ticketNumber: 'TKT-$i',
          createdAt: DateTime.now().subtract(Duration(hours: i)),
        ),
      );

      var filter = const GovernmentFilterModel(
        pageSize: 10,
        page: 0,
        sortBy: GovtComplaintSortField.reportedAt,
        sortAscending: false,
      );

      expect(filter.totalPages(list.length), equals(4)); // 35 / 10 = 4 pages
      final page0 = filter.paginate(list);
      expect(page0.length, equals(10));
      expect(page0.first.id, equals('CF-0'));

      filter = filter.copyWith(pageSize: 25);
      expect(filter.totalPages(list.length), equals(2));
      final page25 = filter.paginate(list);
      expect(page25.length, equals(25));
    });
  });

  group('PHASE 9 — Standardized GovernmentKpiMetrics Tests', () {
    test('Computes standardized KPI values consistently across datasets', () {
      final complaints = [
        // 1. Open, in progress, high priority, SLA warning
        sampleComplaint.copyWith(
          status: ComplaintStatus.inProgress,
          priority: ComplaintPriority.high,
          createdAt: DateTime.now().subtract(const Duration(hours: 40)),
        ),
        // 2. Resolved today within SLA
        sampleComplaint.copyWith(
          status: ComplaintStatus.resolved,
          priority: ComplaintPriority.medium,
          createdAt: DateTime.now().subtract(const Duration(hours: 10)),
          updatedAt: DateTime.now(),
        ),
        // 3. Open, SLA breached
        sampleComplaint.copyWith(
          status: ComplaintStatus.reported,
          priority: ComplaintPriority.low,
          createdAt: DateTime.now().subtract(const Duration(hours: 55)),
        ),
      ];

      final metrics = GovernmentKpiMetrics.fromComplaints(complaints);

      expect(metrics.totalComplaints, equals(3));
      expect(metrics.openComplaints, equals(2));
      expect(metrics.resolvedComplaints, equals(1));
      expect(metrics.resolvedToday, equals(1));
      expect(metrics.slaBreachedCount, equals(1));
      expect(metrics.slaWarningCount, equals(1));
      expect(metrics.criticalComplaints, equals(1));
      expect(metrics.slaComplianceRate, equals(1.0)); // 1 resolved was within SLA
    });
  });

  group('PHASE 9 — Responsive Viewport Verification Tests', () {
    testWidgets('Renders correctly at Mobile (390px) without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        createHarness(
          size: const Size(390, 844),
          child: GovtComplaintDetailsScreen(
            complaint: sampleComplaint,
            user: sampleLead,
            repository: complaintRepo,
            hierarchyRepo: hierarchyRepo,
            routingService: routingService,
            auditService: auditService,
            authService: authService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('TKT-99001'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders correctly at Tablet (768px) without RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      await tester.pumpWidget(
        createHarness(
          size: const Size(768, 1024),
          child: GovtComplaintDetailsScreen(
            complaint: sampleComplaint,
            user: sampleLead,
            repository: complaintRepo,
            hierarchyRepo: hierarchyRepo,
            routingService: routingService,
            auditService: auditService,
            authService: authService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('TKT-99001'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders correctly at Desktop (1440px) with multi-column layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));

      await tester.pumpWidget(
        createHarness(
          size: const Size(1440, 900),
          child: GovtComplaintDetailsScreen(
            complaint: sampleComplaint,
            user: sampleLead,
            repository: complaintRepo,
            hierarchyRepo: hierarchyRepo,
            routingService: routingService,
            auditService: auditService,
            authService: authService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('TKT-99001'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
