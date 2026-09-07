import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// 3-column civic contribution statistics card for Citizen Profile.
class ProfileStatCard extends StatelessWidget {
  final int reportsSubmitted;
  final int reportsResolved;
  final int civicPoints;
  final VoidCallback? onRewardsTap;

  const ProfileStatCard({
    super.key,
    required this.reportsSubmitted,
    required this.reportsResolved,
    required this.civicPoints,
    this.onRewardsTap,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Civic Contribution',
                style: CivicFixTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CivicFixColors.primaryText,
                ),
              ),
              if (onRewardsTap != null)
                InkWell(
                  onTap: onRewardsTap,
                  borderRadius: CivicFixRadius.chipRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          'View Achievements',
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: CivicFixColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: CivicFixColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Reports',
                  value: '$reportsSubmitted',
                  icon: Icons.assignment_outlined,
                  color: CivicFixColors.info,
                ),
              ),
              Container(width: 1, height: 48, color: CivicFixColors.border),
              Expanded(
                child: _buildStatItem(
                  label: 'Resolved',
                  value: '$reportsResolved',
                  icon: Icons.check_circle_outline_rounded,
                  color: CivicFixColors.secondary,
                ),
              ),
              Container(width: 1, height: 48, color: CivicFixColors.border),
              Expanded(
                child: _buildStatItem(
                  label: 'Civic Points',
                  value: '$civicPoints',
                  icon: Icons.stars_rounded,
                  color: CivicFixColors.alertDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: CivicFixTypography.h3.copyWith(
                  color: CivicFixColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            label,
            style: CivicFixTypography.caption.copyWith(
              color: CivicFixColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
