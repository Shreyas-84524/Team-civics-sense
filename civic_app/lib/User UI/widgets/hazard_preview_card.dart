import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/widgets/civic_fix_card.dart';

/// Card showing hazard alert summaries.
class HazardPreviewCard extends StatelessWidget {
  final ComplaintModel hazard;
  final VoidCallback onTap;

  const HazardPreviewCard({
    super.key,
    required this.hazard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      onTap: onTap,
      borderColor: CivicFixColors.alert.withValues(alpha: 0.5),
      backgroundColor: CivicFixColors.surface,
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.sm),
            decoration: BoxDecoration(
              color: CivicFixColors.alertLight,
              borderRadius: CivicFixRadius.chipRadius,
              border: Border.all(color: CivicFixColors.alert.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: CivicFixColors.alertDark,
              size: 24,
            ),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hazard.title,
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  hazard.location.shortDisplayAddress,
                  style: CivicFixTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  '${hazard.upvotes} citizens reported/verified nearby',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.alertDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: CivicFixColors.secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }
}
