import 'package:flutter/foundation.dart';
import '../config/civic_assistant_config.dart';
import '../models/civic_assistant_intent.dart';
import 'assistant_error_type.dart';

/// Represents a privacy-safe telemetry event emitted during assistant operation.
class AssistantAnalyticsEvent {
  final String eventName;
  final String sessionId;
  final DateTime timestamp;
  final Map<String, dynamic> parameters;

  const AssistantAnalyticsEvent({
    required this.eventName,
    required this.sessionId,
    required this.timestamp,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'eventName': eventName,
        'sessionId': sessionId,
        'timestamp': timestamp.toIso8601String(),
        'parameters': parameters,
      };

  @override
  String toString() => 'AssistantAnalyticsEvent($eventName, params: $parameters)';
}

/// Callback definition for custom analytics sinks (e.g. Firebase Analytics, Datadog).
typedef AssistantAnalyticsSink = void Function(AssistantAnalyticsEvent event);

/// Privacy-safe telemetry and event logger for CivicFix Assistant.
///
/// Strictly enforces the Zero-PII logging guarantee:
/// - Never logs raw query text or conversational transcripts.
/// - Never logs phone numbers, emails, passwords, OTPs, Firebase UIDs, employee IDs, signed URLs, or tokens.
/// - Only logs categorical metadata, query lengths, intent classifications, retrieval chunk counts, latencies, and feedback ratings.
class CivicAssistantAnalytics {
  static final CivicAssistantAnalytics instance = CivicAssistantAnalytics._internal();
  CivicAssistantAnalytics._internal();

  final List<AssistantAnalyticsSink> _sinks = [];
  final List<AssistantAnalyticsEvent> _inMemoryEvents = [];
  static const int _maxInMemoryEvents = 200;

  /// Registers a telemetry sink.
  void addSink(AssistantAnalyticsSink sink) {
    _sinks.add(sink);
  }

  /// Removes a telemetry sink.
  void removeSink(AssistantAnalyticsSink sink) {
    _sinks.remove(sink);
  }

  /// Clears in-memory buffer and sinks (useful for test isolation).
  void clear() {
    _inMemoryEvents.clear();
    _sinks.clear();
  }

  /// Read-only snapshot of recently recorded in-memory events.
  List<AssistantAnalyticsEvent> get recentEvents => List.unmodifiable(_inMemoryEvents);

  /// Emits a sanitized analytics event if observability is enabled.
  void logEvent(String eventName, {required String sessionId, Map<String, dynamic>? parameters}) {
    if (!CivicAssistantConfig.current.observabilityEnabled) return;

    final sanitizedParams = _sanitizeParameters(parameters ?? {});
    final event = AssistantAnalyticsEvent(
      eventName: eventName,
      sessionId: sessionId,
      timestamp: DateTime.now(),
      parameters: sanitizedParams,
    );

    if (_inMemoryEvents.length >= _maxInMemoryEvents) {
      _inMemoryEvents.removeAt(0);
    }
    _inMemoryEvents.add(event);

    for (final sink in _sinks) {
      try {
        sink(event);
      } catch (e) {
        debugPrint('[CivicAssistantAnalytics] Sink error: $e');
      }
    }
  }

  // --- Pre-defined Privacy-Safe Event Loggers ---

  void logSessionStarted({
    required String sessionId,
    required String languageCode,
    required String currentScreen,
    bool hasComplaintContext = false,
  }) {
    logEvent(
      'assistant_session_started',
      sessionId: sessionId,
      parameters: {
        'language': languageCode,
        'currentScreen': currentScreen,
        'hasComplaintContext': hasComplaintContext,
      },
    );
  }

  void logQuerySubmitted({
    required String sessionId,
    required int queryLength,
    required String languageCode,
    required String currentScreen,
    bool hasComplaintContext = false,
  }) {
    logEvent(
      'assistant_query_submitted',
      sessionId: sessionId,
      parameters: {
        'queryLength': queryLength,
        'language': languageCode,
        'currentScreen': currentScreen,
        'hasComplaintContext': hasComplaintContext,
      },
    );
  }

  void logIntentClassified({
    required String sessionId,
    required CivicAssistantIntent intent,
    required double confidence,
    required bool isOutOfScope,
  }) {
    logEvent(
      'assistant_intent_classified',
      sessionId: sessionId,
      parameters: {
        'intent': intent.name,
        'confidence': confidence,
        'isOutOfScope': isOutOfScope,
      },
    );
  }

  void logRetrievalCompleted({
    required String sessionId,
    required int chunksCount,
    required double topScore,
    required int latencyMs,
    required bool isMiss,
  }) {
    logEvent(
      'assistant_retrieval_completed',
      sessionId: sessionId,
      parameters: {
        'chunksCount': chunksCount,
        'topScore': topScore,
        'latencyMs': latencyMs,
        'isMiss': isMiss,
      },
    );
  }

  void logResponseGenerated({
    required String sessionId,
    required int latencyMs,
    required bool isFallback,
    required bool isGrounded,
    required bool isError,
    AssistantErrorType? errorType,
  }) {
    final params = <String, dynamic>{
      'latencyMs': latencyMs,
      'isFallback': isFallback,
      'isGrounded': isGrounded,
      'isError': isError,
    };
    if (errorType != null) {
      params['errorType'] = errorType.name;
    }
    logEvent(
      'assistant_response_generated',
      sessionId: sessionId,
      parameters: params,
    );
  }

  void logFeedbackSubmitted({
    required String sessionId,
    required String messageId,
    required String rating, // 'helpful' or 'unhelpful'
    required String languageCode,
    String? intent,
  }) {
    final params = <String, dynamic>{
      'messageId': messageId,
      'rating': rating,
      'language': languageCode,
    };
    if (intent != null) {
      params['intent'] = intent;
    }
    logEvent(
      'assistant_feedback_submitted',
      sessionId: sessionId,
      parameters: params,
    );
  }

  void logChatCleared({required String sessionId}) {
    logEvent('assistant_chat_cleared', sessionId: sessionId);
  }

  /// Sanitizes parameter map to strictly enforce Zero-PII rules.
  Map<String, dynamic> _sanitizeParameters(Map<String, dynamic> source) {
    final sanitized = <String, dynamic>{};
    const forbiddenKeys = {
      'text',
      'query',
      'prompt',
      'transcript',
      'phone',
      'phonenumber',
      'email',
      'password',
      'otp',
      'uid',
      'token',
      'jwt',
      'url',
      'signedurl',
      'credential',
      'employeeid',
    };

    source.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (forbiddenKeys.contains(lowerKey)) {
        sanitized[key] = '[REDACTED_PII]';
      } else if (value is String && _containsPiiPattern(value)) {
        sanitized[key] = '[REDACTED_PII]';
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  bool _containsPiiPattern(String text) {
    // Phone number pattern
    if (RegExp(r'\b[6-9]\d{9}\b').hasMatch(text)) return true;
    // Email pattern
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(text)) return true;
    // OTP pattern (4-6 consecutive digits in message)
    if (RegExp(r'\botp[:\s]+\d{4,6}\b', caseSensitive: false).hasMatch(text)) return true;
    return false;
  }
}
