import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/firebase/messaging/background_message_handler.dart';
import 'core/local/hive/hive_initializer.dart';
import 'core/notifications/notification_service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Safe centralized local storage initialization (Hive)
  try {
    await HiveInitializer.initialize();
  } catch (e) {
    debugPrint('Local storage initialization warning: $e');
  }

  // 2. Safe remote backend initialization (Firebase)
  try {
    await FirebaseInitializer.initialize();
    
    // Register FCM background message handler if Firebase initialized
    if (FirebaseInitializer.isInitialized) {
      try {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      } catch (e) {
        debugPrint('FCM background handler registration notice: $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // 3. Initialize Notification Service
  try {
    await NotificationServiceLocator.instance.initialize(
      navigatorKey: NotificationServiceLocator.navigatorKey,
    );
  } catch (e) {
    debugPrint('Notification service initialization warning: $e');
  }

  runApp(const CivicFixApp());
}

/// Root Application Widget for CivicFix.
class CivicFixApp extends StatelessWidget {
  final String initialRoute;

  const CivicFixApp({
    super.key,
    this.initialRoute = AppRoutes.home,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationServiceLocator.navigatorKey,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
