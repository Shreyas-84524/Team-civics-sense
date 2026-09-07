import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/evidence_model.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../models/complaint_draft.dart';

/// Comprehensive Review Card for Step 4 of Report Issue with individual section edit hooks.
class ComplaintReviewCard extends StatelessWidget {
  final ComplaintDraft draft;
  final Function(int stepNumber) onEditStep;

  const ComplaintReviewCard({
    super.key,
    required this.draft,
    required this.onEditStep,
  });

  void _openPhotoPreview(BuildContext context, int index, String photoPath, EvidenceItem? item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photo Preview (${index + 1} of ${draft.photoCount})',
                    style: CivicFixTypography.h3,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close Preview',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceMd,
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: CivicFixColors.surfaceMuted,
                  borderRadius: CivicFixRadius.cardRadius,
                  border: Border.all(color: CivicFixColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item?.source == EvidenceSource.camera
                          ? Icons.camera_alt_rounded
                          : Icons.image_rounded,
                      size: 48,
                      color: CivicFixColors.primary.withValues(alpha: 0.6),
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      item?.fileName ?? photoPath.split('/').last,
                      textAlign: TextAlign.center,
                      style: CivicFixTypography.bodySmallMedium,
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      item != null
                          ? 'Captured via ${item.source.label} • ${item.formattedTime}'
                          : 'Attached Photo',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceMd,
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = draft.category;
    final location = draft.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your issue',
          style: CivicFixTypography.h2,
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          'Please verify all information before submitting to your ward.',
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        CivicFixSpacing.vSpaceLg,

        // 1. Issue Information Card
        CivicFixCard(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Issue Information',
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CivicFixColors.primaryText,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onEditStep(1),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: CivicFixColors.secondaryDark,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(
                'Title',
                style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                draft.title,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CivicFixSpacing.vSpaceMd,
              Text(
                'Category',
                style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
              ),
              CivicFixSpacing.vSpaceXs,
              if (category != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CivicFixColors.primary.withValues(alpha: 0.1),
                        borderRadius: CivicFixRadius.chipRadius,
                      ),
                      child: Icon(category.icon, size: 16, color: CivicFixColors.primary),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      category.name,
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              CivicFixSpacing.vSpaceMd,
              Text(
                'Description',
                style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                draft.description,
                style: CivicFixTypography.bodySmall,
              ),
              if (draft.isHazard) ...[
                CivicFixSpacing.vSpaceMd,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CivicFixColors.statusUnderReviewBg,
                    borderRadius: CivicFixRadius.chipRadius,
                    border: Border.all(color: CivicFixColors.alert.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: CivicFixColors.alertDark),
                      const SizedBox(width: 4),
                      Text(
                        'Marked as Immediate Safety Hazard',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.alertDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        CivicFixSpacing.vSpaceMd,

        // 2. Photo Evidence Card
        CivicFixCard(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photo Evidence (${draft.photoCount})',
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CivicFixColors.primaryText,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onEditStep(2),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: CivicFixColors.secondaryDark,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              if (draft.photoCount == 0)
                Text(
                  'No photos attached (Optional)',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: CivicFixColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(draft.photoCount, (index) {
                      final path = draft.imageUrls.length > index ? draft.imageUrls[index] : '';
                      final item = draft.evidence.length > index ? draft.evidence[index] : null;

                      return InkWell(
                        onTap: () => _openPhotoPreview(context, index, path, item),
                        borderRadius: CivicFixRadius.chipRadius,
                        child: Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: CivicFixSpacing.sm),
                          decoration: BoxDecoration(
                            color: CivicFixColors.surfaceMuted,
                            borderRadius: CivicFixRadius.chipRadius,
                            border: Border.all(color: CivicFixColors.border),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item?.source == EvidenceSource.camera
                                        ? Icons.camera_alt_outlined
                                        : Icons.image_outlined,
                                    color: CivicFixColors.secondaryDark,
                                    size: 24,
                                  ),
                                  CivicFixSpacing.vSpaceXs,
                                  Text(
                                    'Photo ${index + 1}',
                                    style: CivicFixTypography.caption.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: CivicFixColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        CivicFixSpacing.vSpaceMd,

        // 3. Location Card
        CivicFixCard(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Location',
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CivicFixColors.primaryText,
                          ),
                        ),
                        if (location != null) ...[
                          CivicFixSpacing.hSpaceSm,
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: location.isGps
                                    ? CivicFixColors.secondary.withValues(alpha: 0.12)
                                    : CivicFixColors.primary.withValues(alpha: 0.08),
                                borderRadius: CivicFixRadius.chipRadius,
                              ),
                              child: Text(
                                location.sourceLabel,
                                overflow: TextOverflow.ellipsis,
                                style: CivicFixTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: location.isGps
                                      ? CivicFixColors.secondaryDark
                                      : CivicFixColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onEditStep(3),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: CivicFixColors.secondaryDark,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              if (location != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: CivicFixColors.primary,
                      size: 20,
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.address,
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (location.landmark != null && location.landmark!.isNotEmpty) ...[
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              'Near ${location.landmark}',
                              style: CivicFixTypography.caption.copyWith(
                                color: CivicFixColors.secondaryText,
                              ),
                            ),
                          ],
                          if (location.ward != null && location.ward!.isNotEmpty) ...[
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              location.ward!,
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: CivicFixColors.secondaryDark,
                              ),
                            ),
                          ],
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Lat: ${location.latitude.toStringAsFixed(4)}, Long: ${location.longitude.toStringAsFixed(4)}',
                            style: CivicFixTypography.caption.copyWith(
                              fontSize: 10,
                              color: CivicFixColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        CivicFixSpacing.vSpaceMd,

        // Department Routing Preview Info
        Container(
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: CivicFixColors.surfaceMuted,
            borderRadius: CivicFixRadius.cardRadius,
            border: Border.all(color: CivicFixColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                color: CivicFixColors.info,
                size: 20,
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Text(
                  'This issue will be routed to ${draft.departmentName}.',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
