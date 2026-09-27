import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Early warning and high-priority attention alerts for Zonal DMC Command Center.
class ZoneAttentionSection extends StatelessWidget {
  final List<ZoneAttentionAlert> alerts;
  final ValueChanged<String>? onDismissAlert;
  final ValueChanged<ZoneAttentionAlert>? onAlertAction;

  const ZoneAttentionSection({
    super.key,
    required this.alerts,
    this.onDismissAlert,
    this.onAlertAction,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_active_outlined, color: GovtThemeTokens.warning, size: 20),
            CivicFixSpacing.hSpaceSm,
            Text(
              'ZONAL ATTENTION & EARLY WARNING ALERTS',
              style: CivicFixTypography.captionMedium.copyWith(
                color: GovtThemeTokens.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: GovtThemeTokens.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${alerts.length} Active',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceMd,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length,
          separatorBuilder: (context, index) => CivicFixSpacing.vSpaceSm,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertTile(context, alert);
          },
        ),
      ],
    );
  }

  Widget _buildAlertTile(BuildContext context, ZoneAttentionAlert alert) {
    final isCritical = alert.severity == 'critical';
    final isWarning = alert.severity == 'warning';

    final Color borderColor = isCritical
        ? GovtThemeTokens.error
        : (isWarning ? GovtThemeTokens.warning : GovtThemeTokens.info);

    final Color bgColor = isCritical
        ? const Color(0xFFFEF2F2)
        : (isWarning ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF));

    final Color iconColor = borderColor;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alert.icon ?? (isCritical ? Icons.emergency_rounded : Icons.warning_amber_rounded),
              color: iconColor,
              size: 20,
            ),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: CivicFixTypography.bodySmall.copyWith(
                          color: GovtThemeTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.severity.toUpperCase(),
                        style: CivicFixTypography.caption.copyWith(
                          color: borderColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  alert.message,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.hSpaceSm,
          if (onDismissAlert != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: GovtThemeTokens.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => onDismissAlert!(alert.id),
              tooltip: 'Dismiss Alert',
            ),
        ],
      ),
    );
  }
}
