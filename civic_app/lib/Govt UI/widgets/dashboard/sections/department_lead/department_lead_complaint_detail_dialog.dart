import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../complaints/shared/government_evidence_gallery.dart';

/// Modal dialog for detailed operational complaint view with state-aware actions.
class DepartmentLeadComplaintDetailDialog extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onAssignCrew;
  final VoidCallback? onReassignCrew;
  final VoidCallback? onRaiseRoutingTicket;
  final VoidCallback? onVerifyCompletion;

  const DepartmentLeadComplaintDetailDialog({
    super.key,
    required this.complaint,
    this.onAssignCrew,
    this.onReassignCrew,
    this.onRaiseRoutingTicket,
    this.onVerifyCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final now = DateTime.now();
    final elapsed = now.difference(c.slaStartedAt).inHours;
    final totalAllowed = c.priority == ComplaintPriority.emergency
        ? 24
        : (c.priority == ComplaintPriority.high ? 36 : 48);
    final remaining = (totalAllowed - elapsed).clamp(-999, totalAllowed);
    final isBreached = elapsed > totalAllowed;
    final isResolved = c.status == ComplaintStatus.resolved;

    final isUnassigned =
        c.assignedCrewMemberId == null || c.assignedCrewMemberId!.trim().isEmpty;

    final isAwaitingVerification = !isResolved &&
        c.status != ComplaintStatus.rejected &&
        (c.status == ComplaintStatus.verified ||
            (c.status == ComplaintStatus.inProgress &&
                c.officerNotes != null &&
                c.officerNotes!.toLowerCase().contains('completion')));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 860),
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_outlined,
                      color: GovtThemeTokens.primary, size: 22),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'GRIEVANCE #${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id}',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          CivicFixSpacing.hSpaceSm,
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.status.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.status.label,
                              style: CivicFixTypography.caption.copyWith(
                                color: c.status.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Reported: ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year} ${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            CivicFixSpacing.vSpaceMd,
            const Divider(color: GovtThemeTokens.divider, height: 1),
            CivicFixSpacing.vSpaceMd,

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Description
                    Text(
                      c.title,
                      style: CivicFixTypography.bodyLarge.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      c.description,
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Key Metadata Grid
                    Container(
                      padding: const EdgeInsets.all(CivicFixSpacing.md),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GovtThemeTokens.borderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _metaChip(
                                'Category',
                                c.category.name,
                                Icons.category_outlined,
                              ),
                              _metaChip(
                                'Priority',
                                c.priority.label,
                                Icons.priority_high_rounded,
                                color: c.priority.color,
                              ),
                              _metaChip(
                                'SLA Status',
                                isBreached
                                    ? 'Breached (${elapsed - totalAllowed}h overdue)'
                                    : '${remaining}h remaining',
                                Icons.timer_outlined,
                                color: isBreached
                                    ? const Color(0xFFDC2626)
                                    : (remaining <= 12
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF10B981)),
                              ),
                            ],
                          ),
                          CivicFixSpacing.vSpaceMd,
                          Row(
                            children: [
                              _metaChip(
                                'Location',
                                '${c.location.address} (Ward ${c.location.ward})',
                                Icons.location_on_outlined,
                              ),
                              _metaChip(
                                'Department',
                                c.departmentName ?? c.assignedDepartmentId ?? 'Maintenance',
                                Icons.domain_outlined,
                              ),
                              _metaChip(
                                'Assigned Crew',
                                c.assignedTo ?? c.assignedCrewMemberId ?? 'Unassigned',
                                Icons.engineering_outlined,
                                color: isUnassigned
                                    ? const Color(0xFFF59E0B)
                                    : GovtThemeTokens.primaryDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Citizen Evidence
                    if (c.imageUrls.isNotEmpty) ...[
                      GovernmentEvidenceGallery(
                        title: 'CITIZEN REPORT EVIDENCE (${c.imageUrls.length})',
                        evidenceItems: [
                          for (int i = 0; i < c.imageUrls.length; i++)
                            GovernmentEvidenceItem(
                              imageUrl: c.imageUrls[i],
                              title: 'Citizen Report Evidence #${i + 1}',
                              stage: 'citizen',
                              timestamp: c.createdAt,
                            ),
                        ],
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(CivicFixSpacing.md),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GovtThemeTokens.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.image_not_supported_outlined,
                                size: 16, color: GovtThemeTokens.textMuted),
                            SizedBox(width: 8),
                            Text(
                              'No citizen photos attached with report.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: GovtThemeTokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                    CivicFixSpacing.vSpaceLg,

                    // Timeline & Routing History
                    Text(
                      'OPERATIONAL TIMELINE & AUDIT TRAIL',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    CivicFixSpacing.vSpaceSm,
                    if (c.timeline.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: c.timeline.length,
                        separatorBuilder: (context, index) => CivicFixSpacing.vSpaceSm,
                        itemBuilder: (ctx, i) {
                          final event = c.timeline[i];
                          return Container(
                            padding: const EdgeInsets.all(CivicFixSpacing.sm),
                            decoration: BoxDecoration(
                              color: GovtThemeTokens.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: GovtThemeTokens.borderLight),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: BoxDecoration(
                                    color: event.status.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                CivicFixSpacing.hSpaceSm,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            event.title,
                                            style: CivicFixTypography
                                                .captionMedium
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: GovtThemeTokens.textPrimary,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${event.timestamp.day}/${event.timestamp.month} ${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: CivicFixTypography.caption
                                                .copyWith(
                                              color: GovtThemeTokens.textMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        event.description,
                                        style: CivicFixTypography.caption
                                            .copyWith(
                                          color: GovtThemeTokens.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        'No lifecycle events recorded yet.',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            CivicFixSpacing.vSpaceLg,
            const Divider(color: GovtThemeTokens.divider, height: 1),
            CivicFixSpacing.vSpaceMd,

            // Context-Aware Actions Bar
            Row(
              children: [
                if (!isResolved && onRaiseRoutingTicket != null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Wrong Department'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF97316),
                      side: const BorderSide(color: Color(0xFFF97316)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onRaiseRoutingTicket!();
                    },
                  ),
                  CivicFixSpacing.hSpaceSm,
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                CivicFixSpacing.hSpaceSm,
                if (!isResolved && isUnassigned && onAssignCrew != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Assign Crew'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GovtThemeTokens.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onAssignCrew!();
                    },
                  ),
                if (!isResolved && !isUnassigned && onReassignCrew != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sync_alt_rounded, size: 16),
                    label: const Text('Reassign Crew'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GovtThemeTokens.primary,
                      side: const BorderSide(color: GovtThemeTokens.primary),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onReassignCrew!();
                    },
                  ),
                if (isAwaitingVerification && onVerifyCompletion != null) ...[
                  CivicFixSpacing.hSpaceSm,
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: const Text('Review Work & Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onVerifyCompletion!();
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.sm,
          vertical: CivicFixSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? GovtThemeTokens.textSecondary),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: color ?? GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
