import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_crew_work_service.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_sla_badge.dart';

/// Section showing complaints submitted by crew currently awaiting Lead verification.
class CrewAwaitingReviewSection extends StatelessWidget {
  final List<CrewJobItem> awaitingJobs;
  final void Function(CrewJobItem job) onViewDetails;

  const CrewAwaitingReviewSection({
    super.key,
    required this.awaitingJobs,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORK AWAITING REVIEW',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Completed field jobs submitted to Ward Department Lead for final certification (${awaitingJobs.length})',
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

        if (awaitingJobs.isEmpty) ...[
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
                  Icons.verified_outlined,
                  size: 48,
                  color: Color(0xFF8B5CF6),
                ),
                CivicFixSpacing.vSpaceMd,
                Text(
                  'No work pending review',
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  'Jobs you submit with completion evidence will appear here until certified by your Department Lead.',
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
            itemCount: awaitingJobs.length,
            itemBuilder: (context, index) {
              final job = awaitingJobs[index];
              final c = job.complaint;

              return Container(
                margin: const EdgeInsets.only(bottom: CivicFixSpacing.md),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: GovtThemeTokens.cardRadius,
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  ),
                  boxShadow: GovtThemeTokens.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pending_actions_rounded,
                                    size: 12, color: Color(0xFF8B5CF6)),
                                CivicFixSpacing.hSpaceXs,
                                Text(
                                  'AWAITING LEAD VERIFICATION',
                                  style: CivicFixTypography.caption.copyWith(
                                    color: const Color(0xFF8B5CF6),
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
                        job.address,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                      CivicFixSpacing.vSpaceMd,

                      // Evidence Thumbnails
                      if (c.imageUrls.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'Submitted Evidence:',
                              style: CivicFixTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: GovtThemeTokens.textMuted,
                              ),
                            ),
                            CivicFixSpacing.hSpaceSm,
                            ...c.imageUrls.take(3).map((url) {
                              return Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: GovtThemeTokens.borderLight),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                      Icons.image_outlined,
                                      size: 16,
                                      color: GovtThemeTokens.textMuted,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        CivicFixSpacing.vSpaceMd,
                      ],

                      // Remarks preview
                      if (c.officerNotes != null &&
                          c.officerNotes!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(CivicFixSpacing.sm),
                          decoration: BoxDecoration(
                            color: GovtThemeTokens.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Remarks: ${c.officerNotes}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CivicFixTypography.caption.copyWith(
                              color: GovtThemeTokens.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        CivicFixSpacing.vSpaceMd,
                      ],

                      const Divider(color: GovtThemeTokens.divider, height: 1),
                      CivicFixSpacing.vSpaceSm,

                      Row(
                        children: [
                          GovtSlaBadge.fromDuration(
                            createdAt: c.slaStartedAt,
                            resolvedAt: c.resolvedAt,
                            isCompact: true,
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
                            onPressed: () => onViewDetails(job),
                            child: const Text('Inspect Details'),
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
