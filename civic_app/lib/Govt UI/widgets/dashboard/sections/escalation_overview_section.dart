import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_data_table.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_empty_state.dart';
import '../../common/govt_jurisdiction_badge.dart';
import '../../common/govt_priority_badge.dart';
import '../../common/govt_sla_badge.dart';

/// Section providing oversight on active statutory escalations and SLA breaches.
class EscalationOverviewSection extends StatelessWidget {
  final List<ComplaintModel> escalatedComplaints;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;

  const EscalationOverviewSection({
    super.key,
    required this.escalatedComplaints,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
    if (escalatedComplaints.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GovernmentSectionHeader(
            title: 'Active Escalations',
            subtitle: 'Supervisory review queue for grievances exceeding statutory deadlines',
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: GovtEmptyState.noEscalations(),
          ),
        ],
      );
    }

    final columns = [
      const GovtDataColumn(label: 'Ticket #', width: 130),
      const GovtDataColumn(label: 'Title', width: 220),
      const GovtDataColumn(label: 'Ward', width: 90),
      const GovtDataColumn(label: 'Department', width: 160),
      const GovtDataColumn(label: 'Priority', width: 110),
      const GovtDataColumn(label: 'Escalation State', width: 140),
      const GovtDataColumn(label: 'Responsible Lead', width: 160),
      const GovtDataColumn(label: 'Action', width: 90, alignment: Alignment.center),
    ];

    final rows = escalatedComplaints.take(8).map((c) {
      final wardStr = c.wardId ?? c.location.ward ?? '—';
      final leadStr = c.assignedDepartmentLeadId ?? (c.assignedTo ?? 'Unassigned');

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
        // Title
        Text(
          c.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        // Ward
        GovtJurisdictionBadge.ward(wardStr, isCompact: true, withBrackets: false),
        // Department
        Text(c.effectiveDepartment, style: GovtTypography.bodySmall),
        // Priority
        GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
        // Escalation State
        GovtSlaBadge.breached(overdueText: 'Statutory Escalation', isCompact: true),
        // Responsible Lead
        Text(leadStr, style: GovtTypography.caption),
        // Action
        TextButton(
          onPressed: onViewComplaint != null ? () => onViewComplaint!(c.id) : null,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: GovtThemeTokens.primary,
          ),
          child: const Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'Active Escalations',
          subtitle: 'Supervisory review queue for grievances exceeding statutory deadlines',
          count: escalatedComplaints.length,
        ),
        CivicFixSpacing.vSpaceSm,
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: isLoading,
          title: 'Statutory Grievance Escalation Queue',
          totalCount: escalatedComplaints.length,
          pageSize: 8,
          minWidth: 1100,
        ),
      ],
    );
  }
}
