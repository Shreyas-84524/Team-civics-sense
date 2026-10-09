import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Standardized, accessible page header component for CivicFix screens.
///
/// Follows Design.md:
/// - Prominent title in Plus Jakarta Sans
/// - Descriptive subtitle in Inter
/// - Optional breadcrumb navigation
/// - Optional status chip / jurisdiction badge
/// - Optional leading back button and trailing action buttons
/// - Responsive wrapping preventing text clipping or overflow
class CivicFixPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onBack;
  final Widget? badge;
  final List<Widget>? actions;
  final Widget? breadcrumbs;
  final EdgeInsetsGeometry? padding;
  final bool showBottomBorder;

  const CivicFixPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onBack,
    this.badge,
    this.actions,
    this.breadcrumbs,
    this.padding,
    this.showBottomBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = CivicFixBreakpoints.isMobile(context);

    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: isMobile ? CivicFixSpacing.marginMobile : CivicFixSpacing.gutter,
          vertical: isMobile ? CivicFixSpacing.spaceMd : CivicFixSpacing.spaceLg,
        );

    Widget headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional Breadcrumbs
        if (breadcrumbs != null) ...[
          breadcrumbs!,
          const SizedBox(height: CivicFixSpacing.spaceSm),
        ],

        // Main Header Row / Column
        if (isMobile)
          _buildMobileLayout(context)
        else
          _buildDesktopLayout(context),
      ],
    );

    if (showBottomBorder) {
      return Container(
        padding: effectivePadding,
        decoration: const BoxDecoration(
          color: CivicFixColors.surfaceRaised,
          border: Border(
            bottom: BorderSide(
              color: CivicFixColors.border,
              width: 1.0,
            ),
          ),
        ),
        child: headerContent,
      );
    }

    return Padding(
      padding: effectivePadding,
      child: headerContent,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (onBack != null || leading != null) ...[
          leading ??
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: CivicFixColors.textPrimary,
                tooltip: 'Back',
              ),
          const SizedBox(width: CivicFixSpacing.spaceSm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: CivicFixSpacing.spaceSm,
                runSpacing: CivicFixSpacing.spaceXs,
                children: [
                  Text(
                    title,
                    style: CivicFixTypographyTokens.headlineLg.copyWith(
                      color: CivicFixColors.textPrimary,
                    ),
                  ),
                  ?badge,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: CivicFixTypographyTokens.bodySm.copyWith(
                    color: CivicFixColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(width: CivicFixSpacing.spaceMd),
          Wrap(
            spacing: CivicFixSpacing.spaceSm,
            runSpacing: CivicFixSpacing.spaceXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions!,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null || leading != null) ...[
              leading ??
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: CivicFixColors.textPrimary,
                    tooltip: 'Back',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              const SizedBox(width: CivicFixSpacing.spaceSm),
            ],
            Expanded(
              child: Text(
                title,
                style: CivicFixTypographyTokens.headlineLgMobile.copyWith(
                  color: CivicFixColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (badge != null) ...[
          const SizedBox(height: CivicFixSpacing.spaceXs),
          badge!,
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: CivicFixTypographyTokens.bodySm.copyWith(
              color: CivicFixColors.textSecondary,
            ),
          ),
        ],
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(height: CivicFixSpacing.spaceMd),
          Wrap(
            spacing: CivicFixSpacing.spaceSm,
            runSpacing: CivicFixSpacing.spaceSm,
            children: actions!,
          ),
        ],
      ],
    );
  }
}
