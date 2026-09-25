import 'dart:async';
import 'dart:io';
import 'package:civic_app/core/ai/gemini_ai_authenticity_service.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_enums.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_result.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiAuthenticityEnums Tests', () {
    test('AiAuthenticityStatus fromString maps known variants correctly', () {
      expect(AiAuthenticityStatus.fromString('likely_real'), AiAuthenticityStatus.likelyReal);
      expect(AiAuthenticityStatus.fromString('likelyreal'), AiAuthenticityStatus.likelyReal);
      expect(AiAuthenticityStatus.fromString('real'), AiAuthenticityStatus.likelyReal);
      expect(AiAuthenticityStatus.fromString('authentic'), AiAuthenticityStatus.likelyReal);
      expect(AiAuthenticityStatus.fromString('photo'), AiAuthenticityStatus.likelyReal);

      expect(AiAuthenticityStatus.fromString('likely_ai_generated'), AiAuthenticityStatus.likelyAiGenerated);
      expect(AiAuthenticityStatus.fromString('likelyaigenerated'), AiAuthenticityStatus.likelyAiGenerated);
      expect(AiAuthenticityStatus.fromString('ai_generated'), AiAuthenticityStatus.likelyAiGenerated);
      expect(AiAuthenticityStatus.fromString('synthetic'), AiAuthenticityStatus.likelyAiGenerated);

      expect(AiAuthenticityStatus.fromString('uncertain'), AiAuthenticityStatus.uncertain);
      expect(AiAuthenticityStatus.fromString('inconclusive'), AiAuthenticityStatus.uncertain);
    });

    test('Step 14 Test 5: Invalid status safely falls back to uncertain', () {
      expect(AiAuthenticityStatus.fromString('definitely_fake'), AiAuthenticityStatus.uncertain);
      expect(AiAuthenticityStatus.fromString('100%_ai'), AiAuthenticityStatus.uncertain);
      expect(AiAuthenticityStatus.fromString(''), AiAuthenticityStatus.uncertain);
      expect(AiAuthenticityStatus.fromString(null), AiAuthenticityStatus.uncertain);
    });

    test('AiAuthenticityStatus properties and labels are properly formatted', () {
      expect(AiAuthenticityStatus.likelyReal.rawValue, 'likely_real');
      expect(AiAuthenticityStatus.likelyReal.label, 'Likely Real Photograph');

      expect(AiAuthenticityStatus.likelyAiGenerated.rawValue, 'likely_ai_generated');
      expect(AiAuthenticityStatus.likelyAiGenerated.label, 'Likely AI-Generated / Manipulated');

      expect(AiAuthenticityStatus.uncertain.rawValue, 'uncertain');
      expect(AiAuthenticityStatus.uncertain.label, 'Uncertain Origin');
    });
  });

  group('AiAuthenticityResult Serialization Tests', () {
    test('Step 14 Test 1: Parses likely_real response accurately', () {
      const jsonStr = '''
      {
        "status": "likely_real",
        "confidence": 0.9,
        "reasoning": "Natural photographic characteristics.",
        "indicators": ["natural texture", "consistent lighting"]
      }
      ''';

      final result = AiAuthenticityResult.fromJsonString(jsonStr, model: 'gemini-3.6-flash');

      expect(result.status, AiAuthenticityStatus.likelyReal);
      expect(result.isLikelyReal, isTrue);
      expect(result.isLikelyAiGenerated, isFalse);
      expect(result.isUncertain, isFalse);
      expect(result.confidence, 0.9);
      expect(result.reasoning, 'Natural photographic characteristics.');
      expect(result.indicators, ['natural texture', 'consistent lighting']);
      expect(result.model, 'gemini-3.6-flash');
      expect(result.isSuccess, isTrue);
    });

    test('Step 14 Test 2: Parses likely_ai_generated response accurately', () {
      const jsonStr = '''
      {
        "status": "likely_ai_generated",
        "confidence": 0.93,
        "reasoning": "Several visual inconsistencies are consistent with synthetic image generation.",
        "indicators": ["inconsistent text rendering", "unnatural object boundaries", "synthetic-looking textures"]
      }
      ''';

      final result = AiAuthenticityResult.fromJsonString(jsonStr, model: 'gemini-3.6-flash');

      expect(result.status, AiAuthenticityStatus.likelyAiGenerated);
      expect(result.isLikelyAiGenerated, isTrue);
      expect(result.isLikelyReal, isFalse);
      expect(result.isUncertain, isFalse);
      expect(result.confidence, 0.93);
      expect(result.reasoning, contains('synthetic image generation'));
      expect(result.indicators.length, 3);
      expect(result.indicators, contains('inconsistent text rendering'));
      expect(result.isSuccess, isTrue);
    });

    test('Step 14 Test 3: Parses uncertain response accurately', () {
      const jsonStr = '''
      {
        "status": "uncertain",
        "confidence": 0.42,
        "reasoning": "The available visual evidence is insufficient to reliably determine the image's origin.",
        "indicators": ["low resolution blur", "ambiguous textures"]
      }
      ''';

      final result = AiAuthenticityResult.fromJsonString(jsonStr, model: 'gemini-3.6-flash');

      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.isUncertain, isTrue);
      expect(result.isLikelyReal, isFalse);
      expect(result.isLikelyAiGenerated, isFalse);
      expect(result.confidence, 0.42);
      expect(result.indicators.length, 2);
      expect(result.isSuccess, isTrue);
    });

    test('Step 14 Test 4: Malformed JSON fails safely without crashing', () {
      const malformedJson = '<<< NOT JSON >>> This is an invalid text response';

      final result = AiAuthenticityResult.fromJsonString(malformedJson, model: 'gemini-3.6-flash');

      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.isUncertain, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Failed to parse Gemini authenticity response'));
    });

    test('Step 14 Test 5: Invalid status safely falls back to uncertain in result', () {
      const jsonStr = '''
      {
        "status": "definitely_fake",
        "confidence": 0.99,
        "reasoning": "Suspected fake",
        "indicators": []
      }
      ''';

      final result = AiAuthenticityResult.fromJsonString(jsonStr, model: 'gemini-3.6-flash');

      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.isUncertain, isTrue);
      expect(result.isLikelyAiGenerated, isFalse);
    });

    test('Parses markdown code block wrapped JSON safely', () {
      const wrappedJson = '''
```json
{
  "status": "likely_real",
  "confidence": 0.88,
  "reasoning": "Photographic noise and authentic camera depth of field present.",
  "indicators": ["sensor noise", "coherent reflections"]
}
```
''';

      final result = AiAuthenticityResult.fromJsonString(wrappedJson, model: 'gemini-3.6-flash');

      expect(result.status, AiAuthenticityStatus.likelyReal);
      expect(result.confidence, 0.88);
      expect(result.indicators, ['sensor noise', 'coherent reflections']);
    });

    test('Step 14 Test 7: toMap / fromMap roundtrip preserves all fields', () {
      final now = DateTime.now();
      final original = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.85,
        reasoning: 'Authentic photograph.',
        indicators: const ['natural texture', 'real noise'],
        model: 'gemini-3.6-flash',
        analyzedAt: now,
      );

      final map = original.toMap();
      expect(map['status'], 'likely_real');
      expect(map['confidence'], 0.85);
      expect(map['reasoning'], 'Authentic photograph.');
      expect(map['indicators'], ['natural texture', 'real noise']);
      expect(map['model'], 'gemini-3.6-flash');

      final reconstructed = AiAuthenticityResult.fromMap(map);
      expect(reconstructed.status, original.status);
      expect(reconstructed.confidence, original.confidence);
      expect(reconstructed.reasoning, original.reasoning);
      expect(reconstructed.indicators, original.indicators);
      expect(reconstructed.model, original.model);
    });
  });

  group('GeminiAiAuthenticityService Unit Tests with Mock Generator', () {
    test('Input validation: Empty bytes returns failure with uncertain status', () async {
      final service = GeminiAiAuthenticityService();
      final result = await service.analyzeAuthenticity(
        imageBytes: [],
        mimeType: 'image/jpeg',
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.errorMessage, contains('image bytes cannot be empty'));
    });

    test('Input validation: Unsupported MIME type returns failure with uncertain status', () async {
      final service = GeminiAiAuthenticityService();
      final result = await service.analyzeAuthenticity(
        imageBytes: [1, 2, 3, 4],
        mimeType: 'application/pdf',
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.errorMessage, contains('Unsupported image format'));
    });

    test('Normalizes MIME types correctly (e.g. image/jpg, PNG, webp)', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        return GenerateContentResponse(
          [
            Candidate(
              Content.model([
                TextPart('{"status": "likely_real", "confidence": 0.85, "reasoning": "Real.", "indicators": []}')
              ]),
              null,
              null,
              null,
              null,
            )
          ],
          null,
        );
      }

      final service = GeminiAiAuthenticityService(contentGenerator: mockRunner);
      final result = await service.analyzeAuthenticity(
        imageBytes: [0xFF, 0xD8, 0xFF],
        mimeType: 'image/jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(result.status, AiAuthenticityStatus.likelyReal);
    });

    test('Step 14 Test 6: Network failure (SocketException) fails safely as uncertain', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw const SocketException('No route to host');
      }

      final service = GeminiAiAuthenticityService(contentGenerator: mockRunner);
      final result = await service.analyzeAuthenticity(
        imageBytes: [1, 2, 3, 4],
        mimeType: 'image/jpeg',
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.isLikelyAiGenerated, isFalse);
      expect(result.errorMessage, contains('Network error'));
    });

    test('Step 14 Test 6: TimeoutException fails safely as uncertain', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw TimeoutException('Request timed out');
      }

      final service = GeminiAiAuthenticityService(contentGenerator: mockRunner);
      final result = await service.analyzeAuthenticity(
        imageBytes: [1, 2, 3, 4],
        mimeType: 'image/jpeg',
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.errorMessage, contains('timed out'));
    });

    test('Step 14 Test 6: QuotaExceeded fails safely as uncertain', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw QuotaExceeded('Resource has been exhausted');
      }

      final service = GeminiAiAuthenticityService(contentGenerator: mockRunner);
      final result = await service.analyzeAuthenticity(
        imageBytes: [1, 2, 3, 4],
        mimeType: 'image/jpeg',
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.errorMessage, contains('capacity temporarily exceeded'));
    });

    test('PlatformException fails safely as uncertain without crashing', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw PlatformException(code: 'APP_CHECK_FAILED', message: 'Token rejected');
      }

      final service = GeminiAiAuthenticityService(contentGenerator: mockRunner);
      final result = await service.analyzeAuthenticity(
        imageBytes: [1, 2, 3, 4],
        mimeType: 'image/jpeg',
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.errorMessage, contains('Device platform error'));
    });

    test('Missing file in analyzeAuthenticityFile returns uncertain failure', () async {
      final service = GeminiAiAuthenticityService();
      final nonExistentFile = File('non_existent_file_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final result = await service.analyzeAuthenticityFile(nonExistentFile);

      expect(result.isSuccess, isFalse);
      expect(result.status, AiAuthenticityStatus.uncertain);
      expect(result.errorMessage, contains('does not exist'));
    });
  });
}
