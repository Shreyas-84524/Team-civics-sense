import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../services/government_department_lead_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Department SLA Monitor" Section for Ward Department Lead Operations Center.
/// Displays live SLA compliance rates, healthy vs at-risk vs breached aggregates,
/// multi-dimensional breakdowns by Priority, Status, and Crew Member, and an Overdue complaints table.
class DepartmentLeadSlaMonitorSection extends StatelessWidget {
  final DepartmentLeadSlaMonitoringData slaData;
  final bool isLoading;
  final ValueChanged<ComplaintModel>? onViewComplaint;

  const DepartmentLeadSlaMonitorSection({
    super.key,
    required this.slaData,
    this.isLoading = false,
    this.onViewComplaint,
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
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.timer_outlined,
                    color: Color(0xFFDC2626), size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT SLA MONITOR',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Operational turnaround tracking against 48-hour municipal charter standard',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (slaData.slaComplianceRate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: slaData.slaComplianceRate! >= 90
                        ? GovtThemeTokens.success.withValues(alpha: 0.1)
                        : GovtThemeTokens.alert.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: slaData.slaComplianceRate! >= 90
                          ? GovtThemeTokens.success.withValues(alpha: 0.3)
                          : GovtThemeTokens.alert.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${slaData.slaComplianceRate!.toStringAsFixed(1)}% Compliance',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: slaData.slaComplianceRate! >= 90
                          ? GovtThemeTokens.success
                          : GovtThemeTokens.alert,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          // SLA Overview Cards (Healthy, At Risk, Breached)
          Row(
            children: [
              Expanded(
                child: _buildHealthCard(
                  'SLA Healthy',
                  '${slaData.slaHealthyCount}',
                  '> 12h remaining',
                  const Color(0xFF10B981),
                  Icons.check_circle_outline_rounded,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: _buildHealthCard(
                  'SLA At Risk',
                  '${slaData.slaAtRiskCount}',
                  'Approaching 48h mark',
                  const Color(0xFFF97316),
                  Icons.warning_amber_rounded,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: _buildHealthCard(
                  'SLA Breached',
                  '${slaData.slaBreachedCount}',
                  'Exceeded charter threshold',
                  const Color(0xFFDC2626),
                  Icons.alarm_off_rounded,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Breakdowns: Priority, Status, Crew
          Text(
            'SLA COMPLIANCE BREAKDOWNS',
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          if (!isMobile) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildBreakdownBox(
                    'By Priority',
                    slaData.priorityBreakdown.entries.map((e) {
                      return _BreakdownRow(
                        label: e.key.label,
                        count: e.value,
                        color: e.key.color,
                      );
                    }).toList(),
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: _buildBreakdownBox(
                    'By Status',
                    slaData.statusBreakdown.entries.map((e) {
                      return _BreakdownRow(
                        label: e.key.label,
                        count: e.value,
                        color: e.key.color,
                      );
                    }).toList(),
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: _buildBreakdownBox(
                    'By Crew Member',
                    slaData.crewBreakdown.entries.map((e) {
                      return _BreakdownRow(
                        label: e.key,
                        count: e.value,
                        color: GovtThemeTokens.primary,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ] else ...[
            Column(
              children: [
                _buildBreakdownBox(
                  'By Priority',
                  slaData.priorityBreakdown.entries.map((e) {
                    return _BreakdownRow(
                      label: e.key.label,
                      count: e.value,
                      color: e.key.color,
                    );
                  }).toList(),
                ),
                CivicFixSpacing.vSpaceMd,
                _buildBreakdownBox(
                  'By Status',
                  slaData.statusBreakdown.entries.map((e) {
                    return _BreakdownRow(
                      label: e.key.label,
                      count: e.value,
                      color: e.key.color,
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
          CivicFixSpacing.vSpaceLg,

          // Overdue Table
          Text(
            'OVERDUE GRIEVANCES (${slaData.overdueComplaints.length})',
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          if (slaData.overdueComplaints.isEmpty)
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.lg),
              alignment: Alignment.center,
              child: Text(
                'No overdue grievances currently in this department unit.',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.textMuted,
                ),
              ),
            )
          else
            _buildOverdueTable(context),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
      String title, String count, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Text(
                  title,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text(
            count,
            style: CivicFixTypography.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textMuted,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBox(String title, List<_BreakdownRow> rows) {
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
          Text(
            title,
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: r.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: Text(
                        r.label,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${r.count}',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOverdueTable(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2), // Complaint
          1: FlexColumnWidth(1.2), // Priority
          2: FlexColumnWidth(1.2), // Status
          3: FlexColumnWidth(1.6), // Crew
          4: FlexColumnWidth(1.4), // Overdue By
          5: FlexColumnWidth(1.4), // Reported Time
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
            ),
            children: [
              _tableHeader('COMPLAINT'),
              _tableHeader('PRIORITY'),
              _tableHeader('STATUS'),
              _tableHeader('CREW'),
              _tableHeader('OVERDUE BY'),
              _tableHeader('REPORTED TIME'),
            ],
          ),
          ...slaData.overdueComplaints.map((item) {
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight),
                ),
              ),
              children: [
                // Complaint
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: InkWell(
                    onTap: onViewComplaint != null
                        ? () => onViewComplaint!(item.complaint)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ticketNumber,
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          item.title,
                          style: CivicFixTypography.bodySmall.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Priority
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.priority.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.priority.label,
                        style: CivicFixTypography.caption.copyWith(
                          color: item.priority.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    item.status.label,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: item.status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Crew
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    item.crewName,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Overdue By
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '+${item.overdueHours.toStringAsFixed(1)}h',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Reported Time
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${item.reportedTime.day}/${item.reportedTime.month}/${item.reportedTime.year}\n${item.reportedTime.hour}:${item.reportedTime.minute.toString().padLeft(2, '0')}',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.sm),
      child: Text(
        text,
        style: CivicFixTypography.captionMedium.copyWith(
          color: GovtThemeTokens.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BreakdownRow {
  final String label;
  final int count;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.color,
  });
}
