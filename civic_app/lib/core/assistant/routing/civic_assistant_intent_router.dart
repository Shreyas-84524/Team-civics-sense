import '../models/assistant_conversation_history.dart';
import '../models/civic_assistant_intent.dart';

/// Semantic intent router for the CivicFix Assistant.
///
/// Supports English, Hindi (Devanagari & Romanized), and Marathi (Devanagari & Romanized)
/// phrase structures, context-aware follow-ups, and municipal domain routing.
class CivicAssistantIntentRouter {
  /// Evaluates user input and conversation context to determine the primary intent.
  static AssistantIntentResult route({
    required String query,
    AssistantConversationHistory? history,
  }) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.unknown,
        matchedRule: 'empty_query',
      );
    }

    // 1. Context-Aware Follow-Up Check (Multi-turn conversational resolution)
    if (_isContextualFollowUp(clean) && history != null && history.isNotEmpty) {
      final contextIntent = _resolveContextualFollowUp(clean, history);
      if (contextIntent != null) {
        return contextIntent;
      }
    }

    // 2. Casual Greetings
    if (_matchesCasualGreeting(clean)) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.casualGreeting,
        matchedRule: 'casual_greeting',
      );
    }

    // 3. Casual Small Talk
    if (_matchesCasualSmallTalk(clean)) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.casualSmallTalk,
        matchedRule: 'casual_small_talk',
      );
    }

    // 4. CivicFix Help (Reporting steps, editing rules, photo/location guidance, offline troubleshooting)
    if (_matchesCivicFixHelp(clean)) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.civicfixHelp,
        matchedRule: 'civicfix_help',
      );
    }

    // 5. CivicFix In-App Navigation & Tracking
    if (_matchesCivicFixNavigation(clean)) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.civicfixNavigation,
        matchedRule: 'civicfix_navigation',
      );
    }

    // 6. CivicFix Process, Workflow, Roles & SLAs
    if (_matchesCivicFixProcess(clean)) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.civicfixProcess,
        matchedRule: 'civicfix_process',
      );
    }

    // 7. CivicFix General Questions (Overview, departments, wards, jurisdiction)
    if (_matchesCivicFixGeneral(clean)) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.civicfixGeneral,
        matchedRule: 'civicfix_general',
      );
    }

    // 8. Out-of-Scope General Questions
    if (_matchesOutOfScopeGeneral(clean)) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.outOfScopeGeneral,
        matchedRule: 'out_of_scope_general',
      );
    }

    // 9. Unknown / Unclassified
    return const AssistantIntentResult(
      intent: CivicAssistantIntent.unknown,
      confidence: 0.5,
      matchedRule: 'unclassified_fallback',
    );
  }

  // --- Pattern Matchers ---

  static bool _matchesCasualGreeting(String text) {
    final greetings = [
      // English
      RegExp(r'^(hi|hello|hey|hiya)[\s!.,?]*$'),
      RegExp(r'^(good\s+(morning|afternoon|evening|day))[\s!.,?]*$'),
      RegExp(r'^(hi|hello|hey)\s+(civicfix|assistant|there|bot)[\s!.,?]*$'),
      // Hindi / Marathi Devanagari
      RegExp(r'^(नमस्ते|नमस्कार|प्रणाम|जय\s+महाराष्ट्र|जय\s+हिंद)[\s!.,?]*$'),
      RegExp(r'^(शुभ\s+(प्रभात|संध्या|सकाळ|संध्याकाळ|दिवस))[\s!.,?]*$'),
      // Romanized
      RegExp(r'^(namaste|namaskar|pranam|ram\s+ram)[\s!.,?]*$'),
    ];
    return greetings.any((regex) => regex.hasMatch(text));
  }

  static bool _matchesCasualSmallTalk(String text) {
    final smallTalkPatterns = [
      // English
      RegExp(r'how\s+are\s+you'),
      RegExp(r'how\s+r\s+u'),
      RegExp(r'how\s+is\s+it\s+going'),
      RegExp(r'what\s+are\s+you\s+doing'),
      RegExp(r'what\s+r\s+u\s+doing'),
      RegExp(r'who\s+are\s+you'),
      RegExp(r'who\s+r\s+u'),
      RegExp(r'what\s+is\s+your\s+name'),
      RegExp(r'thank\s*you'),
      RegExp(r'thanks'),
      RegExp(r'^(bye|goodbye|see\s+you|later|cya)[\s!.,?]*$'),

      // Hindi Devanagari
      RegExp(r'(आप\s+कैसे\s+हैं|तुम\s+कैसे\s+हो|कैसा\s+है|क्या\s+हाल\s+है)'),
      RegExp(r'(आप\s+क्या\s+कर\s+रहे\s+हैं|तुम\s+क्या\s+कर\s+रहे\s+हो)'),
      RegExp(r'(आप\s+कौन\s+हैं|तुम\s+कौन\s+हो|तुम्हारा\s+नाम\s+क्या\s+है)'),
      RegExp(r'(धन्यवाद|शुक्रिया|अलविदा)'),

      // Marathi Devanagari
      RegExp(r'(तुम्ही\s+कसे\s+आहात|कसे\s+आहात|तू\s+कसा\s+आहेस|तू\s+कशी\s+आहेस)'),
      RegExp(r'(तुम्ही\s+काय\s+करत\s+आहात|तू\s+काय\s+करतोस|तू\s+काय\s+करतेस)'),
      RegExp(r'(तुम्ही\s+कोण\s+आहात|तू\s+कोण\s+आहेस|तुमचे\s+नाव\s+काय\s+आहे)'),
      RegExp(r'(आभार|धन्यवाद|येतो\s+मी|येते\s+मी)'),

      // Romanized
      RegExp(r'\b(kese\s+ho|kaise\s+ho|kase\s+ahat|kasa\s+ahes|kashi\s+ahes)\b'),
      RegExp(r'\b(dhanyawad|dhanyavad|shukriya|aabhar)\b'),
    ];
    return smallTalkPatterns.any((regex) => regex.hasMatch(text));
  }

  static bool _matchesCivicFixGeneral(String text) {
    final generalPatterns = [
      // English
      RegExp(r'what\s+is\s+civicfix'),
      RegExp(r'about\s+civicfix'),
      RegExp(r'tell\s+me\s+about\s+civicfix'),
      RegExp(r'what\s+does\s+this\s+app\s+do'),
      RegExp(r'what\s+is\s+this\s+app'),
      RegExp(r'who\s+created\s+civicfix'),
      RegExp(r'who\s+made\s+civicfix'),
      RegExp(r'purpose\s+of\s+civicfix'),
      RegExp(r'how\s+many\s+(wards|departments)'),
      RegExp(r'what\s+can\s+a\s+citizen\s+do'),
      RegExp(r'prevent\s+duplicate'),
      RegExp(r'duplicate\s+complaint'),
      RegExp(r'detect\s+duplicate'),
      RegExp(r'duplicate.*radius'),
      RegExp(r'what\s+are\s+the\s+(18\s+)?departments'),
      RegExp(r'what\s+are\s+the\s+(24\s+)?wards'),
      RegExp(r'list\s+(all\s+)?(departments|wards)'),
      RegExp(r'\b(18\s+departments|24\s+wards)\b'),
      RegExp(r'\b(jurisdiction|coverage)\b'),

      // Hindi
      RegExp(r'सिविकफिक्स\s+क्या\s+है'),
      RegExp(r'सिविकफिक्स\s+के\s+बारे\s+में'),
      RegExp(r'यह\s+ऐप\s+क्या\s+करता\s+है'),
      RegExp(r'(कितने\s+विभाग|कितने\s+वार्ड|कितने\s+प्रभाग)'),
      RegExp(r'\b(18\s+विभाग|24\s+वॉर्ड|24\s+प्रभाग|कार्यक्षेत्र)\b'),

      // Marathi
      RegExp(r'civicfix\s+काय\s+आहे'),
      RegExp(r'सिविकफिक्स\s+काय\s+आहे'),
      RegExp(r'सिविकफिक्स\s+बद्दल'),
      RegExp(r'हे\s+(ॲप|अॅप|app)\s+काय\s+करते'),
      RegExp(r'(किती\s+विभाग|किती\s+प्रभाग)'),
      RegExp(r'\b(18\s+विभाग|24\s+प्रभाग|अधिकारक्षेत्र)\b'),

      // Romanized
      RegExp(r'civicfix\s+(kya|kay)\s+(hai|aahe)'),
    ];
    return generalPatterns.any((regex) => regex.hasMatch(text));
  }

  static bool _matchesCivicFixHelp(String text) {
    final helpPatterns = [
      // How to report (English, Hindi, Marathi, Romanized)
      RegExp(r'how\s+(do\s+i|to)\s+(report|file|lodge|register|submit)\s+(a\s+)?(complaint|issue|pothole|grievance|garbage|water)'),
      RegExp(r'steps?\s+to\s+report'),
      RegExp(r'report\s+(an?\s+)?issue'),
      RegExp(r'what\s+do\s+i\s+do(\s+here)?'),
      RegExp(r'(शिकायत\s+कैसे\s+(दर्ज|करें|रजिस्टर|सबमिट)|रिपोर्ट\s+कैसे\s+करें)'),
      RegExp(r'(तक्रार\s+कशी\s+(नोंदवायची|करावी|नोंदणी|सादर)|नोंदणी\s+कशी\s+करावी)'),
      RegExp(r'(shikayat|takrar|pothole|road|issue)\s+.*report\s+kaise'),
      RegExp(r'report\s+kaise\s+(kare|karu|karein|karayche)'),

      // Which department handles specific complaints
      RegExp(r'which\s+department\s+(fixes|handles|clears|removes|prunes|is\s+responsible|conducts)'),
      RegExp(r'department\s+(fixes|handles|clears|removes|prunes)'),

      // Post-submission modification rules
      RegExp(r'can\s+i\s+edit\s+(a\s+)?(complaint|ticket)'),
      RegExp(r'how\s+to\s+edit\s+(my\s+)?complaint'),
      RegExp(r'can\s+i\s+change\s+(my\s+)?complaint'),
      RegExp(r'(शिकायत\s+में\s+बदलाव|शिकायत\s+एडिट|बदल\s+सकते\s+हैं)'),
      RegExp(r'(तक्रारीत\s+बदल|तक्रार\s+बदलता\s+येते\s+का|तक्रार\s+संपादित)'),

      // Photos / Evidence & Anti-Fraud
      RegExp(r'how\s+(do\s+i|to)\s+(add|upload|attach)\s+(a\s+)?(photo|picture|evidence|image)'),
      RegExp(r'photo\s+evidence'),
      RegExp(r'how\s+many\s+photos'),
      RegExp(r'upload.*gallery'),
      RegExp(r'gallery\s+photos?'),
      RegExp(r'why\s+can.*upload'),
      RegExp(r'camera\s+in\s+real-time'),
      RegExp(r'live\s+camera'),
      RegExp(r'real-time'),
      RegExp(r'gps\s+exif'),
      RegExp(r'exif\s+metadata'),
      RegExp(r'photo\s+tampering'),
      RegExp(r'gps\s+fraud'),
      RegExp(r'\b(tamper|fraud)\b'),
      RegExp(r'what\s+evidence\s+must'),
      RegExp(r'proof\s+must\s+a\s+field\s+officer'),
      RegExp(r'what\s+proof'),
      RegExp(r'officer\s+proof'),
      RegExp(r'evidence\s+must\s+a\s+field\s+officer'),
      RegExp(r'(फोटो\s+कैसे\s+जोड़ें|फोटो\s+अपलोड|प्रमाण\s+अपलोड|फोटो\s+अपलोड\s+करने\s+के\s+नियम)'),
      RegExp(r'(फोटो\s+कसा\s+जोडायचा|फोटो\s+अपलोड|पुरावा\s+जोडा)'),

      // Location & GPS
      RegExp(r'how\s+(do\s+i|to)\s+(select|set|pin|choose)\s+(location|gps|address)'),
      RegExp(r'gps\s+(not\s+working|error|permission)'),
      RegExp(r'(लोकेशन\s+कैसे\s+चुनें|स्थान\s+कैसे\s+सेट\s+करें|जीपीएस\s+काम\s+नहीं)'),
      RegExp(r'(स्थान\s+कसे\s+निवडायचे|पत्ता\s+कसा\s+टाकायचा|जीपीएस\s+त्रुटी)'),

      // Troubleshooting & Offline Sync
      RegExp(r"why\s+(can'?t|cannot)\s+i\s+track"),
      RegExp(r'no\s+internet\s+connection'),
      RegExp(r"don'?t\s+have\s+internet"),
      RegExp(r'no\s+active\s+internet'),
      RegExp(r'file\s+a\s+complaint\s+when.*internet'),
      RegExp(r'stored\s+on\s+(the\s+)?device'),
      RegExp(r'saved\s+on\s+(my\s+)?device'),
      RegExp(r'offline\s+complaint\s+saved'),
      RegExp(r'uploaded\s+to\s+bmc'),
      RegExp(r'upload\s+automatically'),
      RegExp(r'internet\s+reconnect'),
      RegExp(r'sync\s+pending'),
      RegExp(r'status\s+is\s+displayed\s+for\s+pending\s+offline'),
      RegExp(r'\b(offline|no\s+internet|sync\s+pending|синк\s+पेंडिंग|ऑफलाइन|सिंक\s+प्रलंबित)\b'),
      RegExp(r'upload\s+(failed|error)'),
      RegExp(r'(बिना\s+इंटरनेट|इंटरनेट\s+नसताना)'),
      RegExp(r'(ट्रैक\s+क्यों\s+नहीं|ट्रॅक\s+का\s+होत\s+नाही|सिंक\s+का\s+होत\s+नाही|sync\s+kyu)'),

      // Categories
      RegExp(r'what\s+categories'),
      RegExp(r'which\s+category'),
      RegExp(r'pothole\s+category'),
      RegExp(r'(कोणत्या\s+वर्गवाऱ्या|कॅटेगरी|श्रेणी)'),
    ];
    return helpPatterns.any((regex) => regex.hasMatch(text));
  }

  static bool _matchesCivicFixProcess(String text) {
    final processPatterns = [
      // Post-submission lifecycle & workflow
      RegExp(r'\blifecycle\b'),
      RegExp(r'what\s+is\s+the\s+(complete\s+)?lifecycle'),
      RegExp(r'what\s+happens\s+after(\s+i)?\s+submi'),
      RegExp(r'what\s+(is\s+done|happens)\s+after\s+submi'),
      RegExp(r'after\s+submission'),
      RegExp(r'what\s+happens\s+next'),
      RegExp(r'next\s+steps?\s+after'),
      RegExp(r'what\s+is\s+the\s+workflow'),
      RegExp(r'how\s+does\s+the\s+workflow\s+work'),
      RegExp(r'workflow\s+from\s+start\s+to\s+finish'),
      RegExp(r'what\s+is\s+happening(\s+with|\s+to|\s+now)?'),
      RegExp(r'what\s+occurs\s+during'),
      RegExp(r'what\s+happens\s+(during|when)'),
      RegExp(r'status\s+of\s+(my\s+)?complaint'),
      RegExp(r'is\s+(it|work|the\s+repair|my\s+repair|my\s+complaint|this)\s+(finished|resolved|done|completed)'),
      RegExp(r'is\s+(it|work|the\s+repair|my\s+repair|my\s+complaint)\s+started'),
      RegExp(r'has\s+(work|the\s+repair|my\s+repair|it)\s+started'),
      RegExp(r'who\s+is\s+working\s+on'),

      // Hindi Process
      RegExp(r'(शिकायत\s+दर्ज\s+करने\s+के\s+बाद\s+क्या|सबमिशन\s+के\s+बाद)'),
      RegExp(r'(अब\s+आगे\s+क्या\s+होगा|आगे\s+क्या\s+होगा|आगे\s+की\s+प्रक्रिया)'),
      RegExp(r'(मेरी\s+शिकायत\s+की\s+स्थिति|शिकायत\s+का\s+क्या\s+हुआ|काम\s+शुरू\s+हुआ\s+क्या|क्या\s+काम\s+शुरू|काम\s+शुरू\s+हो\s+गया)'),
      RegExp(r'(क्या\s+मेरी\s+शिकायत\s+पूरी\s+हो\s+गई|समाधान\s+हुआ\s+क्या)'),

      // Marathi Process
      RegExp(r'(तक्रार\s+नोंदवल्यानंतर\s+पुढे\s+काय|सबमिशननंतर\s+काय)'),
      RegExp(r'(आता\s+पुढे\s+काय\s+होईल|पुढे\s+काय\s+होईल|पुढे\s+काय\s+होणार)'),
      RegExp(r'(माझ्या\s+तक्रारीची\s+स्थिती|तक्रारीचे\s+काय\s+झाले|काम\s+सुरू\s+झाले\s+का|काम\s+सुरू\s+झाले|काम\s+सुरू\s+आहे)'),
      RegExp(r'(तक्रार\s+निकाली\s+निघाली\s+का|निवारण\s+झाले\s+का|तक्रार\s+पूर्ण\s+झाली\s+का)'),

      // Romanized Process
      RegExp(r'\b(aage\s+kya\s+hoga|pudhe\s+kay\s+hoil|work\s+start\s+(zala|hua)\s+ka|kam\s+shuru\s+hua|work\s+start\s+hua\s+kya|work\s+start\s+zala\s+ka)\b'),
      RegExp(r'assigned.*work\s+start'),

      // Status definitions
      RegExp(r'what\s+does\s+(the\s+)?(reported|under\s+verification|assigned|in\s+progress|resolved|closed|blocked|reopened)\s+(status\s+)?mean'),
      RegExp(r'under\s+verification'),
      RegExp(r'why\s+is\s+it\s+(still\s+)?under\s+verification'),
      RegExp(r'why\s+is\s+(it|verification)\s+taking\s+time'),
      RegExp(r'complaint\s+stages?'),
      RegExp(r'5\s+stages?'),
      RegExp(r'(सत्यापन\s+का\s+मतलब|सत्यापनाधीन\s+क्यों|सत्यापन\s+में\s+समय)'),
      RegExp(r'(पडताळणी\s+म्हणजे\s+काय|पडताळणीमध्ये\s+का|पडताळणीला\s+वेळ)'),

      // Roles & Assignment
      RegExp(r'(role|responsibility|responsibilities|duties)\s+(of\s+)?(a\s+|the\s+)?(junior\s+engineer|je|field\s+officer|field\s+execution\s+officer|ward\s+department\s+lead|executive\s+engineer|citizen)'),
      RegExp(r'what\s+does\s+(a\s+|the\s+)?(junior\s+engineer|field\s+officer|field\s+execution\s+officer|ward\s+department\s+lead|executive\s+engineer|citizen)\s+(do|oversee)'),
      RegExp(r'can\s+a\s+junior\s+engineer\s+also\s+be'),
      RegExp(r'has\s+(work\s+started|someone\s+been\s+assigned)'),
      RegExp(r'who\s+is\s+assigned'),
      RegExp(r'who\s+handles?\s+(my\s+)?complaint'),
      RegExp(r'who\s+will\s+fix\s+(my\s+)?(complaint|issue|problem)'),
      RegExp(r'government\s+roles'),
      RegExp(r'(कनिष्ठ\s+अभियंता|क्षेत्रीय\s+(अंमलबजावणी\s+)?अधिकारी|कार्यकारी\s+अभियंता|अधिकारी\s+कोण|फील्ड\s+ऑफिसर)'),
      RegExp(r'(कोणाची\s+नियुक्ती|नियुक्ती\s+झाली|किसे\s+असाइन|किसे\s+सौंपा|असाइन\s+किया|कोणाला\s+नेमले)'),

      // Obstacle / Blocked
      RegExp(r"why\s+(is\s+it\s+blocked|isn'?t\s+the\s+work\s+moving|is\s+it\s+not\s+moving|is\s+work\s+stopped|is\s+work\s+paused)"),
      RegExp(r'(काम\s+क्यों\s+रुका|बाधा\s+क्यों|अवरुद्ध\s+क्यों)'),
      RegExp(r'(काम\s+का\s+थांबले|अडथळा\s+काय|काम\s+का\s+पुढे\s+जात\s+नाही)'),

      // Reopening & Rework
      RegExp(r'what\s+happens\s+when\s+a\s+complaint\s+is\s+reopened'),
      RegExp(r'why\s+(was\s+this|was\s+my\s+complaint|are\s+they\s+fixing\s+it|is\s+my\s+complaint\s+active)\s+(reopened|again|for\s+rework)'),
      RegExp(r'supervisor\s+rejects'),
      RegExp(r'unsatisfactory'),
      RegExp(r'why\s+would\s+a\s+complaint\s+be\s+sent\s+back'),
      RegExp(r'reopen(ed)?\s+complaint'),
      RegExp(r'rework'),
      RegExp(r'(शिकायत\s+दोबारा\s+क्यों\s+खोली|पुनः\s+खोला|रिवर्क)'),
      RegExp(r'(तक्रार\s+पुन्हा\s+का\s+उघडली|पुन्हा\s+उघडले|रिवर्क\s+म्हणजे)'),
      RegExp(r'reopen\s+(kyu|ka)\s+(hua|zali)'),

      // SLA & Timelines
      RegExp(r'how\s+long\s+does\s+it\s+take'),
      RegExp(r'how\s+long\s+will\s+it\s+take'),
      RegExp(r'turnaround\s+time'),
      RegExp(r'when\s+does\s+the\s+sla'),
      RegExp(r'countdown\s+clock'),
      RegExp(r'does\s+an?\s+on-ground\s+obstacle\s+pause'),
      RegExp(r'\bsla\b'),
      RegExp(r'does\s+sla\s+reset'),
      RegExp(r'(कितना\s+समय\s+लगेगा|समय\s+सीमा|sla\s+रीसेट)'),
      RegExp(r'(किती\s+वेळ\s+लागेल|सेवा\s+मुदत|sla\s+रिसेट)'),
      RegExp(r'(kitna\s+time\s+lagega|kitna\s+time|solve\s+hone\s+me)'),

      // Fallback & AI Verification
      RegExp(r'what\s+happens\s+if\s+ai\s+verification\s+is\s+unavailable'),
      RegExp(r'ai\s+verification\s+(fails?|unavailable|error)'),
    ];
    return processPatterns.any((regex) => regex.hasMatch(text));
  }

  static bool _matchesCivicFixNavigation(String text) {
    final navPatterns = [
      // English
      RegExp(r'where\s+(can\s+i\s+)?(see|view|find)\s+(my\s+)?complaints'),
      RegExp(r'how\s+(do\s+i|can\s+i)\s+track(\s+my)?\s+complaint'),
      RegExp(r'^(where\s+to\s+track|track\s+(my\s+)?complaint)$'),
      RegExp(r'where\s+is\s+the\s+(hazard\s+)?map'),
      RegExp(r'how\s+does\s+the.*map\s+work'),
      RegExp(r'how\s+does\s+this\s+screen\s+work'),
      RegExp(r'map\s+screen'),
      RegExp(r'features\s+.*map'),
      RegExp(r'color\s+pins'),
      RegExp(r'pin\s+colors'),
      RegExp(r'pins\s+on\s+the\s+map'),
      RegExp(r'merge\s+into\s+numbers'),
      RegExp(r'zooming\s+out'),
      RegExp(r'clustering'),
      RegExp(r'map\s+cluster'),
      RegExp(r'hazard\s+map'),
      RegExp(r'see\s+hazards'),
      RegExp(r'nearby\s+(civic\s+)?issues'),
      RegExp(r'pins\s+mean\s+on\s+the\s+map'),
      RegExp(r'where\s+(can\s+i\s+find|are)\s+(my\s+)?(rewards|points|badges)'),

      // Hindi
      RegExp(r'(मेरी\s+शिकायत\s+कहाँ\s+देखें|शिकायत\s+ट्रैक\s+कैसे\s+करें|शिकायत\s+ट्रैक\s+करें|स्थिति\s+कैसे\s+देखें|शिकायत\s+की\s+स्थिति\s+कैसे\s+देखें)'),
      RegExp(r'(मैप\s+कहाँ\s+है|नक्शा\s+कैसे\s+काम\s+करता\s+है|मैप\s+कैसे\s+इस्तेमाल|हैज़र्ड\s+मैप)'),
      RegExp(r'(रिवॉर्ड्स\s+कहाँ|पॉइंट्स\s+कहाँ)'),

      // Marathi
      RegExp(r'(माझी\s+तक्रार\s+कुठे\s+पाहू|तक्रार\s+कशी\s+ट्रॅक\s+करायची|तक्रार\s+ट्रॅक\s+करा|तक्रार\s+कुठे\s+ट्रॅक)'),
      RegExp(r'(नकाशा\s+कुठे\s+आहे|धोका\s+नकाशा|नकाशा\s+कसा\s+चालतो)'),
      RegExp(r'(गुण\s+कुठे\s+पाहू|बक्षिसे\s+कुठे\s+आहेत)'),

      // Romanized
      RegExp(r'map\s+pe\s+(complaint|status)'),
      RegExp(r'complaint\s+track\s+kashi\s+karaychi'),
      RegExp(r'track\s+kashi\s+karaychi'),
    ];
    return navPatterns.any((regex) => regex.hasMatch(text));
  }

  static bool _matchesOutOfScopeGeneral(String text) {
    final outOfScopePatterns = [
      // English
      RegExp(r'tell\s+me\s+a\s+(funny\s+)?joke'),
      RegExp(r'make\s+me\s+laugh'),
      RegExp(r'photosynthesis'),
      RegExp(r'what(\s+is|\x27s)\s+the\s+capital\s+of'),
      RegExp(r'weather\s+in'),
      RegExp(r'write\s+a\s+(poem|story|song)'),
      RegExp(r'who\s+won\s+the\s+world\s+cup'),
      RegExp(r'calculate\s+\d+'),

      // Hindi
      RegExp(r'(चुटकुला|चुटकला|मुझे\s+हंसाओ|प्रकाश\s+संश्लेषण|राजधानी\s+क्या\s+है|कविता\s+लिखो)'),

      // Marathi
      RegExp(r'(विनोद\s+सांगा|मला\s+हसवा|प्रकाशसंश्लेषण|राजधानी\s+काय\s+आहे|कविता\s+लिहा)'),
    ];
    return outOfScopePatterns.any((regex) => regex.hasMatch(text));
  }

  // --- Context-Aware Follow-Up Helpers ---

  static bool _isContextualFollowUp(String text) {
    final followUpPhrases = [
      // English
      RegExp(r'^(what\s+happens\s+next|what\s+next|then\s+what|what\s+after\s+that|and\s+then)[\s!.,?]*$'),
      RegExp(r'^(who\s+does\s+that|who\s+will\s+do\s+it)[\s!.,?]*$'),
      RegExp(r'^(how\s+long\s+does\s+it\s+take)[\s!.,?]*$'),

      // Hindi
      RegExp(r'^(अब\s+आगे\s+क्या\s+होगा|आगे\s+क्या|फिर\s+क्या|उसके\s+बाद\s+क्या|यह\s+कौन\s+करेगा)[\s!.,?]*$'),

      // Marathi
      RegExp(r'^(आता\s+पुढे\s+काय\s+होईल|पुढे\s+काय|त्यानंतर\s+काय|नंतर\s+काय|हे\s+कोण\s+करेल)[\s!.,?]*$'),

      // Romanized
      RegExp(r'^(aage\s+kya\s+hoga|pudhe\s+kay\s+hoil|phir\s+kya|nanter\s+kay)[\s!.,?]*$'),
    ];
    return followUpPhrases.any((regex) => regex.hasMatch(text));
  }

  static AssistantIntentResult? _resolveContextualFollowUp(
    String text,
    AssistantConversationHistory history,
  ) {
    final lastUser = (history.lastUserQuery ?? '').toLowerCase();
    final lastAssistant = (history.lastAssistantReply ?? '').toLowerCase();

    if (lastUser.contains('verification') ||
        lastUser.contains('under verification') ||
        lastUser.contains('पडताळणी') ||
        lastUser.contains('सत्यापन') ||
        lastAssistant.contains('verification') ||
        lastAssistant.contains('पडताळणी') ||
        lastAssistant.contains('सत्यापन') ||
        lastAssistant.contains('stage 2')) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.civicfixProcess,
        matchedRule: 'contextual_follow_up_post_verification',
        slots: {'context': 'under_verification_next_step'},
      );
    }

    if (lastUser.contains('reported') ||
        lastUser.contains('नोंद') ||
        lastUser.contains('दर्ज') ||
        lastAssistant.contains('stage 1')) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.civicfixProcess,
        matchedRule: 'contextual_follow_up_post_reported',
        slots: {'context': 'reported_next_step'},
      );
    }

    if (lastUser.contains('assigned') ||
        lastUser.contains('नियुक्त') ||
        lastUser.contains('असाइन') ||
        lastAssistant.contains('stage 3')) {
      return const AssistantIntentResult(
        intent: CivicAssistantIntent.civicfixProcess,
        matchedRule: 'contextual_follow_up_post_assigned',
        slots: {'context': 'assigned_next_step'},
      );
    }

    return null;
  }
}
