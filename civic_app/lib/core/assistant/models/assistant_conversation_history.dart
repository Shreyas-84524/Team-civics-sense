import '../../models/assistant_message_model.dart';

/// Single conversational turn between the citizen and the assistant.
class AssistantConversationTurn {
  final String userQuery;
  final String assistantReply;
  final DateTime timestamp;
  final String? intent;

  const AssistantConversationTurn({
    required this.userQuery,
    required this.assistantReply,
    required this.timestamp,
    this.intent,
  });
}

/// In-session conversation history manager providing a bounded sliding-window memory.
///
/// Ensures the assistant retains conversational context (e.g., follow-ups like "What happens next?")
/// while preventing unbounded token growth or memory leaks during long sessions.
class AssistantConversationHistory {
  /// Maximum number of recent messages retained in the context window.
  final int maxWindowSize;

  final List<AssistantMessage> _messages = [];

  AssistantConversationHistory({this.maxWindowSize = 10});

  List<AssistantMessage> get messages => List.unmodifiable(_messages);

  bool get isEmpty => _messages.isEmpty;
  bool get isNotEmpty => _messages.isNotEmpty;
  int get length => _messages.length;

  /// Adds a message to the in-session history and enforces the bounded sliding window.
  void addMessage(AssistantMessage message) {
    _messages.add(message);
    while (_messages.length > maxWindowSize) {
      _messages.removeAt(0);
    }
  }

  /// Updates an existing message in-place (e.g., for feedback ratings).
  bool updateMessage(String id, AssistantMessage updated) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _messages[index] = updated;
      return true;
    }
    return false;
  }

  /// Appends both a user query and an assistant reply.
  void addExchange(AssistantMessage userMsg, AssistantMessage assistantMsg) {
    addMessage(userMsg);
    addMessage(assistantMsg);
  }

  /// Retrieves the last user query in the session, if any.
  String? get lastUserQuery {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) return _messages[i].text;
    }
    return null;
  }

  /// Retrieves the last assistant reply in the session, if any.
  String? get lastAssistantReply {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isAssistant && !_messages[i].isError) {
        return _messages[i].text;
      }
    }
    return null;
  }

  /// Extracts structured conversational turns from the message history.
  List<AssistantConversationTurn> getRecentTurns() {
    final turns = <AssistantConversationTurn>[];
    String? pendingUser;
    DateTime? userTime;

    for (final msg in _messages) {
      if (msg.isUser) {
        pendingUser = msg.text;
        userTime = msg.timestamp;
      } else if (msg.isAssistant && pendingUser != null) {
        turns.add(
          AssistantConversationTurn(
            userQuery: pendingUser,
            assistantReply: msg.text,
            timestamp: userTime ?? msg.timestamp,
          ),
        );
        pendingUser = null;
      }
    }
    return turns;
  }

  /// Formats the bounded history into a clean multi-turn dialogue string for prompt injection.
  String toPromptHistoryString() {
    final turns = getRecentTurns();
    if (turns.isEmpty) return 'No previous conversation history.';

    final buffer = StringBuffer();
    for (int i = 0; i < turns.length; i++) {
      buffer.writeln('User: ${turns[i].userQuery}');
      buffer.writeln('Assistant: ${turns[i].assistantReply}');
    }
    return buffer.toString().trim();
  }

  /// Clears the in-session history.
  void clear() {
    _messages.clear();
  }
}
