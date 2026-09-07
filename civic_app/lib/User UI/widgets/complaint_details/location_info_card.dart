import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/location/location_model.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Location summary card for complaint details with 'View Location' map trigger.
class LocationInfoCard extends StatelessWidget {
  final CivicLocation location;

  const LocationInfoCard({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final displayAddress = location.shortDisplayAddress.isNotEmpty
        ? location.shortDisplayAddress
        : (location.address.isNotEmpty ? location.address : 'Location selected.');

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Location',
                style: CivicFixTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CivicFixColors.primaryText,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.selectLocation,
                    arguments: location,
                  );
                },
                borderRadius: CivicFixRadius.chipRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 14,
                        color: CivicFixColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View Location',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CivicFixColors.surfaceMuted,
                  borderRadius: CivicFixRadius.chipRadius,
                  border: Border.all(color: CivicFixColors.border),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: CivicFixColors.primary,
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayAddress,
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CivicFixColors.primaryText,
                      ),
                    ),
                    if (location.landmark != null && location.landmark!.isNotEmpty) ...[
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Landmark: ${location.landmark}',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                        ),
                      ),
                    ],
                    if (location.ward != null && location.ward!.isNotEmpty) ...[
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Jurisdiction: ${location.ward}',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
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
