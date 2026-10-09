import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/assistant_message_model.dart';
import '../config/civic_assistant_config.dart';
import '../models/assistant_app_context.dart';
import '../models/chatbot_feedback_record.dart';
import '../observability/assistant_analytics.dart';
import '../observability/assistant_observability.dart';

/// Abstract storage engine interface for chatbot feedback records.
abstract class CivicAssistantFeedbackEngine {
  Future<void> saveFeedback(ChatbotFeedbackRecord record, {bool isUpdate = false});
  Future<void> deleteFeedback(String feedbackId, {String? ownerUid});
  Future<ChatbotFeedbackRecord?> getFeedback(String feedbackId);
}

/// Firebase Cloud Firestore implementation of [CivicAssistantFeedbackEngine].
class FirestoreCivicAssistantFeedbackEngine implements CivicAssistantFeedbackEngine {
  static const String collectionName = 'chatbot_feedback';
  final FirebaseFirestore? _firestore;

  FirestoreCivicAssistantFeedbackEngine({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveFeedback(ChatbotFeedbackRecord record, {bool isUpdate = false}) async {
    final docRef = _db.collection(collectionName).doc(record.feedbackId);
    final data = record.toFirestoreMap(isUpdate: isUpdate);
    await docRef.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteFeedback(String feedbackId, {String? ownerUid}) async {
    final docRef = _db.collection(collectionName).doc(feedbackId);
    await docRef.delete();
  }

  @override
  Future<ChatbotFeedbackRecord?> getFeedback(String feedbackId) async {
    final docRef = _db.collection(collectionName).doc(feedbackId);
    final snap = await docRef.get();
    if (!snap.exists || snap.data() == null) return null;
    return ChatbotFeedbackRecord.fromMap(snap.data()!, snap.id);
  }
}

/// In-memory mock implementation of [CivicAssistantFeedbackEngine] for unit testing.
class MockCivicAssistantFeedbackEngine implements CivicAssistantFeedbackEngine {
  final Map<String, ChatbotFeedbackRecord> _storage = {};
  int saveCallCount = 0;
  int deleteCallCount = 0;
  bool shouldThrow = false;

  @override
  Future<void> saveFeedback(ChatbotFeedbackRecord record, {bool isUpdate = false}) async {
    if (shouldThrow) throw Exception('Simulated Firestore write error');
    saveCallCount++;
    if (isUpdate && _storage.containsKey(record.feedbackId)) {
      final existing = _storage[record.feedbackId]!;
      _storage[record.feedbackId] = existing.copyWith(
        feedbackType: record.feedbackType,
        language: record.language,
        updatedAt: DateTime.now(),
      );
    } else {
      _storage[record.feedbackId] = record.copyWith(
        createdAt: record.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteFeedback(String feedbackId, {String? ownerUid}) async {
    if (shouldThrow) throw Exception('Simulated Firestore delete error');
    deleteCallCount++;
    _storage.remove(feedbackId);
  }

  @override
  Future<ChatbotFeedbackRecord?> getFeedback(String feedbackId) async {
    if (shouldThrow) throw Exception('Simulated Firestore read error');
    return _storage[feedbackId];
  }

  void clear() {
    _storage.clear();
    saveCallCount = 0;
    deleteCallCount = 0;
    shouldThrow = false;
  }
}

/// Centralized service managing quality feedback persistence, vote transitions,
/// request serialization, and privacy-shielded telemetry.
class CivicAssistantFeedbackService {
  static final CivicAssistantFeedbackService _instance =
      CivicAssistantFeedbackService._internal();
  static CivicAssistantFeedbackService get instance => _instance;

  CivicAssistantFeedbackEngine _engine;
  final Map<String, Future<void>> _pendingOperations = {};

  CivicAssistantFeedbackService({CivicAssistantFeedbackEngine? engine})
      : _engine = engine ?? FirestoreCivicAssistantFeedbackEngine();

  CivicAssistantFeedbackService._internal()
      : _engine = FirestoreCivicAssistantFeedbackEngine();

  /// Injects a custom engine (used for unit & widget tests).
  void setEngine(CivicAssistantFeedbackEngine engine) {
    _engine = engine;
  }

  /// Resets to default production Firestore engine.
  void resetEngine() {
    _engine = FirestoreCivicAssistantFeedbackEngine();
  }

  /// Resolves the authenticated user ID if present, without exposing sensitive citizen data.
  String? _resolveOwnerUid(String? explicitUid) {
    if (explicitUid != null && explicitUid.isNotEmpty) return explicitUid;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Submits an upvote or downvote for an assistant message with privacy-safe telemetry.
  ///
  /// Serializes operations per message ID to prevent race conditions during rapid taps.
  Future<bool> submitFeedback({
    required String sessionId,
    required AssistantMessage assistantMessage,
    required AssistantMessage? userMessage,
    required AssistantFeedbackRating rating,
    AssistantAppContext? appContext,
    String? ownerUid,
    bool isUpdate = false,
  }) async {
    if (!CivicAssistantConfig.current.feedbackEnabled) return false;

    final messageId = assistantMessage.id;
    final feedbackId = ChatbotFeedbackRecord.buildFeedbackId(sessionId, messageId);
    final effectiveOwnerUid = _resolveOwnerUid(ownerUid);

    final feedbackType = rating == AssistantFeedbackRating.helpful
        ? ChatbotFeedbackType.upvote
        : ChatbotFeedbackType.downvote;

    // Resolve safe telemetry metadata from assistant message metadata
    final meta = assistantMessage.metadata ?? const {};
    final language = (meta['language'] as String?) ??
        (appContext?.selectedLanguage.isNotEmpty == true
            ? appContext!.selectedLanguage
            : 'en');
    final intent = meta['intent'] as String?;
    final currentScreen = appContext?.currentScreen;
    final complaintStatus = appContext?.complaintStatus;

    final knowledgeIdsRaw = meta['retrievedKnowledgeIds'];
    final List<String> retrievedKnowledgeIds = knowledgeIdsRaw is List
        ? knowledgeIdsRaw.map((e) => e.toString()).toList()
        : const [];
    final retrievalSuccess = meta['retrievalSuccess'] as bool? ??
        (retrievedKnowledgeIds.isNotEmpty ? true : null);
    final providerMode = meta['providerMode'] as String? ??
        (meta['isGrounded'] == true ? 'grounded' : 'composite');
    final latencyMs = (meta['latencyMs'] as num?)?.toInt();
    final knowledgeVersion = meta['knowledgeVersion'] as String? ??
        CivicAssistantConfig.current.knowledgeVersion;
    final assistantVersion = meta['assistantVersion'] as String? ??
        CivicAssistantConfig.current.assistantVersion;

    final triggeringUserText = userMessage?.text ??
        (meta['userMessage'] as String?) ??
        '[Initial System Greeting]';
    final triggeringUserId = userMessage?.id ??
        (meta['userMessageId'] as String?) ??
        'welcome_init';

    final record = ChatbotFeedbackRecord(
      feedbackId: feedbackId,
      sessionId: sessionId,
      assistantMessageId: messageId,
      userMessageId: triggeringUserId,
      userMessage: triggeringUserText,
      assistantReply: assistantMessage.text,
      feedbackType: feedbackType,
      language: language,
      intentCategory: intent,
      currentScreen: currentScreen,
      complaintStatus: complaintStatus,
      retrievedKnowledgeIds: retrievedKnowledgeIds,
      retrievalSuccess: retrievalSuccess,
      providerMode: providerMode,
      responseLatencyMs: latencyMs,
      knowledgeVersion: knowledgeVersion,
      assistantVersion: assistantVersion,
      ownerUid: effectiveOwnerUid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Request serialization per message ID
    final previousOp = _pendingOperations[messageId] ?? Future.value();
    final completer = Completer<void>();
    _pendingOperations[messageId] = completer.future;

    try {
      await previousOp;
      await _engine.saveFeedback(record, isUpdate: isUpdate);

      final isHelpful = rating == AssistantFeedbackRating.helpful;
      CivicAssistantObservability.instance.recordFeedback(isHelpful: isHelpful);
      CivicAssistantAnalytics.instance.logFeedbackSubmitted(
        sessionId: sessionId,
        messageId: messageId,
        rating: isHelpful ? 'helpful' : 'unhelpful',
        languageCode: language,
        intent: intent,
      );

      return true;
    } catch (e) {
      debugPrint('[CivicAssistantFeedbackService] Failed to persist feedback: $e');
      return false;
    } finally {
      completer.complete();
      if (_pendingOperations[messageId] == completer.future) {
        _pendingOperations.remove(messageId);
      }
    }
  }

  /// Removes an existing feedback record (used when user deselects their active vote).
  Future<bool> removeFeedback({
    required String sessionId,
    required String assistantMessageId,
    String? ownerUid,
  }) async {
    final feedbackId = ChatbotFeedbackRecord.buildFeedbackId(sessionId, assistantMessageId);
    final effectiveOwnerUid = _resolveOwnerUid(ownerUid);

    final previousOp = _pendingOperations[assistantMessageId] ?? Future.value();
    final completer = Completer<void>();
    _pendingOperations[assistantMessageId] = completer.future;

    try {
      await previousOp;
      await _engine.deleteFeedback(feedbackId, ownerUid: effectiveOwnerUid);
      return true;
    } catch (e) {
      debugPrint('[CivicAssistantFeedbackService] Failed to remove feedback: $e');
      return false;
    } finally {
      completer.complete();
      if (_pendingOperations[assistantMessageId] == completer.future) {
        _pendingOperations.remove(assistantMessageId);
      }
    }
  }

  /// Retrieves a persisted feedback record for verification/inspection.
  Future<ChatbotFeedbackRecord?> getFeedbackRecord({
    required String sessionId,
    required String assistantMessageId,
  }) async {
    final feedbackId = ChatbotFeedbackRecord.buildFeedbackId(sessionId, assistantMessageId);
    try {
      return await _engine.getFeedback(feedbackId);
    } catch (e) {
      debugPrint('[CivicAssistantFeedbackService] Failed to get feedback: $e');
      return null;
    }
  }
}
