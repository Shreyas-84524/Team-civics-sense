import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/assistant_message_model.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/assistant_service.dart';
import '../widgets/assistant/assistant_message_bubble.dart';

/// Screen for CivicFix AI Citizen Assistant providing local intent-matched answers.
class AssistantScreen extends StatefulWidget {
  final CivicAssistantService? assistantService;
  final UserRepository? userRepository;

  const AssistantScreen({
    super.key,
    this.assistantService,
    this.userRepository,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late final CivicAssistantService _assistantService;
  late final UserRepository _userRepository;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AssistantMessage> _messages = [];

  bool _isProcessing = false;
  String _userLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _assistantService = widget.assistantService ?? CivicAssistantService();
    _userRepository = widget.userRepository ?? MockUserRepository();
    _initAssistant();
  }

  Future<void> _initAssistant() async {
    final user = await _userRepository.getCurrentUser();
    if (mounted) {
      setState(() {
        _userLanguage = user.languageCode;
        _messages.add(
          AssistantMessage(
            id: 'init_1',
            text: _getWelcomeGreeting(_userLanguage),
            sender: AssistantMessageSender.assistant,
            timestamp: DateTime.now(),
            followUpSuggestions: CivicAssistantService.getSuggestedPrompts(_userLanguage),
          ),
        );
      });
    }
  }

  String _getWelcomeGreeting(String lang) {
    switch (lang) {
      case 'hi':
        return 'नमस्ते! मैं आपका CivicFix सहायक हूँ। मैं आपको नागरिक शिकायत दर्ज करने, श्रेणियों को समझने, या स्थिति ट्रैक करने में मदद कर सकता हूँ।';
      case 'mr':
        return 'नमस्कार! मी तुमचा CivicFix सहाय्यक आहे. मी तक्रार नोंदवणे, प्रभाग माहिती, किंवा स्थिती ट्रॅक करण्यात मदत करू शकतो.';
      case 'en':
      default:
        return 'Hello! I am your CivicFix Assistant. How can I help you with civic issues, categories, or tracking complaints today?';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isProcessing) return;

    _textController.clear();

    final userMsg = AssistantMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      sender: AssistantMessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isProcessing = true;
    });
    _scrollToBottom();

    try {
      final reply = await _assistantService.processQuery(
        query: query,
        languageCode: _userLanguage,
      );

      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isProcessing = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(
            AssistantMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: "Sorry, I couldn't process that question right now. Try selecting a suggested topic.",
              sender: AssistantMessageSender.assistant,
              timestamp: DateTime.now(),
              isError: true,
              followUpSuggestions: CivicAssistantService.getSuggestedPrompts(_userLanguage),
            ),
          );
          _isProcessing = false;
        });
        _scrollToBottom();
      }
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
    setState(() {
      _messages.clear();
      _messages.add(
        AssistantMessage(
          id: 'reinit_${DateTime.now().millisecondsSinceEpoch}',
          text: _getWelcomeGreeting(_userLanguage),
          sender: AssistantMessageSender.assistant,
          timestamp: DateTime.now(),
          followUpSuggestions: CivicAssistantService.getSuggestedPrompts(_userLanguage),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: CivicFixAppBar(
        title: 'Civic Assistant',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: EdgeInsets.zero,
          child: Column(
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
                    children: CivicAssistantService.getSuggestedPrompts(_userLanguage).map((prompt) {
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
                  itemCount: _messages.length,
                  separatorBuilder: (_, _) => CivicFixSpacing.vSpaceMd,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return AssistantMessageBubble(
                      message: message,
                      onSuggestionTap: _handleSendMessage,
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
                        'Assistant is thinking...',
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
                          hintText: 'Ask about reporting, tracking, or categories...',
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
