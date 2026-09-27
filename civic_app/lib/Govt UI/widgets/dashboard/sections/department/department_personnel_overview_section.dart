import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Department Personnel Hierarchy & Roster Overview Section for Central Department HOD.
/// Shows structural breakdown: 1 Central HOD, 24 Ward Leads, 120 Field Crew = 145 total personnel.
class DepartmentPersonnelOverviewSection extends StatelessWidget {
  final DepartmentPersonnelSummary personnelSummary;
  final bool isLoading;

  const DepartmentPersonnelOverviewSection({
    super.key,
    required this.personnelSummary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_outlined,
                    color: GovtThemeTokens.primaryDark, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT PERSONNEL & WORKFORCE STRENGTH',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Command hierarchy: 1 Central HOD, 24 Ward Unit Leads, 120 Field Technicians',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${personnelSummary.totalPersonnelCount} Total Staff',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = isMobile
                    ? (constraints.maxWidth - 8) / 2
                    : (constraints.maxWidth - 24) / 4;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPersonnelCard(
                      'CENTRAL HOD',
                      '1 Officer',
                      personnelSummary.hod?.fullName ?? 'Chief Engineer (You)',
                      Icons.account_balance,
                      GovtThemeTokens.primaryDark,
                      cardWidth,
                    ),
                    _buildPersonnelCard(
                      'WARD LEADS',
                      '${personnelSummary.leadCount} Officers',
                      '1 Lead per Municipal Ward (24)',
                      Icons.supervisor_account,
                      GovtThemeTokens.primary,
                      cardWidth,
                    ),
                    _buildPersonnelCard(
                      'FIELD TECHNICIANS',
                      '${personnelSummary.crewCount} Crew',
                      '5 Technicians per Ward Unit',
                      Icons.engineering,
                      GovtThemeTokens.info,
                      cardWidth,
                    ),
                    _buildPersonnelCard(
                      'ACTIVE ON DUTY',
                      '${personnelSummary.activePersonnelCount} Staff',
                      'Operational deployment 100%',
                      Icons.verified_user,
                      GovtThemeTokens.success,
                      cardWidth,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonnelCard(
    String title,
    String count,
    String subtitle,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Text(
                  title,
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text(
            count,
            style: CivicFixTypography.h2.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
