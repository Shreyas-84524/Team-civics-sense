import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../services/government_city_dashboard_service.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_data_table.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_jurisdiction_badge.dart';

/// Citywide Department Performance Section comparing all 18 technical BMC Departments.
class DepartmentPerformanceSection extends StatefulWidget {
  final List<DepartmentPerformanceMetric> departmentMetrics;
  final bool isLoading;
  final ValueChanged<String>? onViewDepartment;

  const DepartmentPerformanceSection({
    super.key,
    required this.departmentMetrics,
    this.isLoading = false,
    this.onViewDepartment,
  });

  @override
  State<DepartmentPerformanceSection> createState() => _DepartmentPerformanceSectionState();
}

class _DepartmentPerformanceSectionState extends State<DepartmentPerformanceSection> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    var list = List.of(widget.departmentMetrics);

    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int comp = 0;
        switch (_sortColumnIndex) {
          case 0: // Department Name
            comp = a.departmentName.compareTo(b.departmentName);
            break;
          case 1: // Units
            comp = a.wardUnitsCount.compareTo(b.wardUnitsCount);
            break;
          case 2: // Open
            comp = a.openComplaints.compareTo(b.openComplaints);
            break;
          case 3: // In Progress
            comp = a.inProgressComplaints.compareTo(b.inProgressComplaints);
            break;
          case 4: // Resolved
            comp = a.resolvedComplaints.compareTo(b.resolvedComplaints);
            break;
          case 5: // Critical
            comp = a.criticalComplaints.compareTo(b.criticalComplaints);
            break;
          case 6: // SLA Breached
            comp = a.slaBreachedComplaints.compareTo(b.slaBreachedComplaints);
            break;
          case 7: // SLA Compliance
            comp = (a.slaComplianceRate ?? -1).compareTo(b.slaComplianceRate ?? -1);
            break;
          case 8: // Pending Routing
            comp = a.pendingRoutingTickets.compareTo(b.pendingRoutingTickets);
            break;
          case 9: // Avg Time
            comp = (a.avgResolutionHours ?? 9999).compareTo(b.avgResolutionHours ?? 9999);
            break;
        }
        return _sortAscending ? comp : -comp;
      });
    }

    final columns = [
      const GovtDataColumn(label: 'Department', width: 220, isSortable: true),
      const GovtDataColumn(label: 'Ward Units', width: 95, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Open', width: 85, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'In Progress', width: 100, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Resolved', width: 95, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Critical', width: 85, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'SLA Breached', width: 110, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'SLA Compliance', width: 125, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Pending Tickets', width: 120, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Avg Time', width: 90, isNumeric: true, isSortable: true),
    ];

    final rows = list.map((d) {
      final slaText = d.slaComplianceRate != null
          ? '${d.slaComplianceRate!.toStringAsFixed(1)}%'
          : 'Unavailable';

      final slaColor = d.slaComplianceRate == null
          ? GovtThemeTokens.textMuted
          : (d.slaComplianceRate! >= 90
              ? GovtThemeTokens.slaHealthy
              : (d.slaComplianceRate! >= 75 ? GovtThemeTokens.slaWarning : GovtThemeTokens.slaBreached));

      final avgHoursText = d.avgResolutionHours != null
          ? '${d.avgResolutionHours!.toStringAsFixed(1)}h'
          : '—';

      return [
        // Department Name
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GovtJurisdictionBadge.department(d.departmentCode, isCompact: true, withBrackets: false),
            CivicFixSpacing.hSpaceSm,
            SizedBox(
              width: 120,
              child: Text(
                d.departmentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
        // Ward Units
        Text('${d.wardUnitsCount}', style: GovtTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        // Open
        Text(
          '${d.openComplaints}',
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: d.openComplaints > 0 ? GovtThemeTokens.primary : GovtThemeTokens.textSecondary,
          ),
        ),
        // In Progress
        Text('${d.inProgressComplaints}', style: GovtTypography.bodySmall),
        // Resolved
        Text(
          '${d.resolvedComplaints}',
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.success,
          ),
        ),
        // Critical
        Text(
          '${d.criticalComplaints}',
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: d.criticalComplaints > 0 ? GovtThemeTokens.critical : GovtThemeTokens.textMuted,
          ),
        ),
        // SLA Breached
        Text(
          '${d.slaBreachedComplaints}',
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: d.slaBreachedComplaints > 0 ? GovtThemeTokens.slaBreached : GovtThemeTokens.textMuted,
          ),
        ),
        // SLA Compliance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: slaColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            slaText,
            style: GovtTypography.caption.copyWith(
              color: slaColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        // Pending Routing Tickets
        Text(
          '${d.pendingRoutingTickets}',
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: d.pendingRoutingTickets > 0 ? const Color(0xFFD97706) : GovtThemeTokens.textMuted,
          ),
        ),
        // Avg Time
        Text(avgHoursText, style: GovtTypography.bodySmall),
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'Department Performance',
          subtitle: 'Operational efficiency and SLA compliance across all 18 BMC Technical Departments',
          count: widget.departmentMetrics.length,
        ),
        CivicFixSpacing.vSpaceSm,
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: widget.isLoading,
          title: '18 Municipal Departments Ledger',
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          onSort: (colIdx, ascending) {
            setState(() {
              _sortColumnIndex = colIdx;
              _sortAscending = ascending;
            });
          },
          totalCount: rows.length,
          pageSize: 18,
          minWidth: 1100,
        ),
      ],
    );
  }
}
