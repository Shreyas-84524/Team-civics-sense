import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import 'department_ward_unit_drilldown_dialog.dart';

/// Comprehensive 24-Ward Performance Table and Mobile Cards for Central Department HOD.
class DepartmentWardPerformanceSection extends StatefulWidget {
  final List<WardDepartmentUnitPerformanceData> wardUnits;
  final String departmentId;
  final bool isLoading;
  final GovernmentDepartmentDashboardService? dashboardService;

  const DepartmentWardPerformanceSection({
    super.key,
    required this.wardUnits,
    required this.departmentId,
    this.isLoading = false,
    this.dashboardService,
  });

  @override
  State<DepartmentWardPerformanceSection> createState() => _DepartmentWardPerformanceSectionState();
}

class _DepartmentWardPerformanceSectionState extends State<DepartmentWardPerformanceSection> {
  String _searchQuery = '';
  String? _zoneFilter;
  bool _slaBreachedOnly = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    // Apply local table filtering
    var filtered = widget.wardUnits.where((u) {
      if (_zoneFilter != null && _zoneFilter != 'all') {
        if (u.zone.zoneId.toUpperCase() != _zoneFilter!.toUpperCase()) {
          return false;
        }
      }
      if (_slaBreachedOnly && u.slaBreachedComplaints == 0) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchCode = u.wardCode.toLowerCase().contains(q);
        final matchName = u.wardName.toLowerCase().contains(q);
        final matchLead = u.leadName.toLowerCase().contains(q);
        if (!matchCode && !matchName && !matchLead) return false;
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.wardCode.compareTo(b.wardCode);
          break;
        case 1:
          cmp = a.zone.zoneId.compareTo(b.zone.zoneId);
          break;
        case 2:
          cmp = a.openComplaints.compareTo(b.openComplaints);
          break;
        case 3:
          cmp = a.criticalComplaints.compareTo(b.criticalComplaints);
          break;
        case 4:
          cmp = a.slaBreachedComplaints.compareTo(b.slaBreachedComplaints);
          break;
        case 5:
          final rateA = a.slaComplianceRate ?? 100.0;
          final rateB = b.slaComplianceRate ?? 100.0;
          cmp = rateA.compareTo(rateB);
          break;
        default:
          cmp = a.wardCode.compareTo(b.wardCode);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final zones = widget.wardUnits.map((u) => u.zone.zoneId).toSet().toList()..sort();

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
          // Section Header
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
                            '24-WARD OPERATIONAL UNIT PERFORMANCE',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Technical operations, SLA adherence, and lead accountability across all municipal wards',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${widget.wardUnits.length} Ward Units',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceMd,

          // Filter Toolbar
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search field
              SizedBox(
                width: 220,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search ward or lead...',
                    hintStyle: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),

              // Zone Dropdown
              DropdownButton<String>(
                value: _zoneFilter ?? 'all',
                isDense: true,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All 7 Zones')),
                  ...zones.map((z) => DropdownMenuItem(value: z, child: Text(z))),
                ],
                onChanged: (val) => setState(() => _zoneFilter = val == 'all' ? null : val),
              ),

              // SLA Breached Toggle
              FilterChip(
                label: const Text('SLA Breached Only'),
                selected: _slaBreachedOnly,
                onSelected: (val) => setState(() => _slaBreachedOnly = val),
                selectedColor: GovtThemeTokens.error.withValues(alpha: 0.15),
                checkmarkColor: GovtThemeTokens.error,
                labelStyle: CivicFixTypography.caption.copyWith(
                  color: _slaBreachedOnly ? GovtThemeTokens.error : GovtThemeTokens.textSecondary,
                  fontWeight: _slaBreachedOnly ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Text(
                  'No ward operational units matching criteria.',
                  style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) => _buildWardMobileCard(context, filtered[index]),
            )
          else
            _buildWardDesktopTable(context, filtered),
        ],
      ),
    );
  }

  Widget _buildWardDesktopTable(BuildContext context, List<WardDepartmentUnitPerformanceData> units) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GovtThemeTokens.surfaceMuted),
        horizontalMargin: CivicFixSpacing.md,
        columnSpacing: CivicFixSpacing.lg,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          DataColumn(
            label: const Text('WARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onSort: (idx, asc) => setState(() {
              _sortColumnIndex = idx;
              _sortAscending = asc;
            }),
          ),
          DataColumn(
            label: const Text('ZONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onSort: (idx, asc) => setState(() {
              _sortColumnIndex = idx;
              _sortAscending = asc;
            }),
          ),
          DataColumn(
            label: const Text('OPEN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            numeric: true,
            onSort: (idx, asc) => setState(() {
              _sortColumnIndex = idx;
              _sortAscending = asc;
            }),
          ),
          const DataColumn(label: Text('IN PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          const DataColumn(label: Text('RESOLVED TODAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(
            label: const Text('CRITICAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            numeric: true,
            onSort: (idx, asc) => setState(() {
              _sortColumnIndex = idx;
              _sortAscending = asc;
            }),
          ),
          DataColumn(
            label: const Text('SLA BREACHED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            numeric: true,
            onSort: (idx, asc) => setState(() {
              _sortColumnIndex = idx;
              _sortAscending = asc;
            }),
          ),
          DataColumn(
            label: const Text('SLA COMPLIANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            numeric: true,
            onSort: (idx, asc) => setState(() {
              _sortColumnIndex = idx;
              _sortAscending = asc;
            }),
          ),
          const DataColumn(label: Text('AVG TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          const DataColumn(label: Text('DEPARTMENT LEAD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const DataColumn(label: Text('CREW LOAD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: units.map((u) {
          final slaRate = u.slaComplianceRate;
          return DataRow(
            cells: [
              // 1. Ward Code & Name
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ward ${u.wardCode}',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primaryDark,
                      ),
                    ),
                    Text(
                      u.wardName,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // 2. Zone
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: GovtThemeTokens.borderLight),
                  ),
                  child: Text(
                    u.zone.zoneId,
                    style: CivicFixTypography.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
              ),

              // 3. Open
              DataCell(
                Text(
                  '${u.openComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: u.openComplaints > 0 ? GovtThemeTokens.primary : GovtThemeTokens.textMuted,
                  ),
                ),
              ),

              // 4. In Progress
              DataCell(Text('${u.inProgressComplaints}')),

              // 5. Resolved Today
              DataCell(
                Text(
                  '+${u.resolvedToday}',
                  style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.success, fontWeight: FontWeight.w600),
                ),
              ),

              // 6. Critical
              DataCell(
                Text(
                  '${u.criticalComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: u.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted,
                  ),
                ),
              ),

              // 7. SLA Breached
              DataCell(
                Text(
                  '${u.slaBreachedComplaints}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: u.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted,
                  ),
                ),
              ),

              // 8. SLA Compliance
              DataCell(
                Text(
                  slaRate != null ? '${slaRate.toStringAsFixed(1)}%' : 'N/A',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: (slaRate ?? 100) >= 80
                        ? GovtThemeTokens.success
                        : ((slaRate ?? 100) >= 70 ? GovtThemeTokens.warning : GovtThemeTokens.error),
                  ),
                ),
              ),

              // 9. Avg Resolution Time
              DataCell(
                Text(
                  u.avgResolutionHours != null ? '${u.avgResolutionHours!.toStringAsFixed(1)} hrs' : 'N/A',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),

              // 10. Department Lead
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      u.leadName,
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    Text(
                      u.leadPhone,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // 11. Crew Load
              DataCell(
                Text('${u.activeCrewJobs} / ${u.crewCount} active jobs'),
              ),

              // 12. Action: View Ward Unit
              DataCell(
                ElevatedButton(
                  onPressed: () {
                    DepartmentWardUnitDrilldownDialog.show(
                      context,
                      ward: u.ward,
                      departmentId: widget.departmentId,
                      dashboardService: widget.dashboardService,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('View Ward Unit'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWardMobileCard(BuildContext context, WardDepartmentUnitPerformanceData u) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ward ${u.wardCode} (${u.wardName})',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.primaryDark,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(u.zone.zoneId, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text('Lead: ${u.leadName}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary)),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _metricPill('Open', '${u.openComplaints}', GovtThemeTokens.primary),
              _metricPill('Critical', '${u.criticalComplaints}', u.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted),
              _metricPill('SLA Breached', '${u.slaBreachedComplaints}', u.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted),
              _metricPill('SLA %', u.slaComplianceRate != null ? '${u.slaComplianceRate!.toStringAsFixed(0)}%' : 'N/A',
                  (u.slaComplianceRate ?? 100) >= 80 ? GovtThemeTokens.success : GovtThemeTokens.warning),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          OutlinedButton(
            onPressed: () {
              DepartmentWardUnitDrilldownDialog.show(
                context,
                ward: u.ward,
                departmentId: widget.departmentId,
                dashboardService: widget.dashboardService,
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              side: const BorderSide(color: GovtThemeTokens.primary),
            ),
            child: const Text('View Ward Unit'),
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 11)),
        Text(value, style: CivicFixTypography.caption.copyWith(fontWeight: FontWeight.w700, color: color, fontSize: 11)),
      ],
    );
  }
}
