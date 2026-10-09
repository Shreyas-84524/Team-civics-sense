import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/complaint_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/status_badge.dart';

/// Full interactive card summarizing a civic complaint report.
class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onTap;
  final VoidCallback? onUpvote;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    final locationSelectedText =
        context.l10nOrNull?.locationSelected ?? 'Location selected';
    final locationText = complaint.location.shortDisplayAddress.isNotEmpty
        ? complaint.location.shortDisplayAddress
        : (complaint.location.address.isNotEmpty
            ? complaint.location.address
            : locationSelectedText);

    final updatedTimeText = DateFormatter.formatRelativeTime(complaint.updatedAt);
    final statusLabel = complaint.status.localizedLabel(context);

    final semanticDescription =
        'Complaint ${complaint.ticketNumber}, ${complaint.title}, status $statusLabel, category ${complaint.category.name}, located near $locationText, updated $updatedTimeText.';

    return Semantics(
      label: semanticDescription,
      button: true,
      child: CivicFixCard(
        onTap: onTap,
        padding: const EdgeInsets.all(CivicFixSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Ticket Number & Category on left, Status and Sync badges on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: complaint.ticketNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10nOrNull?.complaintIdCopied(complaint.ticketNumber) ??
                              'Complaint ID ${complaint.ticketNumber} copied.',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: CivicFixRadius.chipRadius,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        complaint.ticketNumber,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.border,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        complaint.category.name,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (complaint.syncStatus == SyncStatus.pending) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CivicFixColors.statusInProgressBg,
                          borderRadius: CivicFixRadius.chipRadius,
                          border: Border.all(
                            color: CivicFixColors.alertDark.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 11,
                              color: CivicFixColors.alertDark,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              context.l10nOrNull?.pendingSync ?? 'Pending Sync',
                              style: CivicFixTypography.captionMedium.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: CivicFixColors.alertDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else if (complaint.syncStatus == SyncStatus.syncing) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CivicFixColors.statusUnderReviewBg,
                          borderRadius: CivicFixRadius.chipRadius,
                          border: Border.all(
                            color: CivicFixColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: CivicFixColors.info),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10nOrNull?.syncing ?? 'Syncing...',
                              style: CivicFixTypography.captionMedium.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: CivicFixColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else if (complaint.syncStatus == SyncStatus.failed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CivicFixColors.statusRejectedBg,
                          borderRadius: CivicFixRadius.chipRadius,
                          border: Border.all(
                            color: CivicFixColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sync_problem_rounded,
                              size: 11,
                              color: CivicFixColors.error,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              context.l10nOrNull?.syncFailed ?? 'Sync Failed',
                              style: CivicFixTypography.captionMedium.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: CivicFixColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    StatusBadge(status: complaint.status, isCompact: true),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              complaint.title,
              style: CivicFixTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: CivicFixColors.primaryText,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            CivicFixSpacing.vSpaceXs,

            // Location row
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: CivicFixColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationText,
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Handling Officer or Phase Indicator
            if (complaint.isReopened) ...[
              CivicFixSpacing.vSpaceXs,
              Row(
                children: [
                  const Icon(
                    Icons.replay_circle_filled_rounded,
                    size: 13,
                    color: CivicFixColors.alertDark,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      context.l10nOrNull?.reopenedForQualityRework ??
                          'Reopened for quality rework',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.alertDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else if (complaint.isFieldOfficerAssigned) ...[
              CivicFixSpacing.vSpaceXs,
              Row(
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 13,
                    color: CivicFixColors.info,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${context.l10nOrNull?.fieldOfficer ?? "Field Officer"}: ${complaint.assignedFieldOfficerName ?? (context.l10nOrNull?.statusAssigned ?? "Assigned")}',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else if (complaint.isJuniorEngineerAssigned) ...[
              CivicFixSpacing.vSpaceXs,
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 13,
                    color: CivicFixColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${context.l10nOrNull?.supervisingJuniorEngineer ?? "Supervising JE"}: ${complaint.assignedJuniorEngineerName ?? (context.l10nOrNull?.statusAssigned ?? "Assigned")}',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            CivicFixSpacing.vSpaceMd,

            const Divider(height: 1, color: CivicFixColors.border),
            CivicFixSpacing.vSpaceSm,

            // Footer: Last updated time + Hazard pill or upvotes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: CivicFixColors.disabledText,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          context.l10nOrNull != null
                              ? context.l10n.updatedTime(updatedTimeText)
                              : 'Updated $updatedTimeText',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CivicFixSpacing.sm),
                if (complaint.isHazard)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CivicFixColors.statusUnderReviewBg,
                      borderRadius: CivicFixRadius.chipRadius,
                      border: Border.all(
                        color: CivicFixColors.alertDark.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: CivicFixColors.alertDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10nOrNull?.safetyHazard ?? 'Safety Hazard',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.alertDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onUpvote,
                      borderRadius: CivicFixRadius.chipRadius,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              complaint.upvotes > 0
                                  ? Icons.thumb_up_alt_rounded
                                  : Icons.thumb_up_alt_outlined,
                              size: 13,
                              color: complaint.upvotes > 0
                                  ? CivicFixColors.primary
                                  : CivicFixColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              complaint.upvotes > 0
                                  ? (context.l10nOrNull != null
                                      ? context.l10n.supportsCount(complaint.upvotes)
                                      : '${complaint.upvotes} supports')
                                  : (context.l10nOrNull?.support ?? 'Support'),
                              style: CivicFixTypography.caption.copyWith(
                                color: complaint.upvotes > 0
                                    ? CivicFixColors.primary
                                    : CivicFixColors.secondaryText,
                                fontSize: 11,
                                fontWeight: complaint.upvotes > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
