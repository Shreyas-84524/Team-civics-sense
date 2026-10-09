import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Clean, elevated card container adhering to the "Civic Precision" design specification.
///
/// Features:
/// - Pure white surface (`#FFFFFF`) on porcelain canvas
/// - Architectural 1px hairline border (`#E2E8F0`)
/// - 8px radius (`CivicFixRadius.card`)
/// - Optional top accent rule (2px) in burnished gold or custom semantic color for alerts
/// - Zero hardcoded colors.
class CivicFixCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;
  final double borderRadius;
  final Color? topAccentColor;
  final double topAccentHeight;
  final List<BoxShadow>? customShadow;

  const CivicFixCard({
    super.key,
    required this.child,
    this.padding = CivicFixSpacing.cardPadding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
    this.borderRadius = CivicFixRadius.card,
    this.topAccentColor,
    this.topAccentHeight = 2.0,
    this.customShadow,
  });

  /// Factory constructor for a high-priority / alert card with a burnished gold top accent.
  factory CivicFixCard.accent({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = CivicFixSpacing.cardPadding,
    VoidCallback? onTap,
    Color topAccentColor = CivicFixColors.primaryAccent,
  }) {
    return CivicFixCard(
      key: key,
      padding: padding,
      onTap: onTap,
      topAccentColor: topAccentColor,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? CivicFixColors.surfaceRaised;
    final border = BorderSide(
      color: borderColor ?? CivicFixColors.border,
      width: 1,
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: border,
    );

    Widget content = child;

    // Optional top accent line for prioritized or pinned national alerts
    if (topAccentColor != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: topAccentHeight,
              color: topAccentColor,
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: padding,
        child: child,
      );
    }

    final cardWidget = Material(
      color: bg,
      elevation: elevation,
      shadowColor: CivicFixColors.secondaryAuthority,
      shape: cardShape,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: CivicFixColors.surfaceContainerLow,
              highlightColor: CivicFixColors.surfaceContainer,
              child: topAccentColor != null ? content : content,
            )
          : content,
    );

    if (customShadow != null && customShadow!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: customShadow,
        ),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
