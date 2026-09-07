import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Primary action button for CivicFix with loading state and 48px+ touch target.
class CivicFixButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;

  const CivicFixButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = CivicFixSpacing.huge,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? CivicFixColors.primary;
    final fg = foregroundColor ?? Colors.white;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: CivicFixColors.disabledText.withValues(alpha: 0.3),
          disabledForegroundColor: CivicFixColors.disabledText,
          shape: RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          elevation: 0,
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
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.button.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
