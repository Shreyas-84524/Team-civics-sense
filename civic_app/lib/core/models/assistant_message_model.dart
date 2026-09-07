/// Sender identity for civic assistant messages.
enum AssistantMessageSender {
  user,
  assistant,
}

/// Message payload for Civic Assistant conversation.
class AssistantMessage {
  final String id;
  final String text;
  final AssistantMessageSender sender;
  final DateTime timestamp;
  final bool isError;
  final List<String> followUpSuggestions;

  const AssistantMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
    this.followUpSuggestions = const [],
  });

  bool get isUser => sender == AssistantMessageSender.user;
  bool get isAssistant => sender == AssistantMessageSender.assistant;
}
