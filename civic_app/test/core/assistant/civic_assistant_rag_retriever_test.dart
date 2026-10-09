import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/config/civic_assistant_prompt.dart';
import 'package:civic_app/core/assistant/models/assistant_conversation_history.dart';
import 'package:civic_app/core/assistant/models/assistant_rag_context.dart';
import 'package:civic_app/core/assistant/models/civic_assistant_intent.dart';
import 'package:civic_app/core/assistant/retrieval/civic_assistant_hybrid_retriever.dart';
import 'package:civic_app/core/assistant/retrieval/query_normalizer.dart';
import 'package:civic_app/core/assistant/retrieval/retrieval_models.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_provider.dart';
import 'package:civic_app/core/models/assistant_message_model.dart';

void main() {
  group('CivicFix Chatbot Phase 4 — RAG Retrieval Engine Tests', () {
    final retriever = CivicAssistantHybridRetriever.instance;

    test('QueryNormalizer extracts clean tokens and domain aliases', () {
      final query = 'How does the JE assign the Field Officer for SWM?';
      final tokens = QueryNormalizer.extractTokens(query);
      final expanded = QueryNormalizer.getExpandedTokenSet(query);

      expect(tokens, contains('je'));
      expect(tokens, contains('assign'));
      expect(tokens, contains('field'));
      expect(tokens, contains('officer'));
      expect(tokens, contains('swm'));
      expect(tokens, isNot(contains('how')));
      expect(tokens, isNot(contains('the')));
      expect(tokens, isNot(contains('for')));

      // Verify domain alias expansion
      expect(expanded, contains('junior'));
      expect(expanded, contains('engineer'));
      expect(expanded, contains('solid'));
      expect(expanded, contains('waste'));
      expect(expanded, contains('garbage'));
    });

    group('Evaluation Dataset Benchmark', () {
      test('GENERAL: "What is CivicFix?" retrieves platform overview', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What is CivicFix?',
          intent: CivicAssistantIntent.civicfixGeneral,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.isBypassed, isFalse);
        final topChunk = result.chunks.first;
        expect(
          topChunk.id == 'overview_platform' || topChunk.id == 'faq_what_is_civicfix',
          isTrue,
        );
      });

      test('PROCESS: "What happens after I report an issue?" retrieves lifecycle', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What happens after I report an issue?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('lifecycle_overview'), contains('faq_what_happens_after_submit')));
      });

      test('STATUS: "What does Under Verification mean?" retrieves stage 2 status', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What does Under Verification mean?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('status_under_verification'), contains('lifecycle_under_verification'), contains('faq_under_verification_meaning')));
      });

      test('STATUS: "What does Closed mean?" retrieves closure definition', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What does Closed status mean?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, contains('complaint_statuses_all'));
      });

      test('ROLES: "What does a Junior Engineer do?" retrieves JE role knowledge', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What does a Junior Engineer do?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('roles_junior_engineer'), contains('faq_junior_engineer_role')));
        expect(result.chunks.first.content, contains('technical'));
      });

      test('ROLES: "What does an Execution Officer do?" retrieves field officer role', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What does an Execution Officer do?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('roles_field_officer'), contains('faq_field_officer_role')));
      });

      test('DEPARTMENTS: "Who handles potholes?" retrieves road maintenance department', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Who handles potholes on the street?',
          intent: CivicAssistantIntent.civicfixHelp,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('dept_maintenance_roads'), contains('category_pothole_reporting')));
      });

      test('DEPARTMENTS: "Which department handles water leakage?" retrieves water works', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Which department handles water leakage?',
          intent: CivicAssistantIntent.civicfixHelp,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('dept_water_works'), contains('category_water_leak_reporting')));
      });

      test('EVIDENCE: "Can I see resolution photos?" retrieves after-work evidence rules', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Can I see resolution photos of the repair?',
          intent: CivicAssistantIntent.civicfixHelp,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('evidence_after_work'), contains('evidence_rules_overview')));
      });

      test('REWORK: "Why was my complaint reopened?" retrieves quality audit and rework policy', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Why was my complaint reopened for rework?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('resolution_rework_workflow'), contains('faq_rework_defective_repair')));
      });

      test('SLA: "Does rework reset SLA?" retrieves SLA continuity rule', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Does rework reset SLA countdown?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('rework_sla_preservation'), contains('faq_does_sla_reset_on_rework')));
        expect(result.chunks.any((c) => c.content.contains('does NOT reset') || c.content.contains('never resets')), isTrue);
      });

      test('MAP: "What do clusters mean on the map?" retrieves GIS map knowledge', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What do clusters mean on the hazard map?',
          intent: CivicAssistantIntent.civicfixNavigation,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, anyOf(contains('map_gis_overview'), contains('faq_how_map_works')));
      });

      test('TROUBLESHOOTING: "Why is sync pending?" retrieves offline queue knowledge', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Why is sync pending for my complaint?',
          intent: CivicAssistantIntent.civicfixHelp,
        ));

        expect(result.hasChunks, isTrue);
        expect(result.retrievedKnowledgeIds, contains('troubleshoot_offline_queue'));
      });
    });

    group('Casual Conversation & Out-of-Scope Bypass', () {
      test('Casual greeting "Hello" completely bypasses RAG retrieval', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Hello',
          intent: CivicAssistantIntent.casualGreeting,
        ));

        expect(result.isBypassed, isTrue);
        expect(result.chunks, isEmpty);
        expect(result.hasChunks, isFalse);
      });

      test('Casual small talk "How are you?" bypasses RAG retrieval', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'How are you?',
          intent: CivicAssistantIntent.casualSmallTalk,
        ));

        expect(result.isBypassed, isTrue);
        expect(result.chunks, isEmpty);
      });

      test('Out of scope "Tell me a joke" bypasses RAG retrieval', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Tell me a joke',
          intent: CivicAssistantIntent.outOfScopeGeneral,
        ));

        expect(result.isBypassed, isTrue);
        expect(result.chunks, isEmpty);
      });
    });

    group('Confidence Threshold & Bounded Top-K', () {
      test('Gibberish query does not leak random chunks (returns empty)', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'xyzqwertylkajshd zxcvbnmasdf',
          intent: CivicAssistantIntent.unknown,
          config: AssistantRetrievalConfig(minScoreThreshold: 20.0),
        ));

        expect(result.isBypassed, isFalse);
        expect(result.hasChunks, isFalse);
        expect(result.chunks, isEmpty);
      });

      test('Top-K limits result count strictly to maxResults + bounded expansion', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What are the BMC departments, wards, and reporting rules?',
          intent: CivicAssistantIntent.civicfixGeneral,
          config: AssistantRetrievalConfig(maxResults: 3, maxRelatedExpansion: 1),
        ));

        expect(result.chunks.length, inInclusiveRange(1, 4));
      });
    });

    group('Multi-Turn Contextual Retrieval', () {
      test('Resolves ambiguous follow-up "What happens next?" using session history', () {
        final history = AssistantConversationHistory(maxWindowSize: 5);
        history.addMessage(AssistantMessage(
          id: 'u1',
          text: 'My complaint is under verification stage.',
          sender: AssistantMessageSender.user,
          timestamp: DateTime.now(),
        ));
        history.addMessage(AssistantMessage(
          id: 'a1',
          text: 'Stage 2 Under Verification validates photo authenticity and routes to the department.',
          sender: AssistantMessageSender.assistant,
          timestamp: DateTime.now(),
        ));

        final result = retriever.retrieve(AssistantRetrievalRequest(
          query: 'What happens next?',
          intent: CivicAssistantIntent.civicfixProcess,
          history: history,
        ));

        expect(result.hasChunks, isTrue);
        expect(
          result.retrievedKnowledgeIds,
          anyOf(
            contains('lifecycle_under_verification'),
            contains('lifecycle_assigned'),
            contains('roles_junior_engineer'),
            contains('lifecycle_overview'),
          ),
        );
      });
    });

    group('Prompt Integration & Provider Grounding', () {
      test('Prompt builder formats retrieved chunks cleanly instead of entire KB', () {
        final result = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'How do I report a pothole?',
          intent: CivicAssistantIntent.civicfixHelp,
        ));

        final ragContext = AssistantRagContext.fromRetrievalResult(result);
        expect(ragContext.isGrounded, isTrue);

        final prompt = CivicAssistantPromptBuilder.buildFullPrompt(
          userQuery: 'How do I report a pothole?',
          languageCode: 'en',
          ragContext: ragContext,
        );

        expect(prompt, contains('=== VERIFIED CIVICFIX DOCUMENTATION (RETRIEVED KNOWLEDGE) ==='));
        expect(prompt, contains('Pothole'));
        expect(prompt, isNot(contains('=== VERIFIED CIVICFIX KNOWLEDGE BASE ===')));
      });

      test('GroundedCivicAssistantProvider uses RAG context seamlessly', () async {
        final provider = GroundedCivicAssistantProvider();
        final reply = await provider.generateResponse(
          query: 'What are the 18 BMC departments?',
          languageCode: 'en',
        );

        expect(reply.text, contains('18 canonical Brihanmumbai Municipal Corporation'));
      });
    });
  });
}
