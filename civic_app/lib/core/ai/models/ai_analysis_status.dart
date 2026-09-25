/// Operational lifecycle status for AI authenticity verification.
///
/// NOTE: This reflects the execution lifecycle of the AI analysis, NOT the authenticity
/// classification itself (which is represented by [AiAuthenticityStatus]).
enum AiAnalysisStatus {
  /// Complaint/evidence exists; authenticity analysis has not yet started or is queued offline.
  pending('pending', 'Pending Verification'),

  /// Authenticity analysis request is currently executing against Gemini / Firebase AI Logic.
  processing('processing', 'Processing...'),

  /// Authenticity analysis completed successfully and produced a valid [AiAuthenticityResult].
  completed('completed', 'Verification Completed'),

  /// Authenticity analysis encountered a technical failure (network, quota, timeout, etc.).
  /// NOTE: This does NOT mean the complaint is rejected or the evidence is fraudulent.
  failed('failed', 'Verification Failed');

  final String rawValue;
  final String label;

  const AiAnalysisStatus(this.rawValue, this.label);

  static AiAnalysisStatus fromString(String? value) {
    if (value == null) return AiAnalysisStatus.pending;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'processing':
      case 'in_progress':
        return AiAnalysisStatus.processing;
      case 'completed':
      case 'done':
      case 'success':
        return AiAnalysisStatus.completed;
      case 'failed':
      case 'error':
        return AiAnalysisStatus.failed;
      case 'pending':
      default:
        return AiAnalysisStatus.pending;
    }
  }

  bool get isPending => this == AiAnalysisStatus.pending;
  bool get isProcessing => this == AiAnalysisStatus.processing;
  bool get isCompleted => this == AiAnalysisStatus.completed;
  bool get isFailed => this == AiAnalysisStatus.failed;

  @override
  String toString() => rawValue;
}
