import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import 'zone_ward_drilldown_dialog.dart';

/// Ward Officer Directory Section for Deputy Municipal Commissioner Command Center.
/// Lists all Assistant Commissioners presiding over wards in the DMC's zone.
class ZoneWardOfficerDirectorySection extends StatelessWidget {
  final String zoneId;
  final List<WardOfficerInfo> wardOfficers;
  final bool isLoading;
  final GovernmentZoneDashboardService? dashboardService;

  const ZoneWardOfficerDirectorySection({
    super.key,
    required this.zoneId,
    required this.wardOfficers,
    this.isLoading = false,
    this.dashboardService,
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
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL WARD OFFICERS DIRECTORY',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Assistant Commissioners presiding over the administrative wards in this zone',
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
                  '${wardOfficers.length} Ward Officers',
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
          else if (wardOfficers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Text(
                  'No ward officers assigned to this zone.',
                  style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wardOfficers.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) {
                final officer = wardOfficers[index];
                return _buildOfficerCard(context, officer, isMobile);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOfficerCard(BuildContext context, WardOfficerInfo officer, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: GovtThemeTokens.primary,
                radius: 18,
                child: Text(
                  officer.officerName.isNotEmpty ? officer.officerName[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officer.officerName,
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    Text(
                      'Assistant Commissioner · Ward ${officer.wardCode} (${officer.wardName})',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  officer.employeeId,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.primaryDark,
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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _metricPill('Active Complaints', '${officer.openComplaints}', GovtThemeTokens.textPrimary),
              _metricPill(
                'SLA Compliance',
                officer.slaComplianceRate != null ? '${officer.slaComplianceRate!.toStringAsFixed(0)}%' : 'N/A',
                (officer.slaComplianceRate ?? 100) >= 80 ? GovtThemeTokens.success : GovtThemeTokens.warning,
              ),
              _metricPill('Escalations', '${officer.escalatedCount}', officer.escalatedCount > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
              ElevatedButton(
                onPressed: () {
                  ZoneWardDrilldownDialog.show(
                    context,
                    ward: officer.ward,
                    zoneId: zoneId,
                    dashboardService: dashboardService,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Inspect Ward'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10)),
        Text(
          value,
          style: CivicFixTypography.captionMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
