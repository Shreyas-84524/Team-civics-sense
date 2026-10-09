import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../../core/widgets/supabase_evidence_image.dart';
import '../../../core/localization/widgets/civic_fix_translated_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'evidence_gallery.dart';

/// Card presenting ground execution resolution evidence: Before and After photos,
/// Field Officer remarks, resolved timestamp, and verifier identity.
class ResolutionEvidenceCard extends StatelessWidget {
  final ComplaintModel complaint;

  const ResolutionEvidenceCard({
    super.key,
    required this.complaint,
  });

  void _openImageViewer(BuildContext context, List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => ImageViewerModal(
        imageUrls: images,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final beforePhoto = complaint.beforeWorkPhoto ??
        (complaint.imageUrls.isNotEmpty ? complaint.imageUrls.first : null);
    final afterPhoto = complaint.afterWorkPhoto ??
        (complaint.previousResolutionEvidence.isNotEmpty
            ? complaint.previousResolutionEvidence.last
            : null);
    final remarks = complaint.resolutionRemarks;
    final resolvedDate = complaint.resolvedAt ?? complaint.updatedAt;
    final resolvedByOfficer = complaint.resolvedBy ??
        complaint.assignedFieldOfficerName ??
        (l10n?.fieldExecutionOfficer ?? 'Field Execution Officer');

    final hasEvidence = beforePhoto != null || afterPhoto != null || (remarks != null && remarks.isNotEmpty);
    if (!hasEvidence && complaint.status != ComplaintStatus.resolved) {
      return const SizedBox.shrink();
    }

    final List<String> viewableImages = [
      ?beforePhoto,
      ?afterPhoto,
    ];

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CivicFixColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 18,
                  color: CivicFixColors.secondary,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.resolutionAndVerification ?? 'Resolution & Work Verification',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CivicFixColors.primaryText,
                      ),
                    ),
                    Text(
                      l10n?.groundInspectionEvidence ?? 'Ground inspection & completion evidence',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Before & After Evidence Comparison
          if (beforePhoto != null || afterPhoto != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 380 && beforePhoto != null && afterPhoto != null;
                final beforeTitle = l10n?.reportedIssueBefore ?? 'Reported Issue (Before)';
                final afterTitle = l10n?.resolvedConditionAfter ?? 'Resolved Condition (After)';

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildEvidenceTile(
                          context: context,
                          title: beforeTitle,
                          imagePath: beforePhoto,
                          badgeColor: CivicFixColors.alertDark,
                          onTap: () => _openImageViewer(context, viewableImages, 0),
                        ),
                      ),
                      CivicFixSpacing.hSpaceMd,
                      Expanded(
                        child: _buildEvidenceTile(
                          context: context,
                          title: afterTitle,
                          imagePath: afterPhoto,
                          badgeColor: CivicFixColors.secondary,
                          onTap: () => _openImageViewer(
                            context,
                            viewableImages,
                            1,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      if (beforePhoto != null) ...[
                        _buildEvidenceTile(
                          context: context,
                          title: beforeTitle,
                          imagePath: beforePhoto,
                          badgeColor: CivicFixColors.alertDark,
                          onTap: () => _openImageViewer(context, viewableImages, 0),
                        ),
                        if (afterPhoto != null) CivicFixSpacing.vSpaceMd,
                      ],
                      if (afterPhoto != null) ...[
                        _buildEvidenceTile(
                          context: context,
                          title: afterTitle,
                          imagePath: afterPhoto,
                          badgeColor: CivicFixColors.secondary,
                          onTap: () => _openImageViewer(
                            context,
                            viewableImages,
                            beforePhoto != null ? 1 : 0,
                          ),
                        ),
                      ],
                    ],
                  );
                }
              },
            ),
            CivicFixSpacing.vSpaceLg,
          ],

          // Field Officer Completion Remarks (Authoritative officer text is preserved immutable)
          if (remarks != null && remarks.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(CivicFixSpacing.md),
              decoration: BoxDecoration(
                color: CivicFixColors.statusResolvedBg.withValues(alpha: 0.5),
                borderRadius: CivicFixRadius.cardRadius,
                border: Border.all(
                  color: CivicFixColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.rate_review_outlined,
                        size: 14,
                        color: CivicFixColors.secondaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n?.officerResolutionRemarks ?? 'Officer Resolution Remarks',
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: CivicFixColors.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                  CivicFixSpacing.vSpaceXs,
                  CivicFixTranslatedText(
                    originalText: remarks,
                    contentId: complaint.id,
                    fieldName: 'resolutionRemarks',
                    contentCategory: 'resolution_remarks',
                    style: CivicFixTypography.bodySmall.copyWith(
                      color: CivicFixColors.primaryText,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            CivicFixSpacing.vSpaceMd,
          ],

          // Footer: Resolved On & Verified By
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: CivicFixSpacing.sm,
              horizontal: CivicFixSpacing.md,
            ),
            decoration: BoxDecoration(
              color: CivicFixColors.surfaceMuted,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: CivicFixColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n?.executedByOfficer(resolvedByOfficer) ?? 'Executed by $resolvedByOfficer',
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: CivicFixColors.primaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                Text(
                  DateFormatter.formatFullDate(resolvedDate),
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceTile({
    required BuildContext context,
    required String title,
    required String imagePath,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: CivicFixRadius.chipRadius,
          ),
          child: Text(
            title,
            style: CivicFixTypography.captionMedium.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
        CivicFixSpacing.vSpaceXs,
        Semantics(
          label: '$title photo. Tap to view full size.',
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: CivicFixRadius.cardRadius,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: CivicFixRadius.cardRadius,
                border: Border.all(color: CivicFixColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SupabaseEvidenceImage(
                    imagePath: imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 180,
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
