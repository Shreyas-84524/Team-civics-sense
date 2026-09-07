import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/status_badge.dart';
import '../models/home_data_model.dart';

/// Compact card displaying a nearby civic hazard preview.
class NearbyHazardCard extends StatelessWidget {
  final NearbyHazardModel hazard;
  final VoidCallback? onTap;

  const NearbyHazardCard({
    super.key,
    required this.hazard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      onTap: onTap ??
          () {
            Navigator.pushNamed(context, AppRoutes.hazardMap);
          },
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.lg,
        vertical: CivicFixSpacing.md,
      ),
      child: Row(
        children: [
          // Category Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CivicFixColors.alertLight,
              borderRadius: CivicFixRadius.chipRadius,
              border: Border.all(
                color: CivicFixColors.alert.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Icon(
                hazard.category.icon,
                color: CivicFixColors.alertDark,
                size: 22,
              ),
            ),
          ),
          CivicFixSpacing.hSpaceMd,

          // Hazard Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        hazard.title,
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: CivicFixColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    StatusBadge(
                      status: hazard.status,
                      isCompact: true,
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Row(
                  children: [
                    // Distance pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CivicFixColors.primary.withValues(alpha: 0.07),
                        borderRadius: CivicFixRadius.chipRadius,
                      ),
                      child: Text(
                        hazard.distanceText,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: Text(
                        hazard.locality,
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
