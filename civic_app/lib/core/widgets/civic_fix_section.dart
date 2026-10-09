import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';
import 'section_header.dart';

/// Standard structural section container with consistent vertical rhythm.
///
/// Follows Design.md:
/// - Consistent vertical section spacing (24px default)
/// - Integrated [CivicFixSectionHeader] support
/// - Standard padding and child alignment
class CivicFixSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? actionTitle;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final Widget? header;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? headerPadding;
  final double? headerSpacing;

  const CivicFixSection({
    super.key,
    this.title,
    this.subtitle,
    this.actionTitle,
    this.onActionTap,
    this.trailing,
    this.header,
    required this.child,
    this.padding,
    this.headerPadding,
    this.headerSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.only(bottom: CivicFixSpacing.spaceLg);

    Widget? headerWidget = header;
    if (headerWidget == null && title != null) {
      headerWidget = SectionHeader(
        title: title!,
        subtitle: subtitle,
        actionTitle: actionTitle,
        onActionTap: onActionTap,
        trailing: trailing,
        padding: headerPadding ?? const EdgeInsets.only(bottom: CivicFixSpacing.spaceSm),
      );
    }

    return Padding(
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headerWidget != null) ...[
            headerWidget,
            if (headerSpacing != null) SizedBox(height: headerSpacing!),
          ],
          child,
        ],
      ),
    );
  }
}
