import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/category_model.dart';

/// Interactive Civic Category Selector for Step 1 of Report Issue.
class IssueCategorySelector extends StatelessWidget {
  final CivicCategory? selectedCategory;
  final ValueChanged<CivicCategory> onCategorySelected;
  final String? errorMessage;

  const IssueCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final categories = CivicCategory.defaultCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Category',
              style: CivicFixTypography.bodySmallMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: CivicFixColors.primaryText,
              ),
            ),
            Text(
              ' *',
              style: CivicFixTypography.bodySmallMedium.copyWith(
                color: CivicFixColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          'Select the category that best matches the problem.',
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        CivicFixSpacing.vSpaceSm,

        // Category Cards Grid / List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, _) => CivicFixSpacing.vSpaceSm,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory?.id == category.id;

            return _CategoryTile(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category),
            );
          },
        ),

        // Error message if category was omitted
        if (errorMessage != null) ...[
          CivicFixSpacing.vSpaceXs,
          Padding(
            padding: const EdgeInsets.only(left: CivicFixSpacing.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: CivicFixColors.error,
                  size: 14,
                ),
                CivicFixSpacing.hSpaceXs,
                Text(
                  errorMessage!,
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CivicCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${category.name}: ${category.description}',
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: CivicFixRadius.cardRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.md,
              vertical: CivicFixSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isSelected ? CivicFixColors.accentLight.withValues(alpha: 0.35) : CivicFixColors.surface,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(
                color: isSelected ? CivicFixColors.secondary : CivicFixColors.border,
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: CivicFixColors.secondary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CivicFixColors.secondary
                        : CivicFixColors.primary.withValues(alpha: 0.08),
                    borderRadius: CivicFixRadius.chipRadius,
                  ),
                  child: Icon(
                    category.icon,
                    size: 22,
                    color: isSelected ? Colors.white : CivicFixColors.primary,
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? CivicFixColors.secondaryDark : CivicFixColors.primaryText,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        category.description,
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? CivicFixColors.secondary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? CivicFixColors.secondary : CivicFixColors.disabledText,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
