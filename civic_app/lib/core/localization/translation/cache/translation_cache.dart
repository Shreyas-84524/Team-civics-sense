import '../models/translation_result.dart';

/// Interface for caching dynamic translations separately from canonical database documents.
abstract class TranslationCache {
  /// Retrieves a cached translation for the given text and target language code.
  Future<TranslationResult?> get(
    String text,
    String targetLanguage, {
    String? contentId,
    String? fieldName,
    String? sourceLanguage,
  });

  /// Stores a translation result in cache.
  Future<void> put(
    TranslationResult result, {
    String? contentId,
    String? fieldName,
  });

  /// Invalidates cache entries for a specific text across all languages.
  Future<void> invalidate(String text);

  /// Invalidates cache entries for a specific content ID and optional field name.
  Future<void> invalidateContent(String contentId, [String? fieldName]);

  /// Completely clears the cache.
  Future<void> clear();

  /// Total number of cached translation entries.
  Future<int> get size;
}
