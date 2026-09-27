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
import '../../common/govt_status_badge.dart';

/// Highly visible command section highlighting statutory SLA breaches requiring intervention.
class SlaBreachesSection extends StatefulWidget {
  final List<ComplaintModel> slaBreachedComplaints;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;

  const SlaBreachesSection({
    super.key,
    required this.slaBreachedComplaints,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  State<SlaBreachesSection> createState() => _SlaBreachesSectionState();
}

class _SlaBreachesSectionState extends State<SlaBreachesSection> {
  String _sortBy = 'most_overdue'; // 'most_overdue', 'priority', 'ward', 'department'

  @override
  Widget build(BuildContext context) {
    final list = List<ComplaintModel>.from(widget.slaBreachedComplaints);
    final now = DateTime.now();

    list.sort((a, b) {
      switch (_sortBy) {
        case 'priority':
          return b.priority.index.compareTo(a.priority.index);
        case 'ward':
          final wA = a.wardId ?? a.location.ward ?? '';
          final wB = b.wardId ?? b.location.ward ?? '';
          return wA.compareTo(wB);
        case 'department':
          return a.effectiveDepartment.compareTo(b.effectiveDepartment);
        case 'most_overdue':
        default:
          final elapsedA = now.difference(a.slaStartedAt);
          final elapsedB = now.difference(b.slaStartedAt);
          return elapsedB.compareTo(elapsedA);
      }
    });

    if (list.isEmpty && !widget.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GovernmentSectionHeader(
            title: 'SLA Breaches Requiring Attention',
            subtitle: 'Supervisory monitoring for grievances exceeding statutory 48h resolution limits',
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
              title: 'Zero SLA Breaches',
              message: 'All open municipal grievances are currently progressing within statutory timeframes.',
              icon: Icons.verified_user_outlined,
              isCompact: true,
            ),
          ),
        ],
      );
    }

    final columns = [
      const GovtDataColumn(label: 'Ticket #', width: 130),
      const GovtDataColumn(label: 'Ward', width: 95),
      const GovtDataColumn(label: 'Department', width: 160),
      const GovtDataColumn(label: 'Priority', width: 110),
      const GovtDataColumn(label: 'Status', width: 125),
      const GovtDataColumn(label: 'Time Overdue', width: 140),
      const GovtDataColumn(label: 'Assigned Lead / Officer', width: 170),
      const GovtDataColumn(label: 'Reassignments', width: 110, isNumeric: true),
      const GovtDataColumn(label: 'Action', width: 90, alignment: Alignment.center),
    ];

    final rows = list.take(10).map((c) {
      final wardStr = c.wardId ?? c.location.ward ?? '—';
      final elapsedHours = now.difference(c.slaStartedAt).inHours;
      final overdueHours = (elapsedHours - 48).clamp(1, 9999);
      final assignedStr = c.assignedTo != null && c.assignedTo!.isNotEmpty
          ? c.assignedTo!
          : (c.assignedDepartmentLeadId ?? 'Unassigned');

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
        // Ward
        GovtJurisdictionBadge.ward(wardStr, isCompact: true, withBrackets: false),
        // Department
        Text(
          c.effectiveDepartment,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GovtTypography.bodySmall,
        ),
        // Priority
        GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
        // Status
        GovtStatusBadge.complaint(c.status, isCompact: true),
        // Time Overdue
        GovtSlaBadge.breached(overdueText: '+$overdueHours hrs overdue', isCompact: true),
        // Assigned Lead / Officer
        Text(
          assignedStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        // Reassignments
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.reassignmentCount > 0
                ? const Color(0xFFFEF8EC)
                : GovtThemeTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${c.reassignmentCount}x',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.reassignmentCount > 0 ? const Color(0xFFD97706) : GovtThemeTokens.textSecondary,
            ),
          ),
        ),
        // Action
        TextButton(
          onPressed: widget.onViewComplaint != null ? () => widget.onViewComplaint!(c.id) : null,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: GovtThemeTokens.primary,
          ),
          child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'SLA Breaches Requiring Attention',
          subtitle: 'Supervisory monitoring for grievances exceeding statutory 48h resolution limits',
          count: widget.slaBreachedComplaints.length,
          action: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.sm),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'most_overdue', child: Text('Sort: Most Overdue')),
                  DropdownMenuItem(value: 'priority', child: Text('Sort: Highest Priority')),
                  DropdownMenuItem(value: 'ward', child: Text('Sort: Ward')),
                  DropdownMenuItem(value: 'department', child: Text('Sort: Department')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sortBy = val);
                },
                style: GovtTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: GovtThemeTokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
        CivicFixSpacing.vSpaceSm,
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: widget.isLoading,
          title: 'Lapsed Grievances Escalation Ledger',
          totalCount: list.length,
          pageSize: 10,
          minWidth: 1200,
        ),
      ],
    );
  }
}
