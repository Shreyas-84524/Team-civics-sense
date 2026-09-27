import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Early warning alerts and critical notifications for the Ward Officer.
class WardAttentionSection extends StatelessWidget {
  final List<WardAttentionAlert> alerts;
  final ValueChanged<String>? onDismissAlert;
  final ValueChanged<String>? onAlertTap;

  const WardAttentionSection({
    super.key,
    required this.alerts,
    this.onDismissAlert,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: GovtThemeTokens.error, size: 20),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Text(
                'CRITICAL WARD ATTENTION ALERTS (${alerts.length})',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceSm,
        ...alerts.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(WardAttentionAlert alert) {
    final isCritical = alert.severity == 'critical';
    final isWarning = alert.severity == 'warning';

    final Color borderColor = isCritical
        ? GovtThemeTokens.error.withValues(alpha: 0.4)
        : (isWarning ? GovtThemeTokens.warning.withValues(alpha: 0.4) : GovtThemeTokens.info.withValues(alpha: 0.4));

    final Color bgColor = isCritical
        ? GovtThemeTokens.error.withValues(alpha: 0.05)
        : (isWarning ? GovtThemeTokens.warning.withValues(alpha: 0.05) : GovtThemeTokens.info.withValues(alpha: 0.05));

    final Color iconColor = isCritical
        ? GovtThemeTokens.error
        : (isWarning ? GovtThemeTokens.warning : GovtThemeTokens.info);

    return Padding(
      padding: const EdgeInsets.only(bottom: CivicFixSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(CivicFixSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(alert.icon ?? (isCritical ? Icons.error_rounded : Icons.info_rounded),
                color: iconColor, size: 22),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    alert.message,
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onDismissAlert != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: GovtThemeTokens.textMuted),
                onPressed: () => onDismissAlert!(alert.id),
                tooltip: 'Dismiss alert',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
