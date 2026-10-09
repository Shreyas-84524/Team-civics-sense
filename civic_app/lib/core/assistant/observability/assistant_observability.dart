import '../config/civic_assistant_config.dart';
import 'assistant_error_type.dart';

/// Read-only snapshot of aggregate assistant observability metrics.
class AssistantObservabilityMetrics {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int fallbackCount;
  final double averageLatencyMs;
  final double p95LatencyMs;
  final Map<String, int> intentDistribution;
  final Map<String, int> localeDistribution;
  final int retrievalMisses;
  final Map<String, int> errorTypeDistribution;
  final int helpfulFeedbackCount;
  final int unhelpfulFeedbackCount;

  const AssistantObservabilityMetrics({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.fallbackCount,
    required this.averageLatencyMs,
    required this.p95LatencyMs,
    required this.intentDistribution,
    required this.localeDistribution,
    required this.retrievalMisses,
    required this.errorTypeDistribution,
    required this.helpfulFeedbackCount,
    required this.unhelpfulFeedbackCount,
  });

  double get successRate =>
      totalRequests > 0 ? (successfulRequests / totalRequests) * 100.0 : 100.0;
  double get errorRate =>
      totalRequests > 0 ? (failedRequests / totalRequests) * 100.0 : 0.0;
  double get fallbackRate =>
      totalRequests > 0 ? (fallbackCount / totalRequests) * 100.0 : 0.0;
  double get satisfactionRate =>
      (helpfulFeedbackCount + unhelpfulFeedbackCount) > 0
          ? (helpfulFeedbackCount /
                  (helpfulFeedbackCount + unhelpfulFeedbackCount)) *
              100.0
          : 100.0;

  Map<String, dynamic> toJson() => {
        'totalRequests': totalRequests,
        'successfulRequests': successfulRequests,
        'failedRequests': failedRequests,
        'fallbackCount': fallbackCount,
        'successRate': '${successRate.toStringAsFixed(1)}%',
        'errorRate': '${errorRate.toStringAsFixed(1)}%',
        'fallbackRate': '${fallbackRate.toStringAsFixed(1)}%',
        'averageLatencyMs': '${averageLatencyMs.toStringAsFixed(2)} ms',
        'p95LatencyMs': '${p95LatencyMs.toStringAsFixed(2)} ms',
        'intentDistribution': intentDistribution,
        'localeDistribution': localeDistribution,
        'retrievalMisses': retrievalMisses,
        'errorTypeDistribution': errorTypeDistribution,
        'helpfulFeedback': helpfulFeedbackCount,
        'unhelpfulFeedback': unhelpfulFeedbackCount,
        'satisfactionRate': '${satisfactionRate.toStringAsFixed(1)}%',
      };
}

/// In-memory aggregation monitor collecting runtime latency, error rates, and intent distributions.
class CivicAssistantObservability {
  static final CivicAssistantObservability instance =
      CivicAssistantObservability._internal();
  CivicAssistantObservability._internal();

  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  int _fallbackCount = 0;
  int _retrievalMisses = 0;
  int _helpfulFeedback = 0;
  int _unhelpfulFeedback = 0;

  final List<int> _latencies = [];
  final Map<String, int> _intentCounts = {};
  final Map<String, int> _localeCounts = {};
  final Map<String, int> _errorCounts = {};

  static const int _maxLatencyWindow = 500;

  /// Records an execution outcome.
  void recordRequest({
    required int latencyMs,
    required bool isSuccess,
    bool isFallback = false,
    String? intent,
    String? languageCode,
    AssistantErrorType? errorType,
  }) {
    if (!CivicAssistantConfig.current.observabilityEnabled) return;

    _totalRequests++;
    if (isSuccess) {
      _successfulRequests++;
    } else {
      _failedRequests++;
    }

    if (isFallback) {
      _fallbackCount++;
    }

    if (intent != null && intent.isNotEmpty) {
      _intentCounts[intent] = (_intentCounts[intent] ?? 0) + 1;
    }

    if (languageCode != null && languageCode.isNotEmpty) {
      _localeCounts[languageCode] = (_localeCounts[languageCode] ?? 0) + 1;
    }

    if (errorType != null) {
      _errorCounts[errorType.name] = (_errorCounts[errorType.name] ?? 0) + 1;
    }

    if (_latencies.length >= _maxLatencyWindow) {
      _latencies.removeAt(0);
    }
    _latencies.add(latencyMs);
  }

  /// Records a retrieval miss (no matching knowledge entries found above threshold).
  void recordRetrievalMiss() {
    if (!CivicAssistantConfig.current.observabilityEnabled) return;
    _retrievalMisses++;
  }

  /// Records citizen feedback rating.
  void recordFeedback({required bool isHelpful}) {
    if (!CivicAssistantConfig.current.observabilityEnabled) return;
    if (isHelpful) {
      _helpfulFeedback++;
    } else {
      _unhelpfulFeedback++;
    }
  }

  /// Returns a point-in-time metrics snapshot.
  AssistantObservabilityMetrics getSnapshot() {
    final sortedLatencies = List<int>.from(_latencies)..sort();
    final double avgLatency = sortedLatencies.isEmpty
        ? 0.0
        : sortedLatencies.reduce((a, b) => a + b) / sortedLatencies.length;

    double p95 = 0.0;
    if (sortedLatencies.isNotEmpty) {
      final p95Index =
          (sortedLatencies.length * 0.95).clamp(0, sortedLatencies.length - 1).toInt();
      p95 = sortedLatencies[p95Index].toDouble();
    }

    return AssistantObservabilityMetrics(
      totalRequests: _totalRequests,
      successfulRequests: _successfulRequests,
      failedRequests: _failedRequests,
      fallbackCount: _fallbackCount,
      averageLatencyMs: avgLatency,
      p95LatencyMs: p95,
      intentDistribution: Map.unmodifiable(_intentCounts),
      localeDistribution: Map.unmodifiable(_localeCounts),
      retrievalMisses: _retrievalMisses,
      errorTypeDistribution: Map.unmodifiable(_errorCounts),
      helpfulFeedbackCount: _helpfulFeedback,
      unhelpfulFeedbackCount: _unhelpfulFeedback,
    );
  }

  /// Resets all counters and distributions (used in test setup/teardown).
  void reset() {
    _totalRequests = 0;
    _successfulRequests = 0;
    _failedRequests = 0;
    _fallbackCount = 0;
    _retrievalMisses = 0;
    _helpfulFeedback = 0;
    _unhelpfulFeedback = 0;
    _latencies.clear();
    _intentCounts.clear();
    _localeCounts.clear();
    _errorCounts.clear();
  }
}
