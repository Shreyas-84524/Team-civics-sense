import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import 'zone_ward_drilldown_dialog.dart';

/// Ward Performance and Health Section for Deputy Municipal Commissioner Zonal Command Center.
/// Displays deterministic health status and metrics across all wards strictly in the DMC's zone.
class ZoneWardPerformanceSection extends StatelessWidget {
  final String zoneId;
  final List<WardHealthCardData> wardHealthCards;
  final bool isLoading;
  final ValueChanged<String>? onFilterByWard;
  final GovernmentZoneDashboardService? dashboardService;

  const ZoneWardPerformanceSection({
    super.key,
    required this.zoneId,
    required this.wardHealthCards,
    this.isLoading = false,
    this.onFilterByWard,
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
          // Section Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.holiday_village_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WARD PERFORMANCE & HEALTH AUDIT',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Operational status, SLA compliance, and hazard distribution across ${wardHealthCards.length} zone wards',
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
                  '${wardHealthCards.length} Wards in Zone',
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
          else if (wardHealthCards.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Text(
                  'No wards mapped to this zone.',
                  style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wardHealthCards.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) => _buildWardMobileCard(context, wardHealthCards[index]),
            )
          else
            _buildWardDesktopTable(context),
        ],
      ),
    );
  }

  Widget _buildWardDesktopTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GovtThemeTokens.surfaceMuted),
        horizontalMargin: CivicFixSpacing.md,
        columnSpacing: CivicFixSpacing.lg,
        columns: const [
          DataColumn(label: Text('WARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('HEALTH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('OFFICER IN CHARGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('OPEN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('IN PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('RESOLVED TODAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('CRITICAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SLA BREACHED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SLA RATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('AVG TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: wardHealthCards.map((card) {
          final hs = card.healthStatus;
          return DataRow(
            cells: [
              // 1. Ward Code & Name
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ward ${card.wardCode}',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primaryDark,
                      ),
                    ),
                    Text(
                      card.wardName,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),

              // 2. Health Badge
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hs.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hs.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: hs.color, shape: BoxShape.circle),
                      ),
                      CivicFixSpacing.hSpaceXs,
                      Text(
                        hs.displayName,
                        style: CivicFixTypography.caption.copyWith(
                          color: hs.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Officer
              DataCell(
                Text(
                  card.wardOfficer?.fullName ?? 'Assistant Commissioner',
                  style: CivicFixTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ),

              // 4. Open
              DataCell(
                Text(
                  '${card.openComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
              ),

              // 5. In Progress
              DataCell(
                Text(
                  '${card.inProgressComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(color: const Color(0xFF0D9488)),
                ),
              ),

              // 6. Resolved Today
              DataCell(
                Text(
                  '${card.resolvedToday}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.success,
                  ),
                ),
              ),

              // 7. Critical
              DataCell(
                Text(
                  '${card.criticalComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: card.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted,
                  ),
                ),
              ),

              // 8. SLA Breached
              DataCell(
                Text(
                  '${card.slaBreachedComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: card.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted,
                  ),
                ),
              ),

              // 9. SLA Rate
              DataCell(
                Text(
                  card.slaComplianceRate != null
                      ? '${card.slaComplianceRate!.toStringAsFixed(1)}%'
                      : 'N/A',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: (card.slaComplianceRate ?? 100) >= 80
                        ? GovtThemeTokens.success
                        : ((card.slaComplianceRate ?? 100) >= 70
                            ? GovtThemeTokens.warning
                            : GovtThemeTokens.error),
                  ),
                ),
              ),

              // 10. Avg Resolution Hours
              DataCell(
                Text(
                  card.avgResolutionHours != null
                      ? '${card.avgResolutionHours!.toStringAsFixed(1)} hrs'
                      : 'N/A',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),

              // 11. Actions
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ZoneWardDrilldownDialog.show(
                          context,
                          ward: card.ward,
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
                      child: const Text('Drill Down'),
                    ),
                    if (onFilterByWard != null) ...[
                      CivicFixSpacing.hSpaceXs,
                      IconButton(
                        onPressed: () => onFilterByWard!(card.ward.wardId),
                        icon: const Icon(Icons.filter_alt_outlined, size: 16, color: GovtThemeTokens.textSecondary),
                        tooltip: 'Filter Dashboard by Ward',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWardMobileCard(BuildContext context, WardHealthCardData card) {
    final hs = card.healthStatus;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ward ${card.wardCode} (${card.wardName})',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primaryDark,
                      ),
                    ),
                    Text(
                      card.wardOfficer?.fullName ?? 'Assistant Commissioner',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hs.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hs.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  hs.displayName,
                  style: CivicFixTypography.caption.copyWith(
                    color: hs.color,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _mobileStat('Open', '${card.openComplaints}', GovtThemeTokens.textPrimary),
              _mobileStat('Critical', '${card.criticalComplaints}', card.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
              _mobileStat('Resolved', '${card.resolvedToday}', GovtThemeTokens.success),
              _mobileStat('SLA', card.slaComplianceRate != null ? '${card.slaComplianceRate!.toStringAsFixed(0)}%' : 'N/A', (card.slaComplianceRate ?? 100) >= 80 ? GovtThemeTokens.success : GovtThemeTokens.error),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ZoneWardDrilldownDialog.show(
                    context,
                    ward: card.ward,
                    zoneId: zoneId,
                    dashboardService: dashboardService,
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('View Ward Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileStat(String label, String value, Color color) {
    return Column(
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
