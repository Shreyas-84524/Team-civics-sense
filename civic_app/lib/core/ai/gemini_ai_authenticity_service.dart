import 'dart:async';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ai_authenticity_service.dart';
import 'models/ai_authenticity_result.dart';
import 'prompts/ai_authenticity_prompt.dart';

/// Function signature for generating content, enabling testing without initializing Firebase.
typedef GenerateContentRunner = Future<GenerateContentResponse> Function(Iterable<Content> prompt);

/// Production implementation of [AiAuthenticityService] utilizing Firebase AI Logic & Gemini multimodal vision.
class GeminiAiAuthenticityService implements AiAuthenticityService {
  /// Default recommended Gemini model for fast multimodal visual authenticity assessment.
  static const String defaultModelName = 'gemini-3.6-flash';

  /// Standard request timeout for AI authenticity analysis.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Structured JSON response schema for image authenticity evaluation.
  static final Schema authenticityResponseSchema = Schema.object(
    properties: {
      'status': Schema.enumString(
        enumValues: const [
          'likely_real',
          'likely_ai_generated',
          'uncertain',
        ],
        description: 'Authenticity assessment: likely_real, likely_ai_generated, or uncertain.',
      ),
      'confidence': Schema.number(
        description: 'Normalized confidence score between 0.0 and 1.0 reflecting visual certainty.',
      ),
      'reasoning': Schema.string(
        description: 'Concise human-readable explanation of visual characteristics observed (1-3 sentences). Acknowledge visual inspection limitations.',
      ),
      'indicators': Schema.array(
        items: Schema.string(),
        description: 'Concise list of specific observed visual characteristics (e.g. natural texture, anomalous edges).',
      ),
    },
    optionalProperties: const [
      'confidence',
      'reasoning',
      'indicators',
    ],
  );

  final String _modelName;
  final Duration _timeout;
  final FirebaseAI? _firebaseAI;
  final GenerateContentRunner? _contentGenerator;
  final FirebaseApp? _firebaseApp;

  /// Creates a [GeminiAiAuthenticityService] configured with Firebase AI Logic.
  ///
  /// [modelName]: Gemini model identifier (defaults to [defaultModelName]).
  /// [timeout]: Request timeout duration (defaults to 30 seconds).
  /// [firebaseAI]: Optional custom [FirebaseAI] instance (useful for tests/mocking).
  /// [contentGenerator]: Optional runner function to execute content generation (useful for unit tests).
  /// [app]: Optional explicit [FirebaseApp].
  GeminiAiAuthenticityService({
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
      systemInstruction: Content.system(AiAuthenticityPrompt.systemInstruction),
      generationConfig: generationConfig,
    );
  }

  @override
  Future<AiAuthenticityResult> analyzeAuthenticity({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    // 1. Input Validation
    if (imageBytes.isEmpty) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Image byte array is empty.');
      return AiAuthenticityResult.failure(
        'Invalid image data: image bytes cannot be empty.',
        model: _modelName,
      );
    }

    final normalizedMime = _normalizeMimeType(mimeType);
    if (normalizedMime == null) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Unsupported MIME type "$mimeType".');
      return AiAuthenticityResult.failure(
        'Unsupported image format "$mimeType". Supported formats: JPEG, PNG, WEBP, HEIC.',
        model: _modelName,
      );
    }

    // 2. Structured Diagnostic Logging
    debugPrint('[CivicFix AI] Authenticity analysis started');
    debugPrint('[CivicFix AI] MIME type: $normalizedMime, Bytes: ${imageBytes.length}');

    final startTime = DateTime.now();

    try {
      final Uint8List byteData = imageBytes is Uint8List
          ? imageBytes
          : Uint8List.fromList(imageBytes);

      // 3. Build Multimodal Content with Structured Prompt
      final content = Content.multi([
        TextPart('${AiAuthenticityPrompt.systemInstruction}\n\n${AiAuthenticityPrompt.userPrompt}'),
        InlineDataPart(normalizedMime, byteData),
      ]);

      debugPrint('[CivicFix AI] Structured Gemini authenticity request dispatched');

      // 4. Execute AI Generation with Structured JSON Schema, Retry on Transient 500, & Timeout
      GenerateContentResponse? response;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final generator = _contentGenerator;
          if (generator != null) {
            response = await generator([content]).timeout(_timeout);
          } else {
            final model = _resolveModel(
              generationConfig: GenerationConfig(
                responseMimeType: 'application/json',
                responseSchema: authenticityResponseSchema,
                temperature: 0.1,
              ),
            );
            response = await model.generateContent([content]).timeout(_timeout);
          }
          break;
        } on FirebaseAIException catch (e) {
          if (attempt < 3 && (e.message.contains('500') || e.message.contains('high demand'))) {
            debugPrint('[CivicFix AI] Transient demand spike detected. Retrying attempt ${attempt + 1} after ${attempt * 2}s...');
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          rethrow;
        }
      }

