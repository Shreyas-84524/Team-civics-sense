import 'package:flutter/foundation.dart';

/// Production configuration and feature flags for CivicFix Assistant.
///
/// Enables:
/// - Emergency remote disable of chatbot features (`assistantEnabled`)
/// - Controlled toggle for remote vs local deterministic generation (`remoteAiEnabled`)
/// - Telemetry and observability control (`observabilityEnabled`)
/// - User feedback rating collection (`feedbackEnabled`)
/// - Token/budget and history bounds
/// - Knowledge and assistant version metadata
@immutable
class CivicAssistantConfig {
  /// Master toggle enabling/disabling the Civic Assistant throughout the application.
  final bool assistantEnabled;

  /// Whether remote LLM generation is enabled. When false, the chatbot runs 100% locally.
  final bool remoteAiEnabled;

  /// Whether privacy-safe telemetry and latency monitoring are active.
  final bool observabilityEnabled;

  /// Whether thumbs-up / thumbs-down feedback buttons are rendered on assistant messages.
  final bool feedbackEnabled;

  /// Whether the TTS speaker button / readiness hooks are active.
  final bool ttsReadinessEnabled;

  /// Maximum number of messages kept in conversation history (bounded sliding window).
  final int maxHistoryLength;

  /// Maximum number of knowledge chunks returned by RAG retriever (top-K).
  final int maxRetrievalChunks;

  /// Maximum estimated token budget for system prompt and context assembly.
  final int maxPromptTokens;

  /// Semantic versioning of the authoritative municipal knowledge base.
  final String knowledgeVersion;

  /// Semantic versioning of the assistant orchestration architecture.
  final String assistantVersion;

  /// Semantic versioning of the hybrid RAG retrieval pipeline.
  final String retrievalVersion;

  const CivicAssistantConfig({
    this.assistantEnabled = true,
    this.remoteAiEnabled = false,
    this.observabilityEnabled = true,
    this.feedbackEnabled = true,
    this.ttsReadinessEnabled = true,
    this.maxHistoryLength = 10,
    this.maxRetrievalChunks = 5,
    this.maxPromptTokens = 2048,
    this.knowledgeVersion = 'v1.2.0-2026Q1',
    this.assistantVersion = 'v1.8.0-phase8',
    this.retrievalVersion = 'v1.4.0-hybrid',
  });

  /// Default production configuration.
  static const CivicAssistantConfig defaultProduction = CivicAssistantConfig();

  static CivicAssistantConfig _current = defaultProduction;

  /// Returns the current active configuration singleton.
  static CivicAssistantConfig get current => _current;

  /// Updates the global active configuration.
  static void setGlobal(CivicAssistantConfig config) {
    _current = config;
  }

  /// Resets global configuration to default production settings.
  static void resetToDefault() {
    _current = defaultProduction;
  }

  CivicAssistantConfig copyWith({
    bool? assistantEnabled,
    bool? remoteAiEnabled,
    bool? observabilityEnabled,
    bool? feedbackEnabled,
    bool? ttsReadinessEnabled,
    int? maxHistoryLength,
    int? maxRetrievalChunks,
    int? maxPromptTokens,
    String? knowledgeVersion,
    String? assistantVersion,
    String? retrievalVersion,
  }) {
    return CivicAssistantConfig(
      assistantEnabled: assistantEnabled ?? this.assistantEnabled,
      remoteAiEnabled: remoteAiEnabled ?? this.remoteAiEnabled,
      observabilityEnabled: observabilityEnabled ?? this.observabilityEnabled,
      feedbackEnabled: feedbackEnabled ?? this.feedbackEnabled,
      ttsReadinessEnabled: ttsReadinessEnabled ?? this.ttsReadinessEnabled,
      maxHistoryLength: maxHistoryLength ?? this.maxHistoryLength,
      maxRetrievalChunks: maxRetrievalChunks ?? this.maxRetrievalChunks,
      maxPromptTokens: maxPromptTokens ?? this.maxPromptTokens,
      knowledgeVersion: knowledgeVersion ?? this.knowledgeVersion,
      assistantVersion: assistantVersion ?? this.assistantVersion,
      retrievalVersion: retrievalVersion ?? this.retrievalVersion,
    );
  }
}
