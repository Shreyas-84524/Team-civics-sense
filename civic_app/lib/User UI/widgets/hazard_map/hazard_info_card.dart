import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/hazard_model.dart';
import '../../../core/repositories/complaint_repository.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../../core/widgets/status_badge.dart';

/// Compact floating card displayed when a citizen taps a map hazard marker.
class HazardInfoCard extends StatelessWidget {
  final HazardModel hazard;
  final VoidCallback onClose;
  final ComplaintRepository? complaintRepository;

  const HazardInfoCard({
    super.key,
    required this.hazard,
    required this.onClose,
    this.complaintRepository,
  });

  Future<void> _navigateToComplaintDetails(BuildContext context) async {
    final repo = complaintRepository ?? MockComplaintRepository();
    final complaintId = hazard.complaintId ?? hazard.id;
    final ticketNumber = hazard.ticketNumber;

    // Try finding by internal complaint ID or ticket number
    var complaint = await repo.getComplaintById(complaintId);
    if (complaint == null && ticketNumber != null) {
      complaint = await repo.getComplaintByTicketId(ticketNumber);
    }

    if (context.mounted) {
      if (complaint != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.complaintDetails,
          arguments: complaint,
        );
      } else {
        // Navigate with ID string argument
        Navigator.pushNamed(
          context,
          AppRoutes.complaintDetails,
          arguments: complaintId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Status Badge & Close Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hazard.statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hazard.categoryIcon,
                  color: hazard.statusColor,
                  size: 18,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hazard.category.name,
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CivicFixColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hazard.ticketNumber != null)
                      Text(
                        hazard.ticketNumber!,
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              StatusBadge(status: hazard.status),
              CivicFixSpacing.hSpaceSm,
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: CivicFixColors.secondaryText,
                ),
                tooltip: 'Close hazard details',
                onPressed: onClose,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // Hazard Title
          Text(
            hazard.title,
            style: CivicFixTypography.h3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          CivicFixSpacing.vSpaceSm,

          // Location info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: CivicFixColors.secondaryText,
              ),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  '${hazard.address}${hazard.landmark != null ? " (${hazard.landmark})" : ""}',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,

          // Last Updated Timestamp
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: CivicFixColors.disabledText,
              ),
              CivicFixSpacing.hSpaceXs,
              Text(
                'Updated ${DateFormatter.formatRelativeTime(hazard.updatedAt)}',
                style: CivicFixTypography.caption.copyWith(
                  color: CivicFixColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Primary Action: View Complaint Details
          CivicFixButton(
            text: 'View Complaint',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _navigateToComplaintDetails(context),
          ),
        ],
      ),
    );
  }
}
