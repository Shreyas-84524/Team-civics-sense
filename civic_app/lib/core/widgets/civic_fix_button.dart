import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Button visual variant hierarchy adhering to Design.md.
enum CivicFixButtonVariant {
  /// Primary Authority: Deep slate background (#0F172A), white text (#FFFFFF).
  primary,

  /// Secondary Prestige: White surface (#FFFFFF), deep slate text (#0F172A), 1px border (#E2E8F0).
  secondary,

  /// High-Priority / Accent CTA: Burnished gold (#CA8A04), white text (#FFFFFF).
  accent,
}

/// Standardized action button for CivicFix adhering to "Civic Precision".
///
/// Features:
/// - Exact 48px standard touch target height
/// - Compact 4px architectural radius
/// - Plus Jakarta Sans semi-bold typography
/// - Support for Primary (Slate), Secondary (White/Border), and Accent (Gold) variants
/// - Integrated loading spinner and icon support
/// - Zero hardcoded colors.
class CivicFixButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CivicFixButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? customLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CivicFixButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CivicFixButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.customLeading,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
    this.padding,
  });

  /// Primary action button (Deep Slate).
  const CivicFixButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.customLeading,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
    this.padding,
  }) : variant = CivicFixButtonVariant.primary;

  /// Secondary prestige action button (White surface with 1px border).
  const CivicFixButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.customLeading,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
    this.padding,
  }) : variant = CivicFixButtonVariant.secondary;

  /// High-priority / Accent CTA button (Burnished Gold).
  const CivicFixButton.accent({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.customLeading,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
    this.padding,
  }) : variant = CivicFixButtonVariant.accent;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide side;

    switch (variant) {
      case CivicFixButtonVariant.primary:
        bg = backgroundColor ?? CivicFixColors.secondaryAuthority;
        fg = foregroundColor ?? CivicFixColors.onSecondary;
        side = BorderSide.none;
      case CivicFixButtonVariant.secondary:
        bg = backgroundColor ?? CivicFixColors.surfaceRaised;
        fg = foregroundColor ?? CivicFixColors.secondaryAuthority;
        side = BorderSide(
          color: borderColor ?? CivicFixColors.border,
          width: 1.0,
        );
      case CivicFixButtonVariant.accent:
        bg = backgroundColor ?? CivicFixColors.primaryAccent;
        fg = foregroundColor ?? CivicFixColors.onPrimary;
        side = BorderSide.none;
    }

    final btnPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceLg,
        );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: CivicFixColors.borderLight,
          disabledForegroundColor: CivicFixColors.textDisabled,
          side: side,
          shape: const RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          elevation: 0,
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

/// Convenience standalone alias for Primary Action Button.
class CivicFixPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CivicFixPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixButton.primary(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
    );
  }
}

/// Convenience standalone alias for Secondary Action Button.
class CivicFixSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CivicFixSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixButton.secondary(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
    );
  }
}

/// Convenience standalone alias for High-Priority Accent CTA Button.
class CivicFixAccentButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CivicFixAccentButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = CivicFixSpacing.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixButton.accent(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
    );
  }
}
