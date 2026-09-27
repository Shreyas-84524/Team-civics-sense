import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// SLA Monitoring & Breach Oversight Section for Central Department HOD command center.
/// Shows SLA compliance metrics and list of overdue grievances across all 24 wards.
class DepartmentSlaMonitoringSection extends StatelessWidget {
  final DepartmentSlaMonitoringData slaData;
  final bool isLoading;
  final ValueChanged<DepartmentSlaBreachItem>? onInspectBreach;

  const DepartmentSlaMonitoringSection({
    super.key,
    required this.slaData,
    this.isLoading = false,
    this.onInspectBreach,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);
    final compliance = slaData.overallSlaComplianceRate ?? 100.0;
    final complianceColor = compliance >= 90
        ? GovtThemeTokens.success
        : compliance >= 75
            ? GovtThemeTokens.warning
            : GovtThemeTokens.error;

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
                  color: GovtThemeTokens.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer_off_outlined,
                    color: GovtThemeTokens.warning, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLA MONITORING & BREACH REPOSITORY',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Citizen charter compliance tracking across all 24 ward operational units',
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
                  color: complianceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: complianceColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${compliance.toStringAsFixed(1)}% Compliance',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: complianceColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // KPI Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = isMobile
                    ? (constraints.maxWidth - 8) / 2
                    : (constraints.maxWidth - 24) / 4;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMiniKpi(
                      'OVERALL COMPLIANCE',
                      '${compliance.toStringAsFixed(1)}%',
                      complianceColor,
                      Icons.speed,
                      cardWidth,
                    ),
                    _buildMiniKpi(
                      'ACTIVE BREACHES',
                      '${slaData.totalBreached}',
                      slaData.totalBreached > 0
                          ? GovtThemeTokens.error
                          : GovtThemeTokens.success,
                      Icons.report_problem_outlined,
                      cardWidth,
                    ),
                    _buildMiniKpi(
                      'AT-RISK (< 8H)',
                      '${slaData.atRiskCount}',
                      slaData.atRiskCount > 0
                          ? GovtThemeTokens.warning
                          : GovtThemeTokens.textMuted,
                      Icons.hourglass_top_outlined,
                      cardWidth,
                    ),
                    _buildMiniKpi(
                      'AVG OVERDUE TIME',
                      slaData.avgOverdueHours != null
                          ? '${slaData.avgOverdueHours!.toStringAsFixed(1)}h'
                          : '0.0h',
                      GovtThemeTokens.textPrimary,
                      Icons.schedule,
                      cardWidth,
                    ),
                  ],
                );
              },
            ),
            CivicFixSpacing.vSpaceLg,

            // Breached Complaints List
            if (slaData.breachedItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(CivicFixSpacing.lg),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_outlined,
                          size: 40, color: GovtThemeTokens.success),
                      CivicFixSpacing.vSpaceSm,
                      Text(
                        'Zero Active SLA Breaches in Department',
                        style: CivicFixTypography.bodyMedium.copyWith(
                          color: GovtThemeTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'All grievance resolution workflows across all 24 wards are within charter timeframes.',
                        style: CivicFixTypography.captionMedium
                            .copyWith(color: GovtThemeTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'ACTIVE BREACHED TICKETS (${slaData.breachedItems.length})',
                style: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              CivicFixSpacing.vSpaceSm,
              _buildBreachesTable(context, isMobile),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMiniKpi(
      String label, String value, Color color, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            value,
            style: CivicFixTypography.h2.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreachesTable(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
        ),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        horizontalMargin: 16,
        columnSpacing: 20,
        columns: [
          DataColumn(
            label: Text(
              'TICKET / TITLE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'WARD / ZONE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'OVERDUE DURATION',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'ASSIGNED LEAD',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'ACTION',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
        ],
        rows: slaData.breachedItems.map((item) {
          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ticketNumber,
                        style: CivicFixTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ward ${item.wardCode}',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primaryDark,
                      ),
                    ),
                    Text(
                      item.zone.displayName,
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: GovtThemeTokens.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '+${item.overdueHours.toStringAsFixed(1)}h Overdue',
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.error,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  item.leadName,
                  style: CivicFixTypography.bodyMedium.copyWith(
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
              ),
              DataCell(
                ElevatedButton(
                  onPressed: () => onInspectBreach?.call(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: CivicFixTypography.captionMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Review'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
