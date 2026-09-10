import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase/firestore/firebase_user_data_source.dart';
import '../models/notification_model.dart';
import '../routing/app_routes.dart';
import 'mock_notification_service.dart';
import 'notification_service.dart';

/// Production Firebase Cloud Messaging implementation of [NotificationService].
class FirebaseNotificationService implements NotificationService {
  final FirebaseMessaging? _messaging;
  final FirebaseUserDataSource _userDataSource;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _activeUserId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSub;

  FirebaseNotificationService({
    FirebaseMessaging? messaging,
    FirebaseUserDataSource? userDataSource,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : _messaging = messaging,
        _userDataSource = userDataSource ?? FirebaseUserDataSource(),
        _navigatorKey = navigatorKey;

  FirebaseMessaging get _fcm => _messaging ?? FirebaseMessaging.instance;

  /// Sets or updates the active navigator key for deep-link routing.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Sets the active signed-in user identifier.
  void setActiveUserId(String? userId) {
    _activeUserId = userId;
  }

  @override
  Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    void Function(RemoteMessage)? onNotificationOpened,
    void Function(RemoteMessage)? onForegroundMessage,
  }) async {
    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    }

    try {
      // 1. Request notification permissions on mobile/web
      await requestPermission();

      // 2. Set presentation options for iOS/macOS foreground alerts
      try {
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('[FirebaseNotificationService] Presentation options skipped: $e');
      }

      // 3. Listen for foreground push messages
      await _messageSub?.cancel();
      _messageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FirebaseNotificationService] Foreground message received: ${message.messageId}');
        
        if (onForegroundMessage != null) {
          onForegroundMessage(message);
        } else {
          _presentForegroundNotification(message);
        }
      });

      // 4. Listen for background push message taps
      await _messageOpenedAppSub?.cancel();
      _messageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FirebaseNotificationService] Push opened from background: ${message.messageId}');
        
        if (onNotificationOpened != null) {
          onNotificationOpened(message);
        } else {
          handleNotificationNavigation(message, navigatorKey: _navigatorKey);
        }
      });

      // 5. Check if app was launched from a terminated state via push notification tap
      final initialMessage = await getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FirebaseNotificationService] App launched from terminated state via push: ${initialMessage.messageId}');
        // Delay slightly to let initial widget tree and router settle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (onNotificationOpened != null) {
            onNotificationOpened(initialMessage);
          } else {
            handleNotificationNavigation(initialMessage, navigatorKey: _navigatorKey);
          }
        });
      }

      // 6. Monitor FCM token rotation and update Firestore device record
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((String newToken) async {
        debugPrint('[FirebaseNotificationService] FCM Token refreshed: $newToken');
        if (_activeUserId != null && _activeUserId!.isNotEmpty) {
          await registerDeviceToken(_activeUserId!, platform: defaultTargetPlatform.name);
        }
      });
    } catch (e, st) {
      debugPrint('[FirebaseNotificationService] Initialization error (operating with graceful fallback): $e\n$st');
    }
  }

  @override
  Future<NotificationSettings?> requestPermission() async {
    try {
      return await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      debugPrint('[FirebaseNotificationService] requestPermission skipped: $e');
      return null;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FirebaseNotificationService] getToken failed: $e');
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('[FirebaseNotificationService] deleteToken failed: $e');
    }
  }

  @override
  Future<void> registerDeviceToken(String userId, {String? platform}) async {
    if (userId.isEmpty) return;
    _activeUserId = userId;

    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        final platformName = platform ?? (kIsWeb ? 'web' : defaultTargetPlatform.name);
        await _userDataSource.registerDeviceToken(
          userId,
          token,
          platform: platformName,
        );
        debugPrint('[FirebaseNotificationService] Device token registered for user: $userId');
      }
    } catch (e) {
      debugPrint('[FirebaseNotificationService] Failed to register device token: $e');
    }
  }

  @override
  Future<void> unregisterDeviceToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await _userDataSource.unregisterDeviceToken(userId, token);
        debugPrint('[FirebaseNotificationService] Device token unregistered for user: $userId');
      }
    } catch (e) {
      debugPrint('[FirebaseNotificationService] Failed to unregister device token: $e');
    } finally {
      if (_activeUserId == userId) {
        _activeUserId = null;
      }
    }
  }

  @override
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await _fcm.getInitialMessage();
    } catch (e) {
      debugPrint('[FirebaseNotificationService] getInitialMessage error: $e');
      return null;
    }
  }

  @override
  void handleNotificationNavigation(
    RemoteMessage message, {
    BuildContext? context,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final nav = navigatorKey?.currentState ?? _navigatorKey?.currentState;
    final navContext = context ?? nav?.context;

    final data = message.data;
    final complaintId = data['complaintId'] as String?;
    final targetRoute = data['targetRoute'] as String?;
    final role = data['role'] as String?;
    final type = data['type'] as String?;

    debugPrint(
      '[FirebaseNotificationService] Navigating for push: targetRoute=$targetRoute, '
      'complaintId=$complaintId, role=$role, type=$type',
    );

    // 1. Direct target route specified
    if (targetRoute != null && targetRoute.isNotEmpty) {
      if (nav != null) {
        nav.pushNamed(targetRoute, arguments: complaintId ?? data);
      } else if (navContext != null) {
        Navigator.of(navContext).pushNamed(targetRoute, arguments: complaintId ?? data);
      }
      return;
    }

    // 2. Complaint specific navigation
    if (complaintId != null && complaintId.isNotEmpty) {
      final isGovt = role == 'government' ||
          type == 'high_priority_complaint' ||
          type == 'new_complaint_assigned';

      final destinationRoute = isGovt ? AppRoutes.govtComplaintDetails : AppRoutes.complaintDetails;

      if (nav != null) {
        nav.pushNamed(destinationRoute, arguments: complaintId);
      } else if (navContext != null) {
        Navigator.of(navContext).pushNamed(destinationRoute, arguments: complaintId);
      }
      return;
    }

    // 3. Fallback to notifications inbox
    if (nav != null) {
      nav.pushNamed(AppRoutes.notifications);
    } else if (navContext != null) {
      Navigator.of(navContext).pushNamed(AppRoutes.notifications);
    }
  }

  /// Presents a non-blocking in-app notification banner for foreground push messages.
  void _presentForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'CivicFix Update';
    final body = message.notification?.body ?? message.data['message'] ?? '';
    final typeStr = message.data['type'] as String?;

    NotificationType notifType = NotificationType.statusUpdate;
    if (typeStr != null) {
      if (typeStr.contains('submitted')) {
        notifType = NotificationType.complaintSubmitted;
      } else if (typeStr.contains('verified')) {
        notifType = NotificationType.complaintVerified;
      } else if (typeStr.contains('assigned')) {
        notifType = NotificationType.complaintAssigned;
      } else if (typeStr.contains('resolved')) {
        notifType = NotificationType.complaintResolved;
      } else if (typeStr.contains('hazard')) {
        notifType = NotificationType.hazardAlert;
      }
    }

    final currentContext = _navigatorKey?.currentContext;
    if (currentContext != null) {
      MockNotificationService.showInAppAlert(
        currentContext,
        title: title,
        message: body,
        type: notifType,
        onTap: () {
          handleNotificationNavigation(message, navigatorKey: _navigatorKey);
        },
      );
    }
  }

  /// Disposes active stream subscriptions.
  void dispose() {
    _tokenRefreshSub?.cancel();
    _messageSub?.cancel();
    _messageOpenedAppSub?.cancel();
  }
}
