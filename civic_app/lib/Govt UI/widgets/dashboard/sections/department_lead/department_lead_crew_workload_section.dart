import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_lead_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "My Crew" Section for Ward Department Lead Operations Center.
/// Displays the canonical 5 authorized ground crew technicians attached to
/// this Ward × Department operational unit, their live workloads, and availability statuses.
class DepartmentLeadCrewWorkloadSection extends StatelessWidget {
  final List<CrewWorkloadItem> crewWorkloads;
  final bool isLoading;
  final ValueChanged<CrewWorkloadItem>? onCrewSelected;

  const DepartmentLeadCrewWorkloadSection({
    super.key,
    required this.crewWorkloads,
    this.isLoading = false,
    this.onCrewSelected,
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
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.people_outline_rounded,
                    color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY CREW — AUTHORIZED FIELD TECHNICIANS',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Direct operational oversight of ground crew capacity and job allocations',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${crewWorkloads.length} Authorized Technicians',
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
          CivicFixSpacing.vSpaceMd,

          if (isMobile) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: crewWorkloads.length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (ctx, i) {
                final item = crewWorkloads[i];
                return _buildCrewCard(item);
              },
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth < 1100 ? 2 : 3,
                    crossAxisSpacing: CivicFixSpacing.md,
                    mainAxisSpacing: CivicFixSpacing.md,
                    childAspectRatio: constraints.maxWidth < 1100 ? 1.6 : 1.7,
                  ),
                  itemCount: crewWorkloads.length,
                  itemBuilder: (ctx, i) {
                    final item = crewWorkloads[i];
                    return _buildCrewCard(item);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCrewCard(CrewWorkloadItem item) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    GovtThemeTokens.primary.withValues(alpha: 0.12),
                child: Text(
                  item.crewUser.initials,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ID: ${item.employeeId}',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.availabilityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.availabilityStatus,
                  style: CivicFixTypography.caption.copyWith(
                    color: item.availabilityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceSm,
          Row(
            children: [
              Expanded(
                child: _metricTile(
                    'Assigned', '${item.assignedJobs}', const Color(0xFF3B82F6)),
              ),
              Expanded(
                child: _metricTile(
                    'In Progress', '${item.inProgress}', const Color(0xFF6366F1)),
              ),
              Expanded(
                child: _metricTile('Awaiting', '${item.awaitingVerification}',
                    const Color(0xFF8B5CF6)),
              ),
              Expanded(
                child: _metricTile('Done Today', '${item.completedToday}',
                    const Color(0xFF10B981)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: CivicFixTypography.h3.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
