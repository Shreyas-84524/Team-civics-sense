import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../services/government_city_dashboard_service.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_data_table.dart';
import '../../common/government_filter_bar.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_jurisdiction_badge.dart';

/// Citywide Ward Performance Section covering all 24 municipal administrative wards.
class WardPerformanceSection extends StatefulWidget {
  final List<WardPerformanceMetric> wardMetrics;
  final bool isLoading;
  final ValueChanged<String>? onViewWard;

  const WardPerformanceSection({
    super.key,
    required this.wardMetrics,
    this.isLoading = false,
    this.onViewWard,
  });

  @override
  State<WardPerformanceSection> createState() => _WardPerformanceSectionState();
}

class _WardPerformanceSectionState extends State<WardPerformanceSection> {
  String _searchQuery = '';
  String? _selectedZoneFilter;
  String? _selectedSlaStatus; // 'all', 'healthy', 'breached'
  int _currentPage = 1;
  static const int _pageSize = 8;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    // 1. Filter wards
    var filtered = widget.wardMetrics.where((w) {
      if (_selectedZoneFilter != null && _selectedZoneFilter != 'all') {
        if (w.zoneId.toLowerCase() != _selectedZoneFilter!.toLowerCase()) {
          return false;
        }
      }

      if (_selectedSlaStatus != null && _selectedSlaStatus != 'all') {
        if (_selectedSlaStatus == 'breached' && w.slaBreachedComplaints == 0) {
          return false;
        }
        if (_selectedSlaStatus == 'healthy' &&
            (w.slaComplianceRate == null || w.slaComplianceRate! < 85)) {
          return false;
        }
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchCode = w.wardCode.toLowerCase().contains(q);
        final matchName = w.wardName.toLowerCase().contains(q);
        final matchZone = w.zoneDisplayName.toLowerCase().contains(q);
        if (!matchCode && !matchName && !matchZone) {
          return false;
        }
      }

      return true;
    }).toList();

