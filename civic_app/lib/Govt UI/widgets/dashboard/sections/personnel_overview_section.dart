import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../services/government_city_dashboard_service.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_section_header.dart';

/// Section providing high-level breakdown of the 2,642 BMC municipal personnel hierarchy.
class PersonnelOverviewSection extends StatelessWidget {
  final PersonnelSummary summary;
  final bool isLoading;

  const PersonnelOverviewSection({
    super.key,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      _RoleCount('Super Admin', summary.superAdminCount, 1, Icons.shield_rounded, GovtThemeTokens.primary),
      _RoleCount('Zonal DMCs', summary.zonalDmcCount, 7, Icons.domain_rounded, const Color(0xFF4338CA)),
      _RoleCount('Central HODs', summary.centralHodCount, 18, Icons.account_balance_rounded, const Color(0xFF1D4ED8)),
      _RoleCount('Ward Officers', summary.wardOfficerCount, 24, Icons.home_work_rounded, const Color(0xFF047857)),
      _RoleCount('Ward Dept Leads', summary.wardLeadCount, 432, Icons.engineering_rounded, const Color(0xFFD97706)),
      _RoleCount('Department Crew', summary.crewCount, 2160, Icons.handyman_rounded, const Color(0xFF475569)),
    ];

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
          GovernmentSectionHeader(
            title: 'Personnel Hierarchy & Roster',
            subtitle: 'Dual-supervisory municipal structure covering 2,642 verified government identities',
            count: summary.totalPersonnelCount,
            action: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: summary.integrityMatch
                    ? GovtThemeTokens.success.withValues(alpha: 0.12)
                    : GovtThemeTokens.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: summary.integrityMatch ? GovtThemeTokens.success : GovtThemeTokens.warning,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    summary.integrityMatch ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                    size: 14,
                    color: summary.integrityMatch ? GovtThemeTokens.success : GovtThemeTokens.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    summary.integrityMatch ? '2,642 Canonical Match' : 'Roster Variance Detected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: summary.integrityMatch ? GovtThemeTokens.success : GovtThemeTokens.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // 6 Role Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int cols = 6;
              if (width >= 1200) {
                cols = 6;
              } else if (width >= 800) {
                cols = 3;
              } else if (width >= 500) {
                cols = 2;
              } else {
                cols = 1;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: CivicFixSpacing.sm,
                  mainAxisSpacing: CivicFixSpacing.sm,
                  mainAxisExtent: 88,
                ),
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final r = roles[index];
                  return Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GovtThemeTokens.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${r.actualCount}',
                              style: GovtTypography.cardTitle.copyWith(
                                color: r.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Icon(r.icon, size: 16, color: r.color),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: GovtThemeTokens.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Expected: ${r.expectedCount}',
                          style: GovtTypography.caption.copyWith(
                            color: GovtThemeTokens.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          CivicFixSpacing.vSpaceMd,

          // Account summary row
          Row(
            children: [
              Expanded(
                child: _buildRosterChip(
                  'Active Accounts',
                  '${summary.activeAccountsCount} / ${summary.totalPersonnelCount}',
                  Icons.check_circle_outline_rounded,
                  GovtThemeTokens.success,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: _buildRosterChip(
                  'Operational Units',
                  '432 (24 Wards × 18 Departments)',
                  Icons.grid_view_rounded,
                  GovtThemeTokens.primary,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: _buildRosterChip(
                  'Dual Supervision',
                  'Admin (Ward Officer) + Tech (HOD)',
                  Icons.account_tree_rounded,
                  const Color(0xFF4338CA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRosterChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: GovtThemeTokens.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GovtThemeTokens.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCount {
  final String title;
  final int actualCount;
  final int expectedCount;
  final IconData icon;
  final Color color;

  const _RoleCount(this.title, this.actualCount, this.expectedCount, this.icon, this.color);
}
