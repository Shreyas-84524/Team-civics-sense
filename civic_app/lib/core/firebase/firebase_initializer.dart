import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

import '../auth/auth_service_locator.dart';
import '../repositories/repository_locator.dart';
import '../sync/providers/firebase_sync_provider.dart';
import '../sync/sync_manager.dart';

/// Centralized bootstrap & lifecycle orchestrator for Firebase remote backend services.
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;
  static FirebaseApp? _app;

  /// Whether Firebase has been successfully initialized in the current runtime session.
  static bool get isInitialized => _initialized;

  /// The active default [FirebaseApp] instance, or null if initialization was skipped or failed.
  static FirebaseApp? get app => _app;

  /// Initializes Firebase using platform-specific [DefaultFirebaseOptions].
  ///
  /// This method is safe, idempotent, and non-blocking:
  /// - If Firebase is already initialized (e.g. in tests or hot restart), it returns the existing app.
  /// - If initialization fails (e.g. unsupported platform in development/test), it logs a diagnostic
  ///   warning without crashing, preserving full Hive offline app functionality.
  static Future<bool> initialize({FirebaseOptions? customOptions}) async {
    // If already marked initialized and apps exist, return immediately (idempotent)
    if (_initialized && Firebase.apps.isNotEmpty) {
      _app = Firebase.app();
      _configureProductionBackend();
      return true;
    }

    try {
      // Check if default app was already initialized by FlutterFire CLI / platform channels
      if (Firebase.apps.isNotEmpty) {
        _app = Firebase.app();
        _initialized = true;
        _configureProductionBackend();
        debugPrint('[CivicFix Firebase] Existing Firebase app attached: ${_app?.name}');
        return true;
      }

      final options = customOptions ?? DefaultFirebaseOptions.currentPlatform;

      _app = await Firebase.initializeApp(
        options: options,
      );

      _initialized = true;
      _configureProductionBackend();
      debugPrint('[CivicFix Firebase] Firebase initialized successfully for project: ${_app?.options.projectId}');
      return true;
    } catch (e, stackTrace) {
      // On platforms where options are missing or unsupported (e.g. Linux or test runner),
      // gracefully fail and allow the app to operate offline via Hive.
      debugPrint('[CivicFix Firebase] Warning: Failed to initialize Firebase: $e\n$stackTrace');
      _initialized = false;
      _app = null;
      return false;
    }
  }

  static void _configureProductionBackend() {
    try {
      SyncManager().setProvider(FirebaseSyncProvider());
      RepositoryLocator.useProductionRepositories();
      AuthServiceLocator.useFirebaseServices();
      debugPrint('[CivicFix Firebase] Production sync & repository wiring configured.');
    } catch (e) {
      debugPrint('[CivicFix Firebase] Warning during production backend wiring: $e');
    }
  }

  /// Resets the initializer state for unit and integration testing.
  @visibleForTesting
  static void resetForTesting({bool initialized = false, FirebaseApp? app}) {
    _initialized = initialized;
    _app = app;
  }
}
