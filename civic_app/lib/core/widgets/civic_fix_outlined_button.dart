import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Outlined button for secondary actions adhering to "Civic Precision".
///
/// Features:
/// - Porcelain white / transparent background
/// - 1px hairline border in `#E2E8F0`
/// - Deep slate typography in Plus Jakarta Sans
/// - Compact 4px architectural radius
/// - Zero hardcoded colors.
class CivicFixOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? customLeading;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CivicFixOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.customLeading,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? CivicFixColors.secondaryAuthority;
    final border = borderColor ?? CivicFixColors.border;
    final bg = backgroundColor ?? CivicFixColors.surfaceRaised;
    final btnPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceLg,
        );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledForegroundColor: CivicFixColors.textDisabled,
          side: BorderSide(
            color: border,
            width: 1.0,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          padding: btnPadding,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customLeading != null) ...[
                    customLeading!,
                    CivicFixSpacing.hSpaceSm,
                  ] else if (icon != null) ...[
                    Icon(icon, size: CivicFixSpacing.iconMd, color: fg),
                    CivicFixSpacing.hSpaceSm,
                  ],
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypographyTokens.titleMd.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
