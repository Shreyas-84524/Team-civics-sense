import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Abstract service contract for Firebase Cloud Messaging and notification orchestration.
abstract class NotificationService {
  /// Initializes push notification listeners, background handling, and initial launch checks.
  Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    void Function(RemoteMessage)? onNotificationOpened,
    void Function(RemoteMessage)? onForegroundMessage,
  });

  /// Prompts the user for OS notification permissions (iOS/Android 13+).
  Future<NotificationSettings?> requestPermission();

  /// Retrieves the active FCM device registration token.
  Future<String?> getToken();

  /// Deletes the local FCM registration token instance.
  Future<void> deleteToken();

  /// Registers or updates the active device token in the user's Firestore device subcollection.
  Future<void> registerDeviceToken(String userId, {String? platform});

  /// Removes the device registration token upon user logout.
  Future<void> unregisterDeviceToken(String userId);

  /// Stream of FCM token refresh events.
  Stream<String> get onTokenRefresh;

  /// Stream of incoming push notifications while app is in foreground.
  Stream<RemoteMessage> get onMessage;

  /// Stream of push notifications tapped by user while app is in background.
  Stream<RemoteMessage> get onMessageOpenedApp;

  /// Checks if the app was launched from a terminated state via a push notification tap.
  Future<RemoteMessage?> getInitialMessage();

  /// Handles deep link routing based on notification payload data.
  void handleNotificationNavigation(
    RemoteMessage message, {
    BuildContext? context,
    GlobalKey<NavigatorState>? navigatorKey,
  });
}
