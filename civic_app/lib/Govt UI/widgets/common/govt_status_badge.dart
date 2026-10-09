import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/mappers/canonical_display_mappers.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/models/complaint_routing_ticket_model.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Comprehensive Status Badge for Government operations.
///
/// Supports:
/// 1. Complaint Status (`submitted`, `verified`, `assigned`, `in_progress`, `awaiting_verification`, `resolved`, `rejected`)
/// 2. Routing Status (`assigned`, `reassignment_requested`, `unassigned`, `transferred`)
/// 3. Routing Ticket Status (`pending`, `approved`, `rejected`, `cancelled`)
class GovtStatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool isCompact;
  final String? tooltip;
  final ComplaintStatus? complaintStatus;
  final ComplaintRoutingStatus? routingStatus;

  const GovtStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.isCompact = false,
    this.tooltip,
    this.complaintStatus,
    this.routingStatus,
  });

  /// Factory constructor for [ComplaintStatus].
  factory GovtStatusBadge.complaint(ComplaintStatus status, {bool isCompact = false}) {
    switch (status) {
      case ComplaintStatus.underVerification:
        return GovtStatusBadge(
          label: 'Under Verification',
          icon: Icons.search_rounded,
          color: const Color(0xFF7C3AED),
          backgroundColor: const Color(0xFFF3E8FF),
          isCompact: isCompact,
          tooltip: 'Two-stage AI verification in progress',
          complaintStatus: status,
        );
      case ComplaintStatus.reported:
        return GovtStatusBadge(
          label: 'Reported',
          icon: Icons.assignment_outlined,
          color: GovtThemeTokens.primary,
          backgroundColor: const Color(0xFFE8F2F8),
          isCompact: isCompact,
          tooltip: 'Initial complaint submitted by citizen',
          complaintStatus: status,
        );
      case ComplaintStatus.verified:
        return GovtStatusBadge(
          label: 'Verified',
          icon: Icons.verified_outlined,
          color: GovtThemeTokens.secondary,
          backgroundColor: const Color(0xFFE8F8F0),
          isCompact: isCompact,
          tooltip: 'Complaint verified by municipal reviewer or AI',
          complaintStatus: status,
        );
      case ComplaintStatus.assigned:
        return GovtStatusBadge(
          label: 'Assigned',
          icon: Icons.person_pin_circle_outlined,
          color: GovtThemeTokens.info,
          backgroundColor: const Color(0xFFE8F2F8),
          isCompact: isCompact,
          tooltip: 'Assigned to ward department crew',
          complaintStatus: status,
        );
      case ComplaintStatus.inProgress:
        return GovtStatusBadge(
          label: 'In Progress',
          icon: Icons.engineering_rounded,
          color: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFEF8EC),
          isCompact: isCompact,
          tooltip: 'Field work currently underway',
          complaintStatus: status,
        );
      case ComplaintStatus.resolved:
        return GovtStatusBadge(
          label: 'Resolved',
          icon: Icons.check_circle_rounded,
          color: GovtThemeTokens.success,
          backgroundColor: const Color(0xFFE8F8F0),
          isCompact: isCompact,
          tooltip: 'Remediation completed and verified',
          complaintStatus: status,
        );
      case ComplaintStatus.closed:
        return GovtStatusBadge(
          label: 'Closed',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF059669),
          backgroundColor: const Color(0xFFECFDF5),
          isCompact: isCompact,
          tooltip: 'Complaint resolution closed and finalized',
          complaintStatus: status,
        );
      case ComplaintStatus.rejected:
        return GovtStatusBadge(
          label: 'Rejected',
          icon: Icons.cancel_rounded,
          color: GovtThemeTokens.error,
          backgroundColor: const Color(0xFFFDE8E8),
          isCompact: isCompact,
          tooltip: 'Complaint rejected or deemed invalid',
          complaintStatus: status,
        );
    }
  }

  /// Factory constructor from raw string complaint status (including awaiting_verification).
  factory GovtStatusBadge.fromComplaintStatusString(String? status, {bool isCompact = false}) {
    final normalized = (status ?? '').toLowerCase().trim();
    if (normalized == 'under_verification' || normalized == 'underverification') {
      return GovtStatusBadge.complaint(ComplaintStatus.underVerification, isCompact: isCompact);
    }
    if (normalized == 'awaiting_verification' || normalized == 'awaitingverification') {
      return GovtStatusBadge(
        label: 'Awaiting Verification',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFFF3E8FF),
        isCompact: isCompact,
        tooltip: 'Work completed by crew; awaiting supervisor verification',
      );
    }
    if (normalized == 'submitted' || normalized == 'reported') {
      return GovtStatusBadge.complaint(ComplaintStatus.reported, isCompact: isCompact);
    }
    if (normalized == 'verified' || normalized == 'under_review') {
      return GovtStatusBadge.complaint(ComplaintStatus.verified, isCompact: isCompact);
    }
    if (normalized == 'assigned') {
      return GovtStatusBadge.complaint(ComplaintStatus.assigned, isCompact: isCompact);
    }
    if (normalized == 'in_progress' || normalized == 'inprogress') {
      return GovtStatusBadge.complaint(ComplaintStatus.inProgress, isCompact: isCompact);
    }
    if (normalized == 'resolved') {
      return GovtStatusBadge.complaint(ComplaintStatus.resolved, isCompact: isCompact);
    }
    if (normalized == 'closed') {
      return GovtStatusBadge.complaint(ComplaintStatus.closed, isCompact: isCompact);
    }
    if (normalized == 'rejected') {
      return GovtStatusBadge.complaint(ComplaintStatus.rejected, isCompact: isCompact);
    }
    return GovtStatusBadge.complaint(ComplaintStatus.reported, isCompact: isCompact);
  }

  /// Factory constructor for [ComplaintRoutingStatus].
  factory GovtStatusBadge.routing(ComplaintRoutingStatus status, {bool isCompact = false}) {
    switch (status) {
      case ComplaintRoutingStatus.assigned:
        return GovtStatusBadge(
          label: 'Assigned',
          icon: Icons.check_circle_outline_rounded,
          color: GovtThemeTokens.info,
          backgroundColor: const Color(0xFFE8F2F8),
          isCompact: isCompact,
          routingStatus: status,
        );
      case ComplaintRoutingStatus.reassignmentRequested:
        return GovtStatusBadge(
          label: 'Reassignment Requested',
          icon: Icons.swap_horiz_rounded,
          color: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFEF8EC),
          isCompact: isCompact,
          tooltip: 'Ward department requested transfer to another department',
          routingStatus: status,
        );
      case ComplaintRoutingStatus.unassigned:
        return GovtStatusBadge(
          label: 'Unassigned',
          icon: Icons.help_outline_rounded,
          color: GovtThemeTokens.textSecondary,
          backgroundColor: const Color(0xFFEFF3F0),
          isCompact: isCompact,
          routingStatus: status,
        );
      case ComplaintRoutingStatus.transferred:
        return GovtStatusBadge(
          label: 'Transferred',
          icon: Icons.move_up_rounded,
          color: const Color(0xFF4F46E5),
          backgroundColor: const Color(0xFFEEF2FF),
          isCompact: isCompact,
          routingStatus: status,
        );
      case ComplaintRoutingStatus.inProgress:
        return GovtStatusBadge(
          label: 'In Progress',
          icon: Icons.engineering_rounded,
          color: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFEF8EC),
          isCompact: isCompact,
          routingStatus: status,
        );
      case ComplaintRoutingStatus.resolved:
        return GovtStatusBadge(
          label: 'Resolved',
          icon: Icons.check_circle_rounded,
          color: GovtThemeTokens.success,
          backgroundColor: const Color(0xFFE8F8F0),
          isCompact: isCompact,
          routingStatus: status,
        );
    }
  }

  /// Factory constructor for [RoutingTicketStatus].
  factory GovtStatusBadge.ticket(RoutingTicketStatus status, {bool isCompact = false}) {
    switch (status) {
      case RoutingTicketStatus.pending:
        return GovtStatusBadge(
          label: 'Pending Review',
          icon: Icons.pending_outlined,
          color: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFEF8EC),
          isCompact: isCompact,
          tooltip: 'Awaiting Ward Officer adjudication',
        );
      case RoutingTicketStatus.approved:
        return GovtStatusBadge(
          label: 'Approved',
          icon: Icons.check_circle_rounded,
          color: GovtThemeTokens.success,
          backgroundColor: const Color(0xFFE8F8F0),
          isCompact: isCompact,
          tooltip: 'Cross-department reassignment approved',
        );
      case RoutingTicketStatus.rejected:
        return GovtStatusBadge(
          label: 'Rejected',
          icon: Icons.cancel_rounded,
          color: GovtThemeTokens.error,
          backgroundColor: const Color(0xFFFDE8E8),
          isCompact: isCompact,
          tooltip: 'Reassignment declined; remains with originating department',
        );
      case RoutingTicketStatus.cancelled:
        return GovtStatusBadge(
          label: 'Cancelled',
          icon: Icons.block_rounded,
          color: GovtThemeTokens.textSecondary,
          backgroundColor: const Color(0xFFEFF3F0),
          isCompact: isCompact,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayLabel = label;
    if (complaintStatus != null) {
      displayLabel = localizedComplaintStatus(complaintStatus!, context: context);
    } else if (routingStatus != null) {
      displayLabel = localizedRoutingStatus(routingStatus!, context: context);
    }

    final badgeWidget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? CivicFixSpacing.sm : CivicFixSpacing.md,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: GovtThemeTokens.elevatedSurface,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GovtTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11 : 12,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        child: badgeWidget,
      );
    }

    return badgeWidget;
  }
}
