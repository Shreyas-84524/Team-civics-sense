import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/department_helper.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Card summarizing issue information: Category, Department, Description, and Priority.
class IssueInfoCard extends StatelessWidget {
  final ComplaintModel complaint;

  const IssueInfoCard({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    final department = DepartmentHelper.getDepartmentName(complaint.category);

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue Information',
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
                      'Category',
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
                            complaint.category.name,
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
                      'Department',
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
                            department,
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

          // Description Section
          Text(
            'Description',
            style: CivicFixTypography.caption.copyWith(
              color: CivicFixColors.secondaryText,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            complaint.description.isNotEmpty
                ? complaint.description
                : 'No additional description provided.',
            style: CivicFixTypography.bodySmall.copyWith(
              color: CivicFixColors.primaryText,
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
                    'Priority: ',
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
                      complaint.priority.label,
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
                        'Safety Hazard',
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
