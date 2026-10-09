/// Centralized configuration and feature flags for CivicFix Multilingual & Translation Subsystem.
class TranslationConstants {
  TranslationConstants._();

  /// Current translation schema and prompt version.
  /// Incrementing this invalidates previous cache generations cleanly without data corruption.
  static const int currentTranslationVersion = 1;

  /// Global feature flag / kill-switch for dynamic machine translation.
  /// If set to false, static UI localization continues operating normally while
  /// all user-generated text displays its authoritative original content.
  static bool dynamicTranslationEnabled = true;

  /// Supported canonical languages in the CivicFix municipal ecosystem.
  static const Set<String> supportedLanguages = {'en', 'hi', 'mr'};

  /// Default fallback language code.
  static const String defaultLanguage = 'en';

  /// Maximum allowed character length for translatable user fields (prevents payload abuse).
  static const int maxTranslatableLength = 2000;

  /// Default timeout for remote translation callable / backend endpoints.
  static const Duration defaultTimeout = Duration(seconds: 10);

  /// Default in-memory cache capacity.
  static const int defaultMemoryCacheCapacity = 500;

  /// Default maximum age for persistent translation cache entries.
  static const Duration cacheTtl = Duration(days: 30);
}
