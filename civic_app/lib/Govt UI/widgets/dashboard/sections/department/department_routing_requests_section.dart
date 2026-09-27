import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_routing_ticket_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Inter-Departmental Routing & Transfer Requests Section for Central Department HOD command center.
/// Shows requests where this department is either source or destination.
class DepartmentRoutingRequestsSection extends StatelessWidget {
  final List<ComplaintRoutingTicket> routingTickets;
  final String departmentId;
  final bool isLoading;
  final ValueChanged<ComplaintRoutingTicket>? onApproveTicket;
  final ValueChanged<ComplaintRoutingTicket>? onRejectTicket;
  final ValueChanged<ComplaintRoutingTicket>? onViewDetails;

  const DepartmentRoutingRequestsSection({
    super.key,
    required this.routingTickets,
    required this.departmentId,
    this.isLoading = false,
    this.onApproveTicket,
    this.onRejectTicket,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);
    final pendingCount = routingTickets
        .where((t) => t.status == RoutingTicketStatus.pending)
        .length;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz_outlined,
                    color: GovtThemeTokens.info, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INTER-DEPARTMENTAL ROUTING & REASSIGNMENTS',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Grievance jurisdiction transfers, misrouting corrections, and department handoffs',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? GovtThemeTokens.warning.withValues(alpha: 0.1)
                      : GovtThemeTokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: pendingCount > 0
                        ? GovtThemeTokens.warning.withValues(alpha: 0.3)
                        : GovtThemeTokens.border,
                  ),
                ),
                child: Text(
                  '$pendingCount Pending',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: pendingCount > 0
                        ? GovtThemeTokens.warning
                        : GovtThemeTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (routingTickets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.done_all,
                        size: 40, color: GovtThemeTokens.success),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No Active Department Routing Requests',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'All inter-departmental grievance transfers are up to date.',
                      style: CivicFixTypography.captionMedium
                          .copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildTicketsTable(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildTicketsTable(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
        ),
        dataRowMinHeight: 56,
        dataRowMaxHeight: 64,
        horizontalMargin: 16,
        columnSpacing: 20,
        columns: [
          DataColumn(
            label: Text(
              'TICKET / DATE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'FLOW / DIRECTION',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'REASON / NOTE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'STATUS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'ACTIONS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
        ],
        rows: routingTickets.map((t) {
          final isPending = t.status == RoutingTicketStatus.pending;
          final isApproved = t.status == RoutingTicketStatus.approved;
          final isRejected = t.status == RoutingTicketStatus.rejected;

          final isIncoming = t.suggestedDepartmentId.toLowerCase() ==
                  departmentId.toLowerCase() ||
              t.suggestedDepartmentId.toLowerCase().contains(departmentId.toLowerCase());

          return DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.complaintId.length > 8
                          ? t.complaintId.substring(0, 8).toUpperCase()
                          : t.complaintId,
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    Text(
                      'Ticket: ${t.id.substring(0, 6)}',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isIncoming
                            ? GovtThemeTokens.info.withValues(alpha: 0.1)
                            : GovtThemeTokens.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isIncoming ? 'INWARD' : 'OUTWARD',
                        style: CivicFixTypography.caption.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isIncoming
                              ? GovtThemeTokens.info
                              : GovtThemeTokens.warning,
                        ),
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      '${t.sourceDepartmentId}  ➔  ${t.suggestedDepartmentId}',
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    t.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPending
                        ? GovtThemeTokens.warning.withValues(alpha: 0.15)
                        : isApproved
                            ? GovtThemeTokens.success.withValues(alpha: 0.15)
                            : isRejected
                                ? GovtThemeTokens.error.withValues(alpha: 0.15)
                                : GovtThemeTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.status.name.toUpperCase(),
                    style: CivicFixTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isPending
                          ? GovtThemeTokens.warning
                          : isApproved
                              ? GovtThemeTokens.success
                              : isRejected
                                  ? GovtThemeTokens.error
                                  : GovtThemeTokens.textSecondary,
                    ),
                  ),
                ),
              ),
              DataCell(
                isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => onApproveTicket?.call(t),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GovtThemeTokens.success,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              textStyle: CivicFixTypography.caption
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Approve'),
                          ),
                          CivicFixSpacing.hSpaceXs,
                          OutlinedButton(
                            onPressed: () => onRejectTicket?.call(t),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GovtThemeTokens.error,
                              side:
                                  const BorderSide(color: GovtThemeTokens.error),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              textStyle: CivicFixTypography.caption
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      )
                    : Text(
                        'Resolved',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
