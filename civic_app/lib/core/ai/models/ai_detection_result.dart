import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../models/category_model.dart';
import 'ai_detection_enums.dart';

export 'ai_detection_enums.dart';

/// Strongly typed domain result representing multimodal AI civic verification analysis.
@immutable
class AiDetectionResult {
  /// Whether the AI verification completed successfully without technical or transport errors.
  final bool success;

  /// Canonical [CivicCategory] detected by the AI from visual evidence.
  final CivicCategory? detectedCategory;

  /// String identifier of the detected category (e.g., 'roads', 'waste', 'none').
  final String? detectedCategoryId;

  /// Confidence score for the detected category (0.0 to 1.0).
  final double? categoryConfidence;

  /// Advisory indicator: true if visible evidence matches the citizen-selected category.
  final bool? categoryMatch;

  /// Advisory indicator: true if the photo provides sufficiently clear, real-world evidence.
  final bool? isUsableEvidence;

  /// Assessed visual quality of the photo (poor, acceptable, good).
  final AiImageQuality? imageQuality;

  /// True if the image contains a visible civic or public safety hazard.
  final bool? isHazard;

  /// Classification of the visible hazard (e.g. pothole, garbage_overflow, none).
  final AiHazardType? hazardType;

  /// Urgency/severity rating of the hazard.
  final AiHazardSeverity? hazardSeverity;

  /// Confidence score for the hazard evaluation (0.0 to 1.0).
  final double? hazardConfidence;

  /// List of concise visible municipal or infrastructure objects/features (up to 10).
  final List<String> detectedObjects;

  /// Concise factual explanation from the AI model.
  final String? explanation;

  /// The raw textual or JSON response returned by the model.
  final String? rawResponse;

  /// Human-readable error message if analysis failed.
  final String? errorMessage;

  const AiDetectionResult({
    required this.success,
    this.detectedCategory,
    this.detectedCategoryId,
    this.categoryConfidence,
    this.categoryMatch,
    this.isUsableEvidence,
    this.imageQuality,
    this.isHazard,
    this.hazardType,
    this.hazardSeverity,
    this.hazardConfidence,
    this.detectedObjects = const <String>[],
    this.explanation,
    this.rawResponse,
    this.errorMessage,
  });

  /// Convenience getter indicating if the operation succeeded.
  bool get isSuccess => success;

  /// Convenience getter indicating if the operation failed.
  bool get isFailure => !success;

  /// Helper indicating if a hazard is confirmed present.
  bool get hasHazard => isHazard == true;

  /// Helper indicating if the category matches citizen selection.
  bool get matchesCategory => categoryMatch == true;

  /// Helper indicating if evidence is usable.
  bool get usable => isUsableEvidence == true;

  /// Factory constructor for a successful unstructured or lightweight Phase 2 response.
  factory AiDetectionResult.success(String response) {
    return AiDetectionResult(
      success: true,
      rawResponse: response.trim(),
    );
  }

  /// Factory constructor for a technical failure.
  ///
  /// Note: A technical AI failure must NOT be conflated with category mismatch or low quality.
  factory AiDetectionResult.failure(String errorMessage, {String? rawResponse}) {
    return AiDetectionResult(
      success: false,
      errorMessage: errorMessage,
      rawResponse: rawResponse,
    );
  }

