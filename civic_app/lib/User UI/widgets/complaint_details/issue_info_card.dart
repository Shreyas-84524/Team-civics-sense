import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/mappers/canonical_display_mappers.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/department_helper.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../../core/localization/widgets/civic_fix_translated_text.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Card summarizing issue information: Category, Department, Description, and Priority.
class IssueInfoCard extends StatelessWidget {
  final ComplaintModel complaint;

  const IssueInfoCard({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rawDepartment = DepartmentHelper.getDepartmentName(complaint.category);
    final displayDepartment = localizedDepartment(rawDepartment, context: context);
    final displayCategory = localizedCategory(complaint.category, context: context);
    final displayPriority = localizedComplaintPriority(complaint.priority, context: context);

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.issueInformation ?? 'Issue Information',
            style: CivicFixTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: CivicFixColors.primaryText,
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // Category & Responsible Department Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.categoryLabel ?? 'Category',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Row(
                      children: [
                        Icon(
                          complaint.category.icon,
                          size: 16,
                          color: CivicFixColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            displayCategory,
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CivicFixColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.hSpaceMd,

              // Department
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.department ?? 'Department',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_outlined,
                          size: 16,
                          color: CivicFixColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            displayDepartment,
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CivicFixColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Description Section (Dynamic presentation translation with View Original toggle)
          Text(
            l10n?.describeTheIssue ?? 'Description',
            style: CivicFixTypography.caption.copyWith(
              color: CivicFixColors.secondaryText,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          complaint.description.isNotEmpty
              ? CivicFixTranslatedText(
                  originalText: complaint.description,
                  contentId: complaint.id,
                  fieldName: 'description',
                  contentCategory: 'complaint_description',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: CivicFixColors.primaryText,
                    height: 1.45,
                  ),
                )
              : Text(
                  l10n?.noDescriptionProvided ?? 'No additional description provided.',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: CivicFixColors.disabledText,
                    height: 1.45,
                  ),
                ),
          CivicFixSpacing.vSpaceLg,

          const Divider(height: 1, color: CivicFixColors.border),
          CivicFixSpacing.vSpaceMd,

          // Priority & Safety Hazard Tags (Read-only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${l10n?.priorityLabel ?? 'Priority'}: ',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: complaint.priority.color.withValues(alpha: 0.12),
                      borderRadius: CivicFixRadius.chipRadius,
                      border: Border.all(
                        color: complaint.priority.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      displayPriority,
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: complaint.priority.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (complaint.isHazard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CivicFixColors.statusUnderReviewBg,
                    borderRadius: CivicFixRadius.chipRadius,
                    border: Border.all(
                      color: CivicFixColors.alertDark.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: CivicFixColors.alertDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.safetyHazard ?? 'Safety Hazard',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.alertDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
