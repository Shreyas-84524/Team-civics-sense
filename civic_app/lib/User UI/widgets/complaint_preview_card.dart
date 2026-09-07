import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/routing/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/status_badge.dart';

/// Compact complaint preview card designed for the Citizen Home Dashboard.
class ComplaintPreviewCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onTap;

  const ComplaintPreviewCard({
    super.key,
    required this.complaint,
    this.onTap,
  });

  String _formatUpdatedTime(DateTime updatedAt) {
    final relative = DateFormatter.formatRelativeTime(updatedAt);
    if (relative.toLowerCase().contains('ago') || relative.toLowerCase().contains('now')) {
      return 'Updated $relative';
    }
    return 'Updated on $relative';
  }

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      onTap: onTap ??
          () {
            Navigator.pushNamed(
              context,
              AppRoutes.complaintDetails,
              arguments: complaint,
            );
          },
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Ticket ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                complaint.ticketNumber,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: CivicFixColors.secondaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              StatusBadge(
                status: complaint.status,
                isCompact: true,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          // Title
          Text(
            complaint.title,
            style: CivicFixTypography.bodyLargeMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: CivicFixColors.primaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          CivicFixSpacing.vSpaceMd,

          // Bottom Row: Category & Relative Updated Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category tag
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    complaint.category.icon,
                    size: 14,
                    color: CivicFixColors.secondaryText,
                  ),
                  CivicFixSpacing.hSpaceXs,
                  Text(
                    complaint.category.name,
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Relative updated time
              Text(
                _formatUpdatedTime(complaint.updatedAt),
                style: CivicFixTypography.caption.copyWith(
                  color: CivicFixColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
