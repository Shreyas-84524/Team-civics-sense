import '../../core/models/assistant_message_model.dart';

/// Predefined intent and response structure for the Civic Assistant.
class CivicIntentResponse {
  final String englishResponse;
  final String hindiResponse;
  final String marathiResponse;
  final List<String> keywords;
  final List<String> suggestions;

  const CivicIntentResponse({
    required this.englishResponse,
    required this.hindiResponse,
    required this.marathiResponse,
    required this.keywords,
    this.suggestions = const [],
  });

  String getResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return hindiResponse;
      case 'mr':
        return marathiResponse;
      case 'en':
      default:
        return englishResponse;
    }
  }
}

/// Service providing local FAQ and intent matching for Civic Assistant.
class CivicAssistantService {
  static final CivicAssistantService _instance = CivicAssistantService._internal();
  factory CivicAssistantService() => _instance;
  CivicAssistantService._internal();

  /// Quick suggested questions when the chat is started.
  static List<String> getSuggestedPrompts(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return const [
          'समस्या कैसे दर्ज करें?',
          'शिकायत कैसे ट्रैक करें?',
          'सत्यापित (Verified) का क्या अर्थ है?',
          'कौन सी श्रेणी चुनें?',
        ];
      case 'mr':
        return const [
          'तक्रार कशी नोंदवायची?',
          'तक्रार कशी ट्रॅक करावी?',
          'सत्यापित (Verified) म्हणजे काय?',
          'कोणता प्रवर्ग निवडावा?',
        ];
      case 'en':
      default:
        return const [
          'How do I report an issue?',
          'How can I track my complaint?',
          'What does Verified mean?',
          'Which category should I choose?',
        ];
    }
  }

  /// 12+ Canonical Civic Knowledge Intents
  static final List<CivicIntentResponse> _intents = [
    // 1. Report Issue
    CivicIntentResponse(
      keywords: [
        'report an issue',
        'report issue',
        'how do i report',
        'how to report',
        'report',
        'lodge',
        'submit',
        'file',
        'register',
        'दर्ज',
        'नोंदवा',
        'नोंद',
      ],
      englishResponse:
          "To report a civic issue: Tap 'Report an Issue' on the Home screen. Fill in the title, select a category, attach photos in Evidence (optional, up to 3), confirm your location on the map, then review and submit.",
      hindiResponse:
          "नागरिक समस्या दर्ज करने के लिए: होम स्क्रीन पर 'समस्या दर्ज करें' पर टैप करें। विवरण भरें, श्रेणी चुनें, फ़ोटो संलग्न करें (वैकल्पिक), मानचित्र पर स्थान की पुष्टि करें और सबमिट करें।",
      marathiResponse:
          "नागरी समस्या नोंदवण्यासाठी: मुख्य स्क्रीनवर 'तक्रार नोंदवा' वर टॅप करा. तपशील भरा, प्रवर्ग निवडा, फोटो जोडा (पर्यायी), नकाशावर जागेची खात्री करा आणि तक्रार सादर करा.",
      suggestions: ['How do I add a photo?', 'How do I select a location?'],
    ),

    // 2. Track Complaint
    CivicIntentResponse(
      keywords: [
        'track my complaint',
        'track complaint',
        'how to track',
        'how can i track',
        'check status',
        'track',
        'ट्रैक',
        'ट्रॅक',
        'स्थिती',
      ],
      englishResponse:
          "To track your complaint: Open 'My Complaints' from the bottom navigation or Home screen. Tap any complaint to view its live 5-stage progress tracker from Reported to Resolved.",
      hindiResponse:
          "अपनी शिकायत ट्रैक करने के लिए: नीचे नेविगेशन से 'मेरी शिकायतें' खोलें। रिपोर्ट से समाधान तक 5-चरणीय ट्रैकर देखने के लिए किसी भी शिकायत पर टैप करें।",
      marathiResponse:
          "आपली तक्रार ट्रॅक करण्यासाठी: खालील नेव्हिगेशनमधून 'माझ्या तक्रारी' उघडा. नोंदणीपासून निवारणापर्यंत ५-टप्प्यांचा ट्रॅकर पाहण्यासाठी कोणत्याही तक्रारीवर टॅप करा.",
      suggestions: ['What does Verified mean?', 'What does In Progress mean?'],
    ),

    // 3. Status: Reported
    CivicIntentResponse(
      keywords: ['reported mean', 'what does reported', 'stage 1', 'status reported', 'रिपोर्टेड'],
      englishResponse:
          "'Reported' is Stage 1: Your complaint has been submitted successfully with a unique ticket number (e.g. CF-2026-000024) and is queued for municipal review.",
      hindiResponse:
          "'Reported' चरण 1 है: आपकी शिकायत एक अद्वितीय टिकट नंबर के साथ सफलतापूर्वक दर्ज हो गई है और नगरपालिका समीक्षा के लिए कतारबद्ध है।",
      marathiResponse:
          "'Reported' हा टप्पा १ आहे: तुमची तक्रार विशिष्ट तिकीट क्रमांकासह यशस्वीपणे नोंदवली गेली आहे आणि पालिका पुनरावलोकनासाठी रांगेत आहे.",
      suggestions: ['What does Verified mean?'],
    ),

    // 4. Status: Verified
    CivicIntentResponse(
      keywords: ['verified mean', 'what does verified', 'stage 2', 'status verified', 'सत्यापित'],
      englishResponse:
          "'Verified' is Stage 2: The ward municipal engineer has reviewed and confirmed the civic issue and determined its severity and department routing.",
      hindiResponse:
          "'Verified' चरण 2 है: वार्ड इंजीनियर ने समस्या की समीक्षा करके पुष्टि की है और संबंधित विभाग को निर्देशित किया है।",
      marathiResponse:
          "'Verified' हा टप्पा २ आहे: प्रभाग अभियंत्याने समस्येची पाहणी करून खात्री केली आहे आणि संबंधित विभागाकडे पाठवले आहे.",
      suggestions: ['What does Assigned mean?'],
    ),

    // 5. Status: Assigned
    CivicIntentResponse(
      keywords: ['assigned mean', 'what does assigned', 'stage 3', 'status assigned', 'आवंटित', 'नियुक्त'],
      englishResponse:
          "'Assigned' is Stage 3: The issue has been allocated to a specific field maintenance squad or contractor team with work instructions.",
      hindiResponse:
          "'Assigned' चरण 3 है: समस्या को कार्य निर्देशों के साथ एक विशिष्ट फील्ड रखरखाव टीम को सौंप दिया गया है।",
      marathiResponse:
          "'Assigned' हा टप्पा ३ आहे: ही समस्या कामाच्या सूचनांसह विशिष्ट प्रत्यक्ष दुरुस्ती पथकाकडे सोपवली गेली आहे.",
      suggestions: ['What does In Progress mean?'],
    ),

    // 6. Status: In Progress
    CivicIntentResponse(
      keywords: [
        'in progress mean',
        'what does in progress',
        'status in progress',
        'in progress',
        'underway',
        'stage 4',
        'प्रगति',
        'काम चालू',
      ],
      englishResponse:
          "'In Progress' is Stage 4: Repair or remediation work is actively being executed on site by the assigned municipal maintenance unit.",
      hindiResponse:
          "'In Progress' चरण 4 है: संबंधित विभाग द्वारा घटनास्थल पर सक्रिय रूप से मरम्मत कार्य किया जा रहा है।",
      marathiResponse:
          "'In Progress' हा टप्पा ४ आहे: नियुक्त पथकाद्वारे प्रत्यक्ष जागेवर दुरुस्तीचे काम वेगाने चालू आहे.",
      suggestions: ['What does Resolved mean?'],
    ),

    // 7. Status: Resolved
    CivicIntentResponse(
      keywords: [
        'resolved mean',
        'what does resolved',
        'status resolved',
        'completed',
        'stage 5',
        'समाधान',
        'निवारण',
      ],
      englishResponse:
          "'Resolved' is Stage 5: The civic issue has been successfully fixed and verified. You will see a resolution confirmation and timestamps in complaint details.",
      hindiResponse:
          "'Resolved' चरण 5 है: समस्या का समाधान हो चुका है। आप शिकायत विवरण में पूर्णता की पुष्टि और समय देख सकते हैं।",
      marathiResponse:
          "'Resolved' हा टप्पा ५ आहे: नागरी समस्येचे यशस्वी निवारण झाले आहे. आपण तक्रार तपशीलात निवारणाची खात्री पाहू शकता.",
      suggestions: ['How can I track my complaint?'],
    ),

    // 8. Categories
    CivicIntentResponse(
      keywords: [
        'category',
        'categories',
        'which category',
        'pothole category',
        'water category',
        'श्रेणी',
        'प्रवर्ग',
      ],
      englishResponse:
          "CivicFix has 9 categories: Roads (potholes, cracks), Water Supply (leaks, low pressure), Sanitation & Waste (overflowing bins), Street Lighting, Drainage & Flooding, Public Infrastructure, Traffic & Safety, and General Municipal desk.",
      hindiResponse:
          "CivicFix में 9 श्रेणियां हैं: सड़कें (गड्ढे), जल आपूर्ति (रिसाव), स्वच्छता और कचरा, स्ट्रीट लाइट, जल निकासी, सार्वजनिक बुनियादी ढांचा, और यातायात सुरक्षा।",
      marathiResponse:
          "CivicFix मध्ये ९ प्रवर्ग आहेत: रस्ते (खड्डे), पाणी पुरवठा (गळती), स्वच्छता व कचरा, पथदिवे, सांडपाणी निचरा, सार्वजनिक पायाभूत सुविधा आणि वाहतूक सुरक्षा.",
      suggestions: ['How do I report an issue?'],
    ),

    // 9. Add Photo / Evidence
    CivicIntentResponse(
      keywords: [
        'photo evidence',
        'add a photo',
        'photo',
        'picture',
        'evidence',
        'image',
        'camera',
        'gallery',
        'फ़ोटो',
        'फोटो',
        'पुरावा',
      ],
      englishResponse:
          "In Step 2 (Evidence) of reporting, tap 'Camera' to take a fresh photo or 'Gallery' to pick existing photos. You can upload up to 3 photos. Evidence is optional but helps authorities respond faster.",
      hindiResponse:
          "रिपोर्ट के चरण 2 (सबूत) में, फ़ोटो खींचने के लिए 'कैमरा' या मौजूदा फ़ोटो चुनने के लिए 'गैलरी' पर टैप करें। आप अधिकतम 3 फ़ोटो जोड़ सकते हैं।",
      marathiResponse:
          "तक्रार नोंदवताना टप्पा २ मध्ये, फोटो काढण्यासाठी 'कॅमेरा' किंवा गॅलरीतून फोटो निवडण्यासाठी 'गॅलरी' टॅप करा. आपण जास्तीत जास्त ३ फोटो जोडू शकता.",
      suggestions: ['How do I select a location?'],
    ),

    // 10. Select Location
    CivicIntentResponse(
      keywords: [
        'location on map',
        'select a location',
        'location',
        'gps',
        'pin',
        'address',
        'स्थान',
        'पत्ता',
      ],
      englishResponse:
          "In Step 3 (Location), tap 'Use My Location' for automatic GPS detection, or tap 'Select on Map' to search a landmark and place a pin manually.",
      hindiResponse:
          "चरण 3 (स्थान) में, स्वचालित जीपीएस के लिए 'मेरा स्थान उपयोग करें' पर टैप करें, या पिन सेट करने के लिए 'मानचित्र पर चुनें' पर टैप करें।",
      marathiResponse:
          "टप्पा ३ (जागा) मध्ये, आपोआप जीपीएस शोधण्यासाठी 'माझे स्थान वापरा' टॅप करा, किंवा नकाशावर पिन लावण्यासाठी 'नकाशावर निवडा' टॅप करा.",
      suggestions: ['How do I report an issue?'],
    ),

    // 11. View My Complaints
    CivicIntentResponse(
      keywords: [
        'complaints history',
        'see my complaints',
        'view complaints',
        'my history',
        'शिकायतें देखें',
        'माझ्या तक्रारी कुठे',
      ],
      englishResponse:
          "Tap 'Complaints' on the bottom navigation bar to see all complaints you've reported. You can search by ticket number or filter by status.",
      hindiResponse:
          "अपनी दर्ज की गई शिकायतें देखने के लिए नीचे नेविगेशन बार पर 'शिकायतें' पर टैप करें।",
      marathiResponse:
          "आपल्या सर्व तक्रारी पाहण्यासाठी खालील नेव्हिगेशन बारवर 'तक्रारी' वर टॅप करा.",
      suggestions: ['How can I track my complaint?'],
    ),

    // 12. Hazard Map / Nearby
    CivicIntentResponse(
      keywords: [
        'hazard issues',
        'nearby hazard',
        'hazard map',
        'see hazards',
        'nearby',
        'map issues',
        'आसपास',
        'जवळपास',
      ],
      englishResponse:
          "Tap 'Map' on the bottom navigation bar to open the interactive Hazard Map. You can view all nearby road hazards, open drains, and broken lights plotted with color-coded markers.",
      hindiResponse:
          "इंटरैक्टिव हैजर्ड मैप देखने के लिए नीचे नेविगेशन बार पर 'मैप' पर टैप करें। आप आसपास की सभी समस्याएं देख सकते हैं।",
      marathiResponse:
          "परिसरातील सर्व नागरी समस्या व धोके पाहण्यासाठी खालील नेव्हिगेशन बारवर 'नकाशा' वर टॅप करा.",
      suggestions: ['How do I report an issue?'],
    ),
  ];

  /// Process user query with keyword matching and return assistant response.
  Future<AssistantMessage> processQuery({
    required String query,
    required String languageCode,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: _getFallbackText(languageCode),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: getSuggestedPrompts(languageCode),
      );
    }

    // Match against predefined intents using longest matching keyword
    CivicIntentResponse? bestIntent;
    int maxMatchLength = 0;

    for (final intent in _intents) {
      for (final keyword in intent.keywords) {
        final kw = keyword.toLowerCase();
        if (clean.contains(kw) && kw.length > maxMatchLength) {
          maxMatchLength = kw.length;
          bestIntent = intent;
        }
      }
    }

    if (bestIntent != null) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: bestIntent.getResponse(languageCode),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: bestIntent.suggestions,
      );
    }

    // Unknown question fallback
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: _getFallbackText(languageCode),
      sender: AssistantMessageSender.assistant,
      timestamp: DateTime.now(),
      followUpSuggestions: getSuggestedPrompts(languageCode),
    );
  }

  String _getFallbackText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return "मुझे इसके बारे में सटीक जानकारी नहीं है। कृपया समस्या दर्ज करने, स्थिति ट्रैक करने, स्थान चुनने या श्रेणियों के बारे में पूछें।";
      case 'mr':
        return "मला याबद्दल अचूक माहिती नाही. कृपया तक्रार नोंदवणे, स्थिती तपासणे, जागा निवडणे किंवा प्रवर्गांविषयी विचारा.";
      case 'en':
      default:
        return "I'm still learning how to help with that. Try asking about reporting an issue, tracking a complaint, locations, categories, or complaint statuses.";
    }
  }
}
