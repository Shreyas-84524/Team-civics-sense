import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Compact and accessible search field with clear action for Government tables and dashboards.
class GovtSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final double? width;

  const GovtSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search complaints, IDs, keywords...',
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 320,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: CivicFixTypography.bodySmall.copyWith(
          color: GovtThemeTokens.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textDisabled,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: GovtThemeTokens.textSecondary,
          ),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    controller!.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                )
              : null,
          filled: true,
          fillColor: GovtThemeTokens.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: GovtThemeTokens.chipRadius,
            borderSide: const BorderSide(color: GovtThemeTokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: GovtThemeTokens.chipRadius,
            borderSide: const BorderSide(color: GovtThemeTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: GovtThemeTokens.chipRadius,
            borderSide: const BorderSide(color: GovtThemeTokens.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
