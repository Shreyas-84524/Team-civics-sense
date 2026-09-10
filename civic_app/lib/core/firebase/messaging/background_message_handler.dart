import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_initializer.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
///
/// This entry point is executed in a separate background isolate when a push
/// notification payload arrives while the app is in the background or terminated.
///
/// NOTE: Because this executes in a background isolate without a UI context:
/// - Must be annotated with `@pragma('vm:entry-point')` to prevent tree-shaking.
/// - Must ensure Firebase is initialized before accessing Firebase services.
/// - Must NOT execute Flutter UI operations, dialogs, or platform channels
///   that require an active foreground view.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // 1. Ensure Firebase is initialized in the background isolate
    if (Firebase.apps.isEmpty) {
      await FirebaseInitializer.initialize();
    }

    debugPrint(
      '[CivicFix FCM Background] Message received: id=${message.messageId}, '
      'type=${message.data['type']}, complaintId=${message.data['complaintId']}',
    );
  } catch (e, st) {
    debugPrint('[CivicFix FCM Background] Error processing background message: $e\n$st');
  }
}
