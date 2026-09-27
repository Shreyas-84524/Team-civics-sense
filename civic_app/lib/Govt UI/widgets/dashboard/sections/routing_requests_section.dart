import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_routing_ticket_model.dart';
import '../../../../core/services/complaint_routing_service.dart';
import '../../../../core/services/government_authorization_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_confirmation_dialog.dart';
import '../../common/government_data_table.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_empty_state.dart';
import '../../common/govt_jurisdiction_badge.dart';
import '../../common/govt_status_badge.dart';

/// Section providing visibility and executive override for cross-department transfer requests.
class RoutingRequestsSection extends StatefulWidget {
  final List<ComplaintRoutingTicket> tickets;
  final bool isLoading;
  final ComplaintRoutingService? routingService;
  final VoidCallback? onTicketReviewed;

  const RoutingRequestsSection({
    super.key,
    required this.tickets,
    this.isLoading = false,
    this.routingService,
    this.onTicketReviewed,
  });

  @override
  State<RoutingRequestsSection> createState() => _RoutingRequestsSectionState();
}

class _RoutingRequestsSectionState extends State<RoutingRequestsSection> {
  bool _isProcessing = false;

  void _handleReview(ComplaintRoutingTicket ticket, bool approve) {
    final activeUser = AuthServiceLocator.govtAuth.currentUser;
    if (activeUser == null) return;

    final authService = GovernmentAuthorizationService();
    if (!authService.canReviewRoutingTicket(activeUser, ticket)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: You are not authorized to review this routing ticket.'),
          backgroundColor: GovtThemeTokens.error,
        ),
      );
      return;
    }

    final actionLabel = approve ? 'Approve Reassignment' : 'Reject Reassignment';
    final msg = approve
        ? 'Transfer Complaint ${ticket.complaintId} from ${ticket.sourceDepartmentId} to ${ticket.suggestedDepartmentId}?'
        : 'Reject reassignment and retain Complaint in ${ticket.sourceDepartmentId}?';

    GovernmentConfirmationDialog.show(
      context,
      title: actionLabel,
      message: msg,
      confirmLabel: approve ? 'Approve' : 'Reject',
      type: approve ? GovtDialogType.confirmation : GovtDialogType.destructive,
      onConfirm: () async {
        setState(() => _isProcessing = true);
        final messenger = ScaffoldMessenger.of(context);
        try {
          final service = widget.routingService ?? ComplaintRoutingService();
          await service.reviewRoutingTicket(
            ticketId: ticket.id,
            reviewerId: activeUser.employeeId,
            approve: approve,
            reviewNotes: 'Executive Super Admin determination',
          );
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(approve
                    ? 'Ticket ${ticket.id} approved successfully.'
                    : 'Ticket ${ticket.id} rejected.'),
                backgroundColor: approve ? GovtThemeTokens.success : GovtThemeTokens.primaryDark,
              ),
            );
          }
          if (widget.onTicketReviewed != null) {
            widget.onTicketReviewed!();
          }
        } catch (e) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error updating ticket: $e'),
                backgroundColor: GovtThemeTokens.error,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = AuthServiceLocator.govtAuth.currentUser;
    final canOverride = activeUser != null &&
        (activeUser.isSuperAdmin || activeUser.hasPermission('admin_override'));

    if (widget.tickets.isEmpty && !widget.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GovernmentSectionHeader(
            title: 'Pending Routing Requests',
            subtitle: 'Wrong-department reassignments requiring administrative adjudication',
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: GovtEmptyState.noRoutingRequests(
              onAction: widget.onTicketReviewed,
            ),
          ),
        ],
      );
    }

    final columns = [
      const GovtDataColumn(label: 'Ticket ID', width: 130),
      const GovtDataColumn(label: 'Complaint ID', width: 130),
      const GovtDataColumn(label: 'Ward', width: 85),
      const GovtDataColumn(label: 'Current Dept', width: 160),
      const GovtDataColumn(label: 'Requested Dept', width: 160),
      const GovtDataColumn(label: 'Raised By', width: 130),
      const GovtDataColumn(label: 'Reason Summary', width: 200),
      const GovtDataColumn(label: 'Age', width: 100),
      const GovtDataColumn(label: 'Status', width: 130),
      if (canOverride)
        const GovtDataColumn(label: 'Super Admin Override', width: 160, alignment: Alignment.center),
    ];

    final rows = widget.tickets.map((t) {
      final ageStr = DateFormatter.formatRelative(t.createdAt);

      return [
        // Ticket ID
        Text(
          t.id,
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.primary,
            fontFamily: 'monospace',
          ),
        ),
        // Complaint ID
        Text(
          t.ticketNumber.isNotEmpty ? t.ticketNumber : t.complaintId,
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
        // Ward
        GovtJurisdictionBadge.ward(t.wardId, isCompact: true, withBrackets: false),
        // Current Dept
        Text(t.sourceDepartmentId, style: GovtTypography.bodySmall),
        // Requested Dept
        Text(
          t.suggestedDepartmentId,
          style: GovtTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2563EB),
          ),
        ),
        // Raised By
        Text(t.sourceLeadId, style: GovtTypography.caption),
        // Reason Summary
        Text(
          t.reason,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textPrimary),
        ),
        // Age
        Text(ageStr, style: GovtTypography.caption),
        // Status
        GovtStatusBadge.ticket(t.status, isCompact: true),
        // Super Admin Override Actions
        if (canOverride)
          t.isPending
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: GovtThemeTokens.success, size: 20),
                      tooltip: 'Approve Transfer',
                      onPressed: _isProcessing ? null : () => _handleReview(t, true),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    CivicFixSpacing.hSpaceXs,
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: GovtThemeTokens.error, size: 20),
                      tooltip: 'Reject Transfer',
                      onPressed: _isProcessing ? null : () => _handleReview(t, false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                )
              : const Text('Resolved', style: TextStyle(fontSize: 11, color: GovtThemeTokens.textMuted)),
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'Pending Routing Requests',
          subtitle: 'Wrong-department reassignments requiring administrative adjudication',
          count: widget.tickets.length,
        ),
        CivicFixSpacing.vSpaceSm,
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: widget.isLoading,
          title: 'Cross-Department Transfer Queue',
          totalCount: widget.tickets.length,
          pageSize: 10,
          minWidth: 1250,
        ),
      ],
    );
  }
}
