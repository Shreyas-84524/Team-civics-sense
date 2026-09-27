import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// SLA Status classification for municipal compliance.
enum GovtSlaStatus {
  healthy,
  warning,
  breached;

  bool get isHealthy => this == GovtSlaStatus.healthy;
  bool get isWarning => this == GovtSlaStatus.warning;
  bool get isBreached => this == GovtSlaStatus.breached;

  String get label {
    switch (this) {
      case GovtSlaStatus.healthy:
        return 'SLA Healthy';
      case GovtSlaStatus.warning:
        return 'SLA Warning';
      case GovtSlaStatus.breached:
        return 'SLA Breached';
    }
  }

  Color get color {
    switch (this) {
      case GovtSlaStatus.healthy:
        return GovtThemeTokens.slaHealthy;
      case GovtSlaStatus.warning:
        return GovtThemeTokens.slaWarning;
      case GovtSlaStatus.breached:
        return GovtThemeTokens.slaBreached;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case GovtSlaStatus.healthy:
        return GovtThemeTokens.slaHealthyBg;
      case GovtSlaStatus.warning:
        return GovtThemeTokens.slaWarningBg;
      case GovtSlaStatus.breached:
        return GovtThemeTokens.slaBreachedBg;
    }
  }

  IconData get icon {
    switch (this) {
      case GovtSlaStatus.healthy:
        return Icons.timer_outlined;
      case GovtSlaStatus.warning:
        return Icons.timer_outlined;
      case GovtSlaStatus.breached:
        return Icons.warning_amber_rounded;
    }
  }
}

/// Reusable SLA badge component for government tables, details, and cards.
class GovtSlaBadge extends StatelessWidget {
  final GovtSlaStatus status;
  final String? customLabel;
  final bool isCompact;

  const GovtSlaBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.isCompact = false,
  });

  factory GovtSlaBadge.healthy({String? remainingText, bool isCompact = false}) =>
      GovtSlaBadge(
        status: GovtSlaStatus.healthy,
        customLabel: remainingText,
        isCompact: isCompact,
      );

  factory GovtSlaBadge.warning({String? remainingText, bool isCompact = false}) =>
      GovtSlaBadge(
        status: GovtSlaStatus.warning,
        customLabel: remainingText,
        isCompact: isCompact,
      );

  factory GovtSlaBadge.breached({String? overdueText, bool isCompact = false}) =>
      GovtSlaBadge(
        status: GovtSlaStatus.breached,
        customLabel: overdueText,
        isCompact: isCompact,
      );

  /// Calculates SLA status dynamically from creation timestamp and optional SLA target.
  factory GovtSlaBadge.fromDuration({
    required DateTime createdAt,
    Duration targetDuration = const Duration(hours: 48),
    DateTime? resolvedAt,
    bool isCompact = false,
  }) {
    final now = resolvedAt ?? DateTime.now();
    final elapsed = now.difference(createdAt);
    final remaining = targetDuration - elapsed;

    if (remaining.isNegative) {
      final hoursOver = (-remaining.inHours).clamp(1, 999);
      return GovtSlaBadge.breached(
        overdueText: 'Breached (+${hoursOver}h)',
        isCompact: isCompact,
      );
    } else if (remaining.inHours < 6) {
      return GovtSlaBadge.warning(
        remainingText: '< ${remaining.inHours + 1}h left',
        isCompact: isCompact,
      );
    } else {
      return GovtSlaBadge.healthy(
        remainingText: '${remaining.inHours}h left',
        isCompact: isCompact,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel = customLabel ?? status.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.sm : CivicFixSpacing.md,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(
          color: status.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: isCompact ? 12 : 14,
            color: status.color,
          ),
          SizedBox(width: isCompact ? 4 : 5),
          Text(
            displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GovtTypography.caption.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11 : 12,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
