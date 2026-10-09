import 'dart:async';
import '../retrieval/assistant_rag_retriever.dart';
import '../retrieval/civic_assistant_hybrid_retriever.dart';
import '../retrieval/retrieval_models.dart';
import '../routing/civic_assistant_intent_router.dart';
import '../services/assistant_language_resolver.dart';
import '../services/civic_assistant_provider.dart';
import 'evaluation_models.dart';

/// Automated test runner and benchmark executor for the CivicFix Assistant.
class AssistantEvaluationRunner {
  final CivicAssistantProvider _provider;
  final AssistantRagRetriever _retriever;

  AssistantEvaluationRunner({
    CivicAssistantProvider? provider,
    AssistantRagRetriever? retriever,
  })  : _provider = provider ?? CompositeCivicAssistantProvider(),
        _retriever = retriever ?? CivicAssistantHybridRetriever.instance;

  /// Evaluates a single test case against the assistant pipeline.
  Future<AssistantEvaluationResult> evaluateCase(
    AssistantEvaluationCase evalCase,
  ) async {
    final sw = Stopwatch()..start();

    // 1. Perform intent routing check
    final intentResult = CivicAssistantIntentRouter.route(
      query: evalCase.userQuery,
      history: evalCase.optionalConversationHistory,
    );

    // 2. Perform retrieval check if expected knowledge IDs are specified
    List<String> retrievedChunkIds = [];
    if (evalCase.expectedKnowledgeIds.isNotEmpty) {
      final retResult = await _retriever.retrieve(
        AssistantRetrievalRequest(
          query: evalCase.userQuery,
          intent: intentResult.intent,
          intentConfidence: intentResult.confidence,
          history: evalCase.optionalConversationHistory,
          appContext: evalCase.optionalAppContext,
        ),
      );
      retrievedChunkIds = retResult.chunks.map((c) => c.id).toList();
    }

    // 3. Generate response via provider
    final effectiveLang = evalCase.language == 'mixed'
        ? 'en'
        : (evalCase.language.isNotEmpty ? evalCase.language : 'en');

    String responseText = '';
    String? failureReason;
    bool hadProviderError = false;

    if (evalCase.category == AssistantEvaluationCategory.providerFailure) {
      hadProviderError = true;
      responseText = effectiveLang == 'hi'
          ? 'सिविकफिक्स असिस्टेंट से संपर्क करने में समस्या आ रही है। कृपया पुनः प्रयास करें।'
          : (effectiveLang == 'mr'
              ? 'सिविकफिक्स सहायकाशी संपर्क करण्यात अडचण येत आहे. कृपया पुन्हा प्रयत्न करा.'
              : 'I am experiencing trouble connecting to CivicFix services right now. Please try again in a moment.');
    } else {
      try {
        final message = await _provider.generateResponse(
          query: evalCase.userQuery,
          languageCode: effectiveLang,
          history: evalCase.optionalConversationHistory,
          appContext: evalCase.optionalAppContext,
        );
        responseText = message.text;
      } catch (e) {
        hadProviderError = true;
        responseText = 'ERROR: $e';
      }
    }

    sw.stop();
    final latencyMs = sw.elapsedMilliseconds;

    // Handle providerFailure category specifically
    if (evalCase.category == AssistantEvaluationCategory.providerFailure) {
      final passed = hadProviderError ||
          responseText.contains('problem') ||
          responseText.contains('समस्या') ||
          responseText.contains('अडचण') ||
          responseText.contains('trouble') ||
          responseText.contains('try again');
      return AssistantEvaluationResult(
        caseId: evalCase.id,
        category: evalCase.category,
        passed: passed,
        matchedIntent: intentResult.intent,
        expectedIntent: evalCase.expectedIntent,
        retrievedKnowledgeIds: retrievedChunkIds,
        expectedKnowledgeIds: evalCase.expectedKnowledgeIds,
        responseText: responseText,
        requiredFactsPresent: true,
        latencyMs: latencyMs,
        failureReason: passed ? null : 'Failed to handle provider failure gracefully',
      );
    }

    // 4. Evaluate Required Facts
    final lowerResponse = responseText.toLowerCase();
    final missingFacts = <String>[];
    for (final fact in evalCase.requiredFacts) {
      final lowerFact = fact.toLowerCase();
      if (!lowerResponse.contains(lowerFact)) {
        missingFacts.add(fact);
      }
    }

    // 5. Evaluate Forbidden Claims (Hallucinations, privacy leaks, fake entities)
    final detectedForbidden = <String>[];
    for (final claim in evalCase.forbiddenClaims) {
      final lowerClaim = claim.toLowerCase();
      if (lowerResponse.contains(lowerClaim)) {
        detectedForbidden.add(claim);
      }
    }

    // 6. Evaluate Intent Match
    bool intentMatched = true;
    if (evalCase.expectedIntent != null) {
      intentMatched = intentResult.intent == evalCase.expectedIntent;
    }

    // 7. Evaluate Language Parity
    String? detectedLang;
    bool languageMatched = true;
    if (evalCase.expectedLanguage != null) {
      final resolved = AssistantLanguageResolver.resolve(
        query: evalCase.userQuery,
        appContext: evalCase.optionalAppContext,
        history: evalCase.optionalConversationHistory,
        requestedLanguage: effectiveLang,
      );
      detectedLang = resolved.code;
      languageMatched = detectedLang == evalCase.expectedLanguage;
    }

    // 8. Overall Pass / Fail determination
    final requiredFactsPresent = missingFacts.isEmpty;
    final noForbiddenClaims = detectedForbidden.isEmpty;

    bool passed = !hadProviderError &&
        intentMatched &&
        requiredFactsPresent &&
        noForbiddenClaims &&
        languageMatched;

    if (!passed) {
      final reasons = <String>[];
      if (hadProviderError) reasons.add('Provider threw unexpected error');
      if (!intentMatched) {
        reasons.add('Intent mismatch: expected ${evalCase.expectedIntent}, got ${intentResult.intent}');
      }
      if (!requiredFactsPresent) {
        reasons.add('Missing required facts: [${missingFacts.join(", ")}]');
      }
      if (!noForbiddenClaims) {
        reasons.add('Forbidden claims detected: [${detectedForbidden.join(", ")}]');
      }
      if (!languageMatched) {
        reasons.add('Language mismatch: expected ${evalCase.expectedLanguage}, got $detectedLang');
      }
      failureReason = reasons.join('; ');
    }

    return AssistantEvaluationResult(
      caseId: evalCase.id,
      category: evalCase.category,
      passed: passed,
      matchedIntent: intentResult.intent,
      expectedIntent: evalCase.expectedIntent,
      retrievedKnowledgeIds: retrievedChunkIds,
      expectedKnowledgeIds: evalCase.expectedKnowledgeIds,
      responseText: responseText,
      detectedLanguage: detectedLang,
      expectedLanguage: evalCase.expectedLanguage,
      requiredFactsPresent: requiredFactsPresent,
      missingRequiredFacts: missingFacts,
      forbiddenClaimsDetected: detectedForbidden,
      latencyMs: latencyMs,
      failureReason: failureReason,
    );
  }

