import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/mappers/canonical_display_mappers.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/status_badge.dart';
import '../models/home_data_model.dart';

/// Compact card displaying a nearby civic hazard preview.
/// Matches the design of the Recent Complaints preview card.
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
    final displayCategory = localizedCategory(hazard.category, context: context);

    return CivicFixCard(
      onTap: onTap ??
          () {
            Navigator.pushNamed(context, AppRoutes.hazardMap);
          },
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hazard.title,
                  style: CivicFixTypography.bodyLargeMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CivicFixColors.primaryText,
                    height: 1.3,
                  ),
                  maxLines: 2,
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
          CivicFixSpacing.vSpaceMd,

          // Bottom Row: Category & Distance / Ward Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category tag
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hazard.category.icon,
                    size: 14,
                    color: CivicFixColors.secondaryText,
                  ),
                  CivicFixSpacing.hSpaceXs,
                  Text(
                    displayCategory,
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              CivicFixSpacing.hSpaceSm,

              // Distance & Locality / Ward
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CivicFixColors.primary.withValues(alpha: 0.08),
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
                    if (hazard.locality.isNotEmpty) ...[
                      CivicFixSpacing.hSpaceSm,
                      Flexible(
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

