import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'govt_loading_states.dart';

/// Highly reusable KPI metric card for government command dashboards.
class GovernmentKpiCard extends StatelessWidget {
  final String title;
  final String metric;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? percentageChange;
  final bool? isPositiveChange;
  final String? percentageLabel;
  final String? status;
  final Color? statusColor;
  final String? supportingText;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onTap;

  const GovernmentKpiCard({
    super.key,
    required this.title,
    required this.metric,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.percentageChange,
    this.isPositiveChange,
    this.percentageLabel,
    this.status,
    this.statusColor,
    this.supportingText,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const GovtKpiSkeleton();
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return _buildErrorState(context);
    }

    final accentColor = iconColor ?? GovtThemeTokens.primary;
    final bgIconColor = iconBackgroundColor ?? accentColor.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: GovtThemeTokens.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
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
            // Top Row: Title & Icon Container
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GovtTypography.cardTitle.copyWith(
                      color: GovtThemeTokens.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgIconColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: accentColor,
                  ),
                ),
              ],
            ),

            CivicFixSpacing.vSpaceSm,

            // Primary Metric
            Text(
              metric,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GovtTypography.metricLarge.copyWith(
                color: GovtThemeTokens.textPrimary,
                fontSize: 26,
              ),
            ),

            CivicFixSpacing.vSpaceSm,

            // Bottom Supporting Metadata / Trend / Status
            Row(
              children: [
                if (percentageChange != null) ...[
                  _buildTrendPill(),
                  if (percentageLabel != null) ...[
                    CivicFixSpacing.hSpaceXs,
                    Flexible(
                      child: Text(
                        percentageLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GovtTypography.caption.copyWith(
                          fontSize: 11,
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ] else if (status != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (statusColor ?? GovtThemeTokens.info).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status!,
                      style: GovtTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor ?? GovtThemeTokens.info,
                      ),
                    ),
                  ),
                ],

                if (supportingText != null && percentageChange == null && status == null)
                  Expanded(
                    child: Text(
                      supportingText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GovtTypography.caption.copyWith(
                        fontSize: 11,
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendPill() {
    final isPositive = isPositiveChange ?? (percentageChange! >= 0);
    final color = isPositive ? GovtThemeTokens.success : GovtThemeTokens.error;
    final bg = isPositive ? const Color(0xFFE8F8F0) : const Color(0xFFFDE8E8);
    final sign = percentageChange! > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '$sign${percentageChange!.toStringAsFixed(1)}%',
            style: GovtTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.errorLight),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 24),
          CivicFixSpacing.vSpaceXs,
          Text(
            title,
            style: GovtTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
            textAlign: TextAlign.center,
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            errorMessage!,
            style: GovtTypography.caption.copyWith(color: GovtThemeTokens.error, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (onRetry != null) ...[
            CivicFixSpacing.vSpaceXs,
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Retry', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
