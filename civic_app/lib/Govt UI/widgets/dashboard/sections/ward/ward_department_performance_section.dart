import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import 'ward_department_drilldown_dialog.dart';

enum _WardDeptSortColumn {
  name,
  open,
  inProgress,
  resolved,
  critical,
  slaBreached,
  slaRate,
  pendingRouting,
  activeEscalations,
  crewLoad,
}

/// Core Section for Assistant Commissioner / Ward Officer:
/// Displays performance metrics and operational capacity across all 18 Municipal Departments inside the Ward.
class WardDepartmentPerformanceSection extends StatefulWidget {
  final List<WardDepartmentPerformanceData> departmentPerformances;
  final String wardId;
  final bool isLoading;
  final GovernmentWardDashboardService? dashboardService;
  final ValueChanged<String>? onViewComplaint;

  const WardDepartmentPerformanceSection({
    super.key,
    required this.departmentPerformances,
    required this.wardId,
    this.isLoading = false,
    this.dashboardService,
    this.onViewComplaint,
  });

  @override
  State<WardDepartmentPerformanceSection> createState() => _WardDepartmentPerformanceSectionState();
}

class _WardDepartmentPerformanceSectionState extends State<WardDepartmentPerformanceSection> {
  _WardDeptSortColumn _sortColumn = _WardDeptSortColumn.open;
  bool _sortAscending = false;
  String _searchQuery = '';
  bool _slaBreachedOnly = false;
  bool _criticalOnly = false;

