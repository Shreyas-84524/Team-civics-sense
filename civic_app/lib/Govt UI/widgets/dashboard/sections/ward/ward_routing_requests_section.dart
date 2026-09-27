import 'package:flutter/material.dart';
import '../../../../../core/auth/auth_service_locator.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/civic_department_model.dart';
import '../../../../../core/models/complaint_routing_ticket_model.dart';
import '../../../../../core/services/complaint_routing_service.dart';
import '../../../../../core/services/government_authorization_service.dart';
import '../../../../models/govt_user_model.dart';
import '../../../../services/government_jurisdiction_resolver.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Phase 6 — Routing Request Center.
///
/// Handles the critical municipal workflow where Ward Department Leads flag misrouted
/// complaints and the Ward Officer reviews, approves, or rejects the inter-department transfer.
class WardRoutingRequestsSection extends StatefulWidget {
  final List<ComplaintRoutingTicket> routingTickets;
  final String wardId;
  final bool isLoading;
  final ComplaintRoutingService routingService;
  final GovernmentAuthorizationService? authService;
  final List<CivicDepartment> allDepartments;
  final VoidCallback onRefreshNeeded;
  final ValueChanged<String>? onViewComplaint;

  const WardRoutingRequestsSection({
    super.key,
    required this.routingTickets,
    required this.wardId,
    this.isLoading = false,
    required this.routingService,
    this.authService,
    this.allDepartments = const [],
    required this.onRefreshNeeded,
    this.onViewComplaint,
  });

  @override
  State<WardRoutingRequestsSection> createState() => _WardRoutingRequestsSectionState();
}

