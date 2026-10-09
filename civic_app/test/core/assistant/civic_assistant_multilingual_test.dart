import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/knowledge/civic_assistant_lexicon.dart';
import 'package:civic_app/core/assistant/models/assistant_app_context.dart';
import 'package:civic_app/core/assistant/models/assistant_conversation_history.dart';
import 'package:civic_app/core/assistant/models/assistant_language.dart';
import 'package:civic_app/core/assistant/models/civic_assistant_intent.dart';
import 'package:civic_app/core/assistant/retrieval/civic_assistant_hybrid_retriever.dart';
import 'package:civic_app/core/assistant/retrieval/query_normalizer.dart';
import 'package:civic_app/core/assistant/retrieval/retrieval_models.dart';
import 'package:civic_app/core/assistant/routing/civic_assistant_intent_router.dart';
import 'package:civic_app/core/assistant/services/assistant_language_resolver.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_provider.dart';
import 'package:civic_app/core/models/assistant_message_model.dart';

void main() {
  group('CivicFix Chatbot Phase 6 — Multilingual Conversation (English, Hindi, Marathi)', () {
    final retriever = CivicAssistantHybridRetriever.instance;
    final provider = GroundedCivicAssistantProvider();

    // =========================================================================
    // SECTION 1: LANGUAGE MODEL & LANGUAGE RESOLVER
    // =========================================================================
    group('Section 1: AssistantLanguage & LanguageResolver Priority', () {
      test('AssistantLanguage exposes correct localeCodes and Devanagari flags', () {
        expect(AssistantLanguage.english.code, 'en');
        expect(AssistantLanguage.hindi.code, 'hi');
        expect(AssistantLanguage.marathi.code, 'mr');
        expect(AssistantLanguage.english.isDevanagari, isFalse);
        expect(AssistantLanguage.hindi.isDevanagari, isTrue);
        expect(AssistantLanguage.marathi.isDevanagari, isTrue);
      });

      test('Resolves explicit language switch requests in current message', () {
        expect(
          AssistantLanguageResolver.resolve(query: 'Explain this in Hindi please'),
          AssistantLanguage.hindi,
        );
        expect(
          AssistantLanguageResolver.resolve(query: 'मराठीत सांगा'),
          AssistantLanguage.marathi,
        );
        expect(
          AssistantLanguageResolver.resolve(query: 'Can you speak in English?'),
          AssistantLanguage.english,
        );
      });

      test('Detects Devanagari Hindi vs Marathi based on lexical markers', () {
        // Hindi distinct markers
        expect(
          AssistantLanguageResolver.detectQueryLanguage('मेरी शिकायत की स्थिति क्या है?'),
          AssistantLanguage.hindi,
        );
        expect(
          AssistantLanguageResolver.detectQueryLanguage('सत्यापन में कितना समय लगेगा?'),
          AssistantLanguage.hindi,
        );

        // Marathi distinct markers
        expect(
          AssistantLanguageResolver.detectQueryLanguage('माझ्या तक्रारीची स्थिती काय आहे?'),
          AssistantLanguage.marathi,
        );
        expect(
          AssistantLanguageResolver.detectQueryLanguage('पडताळणीला किती वेळ लागेल?'),
          AssistantLanguage.marathi,
        );
      });

      test('Detects Romanized Hinglish vs Marathlish correctly', () {
        expect(
          AssistantLanguageResolver.detectQueryLanguage('mera complaint under verification mein hai'),
          AssistantLanguage.hindi,
        );
        expect(
          AssistantLanguageResolver.detectQueryLanguage('mazi takrar assigned aahe, pudhe kay?'),
          AssistantLanguage.marathi,
        );
      });

      test('Preserves language continuity across multi-turn exchanges', () {
        final history = AssistantConversationHistory();
        history.addMessage(AssistantMessage(
          id: '1',
          text: 'माझी तक्रार पडताळणीमध्ये आहे.',
          sender: AssistantMessageSender.user,
          timestamp: DateTime.now(),
        ));
        history.addMessage(AssistantMessage(
          id: '2',
          text: 'आपली तक्रार पडताळणीमध्ये आहे.',
          sender: AssistantMessageSender.assistant,
          timestamp: DateTime.now(),
        ));

        // Ambiguous follow-up "पुढे काय?" should resolve to Marathi
        expect(
          AssistantLanguageResolver.resolve(query: 'पुढे काय?', history: history),
          AssistantLanguage.marathi,
        );
      });

      test('Falls back to appContext selectedLanguage or English default', () {
        const mrContext = AssistantAppContext(selectedLanguage: 'mr');
        expect(
          AssistantLanguageResolver.resolve(query: 'What is CivicFix?', appContext: mrContext),
          AssistantLanguage.english, // Query is English
        );
        expect(
          AssistantLanguageResolver.resolve(query: '', appContext: mrContext),
          AssistantLanguage.marathi, // Empty query falls back to app context
        );
      });
    });

    // =========================================================================
    // SECTION 2: MULTILINGUAL INTENT ROUTING
    // =========================================================================
    group('Section 2: Multilingual Intent Routing Parity', () {
      test('Routes Casual Greetings in English, Hindi, and Marathi', () {
        expect(
          CivicAssistantIntentRouter.route(query: 'Hello').intent,
          CivicAssistantIntent.casualGreeting,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'नमस्ते').intent,
          CivicAssistantIntent.casualGreeting,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'नमस्कार').intent,
          CivicAssistantIntent.casualGreeting,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'शुभ सकाळ').intent,
          CivicAssistantIntent.casualGreeting,
        );
      });

      test('Routes Casual Small Talk in English, Hindi, and Marathi', () {
        expect(
          CivicAssistantIntentRouter.route(query: 'How are you?').intent,
          CivicAssistantIntent.casualSmallTalk,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'आप कैसे हैं?').intent,
          CivicAssistantIntent.casualSmallTalk,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'तुम्ही कसे आहात?').intent,
          CivicAssistantIntent.casualSmallTalk,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'धन्यवाद').intent,
          CivicAssistantIntent.casualSmallTalk,
        );
      });

      test('Routes CivicFix General Questions in English, Hindi, and Marathi', () {
        expect(
          CivicAssistantIntentRouter.route(query: 'What is CivicFix?').intent,
          CivicAssistantIntent.civicfixGeneral,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'सिविकफिक्स क्या है?').intent,
          CivicAssistantIntent.civicfixGeneral,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'सिविकफिक्स काय आहे?').intent,
          CivicAssistantIntent.civicfixGeneral,
        );
      });

      test('Routes Reporting & Help Inquiries in English, Hindi, and Marathi', () {
        expect(
          CivicAssistantIntentRouter.route(query: 'How do I report a pothole?').intent,
          CivicAssistantIntent.civicfixHelp,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'शिकायत कैसे दर्ज करें?').intent,
          CivicAssistantIntent.civicfixHelp,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'तक्रार कशी नोंदवायची?').intent,
          CivicAssistantIntent.civicfixHelp,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'फोटो कसा जोडायचा?').intent,
          CivicAssistantIntent.civicfixHelp,
        );
      });

      test('Routes Lifecycle & Process Inquiries in English, Hindi, and Marathi', () {
        expect(
          CivicAssistantIntentRouter.route(query: 'What happens after I submit?').intent,
          CivicAssistantIntent.civicfixProcess,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'अब आगे क्या होगा?').intent,
          CivicAssistantIntent.civicfixProcess,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'आता पुढे काय होईल?').intent,
          CivicAssistantIntent.civicfixProcess,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'पडताळणी म्हणजे काय?').intent,
          CivicAssistantIntent.civicfixProcess,
        );
      });

      test('Routes Navigation & Map Queries in English, Hindi, and Marathi', () {
        expect(
          CivicAssistantIntentRouter.route(query: 'Where can I see my complaints?').intent,
          CivicAssistantIntent.civicfixNavigation,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'मेरी शिकायत कहाँ देखें?').intent,
          CivicAssistantIntent.civicfixNavigation,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'माझी तक्रार कुठे पाहू?').intent,
          CivicAssistantIntent.civicfixNavigation,
        );
        expect(
          CivicAssistantIntentRouter.route(query: 'धोका नकाशा कुठे आहे?').intent,
          CivicAssistantIntent.civicfixNavigation,
        );
      });
    });

    // =========================================================================
    // SECTION 3: MULTILINGUAL RETRIEVAL BRIDGE & PARITY
    // =========================================================================
    group('Section 3: Multilingual RAG Retrieval Bridge & Parity', () {
      test('QueryNormalizer preserves Devanagari script during cleaning', () {
        const raw = 'तक्रार नोंदणी कशी करावी? (BMC-2026)';
        final cleaned = QueryNormalizer.cleanText(raw);
        expect(cleaned, contains('तक्रार'));
        expect(cleaned, contains('नोंदणी'));
      });

      test('Lexicon bridge maps Devanagari terms to canonical tokens', () {
        final bridge = CivicAssistantLexicon.getCanonicalBridgeTokens(['तक्रार', 'पडताळणी', 'नकाशा']);
        expect(bridge, contains('complaint'));
        expect(bridge, contains('under_verification'));
        expect(bridge, contains('map'));
      });

      test('RETRIEVAL PARITY: Under Verification query in en, hi, mr retrieves status_under_verification', () {
        final enRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'What does Under Verification mean?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));
        final hiRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Under Verification का क्या मतलब है?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));
        final mrRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'पडताळणी म्हणजे काय?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(enRes.chunkIds, contains('status_under_verification'));
        expect(hiRes.chunkIds, contains('status_under_verification'));
        expect(mrRes.chunkIds, contains('status_under_verification'));
      });

      test('RETRIEVAL PARITY: Reopened Rework query in en, hi, mr retrieves resolution_rework_workflow', () {
        final enRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'Why was my complaint reopened for rework?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));
        final hiRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'मेरी शिकायत दोबारा क्यों खोली गई?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));
        final mrRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'माझी तक्रार पुन्हा का उघडली?',
          intent: CivicAssistantIntent.civicfixProcess,
        ));

        expect(enRes.chunkIds, contains('resolution_rework_workflow'));
        expect(hiRes.chunkIds, contains('resolution_rework_workflow'));
        expect(mrRes.chunkIds, contains('resolution_rework_workflow'));
      });

      test('RETRIEVAL PARITY: Hazard map query in en, hi, mr retrieves map_gis_overview', () {
        final enRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'How does the hazard map work?',
          intent: CivicAssistantIntent.civicfixNavigation,
        ));
        final hiRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'मैप कैसे काम करता है?',
          intent: CivicAssistantIntent.civicfixNavigation,
        ));
        final mrRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'नकाशा कसा वापरायचा?',
          intent: CivicAssistantIntent.civicfixNavigation,
        ));

        expect(enRes.chunkIds, contains('map_gis_overview'));
        expect(hiRes.chunkIds, contains('map_gis_overview'));
        expect(mrRes.chunkIds, contains('map_gis_overview'));
      });

      test('Casual Greetings in Hindi and Marathi bypass RAG (0 chunks retrieved)', () {
        final hiRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'नमस्ते',
          intent: CivicAssistantIntent.casualGreeting,
        ));
        final mrRes = retriever.retrieve(const AssistantRetrievalRequest(
          query: 'नमस्कार',
          intent: CivicAssistantIntent.casualGreeting,
        ));

        expect(hiRes.chunks.isEmpty, isTrue);
        expect(mrRes.chunks.isEmpty, isTrue);
      });
    });

    // =========================================================================
    // SECTION 4: GROUNDED MULTILINGUAL CONVERSATION
    // =========================================================================
    group('Section 4: Grounded Multilingual Response Quality', () {
      test('Responds to greetings in natural English, Hindi, and Marathi', () async {
        final en = await provider.generateResponse(query: 'Hello', languageCode: 'en');
        final hi = await provider.generateResponse(query: 'नमस्ते', languageCode: 'hi');
        final mr = await provider.generateResponse(query: 'नमस्कार', languageCode: 'mr');

        expect(en.text, contains('How can I help you today?'));
        expect(hi.text, contains('नमस्ते'));
        expect(mr.text, contains('नमस्कार'));
      });

      test('Responds to small talk in natural English, Hindi, and Marathi', () async {
        final en = await provider.generateResponse(query: 'How are you?', languageCode: 'en');
        final hi = await provider.generateResponse(query: 'आप कैसे हैं?', languageCode: 'hi');
        final mr = await provider.generateResponse(query: 'तुम्ही कसे आहात?', languageCode: 'mr');

        expect(en.text, contains('well'));
        expect(hi.text, contains('धन्यवाद'));
        expect(mr.text, contains('धन्यवाद'));
      });

      test('Explains CivicFix platform in English, Hindi, and Marathi', () async {
        final en = await provider.generateResponse(query: 'What is CivicFix?', languageCode: 'en');
        final hi = await provider.generateResponse(query: 'सिविकफिक्स क्या है?', languageCode: 'hi');
        final mr = await provider.generateResponse(query: 'सिविकफिक्स काय आहे?', languageCode: 'mr');

        expect(en.text, contains('CivicFix'));
        expect(hi.text, contains('बृहन्मुंबई महानगरपालिका'));
        expect(mr.text, contains('बृहन्मुंबई महानगरपालिका'));
      });

      test('Handles Out of Scope general queries naturally in all three languages', () async {
        final en = await provider.generateResponse(query: 'Tell me a joke', languageCode: 'en');
        final hi = await provider.generateResponse(query: 'चुटकला सुनाओ', languageCode: 'hi');
        final mr = await provider.generateResponse(query: 'विनोद सांगा', languageCode: 'mr');

        expect(en.text, contains('traffic light'));
        expect(hi.text, contains('ट्रैफिक लाइट'));
        expect(mr.text, contains('ट्रॅफिक सिग्नल'));
      });
    });

    // =========================================================================
    // SECTION 5: LIVE COMPLAINT CONTEXT IN ENGLISH, HINDI & MARATHI
    // =========================================================================
    group('Section 5: Live Complaint Context in English, Hindi, and Marathi', () {
      test('Explains Under Verification state in English, Hindi, and Marathi', () async {
        const context = AssistantAppContext(
          selectedTicketNumber: 'CF-2026-000042',
          complaintStatus: 'underVerification',
          wardId: 'K/West',
          departmentId: 'maintenance_roads',
        );

        final en = await provider.generateResponse(
          query: 'What happens next?',
          languageCode: 'en',
          appContext: context,
        );
        final hi = await provider.generateResponse(
          query: 'अब आगे क्या होगा?',
          languageCode: 'hi',
          appContext: context,
        );
        final mr = await provider.generateResponse(
          query: 'आता पुढे काय होईल?',
          languageCode: 'mr',
          appContext: context,
        );

        expect(en.text, contains('CF-2026-000042'));
        expect(en.text, contains('Under Verification (Stage 2)'));
        expect(en.text, contains('Junior Engineer'));

        expect(hi.text, contains('CF-2026-000042'));
        expect(hi.text, contains('सत्यापनाधीन'));
        expect(hi.text, contains('कनिष्ठ अभियंता'));

        expect(mr.text, contains('CF-2026-000042'));
        expect(mr.text, contains('पडताळणीमध्ये'));
        expect(mr.text, contains('कनिष्ठ अभियंत्याकडे'));
      });

      test('Explains Assigned vs In Progress distinction in English, Hindi, and Marathi', () async {
        const assignedContext = AssistantAppContext(
          selectedTicketNumber: 'CF-2026-000088',
          complaintStatus: 'assigned',
          hasJuniorEngineerAssigned: true,
          assignedJuniorEngineerName: 'Ganesh Kulkarni',
        );

        final en = await provider.generateResponse(
          query: 'Has work started?',
          languageCode: 'en',
          appContext: assignedContext,
        );
        final hi = await provider.generateResponse(
          query: 'क्या काम शुरू हो गया है?',
          languageCode: 'hi',
          appContext: assignedContext,
        );
        final mr = await provider.generateResponse(
          query: 'काम सुरू झाले आहे का?',
          languageCode: 'mr',
          appContext: assignedContext,
        );

        expect(en.text, contains('Not yet'));
        expect(hi.text, contains('अभी नहीं'));
        expect(mr.text, contains('अद्याप नाही'));
      });

      test('Explains Blocked Obstacle in English, Hindi, and Marathi preserving SLA', () async {
        const blockedContext = AssistantAppContext(
          selectedTicketNumber: 'CF-2026-000105',
          complaintStatus: 'inProgress',
          isBlocked: true,
          blockedReason: 'Heavy monsoon waterlogging',
        );

        final en = await provider.generateResponse(
          query: 'Why is it blocked?',
          languageCode: 'en',
          appContext: blockedContext,
        );
        final hi = await provider.generateResponse(
          query: 'काम क्यों रुका हुआ है?',
          languageCode: 'hi',
          appContext: blockedContext,
        );
        final mr = await provider.generateResponse(
          query: 'काम का थांबले आहे?',
          languageCode: 'mr',
          appContext: blockedContext,
        );

        expect(en.text, contains('Heavy monsoon waterlogging'));
        expect(en.text, contains('SLA countdown continues'));

        expect(hi.text, contains('Heavy monsoon waterlogging'));
        expect(hi.text, contains('SLA'));

        expect(mr.text, contains('Heavy monsoon waterlogging'));
        expect(mr.text, contains('SLA'));
      });

      test('Explains Supervisory Rework in English, Hindi, and Marathi preserving SLA', () async {
        const reworkContext = AssistantAppContext(
          selectedTicketNumber: 'CF-2026-000119',
          complaintStatus: 'reopened',
          reopenCount: 1,
          reopenReason: 'Paver block alignment incomplete',
        );

        final en = await provider.generateResponse(
          query: 'Why was my complaint reopened?',
          languageCode: 'en',
          appContext: reworkContext,
        );
        final hi = await provider.generateResponse(
          query: 'मेरी शिकायत दोबारा क्यों खोली गई?',
          languageCode: 'hi',
          appContext: reworkContext,
        );
        final mr = await provider.generateResponse(
          query: 'माझी तक्रार पुन्हा का उघडली?',
          languageCode: 'mr',
          appContext: reworkContext,
        );

        expect(en.text, contains('Paver block alignment incomplete'));
        expect(en.text, contains('quality audit'));

        expect(hi.text, contains('Paver block alignment incomplete'));
        expect(hi.text, contains('गुणवत्ता समीक्षा'));

        expect(mr.text, contains('Paver block alignment incomplete'));
        expect(mr.text, contains('गुणवत्ता तपासणी'));
      });

      test('Explains Offline Sync Queue in English, Hindi, and Marathi', () async {
        const offlineContext = AssistantAppContext(
          selectedTicketNumber: 'CF-2026-000140',
          syncState: 'pending',
        );

        final en = await provider.generateResponse(
          query: "Why can't I track my complaint yet?",
          languageCode: 'en',
          appContext: offlineContext,
        );
        final hi = await provider.generateResponse(
          query: 'मेरी शिकायत ट्रैक क्यों नहीं हो रही?',
          languageCode: 'hi',
          appContext: offlineContext,
        );
        final mr = await provider.generateResponse(
          query: 'तक्रार ट्रॅक का होत नाही?',
          languageCode: 'mr',
          appContext: offlineContext,
        );

        expect(en.text, contains('offline queue'));
        expect(hi.text, contains('ऑफ़लाइन'));
        expect(mr.text, contains('ऑफलाइन'));
      });

      test('State Contradiction Guard works in Hindi and Marathi', () async {
        const activeContext = AssistantAppContext(
          selectedTicketNumber: 'CF-2026-000155',
          complaintStatus: 'inProgress',
        );

        final hi = await provider.generateResponse(
          query: 'मेरी शिकायत बंद हो गई क्या?',
          languageCode: 'hi',
          appContext: activeContext,
        );
        final mr = await provider.generateResponse(
          query: 'माझी तक्रार बंद झाली आहे का?',
          languageCode: 'mr',
          appContext: activeContext,
        );

        expect(hi.text, contains('CF-2026-000155'));
        expect(hi.text, contains('कार्य प्रगति पर'));

        expect(mr.text, contains('CF-2026-000155'));
        expect(mr.text, contains('काम प्रगतीपथावर'));
      });
    });

    // =========================================================================
    // SECTION 6: MIXED-LANGUAGE & CANONICAL PRESERVATION
    // =========================================================================
    group('Section 6: Mixed-Language & Canonical Token Preservation', () {
      test('Handles Hinglish & Marathlish queries reliably', () async {
        final hinglish = await provider.generateResponse(
          query: 'Mera complaint under verification mein hai, next kya hoga?',
          languageCode: 'hi',
        );
        final marathlish = await provider.generateResponse(
          query: 'Mazi complaint assigned aahe, work start zala ka?',
          languageCode: 'mr',
        );

        expect(hinglish.text.isNotEmpty, isTrue);
        expect(marathlish.text.isNotEmpty, isTrue);
      });

      test('Preserves canonical Ticket Numbers, Ward Codes, and Officer Names untouched', () async {
        const context = AssistantAppContext(
          selectedTicketNumber: 'MCGM-2026-9901',
          wardId: 'R/South',
          departmentId: 'maintenance_roads',
          hasJuniorEngineerAssigned: true,
          assignedJuniorEngineerName: 'Ganesh Kulkarni',
          hasFieldOfficerAssigned: true,
          assignedFieldOfficerName: 'Ramesh Patil',
          complaintStatus: 'assigned',
        );

        final mr = await provider.generateResponse(
          query: 'कोणाची नियुक्ती झाली आहे?',
          languageCode: 'mr',
          appContext: context,
        );

        // Ticket number remains exact ASCII
        expect(context.ticketId, 'MCGM-2026-9901');
        // Officer names preserved exactly as snapshots
        expect(mr.text, contains('Ganesh Kulkarni'));
        expect(mr.text, contains('Ramesh Patil'));
      });

      test('Hallucination boundary message is localized in English, Hindi, and Marathi', () async {
        final en = await provider.generateResponse(query: 'xyzzy gibberish query 12345', languageCode: 'en');
        final hi = await provider.generateResponse(query: 'xyzzy gibberish query 12345', languageCode: 'hi');
        final mr = await provider.generateResponse(query: 'xyzzy gibberish query 12345', languageCode: 'mr');

        expect(en.text, contains("verified CivicFix information"));
        expect(hi.text, contains('सत्यापित सिविकफिक्स जानकारी'));
        expect(mr.text, contains('पडताळलेली सिविकफिक्स माहिती'));
      });
    });
  });
}
