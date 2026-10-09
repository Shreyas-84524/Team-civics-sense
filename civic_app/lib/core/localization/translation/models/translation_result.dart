/// Represents the output of a dynamic translation operation.
///
/// Encapsulates the immutable original text alongside the translated result,
/// translation metadata, target language, and translation provider information.
class TranslationResult {
  /// The authoritative, unmutated original text.
  final String originalText;

  /// ISO 639-1 code of the original text's language (detected or specified).
  final String originalLanguage;

  /// ISO 639-1 code of the target language.
  final String targetLanguage;

  /// Translated text output.
  final String translatedText;

  /// Identifier of the provider that performed the translation
  /// (e.g. 'identity', 'cache', 'memory', 'gemini', 'indictrans2', 'mock').
  final String provider;

  /// Timestamp when the translation was completed.
  final DateTime translatedAt;

  /// Confidence score between 0.0 and 1.0 (if provided by backend).
  final double? confidence;

  /// Whether this result was retrieved from local/remote translation cache.
  final bool isCached;

  const TranslationResult({
    required this.originalText,
    required this.originalLanguage,
    required this.targetLanguage,
    required this.translatedText,
    required this.provider,
    required this.translatedAt,
    this.confidence,
    this.isCached = false,
  });

  /// Factory for an identity/no-op translation (source and target match, or translation bypassed).
  factory TranslationResult.identity({
    required String text,
    required String language,
    String provider = 'identity',
  }) {
    return TranslationResult(
      originalText: text,
      originalLanguage: language,
      targetLanguage: language,
      translatedText: text,
      provider: provider,
      translatedAt: DateTime.now(),
      confidence: 1.0,
      isCached: false,
    );
  }

  /// True if translated text is identical to the original input.
  bool get isIdentity => originalText == translatedText;

  TranslationResult copyWith({
    String? originalText,
    String? originalLanguage,
    String? targetLanguage,
    String? translatedText,
    String? provider,
    DateTime? translatedAt,
    double? confidence,
    bool? isCached,
  }) {
    return TranslationResult(
      originalText: originalText ?? this.originalText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      translatedText: translatedText ?? this.translatedText,
      provider: provider ?? this.provider,
      translatedAt: translatedAt ?? this.translatedAt,
      confidence: confidence ?? this.confidence,
      isCached: isCached ?? this.isCached,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'originalLanguage': originalLanguage,
      'targetLanguage': targetLanguage,
      'translatedText': translatedText,
      'provider': provider,
      'translatedAt': translatedAt.toIso8601String(),
      if (confidence != null) 'confidence': confidence,
      'isCached': isCached,
    };
  }

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'] as String? ?? '',
      originalLanguage: json['originalLanguage'] as String? ?? 'en',
      targetLanguage: json['targetLanguage'] as String? ?? 'en',
      translatedText: json['translatedText'] as String? ?? '',
      provider: json['provider'] as String? ?? 'unknown',
      translatedAt: json['translatedAt'] != null
          ? DateTime.tryParse(json['translatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      isCached: json['isCached'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'TranslationResult($originalLanguage -> $targetLanguage, provider: $provider, cached: $isCached)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationResult &&
        other.originalText == originalText &&
        other.originalLanguage == originalLanguage &&
        other.targetLanguage == targetLanguage &&
        other.translatedText == translatedText &&
        other.provider == provider &&
        other.isCached == isCached;
  }

  @override
  int get hashCode => Object.hash(
        originalText,
        originalLanguage,
        targetLanguage,
        translatedText,
        provider,
        isCached,
      );
}
