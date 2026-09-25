import 'dart:async';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/ai/gemini_ai_detection_service.dart';
import 'package:civic_app/core/ai/models/ai_detection_result.dart';
import 'package:civic_app/core/models/category_model.dart';

void main() {
  group('AiDetectionEnums Tests', () {
    test('AiImageQuality parses strings correctly', () {
      expect(AiImageQuality.fromString('poor'), AiImageQuality.poor);
      expect(AiImageQuality.fromString('acceptable'), AiImageQuality.acceptable);
      expect(AiImageQuality.fromString('good'), AiImageQuality.good);
      expect(AiImageQuality.fromString('GOOD'), AiImageQuality.good);
      expect(AiImageQuality.fromString('unknown_val'), isNull);
      expect(AiImageQuality.fromString(null), isNull);
      expect(AiImageQuality.poor.label, 'Poor');
      expect(AiImageQuality.acceptable.label, 'Acceptable');
      expect(AiImageQuality.good.label, 'Good');
    });

    test('AiHazardSeverity parses strings correctly', () {
      expect(AiHazardSeverity.fromString('none'), AiHazardSeverity.none);
      expect(AiHazardSeverity.fromString('low'), AiHazardSeverity.low);
      expect(AiHazardSeverity.fromString('medium'), AiHazardSeverity.medium);
      expect(AiHazardSeverity.fromString('high'), AiHazardSeverity.high);
      expect(AiHazardSeverity.fromString('critical'), AiHazardSeverity.high);
      expect(AiHazardSeverity.fromString('unknown'), AiHazardSeverity.unknown);
      expect(AiHazardSeverity.fromString('invalid_val'), AiHazardSeverity.unknown);
      expect(AiHazardSeverity.fromString(null), AiHazardSeverity.unknown);
      expect(AiHazardSeverity.none.label, 'None');
      expect(AiHazardSeverity.high.label, 'High');
    });

    test('AiHazardType parses strings correctly', () {
      expect(AiHazardType.fromString('pothole'), AiHazardType.pothole);
      expect(AiHazardType.fromString('road_damage'), AiHazardType.roadDamage);
      expect(AiHazardType.fromString('garbage_overflow'), AiHazardType.garbageOverflow);
      expect(AiHazardType.fromString('open_drain'), AiHazardType.openDrain);
      expect(AiHazardType.fromString('waterlogging'), AiHazardType.waterlogging);
      expect(AiHazardType.fromString('damaged_streetlight'), AiHazardType.damagedStreetlight);
      expect(AiHazardType.fromString('fallen_tree'), AiHazardType.fallenTree);
      expect(AiHazardType.fromString('exposed_wire'), AiHazardType.exposedWire);
      expect(AiHazardType.fromString('broken_public_infrastructure'), AiHazardType.brokenPublicInfrastructure);
      expect(AiHazardType.fromString('traffic_obstruction'), AiHazardType.trafficObstruction);
      expect(AiHazardType.fromString('fire_or_smoke'), AiHazardType.fireOrSmoke);
      expect(AiHazardType.fromString('other'), AiHazardType.other);
      expect(AiHazardType.fromString('none'), AiHazardType.none);
      expect(AiHazardType.fromString('unknown'), AiHazardType.unknown);
      expect(AiHazardType.fromString('completely_unknown'), AiHazardType.unknown);
      expect(AiHazardType.fromString(null), AiHazardType.unknown);

      expect(AiHazardType.pothole.rawValue, 'pothole');
      expect(AiHazardType.roadDamage.rawValue, 'road_damage');
      expect(AiHazardType.garbageOverflow.rawValue, 'garbage_overflow');
    });
  });

  group('AiDetectionResult JSON Parsing Tests', () {
    test('1. Valid road damage result with matching category', () {
      const jsonStr = '''
      {
        "detected_category": "roads",
        "category_confidence": 0.95,
        "category_match": true,
        "is_usable_evidence": true,
        "image_quality": "good",
        "is_hazard": true,
        "hazard_type": "pothole",
        "hazard_severity": "high",
        "hazard_confidence": 0.90,
        "detected_objects": ["pothole", "asphalt", "cracked pavement"],
        "explanation": "Severe road crater with damaged surface."
      }
      ''';

      final result = AiDetectionResult.fromJsonString(
        jsonString: jsonStr,
        selectedCategory: CivicCategory.defaultCategories[0], // Roads
      );

      expect(result.isSuccess, isTrue);
      expect(result.detectedCategory?.id, 'roads');
      expect(result.detectedCategoryId, 'roads');
      expect(result.categoryConfidence, 0.95);
      expect(result.categoryMatch, isTrue);
      expect(result.isUsableEvidence, isTrue);
      expect(result.imageQuality, AiImageQuality.good);
      expect(result.isHazard, isTrue);
      expect(result.hazardType, AiHazardType.pothole);
      expect(result.hazardSeverity, AiHazardSeverity.high);
      expect(result.hazardConfidence, 0.90);
      expect(result.detectedObjects, ['pothole', 'asphalt', 'cracked pavement']);
      expect(result.explanation, 'Severe road crater with damaged surface.');
      expect(result.hasHazard, isTrue);
      expect(result.matchesCategory, isTrue);
      expect(result.usable, isTrue);
    });

    test('2. Valid garbage result with category mismatch', () {
      const jsonStr = '''
      {
        "detected_category": "waste",
        "category_confidence": 0.88,
        "category_match": false,
        "is_usable_evidence": true,
        "image_quality": "acceptable",
        "is_hazard": true,
        "hazard_type": "garbage_overflow",
        "hazard_severity": "medium",
        "hazard_confidence": 0.85,
        "detected_objects": ["trash bags", "plastic bottles", "sidewalk"],
        "explanation": "Garbage heap spilled onto pedestrian walkway."
      }
      ''';

      final result = AiDetectionResult.fromJsonString(
        jsonString: jsonStr,
        selectedCategory: CivicCategory.defaultCategories[0], // Roads (Mismatch)
      );

      expect(result.isSuccess, isTrue);
      expect(result.detectedCategory?.id, 'waste');
      expect(result.categoryMatch, isFalse);
      expect(result.isUsableEvidence, isTrue);
      expect(result.imageQuality, AiImageQuality.acceptable);
      expect(result.isHazard, isTrue);
      expect(result.hazardType, AiHazardType.garbageOverflow);
      expect(result.hazardSeverity, AiHazardSeverity.medium);
      expect(result.matchesCategory, isFalse);
      expect(result.usable, isTrue);
    });

    test('3. Valid non-hazard result (normal street scene)', () {
      const jsonStr = '''
      {
        "detected_category": "roads",
        "category_confidence": 0.75,
        "category_match": true,
        "is_usable_evidence": true,
        "image_quality": "good",
        "is_hazard": false,
        "hazard_type": "none",
        "hazard_severity": "none",
        "hazard_confidence": 0.10,
        "detected_objects": ["paved road", "curb", "tree"],
        "explanation": "Clear residential street with no visible defects."
      }
      ''';

      final result = AiDetectionResult.fromJsonString(
        jsonString: jsonStr,
        selectedCategory: CivicCategory.defaultCategories[0],
      );

      expect(result.isSuccess, isTrue);
      expect(result.isHazard, isFalse);
      expect(result.hazardType, AiHazardType.none);
      expect(result.hazardSeverity, AiHazardSeverity.none);
      expect(result.hasHazard, isFalse);
    });

    test('4. Unknown category and non-civic / invalid image', () {
      const jsonStr = '''
      {
        "detected_category": "none",
        "category_confidence": 0.05,
        "category_match": false,
        "is_usable_evidence": false,
        "image_quality": "poor",
        "is_hazard": false,
        "hazard_type": "unknown",
        "hazard_severity": "unknown",
        "hazard_confidence": 0.0,
        "detected_objects": ["digital graphic", "yellow circle"],
        "explanation": "Synthetic digital image containing no civic scene."
      }
      ''';

      final result = AiDetectionResult.fromJsonString(
        jsonString: jsonStr,
        selectedCategory: CivicCategory.defaultCategories[0],
      );

      expect(result.isSuccess, isTrue);
      expect(result.detectedCategory, isNull);
      expect(result.categoryMatch, isFalse);
      expect(result.isUsableEvidence, isFalse);
      expect(result.imageQuality, AiImageQuality.poor);
      expect(result.isHazard, isFalse);
      expect(result.hazardType, AiHazardType.unknown);
      expect(result.hazardSeverity, AiHazardSeverity.unknown);
      expect(result.usable, isFalse);
    });

    test('5. Missing optional fields handled gracefully', () {
      const jsonStr = '''
      {
        "detected_category": "streetlights",
        "category_match": true,
        "is_usable_evidence": true
      }
      ''';

      final result = AiDetectionResult.fromJsonString(
        jsonString: jsonStr,
        selectedCategory: CivicCategory.defaultCategories[4], // Street Lights
      );

      expect(result.isSuccess, isTrue);
      expect(result.detectedCategory?.id, 'streetlights');
      expect(result.categoryConfidence, isNull);
      expect(result.categoryMatch, isTrue);
      expect(result.isUsableEvidence, isTrue);
      expect(result.imageQuality, isNull);
      expect(result.isHazard, isNull);
      expect(result.hazardType, AiHazardType.unknown);
      expect(result.hazardSeverity, AiHazardSeverity.unknown);
      expect(result.detectedObjects, isEmpty);
      expect(result.explanation, isNull);
    });

    test('6. Invalid confidence values clamped and sanitized', () {
      const jsonStr = '''
      {
        "detected_category": "water",
        "category_confidence": 1.5,
        "hazard_confidence": -0.2
      }
      ''';

      final result = AiDetectionResult.fromJsonString(
        jsonString: jsonStr,
      );

      expect(result.categoryConfidence, 1.0); // Clamped to 1.0
      expect(result.hazardConfidence, 0.0); // Clamped to 0.0
    });

    test('7. Malformed JSON returns typed failure without crashing', () {
      const invalidJsonStr = '{ "detected_category": "roads", incomplete...';

      final result = AiDetectionResult.fromJsonString(
        jsonString: invalidJsonStr,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Failed to parse structured JSON response'));
      expect(result.categoryMatch, isNull); // Must not be marked false on AI technical error
      expect(result.isUsableEvidence, isNull);
    });

    test('8. Unexpected non-map JSON returns typed failure', () {
      const arrayJsonStr = '["roads", "pothole"]';

      final result = AiDetectionResult.fromJsonString(
        jsonString: arrayJsonStr,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('expected JSON Object'));
    });
  });

  group('GeminiAiDetectionService verifyEvidence Service Tests', () {
    final dummyCategory = CivicCategory.defaultCategories[0]; // Roads
    final dummyImageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);

    test('Input Validation fails with empty byte array', () async {
      final service = GeminiAiDetectionService();
      final result = await service.verifyEvidence(
        imageBytes: [],
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('empty'));
      expect(result.categoryMatch, isNull);
    });

    test('Input Validation fails with unsupported MIME type', () async {
      final service = GeminiAiDetectionService();
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'application/pdf',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Unsupported image format'));
    });

    test('Successfully passes category context into prompt and receives structured result', () async {
      String? capturedPromptText;
      InlineDataPart? capturedInlineData;

      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        final multiContent = prompt.first;
        for (final part in multiContent.parts) {
          if (part is TextPart) capturedPromptText = part.text;
          if (part is InlineDataPart) capturedInlineData = part;
        }

        return GenerateContentResponse(
          [
            Candidate(
              Content.text('''
              {
                "detected_category": "roads",
                "category_confidence": 0.96,
                "category_match": true,
                "is_usable_evidence": true,
                "image_quality": "good",
                "is_hazard": true,
                "hazard_type": "pothole",
                "hazard_severity": "high",
                "hazard_confidence": 0.92,
                "detected_objects": ["pothole", "cracked asphalt"],
                "explanation": "Deep pothole in the roadway."
              }
              '''),
              null,
              null,
              FinishReason.stop,
              null,
            )
          ],
          null,
        );
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isSuccess, isTrue);
      expect(result.categoryMatch, isTrue);
      expect(result.detectedCategory?.id, 'roads');
      expect(result.hazardType, AiHazardType.pothole);
      expect(result.hazardSeverity, AiHazardSeverity.high);

      // Verify prompt included the selected category name and description
      expect(capturedPromptText, contains('Roads'));
      expect(capturedPromptText, contains(dummyCategory.description));
      expect(capturedInlineData?.mimeType, 'image/jpeg');
    });

    test('Handles empty text response from Gemini', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        return GenerateContentResponse(
          [
            Candidate(
              Content.text('   '),
              null,
              null,
              FinishReason.stop,
              null,
            )
          ],
          null,
        );
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('empty response'));
    });

    test('Handles Timeout gracefully', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        await Future.delayed(const Duration(milliseconds: 50));
        throw TimeoutException('Request timed out');
      }

      final service = GeminiAiDetectionService(
        contentGenerator: mockRunner,
        timeout: const Duration(milliseconds: 10),
      );
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('timed out'));
    });

    test('Handles SocketException (Network Error)', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw const SocketException('Connection reset by peer');
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Network error'));
    });

    test('Handles QuotaExceeded exception', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw QuotaExceeded('Resource exhausted');
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('capacity temporarily exceeded'));
    });

    test('Handles ServiceApiNotEnabled exception', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw ServiceApiNotEnabled('API not enabled');
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Firebase AI service is not enabled'));
    });

    test('Handles InvalidApiKey exception', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw InvalidApiKey('API key invalid');
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Invalid Firebase AI authentication'));
    });

    test('Handles UnsupportedUserLocation exception', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw UnsupportedUserLocation();
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('not supported in the current geographic region'));
    });

    test('Handles generic FirebaseAIException', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw FirebaseAIException('Backend server failure');
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Firebase AI verification failed'));
    });

    test('Handles PlatformException', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Channel unavailable');
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.verifyEvidence(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
        selectedCategory: dummyCategory,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Device platform error'));
    });

    test('Phase 2 backward compatibility: analyzeImage functions properly', () async {
      Future<GenerateContentResponse> mockRunner(Iterable<Content> prompt) async {
        return GenerateContentResponse(
          [
            Candidate(
              Content.text('A visual description of a roadway with cracks.'),
              null,
              null,
              FinishReason.stop,
              null,
            )
          ],
          null,
        );
      }

      final service = GeminiAiDetectionService(contentGenerator: mockRunner);
      final result = await service.analyzeImage(
        imageBytes: dummyImageBytes,
        mimeType: 'image/jpeg',
      );

      expect(result.isSuccess, isTrue);
      expect(result.rawResponse, 'A visual description of a roadway with cracks.');
    });
  });
}
