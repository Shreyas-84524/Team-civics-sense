import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_routes.dart';

/// Circular floating action button providing quick access to the CivicFix AI Assistant.
class CivicChatbotFab extends StatelessWidget {
  final Object? heroTag;
  final VoidCallback? onPressed;

  const CivicChatbotFab({
    super.key,
    this.heroTag = 'civic_assistant_fab',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tooltipText = context.l10nOrNull?.assistant ?? 'CivicFix Assistant';

    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed ??
          () {
            Navigator.pushNamed(context, AppRoutes.assistant);
          },
      backgroundColor: CivicFixColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 6,
      shape: const CircleBorder(),
      tooltip: tooltipText,
      child: const Icon(
        Icons.smart_toy_rounded,
        size: 26,
        color: Colors.white,
      ),
    );
  }
}