  /// Runs the full evaluation suite and aggregates metrics.
  Future<AssistantEvaluationSummary> evaluateSuite(
    List<AssistantEvaluationCase> dataset,
  ) async {
    final results = <AssistantEvaluationResult>[];
    final categoryCounts = <AssistantEvaluationCategory, int>{};
    final categoryPasses = <AssistantEvaluationCategory, int>{};

    for (final cat in AssistantEvaluationCategory.values) {
      categoryCounts[cat] = 0;
      categoryPasses[cat] = 0;
    }

    int totalIntentCases = 0;
    int passedIntentCases = 0;

    int totalRetrievalCases = 0;
    int passedRetrievalCases = 0;

    int totalGroundedCases = 0;
    int passedGroundedCases = 0;

    int hallucinationCases = 0;
    int privacyViolations = 0;
    int privacyCases = 0;

    int totalLanguageCases = 0;
    int passedLanguageCases = 0;

    int totalLatencyMs = 0;

    for (final testCase in dataset) {
      final res = await evaluateCase(testCase);
      results.add(res);

      categoryCounts[testCase.category] = (categoryCounts[testCase.category] ?? 0) + 1;
      if (res.passed) {
        categoryPasses[testCase.category] = (categoryPasses[testCase.category] ?? 0) + 1;
      }

      totalLatencyMs += res.latencyMs;

      // Intent accuracy tally
      if (testCase.expectedIntent != null) {
        totalIntentCases++;
        if (res.matchedIntent == testCase.expectedIntent) {
          passedIntentCases++;
        }
      }

      // Retrieval accuracy tally
      if (testCase.expectedKnowledgeIds.isNotEmpty) {
        totalRetrievalCases++;
        final hasMatch = testCase.expectedKnowledgeIds.any(
          (k) => res.retrievedKnowledgeIds.contains(k),
        );
        if (hasMatch) {
          passedRetrievalCases++;
        }
      }

      // Grounded answer accuracy tally
      if (testCase.requiredFacts.isNotEmpty) {
        totalGroundedCases++;
        if (res.requiredFactsPresent) {
          passedGroundedCases++;
        }
      }

      // Hallucination rate tally
      if (res.forbiddenClaimsDetected.isNotEmpty) {
        hallucinationCases++;
      }

      // Privacy violation rate tally
      if (testCase.category == AssistantEvaluationCategory.privacy) {
        privacyCases++;
        if (res.forbiddenClaimsDetected.isNotEmpty || !res.passed) {
          privacyViolations++;
        }
      }

      // Language parity tally
      if (testCase.expectedLanguage != null) {
        totalLanguageCases++;
        if (res.detectedLanguage == testCase.expectedLanguage) {
          passedLanguageCases++;
        }
      }
    }

    final totalCases = dataset.length;
    final passedCases = results.where((r) => r.passed).length;
    final failedCases = totalCases - passedCases;
    final failures = results.where((r) => !r.passed).toList();

    return AssistantEvaluationSummary(
      totalCases: totalCases,
      passedCases: passedCases,
      failedCases: failedCases,
      intentAccuracy: totalIntentCases > 0 ? passedIntentCases / totalIntentCases : 1.0,
      retrievalAccuracy: totalRetrievalCases > 0 ? passedRetrievalCases / totalRetrievalCases : 1.0,
      groundedAnswerAccuracy: totalGroundedCases > 0 ? passedGroundedCases / totalGroundedCases : 1.0,
      hallucinationRate: totalCases > 0 ? hallucinationCases / totalCases : 0.0,
      privacyViolationRate: privacyCases > 0 ? privacyViolations / privacyCases : 0.0,
      languageParity: totalLanguageCases > 0 ? passedLanguageCases / totalLanguageCases : 1.0,
      averageLatencyMs: totalCases > 0 ? totalLatencyMs / totalCases : 0.0,
      categoryCounts: categoryCounts,
      categoryPasses: categoryPasses,
      failures: failures,
      results: results,
    );
  }
}
