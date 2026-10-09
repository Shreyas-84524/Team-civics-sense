import 'package:flutter/material.dart';
import '../../core/assistant/config/civic_assistant_config.dart';
import '../../core/assistant/models/assistant_app_context.dart';
import '../../core/assistant/models/assistant_conversation_history.dart';
import '../../core/assistant/observability/assistant_analytics.dart';
import '../../core/assistant/services/civic_assistant_feedback_service.dart';
import '../../core/assistant/services/civic_assistant_tts_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/models/assistant_message_model.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/assistant_service.dart';
import '../widgets/assistant/assistant_message_bubble.dart';

/// Screen for CivicFix Citizen Assistant providing natural conversational guidance.
class AssistantScreen extends StatefulWidget {
  final CivicAssistantService? assistantService;
  final UserRepository? userRepository;
  final AssistantAppContext? initialContext;

  const AssistantScreen({
    super.key,
    this.assistantService,
    this.userRepository,
    this.initialContext,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> with WidgetsBindingObserver {
  late final CivicAssistantService _assistantService;
  late final UserRepository _userRepository;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AssistantConversationHistory _history =
      AssistantConversationHistory(maxWindowSize: CivicAssistantConfig.current.maxHistoryLength);

  bool _isProcessing = false;
  String _userLanguage = 'en';
  String? _lastUserQuery;
  late AssistantAppContext _appContext;
  final String _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CivicAssistantTtsService.instance.addListener(_onTtsStateChanged);
    _assistantService = widget.assistantService ?? CivicAssistantService();
    _userRepository = widget.userRepository ?? RepositoryLocator.userRepository;
    _appContext = widget.initialContext ?? const AssistantAppContext();
    _initAssistant();
  }

  @override
  void didUpdateWidget(covariant AssistantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContext != oldWidget.initialContext && widget.initialContext != null) {
      setState(() {
        _appContext = widget.initialContext!;
      });
    }
  }

  String _getActiveLanguage() {
    try {
      if (mounted) {
        final loc = Localizations.maybeLocaleOf(context);
        if (loc != null &&
            (loc.languageCode == 'hi' ||
                loc.languageCode == 'mr' ||
                loc.languageCode == 'en')) {
          return loc.languageCode;
        }
      }
    } catch (_) {}
    try {
      return LocaleController.instance.currentLocale.languageCode;
    } catch (_) {
      return _userLanguage;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_history.isEmpty) {
      final activeLang = _getActiveLanguage();
      final welcome = AssistantMessage(
        id: 'init_1',
        text: CivicAssistantService.getWelcomeGreeting(activeLang, context: _appContext),
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        followUpSuggestions:
            CivicAssistantService.getSuggestedPrompts(activeLang, context: _appContext),
      );
      _history.addMessage(welcome);

      CivicAssistantAnalytics.instance.logSessionStarted(
        sessionId: _sessionId,
        languageCode: activeLang,
        currentScreen: _appContext.currentScreen ?? 'assistant',
        hasComplaintContext: _appContext.hasComplaintContext,
      );
    }
  }

  Future<void> _initAssistant() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (mounted) {
        setState(() {
          _userLanguage = user.languageCode;
          _appContext = _appContext.copyWith(
            userRole: user.role,
            selectedLanguage: user.languageCode,
            currentScreen: _appContext.currentScreen ?? 'assistant',
          );
          if (_history.isEmpty) {
            final activeLang = _getActiveLanguage();
            final welcome = AssistantMessage(
              id: 'init_1',
              text: CivicAssistantService.getWelcomeGreeting(activeLang, context: _appContext),
              sender: AssistantMessageSender.assistant,
              timestamp: DateTime.now(),
              followUpSuggestions:
                  CivicAssistantService.getSuggestedPrompts(activeLang, context: _appContext),
            );
            _history.addMessage(welcome);

            CivicAssistantAnalytics.instance.logSessionStarted(
              sessionId: _sessionId,
              languageCode: activeLang,
              currentScreen: _appContext.currentScreen ?? 'assistant',
              hasComplaintContext: _appContext.hasComplaintContext,
            );
          }
        });
      }
    } catch (_) {
      // Fallback gracefully to defaults
      if (mounted && _history.isEmpty) {
        final activeLang = _getActiveLanguage();
        final welcome = AssistantMessage(
          id: 'init_1',
          text: CivicAssistantService.getWelcomeGreeting(activeLang, context: _appContext),
          sender: AssistantMessageSender.assistant,
          timestamp: DateTime.now(),
          followUpSuggestions:
              CivicAssistantService.getSuggestedPrompts(activeLang, context: _appContext),
        );
        setState(() {
          _history.addMessage(welcome);
        });

        CivicAssistantAnalytics.instance.logSessionStarted(
          sessionId: _sessionId,
          languageCode: activeLang,
          currentScreen: _appContext.currentScreen ?? 'assistant',
          hasComplaintContext: _appContext.hasComplaintContext,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CivicAssistantTtsService.instance.removeListener(_onTtsStateChanged);
    CivicAssistantTtsService.instance.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      CivicAssistantTtsService.instance.stop();
    }
  }

  void _onTtsStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSpeak(AssistantMessage message) async {
    final activeLang = _getActiveLanguage();
    final success = await CivicAssistantTtsService.instance.toggleSpeakMessage(
      message,
      languageCode: activeLang,
    );
    if (!success &&
        CivicAssistantTtsService.instance.state == CivicAssistantTtsState.error &&
        mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            activeLang == 'hi'
                ? 'टेक्स्ट-टू-स्पीच अभी उपलब्ध नहीं है।'
                : activeLang == 'mr'
                    ? 'टेक्स्ट-टू-स्पीच सध्या उपलब्ध नाही.'
                    : 'Text-to-speech is unavailable right now.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isProcessing) return;

    // Stop in-flight speech before processing new user query
    CivicAssistantTtsService.instance.stop();

    _textController.clear();
    _lastUserQuery = query;
    final activeLang = _getActiveLanguage();

    final userMsg = AssistantMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      sender: AssistantMessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _history.addMessage(userMsg);
      _isProcessing = true;
    });
    _scrollToBottom();

    CivicAssistantAnalytics.instance.logQuerySubmitted(
      sessionId: _sessionId,
      queryLength: query.length,
      languageCode: activeLang,
      currentScreen: _appContext.currentScreen ?? 'assistant',
      hasComplaintContext: _appContext.hasComplaintContext,
    );

    try {
      var reply = await _assistantService.processQuery(
        query: query,
        languageCode: activeLang,
        history: _history,
        appContext: _appContext.copyWith(selectedLanguage: activeLang),
      );

      reply = reply.copyWith(
        metadata: {
          ...?reply.metadata,
          'userMessageId': userMsg.id,
          'userMessage': userMsg.text,
        },
      );

      if (mounted) {
        setState(() {
          _history.addMessage(reply);
          _isProcessing = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _history.addMessage(
            AssistantMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: "I'm having trouble responding right now. Please try again.",
              sender: AssistantMessageSender.assistant,
              timestamp: DateTime.now(),
              isError: true,
              followUpSuggestions:
                  CivicAssistantService.getSuggestedPrompts(activeLang, context: _appContext),
              metadata: {
                'userMessageId': userMsg.id,
                'userMessage': userMsg.text,
              },
            ),
          );
          _isProcessing = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleRetry() async {
    if (_lastUserQuery != null && !_isProcessing) {
      await _handleSendMessage(_lastUserQuery!);
    }
  }

  Future<void> _handleFeedback(String messageId, AssistantFeedbackRating rating) async {
    final index = _history.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final msg = _history.messages[index];
    final oldRating = msg.feedbackRating;
    final isDeselect = oldRating == rating;
    final isUpdate = oldRating != null && !isDeselect;
    final newRating = isDeselect ? null : rating;

    // 1. Optimistic UI update
    setState(() {
      _history.updateMessage(
        messageId,
        msg.copyWith(
          feedbackRating: newRating,
          clearFeedbackRating: isDeselect,
        ),
      );
    });

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

    // 3. Persist to Firestore
    String? currentUid;
    try {
      final user = await _userRepository.getCurrentUser();
      if (user.id.isNotEmpty) currentUid = user.id;
    } catch (_) {}

    bool success = false;
    if (isDeselect) {
      success = await CivicAssistantFeedbackService.instance.removeFeedback(
        sessionId: _sessionId,
        assistantMessageId: messageId,
        ownerUid: currentUid,
      );
    } else {
      success = await CivicAssistantFeedbackService.instance.submitFeedback(
        sessionId: _sessionId,
        assistantMessage: msg,
        userMessage: triggeringUserMsg,
        rating: rating,
        appContext: _appContext,
        ownerUid: currentUid,
        isUpdate: isUpdate,
      );
    }

    if (!success && mounted) {
      // Rollback optimistic update
      setState(() {
        _history.updateMessage(
          messageId,
          msg.copyWith(
            feedbackRating: oldRating,
            clearFeedbackRating: oldRating == null,
          ),
        );
      });

      final activeLang = _getActiveLanguage();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            activeLang == 'hi'
                ? 'फ़ीडबैक सहेजने में असमर्थ। कृपया पुनः प्रयास करें।'
                : activeLang == 'mr'
                    ? 'अभिप्राय जतन करता आला नाही. कृपया पुन्हा प्रयत्न करा.'
                    : "Couldn't save feedback. Please try again.",
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    CivicAssistantTtsService.instance.stop();
    final activeLang = _getActiveLanguage();
    CivicAssistantAnalytics.instance.logChatCleared(sessionId: _sessionId);
    setState(() {
      _history.clear();
      _lastUserQuery = null;
      _history.addMessage(
        AssistantMessage(
          id: 'reinit_${DateTime.now().millisecondsSinceEpoch}',
          text: CivicAssistantService.getWelcomeGreeting(activeLang, context: _appContext),
          sender: AssistantMessageSender.assistant,
          timestamp: DateTime.now(),
          followUpSuggestions:
              CivicAssistantService.getSuggestedPrompts(activeLang, context: _appContext),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    final activeLang = _getActiveLanguage();
    final messages = _history.messages;
    final isAssistantEnabled = CivicAssistantConfig.current.assistantEnabled;

    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: CivicFixAppBar(
        title: l10n?.civicAssistant ?? 'Civic Assistant',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n?.clearChat ?? 'Clear Chat',
            onPressed: isAssistantEnabled ? _clearChat : null,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: EdgeInsets.zero,
          child: !isAssistantEnabled
              ? Center(
                  child: Padding(
                    padding: CivicFixSpacing.pagePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.build_circle_outlined,
                          size: 48,
                          color: CivicFixColors.secondaryText,
                        ),
                        CivicFixSpacing.vSpaceMd,
                        Text(
                          activeLang == 'hi'
                              ? 'सिविक सहायक अभी रखरखाव के लिए अस्थायी रूप से अनुपलब्ध है।'
                              : activeLang == 'mr'
                                  ? 'सिविक सहाय्यक सध्या देखभालीसाठी तात्पुरता अनुपलब्ध आहे.'
                                  : 'Civic Assistant is temporarily unavailable for scheduled maintenance.',
                          style: CivicFixTypography.bodyMedium.copyWith(
                            color: CivicFixColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Top Suggestion Chips Bar
                    Container(
                      color: CivicFixColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CivicFixSpacing.md,
                        vertical: CivicFixSpacing.sm,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: CivicAssistantService.getSuggestedPrompts(
                            activeLang,
                            context: _appContext,
                          ).map((prompt) {
                            return Padding(
                              padding: const EdgeInsets.only(right: CivicFixSpacing.xs),
                              child: ActionChip(
                                label: Text(
                                  prompt,
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    color: CivicFixColors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                                backgroundColor: CivicFixColors.surfaceMuted,
                                shape: RoundedRectangleBorder(
                                  borderRadius: CivicFixRadius.chipRadius,
                                  side: const BorderSide(color: CivicFixColors.border),
                                ),
                                onPressed: () => _handleSendMessage(prompt),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: CivicFixColors.border),

                    // Chat Messages Area
                    Expanded(
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: CivicFixSpacing.pagePadding,
                        itemCount: messages.length,
                        separatorBuilder: (_, _) => CivicFixSpacing.vSpaceMd,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isSpeakingThis = CivicAssistantTtsService.instance.isSpeaking &&
                              CivicAssistantTtsService.instance.activeSpeakingMessageId == message.id;
                          return AssistantMessageBubble(
                            message: message,
                            isSpeaking: isSpeakingThis,
                            onSuggestionTap: _handleSendMessage,
                            onRetryTap: message.isError ? _handleRetry : null,
                            onFeedbackTap: (rating) => _handleFeedback(message.id, rating),
                            onSpeakTap: () => _handleSpeak(message),
                          );
                        },
                      ),
                    ),

                    // Thinking Indicator
                    if (_isProcessing)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 8),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            CivicFixSpacing.hSpaceSm,
                            Text(
                              l10n?.assistantThinking ?? 'Assistant is thinking...',
                              style: CivicFixTypography.caption.copyWith(
                                color: CivicFixColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Input Bar
                    Container(
                      decoration: BoxDecoration(
                        color: CivicFixColors.surface,
                        border: const Border(
                          top: BorderSide(color: CivicFixColors.border),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        CivicFixSpacing.md,
                        CivicFixSpacing.sm,
                        CivicFixSpacing.md,
                        CivicFixSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: CivicFixTypography.bodySmall,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: l10n?.assistantMessageHint ??
                                    'Ask about reporting, tracking, or categories...',
                                hintStyle: CivicFixTypography.caption.copyWith(
                                  color: CivicFixColors.disabledText,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: CivicFixSpacing.md,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: CivicFixColors.surfaceMuted,
                                border: OutlineInputBorder(
                                  borderRadius: CivicFixRadius.inputRadius,
                                  borderSide: const BorderSide(color: CivicFixColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: CivicFixRadius.inputRadius,
                                  borderSide: const BorderSide(color: CivicFixColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: CivicFixRadius.inputRadius,
                                  borderSide: const BorderSide(color: CivicFixColors.primary),
                                ),
                              ),
                              onSubmitted: _handleSendMessage,
                            ),
                          ),
                          CivicFixSpacing.hSpaceSm,
                          IconButton.filled(
                            onPressed: () => _handleSendMessage(_textController.text),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: CivicFixColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(44, 44),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
