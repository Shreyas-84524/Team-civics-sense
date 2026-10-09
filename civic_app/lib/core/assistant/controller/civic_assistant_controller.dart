import 'package:flutter/foundation.dart';
import '../../models/assistant_message_model.dart';
import '../../models/complaint_model.dart';
import '../adapters/complaint_context_mapper.dart';
import '../config/civic_assistant_config.dart';
import '../models/assistant_app_context.dart';
import '../models/assistant_conversation_history.dart';
import '../models/assistant_language.dart';
import '../observability/assistant_analytics.dart';
import '../observability/assistant_error_type.dart';
import '../services/assistant_language_resolver.dart';
import '../services/civic_assistant_feedback_service.dart';
import '../services/civic_assistant_provider.dart';
import '../services/civic_assistant_tts_service.dart';

/// State and conversation coordinator for the CivicFix Assistant UI.
class CivicAssistantController extends ChangeNotifier {
  final CivicAssistantProvider _provider;
  final AssistantConversationHistory _history;

  bool _isProcessing = false;
  String _activeLanguage = 'en';
  AssistantAppContext _appContext;
  String? _lastUserQuery;
  final String _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

  CivicAssistantController({
    CivicAssistantProvider? provider,
    AssistantConversationHistory? history,
    AssistantAppContext? initialContext,
  })  : _provider = provider ?? CompositeCivicAssistantProvider(),
        _history = history ??
            AssistantConversationHistory(
              maxWindowSize: CivicAssistantConfig.current.maxHistoryLength,
            ),
        _appContext = initialContext ?? const AssistantAppContext();

  bool get isProcessing => _isProcessing;
  String get activeLanguage => _activeLanguage;
  AssistantLanguage get resolvedLanguage => AssistantLanguage.fromCode(_activeLanguage);
  AssistantAppContext get appContext => _appContext;
  List<AssistantMessage> get messages => _history.messages;
  bool get canRetry => _lastUserQuery != null && !_isProcessing;
  bool get hasComplaintContext => _appContext.hasComplaintContext;
  String get sessionId => _sessionId;
  CivicAssistantTtsService get ttsService => CivicAssistantTtsService.instance;
  bool get isSpeaking => ttsService.isSpeaking;
  String? get currentSpeakingMessageId => ttsService.currentSpeakingMessageId;
  String? get activeSpeakingMessageId => ttsService.activeSpeakingMessageId;

  /// Speaks the provided assistant message using the centralized TTS service.
  Future<bool> speakMessage(AssistantMessage message, {String? languageCode}) {
    return ttsService.speakMessage(
      message,
      languageCode: languageCode ?? _activeLanguage,
    );
  }

  /// Toggles speech for an assistant message (start if idle, stop if currently speaking).
  Future<bool> toggleSpeakMessage(AssistantMessage message, {String? languageCode}) {
    return ttsService.toggleSpeakMessage(
      message,
      languageCode: languageCode ?? _activeLanguage,
    );
  }

  /// Stops any in-flight assistant speech.
  Future<void> stopSpeech() => ttsService.stop();

  void updateLanguage(String languageCode) {
    if (_activeLanguage != languageCode) {
      stopSpeech();
      _activeLanguage = languageCode;
      _appContext = _appContext.copyWith(selectedLanguage: languageCode);
      notifyListeners();
    }
  }

  void updateAppContext(AssistantAppContext context) {
    _appContext = context;
    notifyListeners();
  }

  /// Updates context with a live [ComplaintModel] instance.
  void updateComplaintContext(
    ComplaintModel? complaint, {
    String currentScreen = 'complaintDetails',
  }) {
    if (complaint == null) {
      clearComplaintContext(currentScreen: currentScreen);
      return;
    }
    _appContext = ComplaintToAssistantContextMapper.mapFromComplaint(
      complaint,
      currentScreen: currentScreen,
      selectedLanguage: _activeLanguage,
      userRole: _appContext.userRole,
    );
    notifyListeners();
  }

  /// Clears active complaint context when user navigates away.
  void clearComplaintContext({String currentScreen = 'home'}) {
    _appContext = AssistantAppContext(
      userRole: _appContext.userRole,
      currentScreen: currentScreen,
      selectedLanguage: _activeLanguage,
      isGovernmentUser: _appContext.isGovernmentUser,
    );
    notifyListeners();
  }

