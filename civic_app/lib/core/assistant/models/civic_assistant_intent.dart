/// Canonical intent categories for the CivicFix Assistant conversational routing layer.
enum CivicAssistantIntent {
  /// Casual greetings (e.g., "Hello", "Hi", "Good morning", "Hey").
  casualGreeting,

  /// Casual conversational small talk (e.g., "How are you?", "What are you doing?", "Thank you", "Who are you?").
  casualSmallTalk,

  /// High-level general information about CivicFix (e.g., "What is CivicFix?", "What does this app do?").
  civicfixGeneral,

  /// Grievance lifecycle, workflow, and post-submission stages (e.g., "What happens after I submit a complaint?", "What does Under Verification mean?", "Who handles my complaint?").
  civicfixProcess,

  /// Step-by-step reporting instructions, evidence upload, location selection, or category guidance (e.g., "How do I report a pothole?", "How to add photos?").
  civicfixHelp,

  /// In-app navigation guidance (e.g., "Where can I see my complaints?", "How do I open the Hazard Map?").
  civicfixNavigation,

  /// Harmless general questions outside CivicFix scope (e.g., "Tell me a joke", "What is the capital of Japan?").
  outOfScopeGeneral,

  /// Unknown or ungrounded input requiring conversational fallback or model reasoning.
  unknown,
}

/// Structured intent classification result from the intent routing layer.
class AssistantIntentResult {
  final CivicAssistantIntent intent;
  final double confidence;
  final String matchedRule;
  final Map<String, dynamic> slots;

  const AssistantIntentResult({
    required this.intent,
    this.confidence = 1.0,
    this.matchedRule = 'default',
    this.slots = const {},
  });

  bool get isCasual =>
      intent == CivicAssistantIntent.casualGreeting ||
      intent == CivicAssistantIntent.casualSmallTalk;

  bool get isCivic =>
      intent == CivicAssistantIntent.civicfixGeneral ||
      intent == CivicAssistantIntent.civicfixProcess ||
      intent == CivicAssistantIntent.civicfixHelp ||
      intent == CivicAssistantIntent.civicfixNavigation;

  bool get isOutOfScope => intent == CivicAssistantIntent.outOfScopeGeneral;
}
