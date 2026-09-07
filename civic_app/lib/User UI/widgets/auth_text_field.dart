import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Form input field tailored for authentication forms with accessibility and validation.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePasswordVisibility;
  final Widget? prefixIcon;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final bool enabled;
  final int? maxLength;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePasswordVisibility,
    this.prefixIcon,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: CivicFixTypography.bodySmallMedium.copyWith(
            color: CivicFixColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        CivicFixSpacing.vSpaceSm,
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: isPassword && !isPasswordVisible,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          autofocus: autofocus,
          enabled: enabled,
          maxLength: maxLength,
          style: CivicFixTypography.body,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: isPassword
                ? Semantics(
                    label: isPasswordVisible ? 'Hide password' : 'Show password',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: CivicFixColors.secondaryText,
                        size: 22,
                      ),
                      tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                      onPressed: onTogglePasswordVisibility,
                    ),
                  )
                : null,
            filled: true,
            fillColor: enabled ? CivicFixColors.surface : CivicFixColors.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.lg,
              vertical: CivicFixSpacing.lg,
            ),
            border: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.border, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.border, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.primary, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: CivicFixRadius.buttonRadius,
              borderSide: const BorderSide(color: CivicFixColors.error, width: 2.0),
            ),
            errorMaxLines: 2,
            errorStyle: CivicFixTypography.caption.copyWith(
              color: CivicFixColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
