import 'dart:convert';
import 'ai_authenticity_enums.dart';

/// Structured result of an AI-assisted image authenticity assessment.
///
/// This provides an advisory evaluation of whether an image appears to be a
/// genuine camera photograph, generative AI output, or uncertain.
///
/// NOTE: This is NOT forensic proof of image authenticity.
class AiAuthenticityResult {
  /// Assessed authenticity status.
  final AiAuthenticityStatus status;

  /// Normalized confidence score between 0.0 and 1.0.
  ///
  /// Represents Gemini's confidence in its visual observation, NOT mathematical proof.
  final double confidence;

  /// Concise human-readable explanation of visual characteristics observed.
  final String reasoning;

  /// Structured list of short visual indicators observed in the image.
  final List<String> indicators;

  /// The Gemini model identifier used for analysis.
  final String model;

  /// Timestamp when the analysis was performed.
  final DateTime analyzedAt;

  /// Whether the AI request executed successfully without a technical error.
  final bool isSuccess;

  /// Diagnostic error message if a technical failure occurred during analysis.
  final String? errorMessage;

  /// Raw textual response received from Gemini, if retained for debugging.
  final String? rawResponse;

  const AiAuthenticityResult({
    required this.status,
    required this.confidence,
    required this.reasoning,
    required this.indicators,
    required this.model,
    required this.analyzedAt,
    this.isSuccess = true,
    this.errorMessage,
    this.rawResponse,
  });

  /// Factory for creating an advisory failure result when an error occurs.
  ///
  /// Technical failures always default to [AiAuthenticityStatus.uncertain]
  /// and NEVER to [AiAuthenticityStatus.likelyAiGenerated].
  factory AiAuthenticityResult.failure(
    String errorMessage, {
    String model = 'unknown',
    DateTime? analyzedAt,
    String? rawResponse,
  }) {
    return AiAuthenticityResult(
      status: AiAuthenticityStatus.uncertain,
      confidence: 0.0,
      reasoning: 'Authenticity assessment could not be completed: $errorMessage',
      indicators: const [],
      model: model,
      analyzedAt: analyzedAt ?? DateTime.now(),
      isSuccess: false,
      errorMessage: errorMessage,
      rawResponse: rawResponse,
    );
  }

  /// Parses structured JSON map from Gemini or storage into [AiAuthenticityResult].
  factory AiAuthenticityResult.fromJson(
    Map<String, dynamic> json, {
    String model = 'unknown',
    DateTime? analyzedAt,
    String? rawResponse,
  }) {
    final statusStr = json['status']?.toString();
    final status = AiAuthenticityStatus.fromString(statusStr);

    final rawConfidence = json['confidence'];
    double parsedConfidence = 0.5;
    if (rawConfidence is num) {
      parsedConfidence = rawConfidence.toDouble().clamp(0.0, 1.0);
    } else if (rawConfidence is String) {
      final parsed = double.tryParse(rawConfidence);
      if (parsed != null) {
        parsedConfidence = parsed.clamp(0.0, 1.0);
      }
    }

    final reasoning = json['reasoning']?.toString().trim() ??
        'No detailed reasoning provided by the evaluation model.';

    final rawIndicators = json['indicators'];
    List<String> indicators = [];
    if (rawIndicators is List) {
      indicators = rawIndicators
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final parsedModel = json['model']?.toString() ?? model;

    DateTime timestamp = analyzedAt ?? DateTime.now();
    if (json['analyzedAt'] != null || json['analyzed_at'] != null) {
      final dateStr = (json['analyzedAt'] ?? json['analyzed_at']).toString();
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        timestamp = parsedDate;
      }
    }

    final bool parsedSuccess = json['isSuccess'] is bool
        ? json['isSuccess'] as bool
        : true;
    final String? parsedErrorMessage = json['errorMessage']?.toString();

    return AiAuthenticityResult(
      status: status,
      confidence: parsedConfidence,
      reasoning: reasoning,
      indicators: List.unmodifiable(indicators),
      model: parsedModel,
      analyzedAt: timestamp,
      isSuccess: parsedSuccess,
      errorMessage: parsedErrorMessage,
      rawResponse: rawResponse,
    );
  }

  /// Safely parses a JSON string into [AiAuthenticityResult], handling markdown backticks or errors.
  factory AiAuthenticityResult.fromJsonString(
    String jsonString, {
    String model = 'unknown',
    DateTime? analyzedAt,
  }) {
    try {
      var cleaned = jsonString.trim();

      // Strip markdown code fences if Gemini included them
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final decoded = json.decode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return AiAuthenticityResult.fromJson(
          decoded,
          model: model,
          analyzedAt: analyzedAt,
          rawResponse: jsonString,
        );
      }

      return AiAuthenticityResult.failure(
        'Gemini output was not a valid JSON object.',
        model: model,
        analyzedAt: analyzedAt,
        rawResponse: jsonString,
      );
    } catch (e) {
      return AiAuthenticityResult.failure(
        'Failed to parse Gemini authenticity response: $e',
        model: model,
        analyzedAt: analyzedAt,
        rawResponse: jsonString,
      );
    }
  }

  /// Factory for deserialization from a persistent map (e.g. Firestore / Hive / local storage).
  factory AiAuthenticityResult.fromMap(Map<String, dynamic> map) {
    return AiAuthenticityResult.fromJson(map);
  }

  /// Converts the authenticity result to a persistent map representation.
  Map<String, dynamic> toMap() {
    return {
      'status': status.rawValue,
      'confidence': confidence,
      'reasoning': reasoning,
      'indicators': indicators,
      'model': model,
      'analyzedAt': analyzedAt.toIso8601String(),
      'isSuccess': isSuccess,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  /// Alias for JSON encoding.
  Map<String, dynamic> toJsonMap() => toMap();

  /// Encodes this result into a JSON string.
  String toJson() => json.encode(toMap());

  /// Alias for JSON string encoding.
  String toJsonString() => toJson();

  /// Returns true if the image is assessed as likely a genuine photograph.
  bool get isLikelyReal => status == AiAuthenticityStatus.likelyReal;

  /// Returns true if the image is assessed as likely AI-generated or manipulated.
  bool get isLikelyAiGenerated => status == AiAuthenticityStatus.likelyAiGenerated;

  /// Returns true if the assessment is inconclusive or uncertain.
  bool get isUncertain => status == AiAuthenticityStatus.uncertain;

  @override
  String toString() {
    return 'AiAuthenticityResult('
        'status: ${status.rawValue}, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'reasoning: "$reasoning", '
        'indicators: $indicators, '
        'model: $model, '
        'analyzedAt: $analyzedAt)';
  }
}
