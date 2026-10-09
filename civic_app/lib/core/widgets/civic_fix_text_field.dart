import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Standardized text input field adhering to "Civic Precision".
///
/// Features:
/// - Exact 42px standard input height
/// - Pure white surface (`#FFFFFF`) with 1px hairline border (`#E2E8F0`)
/// - 4px architectural radius
/// - Focus outline with deep slate (#0F172A)
/// - Error outline in #BA1A1A
/// - Inter typography for readable data entry
/// - Zero hardcoded colors.
class CivicFixTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;

  const CivicFixTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: CivicFixTypographyTokens.labelMd.copyWith(
              color: CivicFixColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          autofocus: autofocus,
          style: CivicFixTypographyTokens.bodyMd.copyWith(
            color: enabled ? CivicFixColors.textPrimary : CivicFixColors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly || !enabled
                ? CivicFixColors.surfaceContainerLow
                : CivicFixColors.surfaceContainerLowest,
            contentPadding: EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.spaceMd,
              vertical: maxLines > 1 ? CivicFixSpacing.spaceMd : 10.0,
            ),
            hintStyle: CivicFixTypographyTokens.bodyMd.copyWith(
              color: CivicFixColors.textMuted,
            ),
            helperStyle: CivicFixTypographyTokens.labelSm.copyWith(
              color: CivicFixColors.textSecondary,
            ),
            border: const OutlineInputBorder(
              borderRadius: CivicFixRadius.inputRadius,
              borderSide: CivicFixElevation.hairlineBorder,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: CivicFixRadius.inputRadius,
              borderSide: CivicFixElevation.hairlineBorder,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: CivicFixRadius.inputRadius,
              borderSide: BorderSide(
                color: CivicFixColors.secondaryAuthority,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: CivicFixRadius.inputRadius,
              borderSide: BorderSide(
                color: CivicFixColors.error,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: CivicFixRadius.inputRadius,
              borderSide: BorderSide(
                color: CivicFixColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
