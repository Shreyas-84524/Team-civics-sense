import 'package:cloud_firestore/cloud_firestore.dart';

/// Rating type for chatbot assistant response quality.
enum ChatbotFeedbackType {
  upvote,
  downvote;

  String get value => name;

  static ChatbotFeedbackType? fromString(String? value) {
    if (value == null) return null;
    final clean = value.trim().toLowerCase();
    if (clean == 'upvote' || clean == 'helpful') return ChatbotFeedbackType.upvote;
    if (clean == 'downvote' || clean == 'unhelpful') return ChatbotFeedbackType.downvote;
    return null;
  }
}

/// Strongly typed record representing quality feedback on an assistant message in Firestore.
///
/// Designed for human-in-the-loop quality analysis and prompt/knowledge improvements,
/// with strict privacy shielding, maximum length bounds, and no automated retraining.
class ChatbotFeedbackRecord {
  static const int maxTextLength = 2000;

  final String feedbackId;
  final String sessionId;
  final String assistantMessageId;
  final String userMessageId;
  final String userMessage;
  final String assistantReply;
  final ChatbotFeedbackType feedbackType;
  final String language;
  final String? intentCategory;
  final String? currentScreen;
  final String? complaintStatus;
  final List<String> retrievedKnowledgeIds;
  final bool? retrievalSuccess;
  final String? providerMode;
  final int? responseLatencyMs;
  final String? knowledgeVersion;
  final String? assistantVersion;
  final String? ownerUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatbotFeedbackRecord({
    required this.feedbackId,
    required this.sessionId,
    required this.assistantMessageId,
    required this.userMessageId,
    required this.userMessage,
    required this.assistantReply,
    required this.feedbackType,
    required this.language,
    this.intentCategory,
    this.currentScreen,
    this.complaintStatus,
    this.retrievedKnowledgeIds = const [],
    this.retrievalSuccess,
    this.providerMode,
    this.responseLatencyMs,
    this.knowledgeVersion,
    this.assistantVersion,
    this.ownerUid,
    this.createdAt,
    this.updatedAt,
  });

