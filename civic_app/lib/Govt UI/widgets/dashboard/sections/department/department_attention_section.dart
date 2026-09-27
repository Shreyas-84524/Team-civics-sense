import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Active early warning alerts and high-priority operational notifications for HOD.
class DepartmentAttentionSection extends StatelessWidget {
  final List<DepartmentAttentionAlert> alerts;
  final ValueChanged<String>? onDismissAlert;
  final ValueChanged<String>? onWardAlertTap;

  const DepartmentAttentionSection({
    super.key,
    required this.alerts,
    this.onDismissAlert,
    this.onWardAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alerts.map((alert) {
        final isCritical = alert.severity == 'critical';
        final isWarning = alert.severity == 'warning';

        final bgColor = isCritical
            ? GovtThemeTokens.error.withValues(alpha: 0.08)
            : isWarning
                ? GovtThemeTokens.warning.withValues(alpha: 0.08)
                : GovtThemeTokens.info.withValues(alpha: 0.08);

        final borderColor = isCritical
            ? GovtThemeTokens.error.withValues(alpha: 0.3)
            : isWarning
                ? GovtThemeTokens.warning.withValues(alpha: 0.3)
                : GovtThemeTokens.info.withValues(alpha: 0.3);

        final iconColor = isCritical
            ? GovtThemeTokens.error
            : isWarning
                ? GovtThemeTokens.warning
                : GovtThemeTokens.info;

        return Container(
          margin: const EdgeInsets.only(bottom: CivicFixSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.sm),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(alert.icon ?? (isCritical ? Icons.error_outline_rounded : Icons.info_outline_rounded),
                  color: iconColor, size: 20),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    Text(
                      alert.message,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              if (alert.wardId != null && onWardAlertTap != null)
                TextButton(
                  onPressed: () => onWardAlertTap!(alert.wardId!),
                  child: const Text('Inspect Ward'),
                ),
              if (onDismissAlert != null)
                IconButton(
                  onPressed: () => onDismissAlert!(alert.id),
                  icon: const Icon(Icons.close_rounded, size: 16, color: GovtThemeTokens.textMuted),
                  tooltip: 'Dismiss alert',
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
