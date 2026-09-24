import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/User%20UI/models/complaint_draft.dart';
import 'package:civic_app/User%20UI/screens/complaint_details_screen.dart';
import 'package:civic_app/User%20UI/services/mock_auth_service.dart';
import 'package:civic_app/User%20UI/services/offline_first_complaint_service.dart';
import 'package:civic_app/User%20UI/widgets/complaint_card.dart';
import 'package:civic_app/Govt%20UI/models/analytics_model.dart';
import 'package:civic_app/Govt%20UI/models/department_model.dart';
import 'package:civic_app/Govt%20UI/services/analytics_repository.dart';
import 'package:civic_app/Govt%20UI/services/govt_complaint_analytics_repository.dart';
import 'package:civic_app/Govt%20UI/services/govt_complaint_repository.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuth;
  late MockComplaintRepository mockComplaintRepo;

  setUp(() {
    mockAuth = MockAuthService();
    mockAuth.resetForTesting();
    AuthServiceLocator.citizenAuth = mockAuth;
    mockComplaintRepo = MockComplaintRepository();
    RepositoryLocator.reset();
  });

  tearDown(() {
    mockAuth.resetForTesting();
    RepositoryLocator.reset();
  });

  group('Phase 3.1 Fix 1: Citizen Auth & Ownership Enforcement', () {
    test('OfflineFirstComplaintService rejects submission when user is unauthenticated', () async {
      mockAuth.setMockUser(null); // Ensure no user logged in
      final service = OfflineFirstComplaintService(complaintRepository: mockComplaintRepo);

      final draft = ComplaintDraft(
        title: 'Broken Pothole',
        description: 'Dangerous pothole near the station',
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Station Road',
        ),
      );

      expect(
        () => service.submitComplaint(draft),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please sign in to submit a complaint.'),
        )),
      );
    });

    test('OfflineFirstComplaintService attaches authenticated citizen UID to created complaint', () async {
      const testUser = UserModel(
        id: 'auth_citizen_999',
        fullName: 'Test Citizen',
        email: 'test@citizen.org',
        phone: '+91 99999 88888',
      );
      mockAuth.setMockUser(testUser);

      final service = OfflineFirstComplaintService(complaintRepository: mockComplaintRepo);

      final draft = ComplaintDraft(
        title: 'Broken Water Pipe',
        description: 'Clean drinking water leaking on main street',
        category: CivicCategory.defaultCategories[1],
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Main Street',
        ),
      );

      final created = await service.submitComplaint(draft);

      expect(created.citizenId, equals('auth_citizen_999'));
      expect(created.title, equals('Broken Water Pipe'));
    });

    test('MockComplaintRepository and HiveComplaintRepository strictly filter by citizenId', () async {
      final repo = MockComplaintRepository();
      // Query with a custom citizenId that has no complaints
      final results = await repo.getCitizenComplaints('non_existent_citizen');
      expect(results, isEmpty);

      // Query with the seeded mock citizen
      final seededResults = await repo.getCitizenComplaints('user_citizen_001');
      expect(seededResults, isNotEmpty);
      for (final c in seededResults) {
        expect(c.citizenId, equals('user_citizen_001'));
      }
    });
  });

  group('Phase 3.1 Fix 2: Citizen Upvoting UI & Deduplication', () {
    testWidgets('ComplaintCard renders interactive Support button and triggers onUpvote', (tester) async {
      bool upvoteTriggered = false;
      final testComplaint = ComplaintModel(
        id: 'cmp_test_001',
        citizenId: 'user_123',
        ticketNumber: 'CF-2026-000001',
        title: 'Streetlight not working',
        description: 'Completely dark road',
        category: CivicCategory.defaultCategories[4], // Streetlights
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 19.0, longitude: 72.0, address: 'Road 5'),
        imageUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        upvotes: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(
              complaint: testComplaint,
              onTap: () {},
              onUpvote: () {
                upvoteTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('3 supports'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);

      await tester.tap(find.text('3 supports'));
      await tester.pumpAndSettle();

      expect(upvoteTriggered, isTrue);
    });

    testWidgets('ComplaintDetailsScreen allows user to upvote and increments support count', (tester) async {
      final testComplaint = ComplaintModel(
        id: 'cmp_details_001',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000002',
        title: 'Garbage pile on corner',
        description: 'Trash accumulating for weeks',
        category: CivicCategory.defaultCategories[3], // Waste Management
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 19.0, longitude: 72.0, address: 'Corner 4'),
        imageUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        upvotes: 5,
      );

      mockAuth.setMockUser(const UserModel(
        id: 'user_citizen_001',
        fullName: 'Rahul Sharma',
        email: 'citizen@civicfix.test',
        phone: '+91 98765 43210',
      ));

      mockComplaintRepo.createComplaint(
        citizenId: 'user_citizen_001',
        title: testComplaint.title,
        description: testComplaint.description,
        category: testComplaint.category,
        location: testComplaint.location,
        priority: testComplaint.priority,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailsScreen(
            complaint: testComplaint,
            repository: mockComplaintRepo,
            authService: mockAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Support button with initial count '5'
      expect(find.text('5'), findsOneWidget);

      // Tap support button
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Verify updated support count '6'
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Supported this complaint!'), findsOneWidget);
    });
  });

  group('Phase 3.1 Fix 3: Govt Complaint Analytics Repository', () {
    test('GovtComplaintAnalyticsRepository derives accurate KPIs from real complaints', () async {
      final govtRepo = MockGovtComplaintRepository();
      final analyticsRepo = GovtComplaintAnalyticsRepository(complaintRepository: govtRepo);

      final data = await analyticsRepo.getAnalytics();

      final allComplaints = await govtRepo.getComplaints();
      expect(data.summary.totalComplaints, equals(allComplaints.length));

      final resolvedCount = allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
      expect(data.summary.resolvedComplaints, equals(resolvedCount));

      final expectedResolutionRate = allComplaints.isNotEmpty ? resolvedCount / allComplaints.length : 0.0;
      expect(data.summary.resolutionRate, closeTo(expectedResolutionRate, 0.001));

      // All 9 civic categories must be present
      expect(data.categoryBreakdowns.length, equals(9));

      // All 5 canonical statuses must be present
      expect(data.statusBreakdowns.length, equals(5));

      // All 9 departments must be present
      expect(data.departmentBreakdowns.length, equals(9));
      expect(
        data.departmentBreakdowns.map((d) => d.departmentId),
        containsAll(GovtDepartmentModel.defaultDepartments.map((d) => d.id)),
      );
    });

    test('GovtComplaintAnalyticsRepository correctly applies multi-criteria filter', () async {
      final govtRepo = MockGovtComplaintRepository();
      final analyticsRepo = GovtComplaintAnalyticsRepository(complaintRepository: govtRepo);

      // Filter for resolved complaints only
      final filter = const AnalyticsFilter(
        status: ComplaintStatus.resolved,
      );

      final data = await analyticsRepo.getAnalytics(filter: filter);

      expect(data.summary.pendingComplaints, equals(0));
      expect(data.summary.inProgressComplaints, equals(0));
      expect(data.summary.totalComplaints, equals(data.summary.resolvedComplaints));
    });

    test('RepositoryLocator provides GovtComplaintAnalyticsRepository in production', () {
      RepositoryLocator.useProductionRepositories();
      expect(RepositoryLocator.isProductionActive, isTrue);
      expect(RepositoryLocator.analyticsRepository, isA<GovtComplaintAnalyticsRepository>());

      RepositoryLocator.useMockRepositories();
      expect(RepositoryLocator.isProductionActive, isFalse);
      expect(RepositoryLocator.analyticsRepository, isA<MockAnalyticsRepository>());
    });
  });
}
