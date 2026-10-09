import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../local/hive/hive_boxes.dart';
import '../local/hive/hive_storage_service.dart';
import '../local/local_storage_service.dart';
import '../local/models/settings_local_model.dart';
import 'models/app_locale.dart';

/// Centralized state controller for managing, switching, and persisting
/// application locales across CivicFix at runtime.
///
/// Implements [ValueListenable<Locale>] so it can be passed directly to
/// [ValueListenableBuilder<Locale>], [ListenableBuilder], Riverpod state providers, etc.
class LocaleController implements ValueListenable<Locale> {
  static const String selectedLocaleStorageKey = 'selected_locale';

  /// Supported locales for CivicFix (English, Hindi, Marathi).
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// Supported ISO 639-1 language codes.
  static const List<String> supportedLanguageCodes = <String>['en', 'hi', 'mr'];

  /// Canonical fallback locale when none is specified or supported.
  static const Locale defaultLocale = Locale('en');

  static LocaleController? _instance;

  /// Singleton accessor for [LocaleController].
  static LocaleController get instance {
    _instance ??= LocaleController();
    return _instance!;
  }

  /// Sets or overrides the singleton instance (useful for unit & widget tests).
  static set instance(LocaleController controller) {
    _instance = controller;
  }

  final LocalStorageService _storage;
  final ValueNotifier<Locale> _localeNotifier;
  bool _initialized = false;
  bool _hasExplicitSelection = false;

  LocaleController({
    LocalStorageService? storage,
    Locale initialLocale = defaultLocale,
  })  : _storage = storage ?? HiveStorageService.instance,
        _localeNotifier = ValueNotifier<Locale>(initialLocale);

  /// ValueNotifier exposing the active [Locale] for reactive UI updates.
  ValueNotifier<Locale> get localeNotifier => _localeNotifier;

  /// The active [Locale].
  Locale get currentLocale => _localeNotifier.value;

  /// The active [AppLocale] enum instance.
  AppLocale get currentAppLocale => AppLocale.fromLocale(_localeNotifier.value);

  /// The active ISO 639-1 language code (e.g. 'en', 'hi', 'mr').
  String get currentLanguageCode => _localeNotifier.value.languageCode;

  /// Whether the controller has been initialized.
  bool get isInitialized => _initialized;

  /// Whether the user has explicitly selected a locale in this session or storage.
  bool get hasExplicitSelection => _hasExplicitSelection;

  @override
  Locale get value => _localeNotifier.value;

  @override
  void addListener(VoidCallback listener) => _localeNotifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _localeNotifier.removeListener(listener);

  /// Checks if a language code or [Locale] is supported.
  static bool isSupported(dynamic localeOrCode) {
    return AppLocale.isSupported(localeOrCode);
  }

  /// Initializes the controller by resolving the initial locale following the fallback chain:
  /// 1. Stored Preference (Hive settings box)
  /// 2. Supported Device Locale (System settings)
  /// 3. Canonical Fallback (English 'en')
  Future<Locale> initialize({Locale? customDeviceLocale}) async {
    final resolvedLocale = await determineInitialLocale(deviceLocale: customDeviceLocale);
    _localeNotifier.value = resolvedLocale;
    _initialized = true;
    return resolvedLocale;
  }

  /// Determines the active locale using the strict 3-tier fallback chain.
  Future<Locale> determineInitialLocale({Locale? deviceLocale}) async {
    // Tier 1: Stored Preference
    try {
      if (_storage.isInitialized) {
        final storedCode = await _storage.get<String>(
          HiveBoxes.settings,
          selectedLocaleStorageKey,
        );
        if (storedCode != null && isSupported(storedCode)) {
          _hasExplicitSelection = true;
          return AppLocale.fromLanguageCode(storedCode).flutterLocale;
        }

        // Also check if SettingsLocalModel has a valid languageCode
        final settings = await _storage.get<SettingsLocalModel>(
          HiveBoxes.settings,
          HiveBoxes.appSettingsKey,
        );
        if (settings != null && isSupported(settings.languageCode)) {
          _hasExplicitSelection = true;
          return AppLocale.fromLanguageCode(settings.languageCode).flutterLocale;
        }
      }
    } catch (e) {
      debugPrint('[LocaleController] Warning: Error reading stored locale: $e');
    }

    // Tier 2: Supported Device Locale
    final systemLocale = deviceLocale ?? getSystemLocale();
    if (systemLocale != null && isSupported(systemLocale.languageCode)) {
      return AppLocale.fromLocale(systemLocale).flutterLocale;
    }

    // Tier 3: Canonical English Fallback
    return defaultLocale;
  }

  /// Queries the system/host platform dispatcher for the current system locale.
  Locale? getSystemLocale() {
    try {
      final dispatcher = ui.PlatformDispatcher.instance;
      if (dispatcher.locales.isNotEmpty) {
        return dispatcher.locales.first;
      }
      return dispatcher.locale;
    } catch (e) {
      debugPrint('[LocaleController] Could not retrieve platform locale: $e');
      return null;
    }
  }

  /// Resolves the locale to use for MaterialApp.localeResolutionCallback.
  Locale resolveLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
    if (_hasExplicitSelection) {
      return _localeNotifier.value;
    }

    if (deviceLocale != null && isSupported(deviceLocale.languageCode)) {
      return AppLocale.fromLocale(deviceLocale).flutterLocale;
    }

    return _localeNotifier.value;
  }

  /// Switches the active application locale at runtime without app restart
  /// and persists the choice to offline storage.
  Future<void> setLocale(Locale locale) async {
    final targetAppLocale = AppLocale.fromLocale(locale);
    final targetLocale = targetAppLocale.flutterLocale;

    _hasExplicitSelection = true;
    _localeNotifier.value = targetLocale;

    try {
      if (_storage.isInitialized) {
        await _storage.put<String>(
          HiveBoxes.settings,
          selectedLocaleStorageKey,
          targetLocale.languageCode,
        );

        // Keep SettingsLocalModel in sync
        final currentSettings = await _storage.get<SettingsLocalModel>(
          HiveBoxes.settings,
          HiveBoxes.appSettingsKey,
        );
        if (currentSettings != null) {
          await _storage.put<SettingsLocalModel>(
            HiveBoxes.settings,
            HiveBoxes.appSettingsKey,
            currentSettings.copyWith(languageCode: targetLocale.languageCode),
          );
        } else {
          await _storage.put<SettingsLocalModel>(
            HiveBoxes.settings,
            HiveBoxes.appSettingsKey,
            SettingsLocalModel(languageCode: targetLocale.languageCode),
          );
        }
      }
    } catch (e) {
      debugPrint('[LocaleController] Warning: Failed to persist locale selection: $e');
    }
  }

  /// Switches the active application locale using an [AppLocale] enum value.
  Future<void> setAppLocale(AppLocale appLocale) => setLocale(appLocale.flutterLocale);

  /// Helper to set locale by ISO 639-1 language code string ('en', 'hi', 'mr').
  Future<void> setLanguageCode(String languageCode) =>
      setLocale(AppLocale.fromLanguageCode(languageCode).flutterLocale);

  /// Resets controller state for unit or widget testing.
  @visibleForTesting
  Future<void> resetForTesting({Locale initialLocale = defaultLocale}) async {
    _hasExplicitSelection = false;
    _initialized = false;
    _localeNotifier.value = initialLocale;
  }

  /// Tears down and resets the singleton instance.
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }
}
