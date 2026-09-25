/// Lightweight representation of an object or feature identified in a civic complaint image.
class DetectedObject {
  /// Name or label of the identified entity (e.g., 'pothole', 'garbage heap', 'water leak').
  final String label;

  /// Confidence score between 0.0 and 1.0, if available.
  final double? confidence;

  const DetectedObject({
    required this.label,
    this.confidence,
  });

  @override
  String toString() =>
      'DetectedObject(label: $label${confidence != null ? ", confidence: ${(confidence! * 100).toStringAsFixed(1)}%" : ""})';
}
