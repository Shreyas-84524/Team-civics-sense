import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Ward Personnel Hierarchy Overview for Ward Officer.
///
/// Displays the canonical municipal workforce breakdown for the Ward:
/// - 1 Assistant Commissioner / Ward Officer
/// - 18 Ward Department Leads
/// - 90 Field Crew Members (5 per department)
/// = 109 total municipal personnel
class WardPersonnelOverviewSection extends StatelessWidget {
  final WardPersonnelSummary personnelSummary;
  final bool isLoading;

  const WardPersonnelOverviewSection({
    super.key,
    required this.personnelSummary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = personnelSummary;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_outline_rounded, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WARD PERSONNEL & WORKFORCE OVERVIEW',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Staffing structure, operational leads, and field crew deployment in this ward',
                      style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          // 4 Workforce Hierarchy Cards
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildHierarchyCard(
                title: 'Ward Officer',
                subtitle: 'Assistant Commissioner',
                count: '1',
                activeText: 'Active Session Head',
                color: GovtThemeTokens.primaryDark,
                icon: Icons.badge_rounded,
                avatarInitials: p.wardOfficer?.initials ?? 'WO',
              ),
              _buildHierarchyCard(
                title: 'Department Leads',
                subtitle: 'Executive Engineers',
                count: '${p.leadCount}',
                activeText: '18 / 18 Units Assigned',
                color: GovtThemeTokens.primary,
                icon: Icons.engineering_rounded,
                avatarInitials: '18L',
              ),
              _buildHierarchyCard(
                title: 'Department Crew',
                subtitle: 'Field Technicians',
                count: '${p.crewCount}',
                activeText: '5 Technicians per Dept',
                color: GovtThemeTokens.secondary,
                icon: Icons.handyman_rounded,
                avatarInitials: '90C',
              ),
              _buildHierarchyCard(
                title: 'Total Workforce',
                subtitle: 'Municipal Staff in Ward',
                count: '${p.totalPersonnelCount}',
                activeText: '${p.activePersonnelCount} Verified Active',
                color: GovtThemeTokens.success,
                icon: Icons.groups_rounded,
                avatarInitials: '109',
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,

          // Staffing Health Bar
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GovtThemeTokens.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: GovtThemeTokens.success, size: 20),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Text(
                    'Full Departmental Coverage: All 18 municipal departments have dedicated Ward Department Leads and 5-member field technician rosters in place.',
                    style: CivicFixTypography.bodySmallMedium.copyWith(color: GovtThemeTokens.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyCard({
    required String title,
    required String subtitle,
    required String count,
    required String activeText,
    required Color color,
    required IconData icon,
    required String avatarInitials,
  }) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: Text(avatarInitials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          Text(
            count,
            style: CivicFixTypography.h2.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(title, style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700)),
          Text(subtitle, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 11)),
          CivicFixSpacing.vSpaceXs,
          Text(activeText, style: CivicFixTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)),
        ],
      ),
    );
  }
}
