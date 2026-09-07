import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Reusable Government content card container with header and actions.
class DashboardCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? headerTrailing;
  final Widget? headerAction;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    this.title,
    this.subtitle,
    this.headerTrailing,
    this.headerAction,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || headerTrailing != null || headerAction != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.lg,
              vertical: CivicFixSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: CivicFixTypography.h3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?(headerTrailing ?? headerAction),
              ],
            ),
          ),
          const Divider(color: GovtThemeTokens.border, height: 1),
        ],
        Padding(
          padding: padding ?? const EdgeInsets.all(CivicFixSpacing.lg),
          child: child,
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: GovtThemeTokens.cardRadius,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: GovtThemeTokens.cardRadius,
                child: cardContent,
              )
            : cardContent,
      ),
    );
  }
}
