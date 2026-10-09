import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Standardized section header for dashboards and detail screens.
///
/// Follows Design.md:
/// - Plus Jakarta Sans title
/// - Inter subtitle
/// - Restrained gold / slate action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionTitle;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionTitle,
    this.onActionTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: CivicFixSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: CivicFixTypographyTokens.headlineSm.copyWith(
                    color: CivicFixColors.textPrimary,
                  ),
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
          if (trailing != null)
            trailing!
          else if (actionTitle != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: CivicFixRadius.baseRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: CivicFixSpacing.xs,
                  horizontal: CivicFixSpacing.xs + 2,
                ),
                child: Text(
                  actionTitle!,
                  style: CivicFixTypographyTokens.labelMd.copyWith(
                    color: CivicFixColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard alias conforming to the CivicFix naming convention.
typedef CivicFixSectionHeader = SectionHeader;
