import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_jurisdiction_resolver.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_status_badge.dart';

enum _WardSlaSortColumn {
  overdue,
  priority,
  department,
}

/// Comprehensive SLA Monitoring and Overdue Breach Oversight for Ward Officer.
class WardSlaMonitoringSection extends StatefulWidget {
  final WardSlaMonitoringData slaData;
  final bool isLoading;
  final ValueChanged<WardSlaBreachItem>? onInspectBreach;

  const WardSlaMonitoringSection({
    super.key,
    required this.slaData,
    this.isLoading = false,
    this.onInspectBreach,
  });

  @override
  State<WardSlaMonitoringSection> createState() => _WardSlaMonitoringSectionState();
}

class _WardSlaMonitoringSectionState extends State<WardSlaMonitoringSection> {
  _WardSlaSortColumn _sortColumn = _WardSlaSortColumn.overdue;
  bool _sortAscending = false;

  void _onSort(_WardSlaSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
    });
  }

  List<WardSlaBreachItem> _getSortedBreaches() {
    final list = List<WardSlaBreachItem>.from(widget.slaData.breachedItems);
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case _WardSlaSortColumn.overdue:
          cmp = a.overdueHours.compareTo(b.overdueHours);
          break;
        case _WardSlaSortColumn.priority:
          cmp = a.priority.index.compareTo(b.priority.index);
          break;
        case _WardSlaSortColumn.department:
          cmp = a.departmentName.compareTo(b.departmentName);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slaData;
    final breaches = _getSortedBreaches();
    final isMobile = GovtResponsive.isMobile(context);

    final complianceRate = s.overallSlaComplianceRate ?? 100.0;
    final complianceColor = complianceRate >= 85
        ? GovtThemeTokens.success
        : (complianceRate >= 70 ? GovtThemeTokens.warning : GovtThemeTokens.error);

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
                  color: GovtThemeTokens.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer_off_rounded, color: GovtThemeTokens.error, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WARD SLA MONITORING & COMPLIANCE',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Statutory 48-hour SLA deadline tracking and overdue grievance enforcement',
                      style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          // 4 Key Stats Tiles
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildSlaMetricTile(
                title: 'Overall Compliance',
                value: s.overallSlaComplianceRate != null ? '${complianceRate.toStringAsFixed(1)}%' : 'N/A',
                subtitle: 'Target: 85%+',
                color: complianceColor,
                icon: Icons.verified_user_outlined,
              ),
              _buildSlaMetricTile(
                title: 'Total Breached',
                value: '${s.totalBreached}',
                subtitle: '>48h statutory limit',
                color: s.totalBreached > 0 ? GovtThemeTokens.error : GovtThemeTokens.success,
                icon: Icons.alarm_off_rounded,
              ),
              _buildSlaMetricTile(
                title: 'At-Risk Grievances',
                value: '${s.atRiskCount}',
                subtitle: '40h - 48h active age',
                color: s.atRiskCount > 0 ? GovtThemeTokens.warning : GovtThemeTokens.success,
                icon: Icons.warning_amber_rounded,
              ),
              _buildSlaMetricTile(
                title: 'Avg Overdue Time',
                value: s.avgOverdueHours != null ? '${s.avgOverdueHours!.toStringAsFixed(1)} hrs' : '0.0 hrs',
                subtitle: 'Average elapsed overdue',
                color: GovtThemeTokens.secondary,
                icon: Icons.hourglass_bottom_rounded,
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,

          // Department Breach Breakdown Cards if any
          if (s.breachCountByDepartment.isNotEmpty) ...[
            Text(
              'BREACHES BY MUNICIPAL DEPARTMENT',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            CivicFixSpacing.vSpaceSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s.breachCountByDepartment.entries.map((entry) {
                final deptName = GovernmentJurisdictionResolver.resolveDepartment(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GovtThemeTokens.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(deptName, style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
                      CivicFixSpacing.hSpaceSm,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            CivicFixSpacing.vSpaceLg,
          ],

          // Overdue Complaints Table
          Text(
            'ACTIVE SLA BREACH REGISTER (${breaches.length})',
            style: CivicFixTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          CivicFixSpacing.vSpaceSm,

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (breaches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.lg),
              child: Center(
                child: Text('Zero SLA breaches in this ward.', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted)),
              ),
            )
          else if (isMobile)
            _buildMobileBreachList(breaches)
          else
            _buildDesktopBreachTable(breaches),
        ],
      ),
    );
  }

  Widget _buildSlaMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),
              CivicFixSpacing.hSpaceXs,
              Icon(icon, color: color, size: 16),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            value,
            style: CivicFixTypography.h2.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(subtitle, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDesktopBreachTable(List<WardSlaBreachItem> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GovtThemeTokens.surfaceMuted),
        headingTextStyle: CivicFixTypography.captionMedium.copyWith(
          color: GovtThemeTokens.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 18,
        horizontalMargin: 12,
        columns: [
          const DataColumn(label: Text('COMPLAINT')),
          DataColumn(
            label: const Text('DEPARTMENT'),
            onSort: (_, _) => _onSort(_WardSlaSortColumn.department),
          ),
          DataColumn(
            label: const Text('PRIORITY'),
            onSort: (_, _) => _onSort(_WardSlaSortColumn.priority),
          ),
          const DataColumn(label: Text('STATUS')),
          DataColumn(
            label: const Text('OVERDUE BY'),
            numeric: true,
            onSort: (_, _) => _onSort(_WardSlaSortColumn.overdue),
          ),
          const DataColumn(label: Text('DEPT LEAD')),
          const DataColumn(label: Text('CREW')),
          const DataColumn(label: Text('REASSIGNMENTS'), numeric: true),
          const DataColumn(label: Text('ACTION')),
        ],
        rows: list.map((item) {
          final crewText = item.assignedCrew.isNotEmpty ? item.assignedCrew.map((c) => c.fullName).join(', ') : 'Unassigned';

          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.ticketNumber, style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700, color: GovtThemeTokens.primary)),
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              DataCell(Text(item.departmentName, style: CivicFixTypography.bodySmall)),
              DataCell(GovtPriorityBadge.fromPriority(item.priority, isCompact: true)),
              DataCell(GovtStatusBadge.complaint(item.status, isCompact: true)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.errorLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${item.overdueHours.toStringAsFixed(1)} hrs',
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.error,
                    ),
                  ),
                ),
              ),
              DataCell(Text(item.leadName, style: CivicFixTypography.caption)),
              DataCell(Text(crewText, style: CivicFixTypography.caption)),
              DataCell(Text('${item.reassignmentCount}', style: CivicFixTypography.bodySmall)),
              DataCell(
                OutlinedButton.icon(
                  onPressed: widget.onInspectBreach != null ? () => widget.onInspectBreach!(item) : null,
                  icon: const Icon(Icons.warning_amber_rounded, size: 14, color: GovtThemeTokens.error),
                  label: const Text('Inspect'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: GovtThemeTokens.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileBreachList(List<WardSlaBreachItem> list) {
    return Column(
      children: list.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            onTap: widget.onInspectBreach != null ? () => widget.onInspectBreach!(item) : null,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.ticketNumber, style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700)),
                Text('+${item.overdueHours.toStringAsFixed(1)} hrs', style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.error, fontWeight: FontWeight.w700)),
              ],
            ),
            subtitle: Text('Dept: ${item.departmentName} · Lead: ${item.leadName}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
          ),
        );
      }).toList(),
    );
  }
}
