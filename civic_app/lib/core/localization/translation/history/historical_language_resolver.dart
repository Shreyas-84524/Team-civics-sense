import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/translation_constants.dart';
import '../models/translatable_content.dart';
import '../utils/language_detector.dart';

/// Historical Record Classification categories per CivicFix Multilingual Rollout Specification.
enum HistoricalDataCategory {
  /// Category A: Explicit source-language metadata exists on the record.
  explicitMetadata,

  /// Category B: No explicit metadata, but text is confidently detectable (en, hi, mr).
  confidentDetectable,

  /// Category C: Mixed-language content (e.g. English + Marathi, Latin + Devanagari scripts).
  mixedLanguage,

  /// Category D: Uncertain / ambiguous language (e.g. pure numbers, punctuation, short acronyms).
  uncertain,

  /// Category E: Empty or null optional human-text field.
  emptyOrNull,
}

/// Result of historical source-language resolution and audit classification.
class HistoricalResolutionResult {
  final String sourceLanguage;
  final double confidence;
  final HistoricalDataCategory category;
  final String sourceHash;
  final bool isFromCache;
  final String? originalText;

  const HistoricalResolutionResult({
    required this.sourceLanguage,
    required this.confidence,
    required this.category,
    required this.sourceHash,
    this.isFromCache = false,
    this.originalText,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourceLanguage': sourceLanguage,
      'confidence': confidence,
      'category': category.name,
      'sourceHash': sourceHash,
      'isFromCache': isFromCache,
      if (originalText != null) 'originalText': originalText,
    };
  }
}

/// Resolves source language for historical and legacy complaint content without altering original records.
///
/// Priority Order:
/// 1. Explicit trusted source-language metadata -> use it immediately.
/// 2. Cached detection result for matching sourceHash -> reuse it.
/// 3. LanguageDetector detection -> evaluate script and token frequencies.
/// 4. Confident 'en', 'hi', or 'mr' -> use detected language.
/// 5. Uncertain / ambiguous -> preserve original and fallback to 'auto' to avoid forced/hallucinated translation.
class HistoricalLanguageResolver {
  static final Map<String, HistoricalResolutionResult> _detectionCache = {};

  /// Computes deterministic SHA-256 source hash for language detection caching.
  static String computeSourceHash(String text) {
    return sha256.convert(utf8.encode(text.trim())).toString();
  }

  /// Resolves the source language for a given text or translatable content.
  static HistoricalResolutionResult resolve({
    required String? text,
    String? explicitLanguage,
    String? contentId,
    String? fieldName,
  }) {
    final raw = text?.trim() ?? '';
    final hash = computeSourceHash(raw);

    // Category E: Empty or null text
    if (raw.isEmpty) {
      return HistoricalResolutionResult(
        sourceLanguage: TranslationConstants.defaultLanguage,
        confidence: 1.0,
        category: HistoricalDataCategory.emptyOrNull,
        sourceHash: hash,
        originalText: text,
      );
    }

    // Step 1: Explicit trusted metadata (Category A)
    if (explicitLanguage != null &&
        explicitLanguage.trim().isNotEmpty &&
        TranslationConstants.supportedLanguages.contains(explicitLanguage.trim().toLowerCase())) {
      final lang = explicitLanguage.trim().toLowerCase();
      final result = HistoricalResolutionResult(
        sourceLanguage: lang,
        confidence: 1.0,
        category: HistoricalDataCategory.explicitMetadata,
        sourceHash: hash,
        originalText: text,
      );
      _detectionCache[hash] = result;
      return result;
    }

    // Step 2: Cached detection result (Avoids re-evaluating unchanged historical records)
    final cached = _detectionCache[hash];
    if (cached != null) {
      return HistoricalResolutionResult(
        sourceLanguage: cached.sourceLanguage,
        confidence: cached.confidence,
        category: cached.category,
        sourceHash: hash,
        isFromCache: true,
        originalText: text,
      );
    }

    // Step 3 & 4: Dynamic detection & classification
    final classifiedCategory = classifyContent(raw);
    final detected = LanguageDetector.detect(raw);
    final detectedCode = detected.code.toLowerCase();

    String finalLanguage;
    double finalConfidence;

    if (classifiedCategory == HistoricalDataCategory.emptyOrNull ||
        classifiedCategory == HistoricalDataCategory.uncertain) {
      // Step 5: Uncertain -> preserve original, fallback safely to 'auto'
      finalLanguage = 'auto';
      finalConfidence = 0.5;
    } else if (classifiedCategory == HistoricalDataCategory.mixedLanguage) {
      // Mixed language -> use dominant detected language
      finalLanguage = TranslationConstants.supportedLanguages.contains(detectedCode)
          ? detectedCode
          : TranslationConstants.defaultLanguage;
      finalConfidence = detected.confidence.clamp(0.6, 0.85);
    } else {
      // Confident single language
      finalLanguage = TranslationConstants.supportedLanguages.contains(detectedCode)
          ? detectedCode
          : TranslationConstants.defaultLanguage;
      finalConfidence = detected.confidence;
    }

    final result = HistoricalResolutionResult(
      sourceLanguage: finalLanguage,
      confidence: finalConfidence,
      category: classifiedCategory,
      sourceHash: hash,
      originalText: text,
    );

    _detectionCache[hash] = result;
    return result;
  }

  /// Classifies arbitrary historical text into Category A-E.
  static HistoricalDataCategory classifyContent(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return HistoricalDataCategory.emptyOrNull;

    // Check if purely numbers, punctuation, or ticket IDs
    final hasLetters = RegExp(r'[a-zA-Z\u0900-\u097F]').hasMatch(raw);
    if (!hasLetters) {
      return HistoricalDataCategory.uncertain;
    }

    // Check if very short acronym or code
    if (raw.length <= 3 && !RegExp(r'[\u0900-\u097F]').hasMatch(raw)) {
      return HistoricalDataCategory.uncertain;
    }

    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(raw);
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(raw);

    // Mixed script (e.g. Latin proper noun + Devanagari text)
    if (hasDevanagari && hasLatin) {
      return HistoricalDataCategory.mixedLanguage;
    }

    // Single script -> confident detection
    return HistoricalDataCategory.confidentDetectable;
  }

  /// Resolves translatable content wrapper.
  static TranslatableContent wrapTranslatable({
    required String? text,
    String? explicitLanguage,
    String? contentId,
    String? fieldName,
  }) {
    final res = resolve(
      text: text,
      explicitLanguage: explicitLanguage,
      contentId: contentId,
      fieldName: fieldName,
    );

    return TranslatableContent(
      rawOriginalText: text ?? '',
      detectedLanguage: res.sourceLanguage == 'auto' ? TranslationConstants.defaultLanguage : res.sourceLanguage,
    );
  }

  /// Clears the in-memory detection cache (for testing/maintenance).
  static void clearDetectionCache() {
    _detectionCache.clear();
  }

  /// Returns size of current detection cache.
  static int get detectionCacheSize => _detectionCache.length;
}
