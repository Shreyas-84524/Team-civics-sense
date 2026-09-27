import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_data_table.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_empty_state.dart';
import '../../common/govt_jurisdiction_badge.dart';
import '../../common/govt_priority_badge.dart';
import '../../common/govt_sla_badge.dart';
import '../../common/govt_status_badge.dart';

/// Prominent operational section showcasing high-priority unresolved emergencies.
class CriticalComplaintsSection extends StatelessWidget {
  final List<ComplaintModel> criticalComplaints;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;
  final VoidCallback? onViewAllCritical;

  const CriticalComplaintsSection({
    super.key,
    required this.criticalComplaints,
    this.isLoading = false,
    this.onViewComplaint,
    this.onViewAllCritical,
  });

  @override
  Widget build(BuildContext context) {
    if (criticalComplaints.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GovernmentSectionHeader(
            title: 'Critical Complaints',
            subtitle: 'High-severity safety hazards and urgent civic infrastructure emergencies',
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: const GovtEmptyState(
              title: 'No active critical emergencies',
              message: 'Zero urgent or emergency priority grievances currently require emergency dispatch.',
              icon: Icons.check_circle_outline_rounded,
              isCompact: true,
            ),
          ),
        ],
      );
    }

    final columns = [
      const GovtDataColumn(label: 'Ticket #', width: 130),
      const GovtDataColumn(label: 'Category / Title', width: 220),
      const GovtDataColumn(label: 'Ward', width: 100),
      const GovtDataColumn(label: 'Department', width: 150),
      const GovtDataColumn(label: 'Priority', width: 110),
      const GovtDataColumn(label: 'Status', width: 130),
      const GovtDataColumn(label: 'SLA State', width: 130),
      const GovtDataColumn(label: 'Reported Time', width: 120),
      const GovtDataColumn(label: 'Assigned To', width: 140),
      const GovtDataColumn(label: 'Action', width: 100, alignment: Alignment.center),
    ];

    final rows = criticalComplaints.take(8).map((c) {
      final wardStr = c.wardId ?? c.location.ward ?? '—';
      final deptStr = c.effectiveDepartment;
      final reportedStr = DateFormatter.formatRelative(c.createdAt);
      final assignedStr = c.assignedTo != null && c.assignedTo!.isNotEmpty
          ? c.assignedTo!
          : 'Unassigned';

      return [
        // Ticket #
        Text(
          c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.primary,
            fontFamily: 'monospace',
          ),
        ),
        // Category / Title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              c.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              c.category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GovtTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 10),
            ),
          ],
        ),
        // Ward
        GovtJurisdictionBadge.ward(wardStr, isCompact: true, withBrackets: false),
        // Department
        Text(
          deptStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GovtTypography.bodySmall,
        ),
        // Priority
        GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
        // Status
        GovtStatusBadge.complaint(c.status, isCompact: true),
        // SLA State
        GovtSlaBadge.fromDuration(
          createdAt: c.slaStartedAt,
          isCompact: true,
        ),
        // Reported Time
        Text(reportedStr, style: GovtTypography.bodySmall),
        // Assigned To
        Text(
          assignedStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GovtTypography.caption.copyWith(
            color: assignedStr == 'Unassigned' ? GovtThemeTokens.textMuted : GovtThemeTokens.textPrimary,
            fontWeight: assignedStr == 'Unassigned' ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        // Action
        TextButton(
          onPressed: onViewComplaint != null ? () => onViewComplaint!(c.id) : null,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: GovtThemeTokens.primary,
          ),
          child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'Critical Complaints',
          subtitle: 'High-severity safety hazards and urgent civic infrastructure emergencies',
          count: criticalComplaints.length,
          action: onViewAllCritical != null
              ? TextButton(
                  onPressed: onViewAllCritical,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All Critical', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                )
              : null,
        ),
        CivicFixSpacing.vSpaceSm,
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: isLoading,
          title: 'Urgent Dispatch Triage',
          totalCount: criticalComplaints.length,
          pageSize: 8,
          minWidth: 1200,
        ),
      ],
    );
  }
}
