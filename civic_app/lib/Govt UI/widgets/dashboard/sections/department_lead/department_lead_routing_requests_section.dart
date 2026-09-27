import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_routing_ticket_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Routing Requests" Center for Ward Department Lead Operations Center.
/// Displays Wrong-Department reassignment requests raised by this department unit.
/// Explicitly enforces that Department Leads CANNOT self-approve tickets (approval remains with Ward Officer).
class DepartmentLeadRoutingRequestsSection extends StatelessWidget {
  final List<ComplaintRoutingTicket> routingTickets;
  final bool isLoading;
  final VoidCallback? onRaiseNewTicket;
  final ValueChanged<String>? onViewComplaint;

  const DepartmentLeadRoutingRequestsSection({
    super.key,
    required this.routingTickets,
    this.isLoading = false,
    this.onRaiseNewTicket,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFFF97316), size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTING REQUESTS & REASSIGNMENT CENTER',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Inter-department wrong-routing tickets raised for Ward Officer adjudication',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFF97316).withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${routingTickets.length} Unit Tickets',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: const Color(0xFFEA580C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Governance Notice: Ward Officer Sole Approval Authority
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.infoLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GovtThemeTokens.info.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: GovtThemeTokens.info, size: 18),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Text(
                    'Administrative Governance Rule: Department Leads can initiate reassignment requests. Approval authority is strictly reserved for the Assistant Commissioner (Ward Officer).',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          if (routingTickets.isEmpty)
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 36, color: Color(0xFF10B981)),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'No Routing Tickets',
                    style: CivicFixTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                  Text(
                    'No pending or past wrong-department requests for this unit.',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: routingTickets.length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (ctx, i) {
                final t = routingTickets[i];
                return _buildMobileTicketCard(t);
              },
            )
          else
            _buildDesktopTable(context),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final now = DateTime.now();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.6), // Ticket ID
          1: FlexColumnWidth(1.6), // Complaint
          2: FlexColumnWidth(1.6), // Current Dept
          3: FlexColumnWidth(1.6), // Requested Dept
          4: FlexColumnWidth(2.0), // Reason
          5: FlexColumnWidth(1.4), // Created / Age
          6: FlexColumnWidth(1.2), // Status
          7: FlexColumnWidth(1.6), // Reviewed By / Notes
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
            ),
            children: [
              _tableHeader('TICKET ID'),
              _tableHeader('COMPLAINT'),
              _tableHeader('CURRENT DEPT'),
              _tableHeader('REQUESTED DEPT'),
              _tableHeader('REASON'),
              _tableHeader('CREATED / AGE'),
              _tableHeader('STATUS'),
              _tableHeader('REVIEW DETAILS'),
            ],
          ),
          ...routingTickets.map((t) {
            final ageHours = now.difference(t.createdAt).inHours;

            Color statusColor;
            String statusLabel;
            switch (t.status) {
              case RoutingTicketStatus.pending:
                statusColor = const Color(0xFFF59E0B);
                statusLabel = 'Pending Review';
                break;
              case RoutingTicketStatus.approved:
                statusColor = const Color(0xFF10B981);
                statusLabel = 'Approved';
                break;
              case RoutingTicketStatus.rejected:
                statusColor = const Color(0xFFEF4444);
                statusLabel = 'Rejected';
                break;
              case RoutingTicketStatus.cancelled:
                statusColor = const Color(0xFF6B7280);
                statusLabel = 'Cancelled';
                break;
            }

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight),
                ),
              ),
              children: [
                // Ticket ID
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    t.id,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Complaint
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: InkWell(
                    onTap: onViewComplaint != null
                        ? () => onViewComplaint!(t.complaintId)
                        : null,
                    child: Text(
                      t.ticketNumber.isNotEmpty
                          ? t.ticketNumber
                          : t.complaintId,
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                // Current Dept
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    t.sourceDepartmentId.replaceAll('_', ' ').toUpperCase(),
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Requested Dept
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    t.suggestedDepartmentId.replaceAll('_', ' ').toUpperCase(),
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: const Color(0xFFF97316),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Reason
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    t.reason,
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Created At / Age
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${t.createdAt.day}/${t.createdAt.month} (${ageHours}h ago)',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: CivicFixTypography.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // Reviewed By / Remarks
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    t.reviewedBy != null
                        ? 'Reviewed by ${t.reviewedBy}\n${t.reviewNotes ?? ""}'
                        : 'Awaiting Ward Officer',
                    style: CivicFixTypography.caption.copyWith(
                      color: t.reviewedBy != null
                          ? GovtThemeTokens.textPrimary
                          : GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileTicketCard(ComplaintRoutingTicket t) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.id,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                t.status.name.toUpperCase(),
                style: CivicFixTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Transfer to: ${t.suggestedDepartmentId.replaceAll("_", " ").toUpperCase()}',
            style: CivicFixTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF97316),
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Reason: ${t.reason}',
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.sm),
      child: Text(
        text,
        style: CivicFixTypography.captionMedium.copyWith(
          color: GovtThemeTokens.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
