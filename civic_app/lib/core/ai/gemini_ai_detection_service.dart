import 'dart:async';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/category_model.dart';
import 'ai_detection_service.dart';
import 'models/ai_detection_result.dart';
import 'prompts/civic_verification_prompt.dart';

/// Function signature for generating content, enabling testing without initializing Firebase.
typedef GenerateContentRunner = Future<GenerateContentResponse> Function(Iterable<Content> prompt);

/// Production implementation of [AiDetectionService] utilizing Firebase AI Logic & Gemini multimodal vision.
@Deprecated('Gemini scope has been corrected to Authenticity Verification only. Use GeminiAiAuthenticityService instead.')
class GeminiAiDetectionService implements AiDetectionService {
  /// Default recommended Gemini model for fast multimodal civic visual analysis.
  static const String defaultModelName = 'gemini-3.6-flash';

  /// Standard request timeout for AI visual verification.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Structured JSON response schema for civic evidence verification.
  static final Schema civicResponseSchema = Schema.object(
    properties: {
      'detected_category': Schema.enumString(
        enumValues: const [
          'roads',
          'water',
          'sanitation',
          'waste',
          'streetlights',
          'drainage',
          'infrastructure',
          'traffic',
          'other',
          'none',
        ],
        description: 'The civic category most accurately identified in the image.',
      ),
      'category_confidence': Schema.number(
        description: 'Confidence score for detected civic category between 0.0 and 1.0.',
      ),
      'category_match': Schema.boolean(
        description: 'True if the image visually supports the citizen-selected category, false otherwise.',
      ),
      'is_usable_evidence': Schema.boolean(
        description: 'True if the image has adequate visual clarity and shows real-world context for civic grievance evaluation.',
      ),
      'image_quality': Schema.enumString(
        enumValues: const ['poor', 'acceptable', 'good'],
        description: 'Visual quality of the image based on lighting, blur, resolution, and clarity.',
      ),
      'is_hazard': Schema.boolean(
        description: 'True if the image depicts a civic public safety hazard or risk.',
      ),
      'hazard_type': Schema.enumString(
        enumValues: const [
          'pothole',
          'road_damage',
          'garbage_overflow',
          'open_drain',
          'waterlogging',
          'damaged_streetlight',
          'fallen_tree',
          'exposed_wire',
          'broken_public_infrastructure',
          'traffic_obstruction',
          'fire_or_smoke',
          'other',
          'none',
          'unknown',
        ],
        description: 'Specific classification of the visible civic hazard.',
      ),
      'hazard_severity': Schema.enumString(
        enumValues: const ['none', 'low', 'medium', 'high', 'unknown'],
        description: 'Assessed urgency/severity level of the visible hazard.',
      ),
      'hazard_confidence': Schema.number(
        description: 'Confidence score for hazard assessment between 0.0 and 1.0.',
      ),
      'detected_objects': Schema.array(
        items: Schema.string(),
        description: 'Concise list of up to 10 visible municipal, infrastructural, or environmental items/features.',
      ),
      'explanation': Schema.string(
        description: 'Concise factual explanation (1-3 sentences) summarizing what is visible.',
      ),
    },
    optionalProperties: const [
      'category_confidence',
      'hazard_confidence',
      'explanation',
    ],
  );

  final String _modelName;
  final Duration _timeout;
  final FirebaseAI? _firebaseAI;
  final GenerateContentRunner? _contentGenerator;
  final FirebaseApp? _firebaseApp;

  /// Creates a [GeminiAiDetectionService] configured with Firebase AI Logic.
  ///
  /// [modelName]: Gemini model identifier (defaults to [defaultModelName]).
  /// [timeout]: Request timeout duration (defaults to 30 seconds).
  /// [firebaseAI]: Optional custom [FirebaseAI] instance (useful for tests/mocking).
  /// [contentGenerator]: Optional runner function to execute content generation (useful for unit tests).
  /// [app]: Optional explicit [FirebaseApp].
  GeminiAiDetectionService({
    String modelName = defaultModelName,
    Duration timeout = defaultTimeout,
    FirebaseAI? firebaseAI,
    GenerateContentRunner? contentGenerator,
    FirebaseApp? app,
  })  : _modelName = modelName,
        _timeout = timeout,
        _firebaseAI = firebaseAI,
        _contentGenerator = contentGenerator,
        _firebaseApp = app;

  String get modelName => _modelName;

  /// Resolves the active [GenerativeModel] via Firebase AI Logic.
  GenerativeModel _resolveModel({GenerationConfig? generationConfig}) {
    final ai = _firebaseAI ??
        FirebaseAI.googleAI(
          app: _firebaseApp ?? (Firebase.apps.isNotEmpty ? Firebase.app() : null),
        );

    return ai.generativeModel(
      model: _modelName,
      generationConfig: generationConfig,
    );
  }

