import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Field Crew Distribution and Workload across all 18 Departments inside the Ward (90 Technicians).
class WardCrewDistributionSection extends StatelessWidget {
  final List<DepartmentCrewWorkloadData> crewDistribution;
  final bool isLoading;

  const WardCrewDistributionSection({
    super.key,
    required this.crewDistribution,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.handyman_rounded, color: GovtThemeTokens.secondary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'FIELD CREW WORKLOAD & ROSTER',
                          style: CivicFixTypography.h3.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: GovtThemeTokens.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '90 TECHNICIANS',
                            style: TextStyle(
                              color: GovtThemeTokens.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Operational job allocation and availability across 18 department crew units (5 technicians per department)',
                      style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (crewDistribution.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: Center(
                child: Text('No crew workload data available.', style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int count = 3;
                if (width >= 1200) {
                  count = 3;
                } else if (width >= 750) {
                  count = 2;
                } else {
                  count = 1;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: CivicFixSpacing.md,
                    mainAxisSpacing: CivicFixSpacing.md,
                    mainAxisExtent: 145,
                  ),
                  itemCount: crewDistribution.length,
                  itemBuilder: (context, index) => _buildDeptCrewCard(crewDistribution[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeptCrewCard(DepartmentCrewWorkloadData data) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.departmentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('5 Technicians', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _pill('Assigned', '${data.assignedJobsCount}', GovtThemeTokens.info),
              _pill('In Progress', '${data.inProgressJobsCount}', GovtThemeTokens.statusInProgress),
              _pill('Awaiting Verif', '${data.awaitingVerificationJobsCount}', const Color(0xFF7C3AED)),
              _pill('Available', '${data.availableCrewCount}', GovtThemeTokens.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
