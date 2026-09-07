import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Reusable KPI metric card for the Government Dashboard.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final String? trendText;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor = GovtThemeTokens.primary,
    this.subtitle,
    this.trendText,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: GovtThemeTokens.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: GovtThemeTokens.cardRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: GovtThemeTokens.cardRadius,
            border: Border.all(color: GovtThemeTokens.border),
            boxShadow: GovtThemeTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: CivicFixTypography.display.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.textPrimary,
                  height: 1.1,
                ),
              ),
              if (subtitle != null || trendText != null)
                Row(
                  children: [
                    if (trendText != null) ...[
                      Icon(
                        isPositiveTrend
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: isPositiveTrend
                            ? GovtThemeTokens.secondary
                            : GovtThemeTokens.alert,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trendText!,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: isPositiveTrend
                              ? GovtThemeTokens.secondary
                              : GovtThemeTokens.alert,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
