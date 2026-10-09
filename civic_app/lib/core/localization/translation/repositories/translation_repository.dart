import '../cache/memory_translation_cache.dart';
import '../cache/translation_cache.dart';
import '../cache/two_level_translation_cache.dart';
import '../constants/translation_constants.dart';
import '../history/historical_language_resolver.dart';
import '../models/translatable_content.dart';
import '../models/translation_request.dart';
import '../models/translation_result.dart';
import '../services/remote_translation_service.dart';
import '../services/translation_service.dart';
import '../utils/language_detector.dart';

/// Repository interface coordinating dynamic translation requests, cache retrieval,
/// in-flight deduplication, and presentation layer translation resolution.
abstract class TranslationRepository {
  /// Translates text according to [request], checking cache first if [useCache] is true.
  Future<TranslationResult> translate(TranslationRequest request, {bool useCache = true});

  /// Batch translates multiple requests.
  Future<List<TranslationResult>> translateBatch(
    List<TranslationRequest> requests, {
    bool useCache = true,
  });

  /// Translates a [TranslatableContent] wrapper to [targetLanguageCode], preserving original text.
  Future<TranslatableContent> translateContent(
    TranslatableContent content,
    String targetLanguageCode, {
    String? contentCategory,
  });

  /// The underlying cache instance.
  TranslationCache get cache;

  /// The underlying translation service instance.
  TranslationService get service;
}

/// Default implementation of [TranslationRepository] with request coalescing,
/// two-level persistent caching, and safe source language resolution.
class DefaultTranslationRepository implements TranslationRepository {
  static DefaultTranslationRepository? _instance;

  /// Global shared instance for application-wide presentation layer translation.
  static DefaultTranslationRepository get instance {
    _instance ??= DefaultTranslationRepository();
    return _instance!;
  }

  /// Sets or resets the global shared instance (useful for testing or swapping providers).
  static set instance(DefaultTranslationRepository repo) {
    _instance = repo;
  }

  final TranslationService _service;
  final TranslationCache _cache;
  final Map<String, Future<TranslationResult>> _inFlight = {};

  DefaultTranslationRepository({
    TranslationService? service,
    TranslationCache? cache,
  })  : _service = service ?? const RemoteTranslationService(),
        _cache = cache ?? TwoLevelTranslationCache();

  @override
  TranslationCache get cache => _cache;

  @override
  TranslationService get service => _service;

  @override
  Future<TranslationResult> translate(TranslationRequest request, {bool useCache = true}) async {
    if (!request.isValid) {
      return TranslationResult.identity(
        text: request.originalText,
        language: request.targetLanguage,
      );
    }

    // Feature Flag / Kill-Switch Check
    if (!TranslationConstants.dynamicTranslationEnabled) {
      return TranslationResult.identity(
        text: request.originalText,
        language: request.targetLanguage,
        provider: 'feature_flag_disabled',
      );
    }

    // Resolve source language via HistoricalLanguageResolver priority chain
    final resolved = HistoricalLanguageResolver.resolve(
      text: request.originalText,
      explicitLanguage: request.sourceLanguage,
      contentId: request.contentId,
      fieldName: request.fieldName,
    );
    final sourceLang = resolved.sourceLanguage == 'auto'
        ? (LanguageDetector.detect(request.originalText).code)
        : resolved.sourceLanguage;

    final resolvedRequest = request.copyWith(sourceLanguage: sourceLang);

    if (resolvedRequest.isSameLanguage) {
      return TranslationResult.identity(
        text: resolvedRequest.originalText,
        language: resolvedRequest.targetLanguage,
      );
    }

    if (useCache) {
      try {
        final cached = await _cache.get(
          resolvedRequest.originalText,
          resolvedRequest.targetLanguage,
          contentId: resolvedRequest.contentId,
          fieldName: resolvedRequest.fieldName,
          sourceLanguage: resolvedRequest.sourceLanguage,
        );
        if (cached != null) {
          return cached;
        }
      } catch (_) {
        // Cache read failure resilience: continue to provider seamlessly
      }
    }

    // Request Deduplication (Coalescing)
    final dedupeKey = MemoryTranslationCache.buildCacheKey(
      text: resolvedRequest.originalText,
      targetLanguage: resolvedRequest.targetLanguage,
      sourceLanguage: resolvedRequest.sourceLanguage,
      contentId: resolvedRequest.contentId,
      fieldName: resolvedRequest.fieldName,
    );

    if (_inFlight.containsKey(dedupeKey)) {
      return await _inFlight[dedupeKey]!;
    }

    final future = _executeTranslation(resolvedRequest);
    _inFlight[dedupeKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlight.remove(dedupeKey);
    }
  }

  Future<TranslationResult> _executeTranslation(TranslationRequest request) async {
    final freshResult = await _service.translate(request);
    try {
      await _cache.put(
        freshResult,
        contentId: request.contentId,
        fieldName: request.fieldName,
      );
    } catch (_) {
      // Cache write failure resilience: do not block UI
    }
    return freshResult;
  }

  @override
  Future<List<TranslationResult>> translateBatch(
    List<TranslationRequest> requests, {
    bool useCache = true,
  }) async {
    final results = <TranslationResult>[];
    for (final request in requests) {
      final res = await translate(request, useCache: useCache);
      results.add(res);
    }
    return results;
  }

  @override
  Future<TranslatableContent> translateContent(
    TranslatableContent content,
    String targetLanguageCode, {
    String? contentCategory,
  }) async {
    final normalized = targetLanguageCode.trim().toLowerCase();
    if (content.hasTranslationFor(normalized)) {
      return content;
    }

    final result = await translate(
      TranslationRequest(
        originalText: content.rawOriginalText,
        targetLanguage: normalized,
        sourceLanguage: content.detectedLanguage,
        contentCategory: contentCategory,
      ),
    );

    return content.withResult(result);
  }
}
