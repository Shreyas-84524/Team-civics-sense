import '../retrieval/retrieval_models.dart';

/// Retrieved knowledge context containing prompt-ready chunks for RAG grounding.
class AssistantRagContext {
  /// Structured prompt-ready knowledge chunks retrieved from the knowledge base.
  final List<AssistantRetrievedChunk> chunks;

  /// Verified knowledge passages or documentation chunks as raw string snippets.
  final List<String> retrievedSnippets;

  /// Source identifiers (e.g. 'Brain.md', 'departments.ts').
  final List<String> sourceDocuments;

  /// Whether the current response is backed by authoritative retrieved knowledge.
  final bool isGrounded;

  /// Optional underlying retrieval result with scoring and diagnostics.
  final AssistantRetrievalResult? retrievalResult;

  const AssistantRagContext({
    this.chunks = const [],
    this.retrievedSnippets = const [],
    this.sourceDocuments = const [],
    this.isGrounded = false,
    this.retrievalResult,
  });

  /// Factory creating an [AssistantRagContext] directly from an [AssistantRetrievalResult].
  factory AssistantRagContext.fromRetrievalResult(AssistantRetrievalResult result) {
    if (result.isBypassed || !result.hasChunks) {
      return AssistantRagContext(
        chunks: const [],
        retrievedSnippets: const [],
        sourceDocuments: const [],
        isGrounded: false,
        retrievalResult: result,
      );
    }

    final snippets = result.chunks.map((c) => c.toPromptChunk()).toList();
    final sources = result.chunks.map((c) => c.sourceReference).toSet().toList();

    return AssistantRagContext(
      chunks: result.chunks,
      retrievedSnippets: snippets,
      sourceDocuments: sources,
      isGrounded: true,
      retrievalResult: result,
    );
  }

  /// Empty ungrounded context placeholder.
  static const AssistantRagContext empty = AssistantRagContext();

  /// Formats the retrieved knowledge snippets for insertion into the structured prompt.
  String toPromptContextString() {
    if (chunks.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln('=== VERIFIED CIVICFIX DOCUMENTATION (RETRIEVED KNOWLEDGE) ===');
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        buffer.writeln('[Source ${i + 1}: ${chunk.title} (${chunk.topic})]');
        buffer.writeln(chunk.content);
        if (i < chunks.length - 1) {
          buffer.writeln();
        }
      }
      buffer.writeln('==============================================================');
      return buffer.toString().trim();
    }

    if (retrievedSnippets.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('=== VERIFIED CIVICFIX DOCUMENTATION (AUTHORITATIVE) ===');
    for (int i = 0; i < retrievedSnippets.length; i++) {
      buffer.writeln('[Source ${i + 1}]: ${retrievedSnippets[i]}');
    }
    buffer.writeln('=======================================================');
    return buffer.toString().trim();
  }
}
