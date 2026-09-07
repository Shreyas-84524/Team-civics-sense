import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../theme/govt_theme_tokens.dart';

/// Adaptive Card Representation of a Complaint for Tablet / Mobile / Grid views.
class GovtComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onUpdateStatus;

  const GovtComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
    this.onAssign,
    this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: GovtThemeTokens.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: GovtThemeTokens.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Ticket Number & Status / Priority Badges
                Wrap(
                  spacing: CivicFixSpacing.xs,
                  runSpacing: CivicFixSpacing.xs,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CivicFixSpacing.sm,
                        vertical: CivicFixSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF3F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        complaint.ticketNumber,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PriorityBadge(priority: complaint.priority, isCompact: true),
                        CivicFixSpacing.hSpaceXs,
                        StatusBadge(status: complaint.status, isCompact: true),
                      ],
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,

                // Title
                Text(
                  complaint.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.h3.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,

                // Location info
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: GovtThemeTokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${complaint.location.address} • ${complaint.location.ward ?? "Central Zone"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,

                // Metadata Bar
                Row(
                  children: [
                    Icon(
                      complaint.category.icon,
                      size: 14,
                      color: GovtThemeTokens.primaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      complaint.category.name,
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormatter.formatRelative(complaint.createdAt),
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textDisabled,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                // Department & Assigned Officer Info
                CivicFixSpacing.vSpaceSm,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicFixSpacing.sm,
                    vertical: CivicFixSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: complaint.assignedTo != null
                        ? const Color(0xFFE8F2F8)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: complaint.assignedTo != null
                          ? GovtThemeTokens.info.withValues(alpha: 0.2)
                          : GovtThemeTokens.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        complaint.assignedTo != null
                            ? Icons.engineering_outlined
                            : Icons.assignment_late_outlined,
                        size: 13,
                        color: complaint.assignedTo != null
                            ? GovtThemeTokens.info
                            : GovtThemeTokens.textDisabled,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          complaint.assignedTo != null
                              ? 'Assigned: ${complaint.assignedTo} (${complaint.effectiveDepartment})'
                              : 'Unassigned • ${complaint.effectiveDepartment}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: complaint.assignedTo != null
                                ? GovtThemeTokens.info
                                : GovtThemeTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons Bar
                if (onTap != null || onAssign != null || onUpdateStatus != null) ...[
                  CivicFixSpacing.vSpaceMd,
                  const Divider(color: GovtThemeTokens.border, height: 1),
                  CivicFixSpacing.vSpaceSm,
                  Wrap(
                    spacing: CivicFixSpacing.xs,
                    runSpacing: CivicFixSpacing.xs,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (onTap != null)
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.visibility_outlined, size: 14),
                          label: const Text('Details', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: GovtThemeTokens.textSecondary,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      if (onAssign != null)
                        TextButton.icon(
                          onPressed: onAssign,
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                          label: const Text('Assign', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: GovtThemeTokens.primary,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      if (onUpdateStatus != null)
                        ElevatedButton.icon(
                          onPressed: onUpdateStatus,
                          icon: const Icon(Icons.sync_rounded, size: 14),
                          label: const Text('Update Status', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GovtThemeTokens.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
