import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// About CivicFix Portal, Versioning, Mission, Support & Legal.
class GovtAboutWidget extends StatelessWidget {
  const GovtAboutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'About CivicFix Municipal Portal',
      subtitle: 'Official municipal administration & grievance resolution framework',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branding Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary,
                  borderRadius: BorderRadius.circular(GovtThemeTokens.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CivicFix Operations Suite', style: CivicFixTypography.h3),
                    CivicFixSpacing.vSpaceXs,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: GovtThemeTokens.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                          ),
                          child: Text(
                            'v1.0.0-gov',
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: GovtThemeTokens.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        CivicFixSpacing.hSpaceSm,
                        Text(
                          'Release: Build 2026.09 (Local MVP)',
                          style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Municipal Mission
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_circle_outlined, size: 18, color: GovtThemeTokens.secondary),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      'Municipal Mission',
                      style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Empowering transparent, rapid civic grievance resolution across municipal zones through seamless citizen engagement, automated dispatch, and real-time hazard mitigation.',
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // Support Channels
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 18, color: GovtThemeTokens.primary),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      'Municipal IT Support & Helpdesk',
                      style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Official Support Email: helpdesk@civicfix.gov.in\nToll-Free Civic Helpline: 1800-CIVIC-FIX (Mon-Sat 08:00 - 20:00 IST)',
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // Legal & Governance Charter
          Text(
            '© 2026 Municipal Civic Administration. All rights reserved.\nLicensed for authorized municipal operations under the CivicFix Data Governance Charter.',
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textDisabled,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
