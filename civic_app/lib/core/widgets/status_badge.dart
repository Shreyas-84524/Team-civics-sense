import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../localization/mappers/canonical_display_mappers.dart';
import '../models/complaint_model.dart';

/// Status badge displaying icon, label text, and contextual styling.
class StatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  final String? customLabel;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = customLabel ?? localizedComplaintStatus(status, context: context);
    final badgeColor = ComplaintStatus.inProgress.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.sm : CivicFixSpacing.md,
        vertical: isCompact ? CivicFixSpacing.xs : CivicFixSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: CivicFixColors.surfaceWhite,
        borderRadius: CivicFixRadius.chipRadius,
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: isCompact ? 13 : 15,
            color: badgeColor,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CivicFixTypography.statusBadge.copyWith(
                color: badgeColor,
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