  /// Parses structured JSON output from Gemini into a strongly typed [AiDetectionResult].
  factory AiDetectionResult.fromJson({
    required Map<String, dynamic> json,
    required String rawResponse,
    CivicCategory? selectedCategory,
  }) {
    // 1. Detected Category Resolution
    final rawCatId = (json['detected_category'] ?? json['detectedCategory'])?.toString().trim().toLowerCase();
    CivicCategory? matchedCategory;
    if (rawCatId != null && rawCatId.isNotEmpty && rawCatId != 'none') {
      matchedCategory = CivicCategory.defaultCategories.firstWhere(
        (c) => c.id.toLowerCase() == rawCatId || c.name.toLowerCase() == rawCatId,
        orElse: () => CivicCategory.defaultCategories.firstWhere(
          (c) => c.name.toLowerCase().contains(rawCatId) || rawCatId.contains(c.id.toLowerCase()),
          orElse: () => CivicCategory(
            id: rawCatId,
            name: rawCatId[0].toUpperCase() + rawCatId.substring(1),
            description: 'AI-identified civic category.',
            icon: CivicCategory.defaultCategories.last.icon,
          ),
        ),
      );
    }

    // 2. Confidences Parsing with Range Validation [0.0, 1.0]
    final catConf = _parseConfidence(json['category_confidence'] ?? json['categoryConfidence']);
    final hazConf = _parseConfidence(json['hazard_confidence'] ?? json['hazardConfidence']);

    // 3. Boolean Indicators
    final catMatch = _parseBool(json['category_match'] ?? json['categoryMatch']);
    final usableEv = _parseBool(json['is_usable_evidence'] ?? json['isUsableEvidence']);
    final isHaz = _parseBool(json['is_hazard'] ?? json['isHazard']);

    // 4. Enums
    final quality = AiImageQuality.fromString((json['image_quality'] ?? json['imageQuality'])?.toString());
    final hazType = AiHazardType.fromString((json['hazard_type'] ?? json['hazardType'])?.toString());
    final hazSev = AiHazardSeverity.fromString((json['hazard_severity'] ?? json['hazardSeverity'])?.toString());

    // 5. Detected Objects (max 10)
    final rawObjects = json['detected_objects'] ?? json['detectedObjects'];
    final List<String> objects = [];
    if (rawObjects is List) {
      for (final item in rawObjects) {
        final str = item?.toString().trim();
        if (str != null && str.isNotEmpty && !objects.contains(str)) {
          objects.add(str);
          if (objects.length >= 10) break;
        }
      }
    }

    // 6. Explanation
    final exp = (json['explanation'] ?? json['description'])?.toString().trim();

    return AiDetectionResult(
      success: true,
      detectedCategory: matchedCategory,
      detectedCategoryId: rawCatId,
      categoryConfidence: catConf,
      categoryMatch: catMatch,
      isUsableEvidence: usableEv,
      imageQuality: quality,
      isHazard: isHaz,
      hazardType: hazType,
      hazardSeverity: hazSev,
      hazardConfidence: hazConf,
      detectedObjects: List.unmodifiable(objects),
      explanation: exp,
      rawResponse: rawResponse,
    );
  }

  /// Parses JSON string safely into [AiDetectionResult].
  factory AiDetectionResult.fromJsonString({
    required String jsonString,
    CivicCategory? selectedCategory,
  }) {
    try {
      final decoded = jsonDecode(jsonString.trim());
      if (decoded is Map<String, dynamic>) {
        return AiDetectionResult.fromJson(
          json: decoded,
          rawResponse: jsonString,
          selectedCategory: selectedCategory,
        );
      } else if (decoded is Map) {
        return AiDetectionResult.fromJson(
          json: Map<String, dynamic>.from(decoded),
          rawResponse: jsonString,
          selectedCategory: selectedCategory,
        );
      }
      return AiDetectionResult.failure(
        'Gemini response format error: expected JSON Object but received ${decoded.runtimeType}',
        rawResponse: jsonString,
      );
    } catch (e) {
      return AiDetectionResult.failure(
        'Failed to parse structured JSON response: $e',
        rawResponse: jsonString,
      );
    }
  }

  static double? _parseConfidence(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final d = value.toDouble();
      if (d.isNaN || d.isInfinite) return null;
      return d.clamp(0.0, 1.0);
    }
    if (value is String) {
      final d = double.tryParse(value.trim());
      if (d == null || d.isNaN || d.isInfinite) return null;
      return d.clamp(0.0, 1.0);
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final clean = value.trim().toLowerCase();
      if (clean == 'true') return true;
      if (clean == 'false') return false;
    }
    return null;
  }

  @override
  String toString() {
    if (!success) {
      return 'AiDetectionResult(success: false, error: "$errorMessage")';
    }
    return 'AiDetectionResult('
        'success: true, '
        'category: ${detectedCategory?.name ?? detectedCategoryId}, '
        'confidence: $categoryConfidence, '
        'match: $categoryMatch, '
        'usable: $isUsableEvidence ($imageQuality), '
        'hazard: $isHazard ($hazardType / $hazardSeverity, conf: $hazardConfidence), '
        'objects: ${detectedObjects.length})';
  }
}
