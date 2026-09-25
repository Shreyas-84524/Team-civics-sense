import '../models/category_model.dart';
import 'models/ai_detection_result.dart';

/// Abstract contract for civic evidence visual analysis and verification.
///
/// Kept strictly decoupled from UI, Firestore, Hive, and Storage layers.
@Deprecated('Gemini scope has been corrected to Authenticity Verification only. Use AiAuthenticityService instead.')
abstract class AiDetectionService {
  /// Analyzes an evidence image and returns AI verification output (Phase 2 compatibility).
  ///
  /// [imageBytes]: Raw binary bytes of the evidence photo.
  /// [mimeType]: Image MIME type (e.g., 'image/jpeg', 'image/png', 'image/webp').
  Future<AiDetectionResult> analyzeImage({
    required List<int> imageBytes,
    required String mimeType,
  });

  /// Verifies civic evidence against a citizen-selected [CivicCategory] using structured schema output (Phase 3).
  ///
  /// [imageBytes]: Raw binary bytes of the evidence photo.
  /// [mimeType]: Image MIME type (e.g., 'image/jpeg', 'image/png', 'image/webp').
  /// [selectedCategory]: The category chosen by the citizen during complaint drafting.
  Future<AiDetectionResult> verifyEvidence({
    required List<int> imageBytes,
    required String mimeType,
    required CivicCategory selectedCategory,
  });
}
