import 'package:flutter/material.dart';

/// Centralized supported application locales for CivicFix.
///
/// Supports:
/// - English (`en`) - Default / Canonical fallback
/// - Hindi (`hi`)
/// - Marathi (`mr`)
enum AppLocale {
  english('en', 'English', 'English'),
  hindi('hi', 'Hindi', 'हिन्दी'),
  marathi('mr', 'Marathi', 'मराठी');

  final String languageCode;
  final String englishName;
  final String nativeName;

  const AppLocale(this.languageCode, this.englishName, this.nativeName);

  /// Flutter [Locale] representation.
  Locale get flutterLocale => Locale(languageCode);

  /// Default and fallback locale across the entire system.
  static const AppLocale fallback = AppLocale.english;

  /// All supported ISO 639-1 language codes.
  static const List<String> supportedCodes = <String>['en', 'hi', 'mr'];

  /// All supported Flutter [Locale] instances.
  static List<Locale> get supportedFlutterLocales =>
      values.map((l) => l.flutterLocale).toList(growable: false);

  /// Resolves an [AppLocale] from a raw language code or BCP 47 tag.
  ///
  /// Examples: 'en', 'en-US', 'hi', 'hi_IN', 'mr_IN' -> matching [AppLocale].
  /// Unrecognized or null codes safely resolve to [AppLocale.fallback] (English).
  static AppLocale fromLanguageCode(String? code) {
    if (code == null || code.trim().isEmpty) return fallback;
    final normalized = code.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    for (final locale in AppLocale.values) {
      if (locale.languageCode == normalized) {
        return locale;
      }
    }
    return fallback;
  }

  /// Resolves an [AppLocale] from a Flutter [Locale].
  static AppLocale fromLocale(Locale? locale) {
    if (locale == null) return fallback;
    return fromLanguageCode(locale.languageCode);
  }

  /// Checks if a language code or identifier is supported.
  static bool isSupported(dynamic localeOrCode) {
    if (localeOrCode == null) return false;
    final code = localeOrCode is Locale
        ? localeOrCode.languageCode.toLowerCase()
        : localeOrCode.toString().toLowerCase().split(RegExp(r'[-_]')).first;
    return supportedCodes.contains(code);
  }
}
