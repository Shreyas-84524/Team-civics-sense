import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Department Performance Section for Deputy Municipal Commissioner Zonal Command Center.
/// Displays operational metrics across all 18 technical departments operating within the zone.
class ZoneDepartmentPerformanceSection extends StatelessWidget {
  final List<ZoneDepartmentPerformanceMetric> departmentMetrics;
  final bool isLoading;
  final ValueChanged<String>? onFilterByDepartment;

  const ZoneDepartmentPerformanceSection({
    super.key,
    required this.departmentMetrics,
    this.isLoading = false,
    this.onFilterByDepartment,
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
                child: const Icon(Icons.apartment_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TECHNICAL DEPARTMENTS PERFORMANCE IN ZONE',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Cross-departmental efficiency and workload distribution across all 18 departments',
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
                  '${departmentMetrics.length} Departments',
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
          else if (departmentMetrics.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Text(
                  'No department activity found in this zone.',
                  style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: departmentMetrics.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) => _buildDeptMobileCard(context, departmentMetrics[index]),
            )
          else
            _buildDeptDesktopTable(context),
        ],
      ),
    );
  }

  Widget _buildDeptDesktopTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GovtThemeTokens.surfaceMuted),
        horizontalMargin: CivicFixSpacing.md,
        columnSpacing: CivicFixSpacing.lg,
        columns: const [
          DataColumn(label: Text('DEPARTMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('OPEN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('IN PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('RESOLVED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('CRITICAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SLA BREACHED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SLA RATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('AVG TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('TRANSFERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: departmentMetrics.map((dept) {
          return DataRow(
            cells: [
              // 1. Department Name & Code
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dept.departmentName,
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primaryDark,
                      ),
                    ),
                    Text(
                      dept.departmentCode,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),

              // 2. Open
              DataCell(
                Text(
                  '${dept.openComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
              ),

              // 3. In Progress
              DataCell(
                Text(
                  '${dept.inProgressComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(color: const Color(0xFF0D9488)),
                ),
              ),

              // 4. Resolved
              DataCell(
                Text(
                  '${dept.resolvedComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.success,
                  ),
                ),
              ),

              // 5. Critical
              DataCell(
                Text(
                  '${dept.criticalComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: dept.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted,
                  ),
                ),
              ),

              // 6. SLA Breached
              DataCell(
                Text(
                  '${dept.slaBreachedComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: dept.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted,
                  ),
                ),
              ),

              // 7. SLA Rate
              DataCell(
                Text(
                  dept.slaComplianceRate != null
                      ? '${dept.slaComplianceRate!.toStringAsFixed(1)}%'
                      : 'N/A',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: (dept.slaComplianceRate ?? 100) >= 80
                        ? GovtThemeTokens.success
                        : ((dept.slaComplianceRate ?? 100) >= 70
                            ? GovtThemeTokens.warning
                            : GovtThemeTokens.error),
                  ),
                ),
              ),

              // 8. Avg Hours
              DataCell(
                Text(
                  dept.avgResolutionHours != null
                      ? '${dept.avgResolutionHours!.toStringAsFixed(1)} hrs'
                      : 'N/A',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),

              // 9. Routing Transfers
              DataCell(
                Text(
                  '${dept.pendingRoutingTickets}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: dept.pendingRoutingTickets > 0 ? GovtThemeTokens.info : GovtThemeTokens.textMuted,
                    fontWeight: dept.pendingRoutingTickets > 0 ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),

              // 10. Filter Action
              DataCell(
                onFilterByDepartment != null
                    ? IconButton(
                        onPressed: () => onFilterByDepartment!(dept.departmentId),
                        icon: const Icon(Icons.filter_alt_outlined, size: 18, color: GovtThemeTokens.primary),
                        tooltip: 'Filter by Department',
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeptMobileCard(BuildContext context, ZoneDepartmentPerformanceMetric dept) {
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
                child: Text(
                  dept.departmentName,
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GovtThemeTokens.border),
                ),
                child: Text(
                  dept.departmentCode,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                    fontWeight: FontWeight.w700,
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
              _mobileStat('Open', '${dept.openComplaints}', GovtThemeTokens.textPrimary),
              _mobileStat('Critical', '${dept.criticalComplaints}', dept.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
              _mobileStat('Resolved', '${dept.resolvedComplaints}', GovtThemeTokens.success),
              _mobileStat('SLA', dept.slaComplianceRate != null ? '${dept.slaComplianceRate!.toStringAsFixed(0)}%' : 'N/A', (dept.slaComplianceRate ?? 100) >= 80 ? GovtThemeTokens.success : GovtThemeTokens.error),
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
