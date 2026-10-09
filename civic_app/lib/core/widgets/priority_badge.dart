import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../localization/mappers/canonical_display_mappers.dart';
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
        return CivicFixColors.infoContainer;
      case ComplaintPriority.medium:
        return CivicFixColors.infoContainer;
      case ComplaintPriority.high:
        return CivicFixColors.warningContainer;
      case ComplaintPriority.emergency:
        return CivicFixColors.errorContainer;
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

  @override
  Widget build(BuildContext context) {
    final color = priority.color;
    final displayLabel = localizedComplaintPriority(priority, context: context);

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
              displayLabel,
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
