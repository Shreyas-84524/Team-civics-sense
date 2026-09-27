import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Cross-Ward Issues and Hotspot Coordination Section for Zonal DMC Command Center.
class ZoneCrossWardIssuesSection extends StatelessWidget {
  final List<CrossWardIssueData> issues;
  final bool isLoading;

  const ZoneCrossWardIssuesSection({
    super.key,
    required this.issues,
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
                child: const Icon(Icons.share_location_rounded, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CROSS-WARD ISSUES & HOTSPOT COORDINATION',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Incidents spanning adjacent ward boundaries requiring synchronized zonal intervention',
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
                  '${issues.length} Clusters',
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

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (issues.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: GovtThemeTokens.success, size: 40),
                    CivicFixSpacing.vSpaceMd,
                    Text(
                      'No Cross-Ward Incidents Detected',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.success,
                      ),
                    ),
                    Text(
                      'All current grievances are localized to individual wards without multi-ward arterial impact.',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) {
                final item = issues[index];
                final isCritical = item.severity == 'critical';

                return Container(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCritical
                          ? GovtThemeTokens.error.withValues(alpha: 0.3)
                          : GovtThemeTokens.borderLight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCritical ? GovtThemeTokens.error : GovtThemeTokens.warning)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.connect_without_contact_rounded,
                          color: isCritical ? GovtThemeTokens.error : GovtThemeTokens.warning,
                          size: 20,
                        ),
                      ),
                      CivicFixSpacing.hSpaceMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: CivicFixTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: GovtThemeTokens.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.complaintCount} Grievances',
                                    style: CivicFixTypography.caption.copyWith(
                                      color: GovtThemeTokens.primaryDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              item.description,
                              style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                            ),
                            CivicFixSpacing.vSpaceSm,
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: GovtThemeTokens.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: GovtThemeTokens.border),
                                  ),
                                  child: Text(
                                    'Dept: ${item.departmentName}',
                                    style: CivicFixTypography.caption.copyWith(
                                      color: GovtThemeTokens.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                ...item.affectedWardCodes.map(
                                  (code) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Ward $code',
                                      style: CivicFixTypography.caption.copyWith(
                                        color: GovtThemeTokens.primaryDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
