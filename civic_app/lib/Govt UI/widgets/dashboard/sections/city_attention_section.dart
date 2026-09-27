import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../services/government_city_dashboard_service.dart';
import '../../common/government_alert.dart';

/// Section rendering urgent alerts and high-priority statutory notifications.
class CityAttentionSection extends StatelessWidget {
  final List<CityAlertItem> alerts;
  final ValueChanged<String>? onDismissAlert;
  final ValueChanged<CityAlertItem>? onAlertAction;

  const CityAttentionSection({
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < alerts.length; i++) ...[
          _buildAlert(alerts[i]),
          if (i < alerts.length - 1) CivicFixSpacing.vSpaceSm,
        ],
      ],
    );
  }

  Widget _buildAlert(CityAlertItem alert) {
    GovernmentAlertType type;
    switch (alert.severity.toLowerCase()) {
      case 'critical':
        type = GovernmentAlertType.critical;
        break;
      case 'warning':
        type = GovernmentAlertType.warning;
        break;
      case 'success':
        type = GovernmentAlertType.success;
        break;
      default:
        type = GovernmentAlertType.info;
    }

    return GovernmentAlert(
      title: alert.title,
      message: alert.message,
      type: type,
      onDismiss: onDismissAlert != null ? () => onDismissAlert!(alert.id) : null,
      action: onAlertAction != null
          ? TextButton(
              onPressed: () => onAlertAction!(alert),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              child: const Text('View Queue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}
