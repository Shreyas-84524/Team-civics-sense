import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Critical / Urgent Complaints" Section for Ward Department Lead Operations Center.
/// Displays grievances marked as Emergency or High priority within this Ward × Department unit.
class DepartmentLeadCriticalComplaintsSection extends StatelessWidget {
  final List<ComplaintModel> criticalComplaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel>? onAssignCrew;
  final ValueChanged<ComplaintModel>? onViewDetails;

  const DepartmentLeadCriticalComplaintsSection({
    super.key,
    required this.criticalComplaints,
    this.isLoading = false,
    this.onAssignCrew,
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
          color: criticalComplaints.isNotEmpty
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444), size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRITICAL & EMERGENCY HAZARDS',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'High-severity grievances requiring expedited intervention and crew attention',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                CivicFixSpacing.hSpaceSm,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: criticalComplaints.isNotEmpty
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: criticalComplaints.isNotEmpty
                          ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                          : GovtThemeTokens.borderLight,
                    ),
                  ),
                  child: Text(
                    '${criticalComplaints.length} Critical Emergencies',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: criticalComplaints.isNotEmpty
                          ? const Color(0xFFDC2626)
                          : GovtThemeTokens.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (criticalComplaints.isEmpty)
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 36, color: Color(0xFF10B981)),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'No Critical Emergencies',
                    style: CivicFixTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                  Text(
                    'No emergency or severe hazard grievances currently pending in this unit.',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: criticalComplaints.length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (ctx, i) {
                final c = criticalComplaints[i];
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
          0: FlexColumnWidth(2.5), // Complaint
          1: FlexColumnWidth(1.4), // Priority
          2: FlexColumnWidth(1.4), // SLA
          3: FlexColumnWidth(1.6), // Crew
          4: FlexColumnWidth(1.2), // Status
          5: FlexColumnWidth(1.4), // Action
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
            ),
            children: [
              _tableHeader('COMPLAINT'),
              _tableHeader('PRIORITY'),
              _tableHeader('SLA CLOCK'),
              _tableHeader('ASSIGNED CREW'),
              _tableHeader('STATUS'),
              _tableHeader('ACTION'),
            ],
          ),
          ...criticalComplaints.map((c) {
            final elapsed = now.difference(c.slaStartedAt).inHours;
            final isBreached = elapsed > 48;
            final isUnassigned = c.assignedCrewMemberId == null ||
                c.assignedCrewMemberId!.trim().isEmpty;

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

                // Priority
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.priority.color.withValues(alpha: 0.12),
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

                // SLA
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    isBreached ? 'Breached (+${elapsed - 48}h)' : '${48 - elapsed}h left',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: isBreached
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFF97316),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Crew
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    isUnassigned
                        ? 'Unassigned (Action Required)'
                        : (c.assignedTo ?? c.assignedCrewMemberId!),
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: isUnassigned
                          ? const Color(0xFFF59E0B)
                          : GovtThemeTokens.textPrimary,
                      fontWeight: isUnassigned ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),

                // Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    c.status.label,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: c.status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Action
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: isUnassigned && onAssignCrew != null
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => onAssignCrew!(c),
                          child: const Text('DISPATCH'),
                        )
                      : TextButton(
                          onPressed: onViewDetails != null
                              ? () => onViewDetails!(c)
                              : null,
                          child: const Text('View Details'),
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
    final isUnassigned =
        c.assignedCrewMemberId == null || c.assignedCrewMemberId!.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
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
                c.priority.label,
                style: CivicFixTypography.caption.copyWith(
                  color: c.priority.color,
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
            'Crew: ${isUnassigned ? "UNASSIGNED" : (c.assignedTo ?? c.assignedCrewMemberId)} · Status: ${c.status.label}',
            style: CivicFixTypography.caption.copyWith(
              color: isUnassigned
                  ? const Color(0xFFF59E0B)
                  : GovtThemeTokens.textSecondary,
              fontWeight: isUnassigned ? FontWeight.w700 : FontWeight.w500,
            ),
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
