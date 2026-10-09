import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Standard AppBar for CivicFix screens.
///
/// Follows Design.md:
/// - Porcelain white background
/// - Deep slate title in Plus Jakarta Sans
/// - Zero elevation by default, 1px bottom border
/// - Subtle action icons
class CivicFixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double? elevation;

  const CivicFixAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFg = foregroundColor ?? CivicFixColors.textPrimary;
    final effectiveBg = backgroundColor ?? CivicFixColors.surfaceRaised;

    return AppBar(
      title: titleWidget ??
          Text(
            title,
            style: CivicFixTypographyTokens.headlineSm.copyWith(
              color: effectiveFg,
              fontWeight: FontWeight.w700,
            ),
          ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: CivicFixSpacing.spaceSm),
            ]
          : null,
      backgroundColor: effectiveBg,
      foregroundColor: effectiveFg,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      bottom: bottom,
      shape: const Border(
        bottom: BorderSide(
          color: CivicFixColors.border,
          width: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
