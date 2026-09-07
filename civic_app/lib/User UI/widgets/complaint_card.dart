import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
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

  void _copyTicketId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: complaint.ticketNumber));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complaint ID ${complaint.ticketNumber} copied.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationText = complaint.location.shortDisplayAddress.isNotEmpty
        ? complaint.location.shortDisplayAddress
        : (complaint.location.address.isNotEmpty
            ? complaint.location.address
            : 'Location selected');

    final updatedTimeText = DateFormatter.formatRelativeTime(complaint.updatedAt);
    final hasImages = complaint.imageUrls.isNotEmpty;

    final semanticDescription =
        'Complaint ${complaint.ticketNumber}, ${complaint.title}, status ${complaint.status.label}, category ${complaint.category.name}, located near $locationText, updated $updatedTimeText.';

    return Semantics(
      label: semanticDescription,
      button: true,
      child: CivicFixCard(
        onTap: onTap,
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status Badge + Category Pill + Copy ID Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Pill
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CivicFixColors.surfaceMuted,
                            borderRadius: CivicFixRadius.chipRadius,
                            border: Border.all(color: CivicFixColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                complaint.category.icon,
                                size: 13,
                                color: CivicFixColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  complaint.category.name,
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    fontSize: 11,
                                    color: CivicFixColors.primaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      // Ticket Number with Copy trigger
                      InkWell(
                        onTap: () => _copyTicketId(context),
                        borderRadius: CivicFixRadius.chipRadius,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                complaint.ticketNumber,
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: CivicFixColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.copy_rounded,
                                size: 11,
                                color: CivicFixColors.secondaryText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                StatusBadge(status: complaint.status, isCompact: true),
              ],
            ),
            CivicFixSpacing.vSpaceMd,

            // Middle: Title & Optional Thumbnail
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      CivicFixSpacing.vSpaceSm,

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
                    ],
                  ),
                ),
                if (hasImages) ...[
                  CivicFixSpacing.hSpaceMd,
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: CivicFixColors.surfaceMuted,
                      borderRadius: CivicFixRadius.cardRadius,
                      border: Border.all(color: CivicFixColors.border),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: CivicFixColors.secondaryDark,
                          size: 24,
                        ),
                        if (complaint.imageUrls.length > 1)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: CivicFixColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${complaint.imageUrls.length - 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            CivicFixSpacing.vSpaceMd,

            const Divider(height: 1, color: CivicFixColors.border),
            CivicFixSpacing.vSpaceSm,

            // Footer: Last updated time + Hazard pill or upvotes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: CivicFixColors.disabledText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated $updatedTimeText',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                      ),
                    ),
                  ],
                ),
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
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: CivicFixColors.alertDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Safety Hazard',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.alertDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (complaint.upvotes > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 13,
                        color: CivicFixColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${complaint.upvotes} supports',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
