/// Language configuration and metadata for Text-to-Speech (TTS) speech synthesis.
///
/// Ensures future/existing read-aloud controls use the appropriate regional voice engine
/// and strictly read whichever text version (translated vs original) is currently visible on screen.
class TtsLanguageConfig {
  TtsLanguageConfig._();

  /// Maps CivicFix ISO-639-1 language code to the appropriate BCP-47 speech synthesis locale tag.
  static String resolveTtsLocale(String languageCode) {
    final clean = languageCode.trim().toLowerCase();
    switch (clean) {
      case 'hi':
      case 'hi_in':
      case 'hi-in':
        return 'hi-IN';
      case 'mr':
      case 'mr_in':
      case 'mr-in':
        return 'mr-IN';
      case 'en':
      case 'en_in':
      case 'en-in':
      default:
        return 'en-IN';
    }
  }

  /// Resolves the text and voice locale to be read aloud based on the active UI view state.
  ///
  /// RULE:
  /// - If translated text is currently visible -> speak the translated text in the target language voice.
  /// - If user toggled to "View Original" -> speak the verbatim original text in the source language voice.
  static ({String textToSpeak, String speechLocale}) resolveSpeechPayload({
    required String originalText,
    required String sourceLanguage,
    required String targetLanguage,
    String? translatedText,
    bool isViewingOriginal = false,
  }) {
    if (isViewingOriginal || translatedText == null || translatedText.trim().isEmpty) {
      return (
        textToSpeak: originalText,
        speechLocale: resolveTtsLocale(sourceLanguage),
      );
    }

    return (
      textToSpeak: translatedText,
      speechLocale: resolveTtsLocale(targetLanguage),
    );
  }
}
