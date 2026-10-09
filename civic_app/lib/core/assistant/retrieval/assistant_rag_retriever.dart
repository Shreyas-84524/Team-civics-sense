import 'dart:async';
import 'retrieval_models.dart';

/// Abstract contract for RAG retrieval engines in the CivicFix Assistant.
abstract class AssistantRagRetriever {
  /// Executes intent-aware knowledge retrieval for a given query and session context.
  FutureOr<AssistantRetrievalResult> retrieve(AssistantRetrievalRequest request);
}

/// Optional future interface for remote vector / semantic embedding search providers.
///
/// Designed in Phase 4 to ensure the retrieval architecture can easily swap or augment
/// local hybrid search with vector similarity search (e.g. pgvector / Vertex AI embeddings)
/// in future phases without altering caller contracts.
abstract class AssistantSemanticRetriever {
  /// Retrieves knowledge chunks matching the semantic embedding space of the query.
  FutureOr<List<AssistantRetrievedChunk>> retrieveSemanticChunks(
    String query, {
    int topK = 3,
    double minCosineSimilarity = 0.75,
  });
}
