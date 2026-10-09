/// Sender identity for civic assistant messages.
enum AssistantMessageSender {
  user,
  assistant,
}

/// Optional user feedback on assistant message quality.
enum AssistantFeedbackRating {
  helpful,
  unhelpful,
}

/// Message payload for Civic Assistant conversation.
class AssistantMessage {
  final String id;
  final String text;
  final AssistantMessageSender sender;
  final DateTime timestamp;
  final bool isError;
  final List<String> followUpSuggestions;
  final AssistantFeedbackRating? feedbackRating;
  final Map<String, dynamic>? metadata;

  const AssistantMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
    this.followUpSuggestions = const [],
    this.feedbackRating,
    this.metadata,
  });

  bool get isUser => sender == AssistantMessageSender.user;
  bool get isAssistant => sender == AssistantMessageSender.assistant;

  AssistantMessage copyWith({
    String? id,
    String? text,
    AssistantMessageSender? sender,
    DateTime? timestamp,
    bool? isError,
    List<String>? followUpSuggestions,
    AssistantFeedbackRating? feedbackRating,
    bool clearFeedbackRating = false,
    Map<String, dynamic>? metadata,
  }) {
    return AssistantMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
      feedbackRating: clearFeedbackRating ? null : (feedbackRating ?? this.feedbackRating),
      metadata: metadata ?? this.metadata,
    );
  }
}
