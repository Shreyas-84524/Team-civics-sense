import 'package:flutter/material.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/civicfix_design_tokens.dart';
import '../../core/widgets/civic_fix_card.dart';

/// Clean, discoverable chatbot entry banner on the Citizen Home screen.
///
/// Follows Design.md:
/// - 8px card radius, pure white surface with 1px hairline border
/// - Institutional AI Assistant prompt
/// - Plus Jakarta Sans title, Inter description
class HomeAssistantBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeAssistantBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      onTap: onTap ??
          () {
            Navigator.pushNamed(context, AppRoutes.assistant);
          },
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.spaceMd,
        vertical: CivicFixSpacing.spaceMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CivicFixColors.surfaceContainerLow,
              borderRadius: CivicFixRadius.buttonRadius,
              border: Border.all(
                color: CivicFixColors.border,
                width: 1.0,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: CivicFixColors.primaryAccent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: CivicFixSpacing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'CivicFix AI Assistant',
                      style: CivicFixTypographyTokens.titleMd.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CivicFixColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: CivicFixColors.warningContainer,
                        borderRadius: CivicFixRadius.chipRadius,
                      ),
                      child: Text(
                        'AI',
                        style: CivicFixTypographyTokens.labelSm.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: CivicFixColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Need guidance on BMC services or grievance tracking?',
                  style: CivicFixTypographyTokens.bodySm.copyWith(
                    color: CivicFixColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: CivicFixSpacing.spaceSm),
          const Icon(
            Icons.arrow_forward_rounded,
            color: CivicFixColors.secondaryAuthority,
            size: 18,
          ),
        ],
      ),
    );
  }
}
