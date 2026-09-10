import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/firestore/firebase_user_data_source.dart';
import 'package:civic_app/core/notifications/mock_notification_service.dart';
import 'package:civic_app/core/notifications/notification_service_locator.dart';
import 'package:civic_app/core/routing/app_routes.dart';

void main() {
  group('NotificationService & MockNotificationService Unit Tests', () {
    late MockNotificationService service;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      service = MockNotificationService(navigatorKey: navigatorKey);
      NotificationServiceLocator.instance = service;
    });

    test('Initializes with navigatorKey and provides default mock token', () async {
      await service.initialize(navigatorKey: navigatorKey);
      final token = await service.getToken();
      expect(token, isNotNull);
      expect(token, equals('mock_fcm_token_device_001'));
    });

    test('Registers and unregisters device tokens for user', () async {
      const userId = 'user_test_citizen_100';

      expect(service.isUserRegistered(userId), isFalse);

      await service.registerDeviceToken(userId, platform: 'android');
      expect(service.isUserRegistered(userId), isTrue);

      await service.unregisterDeviceToken(userId);
      expect(service.isUserRegistered(userId), isFalse);
    });

    test('Token deletion clears active token', () async {
      final initialToken = await service.getToken();
      expect(initialToken, isNotNull);

      await service.deleteToken();
      final clearedToken = await service.getToken();
      expect(clearedToken, isNull);
    });

    test('Emits token refresh events on token update', () async {
      final emittedTokens = <String>[];
      final sub = service.onTokenRefresh.listen(emittedTokens.add);

      service.setMockToken('refreshed_token_abc');
      service.setMockToken('refreshed_token_xyz');

      await Future.delayed(const Duration(milliseconds: 10));
      expect(emittedTokens, equals(['refreshed_token_abc', 'refreshed_token_xyz']));
      await sub.cancel();
    });

    test('Receives and emits simulated foreground messages', () async {
      final receivedMessages = <RemoteMessage>[];
      final sub = service.onMessage.listen(receivedMessages.add);

      final msg = RemoteMessage(
        messageId: 'msg_001',
        data: {'complaintId': 'cmp_123', 'status': 'verified'},
        notification: const RemoteNotification(
          title: 'Status Updated',
          body: 'Your complaint is verified',
        ),
      );

      service.simulateIncomingForegroundMessage(msg);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(receivedMessages.length, equals(1));
      expect(receivedMessages.first.messageId, equals('msg_001'));
      expect(receivedMessages.first.data['complaintId'], equals('cmp_123'));
      await sub.cancel();
    });

    test('Handles initial message for terminated-launch check', () async {
      final initial = RemoteMessage(
        messageId: 'initial_msg_999',
        data: {'complaintId': 'cmp_init_001'},
      );

      service.setInitialMessage(initial);

      final retrieved = await service.getInitialMessage();
      expect(retrieved, isNotNull);
      expect(retrieved?.messageId, equals('initial_msg_999'));
    });
  });

  group('Notification Navigation & Deep-Link Dispatch Tests', () {
    late MockNotificationService service;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      service = MockNotificationService(navigatorKey: navigatorKey);
    });

    testWidgets('Routes Citizen complaint notification to ComplaintDetailsScreen', (tester) async {
      String? pushedRoute;
      dynamic pushedArguments;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            pushedArguments = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => Scaffold(body: Text('Route: ${settings.name}')),
            );
          },
          home: const Scaffold(body: Text('Initial Screen')),
        ),
      );

      final citizenMessage = RemoteMessage(
        messageId: 'msg_citizen_001',
        data: {
          'complaintId': 'cmp_citizen_789',
          'role': 'citizen',
          'type': 'complaint_status_changed',
        },
      );

      service.handleNotificationNavigation(citizenMessage, navigatorKey: navigatorKey);
      await tester.pumpAndSettle();

      expect(pushedRoute, equals(AppRoutes.complaintDetails));
      expect(pushedArguments, equals('cmp_citizen_789'));
    });

    testWidgets('Routes Government complaint notification to GovtComplaintDetailsScreen', (tester) async {
      String? pushedRoute;
      dynamic pushedArguments;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            pushedArguments = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => Scaffold(body: Text('Route: ${settings.name}')),
            );
          },
          home: const Scaffold(body: Text('Initial Govt Screen')),
        ),
      );

      final govtMessage = RemoteMessage(
        messageId: 'msg_govt_001',
        data: {
          'complaintId': 'cmp_govt_456',
          'role': 'government',
          'type': 'high_priority_complaint',
        },
      );

      service.handleNotificationNavigation(govtMessage, navigatorKey: navigatorKey);
      await tester.pumpAndSettle();

      expect(pushedRoute, equals(AppRoutes.govtComplaintDetails));
      expect(pushedArguments, equals('cmp_govt_456'));
    });

    testWidgets('Routes custom targetRoute explicitly when provided in payload', (tester) async {
      String? pushedRoute;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            return MaterialPageRoute(
              builder: (_) => Scaffold(body: Text('Route: ${settings.name}')),
            );
          },
          home: const Scaffold(body: Text('Initial Screen')),
        ),
      );

      final customMessage = RemoteMessage(
        messageId: 'msg_custom_001',
        data: {
          'targetRoute': AppRoutes.rewards,
        },
      );

      service.handleNotificationNavigation(customMessage, navigatorKey: navigatorKey);
      await tester.pumpAndSettle();

      expect(pushedRoute, equals(AppRoutes.rewards));
    });
  });

  group('FirebaseUserDataSource Token Sanitation & Helpers', () {
    test('sanitizeTokenDocId replaces invalid characters with underscores', () {
      expect(FirebaseUserDataSource.sanitizeTokenDocId(''), equals('default_device'));
      expect(
        FirebaseUserDataSource.sanitizeTokenDocId('fcm:APA91b-Ez_123/xyz.abc'),
        equals('fcm_APA91b-Ez_123_xyz_abc'),
      );
      expect(
        FirebaseUserDataSource.sanitizeTokenDocId('clean_token_123-abc'),
        equals('clean_token_123-abc'),
      );
    });
  });

  group('NotificationServiceLocator Tests', () {
    test('useMockService switches to MockNotificationService', () {
      NotificationServiceLocator.useMockService();
      expect(NotificationServiceLocator.instance, isA<MockNotificationService>());
    });

    test('reset clears singleton instance', () {
      final initial = NotificationServiceLocator.instance;
      NotificationServiceLocator.reset();
      NotificationServiceLocator.useMockService();
      final fresh = NotificationServiceLocator.instance;
      expect(identical(initial, fresh), isFalse);
    });
  });
}
