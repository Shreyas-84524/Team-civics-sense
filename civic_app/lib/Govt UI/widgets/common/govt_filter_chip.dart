import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Interactive filter chip tailored for Government UI filter toolbars.
class GovtFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final int? count;
  final IconData? icon;
  final Color? activeColor;

  const GovtFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelected,
    this.count,
    this.icon,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = activeColor ?? GovtThemeTokens.primary;

    return InkWell(
      onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
      borderRadius: GovtThemeTokens.chipRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md,
          vertical: CivicFixSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : GovtThemeTokens.surface,
          borderRadius: GovtThemeTokens.chipRadius,
          border: Border.all(
            color: isSelected ? selectedColor : GovtThemeTokens.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : GovtThemeTokens.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: CivicFixTypography.captionMedium.copyWith(
                color: isSelected ? Colors.white : GovtThemeTokens.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFEFF3F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
