import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_notification_service.dart';
import 'mock_notification_service.dart';
import 'notification_service.dart';

/// Centralized service locator for [NotificationService].
class NotificationServiceLocator {
  NotificationServiceLocator._();

  static NotificationService? _instance;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Global NavigatorKey accessible across the application and notification routing.
  static GlobalKey<NavigatorState> get navigatorKey {
    _navigatorKey ??= GlobalKey<NavigatorState>();
    return _navigatorKey!;
  }

  /// Sets or overrides the active application navigator key.
  static set navigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Active NotificationService instance.
  static NotificationService get instance {
    if (_instance != null) {
      return _instance!;
    }

    if (_isFirebaseReady) {
      try {
        _instance = FirebaseNotificationService(navigatorKey: _navigatorKey);
        return _instance!;
      } catch (e) {
        debugPrint('[NotificationServiceLocator] Fallback to MockNotificationService: $e');
      }
    }

    _instance = MockNotificationService(navigatorKey: _navigatorKey);
    return _instance!;
  }

  /// Sets or overrides the active NotificationService (e.g. for testing).
  static set instance(NotificationService service) {
    _instance = service;
  }

  /// Switches to in-memory Mock implementation.
  static void useMockService() {
    _instance = MockNotificationService(navigatorKey: _navigatorKey);
  }

  /// Switches to Firebase backend implementation.
  static void useFirebaseService() {
    _instance = FirebaseNotificationService(navigatorKey: _navigatorKey);
  }

  /// Resets cached instances for tests.
  static void reset() {
    _instance = null;
  }

  static bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