  @override
  Future<AiDetectionResult> verifyEvidence({
    required List<int> imageBytes,
    required String mimeType,
    required CivicCategory selectedCategory,
  }) async {
    // 1. Input Validation
    if (imageBytes.isEmpty) {
      debugPrint('[CivicFix AI] Validation Error: Image byte array is empty.');
      return AiDetectionResult.failure('Invalid image data: image bytes cannot be empty.');
    }

    final normalizedMime = _normalizeMimeType(mimeType);
    if (normalizedMime == null) {
      debugPrint('[CivicFix AI] Validation Error: Unsupported MIME type "$mimeType".');
      return AiDetectionResult.failure(
        'Unsupported image format "$mimeType". Supported formats: JPEG, PNG, WEBP, HEIC.',
      );
    }

    // 2. Structured Diagnostic Logging
    debugPrint('[CivicFix AI] Civic verification started');
    debugPrint('[CivicFix AI] Selected category: ${selectedCategory.name}');
    debugPrint('[CivicFix AI] MIME type: $normalizedMime');
    debugPrint('[CivicFix AI] Image bytes: ${imageBytes.length}');

    try {
      final Uint8List byteData = imageBytes is Uint8List
          ? imageBytes
          : Uint8List.fromList(imageBytes);

      // 3. Build Multimodal Content with Structured Prompt
      final promptText = CivicVerificationPrompt.buildPrompt(selectedCategory: selectedCategory);
      final content = Content.multi([
        TextPart(promptText),
        InlineDataPart(normalizedMime, byteData),
      ]);

      debugPrint('[CivicFix AI] Structured Gemini request dispatched');

      // 4. Execute AI Generation with Structured JSON Schema & Timeout
      final GenerateContentResponse response;
      final generator = _contentGenerator;
      if (generator != null) {
        response = await generator([content]).timeout(_timeout);
      } else {
        final model = _resolveModel(
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: civicResponseSchema,
            temperature: 0.1,
          ),
        );
        response = await model.generateContent([content]).timeout(_timeout);
      }

      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        debugPrint('[CivicFix AI] Response Received -> Empty or null text output.');
        return AiDetectionResult.failure(
          'Gemini returned an empty response for the provided image.',
        );
      }

      debugPrint('[CivicFix AI] Structured response received');

      // 5. Safe JSON Parsing and Result Mapping
      final result = AiDetectionResult.fromJsonString(
        jsonString: responseText,
        selectedCategory: selectedCategory,
      );

      if (result.isSuccess) {
        debugPrint('[CivicFix AI] Detected category: ${result.detectedCategory?.name ?? result.detectedCategoryId ?? "none"}');
        if (result.categoryConfidence != null) {
          debugPrint('[CivicFix AI] Category confidence: ${result.categoryConfidence!.toStringAsFixed(2)}');
        }
        debugPrint('[CivicFix AI] Category match: ${result.categoryMatch}');
        debugPrint('[CivicFix AI] Evidence usable: ${result.isUsableEvidence}');
        debugPrint('[CivicFix AI] Hazard: ${result.isHazard}');
        if (result.hazardType != null) {
          debugPrint('[CivicFix AI] Hazard type: ${result.hazardType!.rawValue}');
        }
        if (result.hazardSeverity != null) {
          debugPrint('[CivicFix AI] Hazard severity: ${result.hazardSeverity!.name}');
        }
        debugPrint('[CivicFix AI] Verification completed');
      } else {
        debugPrint('[CivicFix AI] Structured parsing error: ${result.errorMessage}');
      }

