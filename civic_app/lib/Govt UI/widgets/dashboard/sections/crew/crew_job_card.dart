import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../services/government_crew_work_service.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_sla_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Action-oriented, mobile-first field job card for frontline crew technicians.
class CrewJobCard extends StatelessWidget {
  final CrewJobItem job;
  final VoidCallback onViewDetails;
  final VoidCallback? onStartJob;

  const CrewJobCard({
    super.key,
    required this.job,
    required this.onViewDetails,
    this.onStartJob,
  });

  @override
  Widget build(BuildContext context) {
    final c = job.complaint;

    return Container(
      margin: const EdgeInsets.only(bottom: CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: job.isReturnedForRework
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : (c.priority == ComplaintPriority.emergency
                  ? GovtThemeTokens.alert.withValues(alpha: 0.5)
                  : GovtThemeTokens.border),
          width: job.isReturnedForRework || c.priority == ComplaintPriority.emergency ? 1.5 : 1.0,
        ),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rework Notice Banner if returned
          if (job.isReturnedForRework) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.md,
                vertical: CivicFixSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.replay_rounded, size: 16, color: Color(0xFFEF4444)),
                  CivicFixSpacing.hSpaceXs,
                  Expanded(
                    child: Text(
                      'RETURNED FOR REWORK: ${job.reworkReason ?? "Please rectify site defects"}',
                      style: CivicFixTypography.caption.copyWith(
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Card Body
          Padding(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Ticket ID + Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TICKET #${job.ticketNumber}',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: GovtThemeTokens.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              CivicFixSpacing.hSpaceSm,
                              // Distance badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: GovtThemeTokens.surfaceMuted,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: GovtThemeTokens.borderLight),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.near_me_outlined, size: 10, color: GovtThemeTokens.textMuted),
                                    const SizedBox(width: 3),
                                    Text(
                                      job.formattedDistance,
                                      style: CivicFixTypography.caption.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: GovtThemeTokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CivicFixTypography.h3.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: GovtThemeTokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
                  ],
                ),
                CivicFixSpacing.vSpaceSm,

                // Description
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textSecondary,
                    height: 1.3,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,

                // Location & Category details
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: GovtThemeTokens.textMuted),
                    CivicFixSpacing.hSpaceXs,
                    Expanded(
                      child: Text(
                        job.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 15, color: GovtThemeTokens.textMuted),
                    CivicFixSpacing.hSpaceXs,
                    Text(
                      '${c.category.name} · Ward ${job.ward}',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,
                const Divider(color: GovtThemeTokens.divider, height: 1),
                CivicFixSpacing.vSpaceMd,

                // Footer Row: Status, SLA, Action Buttons
                Row(
                  children: [
                    GovtStatusBadge.complaint(c.status, isCompact: true),
                    CivicFixSpacing.hSpaceSm,
                    GovtSlaBadge.fromDuration(
                      createdAt: c.slaStartedAt,
                      resolvedAt: c.resolvedAt,
                      isCompact: true,
                    ),
                    const Spacer(),

                    // Action button
                    if (job.canStart && onStartJob != null) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Start Job'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: onStartJob,
                      ),
                      CivicFixSpacing.hSpaceSm,
                    ],

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GovtThemeTokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: onViewDetails,
                      child: const Text('View Job'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
