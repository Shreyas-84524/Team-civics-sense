import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Needs Assignment" section for Ward Department Lead Operations Center.
/// Prominently displays all grievances within this Ward × Department unit
/// that have not yet been assigned to any ground crew technician.
class DepartmentLeadUnassignedSection extends StatelessWidget {
  final List<ComplaintModel> unassignedComplaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel> onAssignCrew;
  final ValueChanged<ComplaintModel>? onViewDetails;

  const DepartmentLeadUnassignedSection({
    super.key,
    required this.unassignedComplaints,
    this.isLoading = false,
    required this.onAssignCrew,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: unassignedComplaints.isNotEmpty
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : GovtThemeTokens.border,
        ),
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
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.assignment_late_outlined,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEEDS ASSIGNMENT — UNASSIGNED GRIEVANCES',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Complaints requiring immediate field crew technician dispatch',
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
                  color: unassignedComplaints.isNotEmpty
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                      : GovtThemeTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unassignedComplaints.isNotEmpty
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                        : GovtThemeTokens.borderLight,
                  ),
                ),
                child: Text(
                  '${unassignedComplaints.length} Pending Dispatch',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: unassignedComplaints.isNotEmpty
                        ? const Color(0xFFB45309)
                        : GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (unassignedComplaints.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: CivicFixSpacing.lg, vertical: CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 40, color: Color(0xFF10B981)),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'All Grievances Assigned',
                    style: CivicFixTypography.bodyMedium.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Every active complaint in this department unit is currently assigned to a field crew member.',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unassignedComplaints.length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (ctx, i) {
                final c = unassignedComplaints[i];
                return _buildMobileCard(c);
              },
            )
          else
            _buildDesktopTable(context),
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
          0: FlexColumnWidth(2.5), // Complaint & Title
          1: FlexColumnWidth(1.5), // Category
          2: FlexColumnWidth(1.2), // Priority
          3: FlexColumnWidth(1.4), // SLA Remaining
          4: FlexColumnWidth(1.4), // Reported At
          5: FlexColumnWidth(1.6), // Action
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
              _tableHeader('SLA REMAINING'),
              _tableHeader('REPORTED AT'),
              _tableHeader('PRIMARY ACTION'),
            ],
          ),
          ...unassignedComplaints.map((c) {
            final elapsed = now.difference(c.slaStartedAt).inHours;
            final totalAllowed = c.priority == ComplaintPriority.emergency
                ? 24
                : (c.priority == ComplaintPriority.high ? 36 : 48);
            final remaining = (totalAllowed - elapsed).clamp(-999, totalAllowed);
            final isBreached = elapsed > totalAllowed;

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight),
                ),
              ),
              children: [
                // Complaint
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: InkWell(
                    onTap: onViewDetails != null ? () => onViewDetails!(c) : null,
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
                          horizontal: 8, vertical: 2),
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

                // SLA Remaining
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: isBreached
                            ? const Color(0xFFDC2626)
                            : (remaining <= 12
                                ? const Color(0xFFF97316)
                                : const Color(0xFF10B981)),
                      ),
                      CivicFixSpacing.hSpaceXs,
                      Text(
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
                    ],
                  ),
                ),

                // Reported At
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}\n${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Action
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                    label: const Text('ASSIGN CREW'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => onAssignCrew(c),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCard(ComplaintModel c) {
    final now = DateTime.now();
    final elapsed = now.difference(c.slaStartedAt).inHours;
    final totalAllowed = c.priority == ComplaintPriority.emergency
        ? 24
        : (c.priority == ComplaintPriority.high ? 36 : 48);
    final remaining = (totalAllowed - elapsed).clamp(-999, totalAllowed);
    final isBreached = elapsed > totalAllowed;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.priority.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
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
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            c.title,
            style: CivicFixTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Category: ${c.category.name} · SLA: ${isBreached ? "Breached" : "${remaining}h remaining"}',
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textSecondary,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          Row(
            children: [
              if (onViewDetails != null)
                TextButton(
                  onPressed: () => onViewDetails!(c),
                  child: const Text('View Details'),
                ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                label: const Text('ASSIGN CREW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => onAssignCrew(c),
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
