import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Outlined button for secondary actions.
class CivicFixOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double height;

  const CivicFixOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.borderColor,
    this.textColor,
    this.width,
    this.height = CivicFixSpacing.huge,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? CivicFixColors.primary;
    final border = borderColor ?? CivicFixColors.border;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(
            color: border,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.lg,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    CivicFixSpacing.hSpaceSm,
                  ],
                  Text(
                    text,
                    style: CivicFixTypography.button.copyWith(color: fg),
                  ),
                ],
              ),
      ),
    );
  }
}
