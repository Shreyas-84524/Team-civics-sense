import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Ward Department Leads Directory (18 Leads) for Assistant Commissioner / Ward Officer.
class WardLeadDirectorySection extends StatelessWidget {
  final List<WardDepartmentLeadItem> departmentLeads;
  final bool isLoading;
  final ValueChanged<WardDepartmentLeadItem>? onInspectLead;

  const WardLeadDirectorySection({
    super.key,
    required this.departmentLeads,
    this.isLoading = false,
    this.onInspectLead,
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
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.contact_phone_outlined, color: GovtThemeTokens.primary, size: 20),
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
                          'WARD DEPARTMENT LEADS DIRECTORY',
                          style: CivicFixTypography.h3.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${departmentLeads.length} LEADS',
                            style: TextStyle(
                              color: GovtThemeTokens.primaryDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Direct contact directory and operational workload across all 18 Ward Department Leads',
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
          else if (departmentLeads.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: Center(
                child: Text('No department leads found.', style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted)),
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
                    mainAxisExtent: 175,
                  ),
                  itemCount: departmentLeads.length,
                  itemBuilder: (context, index) => _buildLeadCard(departmentLeads[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(WardDepartmentLeadItem lead) {
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
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: GovtThemeTokens.primary,
                child: Text(
                  lead.lead.initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.leadName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      lead.departmentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.primary, fontWeight: FontWeight.w600, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text(lead.phone, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10)),
          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _pill('Open', '${lead.openComplaints}', GovtThemeTokens.primary),
              _pill('Critical', '${lead.criticalComplaints}', lead.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted),
              _pill('Breached', '${lead.slaBreachedComplaints}', lead.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted),
              _pill('Crew Jobs', '${lead.crewLoad}', GovtThemeTokens.secondary),
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
