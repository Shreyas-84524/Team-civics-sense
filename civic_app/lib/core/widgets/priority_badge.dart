import 'package:flutter/material.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../models/complaint_model.dart';

/// Reusable priority badge displaying priority level with semantic icon,
/// background tint, and high-contrast text.
class PriorityBadge extends StatelessWidget {
  final ComplaintPriority priority;
  final bool isCompact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.isCompact = false,
  });

  Color get _backgroundColor {
    switch (priority) {
      case ComplaintPriority.low:
        return const Color(0xFFEFF3F0);
      case ComplaintPriority.medium:
        return const Color(0xFFE8F2F8);
      case ComplaintPriority.high:
        return const Color(0xFFFEF8EC);
      case ComplaintPriority.emergency:
        return const Color(0xFFFDE8E8);
    }
  }

  IconData get _icon {
    switch (priority) {
      case ComplaintPriority.low:
        return Icons.arrow_downward_rounded;
      case ComplaintPriority.medium:
        return Icons.remove_rounded;
      case ComplaintPriority.high:
        return Icons.arrow_upward_rounded;
      case ComplaintPriority.emergency:
        return Icons.warning_amber_rounded;
    }
  }

  String get _displayLabel {
    switch (priority) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';
      case ComplaintPriority.emergency:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = priority.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.sm : CivicFixSpacing.md,
        vertical: isCompact ? CivicFixSpacing.xs : CivicFixSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: CivicFixRadius.chipRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: isCompact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: isCompact ? 3 : 5),
          Flexible(
            child: Text(
              _displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CivicFixTypography.statusBadge.copyWith(
                color: color,
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
