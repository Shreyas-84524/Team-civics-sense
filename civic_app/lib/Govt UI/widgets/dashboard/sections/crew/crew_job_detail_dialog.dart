import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../services/government_crew_work_service.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../complaints/shared/government_evidence_gallery.dart';

/// Comprehensive operational field job detail modal for crew technicians.
class CrewJobDetailDialog extends StatelessWidget {
  final CrewJobItem job;
  final VoidCallback? onStartJob;
  final VoidCallback? onSubmitCompletion;
  final VoidCallback? onReportIssue;
  final VoidCallback? onResumeRework;
  final VoidCallback? onAssignExecutionOfficer;

  const CrewJobDetailDialog({
    super.key,
    required this.job,
    this.onStartJob,
    this.onSubmitCompletion,
    this.onReportIssue,
    this.onResumeRework,
    this.onAssignExecutionOfficer,
  });

  @override
  Widget build(BuildContext context) {
    final c = job.complaint;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 860),
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      color: GovtThemeTokens.primary,
                      size: 24,
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'FIELD JOB DETAILS',
                              style: CivicFixTypography.h3.copyWith(
                                color: GovtThemeTokens.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            CivicFixSpacing.hSpaceSm,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: GovtThemeTokens.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: GovtThemeTokens.borderLight),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me_outlined,
                                      size: 12,
                                      color: GovtThemeTokens.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    job.formattedDistance,
                                    style: CivicFixTypography.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: GovtThemeTokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Ticket #${job.ticketNumber} · ${c.category.name}',
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceMd,
              const Divider(color: GovtThemeTokens.divider, height: 1),
              CivicFixSpacing.vSpaceMd,

              // Rework Banner (if returned for rework)
              if (job.isReturnedForRework) ...[
                Container(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.replay_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      CivicFixSpacing.hSpaceSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RETURNED FOR REWORK BY DEPARTMENT LEAD',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: const Color(0xFFB91C1C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              job.reworkReason ??
                                  'Work was reviewed and rejected. Please correct site defects and resubmit.',
                              style: CivicFixTypography.bodySmall.copyWith(
                                color: const Color(0xFF7F1D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceLg,
              ],

              // Title & Description
              Text(
                job.title,
                style: CivicFixTypography.h3.copyWith(
                  color: GovtThemeTokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                job.description,
                style: CivicFixTypography.bodySmall.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  height: 1.4,
                ),
              ),
              CivicFixSpacing.vSpaceLg,

              // Location Information Box
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
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: GovtThemeTokens.primary),
                        CivicFixSpacing.hSpaceXs,
                        Text(
                          'LOCATION & MUNICIPAL JURISDICTION',
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      job.address,
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    if (job.landmark != null && job.landmark!.isNotEmpty) ...[
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Landmark: ${job.landmark}',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ],
                    CivicFixSpacing.vSpaceSm,
                    Row(
                      children: [
                        Text(
                          'Ward: ${job.ward} Ward · Dept: ${job.department}',
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textMuted,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.directions_outlined, size: 14),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GovtThemeTokens.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: CivicFixTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Opening GPS route to ${job.address}...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,

              // Citizen Evidence Photos
              if (job.citizenImageUrls.isNotEmpty) ...[
                GovernmentEvidenceGallery(
                  title: 'CITIZEN REPORT EVIDENCE (${job.citizenImageUrls.length})',
                  evidenceItems: [
                    for (int i = 0; i < job.citizenImageUrls.length; i++)
                      GovernmentEvidenceItem(
                        imageUrl: job.citizenImageUrls[i],
                        title: 'Citizen Report Evidence #${i + 1}',
                        stage: 'citizen',
                        timestamp: c.createdAt,
                      ),
                  ],
                ),
                CivicFixSpacing.vSpaceLg,
              ],

              // Supervisor Notes (if present)
              if (c.officerNotes != null && c.officerNotes!.isNotEmpty) ...[
                Text(
                  'OFFICER NOTES & INSTRUCTIONS',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GovtThemeTokens.borderLight),
                  ),
                  child: Text(
                    c.officerNotes!,
                    style: CivicFixTypography.bodySmall.copyWith(
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ),
                CivicFixSpacing.vSpaceLg,
              ],

              // Timeline History
              Text(
                'WORK TIMELINE & AUDIT LOG',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              CivicFixSpacing.vSpaceSm,
              Container(
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GovtThemeTokens.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: c.timeline.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: GovtThemeTokens.divider, height: 1),
                  itemBuilder: (ctx, idx) {
                    final event = c.timeline[idx];
                    return Padding(
                      padding: const EdgeInsets.all(CivicFixSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: GovtThemeTokens.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          CivicFixSpacing.hSpaceSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      event.title,
                                      style: CivicFixTypography.captionMedium
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: GovtThemeTokens.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${event.timestamp.day}/${event.timestamp.month} ${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                                      style:
                                          CivicFixTypography.caption.copyWith(
                                        color: GovtThemeTokens.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                CivicFixSpacing.vSpaceXs,
                                Text(
                                  event.description,
                                  style: CivicFixTypography.caption.copyWith(
                                    color: GovtThemeTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              CivicFixSpacing.vSpaceLg,
              const Divider(color: GovtThemeTokens.divider, height: 1),
              CivicFixSpacing.vSpaceMd,

              // Action Buttons Row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Assign Execution Officer
                  if (onAssignExecutionOfficer != null &&
                      c.assignedFieldOfficerId == null &&
                      c.assignedCrewMemberId != null) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.engineering_outlined, size: 18),
                      label: const Text('Assign Execution Officer'),
                      onPressed: () {
                        Navigator.pop(context);
                        onAssignExecutionOfficer!();
                      },
                    ),
                  ],

                  // Rework Resume
                  if (job.isReturnedForRework && onResumeRework != null) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Resume Work on Rework'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onResumeRework!();
                      },
                    ),
                  ],

                  // Report Issue
                  if (c.status != ComplaintStatus.resolved &&
                      onReportIssue != null) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.report_problem_outlined,
                          size: 16, color: Color(0xFFEF4444)),
                      label: const Text('Report Issue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onReportIssue!();
                      },
                    ),
                  ],

                  // Start Job
                  if (job.canStart && onStartJob != null) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Start Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onStartJob!();
                      },
                    ),
                  ],

                  // Submit For Verification
                  if (job.canSubmitCompletion &&
                      onSubmitCompletion != null) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: const Text('Solved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onSubmitCompletion!();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
