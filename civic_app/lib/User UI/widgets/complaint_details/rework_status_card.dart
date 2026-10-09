import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../../core/widgets/supabase_evidence_image.dart';
import '../../../core/localization/app_localizations.dart';
import 'evidence_gallery.dart';

/// Card displayed when a complaint has been reopened by a Department Lead / Supervisory Review
/// for incomplete or defective field work, providing full transparency on rework reasons.
class ReworkStatusCard extends StatefulWidget {
  final ComplaintModel complaint;

  const ReworkStatusCard({
    super.key,
    required this.complaint,
  });

  @override
  State<ReworkStatusCard> createState() => _ReworkStatusCardState();
}

class _ReworkStatusCardState extends State<ReworkStatusCard> {
  bool _isHistoryExpanded = false;

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
    final complaint = widget.complaint;
    final isReopened = complaint.isReopened || (complaint.reopenCount > 0 && complaint.status != ComplaintStatus.resolved);

    if (!isReopened) {
      return const SizedBox.shrink();
    }

    final reason = complaint.reopenReason ??
        'Work quality did not meet municipal standards upon audit review. Reassigned for corrective action.';
    final reviewer = complaint.reopenedBy != null && complaint.reopenedBy!.isNotEmpty
        ? complaint.reopenedBy!
        : 'Department Lead Quality Audit';
    final reopenedTime = complaint.reopenedAt != null
        ? DateFormatter.formatFullDate(complaint.reopenedAt!)
        : DateFormatter.formatFullDate(complaint.updatedAt);
    final previousImages = complaint.previousResolutionEvidence;

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Rework Alert Badge + Cycle Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CivicFixColors.alertDark.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.replay_circle_filled_rounded,
                        size: 20,
                        color: CivicFixColors.alertDark,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reopened for Quality Rework',
                            style: CivicFixTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: CivicFixColors.alertDark,
                            ),
                          ),
                          Text(
                            'Supervisory Quality Review Action',
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
              ),
              CivicFixSpacing.hSpaceSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CivicFixColors.alertDark.withValues(alpha: 0.15),
                  borderRadius: CivicFixRadius.chipRadius,
                  border: Border.all(
                    color: CivicFixColors.alertDark.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  complaint.reopenCount > 1
                      ? 'Rework Cycle #${complaint.reopenCount}'
                      : 'Rework Required',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: CivicFixColors.alertDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // Citizen-Safe Reopen Reason Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: CivicFixColors.statusInProgressBg,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(
                color: CivicFixColors.alertDark.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: CivicFixColors.alertDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reason for Reopening',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: CivicFixColors.alertDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                CivicFixTranslatedText(
                  originalText: reason,
                  contentId: complaint.id,
                  fieldName: 'reopenReason',
                  contentCategory: 'rework_reason',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: CivicFixColors.primaryText,
                    height: 1.35,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: CivicFixColors.disabledText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Reviewed by: $reviewer • $reopenedTime',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // SLA Preservation & Priority Re-execution Note
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: CivicFixColors.primary,
              ),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  'Original SLA preserved from submission. Priority ground execution underway.',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          // Previous Resolution Evidence Disclosure (Expandable)
          if (previousImages.isNotEmpty || complaint.previousResolvedAt != null) ...[
            CivicFixSpacing.vSpaceMd,
            InkWell(
              onTap: () {
                setState(() {
                  _isHistoryExpanded = !_isHistoryExpanded;
                });
              },
              borderRadius: CivicFixRadius.chipRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _isHistoryExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: CivicFixColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _isHistoryExpanded
                            ? 'Hide Previous Resolution Record'
                            : 'View Previous Resolution Record (${previousImages.length} photos)',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isHistoryExpanded) ...[
              CivicFixSpacing.vSpaceSm,
              if (complaint.previousResolvedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: CivicFixSpacing.xs),
                  child: Text(
                    'Prior resolution timestamp: ${DateFormatter.formatFullDate(complaint.previousResolvedAt!)}',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.disabledText,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (previousImages.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - ((previousImages.length - 1) * CivicFixSpacing.sm)) /
                        (previousImages.length > 3 ? 3 : previousImages.length).clamp(1, 3);
                    return Row(
                      children: List.generate(previousImages.length, (index) {
                        final path = previousImages[index];
                        final isLast = index == previousImages.length - 1;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : CivicFixSpacing.sm),
                            child: InkWell(
                              onTap: () => _openImageViewer(context, previousImages, index),
                              borderRadius: CivicFixRadius.cardRadius,
                              child: Container(
                                height: itemWidth > 100 ? 100 : itemWidth,
                                decoration: BoxDecoration(
                                  color: CivicFixColors.surfaceMuted,
                                  borderRadius: CivicFixRadius.cardRadius,
                                  border: Border.all(color: CivicFixColors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SupabaseEvidenceImage(
                                  imagePath: path,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
            ],
          ],
        ],
      ),
    );
  }
}
