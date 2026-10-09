import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/assistant/config/civic_assistant_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/assistant_message_model.dart';
import '../../../core/utils/date_formatter.dart';

/// Message bubble for conversational Civic Assistant chat with accessibility,
/// copy action, TTS readiness, and quality feedback rating.
class AssistantMessageBubble extends StatelessWidget {
  final AssistantMessage message;
  final ValueChanged<String>? onSuggestionTap;
  final VoidCallback? onRetryTap;
  final ValueChanged<AssistantFeedbackRating>? onFeedbackTap;
  final VoidCallback? onCopyTap;
  final VoidCallback? onSpeakTap;
  final bool isSpeaking;

  const AssistantMessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
    this.onRetryTap,
    this.onFeedbackTap,
    this.onCopyTap,
    this.onSpeakTap,
    this.isSpeaking = false,
  });

  void _handleDefaultCopy(BuildContext context) {
    if (onCopyTap != null) {
      onCopyTap!();
    } else {
      Clipboard.setData(ClipboardData(text: message.text));
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;
    final config = CivicAssistantConfig.current;

    return Semantics(
      label: isUser
          ? 'You said: ${message.text}'
          : isError
              ? 'Assistant encountered an error: ${message.text}'
              : 'Assistant says: ${message.text}',
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  decoration: BoxDecoration(
                    color: isError ? CivicFixColors.error : CivicFixColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isError ? Icons.error_outline_rounded : Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicFixSpacing.md,
                    vertical: CivicFixSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? CivicFixColors.primary
                        : isError
                            ? CivicFixColors.error.withValues(alpha: 0.06)
                            : CivicFixColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(CivicFixRadius.card),
                      topRight: const Radius.circular(CivicFixRadius.card),
                      bottomLeft: Radius.circular(isUser ? CivicFixRadius.card : 2),
                      bottomRight: Radius.circular(isUser ? 2 : CivicFixRadius.card),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isError
                                ? CivicFixColors.error.withValues(alpha: 0.3)
                                : CivicFixColors.border,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: CivicFixTypography.bodySmall.copyWith(
                          color: isUser
                              ? Colors.white
                              : isError
                                  ? CivicFixColors.error
                                  : CivicFixColors.primaryText,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormatter.formatTime(message.timestamp),
                            style: CivicFixTypography.caption.copyWith(
                              color: isUser
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : CivicFixColors.disabledText,
                              fontSize: 10,
                            ),
                          ),
                          if (isError && onRetryTap != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onRetryTap,
                              child: Text(
                                'Retry',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: CivicFixColors.primary,
                                  fontSize: 10,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                          if (!isUser && !isError) ...[
                            const SizedBox(width: 8),
                            // Quick Copy Action
                            Semantics(
                              button: true,
                              label: 'Copy message text',
                              child: InkWell(
                                onTap: () => _handleDefaultCopy(context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 13,
                                    color: CivicFixColors.disabledText,
                                  ),
                                ),
                              ),
                            ),
                            // TTS Speaker Action Hook
                            if (config.ttsReadinessEnabled) ...[
                              const SizedBox(width: 6),
                              Semantics(
                                button: true,
                                label: isSpeaking ? 'Stop reading message' : 'Listen to message',
                                child: Tooltip(
                                  message: isSpeaking ? 'Stop reading' : 'Read aloud',
                                  child: InkWell(
                                    onTap: onSpeakTap,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                        isSpeaking
                                            ? Icons.stop_circle_outlined
                                            : Icons.volume_up_outlined,
                                        size: 14,
                                        color: isSpeaking
                                            ? CivicFixColors.primary
                                            : CivicFixColors.disabledText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            // Quality Feedback Actions (Thumbs Up / Down)
                            if (config.feedbackEnabled && onFeedbackTap != null) ...[
                              const SizedBox(width: 8),
                              Semantics(
                                button: true,
                                label: 'Mark message helpful',
                                child: InkWell(
                                  onTap: () => onFeedbackTap!(AssistantFeedbackRating.helpful),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(
                                      message.feedbackRating == AssistantFeedbackRating.helpful
                                          ? Icons.thumb_up_alt_rounded
                                          : Icons.thumb_up_alt_outlined,
                                      size: 13,
                                      color: message.feedbackRating == AssistantFeedbackRating.helpful
                                          ? CivicFixColors.primary
                                          : CivicFixColors.disabledText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Semantics(
                                button: true,
                                label: 'Mark message unhelpful',
                                child: InkWell(
                                  onTap: () => onFeedbackTap!(AssistantFeedbackRating.unhelpful),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(
                                      message.feedbackRating == AssistantFeedbackRating.unhelpful
                                          ? Icons.thumb_down_alt_rounded
                                          : Icons.thumb_down_alt_outlined,
                                      size: 13,
                                      color: message.feedbackRating == AssistantFeedbackRating.unhelpful
                                          ? CivicFixColors.error
                                          : CivicFixColors.disabledText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Follow-up Suggestion Chips for Assistant replies
          if (!isUser && message.followUpSuggestions.isNotEmpty) ...[
            CivicFixSpacing.vSpaceSm,
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Wrap(
                spacing: CivicFixSpacing.xs,
                runSpacing: CivicFixSpacing.xs,
                children: message.followUpSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(
                      suggestion,
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    onPressed: () => onSuggestionTap?.call(suggestion),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
