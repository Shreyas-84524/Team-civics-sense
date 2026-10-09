import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Semantic variants for [CivicFixInfoBanner].
enum CivicFixInfoBannerVariant {
  info,
  warning,
  error,
  success,
  neutral,
}

/// Standardized informational / alert banner.
///
/// Follows Design.md:
/// - 1px hairline border matching the semantic palette
/// - Light tinted surface fill
/// - Clear typography with Inter body and optional Plus Jakarta Sans title
/// - Clean action slot (e.g., "Refresh", "Dismiss", "Retry")
class CivicFixInfoBanner extends StatelessWidget {
  final String message;
  final String? title;
  final CivicFixInfoBannerVariant variant;
  final IconData? icon;
  final bool showIcon;
  final Widget? action;
  final VoidCallback? onTap;
  final bool isCompact;

  const CivicFixInfoBanner({
    super.key,
    required this.message,
    this.title,
    this.variant = CivicFixInfoBannerVariant.info,
    this.icon,
    this.showIcon = true,
    this.action,
    this.onTap,
    this.isCompact = false,
  });

  const CivicFixInfoBanner.info({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.showIcon = true,
    this.action,
    this.onTap,
    this.isCompact = false,
  }) : variant = CivicFixInfoBannerVariant.info;

  const CivicFixInfoBanner.warning({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.showIcon = true,
    this.action,
    this.onTap,
    this.isCompact = false,
  }) : variant = CivicFixInfoBannerVariant.warning;

  const CivicFixInfoBanner.error({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.showIcon = true,
    this.action,
    this.onTap,
    this.isCompact = false,
  }) : variant = CivicFixInfoBannerVariant.error;

  const CivicFixInfoBanner.success({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.showIcon = true,
    this.action,
    this.onTap,
    this.isCompact = false,
  }) : variant = CivicFixInfoBannerVariant.success;

  const CivicFixInfoBanner.neutral({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.showIcon = true,
    this.action,
    this.onTap,
    this.isCompact = false,
  }) : variant = CivicFixInfoBannerVariant.neutral;

  Color _getBackgroundColor() {
    switch (variant) {
      case CivicFixInfoBannerVariant.info:
        return CivicFixColors.infoContainer;
      case CivicFixInfoBannerVariant.warning:
        return CivicFixColors.warningContainer;
      case CivicFixInfoBannerVariant.error:
        return CivicFixColors.errorContainer;
      case CivicFixInfoBannerVariant.success:
        return CivicFixColors.successContainer;
      case CivicFixInfoBannerVariant.neutral:
        return CivicFixColors.surfaceContainerLow;
    }
  }

  Color _getContentColor() {
    switch (variant) {
      case CivicFixInfoBannerVariant.info:
        return CivicFixColors.info;
      case CivicFixInfoBannerVariant.warning:
        return CivicFixColors.warning;
      case CivicFixInfoBannerVariant.error:
        return CivicFixColors.error;
      case CivicFixInfoBannerVariant.success:
        return CivicFixColors.success;
      case CivicFixInfoBannerVariant.neutral:
        return CivicFixColors.textPrimary;
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case CivicFixInfoBannerVariant.info:
        return CivicFixColors.infoBorder;
      case CivicFixInfoBannerVariant.warning:
        return CivicFixColors.warningBorder;
      case CivicFixInfoBannerVariant.error:
        return CivicFixColors.error.withValues(alpha: 0.35);
      case CivicFixInfoBannerVariant.success:
        return CivicFixColors.successBorder;
      case CivicFixInfoBannerVariant.neutral:
        return CivicFixColors.border;
    }
  }

  IconData _getDefaultIcon() {
    if (icon != null) return icon!;
    switch (variant) {
      case CivicFixInfoBannerVariant.info:
        return Icons.info_outline_rounded;
      case CivicFixInfoBannerVariant.warning:
        return Icons.warning_amber_rounded;
      case CivicFixInfoBannerVariant.error:
        return Icons.error_outline_rounded;
      case CivicFixInfoBannerVariant.success:
        return Icons.check_circle_outline_rounded;
      case CivicFixInfoBannerVariant.neutral:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final contentColor = _getContentColor();
    final borderColor = _getBorderColor();
    final effectiveIcon = _getDefaultIcon();

    final bannerContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.spaceMd,
        vertical: isCompact ? CivicFixSpacing.spaceSm : CivicFixSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: CivicFixRadius.cardRadius,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: title != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              effectiveIcon,
              size: isCompact ? 16 : 18,
              color: contentColor,
            ),
            SizedBox(width: CivicFixSpacing.spaceSm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: CivicFixTypographyTokens.labelMd.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: CivicFixTypographyTokens.bodySm.copyWith(
                    color: contentColor,
                    fontSize: isCompact ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            SizedBox(width: CivicFixSpacing.spaceSm),
            action!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: CivicFixRadius.cardRadius,
        child: bannerContent,
      );
    }

    return bannerContent;
  }
}
