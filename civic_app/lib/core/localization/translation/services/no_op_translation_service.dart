import '../models/translation_request.dart';
import '../models/translation_result.dart';
import 'translation_service.dart';

/// Default Phase 1 implementation of [TranslationService].
///
/// Performs ZERO external network or API calls.
/// Returns identity results (original text preserved verbatim) for safe fallback and testing.
class NoOpTranslationService implements TranslationService {
  const NoOpTranslationService();

  @override
  String get providerName => 'no_op_phase1';

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    return TranslationResult(
      originalText: request.originalText,
      originalLanguage: request.sourceLanguage ?? 'en',
      targetLanguage: request.targetLanguage,
      translatedText: request.originalText,
      provider: providerName,
      translatedAt: DateTime.now(),
      confidence: 1.0,
      isCached: false,
    );
  }

  @override
  Future<List<TranslationResult>> translateBatch(List<TranslationRequest> requests) async {
    return Future.wait(requests.map(translate));
  }

  @override
  Future<bool> isLanguageSupported(String languageCode) async {
    final code = languageCode.trim().toLowerCase();
    return code == 'en' || code == 'hi' || code == 'mr';
  }

  @override
  Future<String> detectLanguage(String text) async {
    // Default assumption for Phase 1
    return 'en';
  }
}
