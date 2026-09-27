import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Zone Breakdown Section for Central Department HOD command center.
/// Shows performance of the department across all 7 Municipal Zones (Zone 1 to Zone 7).
class DepartmentZoneBreakdownSection extends StatefulWidget {
  final List<DepartmentZoneBreakdownData> zoneBreakdowns;
  final bool isLoading;
  final ValueChanged<String>? onFilterByZone;

  const DepartmentZoneBreakdownSection({
    super.key,
    required this.zoneBreakdowns,
    this.isLoading = false,
    this.onFilterByZone,
  });

  @override
  State<DepartmentZoneBreakdownSection> createState() =>
      _DepartmentZoneBreakdownSectionState();
}

class _DepartmentZoneBreakdownSectionState
    extends State<DepartmentZoneBreakdownSection> {
  String _searchQuery = '';
  String _sortField = 'zone'; // 'zone', 'open', 'critical', 'sla', 'compliance'
  bool _sortAscending = true;

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
                child: const Icon(Icons.public_outlined,
                    color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL BREAKDOWN (7 ZONES)',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Departmental workload, resolution speed, and SLA compliance across all 7 administrative zones',
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
                  border: Border.all(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${widget.zoneBreakdowns.length} Zones',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Search and Sort controls
          if (!widget.isLoading && widget.zoneBreakdowns.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 260,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: CivicFixTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search zone name or ID...',
                      hintStyle: CivicFixTypography.bodySmall
                          .copyWith(color: GovtThemeTokens.textMuted),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: GovtThemeTokens.textSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: GovtThemeTokens.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: GovtThemeTokens.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            CivicFixSpacing.vSpaceMd,
          ],

          // Content
          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (widget.zoneBreakdowns.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.public_off_outlined,
                        size: 40, color: GovtThemeTokens.textMuted),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No zonal data available for this department.',
                      style: CivicFixTypography.bodyMedium
                          .copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildZonesTable(context, isMobile),
        ],
      ),
    );
  }

  List<DepartmentZoneBreakdownData> get _filteredAndSortedZones {
    var list = widget.zoneBreakdowns.where((z) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return z.displayName.toLowerCase().contains(q) ||
          z.zoneId.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case 'open':
          cmp = a.openComplaints.compareTo(b.openComplaints);
          break;
        case 'critical':
          cmp = a.criticalComplaints.compareTo(b.criticalComplaints);
          break;
        case 'sla':
          cmp = a.slaBreachedComplaints.compareTo(b.slaBreachedComplaints);
          break;
        case 'compliance':
          cmp = (a.slaComplianceRate ?? 100.0)
              .compareTo(b.slaComplianceRate ?? 100.0);
          break;
        case 'resolved':
          cmp = a.resolvedComplaints.compareTo(b.resolvedComplaints);
          break;
        case 'zone':
        default:
          cmp = a.displayName.compareTo(b.displayName);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  void _onSort(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  Widget _buildZonesTable(BuildContext context, bool isMobile) {
    final displayZones = _filteredAndSortedZones;

    if (displayZones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Text(
            'No zones match "$_searchQuery"',
            style: CivicFixTypography.bodyMedium
                .copyWith(color: GovtThemeTokens.textSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
        ),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        horizontalMargin: 16,
        columnSpacing: 24,
        columns: [
          DataColumn(
            label: Text(
              'ZONE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            onSort: (columnIndex, ascending) => _onSort('zone'),
          ),
          DataColumn(
            label: Text(
              'WARDS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'OPEN GRIEVANCES',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort('open'),
          ),
          DataColumn(
            label: Text(
              'CRITICAL',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort('critical'),
          ),
          DataColumn(
            label: Text(
              'SLA BREACHED',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort('sla'),
          ),
          DataColumn(
            label: Text(
              'SLA COMPLIANCE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort('compliance'),
          ),
          DataColumn(
            label: Text(
              'RESOLVED',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
            onSort: (columnIndex, ascending) => _onSort('resolved'),
          ),
          DataColumn(
            label: Text(
              'ACTIONS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
        ],
        rows: displayZones.map((z) {
          final compliance = z.slaComplianceRate ?? 100.0;
          final complianceColor = compliance >= 90
              ? GovtThemeTokens.success
              : compliance >= 75
                  ? GovtThemeTokens.warning
                  : GovtThemeTokens.error;

          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        z.displayName.replaceAll('Zone ', 'Z'),
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: GovtThemeTokens.primaryDark,
                        ),
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          z.displayName,
                          style: CivicFixTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: GovtThemeTokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${z.wardCount} Wards Assigned',
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${z.wardCount}',
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${z.openComplaints}',
                  style: CivicFixTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: z.openComplaints > 0
                        ? GovtThemeTokens.textPrimary
                        : GovtThemeTokens.textMuted,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: z.criticalComplaints > 0
                        ? GovtThemeTokens.error.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${z.criticalComplaints}',
                    style: CivicFixTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: z.criticalComplaints > 0
                          ? GovtThemeTokens.error
                          : GovtThemeTokens.textMuted,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: z.slaBreachedComplaints > 0
                        ? GovtThemeTokens.warning.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${z.slaBreachedComplaints}',
                    style: CivicFixTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: z.slaBreachedComplaints > 0
                          ? GovtThemeTokens.warning
                          : GovtThemeTokens.textMuted,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: complianceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      '${compliance.toStringAsFixed(1)}%',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: complianceColor,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  '${z.resolvedComplaints}',
                  style: CivicFixTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.success,
                  ),
                ),
              ),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () => widget.onFilterByZone?.call(z.zoneId),
                  icon: const Icon(Icons.filter_alt_outlined, size: 14),
                  label: const Text('Filter Zone'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: CivicFixTypography.captionMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
