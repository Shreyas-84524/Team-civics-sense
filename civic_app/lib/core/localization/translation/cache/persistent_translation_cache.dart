import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/translation_result.dart';
import 'translation_cache.dart';

/// Persistent L2 cache for dynamic presentation translations.
///
/// Ensures translations generated once persist across app sessions and restarts,
/// preventing duplicate cloud API costs while keeping authoritative Firestore complaint
/// documents completely untouched and unmutated.
class PersistentTranslationCache implements TranslationCache {
  final Map<String, Map<String, dynamic>> _storage;
  final int schemaVersion;
  final int translationVersion;

  PersistentTranslationCache({
    Map<String, Map<String, dynamic>>? initialStorage,
    this.schemaVersion = 1,
    this.translationVersion = 1,
  }) : _storage = initialStorage ?? {};

  /// Computes deterministic SHA-256 hash for source text.
  static String computeSourceHash(String text) {
    return sha256.convert(utf8.encode(text.trim())).toString();
  }

  /// Computes privacy-conscious, deterministic document key for persistent cache entries.
  static String buildPersistentKey({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    String? contentType,
    int version = 1,
  }) {
    final sourceHash = computeSourceHash(text);
    final target = targetLanguage.trim().toLowerCase();
    final source = (sourceLanguage ?? 'auto').trim().toLowerCase();
    final type = (contentType ?? 'generic').trim().toLowerCase();
    final seed = '$type:$sourceHash:$source:$target:v$version';
    return sha256.convert(utf8.encode(seed)).toString();
  }

  @override
  Future<TranslationResult?> get(
    String text,
    String targetLanguage, {
    String? contentId,
    String? fieldName,
    String? sourceLanguage,
  }) async {
    final rawText = text.trim();
    if (rawText.isEmpty) return null;

    final key = buildPersistentKey(
      text: rawText,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
      version: translationVersion,
    );

    final record = _storage[key];
    if (record == null) {
      // Secondary fallback scan by sourceHash and targetLanguage matching
      final sourceHash = computeSourceHash(rawText);
      final target = targetLanguage.trim().toLowerCase();
      for (final entry in _storage.values) {
        if (entry['sourceHash'] == sourceHash &&
            entry['targetLanguage'] == target &&
            entry['translationVersion'] == translationVersion) {
          return TranslationResult(
            originalText: entry['originalText'] as String? ?? text,
            originalLanguage: entry['sourceLanguage'] as String? ?? entry['originalLanguage'] as String? ?? sourceLanguage ?? 'auto',
            targetLanguage: entry['targetLanguage'] as String? ?? targetLanguage,
            translatedText: entry['translatedText'] as String? ?? text,
            provider: entry['provider'] as String? ?? 'persistent_cache',
            translatedAt: entry['translatedAt'] != null
                ? DateTime.tryParse(entry['translatedAt'] as String) ?? DateTime.now()
                : DateTime.now(),
            confidence: (entry['confidence'] as num?)?.toDouble() ?? 0.95,
            isCached: true,
          );
        }
      }
      return null;
    }

    // Source-hash validation: ensure source text has not changed
    final sourceHash = computeSourceHash(rawText);
    if (record['sourceHash'] != sourceHash) {
      // Stale entry: invalidate immediately
      _storage.remove(key);
      return null;
    }

    return TranslationResult(
      originalText: record['originalText'] as String? ?? text,
      originalLanguage: record['sourceLanguage'] as String? ?? record['originalLanguage'] as String? ?? sourceLanguage ?? 'auto',
      targetLanguage: record['targetLanguage'] as String? ?? targetLanguage,
      translatedText: record['translatedText'] as String? ?? text,
      provider: record['provider'] as String? ?? 'persistent_cache',
      translatedAt: record['translatedAt'] != null
          ? DateTime.tryParse(record['translatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      confidence: (record['confidence'] as num?)?.toDouble() ?? 0.95,
      isCached: true,
    );
  }

  @override
  Future<void> put(
    TranslationResult result, {
    String? contentId,
    String? fieldName,
  }) async {
    final key = buildPersistentKey(
      text: result.originalText,
      targetLanguage: result.targetLanguage,
      sourceLanguage: result.originalLanguage,
      version: translationVersion,
    );

    _storage[key] = {
      'cacheKey': key,
      'contentId': contentId,
      'fieldName': fieldName,
      'sourceHash': computeSourceHash(result.originalText),
      'originalText': result.originalText,
      'sourceLanguage': result.originalLanguage,
      'originalLanguage': result.originalLanguage,
      'targetLanguage': result.targetLanguage,
      'translatedText': result.translatedText,
      'provider': result.provider,
      'confidence': result.confidence ?? 0.95,
      'schemaVersion': schemaVersion,
      'translationVersion': translationVersion,
      'translatedAt': result.translatedAt.toIso8601String(),
      'isCached': true,
    };
  }

  @override
  Future<void> invalidate(String text) async {
    final sourceHash = computeSourceHash(text);
    _storage.removeWhere((_, value) => value['sourceHash'] == sourceHash);
  }

  @override
  Future<void> invalidateContent(String contentId, [String? fieldName]) async {
    _storage.removeWhere((_, value) {
      if (value['contentId'] != contentId) return false;
      if (fieldName != null && value['fieldName'] != fieldName) return false;
      return true;
    });
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<int> get size async => _storage.length;

  /// Exposes current raw storage snapshot (useful for testing and disk serialization).
  Map<String, Map<String, dynamic>> get snapshot => Map.unmodifiable(_storage);
}
