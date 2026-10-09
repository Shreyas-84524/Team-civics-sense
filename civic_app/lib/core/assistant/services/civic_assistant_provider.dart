import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/assistant_message_model.dart';
import '../config/civic_assistant_config.dart';
import '../models/assistant_app_context.dart';
import '../models/assistant_conversation_history.dart';
import '../models/assistant_rag_context.dart';
import '../observability/assistant_analytics.dart';
import '../observability/assistant_error_type.dart';
import '../observability/assistant_observability.dart';
import '../retrieval/assistant_rag_retriever.dart';
import '../retrieval/civic_assistant_hybrid_retriever.dart';
import '../retrieval/retrieval_models.dart';
import '../routing/civic_assistant_intent_router.dart';
import 'assistant_language_resolver.dart';
import 'civic_assistant_conversation_engine.dart';

/// Abstract contract for assistant response generation.
abstract class CivicAssistantProvider {
  Future<AssistantMessage> generateResponse({
    required String query,
    required String languageCode,
    AssistantConversationHistory? history,
    AssistantAppContext? appContext,
    AssistantRagContext? ragContext,
  });
}

/// Deterministic, verified grounded provider using semantic intent routing and local knowledge.
///
/// Ensures 100% testable, zero-latency, offline-capable conversational baseline without external secrets.
class GroundedCivicAssistantProvider implements CivicAssistantProvider {
  final AssistantRagRetriever _retriever;

  GroundedCivicAssistantProvider({AssistantRagRetriever? retriever})
      : _retriever = retriever ?? CivicAssistantHybridRetriever.instance;

  @override
  Future<AssistantMessage> generateResponse({
    required String query,
    required String languageCode,
    AssistantConversationHistory? history,
    AssistantAppContext? appContext,
    AssistantRagContext? ragContext,
  }) async {
    final stopwatch = Stopwatch()..start();
    final sessionId = 'sess_${history?.hashCode ?? DateTime.now().millisecondsSinceEpoch}';

    // 0. Feature Flag Check
    if (!CivicAssistantConfig.current.assistantEnabled) {
      final errorType = AssistantErrorType.assistantDisabled;
      CivicAssistantObservability.instance.recordRequest(
        latencyMs: 0,
        isSuccess: false,
        errorType: errorType,
        languageCode: languageCode,
      );
      return AssistantMessage(
        id: 'disabled_${DateTime.now().millisecondsSinceEpoch}',
        text: errorType.userFriendlyMessage(languageCode),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        isError: true,
      );
    }

    // 1. Resolve Target Language using priority resolver
    final resolvedLang = AssistantLanguageResolver.resolve(
      query: query,
      appContext: appContext,
      history: history,
      requestedLanguage: languageCode,
    );
    final effectiveLanguageCode = resolvedLang.code;

    // 2. Semantic Intent Routing
    final intentResult = CivicAssistantIntentRouter.route(
      query: query,
      history: history,
    );

    CivicAssistantAnalytics.instance.logIntentClassified(
      sessionId: sessionId,
      intent: intentResult.intent,
      confidence: intentResult.confidence,
      isOutOfScope: intentResult.isOutOfScope,
    );

    // 3. Retrieve relevant RAG knowledge chunks if context was not explicitly supplied
    var effectiveRagContext = ragContext;
    if (effectiveRagContext == null) {
      final retrievalWatch = Stopwatch()..start();
      final retrievalResult = await _retriever.retrieve(
        AssistantRetrievalRequest(
          query: query,
          intent: intentResult.intent,
          intentConfidence: intentResult.confidence,
          history: history,
          appContext: appContext,
        ),
      );
      retrievalWatch.stop();

      CivicAssistantAnalytics.instance.logRetrievalCompleted(
        sessionId: sessionId,
        chunksCount: retrievalResult.chunks.length,
        topScore: retrievalResult.topScore,
        latencyMs: retrievalWatch.elapsedMilliseconds,
        isMiss: retrievalResult.chunks.isEmpty,
      );

      if (retrievalResult.chunks.isEmpty) {
        CivicAssistantObservability.instance.recordRetrievalMiss();
      }

      effectiveRagContext = AssistantRagContext.fromRetrievalResult(retrievalResult);
    }

    final rawResponse = CivicAssistantConversationEngine.generateResponse(
      query: query,
      intentResult: intentResult,
      languageCode: effectiveLanguageCode,
      history: history,
      ragContext: effectiveRagContext,
      appContext: appContext,
    );

    stopwatch.stop();
    final latencyMs = stopwatch.elapsedMilliseconds;

    CivicAssistantObservability.instance.recordRequest(
      latencyMs: latencyMs,
      isSuccess: !rawResponse.isError,
      intent: intentResult.intent.name,
      languageCode: effectiveLanguageCode,
    );

    CivicAssistantAnalytics.instance.logResponseGenerated(
      sessionId: sessionId,
      latencyMs: latencyMs,
      isFallback: false,
      isGrounded: true,
      isError: rawResponse.isError,
    );

    return rawResponse.copyWith(
      metadata: {
        'latencyMs': latencyMs,
        'intent': intentResult.intent.name,
        'isFallback': false,
        'isGrounded': true,
        'knowledgeVersion': CivicAssistantConfig.current.knowledgeVersion,
        'assistantVersion': CivicAssistantConfig.current.assistantVersion,
        'retrievalVersion': CivicAssistantConfig.current.retrievalVersion,
        'chunksCount': effectiveRagContext.chunks.length,
        'retrievedKnowledgeIds': effectiveRagContext.chunks.map((c) => c.id).toList(),
        'retrievalSuccess': effectiveRagContext.chunks.isNotEmpty,
        'providerMode': 'grounded',
        'language': effectiveLanguageCode,
        ...?rawResponse.metadata,
      },
    );
  }
}