  void _onSort(_WardDeptSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
    });
  }

  List<WardDepartmentPerformanceData> _getSortedAndFilteredList() {
    var list = widget.departmentPerformances.where((item) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.displayName.toLowerCase().contains(q);
        final matchCode = item.department.departmentCode.toLowerCase().contains(q);
        final matchLead = item.leadName.toLowerCase().contains(q);
        if (!matchName && !matchCode && !matchLead) return false;
      }

      if (_slaBreachedOnly && item.slaBreachedComplaints == 0) {
        return false;
      }

      if (_criticalOnly && item.criticalComplaints == 0) {
        return false;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case _WardDeptSortColumn.name:
          cmp = a.displayName.compareTo(b.displayName);
          break;
        case _WardDeptSortColumn.open:
          cmp = a.openComplaints.compareTo(b.openComplaints);
          break;
        case _WardDeptSortColumn.inProgress:
          cmp = a.inProgressComplaints.compareTo(b.inProgressComplaints);
          break;
        case _WardDeptSortColumn.resolved:
          cmp = a.resolvedTotal.compareTo(b.resolvedTotal);
          break;
        case _WardDeptSortColumn.critical:
          cmp = a.criticalComplaints.compareTo(b.criticalComplaints);
          break;
        case _WardDeptSortColumn.slaBreached:
          cmp = a.slaBreachedComplaints.compareTo(b.slaBreachedComplaints);
          break;
        case _WardDeptSortColumn.slaRate:
          final rateA = a.slaComplianceRate ?? 100.0;
          final rateB = b.slaComplianceRate ?? 100.0;
          cmp = rateA.compareTo(rateB);
          break;
        case _WardDeptSortColumn.pendingRouting:
          cmp = a.pendingRoutingRequests.compareTo(b.pendingRoutingRequests);
          break;
        case _WardDeptSortColumn.activeEscalations:
          cmp = a.activeEscalationsCount.compareTo(b.activeEscalationsCount);
          break;
        case _WardDeptSortColumn.crewLoad:
          cmp = a.activeCrewJobs.compareTo(b.activeCrewJobs);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  void _openDepartmentDrilldown(WardDepartmentPerformanceData item) {
    WardDepartmentDrilldownDialog.show(
      context,
      department: item.department,
      wardId: widget.wardId,
      dashboardService: widget.dashboardService,
      onViewComplaint: widget.onViewComplaint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _getSortedAndFilteredList();
    final isMobile = GovtResponsive.isMobile(context);
    final isTablet = GovtResponsive.isTablet(context);

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
          // Header with Title and Search/Filters
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.domain_rounded, color: GovtThemeTokens.primary, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WARD DEPARTMENT PERFORMANCE',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Administrative metrics and capacity across all 18 municipal departments in Ward ${widget.wardId}',
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips and Search Box
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    height: 36,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search departments...',
                        hintStyle: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: GovtThemeTokens.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        filled: true,
                        fillColor: GovtThemeTokens.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: GovtThemeTokens.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: GovtThemeTokens.borderLight),
                        ),
                      ),
                      style: CivicFixTypography.bodySmall,
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                  ),
                  FilterChip(
                    label: const Text('SLA Breached'),
                    selected: _slaBreachedOnly,
                    onSelected: (val) => setState(() => _slaBreachedOnly = val),
                  ),
                  FilterChip(
                    label: const Text('Critical'),
                    selected: _criticalOnly,
                    onSelected: (val) => setState(() => _criticalOnly = val),
                  ),
                ],
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: Center(
                child: Text('No departments match the current filter.', style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted)),
              ),
            )
          else if (isMobile || isTablet)
            _buildMobileCardsList(list)
          else
            _buildDesktopTable(list),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<WardDepartmentPerformanceData> list) {
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
          DataColumn(
            label: const Text('DEPARTMENT'),
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.name),
          ),
          DataColumn(
            label: const Text('OPEN'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.open),
          ),
          DataColumn(
            label: const Text('IN PROGRESS'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.inProgress),
          ),
          DataColumn(
            label: const Text('RESOLVED'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.resolved),
          ),
          DataColumn(
            label: const Text('CRITICAL'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.critical),
          ),
          DataColumn(
            label: const Text('SLA BREACHED'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.slaBreached),
          ),
          DataColumn(
            label: const Text('SLA RATE'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.slaRate),
          ),
          DataColumn(
            label: const Text('ROUTING'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.pendingRouting),
          ),
          DataColumn(
            label: const Text('ESCALATIONS'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.activeEscalations),
          ),
          DataColumn(
            label: const Text('DEPT LEAD'),
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.name),
          ),
          DataColumn(
            label: const Text('CREW LOAD'),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort(_WardDeptSortColumn.crewLoad),
          ),
          const DataColumn(
            label: Text('ACTION'),
          ),
        ],
        rows: list.map((item) {
          final slaRate = item.slaComplianceRate ?? 100.0;
          final slaColor = slaRate >= 85 ? GovtThemeTokens.success : (slaRate >= 70 ? GovtThemeTokens.warning : GovtThemeTokens.error);

          return DataRow(
            cells: [
              // Department Name & Code
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.displayName,
                      style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      item.department.departmentCode,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // Open
              DataCell(Text('${item.openComplaints}', style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w600))),

              // In Progress
              DataCell(Text('${item.inProgressComplaints}', style: CivicFixTypography.bodySmall)),

              // Resolved (Total / Today)
              DataCell(Text('${item.resolvedTotal} (+${item.resolvedToday})', style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.success))),

              // Critical
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.criticalComplaints > 0 ? GovtThemeTokens.errorLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.criticalComplaints}',
                    style: CivicFixTypography.bodySmall.copyWith(
                      fontWeight: item.criticalComplaints > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: item.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ),

              // SLA Breached
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.slaBreachedComplaints > 0 ? GovtThemeTokens.errorLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.slaBreachedComplaints}',
                    style: CivicFixTypography.bodySmall.copyWith(
                      fontWeight: item.slaBreachedComplaints > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: item.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ),

              // SLA Compliance %
              DataCell(
                Text(
                  item.slaComplianceRate != null ? '${item.slaComplianceRate!.toStringAsFixed(1)}%' : 'N/A',
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: slaColor,
                  ),
                ),
              ),

              // Routing Requests
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.pendingRoutingRequests > 0 ? GovtThemeTokens.infoLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.pendingRoutingRequests}',
                    style: CivicFixTypography.bodySmall.copyWith(
                      fontWeight: item.pendingRoutingRequests > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: item.pendingRoutingRequests > 0 ? GovtThemeTokens.info : GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ),

              // Active Escalations
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.activeEscalationsCount > 0 ? GovtThemeTokens.warningLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.activeEscalationsCount}',
                    style: CivicFixTypography.bodySmall.copyWith(
                      fontWeight: item.activeEscalationsCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: item.activeEscalationsCount > 0 ? GovtThemeTokens.warning : GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ),

              // Department Lead
              DataCell(
                Text(
                  item.leadName,
                  style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w500),
                ),
              ),

              // Crew Load
              DataCell(
                Text(
                  '${item.activeCrewJobs} jobs / ${item.crewCount} crew',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),

              // Action
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => _openDepartmentDrilldown(item),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Unit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCardsList(List<WardDepartmentPerformanceData> list) {
    return Column(
      children: list.map((item) {
        final slaRate = item.slaComplianceRate ?? 100.0;
        final slaColor = slaRate >= 85 ? GovtThemeTokens.success : (slaRate >= 70 ? GovtThemeTokens.warning : GovtThemeTokens.error);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: GovtThemeTokens.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: CivicFixTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      item.slaComplianceRate != null ? '${item.slaComplianceRate!.toStringAsFixed(1)}% SLA' : 'N/A',
                      style: CivicFixTypography.captionMedium.copyWith(color: slaColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text('Lead: ${item.leadName}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary)),
                CivicFixSpacing.vSpaceSm,
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _miniStat('Open', '${item.openComplaints}', GovtThemeTokens.primary),
                    _miniStat('Critical', '${item.criticalComplaints}', item.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted),
                    _miniStat('Breached', '${item.slaBreachedComplaints}', item.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted),
                    _miniStat('Routing', '${item.pendingRoutingRequests}', item.pendingRoutingRequests > 0 ? GovtThemeTokens.info : GovtThemeTokens.textMuted),
                    _miniStat('Escalations', '${item.activeEscalationsCount}', item.activeEscalationsCount > 0 ? GovtThemeTokens.warning : GovtThemeTokens.textMuted),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _openDepartmentDrilldown(item),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View Department Unit'),
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 11)),
        Text(value, style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, color: color, fontSize: 11)),
      ],
    );
  }
}