      return result;
    } on TimeoutException {
      debugPrint('[CivicFix AI] Error: Request timed out after ${_timeout.inSeconds}s.');
      return AiDetectionResult.failure(
        'AI verification timed out. Please check your connection and try again.',
      );
    } on SocketException catch (e) {
      debugPrint('[CivicFix AI] Network Error: ${e.message}');
      return AiDetectionResult.failure(
        'Network error during AI verification. Please verify your internet connection.',
      );
    } on QuotaExceeded catch (e) {
      debugPrint('[CivicFix AI] Error: Gemini quota exceeded (${e.message}).');
      return AiDetectionResult.failure(
        'AI verification service capacity temporarily exceeded. Please try again later.',
      );
    } on ServiceApiNotEnabled catch (e) {
      debugPrint('[CivicFix AI] Configuration Error: Firebase AI service not enabled (${e.message}).');
      return AiDetectionResult.failure(
        'Firebase AI service is not enabled for this project.',
      );
    } on InvalidApiKey catch (e) {
      debugPrint('[CivicFix AI] Auth Error: Invalid API configuration (${e.message}).');
      return AiDetectionResult.failure(
        'Invalid Firebase AI authentication configuration.',
      );
    } on UnsupportedUserLocation {
      debugPrint('[CivicFix AI] Region Error: User location not supported.');
      return AiDetectionResult.failure(
        'Gemini visual analysis is not supported in the current geographic region.',
      );
    } on FirebaseAIException catch (e) {
      debugPrint('[CivicFix AI] FirebaseAI Exception: ${e.message}');
      return AiDetectionResult.failure(
        'Firebase AI verification failed: ${e.message}',
      );
    } on PlatformException catch (e) {
      debugPrint('[CivicFix AI] Platform Error [${e.code}]: ${e.message}');
      return AiDetectionResult.failure(
        'Device platform error during AI verification (${e.code}).',
      );
    } catch (e, stackTrace) {
      debugPrint('[CivicFix AI] Unexpected Error during verification: $e\n$stackTrace');
      return AiDetectionResult.failure(
        'An unexpected error occurred during visual verification: $e',
      );
    }
  }

  @override
  Future<AiDetectionResult> analyzeImage({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    // 1. Input Validation
    if (imageBytes.isEmpty) {
      debugPrint('[CivicFix AI] Validation Error: Image byte array is empty.');
      return AiDetectionResult.failure('Invalid image data: image bytes cannot be empty.');
    }

    final normalizedMime = _normalizeMimeType(mimeType);
    if (normalizedMime == null) {
      debugPrint('[CivicFix AI] Validation Error: Unsupported MIME type "$mimeType".');
      return AiDetectionResult.failure(
        'Unsupported image format "$mimeType". Supported formats: JPEG, PNG, WEBP, HEIC.',
      );
    }

    // 2. Structured Diagnostic Logging
    debugPrint(
      '[CivicFix AI] Verification Started -> MIME: $normalizedMime | Size: ${imageBytes.length} bytes',
    );

    try {
      final Uint8List byteData = imageBytes is Uint8List
          ? imageBytes
          : Uint8List.fromList(imageBytes);

      // 3. Build Multimodal Content
      final content = Content.multi([
        TextPart(CivicVerificationPrompt.diagnosticPrompt),
        InlineDataPart(normalizedMime, byteData),
      ]);

      debugPrint('[CivicFix AI] Request Dispatched -> Model: $_modelName');

      // 4. Execute AI Generation with Timeout
      final GenerateContentResponse response;
      final generator = _contentGenerator;
      if (generator != null) {
        response = await generator([content]).timeout(_timeout);
      } else {
        final model = _resolveModel();
        response = await model.generateContent([content]).timeout(_timeout);
      }

      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        debugPrint('[CivicFix AI] Response Received -> Empty or null text output.');
        return AiDetectionResult.failure(
          'Gemini returned an empty response for the provided image.',
        );
      }

      // 5. Success Logging
      debugPrint(
        '[CivicFix AI] Response Received -> Length: ${responseText.length} characters',
      );
      debugPrint('[CivicFix AI] Verification Completed Successfully.');

      return AiDetectionResult.success(responseText);
    } on TimeoutException {
      debugPrint('[CivicFix AI] Error: Request timed out after ${_timeout.inSeconds}s.');
      return AiDetectionResult.failure(
        'AI verification timed out. Please check your connection and try again.',
      );
    } on SocketException catch (e) {
      debugPrint('[CivicFix AI] Network Error: ${e.message}');
      return AiDetectionResult.failure(
        'Network error during AI verification. Please verify your internet connection.',
      );
    } on QuotaExceeded catch (e) {
      debugPrint('[CivicFix AI] Error: Gemini quota exceeded (${e.message}).');
      return AiDetectionResult.failure(
        'AI verification service capacity temporarily exceeded. Please try again later.',
      );
    } on ServiceApiNotEnabled catch (e) {
      debugPrint('[CivicFix AI] Configuration Error: Firebase AI service not enabled (${e.message}).');
      return AiDetectionResult.failure(
        'Firebase AI service is not enabled for this project.',
      );
    } on InvalidApiKey catch (e) {
      debugPrint('[CivicFix AI] Auth Error: Invalid API configuration (${e.message}).');
      return AiDetectionResult.failure(
        'Invalid Firebase AI authentication configuration.',
      );
    } on UnsupportedUserLocation {
      debugPrint('[CivicFix AI] Region Error: User location not supported.');
      return AiDetectionResult.failure(
        'Gemini visual analysis is not supported in the current geographic region.',
      );
    } on FirebaseAIException catch (e) {
      debugPrint('[CivicFix AI] FirebaseAI Exception: ${e.message}');
      return AiDetectionResult.failure(
        'Firebase AI verification failed: ${e.message}',
      );
    } on PlatformException catch (e) {
      debugPrint('[CivicFix AI] Platform Error [${e.code}]: ${e.message}');
      return AiDetectionResult.failure(
        'Device platform error during AI verification (${e.code}).',
      );
    } catch (e, stackTrace) {
      debugPrint('[CivicFix AI] Unexpected Error during verification: $e\n$stackTrace');
      return AiDetectionResult.failure(
        'An unexpected error occurred during visual verification: $e',
      );
    }
  }

  /// Normalizes and validates MIME type against accepted formats.
  static String? _normalizeMimeType(String mime) {
    final clean = mime.trim().toLowerCase();
    switch (clean) {
      case 'image/jpeg':
      case 'image/jpg':
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'image/png':
      case 'png':
        return 'image/png';
      case 'image/webp':
      case 'webp':
        return 'image/webp';
      case 'image/heic':
      case 'heic':
        return 'image/heic';
      case 'image/heif':
      case 'heif':
        return 'image/heif';
      default:
        if (clean.startsWith('image/')) {
          return clean;
        }
        return null;
    }
  }
}