      if (response == null) {
        return AiAuthenticityResult.failure(
          'Failed to obtain response from Gemini after retries.',
          model: _modelName,
          analyzedAt: startTime,
        );
      }

      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        debugPrint('[CivicFix AI] Authenticity analysis failed: Empty response received.');
        return AiAuthenticityResult.failure(
          'Gemini returned an empty response for the provided image.',
          model: _modelName,
          analyzedAt: startTime,
        );
      }

      debugPrint('[CivicFix AI] Structured response received');

      // 5. Safe JSON Parsing and Result Mapping
      final result = AiAuthenticityResult.fromJsonString(
        responseText,
        model: _modelName,
        analyzedAt: startTime,
      );

      if (result.isSuccess) {
        debugPrint('[CivicFix AI] Authenticity status: ${result.status.rawValue}');
        debugPrint('[CivicFix AI] Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
        debugPrint('[CivicFix AI] Indicators: ${result.indicators.join(", ")}');
        debugPrint('[CivicFix AI] Authenticity analysis completed');
      } else {
        debugPrint('[CivicFix AI] Authenticity parsing error: ${result.errorMessage}');
      }

      return result;
    } on TimeoutException {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Request timed out after ${_timeout.inSeconds}s.');
      return AiAuthenticityResult.failure(
        'AI authenticity analysis timed out. Please check your connection and try again.',
        model: _modelName,
        analyzedAt: startTime,
      );
    } on SocketException catch (e) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Network error: ${e.message}');
      return AiAuthenticityResult.failure(
        'Network error during AI authenticity analysis. Please verify your internet connection.',
        model: _modelName,
        analyzedAt: startTime,
      );
    } on QuotaExceeded catch (e) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Gemini quota exceeded (${e.message}).');
      return AiAuthenticityResult.failure(
        'AI service capacity temporarily exceeded. Please try again later.',
        model: _modelName,
        analyzedAt: startTime,
      );
    } on ServiceApiNotEnabled catch (e) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Firebase AI service not enabled (${e.message}).');
      return AiAuthenticityResult.failure(
        'Firebase AI service is not enabled for this project.',
        model: _modelName,
        analyzedAt: startTime,
      );
    } on InvalidApiKey catch (e) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Invalid API configuration (${e.message}).');
      return AiAuthenticityResult.failure(
        'Invalid Firebase AI authentication configuration.',
        model: _modelName,
        analyzedAt: startTime,
      );
    } on UnsupportedUserLocation {
      debugPrint('[CivicFix AI] Authenticity analysis failed: User location not supported.');
      return AiAuthenticityResult.failure(
        'Gemini visual analysis is not supported in the current geographic region.',
        model: _modelName,
        analyzedAt: startTime,
      );
    } on FirebaseAIException catch (e) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: FirebaseAI Exception: ${e.message}');
      return AiAuthenticityResult.failure(
        'Firebase AI verification failed: ${e.message}',
        model: _modelName,
        analyzedAt: startTime,
      );
    } on PlatformException catch (e) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Platform Error [${e.code}]: ${e.message}');
      return AiAuthenticityResult.failure(
        'Device platform error during AI analysis (${e.code}).',
        model: _modelName,
        analyzedAt: startTime,
      );
    } catch (e, stackTrace) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Unexpected Error: $e\n$stackTrace');
      return AiAuthenticityResult.failure(
        'An unexpected error occurred during authenticity analysis: $e',
        model: _modelName,
        analyzedAt: startTime,
      );
    }
  }

  @override
  Future<AiAuthenticityResult> analyzeAuthenticityFile(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('[CivicFix AI] Authenticity analysis failed: File does not exist at ${imageFile.path}');
        return AiAuthenticityResult.failure(
          'Image file does not exist at path: ${imageFile.path}',
          model: _modelName,
        );
      }

      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint('[CivicFix AI] Authenticity analysis failed: File is empty at ${imageFile.path}');
        return AiAuthenticityResult.failure(
          'Image file is empty: ${imageFile.path}',
          model: _modelName,
        );
      }

      final ext = imageFile.path.split('.').last.toLowerCase();
      String mimeType;
      switch (ext) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'heic':
        case 'heif':
          mimeType = 'image/heic';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          mimeType = 'image/jpeg';
          break;
      }

      return await analyzeAuthenticity(imageBytes: bytes, mimeType: mimeType);
    } catch (e) {
      debugPrint('[CivicFix AI] Authenticity analysis failed: Error reading file: $e');
      return AiAuthenticityResult.failure(
        'Failed to read image file: $e',
        model: _modelName,
      );
    }
  }

  /// Normalizes MIME type string to standard supported types.
  String? _normalizeMimeType(String mime) {
    final lower = mime.trim().toLowerCase();
    if (lower == 'image/jpeg' || lower == 'image/jpg' || lower == 'jpg' || lower == 'jpeg') {
      return 'image/jpeg';
    }
    if (lower == 'image/png' || lower == 'png') {
      return 'image/png';
    }
    if (lower == 'image/webp' || lower == 'webp') {
      return 'image/webp';
    }
    if (lower == 'image/heic' || lower == 'image/heif' || lower == 'heic') {
      return 'image/heic';
    }
    return null;
  }
}
