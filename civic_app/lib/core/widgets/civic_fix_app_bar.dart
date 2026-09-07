import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Standard AppBar for CivicFix screens.
class CivicFixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;

  const CivicFixAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: CivicFixTypography.h3.copyWith(
          color: foregroundColor ?? CivicFixColors.primaryText,
        ),
      ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions != null
          ? [
              ...actions!,
              CivicFixSpacing.hSpaceSm,
            ]
          : null,
      backgroundColor: backgroundColor ?? CivicFixColors.surface,
      foregroundColor: foregroundColor ?? CivicFixColors.primaryText,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: centerTitle,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
