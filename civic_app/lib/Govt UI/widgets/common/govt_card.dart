import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Semantic surface variation for [GovtCard].
enum GovtCardVariant {
  standard,
  metric,
  info,
  warning,
  critical,
}

/// Consistent, restrained surface card for municipal data and operations.
class GovtCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final GovtCardVariant variant;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GovtCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(CivicFixSpacing.lg),
    this.variant = GovtCardVariant.standard,
    this.onTap,
    this.width,
    this.height,
  });

  /// Factory for informational card.
  factory GovtCard.info({
    required Widget child,
    String? title,
    Widget? trailing,
    EdgeInsetsGeometry padding = const EdgeInsets.all(CivicFixSpacing.lg),
    VoidCallback? onTap,
  }) =>
      GovtCard(
        title: title,
        trailing: trailing,
        padding: padding,
        variant: GovtCardVariant.info,
        onTap: onTap,
        child: child,
      );

  /// Factory for warning card.
  factory GovtCard.warning({
    required Widget child,
    String? title,
    Widget? trailing,
    EdgeInsetsGeometry padding = const EdgeInsets.all(CivicFixSpacing.lg),
    VoidCallback? onTap,
  }) =>
      GovtCard(
        title: title,
        trailing: trailing,
        padding: padding,
        variant: GovtCardVariant.warning,
        onTap: onTap,
        child: child,
      );

  /// Factory for critical alert card.
  factory GovtCard.critical({
    required Widget child,
    String? title,
    Widget? trailing,
    EdgeInsetsGeometry padding = const EdgeInsets.all(CivicFixSpacing.lg),
    VoidCallback? onTap,
  }) =>
      GovtCard(
        title: title,
        trailing: trailing,
        padding: padding,
        variant: GovtCardVariant.critical,
        onTap: onTap,
        child: child,
      );

  /// Factory for clickable navigation card.
  factory GovtCard.interactive({
    required Widget child,
    required VoidCallback onTap,
    String? title,
    String? subtitle,
    Widget? leading,
  }) =>
      GovtCard(
        title: title,
        subtitle: subtitle,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: GovtThemeTokens.textSecondary,
          size: 20,
        ),
        onTap: onTap,
        child: child,
      );

  Color get _backgroundColor {
    switch (variant) {
      case GovtCardVariant.standard:
      case GovtCardVariant.metric:
        return GovtThemeTokens.surface;
      case GovtCardVariant.info:
        return const Color(0xFFF0F7FC);
      case GovtCardVariant.warning:
        return const Color(0xFFFEF9EE);
      case GovtCardVariant.critical:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get _borderColor {
    switch (variant) {
      case GovtCardVariant.standard:
      case GovtCardVariant.metric:
        return GovtThemeTokens.border;
      case GovtCardVariant.info:
        return const Color(0xFFBAE6FD);
      case GovtCardVariant.warning:
        return const Color(0xFFFDE68A);
      case GovtCardVariant.critical:
        return const Color(0xFFFECACA);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = child;

    if (title != null || trailing != null) {
      cardContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: GovtTypography.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GovtTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                CivicFixSpacing.hSpaceSm,
                trailing!,
              ],
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          child,
        ],
      );
    }

    final container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: _borderColor),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: cardContent,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: GovtThemeTokens.cardRadius,
        child: container,
      );
    }

    return container;
  }
}
