import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../services/government_city_dashboard_service.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_data_table.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_jurisdiction_badge.dart';

/// Performance analysis and operational comparison across all 7 Mumbai Administrative Zones.
class ZonePerformanceSection extends StatefulWidget {
  final List<ZonePerformanceMetric> zoneMetrics;
  final bool isLoading;
  final ValueChanged<String>? onViewZone;

  const ZonePerformanceSection({
    super.key,
    required this.zoneMetrics,
    this.isLoading = false,
    this.onViewZone,
  });

  @override
  State<ZonePerformanceSection> createState() => _ZonePerformanceSectionState();
}

class _ZonePerformanceSectionState extends State<ZonePerformanceSection> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final list = List<ZonePerformanceMetric>.from(widget.zoneMetrics);

    // Apply sorting if user clicked header
    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int comp = 0;
        switch (_sortColumnIndex) {
          case 0: // Zone
            comp = a.zone.zoneNumber.compareTo(b.zone.zoneNumber);
            break;
          case 1: // Wards
            comp = a.wardCount.compareTo(b.wardCount);
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
          case 8: // Avg Resolution Time
            comp = (a.avgResolutionHours ?? 9999).compareTo(b.avgResolutionHours ?? 9999);
            break;
        }
        return _sortAscending ? comp : -comp;
      });
    }

    final columns = [
      const GovtDataColumn(label: 'Zone', width: 240, isSortable: true),
      const GovtDataColumn(label: 'Wards', width: 80, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Open', width: 90, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'In Progress', width: 100, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Resolved', width: 95, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Critical', width: 90, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'SLA Breached', width: 110, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'SLA Compliance', width: 130, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Avg Time', width: 100, isNumeric: true, isSortable: true),
      const GovtDataColumn(label: 'Actions', width: 110, alignment: Alignment.center),
    ];

    final rows = list.map((m) {
      final slaText = m.slaComplianceRate != null
          ? '${m.slaComplianceRate!.toStringAsFixed(1)}%'
          : 'Unavailable';

      final slaColor = m.slaComplianceRate == null
          ? GovtThemeTokens.textMuted
          : (m.slaComplianceRate! >= 90
              ? GovtThemeTokens.slaHealthy
              : (m.slaComplianceRate! >= 75 ? GovtThemeTokens.slaWarning : GovtThemeTokens.slaBreached));

      final avgHoursText = m.avgResolutionHours != null
          ? '${m.avgResolutionHours!.toStringAsFixed(1)}h'
          : '—';

      return [
        // Zone
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GovtJurisdictionBadge.zone(m.zone.zoneId, isCompact: true, withBrackets: false),
            CivicFixSpacing.hSpaceSm,
            SizedBox(
              width: 120,
              child: Text(
                m.zone.displayName,
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
        // Wards
        Text('${m.wardCount}', style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700)),
        // Open
        Text(
          '${m.openComplaints}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: m.openComplaints > 0 ? GovtThemeTokens.primary : GovtThemeTokens.textSecondary,
          ),
        ),
        // In Progress
        Text('${m.inProgressComplaints}', style: GovtTypography.bodySmall),
        // Resolved
        Text(
          '${m.resolvedComplaints}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.success,
          ),
        ),
        // Critical
        Text(
          '${m.criticalComplaints}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: m.criticalComplaints > 0 ? GovtThemeTokens.critical : GovtThemeTokens.textMuted,
          ),
        ),
        // SLA Breached
        Text(
          '${m.slaBreachedComplaints}',
          style: CivicFixTypography.bodySmallMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: m.slaBreachedComplaints > 0 ? GovtThemeTokens.slaBreached : GovtThemeTokens.textMuted,
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
        // Avg Time
        Text(avgHoursText, style: GovtTypography.bodySmall),
        // Actions
        TextButton(
          onPressed: widget.onViewZone != null ? () => widget.onViewZone!(m.zone.zoneId) : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            visualDensity: VisualDensity.compact,
            foregroundColor: GovtThemeTokens.primary,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 14),
            ],
          ),
        ),
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'Zone Performance',
          subtitle: 'Operational state and SLA compliance comparison across all 7 BMC Zones',
          count: widget.zoneMetrics.length,
        ),
        CivicFixSpacing.vSpaceSm,
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: widget.isLoading,
          title: 'Zonal Oversight Table (7 Zones)',
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          onSort: (colIdx, ascending) {
            setState(() {
              _sortColumnIndex = colIdx;
              _sortAscending = ascending;
            });
          },
          totalCount: rows.length,
          pageSize: 10,
          minWidth: 1000,
        ),
      ],
    );
  }
}
