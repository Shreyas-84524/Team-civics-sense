import 'dart:math';
import 'package:flutter/foundation.dart';
import '../knowledge/civic_assistant_knowledge.dart';
import '../knowledge/knowledge_entry.dart';
import '../models/assistant_app_context.dart';
import '../models/civic_assistant_intent.dart';
import 'assistant_rag_retriever.dart';
import 'query_normalizer.dart';
import 'retrieval_models.dart';

/// High-performance local hybrid RAG retriever for the CivicFix Assistant.
///
/// Combines normalized token overlap, domain alias expansion, intent-aware topic boosting,
/// exact code matching, bounded related-topic expansion, and confidence thresholding.
class CivicAssistantHybridRetriever implements AssistantRagRetriever {
  /// Default singleton instance.
  static final CivicAssistantHybridRetriever instance = CivicAssistantHybridRetriever();

  @override
  AssistantRetrievalResult retrieve(AssistantRetrievalRequest request) {
    final stopwatch = Stopwatch()..start();

    // 1. Casual Intent Bypass (Greetings, Small Talk, Out of Scope skip RAG)
    if (_shouldBypassRetrieval(request.intent)) {
      return AssistantRetrievalResult.bypassed(
        query: request.query,
        reason: 'intent_${request.intent.name}_bypassed',
      );
    }

    final rawQuery = request.query.trim();
    if (rawQuery.isEmpty) {
      return AssistantRetrievalResult.empty(
        query: request.query,
        normalizedQuery: '',
      );
    }

    // 2. Query Normalization & Token Extraction
    final cleanQuery = QueryNormalizer.cleanText(rawQuery);
    final queryTokens = QueryNormalizer.extractTokens(rawQuery);
    final expandedTokens = QueryNormalizer.getExpandedTokenSet(rawQuery);

    // 3. Multi-turn Contextual & App Context Query Enrichment
    final contextTokens = _extractMultiTurnContextTokens(request);
    final appContextTokens = _extractAppContextTokens(request);
    expandedTokens.addAll(contextTokens);
    expandedTokens.addAll(appContextTokens);

    if (queryTokens.isEmpty && contextTokens.isEmpty && appContextTokens.isEmpty) {
      return AssistantRetrievalResult.empty(
        query: request.query,
        normalizedQuery: cleanQuery,
      );
    }

    // 4. Multi-Factor Candidate Scoring
    final scoredEntries = <_ScoredEntry>[];

    for (final entry in CivicAssistantKnowledge.allEntries) {
      final scoreResult = _calculateScore(
        entry: entry,
        cleanQuery: cleanQuery,
        queryTokens: queryTokens,
        expandedTokens: expandedTokens,
        intent: request.intent,
        appContext: request.appContext,
      );

      if (scoreResult.score >= request.config.minScoreThreshold) {
        scoredEntries.add(_ScoredEntry(
          entry: entry,
          score: scoreResult.score,
          matchReason: scoreResult.reason,
        ));
      }
    }

    // If no candidate passes confidence threshold, return clean empty result
    if (scoredEntries.isEmpty) {
      stopwatch.stop();
      return AssistantRetrievalResult.empty(
        query: request.query,
        normalizedQuery: cleanQuery,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        diagnostics: {
          'evaluatedCount': CivicAssistantKnowledge.allEntries.length,
          'passedThresholdCount': 0,
        },
      );
    }

    // 5. Rank Descending
    scoredEntries.sort((a, b) => b.score.compareTo(a.score));

    // 6. Top-K Truncation
    final selectedScored = scoredEntries.take(request.config.maxResults).toList();
    final selectedIds = selectedScored.map((s) => s.entry.id).toSet();

    // 7. Bounded Related Topic Expansion (1-hop)
    if (request.config.enableRelatedExpansion &&
        selectedScored.isNotEmpty &&
        request.config.maxRelatedExpansion > 0) {
      final topEntry = selectedScored.first.entry;
      int addedRelated = 0;

      for (final relatedId in topEntry.relatedTopics) {
        if (addedRelated >= request.config.maxRelatedExpansion) break;
        if (!selectedIds.contains(relatedId)) {
          final relatedEntry = CivicAssistantKnowledge.getById(relatedId);
          if (relatedEntry != null) {
            selectedScored.add(_ScoredEntry(
              entry: relatedEntry,
              score: max(15.0, selectedScored.first.score * 0.7),
              matchReason: 'related_topic_expansion_from_${topEntry.id}',
            ));
            selectedIds.add(relatedId);
            addedRelated++;
          }
        }
      }
    }

    // 8. Convert to Prompt-Ready Chunks
    final chunks = selectedScored.map((s) {
      return AssistantRetrievedChunk(
        id: s.entry.id,
        title: s.entry.title,
        topic: s.entry.topic,
        content: s.entry.canonicalContent,
        score: s.score,
        matchReason: s.matchReason,
        sourceReference: s.entry.sourceReference,
        relatedTopics: s.entry.relatedTopics,
      );
    }).toList();

    stopwatch.stop();

    final result = AssistantRetrievalResult(
      query: request.query,
      normalizedQuery: cleanQuery,
      chunks: chunks,
      retrievedKnowledgeIds: chunks.map((c) => c.id).toList(),
      topicsUsed: chunks.map((c) => c.topic).toSet().toList(),
      topScore: chunks.isNotEmpty ? chunks.first.score : 0.0,
      executionTimeMs: stopwatch.elapsedMilliseconds,
      diagnostics: {
        'cleanQuery': cleanQuery,
        'tokens': queryTokens,
        'expandedTokens': expandedTokens.toList(),
        'contextTokens': contextTokens.toList(),
        'intent': request.intent.name,
        'evaluatedCount': CivicAssistantKnowledge.allEntries.length,
        'matchedCount': chunks.length,
      },
    );

    // 9. Debug Logging (Non-production diagnostics without sensitive data)
    if (request.config.debugMode || kDebugMode) {
      _logDiagnostics(result);
    }

    return result;
  }