  /// Sanitizes text to [maxTextLength] to prevent payload inflation while preserving content verbatim.
  static String sanitizeText(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= maxTextLength) return trimmed;
    return trimmed.substring(0, maxTextLength);
  }

  /// Builds a deterministic document identifier from session and message IDs.
  static String buildFeedbackId(String sessionId, String assistantMessageId) {
    final cleanSession = sessionId.trim().replaceAll('/', '_');
    final cleanMessage = assistantMessageId.trim().replaceAll('/', '_');
    return '${cleanSession}_$cleanMessage';
  }

  /// Converts record to a privacy-guaranteed Firestore JSON map adhering strictly to allowlisted keys.
  Map<String, dynamic> toFirestoreMap({bool isUpdate = false}) {
    final map = <String, dynamic>{
      'feedbackType': feedbackType.value,
      'language': language,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!isUpdate) {
      map['feedbackId'] = feedbackId;
      map['sessionId'] = sessionId;
      map['assistantMessageId'] = assistantMessageId;
      map['userMessageId'] = userMessageId;
      map['userMessage'] = sanitizeText(userMessage);
      map['assistantReply'] = sanitizeText(assistantReply);
      map['createdAt'] = FieldValue.serverTimestamp();

      if (ownerUid != null && ownerUid!.isNotEmpty) {
        map['ownerUid'] = ownerUid;
      }
      if (intentCategory != null && intentCategory!.isNotEmpty) {
        map['intentCategory'] = intentCategory;
      }
      if (currentScreen != null && currentScreen!.isNotEmpty) {
        map['currentScreen'] = currentScreen;
      }
      if (complaintStatus != null && complaintStatus!.isNotEmpty) {
        map['complaintStatus'] = complaintStatus;
      }
      if (retrievedKnowledgeIds.isNotEmpty) {
        map['retrievedKnowledgeIds'] = retrievedKnowledgeIds;
      }
      if (retrievalSuccess != null) {
        map['retrievalSuccess'] = retrievalSuccess;
      }
      if (providerMode != null && providerMode!.isNotEmpty) {
        map['providerMode'] = providerMode;
      }
      if (responseLatencyMs != null) {
        map['responseLatencyMs'] = responseLatencyMs;
      }
      if (knowledgeVersion != null && knowledgeVersion!.isNotEmpty) {
        map['knowledgeVersion'] = knowledgeVersion;
      }
      if (assistantVersion != null && assistantVersion!.isNotEmpty) {
        map['assistantVersion'] = assistantVersion;
      }
    }

    return map;
  }

  /// Converts record to a plain Dart Map for local testing/mocking.
  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'sessionId': sessionId,
      'assistantMessageId': assistantMessageId,
      'userMessageId': userMessageId,
      'userMessage': sanitizeText(userMessage),
      'assistantReply': sanitizeText(assistantReply),
      'feedbackType': feedbackType.value,
      'language': language,
      'intentCategory': intentCategory,
      'currentScreen': currentScreen,
      'complaintStatus': complaintStatus,
      'retrievedKnowledgeIds': retrievedKnowledgeIds,
      'retrievalSuccess': retrievalSuccess,
      'providerMode': providerMode,
      'responseLatencyMs': responseLatencyMs,
      'knowledgeVersion': knowledgeVersion,
      'assistantVersion': assistantVersion,
      'ownerUid': ownerUid,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Deserializes a Firestore document snapshot map into [ChatbotFeedbackRecord].
  factory ChatbotFeedbackRecord.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawType = map['feedbackType'] as String?;
    final feedbackType = ChatbotFeedbackType.fromString(rawType) ?? ChatbotFeedbackType.upvote;

    final knowledgeIdsRaw = map['retrievedKnowledgeIds'];
    final List<String> knowledgeIds = knowledgeIdsRaw is List
        ? knowledgeIdsRaw.map((e) => e.toString()).toList()
        : const [];

    return ChatbotFeedbackRecord(
      feedbackId: (map['feedbackId'] as String?) ?? docId,
      sessionId: (map['sessionId'] as String?) ?? '',
      assistantMessageId: (map['assistantMessageId'] as String?) ?? '',
      userMessageId: (map['userMessageId'] as String?) ?? '',
      userMessage: (map['userMessage'] as String?) ?? '',
      assistantReply: (map['assistantReply'] as String?) ?? '',
      feedbackType: feedbackType,
      language: (map['language'] as String?) ?? 'en',
      intentCategory: map['intentCategory'] as String?,
      currentScreen: map['currentScreen'] as String?,
      complaintStatus: map['complaintStatus'] as String?,
      retrievedKnowledgeIds: knowledgeIds,
      retrievalSuccess: map['retrievalSuccess'] as bool?,
      providerMode: map['providerMode'] as String?,
      responseLatencyMs: (map['responseLatencyMs'] as num?)?.toInt(),
      knowledgeVersion: map['knowledgeVersion'] as String?,
      assistantVersion: map['assistantVersion'] as String?,
      ownerUid: map['ownerUid'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  ChatbotFeedbackRecord copyWith({
    String? feedbackId,
    String? sessionId,
    String? assistantMessageId,
    String? userMessageId,
    String? userMessage,
    String? assistantReply,
    ChatbotFeedbackType? feedbackType,
    String? language,
    String? intentCategory,
    String? currentScreen,
    String? complaintStatus,
    List<String>? retrievedKnowledgeIds,
    bool? retrievalSuccess,
    String? providerMode,
    int? responseLatencyMs,
    String? knowledgeVersion,
    String? assistantVersion,
    String? ownerUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatbotFeedbackRecord(
      feedbackId: feedbackId ?? this.feedbackId,
      sessionId: sessionId ?? this.sessionId,
      assistantMessageId: assistantMessageId ?? this.assistantMessageId,
      userMessageId: userMessageId ?? this.userMessageId,
      userMessage: userMessage ?? this.userMessage,
      assistantReply: assistantReply ?? this.assistantReply,
      feedbackType: feedbackType ?? this.feedbackType,
      language: language ?? this.language,
      intentCategory: intentCategory ?? this.intentCategory,
      currentScreen: currentScreen ?? this.currentScreen,
      complaintStatus: complaintStatus ?? this.complaintStatus,
      retrievedKnowledgeIds: retrievedKnowledgeIds ?? this.retrievedKnowledgeIds,
      retrievalSuccess: retrievalSuccess ?? this.retrievalSuccess,
      providerMode: providerMode ?? this.providerMode,
      responseLatencyMs: responseLatencyMs ?? this.responseLatencyMs,
      knowledgeVersion: knowledgeVersion ?? this.knowledgeVersion,
      assistantVersion: assistantVersion ?? this.assistantVersion,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
