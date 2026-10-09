import '../models/translation_request.dart';
import '../models/translation_result.dart';

/// Abstract service interface for dynamic text translation.
///
/// Implementations may encapsulate on-device ML models (e.g. IndicTrans2 via ONNX / TFLite),
/// cloud AI endpoints (e.g. Gemini 1.5 Flash), Google Cloud Translation, or local test fixtures.
abstract class TranslationService {
  /// Translates a single text request.
  Future<TranslationResult> translate(TranslationRequest request);

  /// Translates a batch of text requests efficiently.
  Future<List<TranslationResult>> translateBatch(List<TranslationRequest> requests);

  /// Determines if a specific language code is supported by this translation engine.
  Future<bool> isLanguageSupported(String languageCode);

  /// Automatically detects the language code of the provided text.
  Future<String> detectLanguage(String text);

  /// Human-readable identifier of the underlying provider.
  String get providerName;
}
