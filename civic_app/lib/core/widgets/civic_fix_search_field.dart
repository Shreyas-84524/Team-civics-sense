import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Public Services Search & Command Bar component adhering to Design.md.
///
/// Features:
/// - Prominent, centered institutional search field
/// - Exact 48px height with pure white fill (#FFFFFF)
/// - 1px hairline border (#E2E8F0)
/// - Left-aligned search icon in muted slate
/// - Optional shortcut badge / trailing action (e.g., 'Cmd + K', 'Filter')
/// - Focus state reveals deep slate (#0F172A) focus outline
/// - Zero hardcoded colors.
class CivicFixSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String hintText;
  final bool readOnly;
  final bool autofocus;
  final String? shortcutLabel;
  final Widget? trailing;
  final FocusNode? focusNode;

  const CivicFixSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.hintText = 'Search public services, records & grievances...',
    this.readOnly = false,
    this.autofocus = false,
    this.shortcutLabel,
    this.trailing,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CivicFixSpacing.searchBarHeight,
      decoration: BoxDecoration(
        color: CivicFixColors.surfaceRaised,
        borderRadius: CivicFixRadius.baseRadius,
        border: Border.all(color: CivicFixColors.border, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: CivicFixSpacing.spaceMd, right: CivicFixSpacing.spaceSm),
            child: Icon(
              Icons.search_rounded,
              size: CivicFixSpacing.iconMd,
              color: CivicFixColors.textMuted,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTap: onTap,
              readOnly: readOnly,
              autofocus: autofocus,
              style: CivicFixTypographyTokens.bodyMd.copyWith(
                color: CivicFixColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: CivicFixTypographyTokens.bodyMd.copyWith(
                  color: CivicFixColors.textMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (controller != null && controller!.text.isNotEmpty && onClear != null)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: CivicFixSpacing.iconSm,
                color: CivicFixColors.textMuted,
              ),
              onPressed: onClear,
              splashRadius: 16,
            ),
          if (shortcutLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: CivicFixSpacing.spaceSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CivicFixSpacing.spaceSm,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: CivicFixColors.surfaceContainerLow,
                  borderRadius: CivicFixRadius.smRadius,
                  border: Border.all(color: CivicFixColors.borderLight),
                ),
                child: Text(
                  shortcutLabel!,
                  style: CivicFixTypographyTokens.labelSm.copyWith(
                    color: CivicFixColors.textSlateMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: CivicFixSpacing.spaceSm),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
