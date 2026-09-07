import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Standardized text input field.
class CivicFixTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
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
  final VoidCallback? onTap;
  final bool autofocus;

  const CivicFixTextField({
    super.key,
    this.label,
    this.hintText,
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
    this.onTap,
    this.autofocus = false,
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
            style: CivicFixTypography.bodySmallMedium.copyWith(
              color: CivicFixColors.primaryText,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          autofocus: autofocus,
          style: CivicFixTypography.body,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly ? CivicFixColors.background : CivicFixColors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.lg,
              vertical: maxLines > 1 ? CivicFixSpacing.md : CivicFixSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