  // --- Scoring & Helper Methods ---

  static bool _shouldBypassRetrieval(CivicAssistantIntent intent) {
    return intent == CivicAssistantIntent.casualGreeting ||
        intent == CivicAssistantIntent.casualSmallTalk ||
        intent == CivicAssistantIntent.outOfScopeGeneral;
  }

  static Set<String> _extractMultiTurnContextTokens(AssistantRetrievalRequest request) {
    final tokens = <String>{};
    final history = request.history;
    if (history == null || history.isEmpty) return tokens;

    final cleanQuery = request.query.toLowerCase();
    final isFollowUp = cleanQuery.contains('what next') ||
        cleanQuery.contains('what happens next') ||
        cleanQuery.contains('who handles') ||
        cleanQuery.contains('how long') ||
        cleanQuery.contains('how many hours') ||
        cleanQuery.contains('deadline') ||
        cleanQuery.contains('sla') ||
        cleanQuery.contains('why') ||
        cleanQuery.contains('then what') ||
        cleanQuery.contains('what about that');

    if (isFollowUp) {
      final lastUser = history.lastUserQuery ?? '';
      final lastReply = history.lastAssistantReply ?? '';
      final combined = '${lastUser.toLowerCase()} ${lastReply.toLowerCase()}';

      // Extract specific domain anchors from prior turn
      if (lastUser.contains('under verification') ||
          (!lastUser.contains('assigned') && combined.contains('under verification'))) {
        tokens.addAll(['assigned', 'stage_3', 'stage 3', 'lifecycle_assigned', 'dispatch', 'junior engineer']);
      } else if (combined.contains('reported') || combined.contains('stage 1')) {
        tokens.addAll(['reported', 'ticket', 'sla']);
      } else if (combined.contains('assigned') || combined.contains('junior engineer')) {
        tokens.addAll(['assigned', 'junior', 'engineer', 'field', 'officer']);
      }
      if (combined.contains('rework') || combined.contains('reopen')) {
        tokens.addAll(['rework', 'reopen', 'quality', 'audit']);
      }
      if (combined.contains('pothole') || combined.contains('road')) {
        if (cleanQuery.contains('hours') || cleanQuery.contains('how long') || cleanQuery.contains('deadline') || cleanQuery.contains('sla')) {
          tokens.addAll(['pothole', 'sla', '48', 'hours']);
        } else {
          tokens.addAll(['pothole', 'roads', 'maintenance']);
        }
      }
      if (combined.contains('garbage') || combined.contains('waste')) {
        if (cleanQuery.contains('hours') || cleanQuery.contains('how long') || cleanQuery.contains('deadline') || cleanQuery.contains('sla')) {
          tokens.addAll(['garbage', 'sla', '12', 'hours', 'solid_waste']);
        } else {
          tokens.addAll(['garbage', 'waste', 'swm']);
        }
      }
    }

    return tokens;
  }

