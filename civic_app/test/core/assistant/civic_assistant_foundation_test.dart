import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/config/civic_assistant_prompt.dart';
import 'package:civic_app/core/assistant/controller/civic_assistant_controller.dart';
import 'package:civic_app/core/assistant/knowledge/civic_assistant_knowledge.dart';
import 'package:civic_app/core/assistant/models/assistant_app_context.dart';
import 'package:civic_app/core/assistant/models/assistant_conversation_history.dart';
import 'package:civic_app/core/assistant/models/assistant_rag_context.dart';
import 'package:civic_app/core/assistant/models/civic_assistant_intent.dart';
import 'package:civic_app/core/assistant/routing/civic_assistant_intent_router.dart';
import 'package:civic_app/core/models/assistant_message_model.dart';
import 'package:civic_app/User UI/services/assistant_service.dart';

void main() {
  group('CivicFix Chatbot Phase 2 — Conversational Foundation Tests', () {
    late CivicAssistantService assistantService;

    setUp(() {
      assistantService = CivicAssistantService();
    });

    // -------------------------------------------------------------
    // SECTION 1: CASUAL CONVERSATION & GREETINGS
    // -------------------------------------------------------------
    group('Section 1: Casual Greetings & Small Talk', () {
      test('Natural greetings do not force complaint flow', () async {
        final greetings = ['Hello', 'Hi', 'Hey', 'Good morning', 'Good evening', 'Namaste'];

        for (final greeting in greetings) {
          final reply = await assistantService.processQuery(
            query: greeting,
            languageCode: 'en',
          );

          expect(reply.isError, isFalse);
          expect(reply.isAssistant, isTrue);
          expect(reply.text, isNot(contains("I'm still learning how to help with that")));
          // Greeting response should be conversational and friendly
          expect(
            reply.text.toLowerCase(),
            anyOf([contains('how can i help'), contains('help you today'), contains('assist you')]),
          );
        }
      });

      test('Small talk queries receive natural conversational responses', () async {
        final smallTalkExchanges = {
          'How are you?': "I'm doing well",
          'What are you doing?': "I'm here to help with CivicFix",
          'Who are you?': "I'm the CivicFix Assistant",
          'Thank you': "You're very welcome",
          'Bye': "Goodbye",
        };

        for (final entry in smallTalkExchanges.entries) {
          final reply = await assistantService.processQuery(
            query: entry.key,
            languageCode: 'en',
          );

          expect(reply.isError, isFalse);
          expect(reply.text, contains(entry.value));
        }
      });
    });

    // -------------------------------------------------------------
    // SECTION 2: INTENT ROUTING & KEYWORD COLLISION REGRESSION
    // -------------------------------------------------------------
    group('Section 2: Intent Routing & Collision Fix', () {
      test('Resolves "What happens after I submit a complaint?" to PROCESS (NOT help)', () {
        final result = CivicAssistantIntentRouter.route(
          query: 'What happens after I submit a complaint?',
        );

        expect(result.intent, equals(CivicAssistantIntent.civicfixProcess));
        expect(result.matchedRule, equals('civicfix_process'));
      });

      test('"What happens after I submit a complaint?" returns lifecycle, not submission instructions', () async {
        final reply = await assistantService.processQuery(
          query: 'What happens after I submit a complaint?',
          languageCode: 'en',
        );

        expect(reply.text, contains('5-stage workflow'));
        expect(reply.text, contains('Reported'));
        expect(reply.text, contains('Under Verification'));
        expect(reply.text, contains('Assigned'));
        expect(reply.text, isNot(contains("Tap 'Report an Issue' on the Home screen")));
      });

      test('Resolves "How do I report a pothole?" to HELP', () {
        final result = CivicAssistantIntentRouter.route(
          query: 'How do I report a pothole?',
        );

        expect(result.intent, equals(CivicAssistantIntent.civicfixHelp));
      });

      test('"Can I edit a complaint after submitting it?" explains edit rules without collision', () async {
        final result = CivicAssistantIntentRouter.route(
          query: 'Can I edit a complaint after submitting it?',
        );

        expect(result.intent, equals(CivicAssistantIntent.civicfixHelp));

        final reply = await assistantService.processQuery(
          query: 'Can I edit a complaint after submitting it?',
          languageCode: 'en',
        );

        expect(reply.text, contains('cannot be directly edited'));
      });

      test('CivicFix general questions route correctly', () {
        final result = CivicAssistantIntentRouter.route(
          query: 'What is CivicFix?',
        );

        expect(result.intent, equals(CivicAssistantIntent.civicfixGeneral));
      });

      test('Under verification definition routes to PROCESS', () {
        final result = CivicAssistantIntentRouter.route(
          query: 'What does Under Verification mean?',
        );

        expect(result.intent, equals(CivicAssistantIntent.civicfixProcess));
      });

      test('Navigation questions route correctly', () {
        final result = CivicAssistantIntentRouter.route(
          query: 'Where can I see my complaints?',
        );

        expect(result.intent, equals(CivicAssistantIntent.civicfixNavigation));
      });

      test('Out of scope questions route correctly', () {
        final result = CivicAssistantIntentRouter.route(
          query: 'Tell me a joke',
        );

        expect(result.intent, equals(CivicAssistantIntent.outOfScopeGeneral));
      });
    });

    // -------------------------------------------------------------
    // SECTION 3: SHORT-TERM SESSION MEMORY & MULTI-TURN CONTEXT
    // -------------------------------------------------------------
    group('Section 3: Session Memory & Multi-turn Reasoning', () {
      test('Retains context for follow-up "What happens next?" after Under Verification', () async {
        final history = AssistantConversationHistory(maxWindowSize: 10);

        // Turn 1: User asks about under verification
        final userMsg1 = AssistantMessage(
          id: 'u1',
          text: 'My complaint is under verification.',
          sender: AssistantMessageSender.user,
          timestamp: DateTime.now(),
        );
        history.addMessage(userMsg1);

        final reply1 = await assistantService.processQuery(
          query: userMsg1.text,
          languageCode: 'en',
          history: history,
        );
        history.addMessage(reply1);

        // Turn 2: Follow-up "What happens next?"
        final userMsg2 = AssistantMessage(
          id: 'u2',
          text: 'What happens next?',
          sender: AssistantMessageSender.user,
          timestamp: DateTime.now(),
        );
        history.addMessage(userMsg2);

        final reply2 = await assistantService.processQuery(
          query: userMsg2.text,
          languageCode: 'en',
          history: history,
        );

        expect(reply2.isError, isFalse);
        expect(reply2.text, contains('Stage 3'));
        expect(reply2.text, contains('Junior Engineer'));
      });

      test('Enforces sliding window limit on conversation history', () {
        final history = AssistantConversationHistory(maxWindowSize: 4);

        for (int i = 1; i <= 6; i++) {
          history.addMessage(
            AssistantMessage(
              id: 'msg_$i',
              text: 'Message $i',
              sender: i % 2 == 0 ? AssistantMessageSender.assistant : AssistantMessageSender.user,
              timestamp: DateTime.now(),
            ),
          );
        }

        expect(history.length, equals(4));
        expect(history.messages.first.text, equals('Message 3'));
        expect(history.messages.last.text, equals('Message 6'));
      });
    });

    // -------------------------------------------------------------
    // SECTION 4: CENTRAL PROMPT & ARCHITECTURE
    // -------------------------------------------------------------
    group('Section 4: Prompt Architecture & Future Interfaces', () {
      test('Builds structured prompt with all 5 layers', () {
        final history = AssistantConversationHistory();
        history.addMessage(
          AssistantMessage(
            id: '1',
            text: 'Hello',
            sender: AssistantMessageSender.user,
            timestamp: DateTime.now(),
          ),
        );

        final appContext = const AssistantAppContext(
          userRole: 'citizen',
          selectedTicketNumber: 'CF-2026-000024',
          complaintStatus: 'inProgress',
          selectedLanguage: 'en',
        );

        final ragContext = const AssistantRagContext(
          retrievedSnippets: ['SOP: Road repair requires 48hr turnaround.'],
          isGrounded: true,
        );

        final fullPrompt = CivicAssistantPromptBuilder.buildFullPrompt(
          userQuery: 'When will it be fixed?',
          languageCode: 'en',
          history: history,
          appContext: appContext,
          ragContext: ragContext,
        );

        expect(fullPrompt, contains('=== SYSTEM INSTRUCTIONS ==='));
        expect(fullPrompt, contains('=== VERIFIED CIVICFIX DOCUMENTATION (AUTHORITATIVE) ==='));
        expect(fullPrompt, contains('=== RECENT CONVERSATION HISTORY ==='));
        expect(fullPrompt, contains('=== CURRENT CITIZEN MESSAGE ==='));
        expect(fullPrompt, contains('CF-2026-000024'));

        // Also verify fallback when ragContext is null
        final fallbackPrompt = CivicAssistantPromptBuilder.buildFullPrompt(
          userQuery: 'When will it be fixed?',
          languageCode: 'en',
          verifiedKnowledgeBase: CivicAssistantKnowledge.consolidatedVerifiedText,
        );
        expect(fallbackPrompt, contains('=== VERIFIED CIVICFIX KNOWLEDGE BASE ==='));
      });
    });

    // -------------------------------------------------------------
    // SECTION 5: CONTROLLER & ERROR HANDLING
    // -------------------------------------------------------------
    group('Section 5: Controller & Error Handling', () {
      test('Controller manages state, welcome greeting, and query dispatch', () async {
        final controller = CivicAssistantController();
        controller.initSession(languageCode: 'en');

        expect(controller.messages.length, equals(1));
        expect(controller.messages.first.isAssistant, isTrue);

        final reply = await controller.sendMessage('Hello');
        expect(controller.messages.length, equals(3)); // Welcome, User Hello, Assistant reply
        expect(reply.isAssistant, isTrue);
        expect(controller.isProcessing, isFalse);
      });

      test('Controller provides safe clear chat and retry mechanisms', () async {
        final controller = CivicAssistantController();
        controller.initSession();

        await controller.sendMessage('What is CivicFix?');
        expect(controller.messages.length, equals(3));

        controller.clearChat();
        expect(controller.messages.length, equals(1));
        expect(controller.messages.first.text, contains('CivicFix Assistant'));
      });
    });
  });
}
