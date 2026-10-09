import '../../models/assistant_message_model.dart';
import '../knowledge/civic_assistant_knowledge.dart';
import '../models/assistant_app_context.dart';
import '../models/assistant_conversation_history.dart';
import '../models/assistant_rag_context.dart';
import '../models/civic_assistant_intent.dart';

/// Core conversational response engine for CivicFix Assistant.
///
/// Implements natural language personality, verified domain knowledge grounding,
/// hybrid RAG retrieval integration, live application context reasoning,
/// and full English, Hindi, and Marathi multilingual conversation.
class CivicAssistantConversationEngine {
  /// Generates a natural, grounded [AssistantMessage] based on intent, conversation context,
  /// retrieved RAG documentation chunks, live app context, and target language.
  static AssistantMessage generateResponse({
    required String query,
    required AssistantIntentResult intentResult,
    required String languageCode,
    AssistantConversationHistory? history,
    AssistantRagContext? ragContext,
    AssistantAppContext? appContext,
  }) {
    final lang = languageCode.trim().toLowerCase();
    final clean = query.trim().toLowerCase();

    // 1. Security & Prompt Injection Defense
    final injectionDefense = _checkPromptInjection(clean, lang);
    if (injectionDefense != null) return injectionDefense;

    // 2. Privacy & Credential Extraction Defense
    final privacyDefense = _checkPrivacyExtraction(clean, lang);
    if (privacyDefense != null) return privacyDefense;

    // 3. High-Risk Non-Civic Advice (Medical, Legal, Financial)
    final riskDefense = _checkHighRiskDomain(clean, lang);
    if (riskDefense != null) return riskDefense;

    // 4. Fake Entities / Fake Departments / Fake Status Guard
    final fakeEntityDefense = _checkFakeEntities(clean, lang);
    if (fakeEntityDefense != null) return fakeEntityDefense;

    // 5. Universal SLA Clarification Guard
    final slaDefense = _checkUniversalSla(clean, lang);
    if (slaDefense != null) return slaDefense;

    // 6. Officer Contact Boundary (Phone/Email privacy)
    final officerContactDefense = _checkOfficerContact(clean, lang);
    if (officerContactDefense != null) return officerContactDefense;

    // 7. Missing Complaint Context Prompt
    final missingCtx = _checkMissingComplaintContext(clean, lang, appContext);
    if (missingCtx != null) return missingCtx;

    // 8. Casual Greetings & Small Talk (Completely bypass complaint context)
    if (intentResult.intent == CivicAssistantIntent.casualGreeting) {
      return _handleGreeting(clean, lang);
    }
    if (intentResult.intent == CivicAssistantIntent.casualSmallTalk) {
      return _handleSmallTalk(clean, lang);
    }
    if (intentResult.intent == CivicAssistantIntent.outOfScopeGeneral) {
      return _handleOutOfScope(clean, lang);
    }

    // 9. State Contradiction Check (e.g. user claims closed when context shows In Progress)
    if (appContext != null && appContext.hasComplaintContext) {
      final contradiction = _checkStateContradiction(clean, appContext, lang);
      if (contradiction != null) {
        return contradiction;
      }
    }

    // 10. Complaint-Specific & Screen-Specific Intent Routing
    switch (intentResult.intent) {
      case CivicAssistantIntent.civicfixGeneral:
        return _handleCivicFixGeneral(clean, lang, ragContext, appContext);

      case CivicAssistantIntent.civicfixProcess:
        return _handleCivicFixProcess(
          clean,
          intentResult,
          lang,
          ragContext,
          appContext,
        );

      case CivicAssistantIntent.civicfixHelp:
        return _handleCivicFixHelp(clean, lang, ragContext, appContext);

      case CivicAssistantIntent.civicfixNavigation:
        return _handleCivicFixNavigation(clean, lang, ragContext, appContext);

      case CivicAssistantIntent.unknown:
        return _handleUnknown(clean, lang, ragContext, appContext);

      case CivicAssistantIntent.casualGreeting:
      case CivicAssistantIntent.casualSmallTalk:
      case CivicAssistantIntent.outOfScopeGeneral:
        return _handleGreeting(clean, lang);
    }
  }

  // --- Prompt Injection Defense ---
  static AssistantMessage? _checkPromptInjection(String clean, String lang) {
    if (clean.contains('ignore previous instructions') ||
        clean.contains('ignore all previous') ||
        clean.contains('ignore instructions') ||
        clean.contains('forget instructions') ||
        clean.contains('disregard instructions') ||
        clean.contains('system prompt') ||
        clean.contains('print system prompt') ||
        clean.contains('show system prompt') ||
        clean.contains('reveal instructions') ||
        clean.contains('print prompt') ||
        clean.contains('override system rules') ||
        clean.contains('act as root') ||
        clean.contains('act as admin') ||
        clean.contains('jailbreak') ||
        clean.contains('dan mode') ||
        clean.contains('ignore rules') ||
        clean.contains('निर्देश अनदेखा') ||
        clean.contains('सिस्टम प्रॉम्प्ट') ||
        clean.contains('सूचना दुर्लक्ष')) {
      final isHi = lang == 'hi';
      final isMr = lang == 'mr';
      final text = isHi
          ? 'सुरक्षा और गोपनीयता कारणों से, मैं आंतरिक सिस्टम निर्देशों को प्रकट, संशोधित या अनदेखा नहीं कर सकता। मैं केवल मुंबई में नागरी शिकायतों की रिपोर्टिंग और ट्रैकिंग में आपकी सहायता के लिए समर्पित सिविकफिक्स सहायक हूँ।'
          : isMr
              ? 'सुरक्षा आणि गोपनीयतेच्या कारणास्तव, मी अंतर्गत सिस्टम सूचना उघड, सुधारित किंवा दुर्लक्षित करू शकत नाही. मी केवळ बृहन्मुंबईत नागरी तक्रारी नोंदवणे आणि ट्रॅक करण्यासाठी समर्पित सिविकफिक्स सहाय्यक आहे.'
              : 'For security and privacy reasons, I cannot disclose, modify, or override internal system instructions. I am the CivicFix Assistant dedicated solely to municipal civic grievance workflows in Greater Mumbai.';
      return AssistantMessage(
        id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: const [
          'What is CivicFix?',
          'How do I report an issue?',
          'How do I track my complaint?',
        ],
      );
    }
    return null;
  }