  static Set<String> _extractAppContextTokens(AssistantRetrievalRequest request) {
    final tokens = <String>{};
    final context = request.appContext;
    if (context == null) return tokens;

    final cleanQuery = request.query.toLowerCase();
    final isContextualQuery = cleanQuery.contains('what next') ||
        cleanQuery.contains('what happens next') ||
        cleanQuery.contains('what is happening') ||
        cleanQuery.contains('what happens') ||
        cleanQuery.contains('status') ||
        cleanQuery.contains('assigned') ||
        cleanQuery.contains('work started') ||
        cleanQuery.contains('blocked') ||
        cleanQuery.contains('reopen') ||
        cleanQuery.contains('rework') ||
        cleanQuery.contains('track') ||
        cleanQuery.contains('sync') ||
        cleanQuery.contains('department') ||
        cleanQuery.contains('ward') ||
        cleanQuery.contains('how does this screen work') ||
        cleanQuery.contains('what do i do here') ||
        cleanQuery.contains('who is handling') ||
        cleanQuery.contains('who handles');

    if (isContextualQuery) {
      if (context.isUnderVerification) {
        tokens.addAll(['verification', 'under', 'assigned', 'lifecycle']);
      } else if (context.isAssigned) {
        tokens.addAll(['assigned', 'junior', 'engineer', 'field', 'officer', 'execution']);
      } else if (context.isInProgress) {
        tokens.addAll(['progress', 'field', 'officer', 'execution', 'repair']);
      } else if (context.isResolved) {
        tokens.addAll(['resolved', 'resolution', 'rework', 'closure', 'audit']);
      } else if (context.isClosed) {
        tokens.addAll(['closed', 'completion', 'lifecycle']);
      }

      if (context.isBlocked) {
        tokens.addAll(['blocked', 'obstacle', 'field_execution']);
      }

      if (context.isReopened || context.reopenCount > 0) {
        tokens.addAll(['rework', 'reopen', 'reopened', 'quality', 'audit', 'sla']);
      }

      if (context.isOfflinePending) {
        tokens.addAll(['offline', 'sync', 'pending', 'queue']);
      }

      if (context.currentScreen == 'map') {
        tokens.addAll(['map', 'gis', 'hazard', 'clusters']);
      }

      if (context.currentScreen == 'reportIssue') {
        tokens.addAll(['report', 'workflow', 'evidence', 'location']);
      }
    }

    return tokens;
  }

