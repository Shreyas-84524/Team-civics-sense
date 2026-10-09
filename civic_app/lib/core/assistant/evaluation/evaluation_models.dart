import '../models/assistant_app_context.dart';
import '../models/assistant_conversation_history.dart';
import '../models/civic_assistant_intent.dart';

/// 20 Canonical Evaluation Categories for the CivicFix Assistant.
enum AssistantEvaluationCategory {
  casualConversation,
  civicfixGeneral,
  complaintLifecycle,
  statusExplanation,
  departmentRouting,
  governmentRoles,
  evidence,
  sla,
  rework,
  map,
  offlineSync,
  liveAppContext,
  multiTurn,
  multilingual,
  mixedLanguage,
  unknown,
  outOfScope,
  privacy,
  hallucination,
  providerFailure,
}

/// A structured evaluation test case for the CivicFix Assistant.
class AssistantEvaluationCase {
  final String id;
  final AssistantEvaluationCategory category;
  final String language; // 'en', 'hi', 'mr', 'mixed'
  final String userQuery;
  final AssistantConversationHistory? optionalConversationHistory;
  final AssistantAppContext? optionalAppContext;
  final CivicAssistantIntent? expectedIntent;
  final List<String> expectedKnowledgeIds;
  final List<String> requiredFacts;
  final List<String> forbiddenClaims;
  final String? expectedLanguage;
  final String notes;

  const AssistantEvaluationCase({
    required this.id,
    required this.category,
    required this.language,
    required this.userQuery,
    this.optionalConversationHistory,
    this.optionalAppContext,
    this.expectedIntent,
    this.expectedKnowledgeIds = const [],
    this.requiredFacts = const [],
    this.forbiddenClaims = const [],
    this.expectedLanguage,
    this.notes = '',
  });
}

/// The result of evaluating a single [AssistantEvaluationCase].
class AssistantEvaluationResult {
  final String caseId;
  final AssistantEvaluationCategory category;
  final bool passed;
  final CivicAssistantIntent? matchedIntent;
  final CivicAssistantIntent? expectedIntent;
  final List<String> retrievedKnowledgeIds;
  final List<String> expectedKnowledgeIds;
  final String responseText;
  final String? detectedLanguage;
  final String? expectedLanguage;
  final bool requiredFactsPresent;
  final List<String> missingRequiredFacts;
  final List<String> forbiddenClaimsDetected;
  final int latencyMs;
  final String? failureReason;

  const AssistantEvaluationResult({
    required this.caseId,
    required this.category,
    required this.passed,
    this.matchedIntent,
    this.expectedIntent,
    this.retrievedKnowledgeIds = const [],
    this.expectedKnowledgeIds = const [],
    required this.responseText,
    this.detectedLanguage,
    this.expectedLanguage,
    required this.requiredFactsPresent,
    this.missingRequiredFacts = const [],
    this.forbiddenClaimsDetected = const [],
    required this.latencyMs,
    this.failureReason,
  });

  @override
  String toString() {
    return 'AssistantEvaluationResult(caseId: $caseId, passed: $passed, latency: ${latencyMs}ms, reason: $failureReason)';
  }
}

/// Aggregated statistical summary of an entire evaluation run.
class AssistantEvaluationSummary {
  final int totalCases;
  final int passedCases;
  final int failedCases;
  final double intentAccuracy;
  final double retrievalAccuracy;
  final double groundedAnswerAccuracy;
  final double hallucinationRate;
  final double privacyViolationRate;
  final double languageParity;
  final double averageLatencyMs;
  final Map<AssistantEvaluationCategory, int> categoryCounts;
  final Map<AssistantEvaluationCategory, int> categoryPasses;
  final List<AssistantEvaluationResult> failures;
  final List<AssistantEvaluationResult> results;

  const AssistantEvaluationSummary({
    required this.totalCases,
    required this.passedCases,
    required this.failedCases,
    required this.intentAccuracy,
    required this.retrievalAccuracy,
    required this.groundedAnswerAccuracy,
    required this.hallucinationRate,
    required this.privacyViolationRate,
    required this.languageParity,
    required this.averageLatencyMs,
    required this.categoryCounts,
    required this.categoryPasses,
    required this.failures,
    required this.results,
  });

  double categoryPassRate(AssistantEvaluationCategory category) {
    final count = categoryCounts[category] ?? 0;
    if (count == 0) return 1.0;
    final passes = categoryPasses[category] ?? 0;
    return passes / count;
  }

  String toFormattedReport() {
    final buffer = StringBuffer();
    buffer.writeln('======================================================');
    buffer.writeln('CIVICFIX CHATBOT PRODUCTION EVALUATION REPORT');
    buffer.writeln('======================================================');
    buffer.writeln('Total Cases Evaluated:       $totalCases');
    buffer.writeln('Passed Cases:               $passedCases / $totalCases (${(passedCases / (totalCases == 0 ? 1 : totalCases) * 100).toStringAsFixed(1)}%)');
    buffer.writeln('Failed Cases:               $failedCases');
    buffer.writeln('------------------------------------------------------');
    buffer.writeln('KEY QUALITY METRICS:');
    buffer.writeln('- Intent Routing Accuracy:   ${(intentAccuracy * 100).toStringAsFixed(1)}%');
    buffer.writeln('- Knowledge Retrieval Acc.:  ${(retrievalAccuracy * 100).toStringAsFixed(1)}%');
    buffer.writeln('- Grounded Answer Accuracy:  ${(groundedAnswerAccuracy * 100).toStringAsFixed(1)}%');
    buffer.writeln('- Hallucination Rate:        ${(hallucinationRate * 100).toStringAsFixed(2)}% (Target: 0.0%)');
    buffer.writeln('- Privacy Violation Rate:    ${(privacyViolationRate * 100).toStringAsFixed(2)}% (Target: 0.0%)');
    buffer.writeln('- Language Parity:           ${(languageParity * 100).toStringAsFixed(1)}%');
    buffer.writeln('- Average Response Latency:  ${averageLatencyMs.toStringAsFixed(2)} ms');
    buffer.writeln('------------------------------------------------------');
    buffer.writeln('CATEGORY BREAKDOWN:');
    for (final cat in AssistantEvaluationCategory.values) {
      final total = categoryCounts[cat] ?? 0;
      final pass = categoryPasses[cat] ?? 0;
      final rate = total > 0 ? (pass / total * 100).toStringAsFixed(1) : 'N/A';
      buffer.writeln('  • ${cat.name.padRight(22)}: $pass / $total ($rate%)');
    }
    if (failures.isNotEmpty) {
      buffer.writeln('------------------------------------------------------');
      buffer.writeln('FAILURES (${failures.length}):');
      for (final f in failures) {
        buffer.writeln('  [FAIL] ${f.caseId} (${f.category.name}): ${f.failureReason}');
        buffer.writeln('         Response: "${f.responseText}"');
      }
    }
    buffer.writeln('======================================================');
    return buffer.toString();
  }
}
