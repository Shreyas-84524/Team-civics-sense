import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Standardized CivicFix list tile for structured, institutional lists.
///
/// Follows Design.md:
/// - Porcelain white background with crisp 1px hairline border
/// - 8px radius
/// - Headings in Plus Jakarta Sans, body/subtitles in Inter
/// - Subtle hover/press interaction states
class CivicFixListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final String? titleText;
  final Widget? subtitle;
  final String? subtitleText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool selected;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  const CivicFixListTile({
    super.key,
    this.leading,
    this.title,
    this.titleText,
    this.subtitle,
    this.subtitleText,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.selected = false,
    this.contentPadding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  }) : assert(title != null || titleText != null, 'Either title or titleText must be provided');

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? CivicFixRadius.cardRadius;
    final effectiveBgColor = backgroundColor ??
        (selected ? CivicFixColors.surfaceContainerLow : CivicFixColors.surfaceRaised);
    final effectiveBorderColor = borderColor ??
        (selected ? CivicFixColors.secondaryAuthority : CivicFixColors.border);

    Widget titleWidget = title ??
        Text(
          titleText!,
          style: (dense ? CivicFixTypographyTokens.labelMd : CivicFixTypographyTokens.titleMd).copyWith(
            color: CivicFixColors.textPrimary,
          ),
        );

    Widget? subtitleWidget;
    if (subtitle != null) {
      subtitleWidget = subtitle;
    } else if (subtitleText != null) {
      subtitleWidget = Text(
        subtitleText!,
        style: CivicFixTypographyTokens.bodySm.copyWith(
          color: CivicFixColors.textSecondary,
        ),
      );
    }

    final padding = contentPadding ??
        EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceMd,
          vertical: dense ? CivicFixSpacing.spaceSm : CivicFixSpacing.md,
        );

    final tileContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: CivicFixElevation.none,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: dense ? CivicFixSpacing.sm : CivicFixSpacing.spaceMd),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget,
                if (subtitleWidget != null) ...[
                  SizedBox(height: dense ? 2 : 4),
                  subtitleWidget,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: dense ? CivicFixSpacing.sm : CivicFixSpacing.spaceMd),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: tileContent,
      );
    }

    return tileContent;
  }
}