class _WardRoutingRequestsSectionState extends State<WardRoutingRequestsSection> {
  late final GovernmentAuthorizationService _authService;
  String _filterStatus = 'all'; // 'all', 'pending', 'resolved'

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? GovernmentAuthorizationService();
  }

  List<ComplaintRoutingTicket> _getFilteredTickets() {
    return widget.routingTickets.where((t) {
      if (_filterStatus == 'pending') {
        return t.isPending;
      }
      if (_filterStatus == 'resolved') {
        return !t.isPending;
      }
      return true;
    }).toList();
  }

  void _showApproveDialog(ComplaintRoutingTicket ticket) {
    final activeUser = AuthServiceLocator.govtAuth.currentUser;
    String selectedDeptId = ticket.suggestedDepartmentId;
    final notesController = TextEditingController(text: 'Reassignment approved to $selectedDeptId.');
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogStateCtx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: GovtThemeTokens.success, size: 20),
                ),
                CivicFixSpacing.hSpaceSm,
                const Text('Approve Reassignment'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authorize transfer of complaint to the designated municipal department in Ward ${widget.wardId}.',
                    style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                  ),
                  CivicFixSpacing.vSpaceMd,
                  Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.md),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GovtThemeTokens.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dialogRow('Ticket ID', ticket.id),
                        _dialogRow('Complaint', ticket.ticketNumber.isNotEmpty ? ticket.ticketNumber : ticket.complaintId),
                        _dialogRow('Current Dept', ticket.sourceDepartmentId),
                        _dialogRow('Raised By Lead', ticket.sourceLeadId),
                        _dialogRow('Lead Reason', ticket.reason),
                      ],
                    ),
                  ),
                  CivicFixSpacing.vSpaceMd,

                  // Destination Department Selector
                  Text('Target Department', style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w700)),
                  CivicFixSpacing.vSpaceXs,
                  DropdownButtonFormField<String>(
                    initialValue: selectedDeptId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                    ),
                    items: widget.allDepartments.isNotEmpty
                        ? widget.allDepartments.map((d) {
                            return DropdownMenuItem(
                              value: d.departmentId,
                              child: Text(d.displayName, style: CivicFixTypography.bodySmall),
                            );
                          }).toList()
                        : [
                            DropdownMenuItem(
                              value: ticket.suggestedDepartmentId,
                              child: Text(ticket.suggestedDepartmentId, style: CivicFixTypography.bodySmall),
                            ),
                          ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedDeptId = val;
                          notesController.text = 'Reassignment approved to $val.';
                        });
                      }
                    },
                  ),
                  CivicFixSpacing.vSpaceMd,

                  // Review Notes
                  Text('Approval Remarks', style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w700)),
                  CivicFixSpacing.vSpaceXs,
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter administrative approval remarks...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    style: CivicFixTypography.bodySmall,
                  ),
                  CivicFixSpacing.vSpaceSm,
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.infoLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: GovtThemeTokens.info),
                        CivicFixSpacing.hSpaceSm,
                        Expanded(
                          child: Text(
                            'Original SLA clock and complaint creation timestamp are strictly preserved.',
                            style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.info, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() => isProcessing = true);
                        try {
                          final reviewerId = activeUser?.employeeId ?? activeUser?.id ?? 'GOV-WO-${widget.wardId}';
                          await widget.routingService.reviewRoutingTicket(
                            ticketId: ticket.id,
                            reviewerId: reviewerId,
                            approve: true,
                            reviewNotes: notesController.text.trim(),
                          );

                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Routing request approved: Transferred to $selectedDeptId.'),
                                backgroundColor: GovtThemeTokens.success,
                              ),
                            );
                            widget.onRefreshNeeded();
                          }
                        } catch (e) {
                          setDialogState(() => isProcessing = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to approve ticket: $e'),
                                backgroundColor: GovtThemeTokens.error,
                              ),
                            );
                          }
                        }
                      },
                icon: isProcessing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 16),
                label: Text(isProcessing ? 'Approving...' : 'Confirm Approval'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRejectDialog(ComplaintRoutingTicket ticket) {
    final activeUser = AuthServiceLocator.govtAuth.currentUser;
    final notesController = TextEditingController(text: 'Reassignment request rejected by Ward Officer. Belongs in current department.');
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogStateCtx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.cancel_outlined, color: GovtThemeTokens.error, size: 20),
                ),
                CivicFixSpacing.hSpaceSm,
                const Text('Reject Reassignment Request'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complaint will remain assigned to the source department (${ticket.sourceDepartmentId}).',
                    style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                  ),
                  CivicFixSpacing.vSpaceMd,
                  Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.md),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GovtThemeTokens.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dialogRow('Ticket ID', ticket.id),
                        _dialogRow('Complaint', ticket.ticketNumber.isNotEmpty ? ticket.ticketNumber : ticket.complaintId),
                        _dialogRow('Source Dept', ticket.sourceDepartmentId),
                        _dialogRow('Raised Reason', ticket.reason),
                      ],
                    ),
                  ),
                  CivicFixSpacing.vSpaceMd,
                  Text('Rejection Remarks (Required)', style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w700)),
                  CivicFixSpacing.vSpaceXs,
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Provide reason for rejecting transfer request...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    style: CivicFixTypography.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (notesController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter rejection remarks.')),
                          );
                          return;
                        }
                        setDialogState(() => isProcessing = true);
                        try {
                          final reviewerId = activeUser?.employeeId ?? activeUser?.id ?? 'GOV-WO-${widget.wardId}';
                          await widget.routingService.reviewRoutingTicket(
                            ticketId: ticket.id,
                            reviewerId: reviewerId,
                            approve: false,
                            reviewNotes: notesController.text.trim(),
                          );

                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Routing request rejected. Complaint remains with current department.'),
                                backgroundColor: GovtThemeTokens.warning,
                              ),
                            );
                            widget.onRefreshNeeded();
                          }
                        } catch (e) {
                          setDialogState(() => isProcessing = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to reject ticket: $e'),
                                backgroundColor: GovtThemeTokens.error,
                              ),
                            );
                          }
                        }
                      },
                icon: isProcessing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.close_rounded, size: 16),
                label: Text(isProcessing ? 'Rejecting...' : 'Confirm Rejection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovtThemeTokens.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dialogRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted)),
          ),
          Expanded(
            child: Text(val, style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _getFilteredTickets();
    final pendingCount = widget.routingTickets.where((t) => t.isPending).length;
    final activeUser = AuthServiceLocator.govtAuth.currentUser;
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.alt_route_rounded, color: GovtThemeTokens.info, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'ROUTING REQUEST CENTER',
                                style: CivicFixTypography.h3.copyWith(
                                  color: GovtThemeTokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (pendingCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: GovtThemeTokens.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pendingCount PENDING',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'Wrong-department reassignment requests raised by Ward Department Leads',
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Segment
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'pending', label: Text('Pending Review')),
                  ButtonSegment(value: 'resolved', label: Text('History')),
                ],
                selected: {_filterStatus},
                onSelectionChanged: (val) {
                  setState(() => _filterStatus = val.first);
                },
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (tickets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: GovtThemeTokens.success, size: 36),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      _filterStatus == 'pending'
                          ? 'Zero pending routing requests in Ward ${widget.wardId}. All complaints correctly routed.'
                          : 'No routing tickets recorded.',
                      style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: tickets.map((t) => _buildTicketCard(t, activeUser, isMobile)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(ComplaintRoutingTicket ticket, GovtUserModel? activeUser, bool isMobile) {
    final canReview = activeUser != null && _authService.canReviewRoutingTicket(activeUser, ticket);
    final ageHours = DateTime.now().difference(ticket.createdAt).inHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: ticket.isPending ? GovtThemeTokens.surface : GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ticket.isPending ? GovtThemeTokens.info.withValues(alpha: 0.4) : GovtThemeTokens.border,
          width: ticket.isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Ticket ID, Status Badge, Age
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    ticket.id,
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.primary,
                    ),
                  ),
                  CivicFixSpacing.hSpaceSm,
                  InkWell(
                    onTap: widget.onViewComplaint != null ? () => widget.onViewComplaint!(ticket.complaintId) : null,
                    child: Text(
                      'Complaint: ${ticket.ticketNumber.isNotEmpty ? ticket.ticketNumber : ticket.complaintId}',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.primaryDark,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _statusBadge(ticket.status),
                  CivicFixSpacing.hSpaceSm,
                  Text(
                    '${ageHours}h ago',
                    style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceSm,

          // Transfer Route Visualization
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT DEPARTMENT', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10)),
                      Text(
                        GovernmentJurisdictionResolver.resolveDepartment(ticket.sourceDepartmentId),
                        style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Lead: ${ticket.sourceLeadId}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, color: GovtThemeTokens.primary, size: 20),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GovtThemeTokens.info.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REQUESTED TARGET', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.info, fontSize: 10, fontWeight: FontWeight.w700)),
                      Text(
                        GovernmentJurisdictionResolver.resolveDepartment(ticket.suggestedDepartmentId),
                        style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700, color: GovtThemeTokens.info),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Designated Unit', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceSm,

          // Reason
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.comment_outlined, size: 14, color: GovtThemeTokens.textMuted),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Text(
                    'Reason: ${ticket.reason}',
                    style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          // If resolved, show review remarks
          if (!ticket.isPending && ticket.reviewNotes != null) ...[
            CivicFixSpacing.vSpaceXs,
            Text(
              'Resolution Note by ${ticket.reviewedBy ?? "Ward Officer"}: ${ticket.reviewNotes}',
              style: CivicFixTypography.caption.copyWith(
                color: ticket.isApproved ? GovtThemeTokens.success : GovtThemeTokens.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Action Buttons for Pending Tickets (Approve / Reject)
          if (ticket.isPending && canReview) ...[
            CivicFixSpacing.vSpaceMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(ticket),
                  icon: const Icon(Icons.cancel_outlined, size: 14, color: GovtThemeTokens.error),
                  label: const Text('REJECT', style: TextStyle(color: GovtThemeTokens.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: GovtThemeTokens.error),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                ElevatedButton.icon(
                  onPressed: () => _showApproveDialog(ticket),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text('APPROVE TRANSFER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.success,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(RoutingTicketStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case RoutingTicketStatus.pending:
        bg = GovtThemeTokens.warningLight;
        fg = GovtThemeTokens.warning;
        label = 'Pending Review';
        break;
      case RoutingTicketStatus.approved:
        bg = GovtThemeTokens.successLight;
        fg = GovtThemeTokens.success;
        label = 'Approved';
        break;
      case RoutingTicketStatus.rejected:
        bg = GovtThemeTokens.errorLight;
        fg = GovtThemeTokens.error;
        label = 'Rejected';
        break;
      case RoutingTicketStatus.cancelled:
        bg = GovtThemeTokens.surfaceMuted;
        fg = GovtThemeTokens.textMuted;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: CivicFixTypography.caption.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}