/// Composite provider coordinating AI generation, fallback grounding, and sanitized error boundaries.
class CompositeCivicAssistantProvider implements CivicAssistantProvider {
  final CivicAssistantProvider _groundedProvider;
  final CivicAssistantProvider? _remoteAiProvider;
  final AssistantRagRetriever _retriever;

  CompositeCivicAssistantProvider({
    CivicAssistantProvider? groundedProvider,
    CivicAssistantProvider? remoteAiProvider,
    AssistantRagRetriever? retriever,
  })  : _retriever = retriever ?? CivicAssistantHybridRetriever.instance,
        _groundedProvider = groundedProvider ??
            GroundedCivicAssistantProvider(
              retriever: retriever ?? CivicAssistantHybridRetriever.instance,
            ),
        _remoteAiProvider = remoteAiProvider;

  @override
  Future<AssistantMessage> generateResponse({
    required String query,
    required String languageCode,
    AssistantConversationHistory? history,
    AssistantAppContext? appContext,
    AssistantRagContext? ragContext,
  }) async {
    final stopwatch = Stopwatch()..start();
    final sessionId = 'sess_${history?.hashCode ?? DateTime.now().millisecondsSinceEpoch}';

    // 0. Feature Flag Check
    if (!CivicAssistantConfig.current.assistantEnabled) {
      final errorType = AssistantErrorType.assistantDisabled;
      CivicAssistantObservability.instance.recordRequest(
        latencyMs: 0,
        isSuccess: false,
        errorType: errorType,
        languageCode: languageCode,
      );
      return AssistantMessage(
        id: 'disabled_${DateTime.now().millisecondsSinceEpoch}',
        text: errorType.userFriendlyMessage(languageCode),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        isError: true,
      );
    }

    try {
      // 1. Resolve Target Language
      final resolvedLang = AssistantLanguageResolver.resolve(
        query: query,
        appContext: appContext,
        history: history,
        requestedLanguage: languageCode,
      );
      final effectiveLanguageCode = resolvedLang.code;

      // 2. Semantic intent pre-classification
      final intentResult = CivicAssistantIntentRouter.route(
        query: query,
        history: history,
      );

      CivicAssistantAnalytics.instance.logIntentClassified(
        sessionId: sessionId,
        intent: intentResult.intent,
        confidence: intentResult.confidence,
        isOutOfScope: intentResult.isOutOfScope,
      );

      // 3. Intent-Aware RAG Retrieval
      var effectiveRagContext = ragContext;
      if (effectiveRagContext == null) {
        final retrievalWatch = Stopwatch()..start();
        final retrievalResult = await _retriever.retrieve(
          AssistantRetrievalRequest(
            query: query,
            intent: intentResult.intent,
            intentConfidence: intentResult.confidence,
            history: history,
            appContext: appContext,
          ),
        );
        retrievalWatch.stop();

        CivicAssistantAnalytics.instance.logRetrievalCompleted(
          sessionId: sessionId,
          chunksCount: retrievalResult.chunks.length,
          topScore: retrievalResult.topScore,
          latencyMs: retrievalWatch.elapsedMilliseconds,
          isMiss: retrievalResult.chunks.isEmpty,
        );

        if (retrievalResult.chunks.isEmpty) {
          CivicAssistantObservability.instance.recordRetrievalMiss();
        }

        effectiveRagContext = AssistantRagContext.fromRetrievalResult(retrievalResult);
      }

      // 4. High-confidence casual and verified civic intents resolve immediately via grounded provider
      if (intentResult.confidence >= 0.9 && !intentResult.isOutOfScope) {
        return await _groundedProvider.generateResponse(
          query: query,
          languageCode: effectiveLanguageCode,
          history: history,
          appContext: appContext,
          ragContext: effectiveRagContext,
        );
      }

      // 5. For complex queries, delegate to Remote AI only if enabled and configured
      if (CivicAssistantConfig.current.remoteAiEnabled && _remoteAiProvider != null) {
        try {
          final remoteResponse = await _remoteAiProvider.generateResponse(
            query: query,
            languageCode: effectiveLanguageCode,
            history: history,
            appContext: appContext,
            ragContext: effectiveRagContext,
          );
          stopwatch.stop();
          final latencyMs = stopwatch.elapsedMilliseconds;

          CivicAssistantObservability.instance.recordRequest(
            latencyMs: latencyMs,
            isSuccess: true,
            intent: intentResult.intent.name,
            languageCode: effectiveLanguageCode,
          );

          return remoteResponse.copyWith(
            metadata: {
              'latencyMs': latencyMs,
              'intent': intentResult.intent.name,
              'isFallback': false,
              'isGrounded': false,
              'knowledgeVersion': CivicAssistantConfig.current.knowledgeVersion,
              'assistantVersion': CivicAssistantConfig.current.assistantVersion,
              'retrievalVersion': CivicAssistantConfig.current.retrievalVersion,
              'retrievedKnowledgeIds': effectiveRagContext.chunks.map((c) => c.id).toList(),
              'retrievalSuccess': effectiveRagContext.chunks.isNotEmpty,
              'providerMode': 'remote_ai',
              'language': effectiveLanguageCode,
              ...?remoteResponse.metadata,
            },
          );
        } catch (e) {
          debugPrint('[CivicFix Assistant] Remote AI fallback to grounded provider: $e');
          final fallbackResponse = await _groundedProvider.generateResponse(
            query: query,
            languageCode: effectiveLanguageCode,
            history: history,
            appContext: appContext,
            ragContext: effectiveRagContext,
          );

          CivicAssistantObservability.instance.recordRequest(
            latencyMs: stopwatch.elapsedMilliseconds,
            isSuccess: true,
            isFallback: true,
            intent: intentResult.intent.name,
            languageCode: effectiveLanguageCode,
          );

          return fallbackResponse.copyWith(
            metadata: {
              ...?fallbackResponse.metadata,
              'isFallback': true,
              'fallbackReason': e.toString(),
            },
          );
        }
      }

      return await _groundedProvider.generateResponse(
        query: query,
        languageCode: effectiveLanguageCode,
        history: history,
        appContext: appContext,
        ragContext: effectiveRagContext,
      );
    } catch (e) {
      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMilliseconds;
      debugPrint('[CivicFix Assistant] Error during response generation: $e');

      final errorType = AssistantErrorType.unknownFailure;
      CivicAssistantObservability.instance.recordRequest(
        latencyMs: latencyMs,
        isSuccess: false,
        errorType: errorType,
        languageCode: languageCode,
      );

      CivicAssistantAnalytics.instance.logResponseGenerated(
        sessionId: sessionId,
        latencyMs: latencyMs,
        isFallback: false,
        isGrounded: false,
        isError: true,
        errorType: errorType,
      );

      final isHi = languageCode == 'hi';
      final isMr = languageCode == 'mr';

      final suggestions = isHi
          ? const ['सिविकफिक्स क्या है?', 'शिकायत कैसे दर्ज करें?', 'शिकायत कैसे ट्रैक करें?']
          : isMr
              ? const ['सिविकफिक्स काय आहे?', 'तक्रार कशी नोंदवायची?', 'तक्रार कशी ट्रॅक करायची?']
              : const ['What is CivicFix?', 'How do I report an issue?', 'How can I track my complaint?'];

      return AssistantMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: errorType.userFriendlyMessage(languageCode),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        isError: true,
        followUpSuggestions: suggestions,
        metadata: {
          'latencyMs': latencyMs,
          'isError': true,
          'errorType': errorType.name,
        },
      );
    }
  }
}
