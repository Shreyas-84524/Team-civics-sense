import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../services/government_jurisdiction_resolver.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_sla_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Ward-wide Complaint Queue table for Assistant Commissioner / Ward Officer.
class WardComplaintQueueSection extends StatefulWidget {
  final List<ComplaintModel> complaints;
  final String wardId;
  final bool isLoading;
  final ValueChanged<String>? onComplaintTapped;

  const WardComplaintQueueSection({
    super.key,
    required this.complaints,
    required this.wardId,
    this.isLoading = false,
    this.onComplaintTapped,
  });

  @override
  State<WardComplaintQueueSection> createState() => _WardComplaintQueueSectionState();
}

class _WardComplaintQueueSectionState extends State<WardComplaintQueueSection> {
  String _searchQuery = '';
  ComplaintPriority? _filterPriority;
  ComplaintStatus? _filterStatus;
  bool _slaBreachedOnly = false;

  List<ComplaintModel> _getFilteredList() {
    final now = DateTime.now();
    return widget.complaints.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTicket = (c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id).toLowerCase().contains(q);
        final matchTitle = c.title.toLowerCase().contains(q);
        final matchDept = c.effectiveDepartment.toLowerCase().contains(q);
        if (!matchTicket && !matchTitle && !matchDept) return false;
      }

      if (_filterPriority != null && c.priority != _filterPriority) {
        return false;
      }

      if (_filterStatus != null && c.status != _filterStatus) {
        return false;
      }

      if (_slaBreachedOnly) {
        if (c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected) return false;
        if (now.difference(c.slaStartedAt).inHours <= 48) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _getFilteredList();
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
                      child: const Icon(Icons.list_alt_rounded, color: GovtThemeTokens.primary, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WARD COMPLAINT QUEUE',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Ward-wide live grievance register across all 18 departments in Ward ${widget.wardId}',
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

              // Search Box & Filters
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 220,
                    height: 36,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search complaint ID, dept...',
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
                child: Text('No complaints match the filter criteria.', style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted)),
              ),
            )
          else if (isMobile)
            _buildMobileComplaintList(list)
          else
            _buildDesktopComplaintTable(list),
        ],
      ),
    );
  }

  Widget _buildDesktopComplaintTable(List<ComplaintModel> list) {
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
        columnSpacing: 16,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('COMPLAINT ID')),
          DataColumn(label: Text('DEPARTMENT')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('PRIORITY')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('SLA')),
          DataColumn(label: Text('DEPT LEAD')),
          DataColumn(label: Text('ASSIGNED CREW')),
          DataColumn(label: Text('REPORTED TIME')),
          DataColumn(label: Text('TRANSFERS'), numeric: true),
          DataColumn(label: Text('ACTION')),
        ],
        rows: list.map((c) {
          final reportedTimeStr = '${c.createdAt.day}/${c.createdAt.month} ${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}';
          final deptName = GovernmentJurisdictionResolver.resolveDepartment(c.assignedDepartmentId ?? c.category.id);

          return DataRow(
            cells: [
              // Complaint ID
              DataCell(
                InkWell(
                  onTap: widget.onComplaintTapped != null ? () => widget.onComplaintTapped!(c.id) : null,
                  child: Text(
                    c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              // Department
              DataCell(Text(deptName, style: CivicFixTypography.bodySmallMedium)),

              // Category
              DataCell(Text(c.category.name, style: CivicFixTypography.caption)),

              // Priority
              DataCell(GovtPriorityBadge.fromPriority(c.priority, isCompact: true)),

              // Status
              DataCell(GovtStatusBadge.complaint(c.status, isCompact: true)),

              // SLA Badge
              DataCell(GovtSlaBadge.fromDuration(createdAt: c.slaStartedAt, resolvedAt: c.resolvedAt, isCompact: true)),

              // Dept Lead
              DataCell(Text(c.assignedTo ?? 'Executive Engineer', style: CivicFixTypography.caption)),

              // Assigned Crew
              DataCell(Text(c.assignedCrewMemberId ?? 'Unassigned', style: CivicFixTypography.caption)),

              // Reported Time
              DataCell(Text(reportedTimeStr, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted))),

              // Reassignment Count
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.reassignmentCount > 0 ? GovtThemeTokens.warningLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${c.reassignmentCount}',
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: c.reassignmentCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: c.reassignmentCount > 0 ? GovtThemeTokens.warning : GovtThemeTokens.textMuted,
                    ),
                  ),
                ),
              ),

              // Action
              DataCell(
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  onPressed: widget.onComplaintTapped != null ? () => widget.onComplaintTapped!(c.id) : null,
                  tooltip: 'View details',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileComplaintList(List<ComplaintModel> list) {
    return Column(
      children: list.map((c) {
        final deptName = GovernmentJurisdictionResolver.resolveDepartment(c.assignedDepartmentId ?? c.category.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: GovtThemeTokens.border),
          ),
          child: ListTile(
            onTap: widget.onComplaintTapped != null ? () => widget.onComplaintTapped!(c.id) : null,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                  style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700, color: GovtThemeTokens.primary),
                ),
                GovtStatusBadge.complaint(c.status, isCompact: true),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CivicFixSpacing.vSpaceXs,
                Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.bodySmall),
                CivicFixSpacing.vSpaceXs,
                Text('Dept: $deptName · Transfers: ${c.reassignmentCount}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
          ),
        );
      }).toList(),
    );
  }
}
