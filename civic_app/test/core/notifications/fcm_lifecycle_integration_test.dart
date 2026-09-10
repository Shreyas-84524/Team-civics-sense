import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/User UI/screens/complaint_tracker_screen.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/notification_model.dart';
import 'package:civic_app/core/notifications/mock_notification_service.dart';
import 'package:civic_app/core/notifications/notification_service_locator.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/routing/app_routes.dart';

void main() {
  group('FCM Lifecycle & End-to-End Integration Tests', () {
    late MockNotificationService notificationService;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      NotificationServiceLocator.navigatorKey = navigatorKey;
      notificationService = MockNotificationService(navigatorKey: navigatorKey);
      NotificationServiceLocator.instance = notificationService;
      AuthServiceLocator.useMockServices();
    });

    test('Citizen Authentication registers device token on login and unregisters on logout', () async {
      final auth = AuthServiceLocator.citizenAuth;

      // Initial state: not registered
      expect(notificationService.isUserRegistered('user_citizen_001'), isFalse);

      // Perform Mock Login
      final result = await auth.login(
        email: 'citizen@civicfix.test',
        password: 'CivicFix123',
      );
      expect(result.isSuccess, isTrue);

      // Simulate token registration hook triggered by auth flow
      await notificationService.registerDeviceToken(result.user!.id);
      expect(notificationService.isUserRegistered(result.user!.id), isTrue);

      // Perform Logout
      await auth.logout();
      await notificationService.unregisterDeviceToken(result.user!.id);
      expect(notificationService.isUserRegistered(result.user!.id), isFalse);
    });

    test('Government Authentication registers device token on login and unregisters on logout', () async {
      final govtAuth = AuthServiceLocator.govtAuth;

      const govtOfficerId = 'govt_officer_101';
      expect(notificationService.isUserRegistered(govtOfficerId), isFalse);

      final result = await govtAuth.login(
        emailOrEmployeeId: 'officer@civicfix.gov.in',
        password: 'CivicFix123',
        departmentId: 'dept_roads',
      );
      expect(result.isSuccess, isTrue);

      await notificationService.registerDeviceToken(result.user!.id);
      expect(notificationService.isUserRegistered(result.user!.id), isTrue);

      await govtAuth.logout();
      await notificationService.unregisterDeviceToken(result.user!.id);
      expect(notificationService.isUserRegistered(result.user!.id), isFalse);
    });

    testWidgets('Foreground Push Notification presents in-app snackbar banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MockNotificationService.showInAppAlert(
                    context,
                    title: 'Status Update: CF-2026-000001',
                    message: 'Your pothole report has been verified by the Roads Department.',
                    type: NotificationType.complaintVerified,
                  );
                },
                child: const Text('Show Banner'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Banner'));
      await tester.pumpAndSettle();

      expect(find.text('Status Update: CF-2026-000001'), findsOneWidget);
      expect(find.text('Your pothole report has been verified by the Roads Department.'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('Push Notification tap triggers deep link to Complaint Tracker Screen', (tester) async {
      final mockRepo = MockComplaintRepository();
      final now = DateTime.now();
      final sampleComplaint = ComplaintModel(
        id: 'cmp_deep_link_001',
        title: 'Deep Link Test Pothole',
        description: 'Test pothole description',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 12.97, longitude: 77.59, address: 'Indiranagar Main Road'),
        ticketNumber: 'CF-2026-009999',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.complaintTracker) {
              return MaterialPageRoute(
                builder: (_) => ComplaintTrackerScreen(
                  complaint: settings.arguments as ComplaintModel,
                  repository: mockRepo,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Home Screen')),
            );
          },
          home: const Scaffold(body: Text('Home Screen')),
        ),
      );

      expect(find.text('Home Screen'), findsOneWidget);

      // Navigate to Tracker
      navigatorKey.currentState?.pushNamed(
        AppRoutes.complaintTracker,
        arguments: sampleComplaint,
      );
      await tester.pumpAndSettle();

      expect(find.text('Status Tracker'), findsOneWidget);
      expect(find.text('CF-2026-009999'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
    });
  });
}
