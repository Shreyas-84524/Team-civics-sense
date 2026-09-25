/// Status of the AI-assisted authenticity evaluation for submitted complaint evidence.
///
/// NOTE: Gemini provides visual inspection analysis only, not forensic proof.
enum AiAuthenticityStatus {
  /// The image visually exhibits normal photographic characteristics (natural lighting,
  /// coherent geometry, sensor noise, photographic texture) with no strong signs of AI generation.
  likelyReal('likely_real', 'Likely Real Photograph'),

  /// The image visually exhibits inconsistencies commonly associated with generative AI
  /// or heavy synthetic manipulation (warped geometry, anomalous text, impossible reflections,
  /// repetitive synthetic artifacts).
  likelyAiGenerated('likely_ai_generated', 'Likely AI-Generated / Manipulated'),

  /// The visual evidence is insufficient, ambiguous, low-quality, or inconclusive to assess.
  /// Also used as safe fallback for unexpected or failed analyses.
  uncertain('uncertain', 'Uncertain Origin');

  /// Machine-readable storage and JSON schema representation.
  final String rawValue;

  /// Human-readable advisory label.
  final String label;

  const AiAuthenticityStatus(this.rawValue, this.label);

  /// Safe deserializer from string with fallback to [uncertain].
  ///
  /// Never throws on invalid or unrecognized input.
  static AiAuthenticityStatus fromString(String? value) {
    if (value == null) return AiAuthenticityStatus.uncertain;
    final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]'), '_');
    switch (normalized) {
      case 'likely_real':
      case 'likelyreal':
      case 'real':
      case 'authentic':
      case 'photo':
      case 'photograph':
        return AiAuthenticityStatus.likelyReal;
      case 'likely_ai_generated':
      case 'likelyaigenerated':
      case 'ai_generated':
      case 'aigenerated':
      case 'synthetic':
      case 'fake':
      case 'manipulated':
        return AiAuthenticityStatus.likelyAiGenerated;
      case 'uncertain':
      case 'unknown':
      case 'inconclusive':
      case 'ambiguous':
      default:
        return AiAuthenticityStatus.uncertain;
    }
  }

  @override
  String toString() => rawValue;
}
