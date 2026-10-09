import '../models/translation_result.dart';
import 'memory_translation_cache.dart';
import 'persistent_translation_cache.dart';
import 'translation_cache.dart';

/// Two-Level Hierarchical Cache for dynamic presentation translations.
///
/// L1: MemoryTranslationCache (ultra-fast, per-session in-memory storage)
/// L2: PersistentTranslationCache (durable, multi-session persistent storage)
///
/// Workflow:
/// 1. Query L1 cache. On hit, return immediately.
/// 2. On L1 miss, query L2 persistent cache.
/// 3. On L2 hit, backfill L1 cache and return.
/// 4. On full miss, return null to trigger translation provider.
/// 5. On new translation, write simultaneously to both L1 and L2.
class TwoLevelTranslationCache implements TranslationCache {
  final MemoryTranslationCache l1;
  final PersistentTranslationCache l2;

  TwoLevelTranslationCache({
    MemoryTranslationCache? l1Cache,
    PersistentTranslationCache? l2Cache,
  })  : l1 = l1Cache ?? MemoryTranslationCache(),
        l2 = l2Cache ?? PersistentTranslationCache();

  @override
  Future<TranslationResult?> get(
    String text,
    String targetLanguage, {
    String? contentId,
    String? fieldName,
    String? sourceLanguage,
  }) async {
    // 1. Check L1 Memory Cache
    final l1Result = await l1.get(
      text,
      targetLanguage,
      contentId: contentId,
      fieldName: fieldName,
      sourceLanguage: sourceLanguage,
    );

    if (l1Result != null) {
      return l1Result.copyWith(isCached: true);
    }

    // 2. Check L2 Persistent Cache
    final l2Result = await l2.get(
      text,
      targetLanguage,
      contentId: contentId,
      fieldName: fieldName,
      sourceLanguage: sourceLanguage,
    );

    if (l2Result != null) {
      // Backfill L1 Memory Cache
      await l1.put(
        l2Result,
        contentId: contentId,
        fieldName: fieldName,
      );
      return l2Result.copyWith(isCached: true);
    }

    return null;
  }

  @override
  Future<void> put(
    TranslationResult result, {
    String? contentId,
    String? fieldName,
  }) async {
    // Write simultaneously to L1 and L2
    await l1.put(result, contentId: contentId, fieldName: fieldName);
    await l2.put(result, contentId: contentId, fieldName: fieldName);
  }

  @override
  Future<void> invalidate(String text) async {
    await l1.invalidate(text);
    await l2.invalidate(text);
  }

  @override
  Future<void> invalidateContent(String contentId, [String? fieldName]) async {
    await l1.invalidateContent(contentId, fieldName);
    await l2.invalidateContent(contentId, fieldName);
  }

  @override
  Future<void> clear() async {
    await l1.clear();
    await l2.clear();
  }

  @override
  Future<int> get size async => await l2.size;
}
