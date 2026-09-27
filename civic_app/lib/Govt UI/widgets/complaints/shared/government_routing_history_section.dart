import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_routing_ticket_model.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../common/govt_status_badge.dart';

/// Reusable Routing & Reassignment History component across all government roles.
class GovernmentRoutingHistorySection extends StatelessWidget {
  final List<ComplaintRoutingTicket> routingTickets;
  final bool isCompact;

  const GovernmentRoutingHistorySection({
    super.key,
    required this.routingTickets,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (routingTickets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GovtThemeTokens.borderLight),
        ),
        alignment: Alignment.center,
        child: Text(
          'No department reassignment tickets have been raised for this grievance.',
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routingTickets.length,
      separatorBuilder: (context, index) => CivicFixSpacing.vSpaceSm,
      itemBuilder: (context, index) {
        final ticket = routingTickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(ComplaintRoutingTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ticket.isPending
              ? const Color(0xFFF97316).withValues(alpha: 0.4)
              : GovtThemeTokens.border,
        ),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Transfer Flow & Decision Badge
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      ticket.sourceDepartmentId,
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: GovtThemeTokens.textMuted),
                    ),
                    Text(
                      ticket.suggestedDepartmentId,
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              GovtStatusBadge.ticket(ticket.status, isCompact: true),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          // Requester & Reason
          Text(
            'Reason for Transfer:',
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            ticket.reason,
            style: CivicFixTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textSecondary,
              height: 1.3,
            ),
          ),
          CivicFixSpacing.vSpaceSm,

          // Meta footer: Request timestamp & actor
          Row(
            children: [
              Text(
                'Raised by: Lead (${ticket.sourceLeadId})',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.textMuted,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                '${ticket.createdAt.day}/${ticket.createdAt.month} ${ticket.createdAt.hour}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          // Adjudication notes if completed
          if (ticket.reviewedBy != null && ticket.reviewedBy!.isNotEmpty) ...[
            CivicFixSpacing.vSpaceSm,
            const Divider(color: GovtThemeTokens.divider, height: 1),
            CivicFixSpacing.vSpaceSm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ticket.isApproved
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 14,
                  color: ticket.isApproved
                      ? GovtThemeTokens.success
                      : GovtThemeTokens.error,
                ),
                CivicFixSpacing.hSpaceXs,
                Expanded(
                  child: Text(
                    'Adjudication: ${ticket.reviewNotes ?? (ticket.isApproved ? "Approved by Ward Officer" : "Rejected by Ward Officer")} (${ticket.reviewedBy})',
                    style: CivicFixTypography.caption.copyWith(
                      color: ticket.isApproved
                          ? GovtThemeTokens.success
                          : GovtThemeTokens.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
