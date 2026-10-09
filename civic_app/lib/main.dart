import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/firebase/messaging/background_message_handler.dart';
import 'core/local/hive/hive_initializer.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/notifications/notification_service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/civicfix_theme.dart';

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

  // 4. Safe centralized localization controller initialization
  try {
    await LocaleController.instance.initialize();
  } catch (e) {
    debugPrint('LocaleController initialization warning: $e');
  }

  runApp(const CivicFixApp());
}

/// Root Application Widget for CivicFix.
class CivicFixApp extends StatelessWidget {
  final String initialRoute;
  final LocaleController? localeController;

  const CivicFixApp({
    super.key,
    this.initialRoute = AppRoutes.splash,
    this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = localeController ?? LocaleController.instance;

    return ValueListenableBuilder<Locale>(
      valueListenable: controller,
      builder: (context, activeLocale, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: NotificationServiceLocator.navigatorKey,
          theme: CivicFixTheme.lightTheme,
          initialRoute: initialRoute,
          locale: activeLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return controller.resolveLocale(deviceLocale, supportedLocales);
          },
          onGenerateInitialRoutes: (String initialRouteName) {
            return [
              AppRouter.generateRoute(RouteSettings(name: initialRouteName)),
            ];
          },
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
