import 'translation_result.dart';

/// Presentation-layer wrapper that encapsulates authoritative, immutable user content
/// along with transient, cached translations.
///
/// HARD ARCHITECTURAL INVARIANT:
/// 1. [rawOriginalText] is the authoritative source of truth. It represents the exact text
///    submitted by citizens or municipal officers.
/// 2. [rawOriginalText] MUST NEVER BE OVERWRITTEN, MUTATED, OR REPLACED by translated text.
/// 3. Translations are stored exclusively in the presentation layer [cachedTranslations] map.
/// 4. When writing back to Firestore or local Hive storage, ONLY [rawOriginalText] is saved to
///    canonical complaint document fields (`title`, `description`, `citizenRemarks`, etc.).
class TranslatableContent {
  /// Authoritative immutable original text entered by the user or officer.
  final String rawOriginalText;

  /// ISO 639-1 code of the original text language ('en', 'hi', 'mr', etc.).
  final String detectedLanguage;

  /// In-memory / presentation cache mapping target language codes to translated strings.
  /// Format: `{'hi': '...', 'mr': '...'}`.
  final Map<String, String> cachedTranslations;

  const TranslatableContent({
    required this.rawOriginalText,
    this.detectedLanguage = 'en',
    this.cachedTranslations = const <String, String>{},
  });

  /// Factory initializing content with no translations yet.
  factory TranslatableContent.fromOriginal(String text, {String detectedLanguage = 'en'}) {
    return TranslatableContent(
      rawOriginalText: text,
      detectedLanguage: detectedLanguage,
      cachedTranslations: const {},
    );
  }

  /// Returns the presentation text for the given [targetLanguageCode].
  ///
  /// If the target matches [detectedLanguage] or no translation is cached,
  /// safely falls back to [rawOriginalText].
  String textFor(String targetLanguageCode) {
    final normalized = targetLanguageCode.trim().toLowerCase();
    if (normalized == detectedLanguage.toLowerCase()) {
      return rawOriginalText;
    }
    return cachedTranslations[normalized] ?? rawOriginalText;
  }

  /// True if a translation exists for [targetLanguageCode].
  bool hasTranslationFor(String targetLanguageCode) {
    final normalized = targetLanguageCode.trim().toLowerCase();
    return normalized == detectedLanguage.toLowerCase() ||
        cachedTranslations.containsKey(normalized);
  }

  /// Creates a new [TranslatableContent] with an added translation while keeping
  /// [rawOriginalText] 100% immutable and unchanged.
  TranslatableContent withTranslation({
    required String targetLanguageCode,
    required String translatedText,
  }) {
    final updatedMap = Map<String, String>.from(cachedTranslations);
    updatedMap[targetLanguageCode.trim().toLowerCase()] = translatedText;
    return TranslatableContent(
      rawOriginalText: rawOriginalText,
      detectedLanguage: detectedLanguage,
      cachedTranslations: Map.unmodifiable(updatedMap),
    );
  }

  /// Creates a new [TranslatableContent] incorporating a [TranslationResult].
  TranslatableContent withResult(TranslationResult result) {
    return withTranslation(
      targetLanguageCode: result.targetLanguage,
      translatedText: result.translatedText,
    );
  }

  @override
  String toString() =>
      'TranslatableContent(rawLength: ${rawOriginalText.length}, lang: $detectedLanguage, translations: ${cachedTranslations.keys.toList()})';
}
