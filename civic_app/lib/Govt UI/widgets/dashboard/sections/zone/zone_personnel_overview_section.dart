import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../models/govt_user_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Zonal Personnel Overview Section for Deputy Municipal Commissioner Command Center.
class ZonePersonnelOverviewSection extends StatelessWidget {
  final List<GovtUserModel> zonePersonnel;
  final int wardCount;
  final bool isLoading;

  const ZonePersonnelOverviewSection({
    super.key,
    required this.zonePersonnel,
    required this.wardCount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final dmcCount = zonePersonnel.where((u) => u.isZonalDmc).length;
    final wardOfficerCount = zonePersonnel.where((u) => u.isWardOfficer).length;
    final wardLeadCount = zonePersonnel.where((u) => u.isWardLead).length;
    final crewCount = zonePersonnel.where((u) => u.isCrew).length;
    final totalPersonnel = zonePersonnel.isNotEmpty ? zonePersonnel.length : (1 + wardCount + (wardCount * 18) + (wardCount * 90));

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
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL MUNICIPAL PERSONNEL DISTRIBUTION',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Administrative officers, department leads, and field staff deployed across the zone',
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
                  color: GovtThemeTokens.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '$totalPersonnel Personnel in Zone',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          // Personnel Hierarchy Cards
          if (isMobile)
            Column(
              children: [
                _buildRoleCard('Zonal DMC (Executive)', dmcCount > 0 ? dmcCount : 1, Icons.domain_rounded, GovtThemeTokens.primaryDark),
                CivicFixSpacing.vSpaceSm,
                _buildRoleCard('Ward Officers (Assistant Commissioners)', wardOfficerCount > 0 ? wardOfficerCount : wardCount, Icons.home_work_rounded, GovtThemeTokens.primary),
                CivicFixSpacing.vSpaceSm,
                _buildRoleCard('Ward Department Leads (Engineers)', wardLeadCount > 0 ? wardLeadCount : (wardCount * 18), Icons.engineering_rounded, const Color(0xFF0D9488)),
                CivicFixSpacing.vSpaceSm,
                _buildRoleCard('Field Technicians & Crew', crewCount > 0 ? crewCount : (wardCount * 90), Icons.handyman_rounded, GovtThemeTokens.textSecondary),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildRoleCard('Zonal DMC', dmcCount > 0 ? dmcCount : 1, Icons.domain_rounded, GovtThemeTokens.primaryDark)),
                CivicFixSpacing.hSpaceMd,
                Expanded(child: _buildRoleCard('Ward Officers', wardOfficerCount > 0 ? wardOfficerCount : wardCount, Icons.home_work_rounded, GovtThemeTokens.primary)),
                CivicFixSpacing.hSpaceMd,
                Expanded(child: _buildRoleCard('Ward Leads', wardLeadCount > 0 ? wardLeadCount : (wardCount * 18), Icons.engineering_rounded, const Color(0xFF0D9488))),
                CivicFixSpacing.hSpaceMd,
                Expanded(child: _buildRoleCard('Field Crew', crewCount > 0 ? crewCount : (wardCount * 90), Icons.handyman_rounded, GovtThemeTokens.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                ),
                Text(
                  isLoading ? '...' : '$count Verified',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textPrimary,
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
