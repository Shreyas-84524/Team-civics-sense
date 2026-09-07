import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Privacy & Data Governance Principles for Government Portal.
class GovtPrivacyPrinciplesWidget extends StatelessWidget {
  const GovtPrivacyPrinciplesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Privacy & Municipal Data Governance Principles',
      subtitle: 'Mandatory civic data protection and confidentiality standards',
      child: Column(
        children: [
          _buildPrincipleTile(
            icon: Icons.filter_alt_outlined,
            title: 'Data Minimization',
            description:
                'Only essential grievance context and geolocation coordinates necessary for municipal inspection and resolution are exposed.',
            badgeColor: GovtThemeTokens.primary,
          ),
          CivicFixSpacing.vSpaceMd,
          _buildPrincipleTile(
            icon: Icons.security_rounded,
            title: 'Citizen Privacy Restrictions',
            description:
                'Citizen identity, personal contact details, and private residence data are strictly masked to prevent unauthorized disclosure or profiling.',
            badgeColor: GovtThemeTokens.secondary,
          ),
          CivicFixSpacing.vSpaceMd,
          _buildPrincipleTile(
            icon: Icons.verified_user_outlined,
            title: 'Authorized Role-Based Access',
            description:
                'Administrative actions, status transitions, department dispatches, and verification reviews are immutably signed with verified officer tokens.',
            badgeColor: GovtThemeTokens.accent,
          ),
          CivicFixSpacing.vSpaceMd,
          _buildPrincipleTile(
            icon: Icons.shield_outlined,
            title: 'Evidence Protection & Audit Integrity',
            description:
                'Photographic evidence, resolution timestamp proofs, and field inspection remarks are safeguarded against tampering.',
            badgeColor: GovtThemeTokens.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipleTile({
    required IconData icon,
    required String title,
    required String description,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
            ),
            child: Icon(icon, color: badgeColor, size: 20),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  description,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