  /// Initializes the chat session with a localized welcome message if empty.
  void initSession({String? languageCode, AssistantAppContext? context}) {
    if (languageCode != null && languageCode.isNotEmpty) {
      _activeLanguage = languageCode;
    }
    if (context != null) {
      _appContext = context;
      if (context.selectedLanguage.isNotEmpty) {
        _activeLanguage = context.selectedLanguage;
      }
    }

    if (_history.isEmpty) {
      final welcome = AssistantMessage(
        id: 'init_welcome_${DateTime.now().millisecondsSinceEpoch}',
        text: getWelcomeGreeting(_activeLanguage, context: _appContext),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions: getSuggestedPrompts(_activeLanguage, context: _appContext),
      );
      _history.addMessage(welcome);

      CivicAssistantAnalytics.instance.logSessionStarted(
        sessionId: _sessionId,
        languageCode: _activeLanguage,
        currentScreen: _appContext.currentScreen ?? 'home',
        hasComplaintContext: _appContext.hasComplaintContext,
      );

      notifyListeners();
    }
  }

  /// Sends a user query and asynchronously resolves the assistant's reply.
  Future<AssistantMessage> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isProcessing) {
      throw StateError('Cannot send empty message or while processing');
    }

    // Stop active speech before processing new user turn
    stopSpeech();

    // 1. Resolve active conversational language
    final resolvedLang = AssistantLanguageResolver.resolve(
      query: query,
      appContext: _appContext,
      history: _history,
    );
    _activeLanguage = resolvedLang.code;
    _appContext = _appContext.copyWith(selectedLanguage: _activeLanguage);

    _lastUserQuery = query;
    _isProcessing = true;

    final userMsg = AssistantMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      sender: AssistantMessageSender.user,
      timestamp: DateTime.now(),
    );

    _history.addMessage(userMsg);

    CivicAssistantAnalytics.instance.logQuerySubmitted(
      sessionId: _sessionId,
      queryLength: query.length,
      languageCode: _activeLanguage,
      currentScreen: _appContext.currentScreen ?? 'home',
      hasComplaintContext: _appContext.hasComplaintContext,
    );

    notifyListeners();

    try {
      var reply = await _provider.generateResponse(
        query: query,
        languageCode: _activeLanguage,
        history: _history,
        appContext: _appContext,
        ragContext: null, // Full hybrid RAG pipeline with multilingual bridge
      );

      reply = reply.copyWith(
        metadata: {
          ...?reply.metadata,
          'userMessageId': userMsg.id,
          'userMessage': userMsg.text,
        },
      );

      _history.addMessage(reply);
      _isProcessing = false;
      notifyListeners();
      return reply;
    } catch (e) {
      final errorType = AssistantErrorType.unknownFailure;
      final errorReply = AssistantMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: errorType.userFriendlyMessage(_activeLanguage),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        isError: true,
        followUpSuggestions: getSuggestedPrompts(_activeLanguage, context: _appContext),
        metadata: {
          'userMessageId': userMsg.id,
          'userMessage': userMsg.text,
        },
      );

      _history.addMessage(errorReply);
      _isProcessing = false;
      notifyListeners();
      return errorReply;
    }
  }

  /// Retries the most recent user query if an error occurred.
  Future<AssistantMessage?> retryLastMessage() async {
    if (_lastUserQuery == null || _isProcessing) return null;
    final query = _lastUserQuery!;
    return await sendMessage(query);
  }

  /// Submits or toggles quality feedback (thumbs up / down) for a specific assistant message.
  ///
  /// Features:
  /// - Optimistic UI state updates with automatic rollback on Firestore error
  /// - Vote switching (upvote -> downvote or vice versa)
  /// - Active vote deselect (removes document from Firestore on re-tap)
  /// - Precise linkage of triggering user message and assistant reply
  /// - Request serialization per message ID
  /// - 100% independent from TTS audio and Copy actions
  Future<bool> submitFeedback(
    String messageId,
    AssistantFeedbackRating rating, {
    String? ownerUid,
  }) async {
    if (!CivicAssistantConfig.current.feedbackEnabled) return false;

    final index = _history.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;

    final msg = _history.messages[index];
    final oldRating = msg.feedbackRating;
    final isDeselect = oldRating == rating;
    final isUpdate = oldRating != null && !isDeselect;
    final newRating = isDeselect ? null : rating;

    // 1. Optimistic UI update
    final updatedMsg = msg.copyWith(
      feedbackRating: newRating,
      clearFeedbackRating: isDeselect,
    );
    _history.updateMessage(messageId, updatedMsg);
    notifyListeners();

    // 2. Resolve triggering user message
    AssistantMessage? triggeringUserMsg;
    final linkedUserId = msg.metadata?['userMessageId'] as String?;
    if (linkedUserId != null) {
      final uIdx = _history.messages.indexWhere((m) => m.id == linkedUserId);
      if (uIdx != -1) triggeringUserMsg = _history.messages[uIdx];
    }
    if (triggeringUserMsg == null && index > 0) {
      for (int i = index - 1; i >= 0; i--) {
        if (_history.messages[i].isUser) {
          triggeringUserMsg = _history.messages[i];
          break;
        }
      }
    }

    // 3. Persist feedback via centralized service
    bool success = false;
    if (isDeselect) {
      success = await CivicAssistantFeedbackService.instance.removeFeedback(
        sessionId: _sessionId,
        assistantMessageId: messageId,
        ownerUid: ownerUid,
      );
    } else {
      success = await CivicAssistantFeedbackService.instance.submitFeedback(
        sessionId: _sessionId,
        assistantMessage: msg,
        userMessage: triggeringUserMsg,
        rating: rating,
        appContext: _appContext,
        ownerUid: ownerUid,
        isUpdate: isUpdate,
      );
    }

    if (!success) {
      // Rollback optimistic state on persistence failure
      final rolledBack = msg.copyWith(
        feedbackRating: oldRating,
        clearFeedbackRating: oldRating == null,
      );
      _history.updateMessage(messageId, rolledBack);
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Resets the conversation session and restores the localized welcome greeting.
  void clearChat() {
    stopSpeech();
    _history.clear();
    _lastUserQuery = null;
    _isProcessing = false;
    CivicAssistantAnalytics.instance.logChatCleared(sessionId: _sessionId);
    initSession();
  }

  @override
  void dispose() {
    stopSpeech();
    super.dispose();
  }

  /// Initial welcome greeting tailored to the requested locale and active context.
  static String getWelcomeGreeting(String languageCode, {AssistantAppContext? context}) {
    final lang = languageCode.trim().toLowerCase();
    final screen = context?.currentScreen?.toLowerCase();
    final hasComplaint = context?.hasComplaintContext ?? false;
    final ticket = context?.selectedTicketNumber ?? context?.selectedComplaintId;

    if (screen == 'complaintdetails' || hasComplaint) {
      if (ticket != null && ticket.isNotEmpty) {
        switch (lang) {
          case 'hi':
            return 'नमस्ते! मैं देख रहा हूँ कि आप शिकायत $ticket देख रहे हैं। मैं इस स्थिति या अगली प्रक्रिया में आपकी क्या मदद कर सकता हूँ?';
          case 'mr':
            return 'नमस्कार! मी पाहत आहे की आपण तक्रार $ticket पाहत आहात. या स्थितीविषयी किंवा पुढील प्रक्रियेविषयी मी काय मदत करू शकतो?';
          case 'en':
          default:
            return "Hello! I see you're viewing complaint $ticket. How can I help you with its status or next steps?";
        }
      }
    } else if (screen == 'reportissue' || screen == 'report_issue') {
      switch (lang) {
        case 'hi':
          return 'नमस्ते! मैं आपकी नागरिक समस्या दर्ज करने, सही श्रेणी चुनने और स्पष्ट फोटो प्रमाण जोड़ने में मदद कर सकता हूँ।';
        case 'mr':
          return 'नमस्कार! मी आपली नागरी तक्रार नोंदवण्यात, योग्य श्रेणी निवडण्यात आणि स्पष्ट पुरावा जोडण्यात मदत करू शकतो.';
        case 'en':
        default:
          return 'Hello! I can guide you through reporting your civic issue, choosing the right category, and uploading clear evidence.';
      }
    } else if (screen == 'map' || screen == 'explore') {
      switch (lang) {
        case 'hi':
          return 'नमस्ते! नक्शे पर नागरिक शिकायतें देख रहे हैं? आप मार्कर, क्लस्टर या प्रभाग सीमाओं के बारे में पूछ सकते हैं।';
        case 'mr':
          return 'नमस्कार! नकाशावर तक्रारी पाहत आहात? तुम्ही चिन्हे, क्लस्टर किंवा प्रभाग सीमांविषयी विचारू शकता.';
        case 'en':
        default:
          return 'Hello! Exploring civic issues on the map? Ask me about map markers, cluster groups, or ward boundaries.';
      }
    }

    switch (lang) {
      case 'hi':
        return 'नमस्ते! मैं आपका CivicFix सहायक हूँ। मैं आपको नागरिक शिकायत दर्ज करने, श्रेणियों को समझने, या स्थिति ट्रैक करने में मदद कर सकता हूँ।';
      case 'mr':
        return 'नमस्कार! मी तुमचा CivicFix सहाय्यक आहे. मी तक्रार नोंदवणे, प्रभाग माहिती, किंवा स्थिती ट्रॅक करण्यात मदत करू शकतो.';
      case 'en':
      default:
        return 'Hello! I am your CivicFix Assistant. How can I help you today?';
    }
  }

  /// Context-aware starter suggestion prompts.
  static List<String> getSuggestedPrompts(String languageCode, {AssistantAppContext? context}) {
    final lang = languageCode.trim().toLowerCase();
    final screen = context?.currentScreen?.toLowerCase();
    final hasComplaint = context?.hasComplaintContext ?? false;

    if (screen == 'complaintdetails' || hasComplaint) {
      switch (lang) {
        case 'hi':
          return const [
            'आगे क्या प्रक्रिया होगी?',
            'इसकी देखरेख कौन कर रहा है?',
            'इस स्थिति का क्या अर्थ है?',
            'SLA समयसीमा कैसे काम करती है?',
          ];
        case 'mr':
          return const [
            'आता पुढे काय होईल?',
            'हे कोणाकडे सोपवले आहे?',
            'या स्थितीचा अर्थ काय आहे?',
            'SLA कालावधी कसा ठरतो?',
          ];
        case 'en':
        default:
          return const [
            'What happens next?',
            'Who is handling this?',
            'What does this status mean?',
            'How do SLA timelines work?',
          ];
      }
    } else if (screen == 'reportissue' || screen == 'report_issue') {
      switch (lang) {
        case 'hi':
          return const [
            'यहाँ क्या जानकारी दर्ज करनी है?',
            'क्या फोटो/प्रमाण अपलोड करना है?',
            'कौन सी श्रेणी चुनें?',
            'प्रभाग (Ward) कैसे चुना जाता है?',
          ];
        case 'mr':
          return const [
            'येथे काय माहिती भरायची?',
            'कोणता पुरावा अपलोड करावा?',
            'कोणती श्रेणी निवडावी?',
            'माझा प्रभाग कसा समजेल?',
          ];
        case 'en':
        default:
          return const [
            'What should I enter here?',
            'What evidence should I upload?',
            'Which category should I choose?',
            'How is my ward detected?',
          ];
      }
    } else if (screen == 'map' || screen == 'explore') {
      switch (lang) {
        case 'hi':
          return const [
            'नक्शे के मार्कर का क्या अर्थ है?',
            'क्लस्टर कैसे काम करते हैं?',
            'क्या प्रभाग अनुसार फ़िल्टर कर सकते हैं?',
            'आस-पास की शिकायतें कैसे दिखती हैं?',
          ];
        case 'mr':
          return const [
            'नकाशावरील चिन्हांचा अर्थ काय?',
            'क्लस्टर कसे काम करतात?',
            'प्रभागानुसार फिल्टर करता येते का?',
            'जवळपासच्या तक्रारी कशा दिसतात?',
          ];
        case 'en':
        default:
          return const [
            'What do these markers mean?',
            'How do clusters work?',
            'Can I filter by ward?',
            'How are nearby issues grouped?',
          ];
      }
    }

    switch (lang) {
      case 'hi':
        return const [
          'समस्या कैसे दर्ज करें?',
          'शिकायत कैसे ट्रैक करें?',
          'सत्यापित (Verified) का क्या अर्थ है?',
          'CivicFix क्या है?',
        ];
      case 'mr':
        return const [
          'तक्रार कशी नोंदवायची?',
          'तक्रार कशी ट्रॅक करावी?',
          'सत्यापित (Verified) म्हणजे काय?',
          'CivicFix काय आहे?',
        ];
      case 'en':
      default:
        return const [
          'What is CivicFix?',
          'How do I report an issue?',
          'What happens after I submit a complaint?',
          'How can I track my complaint?',
        ];
    }
  }
}
