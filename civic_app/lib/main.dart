import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

import 'core/local/hive/hive_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe centralized local storage initialization
  try {
    await HiveInitializer.initialize();
  } catch (e) {
    debugPrint('Local storage initialization warning: $e');
  }

  runApp(const CivicFixApp());
}

/// Root Application Widget for CivicFix.
class CivicFixApp extends StatelessWidget {
  const CivicFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
