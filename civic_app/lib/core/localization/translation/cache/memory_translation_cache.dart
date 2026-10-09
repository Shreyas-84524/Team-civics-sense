import '../models/translation_result.dart';
import 'translation_cache.dart';

/// Fast, in-memory implementation of [TranslationCache].
///
/// Ensures translated strings remain transient presentation data and are never
/// merged into Firestore complaint document schemas.
class MemoryTranslationCache implements TranslationCache {
  final Map<String, TranslationResult> _store = {};
  final int maxEntries;

  MemoryTranslationCache({this.maxEntries = 500});

  /// Builds a deterministic, canonical cache key.
  static String buildCacheKey({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    String? contentId,
    String? fieldName,
  }) {
    final target = targetLanguage.trim().toLowerCase();
    final source = (sourceLanguage ?? 'auto').trim().toLowerCase();
    final cId = (contentId != null && contentId.trim().isNotEmpty) ? contentId.trim() : 'generic';
    final field = (fieldName != null && fieldName.trim().isNotEmpty) ? fieldName.trim() : 'text';
    final textHash = text.trim().hashCode.toString();
    return '$cId:$field:$textHash:$source:$target';
  }

  @override
  Future<TranslationResult?> get(
    String text,
    String targetLanguage, {
    String? contentId,
    String? fieldName,
    String? sourceLanguage,
  }) async {
    final canonicalKey = buildCacheKey(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
      contentId: contentId,
      fieldName: fieldName,
    );
    final result = _store[canonicalKey];
    if (result != null) {
      return result.copyWith(isCached: true);
    }

    // Fallback search by textHash and targetLanguage
    final target = targetLanguage.trim().toLowerCase();
    final textHash = text.trim().hashCode.toString();
    for (final entry in _store.entries) {
      if (entry.key.contains(':$textHash:') && entry.key.endsWith(':$target')) {
        return entry.value.copyWith(isCached: true);
      }
    }

    return null;
  }

  @override
  Future<void> put(
    TranslationResult result, {
    String? contentId,
    String? fieldName,
  }) async {
    if (_store.length >= maxEntries) {
      // Evict oldest entry
      _store.remove(_store.keys.first);
    }
    final canonicalKey = buildCacheKey(
      text: result.originalText,
      targetLanguage: result.targetLanguage,
      sourceLanguage: result.originalLanguage,
      contentId: contentId,
      fieldName: fieldName,
    );
    _store[canonicalKey] = result.copyWith(isCached: true);
  }

  @override
  Future<void> invalidate(String text) async {
    final textHash = text.trim().hashCode.toString();
    _store.removeWhere((key, _) => key.contains(':$textHash:'));
  }

  @override
  Future<void> invalidateContent(String contentId, [String? fieldName]) async {
    final prefix = fieldName != null
        ? '${contentId.trim()}:${fieldName.trim()}:'
        : '${contentId.trim()}:';
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<int> get size async => _store.length;
}
