import '../../core/assistant/config/civic_assistant_prompt.dart';
import '../../core/assistant/controller/civic_assistant_controller.dart';
import '../../core/assistant/models/assistant_app_context.dart';
import '../../core/assistant/models/assistant_conversation_history.dart';
import '../../core/assistant/models/assistant_rag_context.dart';
import '../../core/assistant/services/civic_assistant_provider.dart';
import '../../core/models/assistant_message_model.dart';

/// Service providing conversational assistance and intent routing for CivicFix Assistant.
///
/// Implements production release standards with safe local fallback, context-aware suggestions,
/// and privacy-guaranteed routing.
class CivicAssistantService {
  static final CivicAssistantService _instance = CivicAssistantService._internal();
  factory CivicAssistantService() => _instance;
  CivicAssistantService._internal();

  final CivicAssistantProvider _provider = CompositeCivicAssistantProvider();

  /// Generates the centralized AI system instruction adhering to active locale and terminology.
  static String generateLanguageSystemPrompt(
    String languageCode, {
    AssistantAppContext? appContext,
  }) {
    return CivicAssistantPromptBuilder.buildSystemInstruction(
      languageCode: languageCode,
      appContext: appContext,
    );
  }

  /// Initial welcome greeting tailored to the requested locale and context.
  static String getWelcomeGreeting(String languageCode, {AssistantAppContext? context}) {
    return CivicAssistantController.getWelcomeGreeting(languageCode, context: context);
  }

  /// Quick suggested questions when the chat is started.
  static List<String> getSuggestedPrompts(String languageCode, {AssistantAppContext? context}) {
    return CivicAssistantController.getSuggestedPrompts(languageCode, context: context);
  }

  /// Processes user queries using semantic intent routing, conversation history, and verified grounding.
  Future<AssistantMessage> processQuery({
    required String query,
    required String languageCode,
    AssistantConversationHistory? history,
    AssistantAppContext? appContext,
    AssistantRagContext? ragContext,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: _getFallbackText(languageCode),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: getSuggestedPrompts(languageCode, context: appContext),
      );
    }

    try {
      final reply = await _provider.generateResponse(
        query: clean,
        languageCode: languageCode,
        history: history,
        appContext: appContext,
        ragContext: ragContext,
      );
      return reply.copyWith(
        metadata: {
          ...?reply.metadata,
          'userMessage': clean,
        },
      );
    } catch (_) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: "I'm having trouble responding right now. Please try again.",
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        isError: true,
        followUpSuggestions: getSuggestedPrompts(languageCode, context: appContext),
        metadata: {
          'userMessage': clean,
        },
      );
    }
  }

  String _getFallbackText(String languageCode) {
    switch (languageCode.trim().toLowerCase()) {
      case 'hi':
        return "मुझे इसके बारे में सटीक जानकारी नहीं है। कृपया समस्या दर्ज करने, स्थिति ट्रैक करने, या CivicFix के बारे में पूछें।";
      case 'mr':
        return "मला याबद्दल पुरेशी माहिती नाही. कृपया तक्रार नोंदवणे, स्थिती तपासणे, किंवा CivicFix विषयी विचारा.";
      case 'en':
      default:
        return "I don't have enough verified CivicFix information to answer that accurately yet. Try asking about reporting an issue, complaint statuses, or tracking your grievance.";
    }
  }
}
