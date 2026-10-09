import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Responsive Content Container ensuring content is centered and constrained
/// according to DESIGN.md editorial layout guidelines.
///
/// Automatically applies responsive margins:
/// - Mobile (<768px): 16px gutter
/// - Tablet & Desktop (>=768px): 24px gutter
///
/// Prevents extreme horizontal stretching on wide desktop/web viewports.
class CivicFixContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const CivicFixContentContainer({
    super.key,
    required this.child,
    this.maxWidth = CivicFixBreakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Narrow content container for forms, authentication, and centered reading layouts (680px max).
  const CivicFixContentContainer.narrow({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : maxWidth = CivicFixBreakpoints.maxFormWidth;

  /// Wide content container for data-heavy administrative dashboards & GIS views (1440px max).
  const CivicFixContentContainer.wide({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : maxWidth = CivicFixBreakpoints.maxDashboardWidth;

  @override
  Widget build(BuildContext context) {
    final isMobile = CivicFixBreakpoints.isMobile(context);
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: isMobile ? CivicFixSpacing.marginMobile : CivicFixSpacing.gutter,
        );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
