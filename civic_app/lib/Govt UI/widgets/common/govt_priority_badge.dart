import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/complaint_model.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Reusable priority badge for Government operations (low, medium, high, critical).
class GovtPriorityBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool isCompact;

  const GovtPriorityBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.isCompact = false,
  });

  /// Factory constructor from [ComplaintPriority] model enum.
  factory GovtPriorityBadge.fromPriority(ComplaintPriority priority, {bool isCompact = false}) {
    switch (priority) {
      case ComplaintPriority.low:
        return GovtPriorityBadge(
          label: 'Low',
          icon: Icons.arrow_downward_rounded,
          color: GovtThemeTokens.textSecondary,
          backgroundColor: const Color(0xFFEFF3F0),
          isCompact: isCompact,
        );
      case ComplaintPriority.medium:
        return GovtPriorityBadge(
          label: 'Medium',
          icon: Icons.remove_rounded,
          color: GovtThemeTokens.info,
          backgroundColor: const Color(0xFFE8F2F8),
          isCompact: isCompact,
        );
      case ComplaintPriority.high:
        return GovtPriorityBadge(
          label: 'High',
          icon: Icons.arrow_upward_rounded,
          color: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFEF8EC),
          isCompact: isCompact,
        );
      case ComplaintPriority.emergency:
        return GovtPriorityBadge(
          label: 'Critical',
          icon: Icons.warning_amber_rounded,
          color: GovtThemeTokens.critical,
          backgroundColor: const Color(0xFFFDE8E8),
          isCompact: isCompact,
        );
    }
  }

  /// Factory constructor from string identifier ('low', 'medium', 'high', 'critical', 'emergency').
  factory GovtPriorityBadge.fromString(String? priority, {bool isCompact = false}) {
    final normalized = (priority ?? '').toLowerCase().trim();
    switch (normalized) {
      case 'low':
        return GovtPriorityBadge.fromPriority(ComplaintPriority.low, isCompact: isCompact);
      case 'medium':
        return GovtPriorityBadge.fromPriority(ComplaintPriority.medium, isCompact: isCompact);
      case 'high':
        return GovtPriorityBadge.fromPriority(ComplaintPriority.high, isCompact: isCompact);
      case 'critical':
      case 'emergency':
      default:
        if (normalized.isEmpty) {
          return GovtPriorityBadge.fromPriority(ComplaintPriority.medium, isCompact: isCompact);
        }
        return GovtPriorityBadge.fromPriority(ComplaintPriority.emergency, isCompact: isCompact);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.sm : CivicFixSpacing.md,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: isCompact ? 3 : 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GovtTypography.caption.copyWith(
              color: color,
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
