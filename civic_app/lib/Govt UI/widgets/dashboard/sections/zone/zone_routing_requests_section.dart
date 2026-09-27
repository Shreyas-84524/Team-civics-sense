import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_routing_ticket_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Zonal Routing Requests Section for Deputy Municipal Commissioner Command Center.
/// Displays inter-department wrong-department transfers under supervisory zonal review.
class ZoneRoutingRequestsSection extends StatelessWidget {
  final List<ComplaintRoutingTicket> tickets;
  final bool isLoading;
  final VoidCallback? onTicketReviewed;

  const ZoneRoutingRequestsSection({
    super.key,
    required this.tickets,
    this.isLoading = false,
    this.onTicketReviewed,
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
          Row(
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
                    Text(
                      'ZONAL ROUTING & REASSIGNMENT REQUESTS',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Supervisory visibility into inter-departmental transfers awaiting Ward Officer review',
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
                  color: GovtThemeTokens.infoLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.info.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${tickets.length} Pending in Zone',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceMd,

          // Zonal Supervisory Notice
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GovtThemeTokens.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: GovtThemeTokens.textSecondary),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Text(
                    'Administrative Notice: In accordance with the BMC 2-Tier Routing Matrix, Ward Officers hold primary statutory authority to approve/reject wrong-department transfers. Zonal DMC maintains administrative supervisory oversight.',
                    style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (tickets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.done_all_rounded, color: GovtThemeTokens.success, size: 40),
                    CivicFixSpacing.vSpaceMd,
                    Text(
                      'Zero Pending Transfer Requests in Zone',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.success,
                      ),
                    ),
                    Text(
                      'All inter-department routing requests in this zone have been reviewed.',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) => _buildMobileTicketCard(context, tickets[index]),
            )
          else
            _buildDesktopTicketsTable(context),
        ],
      ),
    );
  }

  Widget _buildDesktopTicketsTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GovtThemeTokens.surfaceMuted),
        horizontalMargin: CivicFixSpacing.md,
        columnSpacing: CivicFixSpacing.lg,
        columns: const [
          DataColumn(label: Text('TICKET ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('WARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SOURCE DEPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SUGGESTED DEPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('REASON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('LEAD ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: tickets.map((t) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  t.ticketNumber,
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.primaryDark,
                  ),
                ),
              ),
              DataCell(
                Text(
                  'Ward ${t.wardId}',
                  style: CivicFixTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  t.sourceDepartmentId,
                  style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: GovtThemeTokens.info),
                    CivicFixSpacing.hSpaceXs,
                    Text(
                      t.suggestedDepartmentId,
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.info,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    t.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textPrimary),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.status.name.toUpperCase(),
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  t.sourceLeadId,
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileTicketCard(BuildContext context, ComplaintRoutingTicket t) {
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
                t.ticketNumber,
                style: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.primaryDark,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Text('Ward ${t.wardId}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.warningLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.status.name.toUpperCase(),
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Row(
            children: [
              Expanded(
                child: Text(
                  'From: ${t.sourceDepartmentId}',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: GovtThemeTokens.info),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  'To: ${t.suggestedDepartmentId}',
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.info,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            t.reason,
            style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textPrimary),
          ),
        ],
      ),
    );
  }
}
