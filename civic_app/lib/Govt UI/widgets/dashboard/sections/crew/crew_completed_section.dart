import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_crew_work_service.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';

/// Section displaying completed and verified jobs assigned to current crew member.
class CrewCompletedSection extends StatefulWidget {
  final List<CrewJobItem> completedJobs;
  final void Function(CrewJobItem job) onViewDetails;

  const CrewCompletedSection({
    super.key,
    required this.completedJobs,
    required this.onViewDetails,
  });

  @override
  State<CrewCompletedSection> createState() => _CrewCompletedSectionState();
}

class _CrewCompletedSectionState extends State<CrewCompletedSection> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.completedJobs.where((job) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return job.ticketNumber.toLowerCase().contains(q) ||
          job.title.toLowerCase().contains(q) ||
          job.address.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMPLETED FIELD WORK',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Certified and resolved field operations assigned to you (${widget.completedJobs.length})',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceMd,

        // Search box
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search completed work...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: GovtThemeTokens.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: GovtThemeTokens.surface,
          ),
        ),
        CivicFixSpacing.vSpaceLg,

        if (filtered.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xxl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 48,
                  color: GovtThemeTokens.textMuted,
                ),
                CivicFixSpacing.vSpaceMd,
                Text(
                  'No completed jobs found',
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  'Completed field jobs certified by your Department Lead will be archived here.',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final job = filtered[index];
              final c = job.complaint;
              final resDate = c.resolvedAt ?? c.updatedAt;

              return Container(
                margin: const EdgeInsets.only(bottom: CivicFixSpacing.md),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: GovtThemeTokens.cardRadius,
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                  boxShadow: GovtThemeTokens.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 12, color: Color(0xFF10B981)),
                                CivicFixSpacing.hSpaceXs,
                                Text(
                                  'CERTIFIED RESOLVED',
                                  style: CivicFixTypography.caption.copyWith(
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GovtPriorityBadge.fromPriority(c.priority,
                              isCompact: true),
                        ],
                      ),
                      CivicFixSpacing.vSpaceSm,
                      Text(
                        'TICKET #${job.ticketNumber} · ${job.title}',
                        style: CivicFixTypography.h3.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Resolved: ${resDate.day}/${resDate.month}/${resDate.year} ${resDate.hour}:${resDate.minute.toString().padLeft(2, '0')} · ${job.address}',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                      CivicFixSpacing.vSpaceMd,
                      const Divider(color: GovtThemeTokens.divider, height: 1),
                      CivicFixSpacing.vSpaceSm,
                      Row(
                        children: [
                          Text(
                            'SLA Result: Compliant',
                            style: CivicFixTypography.caption.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GovtThemeTokens.surfaceMuted,
                              foregroundColor: GovtThemeTokens.textPrimary,
                              elevation: 0,
                              side: const BorderSide(
                                  color: GovtThemeTokens.border),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => widget.onViewDetails(job),
                            child: const Text('View Record'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
