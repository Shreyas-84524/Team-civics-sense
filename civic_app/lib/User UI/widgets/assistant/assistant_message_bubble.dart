import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/assistant_message_model.dart';
import '../../../core/utils/date_formatter.dart';

/// Message bubble for conversational Civic Assistant chat.
class AssistantMessageBubble extends StatelessWidget {
  final AssistantMessage message;
  final ValueChanged<String>? onSuggestionTap;

  const AssistantMessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Semantics(
      label: isUser ? 'You said: ${message.text}' : 'Assistant says: ${message.text}',
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
                  decoration: const BoxDecoration(
                    color: CivicFixColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.smart_toy_rounded,
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
                    color: isUser ? CivicFixColors.primary : CivicFixColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(CivicFixRadius.card),
                      topRight: const Radius.circular(CivicFixRadius.card),
                      bottomLeft: Radius.circular(isUser ? CivicFixRadius.card : 2),
                      bottomRight: Radius.circular(isUser ? 2 : CivicFixRadius.card),
                    ),
                    border: isUser ? null : Border.all(color: CivicFixColors.border),
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
                          color: isUser ? Colors.white : CivicFixColors.primaryText,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        DateFormatter.formatTime(message.timestamp),
                        style: CivicFixTypography.caption.copyWith(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.7)
                              : CivicFixColors.disabledText,
                          fontSize: 10,
                        ),
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
