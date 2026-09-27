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

/// Unresolved Critical & Emergency Public Safety Hazards in Ward.
class WardCriticalComplaintsSection extends StatelessWidget {
  final List<ComplaintModel> criticalComplaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel>? onComplaintTapped;

  const WardCriticalComplaintsSection({
    super.key,
    required this.criticalComplaints,
    this.isLoading = false,
    this.onComplaintTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emergency_rounded, color: GovtThemeTokens.error, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'CRITICAL & EMERGENCY COMPLAINTS',
                                style: CivicFixTypography.h3.copyWith(
                                  color: GovtThemeTokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: criticalComplaints.isNotEmpty ? GovtThemeTokens.error : GovtThemeTokens.success,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${criticalComplaints.length} ACTIVE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'High-severity public safety hazards and emergency escalations requiring immediate action',
                            style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (criticalComplaints.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.verified_rounded, color: GovtThemeTokens.success, size: 36),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'Zero active critical grievances in this ward. All emergency hazards resolved.',
                      style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else if (isMobile)
            _buildMobileList()
          else
            _buildDesktopTable(),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
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
        columns: const [
          DataColumn(label: Text('TICKET')),
          DataColumn(label: Text('DEPARTMENT')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('PRIORITY')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('SLA STATUS')),
          DataColumn(label: Text('ASSIGNED LEAD')),
          DataColumn(label: Text('ASSIGNED CREW')),
          DataColumn(label: Text('REPORTED AT')),
          DataColumn(label: Text('ACTION')),
        ],
        rows: criticalComplaints.map((c) {
          final deptName = GovernmentJurisdictionResolver.resolveDepartment(c.assignedDepartmentId ?? c.category.id);
          final reportedTimeStr = '${c.createdAt.day}/${c.createdAt.month} ${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}';

          return DataRow(
            cells: [
              // Ticket
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primary,
                      ),
                    ),
                    Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 10),
                    ),
                  ],
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

              // SLA Status
              DataCell(GovtSlaBadge.fromDuration(createdAt: c.slaStartedAt, resolvedAt: c.resolvedAt, isCompact: true)),

              // Dept Lead
              DataCell(Text(c.assignedTo ?? 'Executive Engineer', style: CivicFixTypography.caption)),

              // Assigned Crew
              DataCell(Text(c.assignedCrewMemberId ?? 'Unassigned', style: CivicFixTypography.caption)),

              // Reported Time
              DataCell(Text(reportedTimeStr, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted))),

              // Action
              DataCell(
                OutlinedButton.icon(
                  onPressed: onComplaintTapped != null ? () => onComplaintTapped!(c) : null,
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Complaint'),
                  style: OutlinedButton.styleFrom(
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

  Widget _buildMobileList() {
    return Column(
      children: criticalComplaints.map((c) {
        final deptName = GovernmentJurisdictionResolver.resolveDepartment(c.assignedDepartmentId ?? c.category.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                      style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700, color: GovtThemeTokens.primary),
                    ),
                    GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(c.title, style: CivicFixTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                CivicFixSpacing.vSpaceXs,
                Text('Dept: $deptName · Status: ${c.status.name}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted)),
                CivicFixSpacing.vSpaceMd,
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onComplaintTapped != null ? () => onComplaintTapped!(c) : null,
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View Complaint'),
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
}