  static _ScoreDetail _calculateScore({
    required KnowledgeEntry entry,
    required String cleanQuery,
    required List<String> queryTokens,
    required Set<String> expandedTokens,
    required CivicAssistantIntent intent,
    AssistantAppContext? appContext,
  }) {
    double score = 0.0;
    String primaryReason = 'token_overlap';

    final entryIdLower = entry.id.toLowerCase();
    final titleLower = entry.title.toLowerCase();
    final contentLower = entry.canonicalContent.toLowerCase();

    // 1. Exact ID Match (e.g. 'dept_maintenance_roads', 'ward_k_west')
    if (cleanQuery == entryIdLower ||
        entryIdLower == cleanQuery.replaceAll(RegExp(r'\s+'), '_')) {
      score += 100.0;
      primaryReason = 'exact_id_match';
    }

    // 2. Department & Ward Code Direct Matches (Bounded with word boundaries)
    if (entry.topic == 'departments') {
      final deptCode = entryIdLower.replaceFirst('dept_', '');
      final deptSpace = deptCode.replaceAll('_', ' ');
      final hasDeptMatch = RegExp(r'\b' + RegExp.escape(deptCode) + r'\b').hasMatch(cleanQuery) ||
          RegExp(r'\b' + RegExp.escape(deptSpace) + r'\b').hasMatch(cleanQuery);
      if (hasDeptMatch) {
        score += 80.0;
        primaryReason = 'exact_department_code_match';
      }
    } else if (entry.topic == 'wards') {
      final rawWard = entryIdLower.replaceFirst('ward_', '');
      final slashWard = rawWard.replaceAll('_', '/');
      final dashWard = rawWard.replaceAll('_', '-');
      final spaceWard = rawWard.replaceAll('_', ' ');

      // Only match if explicit "ward X" or compound ward names like "f/north", "k/west", "g south"
      final hasWardPrefix = RegExp(r'\bward\s+(' + RegExp.escape(slashWard) + r'|' + RegExp.escape(dashWard) + r'|' + RegExp.escape(rawWard) + r')\b').hasMatch(cleanQuery);
      final hasCompoundWard = rawWard.contains('_') && (
        RegExp(r'\b' + RegExp.escape(slashWard) + r'\b').hasMatch(cleanQuery) ||
        RegExp(r'\b' + RegExp.escape(dashWard) + r'\b').hasMatch(cleanQuery) ||
        RegExp(r'\b' + RegExp.escape(spaceWard) + r'\b').hasMatch(cleanQuery)
      );

      if (hasWardPrefix || hasCompoundWard) {
        score += 80.0;
        primaryReason = 'exact_ward_code_match';
      }
    }

    // 3. Title Matching
    if (titleLower == cleanQuery) {
      score += 100.0;
      primaryReason = 'exact_title_match';
    } else if (titleLower.contains(cleanQuery) || cleanQuery.contains(titleLower)) {
      score += 65.0;
      primaryReason = 'title_phrase_match';
    } else {
      int titleTokenMatches = 0;
      for (final token in expandedTokens) {
        if (titleLower.contains(token)) {
          titleTokenMatches++;
        }
      }
      if (titleTokenMatches > 0) {
        score += titleTokenMatches * 20.0;
        primaryReason = 'title_token_match';
      }
    }

    // 4. Tag Matching
    int tagMatches = 0;
    for (final tag in entry.tags) {
      final tagLower = tag.toLowerCase();
      if (tagLower == cleanQuery) {
        score += 120.0;
        primaryReason = 'exact_tag_match';
      } else if (tagLower.length >= 4 &&
          (cleanQuery.contains(tagLower) || tagLower.contains(cleanQuery))) {
        score += 35.0;
        primaryReason = 'tag_phrase_match';
      } else {
        for (final token in expandedTokens) {
          if (tagLower.contains(token)) {
            tagMatches++;
          }
        }
      }
    }
    score += tagMatches * 15.0;

    // 5. Canonical Content Matching (Capped to prevent long entries from dominating)
    double contentScore = 0.0;
    if (contentLower.contains(cleanQuery)) {
      contentScore += 30.0;
    }
    int contentTokenMatches = 0;
    for (final token in expandedTokens) {
      if (contentLower.contains(token)) {
        contentTokenMatches++;
      }
    }
    contentScore += min(30.0, contentTokenMatches * 4.0);
    score += contentScore;

    // 6. Intent-Aware Topic Prioritization
    score += _getIntentTopicBoost(intent, entry.topic);

    // 7. Domain Keyword Topic Prioritization
    if ((cleanQuery.contains('department') || cleanQuery.contains('which dept')) &&
        entry.topic == 'departments') {
      score += 35.0;
    }
    if ((cleanQuery.contains('sla') ||
            cleanQuery.contains('how long') ||
            cleanQuery.contains('deadline') ||
            cleanQuery.contains('turnaround')) &&
        entry.topic == 'sla') {
      score += 30.0;
    }
    if ((cleanQuery.contains('map') ||
            cleanQuery.contains('pins') ||
            cleanQuery.contains('cluster')) &&
        entry.topic == 'map_gis') {
      score += 30.0;
    }
    if ((cleanQuery.contains('offline') ||
            cleanQuery.contains('internet') ||
            cleanQuery.contains('autosync') ||
            cleanQuery.contains('pending sync')) &&
        entry.topic == 'troubleshooting') {
      score += 30.0;
    }
    if ((cleanQuery.contains('photo') ||
            cleanQuery.contains('camera') ||
            cleanQuery.contains('exif') ||
            cleanQuery.contains('tamper') ||
            cleanQuery.contains('fraud') ||
            cleanQuery.contains('proof')) &&
        (entry.topic == 'evidence' || entry.topic == 'verification')) {
      score += 30.0;
    }

    // 8. App-Context Topic Prioritization
    if (appContext != null) {
      score += _getAppContextTopicBoost(appContext, entry.topic, entry.id);
    }

    return _ScoreDetail(score: score, reason: primaryReason);
  }

