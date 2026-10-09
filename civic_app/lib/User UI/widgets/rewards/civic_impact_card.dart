import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/reward_model.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Card summarizing the citizen's real-world civic impact across all complaints.
///
/// Metrics derived from existing CivicFix data:
/// - Complaints Submitted
/// - Complaints Verified
/// - Complaints Resolved
/// - Community Upvotes
/// - Achievements Unlocked
class CivicImpactCard extends StatelessWidget {
  final CivicImpactSummary impact;

  const CivicImpactCard({
    super.key,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CivicFixColors.primary.withValues(alpha: 0.1),
                  borderRadius: CivicFixRadius.chipRadius,
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: CivicFixColors.primary,
                  size: 18,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Text(
                'Civic Impact',
                style: CivicFixTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: CivicFixColors.primaryText,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // 5-Metric Responsive Grid/Row Layout
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Submitted',
                  value: '${impact.complaintsSubmitted}',
                  icon: Icons.send_rounded,
                  color: CivicFixColors.info,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildMetricItem(
                  label: 'Verified',
                  value: '${impact.complaintsVerified}',
                  icon: Icons.verified_rounded,
                  color: CivicFixColors.primary,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildMetricItem(
                  label: 'Resolved',
                  value: '${impact.complaintsResolved}',
                  icon: Icons.task_alt_rounded,
                  color: CivicFixColors.secondary,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          Container(height: 1, color: CivicFixColors.border),
          CivicFixSpacing.vSpaceMd,
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Community Upvotes',
                  value: '${impact.communityUpvotes}',
                  icon: Icons.thumb_up_alt_rounded,
                  color: CivicFixColors.accent,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildMetricItem(
                  label: 'Achievements',
                  value: '${impact.achievementsUnlocked}',
                  icon: Icons.emoji_events_rounded,
                  color: CivicFixColors.alertDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: CivicFixColors.border,
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: CivicFixTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: CivicFixColors.primaryText,
                height: 1.1,
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          label,
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
