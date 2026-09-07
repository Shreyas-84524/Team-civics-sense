import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// Clean, elevated card container with standard 12px border radius.
class CivicFixCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;
  final double borderRadius;

  const CivicFixCard({
    super.key,
    required this.child,
    this.padding = CivicFixSpacing.cardPadding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
    this.borderRadius = CivicFixRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: borderColor ?? CivicFixColors.border,
      width: 1,
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: border,
    );

    if (onTap != null) {
      return Card(
        elevation: elevation,
        shape: cardShape,
        color: backgroundColor ?? CivicFixColors.surface,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      );
    }

    return Card(
      elevation: elevation,
      shape: cardShape,
      color: backgroundColor ?? CivicFixColors.surface,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
