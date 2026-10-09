import '../models/assistant_app_context.dart';
import '../models/assistant_conversation_history.dart';
import '../models/civic_assistant_intent.dart';

/// Configuration parameters for the CivicFix RAG retrieval pipeline.
class AssistantRetrievalConfig {
  /// Maximum number of top relevant chunks to retrieve for prompt injection.
  final int maxResults;

  /// Minimum relevance score required for a knowledge chunk to be accepted.
  /// Prevents injecting weak, irrelevant, or noisy chunks into the LLM context.
  final double minScoreThreshold;

  /// Whether to enable bounded 1-hop expansion for related topics on top hits.
  final bool enableRelatedExpansion;

  /// Maximum number of related topic chunks to append.
  final int maxRelatedExpansion;

  /// Whether to output debug-only diagnostic logs in non-production runs.
  final bool debugMode;

  const AssistantRetrievalConfig({
    this.maxResults = 4,
    this.minScoreThreshold = 15.0,
    this.enableRelatedExpansion = true,
    this.maxRelatedExpansion = 1,
    this.debugMode = false,
  });

  /// Default production configuration optimized for compact, high-precision retrieval.
  static const AssistantRetrievalConfig defaultConfig = AssistantRetrievalConfig();

  /// High-precision configuration for strict verification queries.
  static const AssistantRetrievalConfig strictConfig = AssistantRetrievalConfig(
    maxResults: 3,
    minScoreThreshold: 25.0,
    enableRelatedExpansion: false,
  );
}

/// A prompt-ready knowledge chunk retrieved from the authoritative CivicFix knowledge base.
class AssistantRetrievedChunk {
  /// Unique canonical entry ID (e.g., 'dept_maintenance_roads', 'roles_junior_engineer').
  final String id;

  /// Human-readable title.
  final String title;

  /// Knowledge domain topic (e.g., 'departments', 'lifecycle', 'roles', 'sla').
  final String topic;

  /// Canonical, authoritative content text.
  final String content;

  /// Calculated relevance score from hybrid retrieval scoring.
  final double score;

  /// Primary match rationale (e.g., 'exact_id_match', 'tag_token_overlap', 'title_phrase_match').
  final String matchReason;

  /// Authoritative source document reference (e.g., 'Brain.md', 'departments.ts').
  final String sourceReference;

  /// Related topic identifiers for bounded context expansion.
  final List<String> relatedTopics;

  /// Optional metadata attributes.
  final Map<String, dynamic> metadata;

  const AssistantRetrievedChunk({
    required this.id,
    required this.title,
    required this.topic,
    required this.content,
    required this.score,
    required this.matchReason,
    required this.sourceReference,
    this.relatedTopics = const [],
    this.metadata = const {},
  });

  /// Formats the chunk into a clean, compact representation for prompt injection.
  String toPromptChunk() {
    return '[$title] (Topic: $topic)\n$content';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'content': content,
        'score': score,
        'matchReason': matchReason,
        'sourceReference': sourceReference,
        'relatedTopics': relatedTopics,
        'metadata': metadata,
      };
}

/// Incoming retrieval request payload containing query, intent hints, and session context.
class AssistantRetrievalRequest {
  /// Raw user query string.
  final String query;

  /// Pre-classified intent from Intent Router.
  final CivicAssistantIntent intent;

  /// Intent classifier confidence score (0.0 to 1.0).
  final double intentConfidence;

  /// Bounded conversation history for multi-turn context resolution.
  final AssistantConversationHistory? history;

  /// Live application and complaint context for contextual relevance boosts.
  final AssistantAppContext? appContext;

  /// Retrieval configuration rules.
  final AssistantRetrievalConfig config;

  const AssistantRetrievalRequest({
    required this.query,
    this.intent = CivicAssistantIntent.unknown,
    this.intentConfidence = 1.0,
    this.history,
    this.appContext,
    this.config = AssistantRetrievalConfig.defaultConfig,
  });
}

/// Encapsulates the output of a RAG retrieval execution.
class AssistantRetrievalResult {
  /// Original query string.
  final String query;

  /// Normalized query tokens used during hybrid scoring.
  final String normalizedQuery;

  /// Ordered list of retrieved knowledge chunks ranked by relevance score.
  final List<AssistantRetrievedChunk> chunks;

  /// Unique knowledge entry IDs included in the result.
  final List<String> retrievedKnowledgeIds;

  /// List of topics represented across the retrieved chunks.
  final List<String> topicsUsed;

  /// Highest relevance score among the retrieved chunks (0.0 if empty).
  final double topScore;

  /// Whether retrieval was bypassed (e.g. for casual greetings or small talk).
  final bool isBypassed;

  /// Execution duration in milliseconds.
  final int executionTimeMs;

  /// Diagnostic metadata (debug diagnostics, token matches, intent boosts).
  final Map<String, dynamic> diagnostics;

  const AssistantRetrievalResult({
    required this.query,
    required this.normalizedQuery,
    required this.chunks,
    required this.retrievedKnowledgeIds,
    required this.topicsUsed,
    required this.topScore,
    this.isBypassed = false,
    this.executionTimeMs = 0,
    this.diagnostics = const {},
  });

  /// Whether any grounded chunks were successfully retrieved.
  bool get hasChunks => chunks.isNotEmpty;

  /// Convenient alias for retrievedKnowledgeIds.
  List<String> get chunkIds => retrievedKnowledgeIds;

  /// Creates a bypassed retrieval result for casual greetings, small talk, or general chat.
  factory AssistantRetrievalResult.bypassed({
    required String query,
    String reason = 'casual_intent_bypass',
  }) {
    return AssistantRetrievalResult(
      query: query,
      normalizedQuery: query.trim().toLowerCase(),
      chunks: const [],
      retrievedKnowledgeIds: const [],
      topicsUsed: const [],
      topScore: 0.0,
      isBypassed: true,
      diagnostics: {'bypassReason': reason},
    );
  }

  /// Creates an empty retrieval result when no knowledge items meet the minimum score threshold.
  factory AssistantRetrievalResult.empty({
    required String query,
    required String normalizedQuery,
    int executionTimeMs = 0,
    Map<String, dynamic> diagnostics = const {},
  }) {
    return AssistantRetrievalResult(
      query: query,
      normalizedQuery: normalizedQuery,
      chunks: const [],
      retrievedKnowledgeIds: const [],
      topicsUsed: const [],
      topScore: 0.0,
      isBypassed: false,
      executionTimeMs: executionTimeMs,
      diagnostics: diagnostics,
    );
  }
}
