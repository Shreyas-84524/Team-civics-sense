import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Semantic variants for [CivicFixStatusChip].
enum CivicFixStatusChipVariant {
  success,
  warning,
  error,
  info,
  neutral,
  verified,
  processing,
}

/// Standardized, high-contrast, institutional status chip.
///
/// Follows Design.md:
/// - Pill shape (full 9999px radius)
/// - 1px hairline border matching the semantic palette
/// - Light tinted background container
/// - Crisp, readable typography with subtle uppercase or label tracking
class CivicFixStatusChip extends StatelessWidget {
  final String label;
  final CivicFixStatusChipVariant variant;
  final IconData? icon;
  final bool showIcon;
  final bool isCompact;
  final VoidCallback? onTap;

  const CivicFixStatusChip({
    super.key,
    required this.label,
    this.variant = CivicFixStatusChipVariant.neutral,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  });

  const CivicFixStatusChip.success({
    super.key,
    required this.label,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  }) : variant = CivicFixStatusChipVariant.success;

  const CivicFixStatusChip.warning({
    super.key,
    required this.label,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  }) : variant = CivicFixStatusChipVariant.warning;

  const CivicFixStatusChip.error({
    super.key,
    required this.label,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  }) : variant = CivicFixStatusChipVariant.error;

  const CivicFixStatusChip.info({
    super.key,
    required this.label,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  }) : variant = CivicFixStatusChipVariant.info;

  const CivicFixStatusChip.neutral({
    super.key,
    required this.label,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  }) : variant = CivicFixStatusChipVariant.neutral;

  const CivicFixStatusChip.verified({
    super.key,
    required this.label,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  }) : variant = CivicFixStatusChipVariant.verified;

  const CivicFixStatusChip.processing({
    super.key,
    required this.label,
    this.icon,
    this.showIcon = true,
    this.isCompact = false,
    this.onTap,
  }) : variant = CivicFixStatusChipVariant.processing;

  Color _getBackgroundColor() {
    return CivicFixColors.surfaceWhite;
  }

  Color _getTextColor() {
    switch (variant) {
      case CivicFixStatusChipVariant.success:
        return CivicFixColors.success;
      case CivicFixStatusChipVariant.warning:
        return CivicFixColors.warning;
      case CivicFixStatusChipVariant.error:
        return CivicFixColors.error;
      case CivicFixStatusChipVariant.info:
        return CivicFixColors.info;
      case CivicFixStatusChipVariant.neutral:
        return CivicFixColors.badgeNeutralText;
      case CivicFixStatusChipVariant.verified:
        return CivicFixColors.badgeVerifiedText;
      case CivicFixStatusChipVariant.processing:
        return CivicFixColors.badgeProcessingText;
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case CivicFixStatusChipVariant.success:
        return CivicFixColors.successBorder;
      case CivicFixStatusChipVariant.warning:
        return CivicFixColors.warningBorder;
      case CivicFixStatusChipVariant.error:
        return CivicFixColors.error.withValues(alpha: 0.35);
      case CivicFixStatusChipVariant.info:
        return CivicFixColors.infoBorder;
      case CivicFixStatusChipVariant.neutral:
        return CivicFixColors.badgeNeutralBorder;
      case CivicFixStatusChipVariant.verified:
        return CivicFixColors.badgeVerifiedBorder;
      case CivicFixStatusChipVariant.processing:
        return CivicFixColors.badgeProcessingBorder;
    }
  }

  IconData? _getDefaultIcon() {
    if (!showIcon) return null;
    if (icon != null) return icon;

    switch (variant) {
      case CivicFixStatusChipVariant.success:
        return Icons.check_circle_outline_rounded;
      case CivicFixStatusChipVariant.warning:
        return Icons.warning_amber_rounded;
      case CivicFixStatusChipVariant.error:
        return Icons.cancel_outlined;
      case CivicFixStatusChipVariant.info:
        return Icons.info_outline_rounded;
      case CivicFixStatusChipVariant.neutral:
        return Icons.circle_outlined;
      case CivicFixStatusChipVariant.verified:
        return Icons.verified_rounded;
      case CivicFixStatusChipVariant.processing:
        return Icons.sync_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = _getDefaultIcon();
    final textColor = _getTextColor();
    final bgColor = _getBackgroundColor();
    final borderColor = _getBorderColor();

    final chipWidget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.spaceSm : CivicFixSpacing.md,
        vertical: isCompact ? CivicFixSpacing.spaceXs : CivicFixSpacing.spaceXs + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: CivicFixRadius.chipRadius,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveIcon != null) ...[
            Icon(
              effectiveIcon,
              size: isCompact ? 12 : 14,
              color: textColor,
            ),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CivicFixTypographyTokens.labelSm.copyWith(
                color: textColor,
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: CivicFixRadius.chipRadius,
        child: chipWidget,
      );
    }

    return chipWidget;
  }
}
