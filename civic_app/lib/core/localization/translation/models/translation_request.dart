/// Represents a provider-agnostic request for dynamic content translation.
///
/// Designed to support future translation backends (e.g. Gemini, IndicTrans2, Google Translate)
/// without altering UI or data persistence contracts.
class TranslationRequest {
  /// The immutable raw user-entered or system-generated text to be translated.
  final String originalText;

  /// Target ISO 639-1 language code (e.g. 'en', 'hi', 'mr').
  final String targetLanguage;

  /// Source ISO 639-1 language code if known. If null, the provider will auto-detect.
  final String? sourceLanguage;

  /// Identifier of the entity containing this text (e.g. complaint ID 'CIV-1234').
  final String? contentId;

  /// Name of the field containing this text (e.g. 'title', 'description', 'reworkReason').
  final String? fieldName;

  /// Semantic content category to guide contextual translations.
  /// Examples: 'complaint_title', 'complaint_description', 'citizen_remarks',
  /// 'officer_instructions', 'resolution_remarks', 'blocked_reason', 'rework_reason'.
  final String? contentCategory;

  /// Optional metadata (e.g. municipal domain hint, glossary context).
  final Map<String, dynamic>? metadata;

  const TranslationRequest({
    required this.originalText,
    required this.targetLanguage,
    this.sourceLanguage,
    this.contentId,
    this.fieldName,
    this.contentCategory,
    this.metadata,
  });

  /// True if request has non-empty text and target language.
  bool get isValid => originalText.trim().isNotEmpty && targetLanguage.trim().isNotEmpty;

  /// True if source and target languages are explicitly identical.
  bool get isSameLanguage =>
      sourceLanguage != null &&
      sourceLanguage!.trim().toLowerCase() == targetLanguage.trim().toLowerCase();

  TranslationRequest copyWith({
    String? originalText,
    String? targetLanguage,
    String? sourceLanguage,
    String? contentId,
    String? fieldName,
    String? contentCategory,
    Map<String, dynamic>? metadata,
  }) {
    return TranslationRequest(
      originalText: originalText ?? this.originalText,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      contentId: contentId ?? this.contentId,
      fieldName: fieldName ?? this.fieldName,
      contentCategory: contentCategory ?? this.contentCategory,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'targetLanguage': targetLanguage,
      if (sourceLanguage != null) 'sourceLanguage': sourceLanguage,
      if (contentId != null) 'contentId': contentId,
      if (fieldName != null) 'fieldName': fieldName,
      if (contentCategory != null) 'contentCategory': contentCategory,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory TranslationRequest.fromJson(Map<String, dynamic> json) {
    return TranslationRequest(
      originalText: json['originalText'] as String? ?? '',
      targetLanguage: json['targetLanguage'] as String? ?? 'en',
      sourceLanguage: json['sourceLanguage'] as String?,
      contentId: json['contentId'] as String?,
      fieldName: json['fieldName'] as String?,
      contentCategory: json['contentCategory'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() =>
      'TranslationRequest(target: $targetLanguage, src: $sourceLanguage, id: $contentId, field: $fieldName, cat: $contentCategory, textLength: ${originalText.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationRequest &&
        other.originalText == originalText &&
        other.targetLanguage == targetLanguage &&
        other.sourceLanguage == sourceLanguage &&
        other.contentId == contentId &&
        other.fieldName == fieldName &&
        other.contentCategory == contentCategory;
  }

  @override
  int get hashCode => Object.hash(
        originalText,
        targetLanguage,
        sourceLanguage,
        contentId,
        fieldName,
        contentCategory,
      );
}
