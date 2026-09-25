import 'dart:io';
import 'models/ai_authenticity_result.dart';

/// Abstract service contract for AI-assisted image authenticity analysis.
///
/// Assesses whether complaint evidence appears to be a genuine photograph
/// or synthetic / AI-generated content.
abstract class AiAuthenticityService {
  /// Analyzes raw binary image bytes for visual authenticity indicators.
  ///
  /// [imageBytes]: Binary data of the image.
  /// [mimeType]: Image MIME type (e.g., 'image/jpeg', 'image/png', 'image/webp').
  Future<AiAuthenticityResult> analyzeAuthenticity({
    required List<int> imageBytes,
    required String mimeType,
  });

  /// Analyzes an image file from local file storage.
  ///
  /// [imageFile]: Local [File] reference.
  Future<AiAuthenticityResult> analyzeAuthenticityFile(File imageFile);
}