  static double _getAppContextTopicBoost(
    AssistantAppContext context,
    String topic,
    String entryId,
  ) {
    double boost = 0.0;
    if (context.isUnderVerification &&
        (topic == 'verification' || entryId.contains('verification'))) {
      boost += 20.0;
    }
    if (context.isAssigned &&
        (topic == 'roles' || topic == 'assignment' || entryId.contains('assigned'))) {
      boost += 20.0;
    }
    if (context.isInProgress &&
        (topic == 'field_execution' || entryId.contains('in_progress'))) {
      boost += 20.0;
    }
    if ((context.isReopened || context.reopenCount > 0) &&
        (topic == 'resolution_rework' || entryId.contains('rework'))) {
      boost += 25.0;
    }
    if (context.isBlocked &&
        (topic == 'field_execution' || entryId.contains('blocked'))) {
      boost += 20.0;
    }
    if (context.isOfflinePending && entryId == 'troubleshoot_offline_queue') {
      boost += 30.0;
    }
    if (context.currentScreen == 'map' && topic == 'map_gis') {
      boost += 20.0;
    }
    if (context.currentScreen == 'reportIssue' &&
        (topic == 'workflows' || topic == 'evidence')) {
      boost += 15.0;
    }
    return boost;
  }

  static double _getIntentTopicBoost(CivicAssistantIntent intent, String topic) {
    switch (intent) {
      case CivicAssistantIntent.civicfixProcess:
        const processTopics = {
          'lifecycle',
          'statuses',
          'roles',
          'assignment',
          'field_execution',
          'rework',
          'sla',
          'verification',
        };
        return processTopics.contains(topic) ? 25.0 : 0.0;

      case CivicAssistantIntent.civicfixHelp:
        const helpTopics = {
          'workflows',
          'categories',
          'evidence',
          'faq',
          'troubleshooting',
          'account',
        };
        return helpTopics.contains(topic) ? 25.0 : 0.0;

      case CivicAssistantIntent.civicfixNavigation:
        const navTopics = {'map_gis', 'workflows', 'overview'};
        return navTopics.contains(topic) ? 25.0 : 0.0;

      case CivicAssistantIntent.civicfixGeneral:
        const generalTopics = {'overview', 'departments', 'wards', 'faq'};
        return generalTopics.contains(topic) ? 25.0 : 0.0;

      case CivicAssistantIntent.casualGreeting:
      case CivicAssistantIntent.casualSmallTalk:
      case CivicAssistantIntent.outOfScopeGeneral:
      case CivicAssistantIntent.unknown:
        return 0.0;
    }
  }

  static void _logDiagnostics(AssistantRetrievalResult result) {
    final ids = result.retrievedKnowledgeIds.join(', ');
    final scoreStr = result.topScore.toStringAsFixed(1);
    debugPrint(
      '[CivicFix RAG] Query: "${result.query}" | TopScore: $scoreStr | Retrieved: [${ids.isEmpty ? "None" : ids}] (${result.executionTimeMs}ms)',
    );
  }
}

class _ScoredEntry {
  final KnowledgeEntry entry;
  final double score;
  final String matchReason;

  const _ScoredEntry({
    required this.entry,
    required this.score,
    required this.matchReason,
  });
}

class _ScoreDetail {
  final double score;
  final String reason;

  const _ScoreDetail({required this.score, required this.reason});
}
