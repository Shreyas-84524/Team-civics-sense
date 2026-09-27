import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Completed Work" Section for Ward Department Lead Operations Center.
/// Displays resolved grievances for this unit with resolution durations,
/// SLA metrics, and verification certification status.
class DepartmentLeadCompletedWorkSection extends StatefulWidget {
  final List<ComplaintModel> completedComplaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel>? onViewDetails;

  const DepartmentLeadCompletedWorkSection({
    super.key,
    required this.completedComplaints,
    this.isLoading = false,
    this.onViewDetails,
  });

  @override
  State<DepartmentLeadCompletedWorkSection> createState() =>
      _DepartmentLeadCompletedWorkSectionState();
}

class _DepartmentLeadCompletedWorkSectionState
    extends State<DepartmentLeadCompletedWorkSection> {
  String _searchQuery = '';
  String? _crewFilter;

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    final filtered = widget.completedComplaints.where((c) {
      if (_crewFilter != null && _crewFilter!.isNotEmpty && _crewFilter != 'all') {
        final matchCrew = c.assignedCrewMemberId == _crewFilter ||
            (c.assignedTo != null &&
                c.assignedTo!.toLowerCase().contains(_crewFilter!.toLowerCase()));
        if (!matchCrew) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesTicket = c.ticketNumber.toLowerCase().contains(q);
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesCrew =
            c.assignedTo != null && c.assignedTo!.toLowerCase().contains(q);
        if (!matchesTicket && !matchesTitle && !matchesCrew) return false;
      }

      return true;
    }).toList();

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
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.verified_outlined,
                    color: Color(0xFF10B981), size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPLETED WORK & RESOLUTION REPOSITORY',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Certified closed grievances with resolution turnaround metrics',
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${widget.completedComplaints.length} Resolved Total',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Quick Filter Toolbar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search completed complaints...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Text(
                'No completed complaints found matching current filters.',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.textMuted,
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (ctx, i) {
                final c = filtered[i];
                return _buildMobileCard(c);
              },
            )
          else
            _buildDesktopTable(filtered),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<ComplaintModel> list) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.5), // Complaint
          1: FlexColumnWidth(1.6), // Crew Member
          2: FlexColumnWidth(1.4), // Resolved At
          3: FlexColumnWidth(1.4), // Resolution Time
          4: FlexColumnWidth(1.4), // SLA Result
          5: FlexColumnWidth(1.6), // Verification Status
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
            ),
            children: [
              _tableHeader('COMPLAINT'),
              _tableHeader('CREW MEMBER'),
              _tableHeader('RESOLVED AT'),
              _tableHeader('RESOLUTION TIME'),
              _tableHeader('SLA RESULT'),
              _tableHeader('VERIFICATION STATUS'),
            ],
          ),
          ...list.map((c) {
            final resTime = c.resolvedAt ?? c.updatedAt;
            final durationHours =
                resTime.difference(c.slaStartedAt).inHours.toDouble();
            final metSla = durationHours <= 48;

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight),
                ),
              ),
              children: [
                // Complaint
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: InkWell(
                    onTap: widget.onViewDetails != null
                        ? () => widget.onViewDetails!(c)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          c.title,
                          style: CivicFixTypography.bodySmall.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Crew Member
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    c.assignedTo ?? c.assignedCrewMemberId ?? 'Field Crew',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ),

                // Resolved At
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${resTime.day}/${resTime.month}/${resTime.year}\n${resTime.hour}:${resTime.minute.toString().padLeft(2, '0')}',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Resolution Time
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${durationHours.toStringAsFixed(1)} hours',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // SLA Result
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: metSla
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      metSla ? 'Met Charter SLA' : 'SLA Breached',
                      style: CivicFixTypography.caption.copyWith(
                        color: metSla
                            ? const Color(0xFF10B981)
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

                // Verification Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 14, color: Color(0xFF10B981)),
                      CivicFixSpacing.hSpaceXs,
                      Text(
                        'Certified Closed',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCard(ComplaintModel c) {
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
                c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified_rounded,
                  size: 16, color: Color(0xFF10B981)),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            c.title,
            style: CivicFixTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Crew: ${c.assignedTo ?? c.assignedCrewMemberId ?? "Squad"} · Resolved: ${c.updatedAt.day}/${c.updatedAt.month}',
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