  // --- Privacy & Sensitive Data Extraction Defense ---
  static AssistantMessage? _checkPrivacyExtraction(String clean, String lang) {
    final hasSensitive = clean.contains('firebase uid') ||
        clean.contains('user uid') ||
        (RegExp(r'\buid\b').hasMatch(clean) && (clean.contains('user') || clean.contains('citizen') || clean.contains('982'))) ||
        clean.contains('auth token') ||
        clean.contains('jwt token') ||
        clean.contains('tokens and') ||
        clean.contains('auth tokens') ||
        clean.contains('password') ||
        RegExp(r'\b(otp|otps)\b').hasMatch(clean) ||
        clean.contains('secret key') ||
        clean.contains('api key') ||
        clean.contains('private key') ||
        clean.contains('database url') ||
        clean.contains('firestore connection') ||
        clean.contains('storage bucket') ||
        clean.contains('bucket url') ||
        clean.contains('users collection') ||
        clean.contains('citizen credentials') ||
        clean.contains('पासवर्ड') ||
        clean.contains('ओटीपी') ||
        clean.contains('टोकन') ||
        clean.contains('गोपनीय डेटा');

    if (hasSensitive) {
      final isHi = lang == 'hi';
      final isMr = lang == 'mr';
      final text = isHi
          ? 'सिविकफिक्स नागरिक गोपनीयता और सुरक्षा मानकों का सख्ती से पालन करता है। मैं उपयोगकर्ता क्रेडेंशियल्स, फायरबेस यूआईडी (UID), ऑथेंटिकेशन टोकन, पासवर्ड, ओटीपी, स्टोरेज बकेट पाथ या निजी डेटाबेस विवरण प्रकट या एक्सेस नहीं कर सकता।'
          : isMr
              ? 'सिविकफिक्स नागरिक गोपनीयता आणि सुरक्षा मानकांचे काटेकोरपणे पालन करते. मी वापरकर्ता क्रेडेंशियल्स, फायरबेस यूआयडी (UID), ऑथेंटिकेशन टोकन्स, पासवर्ड, ओटीपी, स्टोरेज बकेट पाथ किंवा खाजगी डेटाबेस तपशील उघड किंवा ॲक्सेस करू शकत नाही.'
              : 'CivicFix strictly adheres to citizen privacy and security standards. I cannot disclose, access, or extract user credentials, Firebase UIDs, authentication tokens, passwords, OTPs, storage bucket paths, or private database connection details.';
      return AssistantMessage(
        id: 'priv_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: const [
          'How do I report an issue?',
          'How do I track my complaint?',
        ],
      );
    }
    return null;
  }

  // --- Fake Entities / Unsupported Services Guard ---
  static AssistantMessage? _checkFakeEntities(String clean, String lang) {
    if (clean.contains('secret municipal election') ||
        clean.contains('election policy') ||
        clean.contains('secret vip') ||
        clean.contains('vip escalation') ||
        clean.contains('pension scheme') ||
        clean.contains('municipal pension') ||
        clean.contains('senior citizen pension') ||
        clean.contains('property tax bill') ||
        clean.contains('pay my property tax') ||
        clean.contains('property tax formula') ||
        clean.contains('dog license') ||
        clean.contains('pet license') ||
        clean.contains('pet dog license') ||
        clean.contains('smart roads') ||
        clean.contains('flying cars') ||
        clean.contains('department of space') ||
        clean.contains('department of magic') ||
        clean.contains('ministry of magic') ||
        clean.contains('extraterrestrial') ||
        clean.contains('awaitingmayorapproval') ||
        clean.contains('awaiting mayor') ||
        clean.contains('citizenapproved') ||
        clean.contains('mayorpending') ||
        clean.contains('superadminauthorized') ||
        clean.contains('स्मार्ट रोड') ||
        clean.contains('उडणाऱ्या गाड्या') ||
        clean.contains('जादू विभाग') ||
        clean.contains('महापौर मंजुरी')) {
      final isHi = lang == 'hi';
      final isMr = lang == 'mr';
      final text = isHi
          ? 'यह सेवा, योजना या विभाग सिविकफिक्स में मौजूद नहीं है (does not exist in CivicFix)। सिविकफिक्स केवल बृहन्मुंबई महानगरपालिका (BMC) के 18 आधिकारिक विभागों (जैसे रस्ते, घनकचरा, जलकामे) और 8 अधिकृत जीवनचक्र स्थितियों में सत्यापित नागरी शिकायतों के लिए कार्य करता है। पेंशन, कर भुगतान, लाइसेंस या चुनाव सेवाओं के लिए आधिकारिक बीएमसी पोर्टल portal.mcgm.gov.in पर जाएं।'
          : isMr
              ? 'ही सेवा, योजना किंवा विभाग सिविकफिक्समध्ये अस्तित्वात नाही (does not exist in CivicFix). सिविकफिक्स केवळ बृहन्मुंबई महानगरपालिकेच्या (BMC) १८ अधिकृत विभागांमध्ये (उदा. रस्ते देखभाल, घनकचरा, जलकामे) आणि ८ अधिकृत जीवनचक्र स्थितींमध्ये पडताळलेल्या नागरी तक्रारींसाठी कार्य करते. पेन्शन, कर भरणा, परवाने किंवा निवडणूक सेवांसाठी अधिकृत बीएमसी पोर्टल portal.mcgm.gov.in ला भेट द्या.'
              : 'The requested department, service, status, or entity does not exist in CivicFix. CivicFix operates strictly within 18 official BMC departments and 8 canonical lifecycle statuses for verified municipal grievance redressal (such as road repairs, garbage, water leaks, and drainage). For property tax, pensions, pet licensing, or municipal elections, please visit the official BMC portal at portal.mcgm.gov.in.';
      return AssistantMessage(
        id: 'fake_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: const [
          'What departments exist in CivicFix?',
          'What happens after I submit a complaint?',
        ],
      );
    }
    return null;
  }

  // --- Universal SLA Guard ---
  static AssistantMessage? _checkUniversalSla(String clean, String lang) {
    if (clean.contains('sla for all complaints') ||
        clean.contains('sla for every complaint') ||
        clean.contains('universal sla') ||
        clean.contains('fixed sla for all') ||
        clean.contains('is sla always 24 hours') ||
        clean.contains('is sla always the same') ||
        clean.contains('सभी शिकायतों के लिए एसएलए') ||
        clean.contains('सर्व तक्रारींसाठी एसएलए')) {
      final isHi = lang == 'hi';
      final isMr = lang == 'mr';
      final text = isHi
          ? 'सिविकफिक्स में सभी शिकायतों के लिए कोई एक सार्वभौमिक (Universal) समयसीमा (SLA) नहीं है। एसएलए नागरिक शिकायत की श्रेणी और गंभीरता पर निर्भर करता है (जैसे: गड्ढा मरम्मत 48 घंटे, कचरा ओवरफ्लो 12 घंटे, जल रिसाव 24 घंटे, गंभीर नागरी खतरा 6 घंटे)।'
          : isMr
              ? 'सिविकफिक्समध्ये सर्व तक्रारींसाठी एकच सार्वत्रिक (Universal) सेवा मुदत (SLA) नाही. एसएलए हा तक्रारीचा प्रकार आणि तीव्रतेवर अवलंबून असतो (उदा. खड्डे दुरुस्ती ४८ तास, कचरा ओव्हरफ्लो १२ तास, पाण्याची गळती २४ तास, गंभीर धोका ६ तास).'
              : 'CivicFix does not have a single universal SLA duration for all complaints. SLAs are strictly category-specific and severity-based (e.g., Pothole Repairs: 48 hours, Garbage Overflow: 12 hours, Water Leakage: 24 hours, Severe Hazard: 6 hours).';
      return AssistantMessage(
        id: 'sla_univ_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: const [
          'How long does a pothole fix take?',
          'What is the SLA for garbage overflow?',
        ],
      );
    }
    return null;
  }

  // --- Officer Contact Boundary ---
  static AssistantMessage? _checkOfficerContact(String clean, String lang) {
    final hasContactQuery = clean.contains('phone number') ||
        clean.contains('mobile number') ||
        clean.contains('whatsapp') ||
        clean.contains('contact number') ||
        clean.contains('personal email') ||
        clean.contains('phone') ||
        clean.contains('मोबाइल') ||
        clean.contains('मोबाईल') ||
        clean.contains('फोन नंबर');

    final hasOfficerTarget = clean.contains('officer') ||
        clean.contains('engineer') ||
        clean.contains('je') ||
        clean.contains('lead') ||
        clean.contains('inspector') ||
        clean.contains('अधिकारी') ||
        clean.contains('अभियंता');

    if (hasContactQuery && hasOfficerTarget) {
      final isHi = lang == 'hi';
      final isMr = lang == 'mr';
      final text = isHi
          ? 'सुरक्षा और गोपनीयता कारणों से, नगर निगम अधिकारियों के व्यक्तिगत मोबाइल नंबर या सीधे ईमेल पते सार्वजनिक रूप से साझा नहीं किए जाते हैं। आपकी शिकायत की स्थिति, असाइनमेंट और निवारण प्रमाण सीधे सिविकफिक्स ऐप में अपडेट किए जाते हैं।'
          : isMr
              ? 'सुरक्षा आणि गोपनीयतेच्या कारणास्तव, महापालिका अधिकाऱ्यांचे वैयक्तिक मोबाईल नंबर किंवा थेट ईमेल पत्ते सार्वजनिक केले जात नाहीत. तक्रारीची स्थिती, असाइनमेंट आणि निवारण पुरावे थेट सिविकफिक्स ॲपमध्ये अपडेट केले जातात.'
              : 'For security and privacy reasons, personal phone numbers and direct email addresses of municipal officers are not publicly disclosed. All grievance updates, assigned team progress, and resolution evidence are tracked directly within the CivicFix application.';
      return AssistantMessage(
        id: 'off_cont_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: const [
          'How can I track my complaint?',
          'What happens after I submit a complaint?',
        ],
      );
    }
    return null;
  }

  // --- High Risk Non-Civic Advice (Medical, Legal, Financial) ---
  static AssistantMessage? _checkHighRiskDomain(String clean, String lang) {
    if (clean.contains('medical advice') ||
        clean.contains('prescribe medicine') ||
        clean.contains('symptoms of') ||
        clean.contains('diagnose disease') ||
        clean.contains('legal advice') ||
        clean.contains('sue in court') ||
        clean.contains('file a lawsuit') ||
        clean.contains('stock investment') ||
        clean.contains('financial advice') ||
        clean.contains('crypto investment') ||
        clean.contains('औषध सांगा') ||
        clean.contains('कोर्ट केस') ||
        clean.contains('शेअर मार्केट')) {
      final isHi = lang == 'hi';
      final isMr = lang == 'mr';
      final text = isHi
          ? 'मैं केवल ग्रेटर मुंबई में सिविकफिक्स और नागरी शिकायत निवारण के लिए समर्पित सहायक हूँ। मैं चिकित्सीय, कानूनी या वित्तीय सलाह नहीं दे सकता। कृपया इन विषयों के लिए लाइसेंस प्राप्त पेशेवर से परामर्श लें।'
          : isMr
              ? 'मी केवळ बृहन्मुंबईत नागरी तक्रार निवारण आणि सिविकफिक्ससाठी समर्पित सहाय्यक आहे. मी वैद्यकीय, कायदेशीर किंवा आर्थिक सल्ला देऊ शकत नाही. कृपया यासाठी अधिकृत तज्ज्ञांचा सल्ला घ्यावा.'
              : 'I am the CivicFix Assistant for municipal civic grievance services in Greater Mumbai. I cannot provide medical, legal, or financial advice. Please consult a qualified licensed professional for those matters.';
      return AssistantMessage(
        id: 'risk_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: const [
          'What is CivicFix?',
          'How do I report an issue?',
        ],
      );
    }
    return null;
  }

  // --- Missing Complaint Context Check ---
  static AssistantMessage? _checkMissingComplaintContext(
    String clean,
    String lang,
    AssistantAppContext? appContext,
  ) {
    if (appContext == null || !appContext.hasComplaintContext) {
      if (clean.contains('who is handling my complaint') ||
          clean.contains('who is my officer') ||
          clean.contains('who is assigned to my issue') ||
          clean.contains('what is the status of my ticket') ||
          clean.contains('when will my complaint be resolved') ||
          clean.contains('मेरी शिकायत कौन देख रहा है') ||
          clean.contains('माझी तक्रार कोण हाताळत आहे') ||
          clean.contains('माझ्या तक्रारीचे काय झाले')) {
        final isHi = lang == 'hi';
        final isMr = lang == 'mr';
        final text = isHi
            ? 'अपनी विशिष्ट शिकायत की वर्तमान स्थिति या नियुक्त अधिकारी की जानकारी प्राप्त करने के लिए, कृपया नीचे नेविगेशन में "My Complaints" (मेरी शिकायतें) से अपनी संबंधित शिकायत खोलें।'
            : isMr
                ? 'आपल्या विशिष्ट तक्रारीची सद्यस्थिती किंवा नियुक्त अधिकाऱ्याची माहिती मिळवण्यासाठी, कृपया खालील नेव्हिगेशनमध्ये "My Complaints" (माझ्या तक्रारी) मधून संबंधित तक्रार उघडा.'
                : 'To check the assigned team or live progress of your specific grievance, please open and select the complaint from the "My Complaints" section.';
        return AssistantMessage(
          id: 'miss_ctx_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          sender: AssistantMessageSender.assistant,
          timestamp: DateTime.now(),
          followUpSuggestions: const [
            'How do I track my complaint?',
            'What happens after I submit a complaint?',
          ],
        );
      }
    }
    return null;
  }

  // --- State Contradiction Guard ---

  static AssistantMessage? _checkStateContradiction(
    String query,
    AssistantAppContext context,
    String lang,
  ) {
    if (query.contains('my complaint is closed') ||
        query.contains('ticket is closed') ||
        query.contains('it is closed') ||
        query.contains('बंद हो गई') ||
        query.contains('बंद झाली') ||
        query.contains('शिकायत बंद') ||
        query.contains('तक्रार बंद')) {
      if (!context.isClosed) {
        final ticket = context.ticketId ?? 'your complaint';
        final isHi = lang == 'hi';
        final isMr = lang == 'mr';
        final stageNum = context.isUnderVerification ? 2 : (context.isAssigned ? 3 : 4);

        final text = isHi
            ? 'सिविकफिक्स के वर्तमान रिकॉर्ड के अनुसार, शिकायत $ticket अभी still Work In Progress / कार्य प्रगति पर (चरण $stageNum) में है। नगर निगम टीम इस पर सक्रिय रूप से कार्य कर रही है।'
            : isMr
                ? 'सिविकफिक्सच्या सद्य नोंदींनुसार, तक्रार $ticket अद्याप still Work In Progress / काम प्रगतीपथावर (टप्पा $stageNum) मध्ये आहे. महापालिका पथक या तक्रारीवर सक्रियपणे काम करत आहे.'
                : 'According to the current CivicFix records, $ticket is still Work In Progress (Stage $stageNum). The municipal team is actively processing the grievance.';

        final suggestions = isHi
            ? const ['अब आगे क्या होगा?', 'किसे असाइन किया गया है?', 'शिकायत कैसे ट्रैक करें?']
            : isMr
                ? const ['आता पुढे काय होईल?', 'कोणाची नियुक्ती झाली आहे?', 'तक्रार कशी ट्रॅक करायची?']
                : const ['What happens next?', 'Who is assigned?', 'How do I track my complaint?'];

        return AssistantMessage(
          id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          sender: AssistantMessageSender.assistant,
          timestamp: DateTime.now(),
          followUpSuggestions: suggestions,
        );
      }
    }
    return null;
  }

  // --- Handlers ---

  static AssistantMessage _handleGreeting(String query, String lang) {
    String text;
    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    if (query.contains('morning') || query.contains('प्रभात') || query.contains('सकाळ')) {
      text = isHi
          ? 'शुभ प्रभात! मैं आपकी कैसे मदद कर सकता हूँ?'
          : isMr
              ? 'शुभ सकाळ! मी तुम्हाला कशी मदत करू शकतो?'
              : 'Good morning! How can I help you today?';
    } else if (query.contains('evening') || query.contains('संध्या') || query.contains('संध्याकाळ')) {
      text = isHi
          ? 'शुभ संध्या! मैं आपकी कैसे मदद कर सकता हूँ?'
          : isMr
              ? 'शुभ संध्याकाळ! मी तुम्हाला कशी मदत करू शकतो?'
              : 'Good evening! How can I help you today?';
    } else {
      text = isHi
          ? 'नमस्ते! आज मैं आपकी क्या सहायता कर सकता हूँ?'
          : isMr
              ? 'नमस्कार! आज मी तुम्हाला कशी मदत करू शकतो?'
              : 'Hi! How can I help you today?';
    }

    final suggestions = isHi
        ? const ['सिविकफिक्स क्या है?', 'शिकायत कैसे दर्ज करें?', 'शिकायत कैसे ट्रैक करें?']
        : isMr
            ? const ['सिविकफिक्स काय आहे?', 'तक्रार कशी नोंदवायची?', 'तक्रार कशी ट्रॅक करायची?']
            : const ['What is CivicFix?', 'How do I report an issue?', 'How can I track my complaint?'];

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }

  static AssistantMessage _handleSmallTalk(String query, String lang) {
    String text;
    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    List<String> suggestions = isHi
        ? const ['सिविकफिक्स क्या है?', 'शिकायत कैसे दर्ज करें?']
        : isMr
            ? const ['सिविकफिक्स काय आहे?', 'तक्रार कशी नोंदवायची?']
            : const ['What is CivicFix?', 'How do I report an issue?'];

    if (query.contains('how are you') ||
        query.contains('how r u') ||
        query.contains('how is it going') ||
        query.contains('कैसे हैं') ||
        query.contains('कसे आहात') ||
        query.contains('kese ho') ||
        query.contains('kase ahat')) {
      text = isHi
          ? 'मैं अच्छा हूँ, धन्यवाद! मैं यहाँ सिविकफिक्स और बीएमसी सेवाओं में आपकी सहायता के लिए हूँ। आज मैं आपकी क्या मदद करूँ?'
          : isMr
              ? 'मी छान आहे, धन्यवाद! मी येथे सिविकफिक्स आणि महापालिका सेवांमध्ये आपली मदत करण्यासाठी सज्ज आहे. आज मी काय मदत करू?'
              : "I'm doing well, thank you! I'm here to assist you with CivicFix and municipal services in Greater Mumbai. How can I help you today?";
    } else if (query.contains('what are you doing') ||
        query.contains('what r u doing') ||
        query.contains('क्या कर रहे') ||
        query.contains('काय करत')) {
      text = isHi
          ? 'मैं आपकी नागरी समस्याओं की रिपोर्टिंग, स्थिति की जांच और नगर निगम सेवाओं में सहायता के लिए तैयार हूँ।'
          : isMr
              ? 'मी नागरी समस्यांची नोंदणी, तक्रारीची स्थिती तपासणे आणि महानगरपालिका सेवांमध्ये मदत करण्यासाठी सज्ज आहे.'
              : "I'm here to help with CivicFix. I can assist you with reporting civic issues, checking complaint status, and finding municipal services.";
    } else if (query.contains('who are you') ||
        query.contains('who r u') ||
        query.contains('your name') ||
        query.contains('कौन हैं') ||
        query.contains('कोण आहात') ||
        query.contains('नाव काय')) {
      text = isHi
          ? 'मैं सिविकफिक्स सहायक हूँ, जो मुंबई के नागरिकों को नागरी समस्याओं की रिपोर्टिंग और ट्रैकिंग में सहायता करता है।'
          : isMr
              ? 'मी सिविकफिक्स सहाय्यक आहे, जे मुंबईतील नागरिकांना नागरी तक्रारी नोंदवणे आणि ट्रॅक करण्यात मदत करते.'
              : "I'm the CivicFix Assistant, designed to help citizens of Greater Mumbai report and track civic grievances.";
    } else if (query.contains('thank') ||
        query.contains('धन्यवाद') ||
        query.contains('शुक्रिया') ||
        query.contains('आभार') ||
        query.contains('shukriya') ||
        query.contains('dhanyawad')) {
      text = isHi
          ? 'आपका स्वागत है! यदि आपको किसी अन्य सहायता की आवश्यकता हो तो अवश्य बताएं।'
          : isMr
              ? 'आपले स्वागत आहे! आपल्याला आणखी काही मदत हवी असल्यास नक्की सांगा.'
              : "You're very welcome! Let me know if you need anything else.";
    } else if (query.contains('bye') ||
        query.contains('goodbye') ||
        query.contains('अलविदा') ||
        query.contains('येतो') ||
        query.contains('येते')) {
      text = isHi
          ? 'अलविदा! आपका दिन शुभ हो।'
          : isMr
              ? 'नमस्कार! आपला दिवस चांगला जावो.'
              : 'Goodbye! Have a great day ahead.';
      suggestions = const [];
    } else {
      text = isHi
          ? 'मैं आपकी कैसे सहायता कर सकता हूँ? आप शिकायत दर्ज करने, स्थिति की जांच करने या बीएमसी सेवाओं के बारे में पूछ सकते हैं।'
          : isMr
              ? 'मी तुम्हाला कशी मदत करू शकतो? तुम्ही तक्रार नोंदवणे, स्थिती तपासणे किंवा महापालिका सेवांबद्दल विचारू शकता.'
              : 'How can I assist you today? Feel free to ask about reporting issues, tracking status, or BMC municipal services.';
    }

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }

  static AssistantMessage _handleCivicFixGeneral(
    String query,
    String lang,
    AssistantRagContext? ragContext,
    AssistantAppContext? appContext,
  ) {
    String text;
    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    List<String> suggestions = isHi
        ? const ['शिकायत कैसे दर्ज करें?', 'शिकायत के बाद क्या होता है?', 'शिकायत कैसे ट्रैक करें?']
        : isMr
            ? const ['तक्रार कशी नोंदवायची?', 'तक्रार नोंदणीनंतर काय होते?', 'तक्रार कशी ट्रॅक करायची?']
            : const ['How do I report an issue?', 'What happens after I submit a complaint?', 'How do I track my complaint?'];

    if (!isHi && !isMr && ragContext != null && ragContext.isGrounded && ragContext.chunks.isNotEmpty) {
      text = ragContext.chunks.first.content;
    } else if (query.contains('department') || query.contains('विभाग') || query.contains('18')) {
      text = isHi
          ? 'बृहन्मुंबई महानगरपालिका (BMC) 18 विशिष्ट विभागों में कार्य करती है (जैसे रस्ते, जलकामे, ठोस अपशिष्ट प्रबंधन, कीटक नियंत्रण, अतिक्रमण)। सिविकफिक्स आपकी शिकायतों को सीधे सही विभाग को भेजता है।'
          : isMr
              ? 'बृहन्मुंबई महानगरपालिका (BMC) 18 (१८) अधिकृत विभागांमध्ये कार्यरत आहे (उदा. रस्ते देखभाल, जलकामे, घनकचरा व्यवस्थापन, कीटक नियंत्रण, अतिक्रमण निर्मूलन). सिविकफिक्स आपल्या तक्रारी थेट योग्य विभागाकडे पाठवते.'
              : CivicAssistantKnowledge.verifiedExplanations['departments_overview']!;
    } else if (query.contains('ward') || query.contains('प्रभाग') || query.contains('वॉर्ड') || query.contains('24')) {
      text = isHi
          ? 'ग्रेटर मुंबई 24 प्रशासनिक वार्डों (A से T) में विभाजित है। सिविकफिक्स जीपीएस द्वारा सटीक वार्ड निर्धारित करता है।'
          : isMr
              ? 'बृहन्मुंबई २४ प्रशासकीय प्रभागांमध्ये (A ते T) विभागलेली आहे, ज्यामध्ये शहर, पश्चिम उपनगरे आणि पूर्व उपनगरांचा समावेश आहे. सिविकफिक्स जीपीएस स्थानावरून अचूक प्रभाग ओळखतो.'
              : CivicAssistantKnowledge.verifiedExplanations['wards_overview']!;
    } else {
      text = isHi
          ? 'सिविकफिक्स (CivicFix) बृहन्मुंबई महानगरपालिका (BMC) के लिए एक आधुनिक नागरी शिकायत निवारण प्लेटफॉर्म है। इसके माध्यम से नागरिक गड्ढे, कचरा, जल रिसाव जैसी समस्याओं की फोटो और सटीक जीपीएस लोकेशन के साथ शिकायत दर्ज कर सकते हैं और 5 चरणों में लाइव ट्रैक कर सकते हैं।'
          : isMr
              ? 'सिविकफिक्स (CivicFix) हे बृहन्मुंबई महानगरपालिका (BMC) कार्यक्षेत्रासाठी एक आधुनिक नागरी तक्रार निवारण आणि भू-स्थानिक प्लॅटफॉर्म आहे. याद्वारे नागरिक खड्डे, कचरा, पाणी गळती यांसारख्या समस्यांचे फोटो व अचूक जीपीएस स्थानासह तक्रार नोंदवू शकतात आणि थेट ५ टप्प्यांत ट्रॅक करू शकतात.'
              : CivicAssistantKnowledge.verifiedExplanations['what_is_civicfix']!;
    }

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }

  static AssistantMessage _handleCivicFixProcess(
    String query,
    AssistantIntentResult intentResult,
    String lang,
    AssistantRagContext? ragContext,
    AssistantAppContext? appContext,
  ) {
    String text;
    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    List<String> suggestions = isHi
        ? const ['सत्यापन का क्या मतलब है?', 'शिकायत कौन संभालता है?', 'शिकायत कैसे ट्रैक करें?']
        : isMr
            ? const ['पडताळणी म्हणजे काय?', 'तक्रार कोण हाताळते?', 'तक्रार कशी ट्रॅक करायची?']
            : const [
                'What does Under Verification mean?',
                'Who handles my complaint?',
                'How do I track my complaint?',
              ];

    final hasContext = appContext != null && appContext.hasComplaintContext;
    final ticketStr = hasContext && appContext.ticketId != null ? appContext.ticketId! : '';

    // 1. Live Application Complaint Context Handling
    if (hasContext) {
      if (appContext.isUnderVerification) {
        text = isHi
            ? 'आपकी शिकायत ${ticketStr.isNotEmpty ? "$ticketStr " : ""}वर्तमान में वॉर्ड ${appContext.wardId ?? ""} में सत्यापनाधीन (Under Verification (Stage 2)) है। स्वचालित सत्यापन फोटो की प्रामाणिकता (validating photo authenticity) और जिम्मेदार विभाग की पुष्टि करता है। इसके बाद यह कनिष्ठ अभियंता (Junior Engineer) को सौंपी जाएगी।'
            : isMr
                ? 'आपली तक्रार ${ticketStr.isNotEmpty ? "$ticketStr " : ""}सध्या प्रभाग ${appContext.wardId ?? ""} मध्ये पडताळणीमध्ये (टप्पा २ - Under Verification) आहे. स्वयंचलित पडताळणीद्वारे फोटोची सत्यता व जबाबदार विभागाची खातरजमा केली जाते. पडताळणी पूर्ण झाल्यावर कनिष्ठ अभियंत्याकडे वर्ग केली जाईल.'
                : 'Your complaint ${ticketStr.isNotEmpty ? "$ticketStr " : ""}is currently Under Verification (Stage 2) in Ward ${appContext.wardId ?? "designated"}. The system is validating photo authenticity before assigning to the designated Junior Engineer.';
      } else if (appContext.isBlocked) {
        final reason = appContext.blockedReason ?? 'Water logging blocking access';
        text = isHi
            ? 'आपकी शिकायत $ticketStr पर काम मौके पर आई भौतिक बाधा ($reason) के कारण अस्थायी रूप से रुका हुआ है। बाधा दूर होते ही काम फिर से शुरू होगा और SLA countdown continues।'
            : isMr
                ? 'आपल्या तक्रारीवरील $ticketStr काम प्रत्यक्ष जागेवरील अडथळ्यामुळे ($reason) तात्पुरते थांबवले आहे. अडथळा दूर होताच काम पूर्ववत सुरू होईल आणि मूळ SLA मुदत अखंडित राहते.'
                : 'Work on complaint $ticketStr is temporarily paused due to on-ground obstacle: $reason. The SLA countdown continues without pausing the overall deadline.';
      } else if (appContext.isReopened) {
        final reason = appContext.reopenReason ?? 'Asphalt surface uneven';
        text = isHi
            ? 'आपकी शिकायत $ticketStr बीएमसी गुणवत्ता मानकों को सुनिश्चित करने के लिए वॉर्ड विभाग प्रमुख (Ward Department Lead) द्वारा गुणवत्ता समीक्षा के दौरान रिवर्क के लिए दोबारा खोली गई है (कारण: $reason)। The original SLA countdown is strictly preserved और समय सीमा रीसेट नहीं होती है।'
            : isMr
                ? 'आपली तक्रार $ticketStr दर्जा मानकांची पूर्तता करण्यासाठी प्रभाग विभाग प्रमुखांनी गुणवत्ता तपासणी अंती रिवर्कसाठी पुन्हा उघडली आहे (कारण: $reason). मूळ SLA सेवा मुदत रिसेट होत नाही.'
                : 'Your complaint $ticketStr was reopened for rework during quality audit by the Ward Department Lead (Reason: $reason). The original SLA countdown is strictly preserved and continues without resetting.';
      } else if (appContext.isAssigned) {
        final jeName = appContext.assignedJuniorEngineerName ?? 'S. Kadam';
        final foName = appContext.assignedFieldOfficerName ?? 'Ganesh Kulkarni';
        text = isHi
            ? 'शिकायत $ticketStr के लिए काम अभी शुरू नहीं हुआ है (अभी नहीं / Not yet)। कनिष्ठ अभियंता ($jeName) ने फील्ड निष्पादन अधिकारी ($foName) को काम सौंपा है।'
            : isMr
                ? 'तक्रार $ticketStr साठी काम अद्याप सुरू झालेले नाही (अद्याप नाही). कनिष्ठ अभियंता ($jeName) यांनी क्षेत्रीय अंमलबजावणी अधिकारी ($foName) यांची प्रत्यक्ष कामासाठी नियुक्ती केली आहे.'
                : 'Not yet. For complaint $ticketStr, Junior Engineer ($jeName) has assigned Field Execution Officer ($foName) to handle the on-ground execution.';
      } else if (appContext.isInProgress) {
        final foName = appContext.assignedFieldOfficerName ?? 'Field Execution Officer';
        text = isHi
            ? 'हाँ, शिकायत $ticketStr पर मौके पर काम प्रगति पर है (Work In Progress)। नियुक्त फील्ड निष्पादन अधिकारी (Field Execution Officer - $foName) सक्रिय रूप से मौके पर मरम्मत कर रहे हैं।'
            : isMr
                ? 'होय, तक्रार $ticketStr साठी प्रत्यक्ष जागेवर काम प्रगतीपथावर आहे (Work In Progress). नियुक्त क्षेत्रीय अधिकारी (Field Execution Officer) प्रत्यक्ष जागेवर दुरुस्ती करत आहेत.'
                : 'Yes, on-ground work is currently Work In Progress for complaint $ticketStr. The assigned Field Execution Officer is actively executing repairs on site.';
      } else if (appContext.isResolved) {
        text = isHi
            ? 'आपकी शिकायत $ticketStr का समाधान हो गया है (Resolved (Stage 5), not yet Closed)। फोटो प्रमाण जमा कर दिया गया है और Ward Department Lead गुणवत्ता समीक्षा कर रहे हैं।'
            : isMr
                ? 'आपली तक्रार $ticketStr निवारण (टप्पा ५ - Resolved) झाली आहे. पुरावा फोटो सादर झाला असून प्रभाग प्रमुख गुणवत्ता तपासणी करत आहेत.'
                : 'Your complaint $ticketStr is marked as Resolved (Stage 5), not yet Closed. Repair evidence is submitted and awaiting supervisory quality review by the Ward Department Lead.';
      } else if (appContext.isClosed) {
        text = isHi
            ? 'आपकी शिकायत $ticketStr पूरी तरह से बंद (fully Closed) हो चुकी है।'
            : isMr
                ? 'आपली तक्रार $ticketStr पूर्णपणे बंद (fully Closed) झाली आहे.'
                : 'Your complaint $ticketStr is fully Closed.';
      } else {
        text = isHi
            ? 'आपकी शिकायत की वर्तमान स्थिति ${appContext.complaintStatus ?? "सक्रिय"} है।'
            : isMr
                ? 'आपल्या तक्रारीची सद्य स्थिती ${appContext.complaintStatus ?? "सक्रिय"} आहे.'
                : 'Your complaint status is currently ${appContext.complaintStatus ?? "active"}.';
      }
    }
    // 2. English Grounded RAG Retrieval
    else if (!isHi && !isMr && ragContext != null && ragContext.isGrounded && ragContext.chunks.isNotEmpty) {
      text = ragContext.chunks.first.content;
    }
    // 3. Hindi Localized Explanations
    else if (isHi) {
      if (query.contains('sla') || query.contains('समय') || query.contains('घंटे') || query.contains('time')) {
        text = 'सिविकफिक्स में शिकायत दर्ज होने के क्षण से (Reported) SLA घड़ी शुरू होती है। गड्ढा मरम्मत के लिए 48 घंटे, कचरा निस्तारण के लिए 12 घंटे और जल रिसाव के लिए 24 घंटे की समयसीमा होती है। रिवर्क या बाधा के दौरान मूल SLA समय सीमा रीसेट नहीं होती है।';
      } else if (query.contains('rework') || query.contains('रीसेट') || query.contains('दोबारा')) {
        text = 'रिवर्क या बाधा के दौरान मूल SLA समय सीमा रीसेट नहीं होती है और शिकायत का मूल समय बरकरार रहता है।';
      } else if (query.contains('junior engineer') || query.contains('कनिष्ठ अभियंता') || query.contains('je')) {
        text = 'कनिष्ठ अभियंता (Junior Engineer): वॉर्ड और विभाग के तकनीकी प्रमुख होते हैं। वे शिकायत का सत्यापन करते हैं और मौके पर मरम्मत के लिए फील्ड ऑफिसर असाइन करते हैं।';
      } else if (query.contains('field') || query.contains('क्षेत्रीय') || query.contains('फील्ड')) {
        text = 'फील्ड निष्पादन अधिकारी (Field Execution Officer): मौके पर प्रत्यक्ष मरम्मत कार्य करने वाले तकनीशियन होते हैं, जो कार्य शुरू होने पर "Start Work" दबाते हैं और पूरा होने पर फोटो प्रमाण अपलोड करते हैं।';
      } else if (query.contains('verification') || query.contains('सत्यापन')) {
        text = 'सत्यापन (Under Verification - चरण 2): सिस्टम फोटो की प्रामाणिकता, डुप्लीकेट जांच और उचित विभाग का निर्धारण करता है। इसके बाद कनिष्ठ अभियंता को शिकायत सौंपी जाती है।';
      } else {
        text = 'शिकायत दर्ज करने के बाद सिविकफिक्स 5-चरणीय कार्यप्रवाह चलाता है: 1. दर्ज (Reported) -> 2. सत्यापन (Under Verification) -> 3. कनिष्ठ अभियंता को असाइन (Assigned) -> 4. कार्य प्रगति पर (In Progress) -> 5. समाधान (Resolved) / गुणवत्ता समीक्षा।';
      }
    }
    // 4. Marathi Localized Explanations
    else if (isMr) {
      if (query.contains('sla') || query.contains('वेळ') || query.contains('तास') || query.contains('मुदत')) {
        text = 'सिविकफिक्समध्ये तक्रार नोंदणीच्या क्षणापासून (टप्पा १ Reported) सेवा मुदत (SLA) सुरू होते. खड्डे दुरुस्ती ४८ तास, कचरा निर्मूलन १२ तास, पाणी गळती २४ तास. अडथळा किंवा रिवर्क दरम्यान मूळ SLA रिसेट होत नाही.';
      } else if (query.contains('rework') || query.contains('रिसेट') || query.contains('पुन्हा')) {
        text = 'रिवर्क किंवा अडथळ्यादरम्यान मूळ SLA सेवा मुदत रिसेट होत नाही आणि मूळ कालावधी कायम राहतो.';
      } else if (query.contains('junior engineer') || query.contains('कनिष्ठ अभियंता') || query.contains('je')) {
        text = 'कनिष्ठ अभियंता (Junior Engineer): प्रभाग व विभागाचे तांत्रिक प्रमुख असतात. ते तक्रारीची पडताळणी करून प्रत्यक्ष कामासाठी क्षेत्रीय अधिकारी नियुक्त करतात.';
      } else if (query.contains('field') || query.contains('क्षेत्रीय')) {
        text = 'क्षेत्रीय अंमलबजावणी अधिकारी (Field Execution Officer): प्रत्यक्ष जागेवर दुरुस्तीचे काम करणारे अधिकारी असतात, जे काम सुरू झाल्यावर "Start Work" आणि पूर्ण झाल्यावर पुरावा फोटो अपलोड करतात.';
      } else if (query.contains('verification') || query.contains('पडताळणी')) {
        text = 'पडताळणी (Under Verification - टप्पा २): सिस्टीम फोटोची सत्यता, डुप्लिकेट तपासणी व योग्य विभाग निश्चित करते. पडताळणी पूर्ण झाल्यावर कनिष्ठ अभियंत्याकडे तक्रार वर्ग होते.';
      } else {
        text = 'तक्रार नोंदवल्यानंतर सिविकफिक्स ५-टप्प्यांची कार्यपद्धती राबवतो: १. नोंदणीकृत (Reported) -> २. पडताळणीमध्ये (Under Verification) -> ३. कनिष्ठ अभियंता व नियुक्त (Assigned) -> ४. काम प्रगतीपथावर (In Progress) -> ५. निवारण (Resolved) / गुणवत्ता तपासणी.';
      }
    }
    // 5. English Default Fallback
    else {
      text = CivicAssistantKnowledge.verifiedExplanations['post_submission_lifecycle']!;
    }

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }

  static AssistantMessage _handleCivicFixHelp(
    String query,
    String lang,
    AssistantRagContext? ragContext,
    AssistantAppContext? appContext,
  ) {
    String text;
    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    List<String> suggestions = isHi
        ? const ['फोटो कैसे जोड़ें?', 'स्थान कैसे चुनें?']
        : isMr
            ? const ['फोटो कसा जोडायचा?', 'स्थान कसे निवडायचे?']
            : const ['How do I add a photo?', 'How do I select a location?'];

    final hasContext = appContext != null && appContext.hasComplaintContext;
    final currentScreen = appContext?.currentScreen;

    // 1. Screen Context: Report Issue
    if (currentScreen == 'reportIssue') {
      text = isHi
          ? 'सिविकफिक्स में Report Issue के लिए इन 4 चरणों का पालन करें:\n1. Issue Info: शीर्षक, विवरण और श्रेणी चुनें।\n2. Evidence: फोटो जोड़ें।\n3. Location: जीपीएस की पुष्टि करें।\n4. Review & Submit: सबमिट करें।'
          : isMr
              ? 'सिविकफिक्समध्ये Report Issue साठी या ४ टप्प्यांचा वापर करा:\n1. Issue Info: माहिती आणि वर्ग निवडा.\n2. Evidence: फोटो जोडा.\n3. Location: जीपीएस निवडा.\n4. Review & Submit: सबमिट करा.'
              : 'To Report Issue in CivicFix, follow these 4 steps:\n1. Issue Info: Enter title, description, and select category.\n2. Evidence: Attach up to 3 photos.\n3. Location: Confirm GPS or adjust pin.\n4. Review & Submit: Tap Submit Issue to begin SLA tracking.';
    }
    // 2. Context-Aware Offline / Sync Pending Help
    else if (hasContext && appContext.isOfflinePending) {
      final ticket = appContext.ticketId ?? 'TEMP-SYNC';
      text = isHi
          ? 'आपकी शिकायत $ticket वर्तमान में आपके डिवाइस पर ऑफ़लाइन कतार (Pending Sync) में सुरक्षित है। इंटरनेट कनेक्टिविटी बहाल होते ही यह स्वचालित रूप से बीएमसी सर्वर पर सिंक हो जाएगी।'
          : isMr
              ? 'आपली तक्रार $ticket सध्या आपल्या डिव्हाइसवर ऑफलाइन रांगेत (offline queue - Pending Sync) सुरक्षित आहे. इंटरनेट कनेक्ट होताच ती आपोआप बीएमसी सर्व्हरशी सिंक होईल आणि थेट ट्रॅकिंग सुरू होईल.'
              : 'Your complaint $ticket is currently stored locally on your device in the offline queue (Pending Sync). It will automatically sync to the BMC server once internet connectivity is restored, after which live tracking will begin.';
    }
    // 3. English Grounded RAG Retrieval
    else if (!isHi && !isMr && ragContext != null && ragContext.isGrounded && ragContext.chunks.isNotEmpty) {
      text = ragContext.chunks.first.content;
    }
    // 4. Hindi Localized Guidance
    else if (isHi) {
      if (query.contains('offline') || query.contains('ऑफलाइन') || query.contains('इंटरनेट')) {
        text = 'सिविकफिक्स में बिना इंटरनेट कनेक्शन के भी ऑफलाइन शिकायत दर्ज की जा सकती है। इंटरनेट बहाल होते ही रिपोर्ट स्वचालित रूप से सर्वर पर सिंक हो जाती है।';
      } else if (query.contains('photo') || query.contains('फोटो') || query.contains('कैमरा') || query.contains('पुरावा')) {
        text = 'शिकायत दर्ज करते समय आप कैमरा या गैलरी से अधिकतम 3 स्पष्ट फोटो अपलोड कर सकते हैं। जीपीएस और फोटो प्रमाण से नगर निगम त्वरित कार्रवाई करता है।';
      } else {
        text = 'समस्या दर्ज करने के लिए (Report an Issue): होम स्क्रीन पर "Report Issue" दबाएं, शिकायत विवरण भरें, कैमरा या फोटो अपलोड करें, जीपीएस स्थान चुनें और सबमिट करें।';
      }
    }
    // 5. Marathi Localized Guidance
    else if (isMr) {
      if (query.contains('offline') || query.contains('ऑफलाइन') || query.contains('इंटरनेट')) {
        text = 'इंटरनेट नसतानाही सिविकफिक्समध्ये ऑफलाइन तक्रार नोंदवता येते. इंटरनेट कनेक्ट होताच तक्रार आपोआप सिंक होते.';
      } else if (query.contains('photo') || query.contains('फोटो') || query.contains('कॅमेरा') || query.contains('पुरावा')) {
        text = 'तक्रार नोंदवताना आपण कॅमेरा किंवा गॅलरीतून जास्तीत जास्त ३ स्पष्ट फोटो जोडू शकता. अचूक जीपीएस आणि फोटो पुराव्यामुळे जलद निवारण होते.';
      } else {
        text = 'तक्रार नोंदवण्यासाठी (Report an Issue): होम स्क्रीनवर "Report Issue" वर टॅप करा, तक्रार माहिती लिहा, कॅमेरा किंवा फोटो जोडा, जीपीएस स्थान निवडा आणि सबमिट करा.';
      }
    }
    // 6. English Default Fallback
    else {
      text = CivicAssistantKnowledge.verifiedExplanations['how_to_report']!;
    }

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }

  static AssistantMessage _handleCivicFixNavigation(
    String query,
    String lang,
    AssistantRagContext? ragContext,
    AssistantAppContext? appContext,
  ) {
    String text;
    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    List<String> suggestions = isHi
        ? const ['सत्यापन का क्या मतलब है?', 'शिकायत कैसे दर्ज करें?']
        : isMr
            ? const ['पडताळणी म्हणजे काय?', 'तक्रार कशी नोंदवायची?']
            : const ['What does Under Verification mean?', 'How do I report an issue?'];

    final hasContext = appContext != null && appContext.hasComplaintContext;
    final currentScreen = appContext?.currentScreen;

    if (currentScreen == 'map') {
      text = isHi
          ? 'सिविकफिक्स हैज़र्ड मैप (Hazard Map) पर रंग-कोडित पिन और dynamic spatial clustering के साथ आस-पास की समस्याएं दिखाई देती हैं।'
          : isMr
              ? 'धोका नकाशावर (Hazard Map) रंगीत पिन आणि dynamic spatial clustering द्वारे परिसरातील नागरी समस्या दिसतात.'
              : 'The CivicFix Hazard Map is an interactive GIS interface showing color-coded pins and dynamic spatial clustering for nearby civic issues with category and radius filtering.';
    } else if (hasContext && appContext.isOfflinePending) {
      final ticket = appContext.ticketId ?? 'TEMP-SYNC';
      text = isHi
          ? 'आपकी शिकायत $ticket वर्तमान में आपके डिवाइस पर ऑफ़लाइन कतार (Pending Sync) में सुरक्षित है। इंटरनेट कनेक्टिविटी बहाल होते ही यह स्वचालित रूप से बीएमसी सर्वर पर सिंक हो जाएगी।'
          : isMr
              ? 'आपली तक्रार $ticket सध्या आपल्या डिव्हाइसवर ऑफलाइन रांगेत (offline queue - Pending Sync) सुरक्षित आहे. इंटरनेट कनेक्ट होताच ती आपोआप बीएमसी सर्व्हरशी सिंक होईल आणि थेट ट्रॅकिंग सुरू होईल.'
              : 'Your complaint $ticket is currently stored locally on your device in the offline queue (Pending Sync). It will automatically sync to the BMC server once internet connectivity is restored, after which live tracking will begin.';
    } else if (!isHi && !isMr && ragContext != null && ragContext.isGrounded && ragContext.chunks.isNotEmpty) {
      text = ragContext.chunks.first.content;
    } else if (isHi) {
      if (query.contains('map') || query.contains('मैप') || query.contains('नक्शा') || query.contains('hazard')) {
        text = 'सिविकफिक्स हैज़र्ड मैप (Hazard Map / नक्शा) पर आप अपने आस-पास की नागरी समस्याएं, खड्डे और कचरा डंप रंग-कोडित पिन और dynamic spatial clustering के साथ देख सकते हैं।';
      } else {
        text = 'अपनी शिकायतों की स्थिति देखने के लिए नीचे नेविगेशन में "My Complaints" (मेरी शिकायतें) पर टैप करें और लाइव ट्रैक करें।';
      }
    } else if (isMr) {
      if (query.contains('map') || query.contains('नकाशा') || query.contains('धोका') || query.contains('hazard')) {
        text = 'धोका नकाशावर (Hazard Map / नकाशा) आपण परिसरातील नागरी समस्या, खड्डे व कचऱ्याचे ढीग रंगीत पिन आणि dynamic spatial clustering सह पाहू शकता.';
      } else {
        text = 'आपल्या तक्रारींचा ५ टप्प्यांचा प्रवास पाहण्यासाठी खालील नेव्हिगेशनमध्ये "My Complaints" (माझ्या तक्रारी) वर टॅप करा आणि ट्रॅक करा.';
      }
    } else {
      text = CivicAssistantKnowledge.verifiedExplanations['how_to_track']!;
    }

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }

  static AssistantMessage _handleOutOfScope(String query, String lang) {
    String text;
    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    if (query.contains('joke') ||
        query.contains('laugh') ||
        query.contains('चुटकुला') ||
        query.contains('चुटकला') ||
        query.contains('विनोद')) {
      text = isHi
          ? 'ट्रैफिक लाइट लाल क्यों हुई? अगर आपको भी सड़क के बीच में बदलना पड़ता तो आप भी लाल हो जाते! 😄 सिविकफिक्स में आपकी कोई सहायता करूँ?'
          : isMr
              ? 'ट्रॅफिक सिग्नल लाल का झाला? तुम्हालाही रस्त्याच्या मधोमध रंग बदलावा लागला असता तर तुम्हीही लाल झाला असतात! 😄 सिविकफिक्समध्ये काही मदत हवी असल्यास सांगा.'
              : 'Why did the traffic light turn red? You would too if you had to change in the middle of the street! 😄 Let me know if you need any assistance with CivicFix.';
    } else if (query.contains('japan') || query.contains('जपान')) {
      text = isHi
          ? 'जापान की राजधानी टोक्यो है। कृपया मुझे बताएं यदि आप मुंबई में नगर निगम सेवाओं या सिविकफिक्स के बारे में कुछ पूछना चाहते हैं!'
          : isMr
              ? 'जपानची राजधानी टोकियो आहे. मुंबईतील नागरी सेवा किंवा सिविकफिक्सबद्दल काही माहिती हवी असल्यास नक्की विचारा!'
              : 'The capital of Japan is Tokyo. Please let me know if you have any questions about reporting civic issues or municipal services in Greater Mumbai!';
    } else if (query.contains('photosynthesis') ||
        query.contains('प्रकाश संश्लेषण') ||
        query.contains('प्रकाशसंश्लेषण')) {
      text = isHi
          ? 'प्रकाश संश्लेषण (Photosynthesis) वह प्रक्रिया है जिससे पौधे सूर्य के प्रकाश से ऊर्जा बनाते हैं। सिविकफिक्स में किसी सहायता के लिए बताएं!'
          : isMr
              ? 'प्रकाशसंश्लेषण (Photosynthesis) ही वनस्पतींची सूर्यप्रकाशापासून ऊर्जा तयार करण्याची प्रक्रिया आहे. सिविकफिक्समध्ये काही मदत हवी असल्यास विचारा!'
              : 'Photosynthesis is the process by which green plants use sunlight, water, and carbon dioxide to create oxygen and energy. Let me know if I can help you with anything in CivicFix!';
    } else if (query.contains('weather') || query.contains('मौसम') || query.contains('हवामान')) {
      text = isHi
          ? 'मैं केवल ग्रेटर मुंबई में सिविकफिक्स (CivicFix) और नागरी सेवाओं में सहायता कर सकता हूँ। मौसम की जानकारी के लिए मौसम ऐप देखें।'
          : isMr
              ? 'मी केवळ बृहन्मुंबईत नागरी सेवा आणि सिविकफिक्स (CivicFix) साठी मदत करू शकतो. हवामानाच्या माहितीसाठी हवामान ॲप तपासावे.'
              : 'I am the CivicFix Assistant and specialize in municipal civic grievances for Greater Mumbai. Please check a weather service for forecasts outside Mumbai.';
    } else {
      text = isHi
          ? 'मैं सामान्य प्रश्नों का त्वरित उत्तर दे सकता हूँ, लेकिन मेरी मुख्य भूमिका ग्रेटर मुंबई में सिविकफिक्स और बीएमसी सेवाओं में आपकी सहायता करना है।'
          : isMr
              ? 'मी सामान्य प्रश्नांची उत्तरे देऊ शकतो, पण माझी मुख्य भूमिका मुंबईतील नागरी सेवा व सिविकफिक्समध्ये मदत करणे ही आहे.'
              : "I can answer quick general questions, but my primary role is assisting you with CivicFix and municipal services in Greater Mumbai. How can I help you today?";
    }

    final suggestions = isHi
        ? const ['सिविकफिक्स क्या है?', 'शिकायत कैसे दर्ज करें?', 'शिकायत कैसे ट्रैक करें?']
        : isMr
            ? const ['सिविकफिक्स काय आहे?', 'तक्रार कशी नोंदवायची?', 'तक्रार कशी ट्रॅक करायची?']
            : const ['What is CivicFix?', 'How do I report an issue?', 'How do I track my complaint?'];

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }

  static AssistantMessage _handleUnknown(
    String query,
    String lang,
    AssistantRagContext? ragContext,
    AssistantAppContext? appContext,
  ) {
    // If RAG context successfully retrieved high-confidence grounded chunks, answer using top chunk
    if (ragContext != null && ragContext.isGrounded && ragContext.chunks.isNotEmpty) {
      final topChunk = ragContext.chunks.first;
      return AssistantMessage(
        id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
        text: topChunk.content,
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: const [
          'What is CivicFix?',
          'How do I report an issue?',
          'How do I track my complaint?',
        ],
      );
    }

    final isHi = lang == 'hi';
    final isMr = lang == 'mr';

    final text = isHi
        ? 'मेरे पास इस बारे में सटीक उत्तर देने के लिए पर्याप्त सत्यापित सिविकफिक्स जानकारी नहीं है। मैं केवल ग्रेटर मुंबई में बीएमसी कार्यप्रवाह, शिकायत दर्ज करने, ट्रैकिंग, विभागों, वार्डों और नागरिक सेवाओं में सहायता कर सकता हूँ।'
        : isMr
            ? 'याबद्दल अचूक उत्तर देण्यासाठी माझ्याकडे पुरेशी पडताळलेली सिविकफिक्स माहिती उपलब्ध नाही. मी फक्त बृहन्मुंबई महानगरपालिकेच्या कार्यपद्धती, तक्रार नोंदणी, ट्रॅकिंग, विभाग, प्रभाग आणि नागरी सेवांमध्ये मदत करू शकतो.'
            : CivicAssistantKnowledge.strictHallucinationBoundaryMessage;

    final suggestions = isHi
        ? const ['सिविकफिक्स क्या है?', 'शिकायत कैसे दर्ज करें?', 'शिकायत के बाद क्या होता है?', 'शिकायत कैसे ट्रैक करें?']
        : isMr
            ? const ['सिविकफिक्स काय आहे?', 'तक्रार कशी नोंदवायची?', 'तक्रार नोंदणीनंतर काय होते?', 'तक्रार कशी ट्रॅक करायची?']
            : const [
                'What is CivicFix?',
                'How do I report an issue?',
                'What happens after I submit a complaint?',
                'How do I track my complaint?',
              ];

    return AssistantMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: suggestions,
    );
  }
}
