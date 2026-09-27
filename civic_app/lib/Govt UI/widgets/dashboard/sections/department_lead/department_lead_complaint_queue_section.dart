import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../models/govt_user_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Primary Complaint Queue Section for Ward Department Lead Operations Center.
/// Displays all grievances belonging strictly to this Ward × Department unit with
/// comprehensive unit-level filters (Priority, Status, SLA, Crew, Search) and quick actions.
class DepartmentLeadComplaintQueueSection extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final List<GovtUserModel> crewMembers;
  final bool isLoading;

  // Filters
  final ComplaintPriority? selectedPriority;
  final ComplaintStatus? selectedStatus;
  final String? selectedCrew;
  final String? selectedSla;
  final String searchQuery;

  // Filter Callbacks
  final ValueChanged<ComplaintPriority?> onPriorityChanged;
  final ValueChanged<ComplaintStatus?> onStatusChanged;
  final ValueChanged<String?> onCrewChanged;
  final ValueChanged<String?> onSlaChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onResetFilters;

  // Actions
  final ValueChanged<ComplaintModel> onViewDetails;
  final ValueChanged<ComplaintModel> onAssignCrew;
  final ValueChanged<ComplaintModel> onReassignCrew;
  final ValueChanged<ComplaintModel> onRaiseRoutingTicket;
  final ValueChanged<ComplaintModel> onReviewWork;

  const DepartmentLeadComplaintQueueSection({
    super.key,
    required this.complaints,
    required this.crewMembers,
    this.isLoading = false,
    this.selectedPriority,
    this.selectedStatus,
    this.selectedCrew,
    this.selectedSla,
    this.searchQuery = '',
    required this.onPriorityChanged,
    required this.onStatusChanged,
    required this.onCrewChanged,
    required this.onSlaChanged,
    required this.onSearchChanged,
    required this.onResetFilters,
    required this.onViewDetails,
    required this.onAssignCrew,
    required this.onReassignCrew,
    required this.onRaiseRoutingTicket,
    required this.onReviewWork,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    final activeFilterCount = (selectedPriority != null ? 1 : 0) +
        (selectedStatus != null ? 1 : 0) +
        (selectedCrew != null && selectedCrew != 'all' ? 1 : 0) +
        (selectedSla != null && selectedSla != 'all' ? 1 : 0) +
        (searchQuery.trim().isNotEmpty ? 1 : 0);

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
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.table_chart_outlined,
                    color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT COMPLAINT QUEUE',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Comprehensive live operational register of grievances assigned to this unit',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${complaints.length} Complaints',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Multi-Criteria Unit Filter Bar
          _buildFilterBar(context, activeFilterCount),
          CivicFixSpacing.vSpaceLg,

          // Table / Cards
          if (complaints.isEmpty)
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 40, color: GovtThemeTokens.textMuted),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'No Complaints Found',
                    style: CivicFixTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                  Text(
                    activeFilterCount > 0
                        ? 'Try clearing active filters to see all complaints.'
                        : 'No active grievances currently assigned to this department unit.',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    CivicFixSpacing.vSpaceMd,
                    TextButton.icon(
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                      label: const Text('Clear All Filters'),
                      onPressed: onResetFilters,
                    ),
                  ],
                ],
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: complaints.length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (ctx, i) {
                final c = complaints[i];
                return _buildMobileComplaintCard(c);
              },
            )
          else
            _buildDesktopTable(context),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, int activeFilterCount) {
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
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search complaints, title, address...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              // Priority Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: DropdownButtonFormField<ComplaintPriority?>(
                    isExpanded: true,
                    initialValue: selectedPriority,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                    ),
                    hint: const Text('Priority: All',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                    items: [
                      const DropdownMenuItem<ComplaintPriority?>(
                        value: null,
                        child: Text('Priority: All',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      ...ComplaintPriority.values.map(
                        (p) => DropdownMenuItem<ComplaintPriority?>(
                          value: p,
                          child: Text(p.label,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: onPriorityChanged,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              // Status Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: DropdownButtonFormField<ComplaintStatus?>(
                    isExpanded: true,
                    initialValue: selectedStatus,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                    ),
                    hint: const Text('Status: All',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                    items: [
                      const DropdownMenuItem<ComplaintStatus?>(
                        value: null,
                        child: Text('Status: All',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      ...ComplaintStatus.values.map(
                        (s) => DropdownMenuItem<ComplaintStatus?>(
                          value: s,
                          child: Text(s.label,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: onStatusChanged,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              // Crew Filter
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: selectedCrew,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                    ),
                    hint: const Text('Crew: All',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Crew: All',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      ...crewMembers.map(
                        (cr) => DropdownMenuItem<String?>(
                          value: cr.employeeId,
                          child: Text(cr.fullName,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: onCrewChanged,
                  ),
                ),
              ),
              if (activeFilterCount > 0) ...[
                CivicFixSpacing.hSpaceSm,
                IconButton(
                  tooltip: 'Reset Filters',
                  icon: const Icon(Icons.restart_alt_rounded,
                      color: GovtThemeTokens.alert),
                  onPressed: onResetFilters,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final now = DateTime.now();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2), // Complaint ID & Title
          1: FlexColumnWidth(1.4), // Category
          2: FlexColumnWidth(1.2), // Priority
          3: FlexColumnWidth(1.2), // Status
          4: FlexColumnWidth(1.4), // SLA
          5: FlexColumnWidth(1.3), // Reported Time
          6: FlexColumnWidth(1.5), // Assigned Crew
          7: FlexColumnWidth(1.3), // Routing Status
          8: FlexColumnWidth(2.0), // Actions
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
            ),
            children: [
              _tableHeader('COMPLAINT'),
              _tableHeader('CATEGORY'),
              _tableHeader('PRIORITY'),
              _tableHeader('STATUS'),
              _tableHeader('SLA CLOCK'),
              _tableHeader('REPORTED'),
              _tableHeader('ASSIGNED CREW'),
              _tableHeader('ROUTING'),
              _tableHeader('ACTIONS'),
            ],
          ),
          ...complaints.map((c) {
            final elapsed = now.difference(c.slaStartedAt).inHours;
            final totalAllowed = c.priority == ComplaintPriority.emergency
                ? 24
                : (c.priority == ComplaintPriority.high ? 36 : 48);
            final remaining = (totalAllowed - elapsed).clamp(-999, totalAllowed);
            final isBreached = elapsed > totalAllowed;

            final isUnassigned = c.assignedCrewMemberId == null ||
                c.assignedCrewMemberId!.trim().isEmpty;

            final isResolved = c.status == ComplaintStatus.resolved;

            final isAwaitingVerification = !isResolved &&
                c.status != ComplaintStatus.rejected &&
                (c.status == ComplaintStatus.verified ||
                    (c.status == ComplaintStatus.inProgress &&
                        c.officerNotes != null &&
                        c.officerNotes!.toLowerCase().contains('completion')));

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight),
                ),
              ),
              children: [
                // Complaint ID & Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: InkWell(
                    onTap: () => onViewDetails(c),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          c.title,
                          style: CivicFixTypography.bodySmall.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Category
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    c.category.name,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Priority
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.priority.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: c.priority.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        c.priority.label,
                        style: CivicFixTypography.caption.copyWith(
                          color: c.priority.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.status.label,
                      style: CivicFixTypography.caption.copyWith(
                        color: c.status.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

                // SLA Clock
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    isBreached
                        ? 'Breached (-${elapsed - totalAllowed}h)'
                        : '${remaining}h left',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: isBreached
                          ? const Color(0xFFDC2626)
                          : (remaining <= 12
                              ? const Color(0xFFF97316)
                              : const Color(0xFF10B981)),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Reported Time
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${c.createdAt.day}/${c.createdAt.month} ${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Assigned Crew
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    isUnassigned
                        ? 'Unassigned'
                        : (c.assignedTo ?? c.assignedCrewMemberId!),
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: isUnassigned
                          ? const Color(0xFFF59E0B)
                          : GovtThemeTokens.textPrimary,
                      fontWeight:
                          isUnassigned ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Routing Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    c.routingStatus ==
                            ComplaintRoutingStatus.reassignmentRequested
                        ? 'Reassign Req.'
                        : c.routingStatus.name,
                    style: CivicFixTypography.caption.copyWith(
                      color: c.routingStatus ==
                              ComplaintRoutingStatus.reassignmentRequested
                          ? const Color(0xFFF97316)
                          : GovtThemeTokens.textSecondary,
                      fontWeight: c.routingStatus ==
                              ComplaintRoutingStatus.reassignmentRequested
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View
                      IconButton(
                        tooltip: 'View Details',
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        onPressed: () => onViewDetails(c),
                      ),

                      // Assign / Reassign
                      if (!isResolved)
                        IconButton(
                          tooltip: isUnassigned
                              ? 'Assign Crew'
                              : 'Reassign Crew',
                          icon: Icon(
                            isUnassigned
                                ? Icons.person_add_alt_1_rounded
                                : Icons.sync_alt_rounded,
                            size: 16,
                            color: isUnassigned
                                ? const Color(0xFFF59E0B)
                                : GovtThemeTokens.primary,
                          ),
                          onPressed: () => isUnassigned
                              ? onAssignCrew(c)
                              : onReassignCrew(c),
                        ),

                      // Wrong Dept
                      if (!isResolved)
                        IconButton(
                          tooltip: 'Wrong Department',
                          icon: const Icon(Icons.swap_horiz_rounded,
                              size: 16, color: Color(0xFFF97316)),
                          onPressed: () => onRaiseRoutingTicket(c),
                        ),

                      // Verify Work
                      if (isAwaitingVerification)
                        IconButton(
                          tooltip: 'Verify Completion',
                          icon: const Icon(Icons.fact_check_outlined,
                              size: 16, color: Color(0xFF10B981)),
                          onPressed: () => onReviewWork(c),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileComplaintCard(ComplaintModel c) {
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
            children: [
              Text(
                c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                c.status.label,
                style: CivicFixTypography.caption.copyWith(
                  color: c.status.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            c.title,
            style: CivicFixTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Crew: ${c.assignedTo ?? c.assignedCrewMemberId ?? "Unassigned"} · ${c.category.name}',
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textSecondary,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          Row(
            children: [
              TextButton(
                onPressed: () => onViewDetails(c),
                child: const Text('View'),
              ),
              const Spacer(),
              if (c.status != ComplaintStatus.resolved)
                ElevatedButton(
                  onPressed: () => c.assignedCrewMemberId == null
                      ? onAssignCrew(c)
                      : onReassignCrew(c),
                  child: Text(c.assignedCrewMemberId == null
                      ? 'Assign'
                      : 'Reassign'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.sm),
      child: Text(
        text,
        style: CivicFixTypography.captionMedium.copyWith(
          color: GovtThemeTokens.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