    // 2. Sort wards
    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
        int comp = 0;
        switch (_sortColumnIndex) {
          case 0: // Code
            comp = a.wardCode.compareTo(b.wardCode);
            break;
          case 1: // Name
            comp = a.wardName.compareTo(b.wardName);
            break;
          case 2: // Zone
            comp = a.zoneId.compareTo(b.zoneId);
            break;
          case 3: // Open
            comp = a.openComplaints.compareTo(b.openComplaints);
            break;
          case 4: // Resolved Today
            comp = a.resolvedToday.compareTo(b.resolvedToday);
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
            comp = a.pendingRoutingRequests.compareTo(b.pendingRoutingRequests);
            break;
          case 9: // Avg Time
            comp = (a.avgResolutionHours ?? 9999).compareTo(b.avgResolutionHours ?? 9999);
            break;
        }
        return _sortAscending ? comp : -comp;
      });
    }

    final totalCount = filtered.length;
    final startIndex = (_currentPage - 1) * _pageSize;
    final pagedList = filtered.skip(startIndex).take(_pageSize).toList();

    final columns = [
      const GovtDataColumn(label: 'Ward Code', width: 90, isSortable: true),
      const GovtDataColumn(label: 'Ward Name', width: 210, isSortable: true),
      const GovtDataColumn(label: 'Zone', width: 100, isSortable: true),
      const GovtDataColumn(label: 'Open', width: 85, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Resolved Today', width: 120, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Critical', width: 85, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'SLA Breached', width: 110, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'SLA Compliance', width: 125, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Pending Transfers', width: 130, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Avg Time', width: 90, isNumeric: true, isSortable: true),
    ];

    final rows = pagedList.map((w) {
      final slaText = w.slaComplianceRate != null
          ? '${w.slaComplianceRate!.toStringAsFixed(1)}%'
          : 'Unavailable';

      final slaColor = w.slaComplianceRate == null
          ? GovtThemeTokens.textMuted
          : (w.slaComplianceRate! >= 90
              ? GovtThemeTokens.slaHealthy
              : (w.slaComplianceRate! >= 75 ? GovtThemeTokens.slaWarning : GovtThemeTokens.slaBreached));

      final avgHoursText = w.avgResolutionHours != null
          ? '${w.avgResolutionHours!.toStringAsFixed(1)}h'
          : '—';

      return [
        // Ward Code
        GovtJurisdictionBadge.ward(w.wardCode, isCompact: true, withBrackets: true),
        // Ward Name
        Text(
          w.wardName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        // Zone
        GovtJurisdictionBadge.zone(w.zoneId, isCompact: true, withBrackets: false),
        // Open
        Text(
          '${w.openComplaints}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: w.openComplaints > 0 ? GovtThemeTokens.primary : GovtThemeTokens.textSecondary,
          ),
        ),
        // Resolved Today
        Text(
          '${w.resolvedToday}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.success,
          ),
        ),
        // Critical
        Text(
          '${w.criticalComplaints}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: w.criticalComplaints > 0 ? GovtThemeTokens.critical : GovtThemeTokens.textMuted,
          ),
        ),
        // SLA Breached
        Text(
          '${w.slaBreachedComplaints}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: w.slaBreachedComplaints > 0 ? GovtThemeTokens.slaBreached : GovtThemeTokens.textMuted,
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
        // Pending Transfers
        Text(
          '${w.pendingRoutingRequests}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: w.pendingRoutingRequests > 0 ? const Color(0xFFD97706) : GovtThemeTokens.textMuted,
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
          title: 'Ward Performance',
          subtitle: 'Administrative oversight and complaint resolution across all 24 BMC Wards',
          count: widget.wardMetrics.length,
        ),
        CivicFixSpacing.vSpaceSm,

        // Operational Visualization: Top Wards Volume & SLA
        _buildWardVisualComparison(widget.wardMetrics),
        CivicFixSpacing.vSpaceMd,

        // Filter bar for Wards
        GovernmentFilterBar(
          searchHint: 'Search ward by code or name...',
          searchQuery: _searchQuery,
          onSearchChanged: (q) {
            setState(() {
              _searchQuery = q;
              _currentPage = 1;
            });
          },
          dropdownFilters: [
            GovtDropdownFilterConfig<String>(
              label: 'Zone',
              selectedValue: _selectedZoneFilter,
              icon: Icons.domain_rounded,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Zones (7)')),
                DropdownMenuItem(value: 'ZONE_1', child: Text('Zone 1 (South)')),
                DropdownMenuItem(value: 'ZONE_2', child: Text('Zone 2 (City Central)')),
                DropdownMenuItem(value: 'ZONE_3', child: Text('Zone 3 (Western South)')),
                DropdownMenuItem(value: 'ZONE_4', child: Text('Zone 4 (Western North)')),
                DropdownMenuItem(value: 'ZONE_5', child: Text('Zone 5 (Eastern South)')),
                DropdownMenuItem(value: 'ZONE_6', child: Text('Zone 6 (Eastern North)')),
                DropdownMenuItem(value: 'ZONE_7', child: Text('Zone 7 (Northern)')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedZoneFilter = val;
                  _currentPage = 1;
                });
              },
            ),
            GovtDropdownFilterConfig<String>(
              label: 'SLA State',
              selectedValue: _selectedSlaStatus,
              icon: Icons.timer_outlined,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All SLA States')),
                DropdownMenuItem(value: 'healthy', child: Text('SLA Healthy (>=85%)')),
                DropdownMenuItem(value: 'breached', child: Text('Has SLA Breaches')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSlaStatus = val;
                  _currentPage = 1;
                });
              },
            ),
          ],
          activeFilterCount: (_selectedZoneFilter != null && _selectedZoneFilter != 'all' ? 1 : 0) +
              (_selectedSlaStatus != null && _selectedSlaStatus != 'all' ? 1 : 0) +
              (_searchQuery.isNotEmpty ? 1 : 0),
          onClearAll: () {
            setState(() {
              _searchQuery = '';
              _selectedZoneFilter = null;
              _selectedSlaStatus = null;
              _currentPage = 1;
            });
          },
        ),
        CivicFixSpacing.vSpaceSm,

        // Data Table
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: widget.isLoading,
          title: '24 Ward Operational Ledger',
          currentPage: _currentPage,
          pageSize: _pageSize,
          totalCount: totalCount,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          onSort: (colIdx, ascending) {
            setState(() {
              _sortColumnIndex = colIdx;
              _sortAscending = ascending;
            });
          },
          onPreviousPage: () {
            if (_currentPage > 1) {
              setState(() => _currentPage--);
            }
          },
          onNextPage: () {
            if (_currentPage * _pageSize < totalCount) {
              setState(() => _currentPage++);
            }
          },
          minWidth: 1100,
        ),
      ],
    );
  }

  Widget _buildWardVisualComparison(List<WardPerformanceMetric> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    // Top 5 highest volume wards
    final sortedByVolume = List<WardPerformanceMetric>.from(metrics)
      ..sort((a, b) => b.totalComplaints.compareTo(a.totalComplaints));
    final topWards = sortedByVolume.take(5).toList();
    final maxCount = topWards.fold<int>(1, (max, w) => w.totalComplaints > max ? w.totalComplaints : max);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Top Wards by Volume & Workload',
                style: GovtTypography.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                'Active Municipal Load',
                style: GovtTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 11),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          for (final w in topWards) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Ward ${w.wardCode}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                  CivicFixSpacing.hSpaceSm,
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxCount > 0 ? (w.totalComplaints / maxCount).clamp(0.05, 1.0) : 0.0,
                        minHeight: 10,
                        backgroundColor: GovtThemeTokens.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          w.criticalComplaints > 0 ? GovtThemeTokens.critical : GovtThemeTokens.primary,
                        ),
                      ),
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${w.totalComplaints} total',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
