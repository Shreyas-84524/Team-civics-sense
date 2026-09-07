import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/complaint_model.dart';
import '../../models/analytics_model.dart';
import '../../models/department_model.dart';
import '../../theme/govt_theme_tokens.dart';

import '../../widgets/common/govt_filter_chip.dart';

/// Top multi-criteria filter toolbar for Government Analytics.
class GovtAnalyticsFilterBar extends StatelessWidget {
  final AnalyticsFilter activeFilter;
  final int totalCount;
  final ValueChanged<AnalyticsFilter> onFilterChanged;
  final VoidCallback onResetFilters;

  const GovtAnalyticsFilterBar({
    super.key,
    required this.activeFilter,
    required this.totalCount,
    required this.onFilterChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Header & Summary Count / Reset Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 20, color: GovtThemeTokens.primary),
                  CivicFixSpacing.hSpaceSm,
                  Text(
                    'Analytics Filters & Time Range',
                    style: CivicFixTypography.h3.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: GovtThemeTokens.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        CivicFixSpacing.hSpaceXs,
                        Text(
                          '$totalCount Grievances Analyzed',
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: GovtThemeTokens.primary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeFilter.isFiltered) ...[
                    CivicFixSpacing.hSpaceMd,
                    TextButton.icon(
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(
                        foregroundColor: GovtThemeTokens.alert,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onResetFilters,
                    ),
                  ],
                ],
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.border, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Section 2: Date Range Filter Pills
          Row(
            children: [
              Text(
                'Time Range:',
                style: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: GovtThemeTokens.textSecondary,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DateRangeOption.values.map((range) {
                      final isSelected = activeFilter.dateRange == range;
                      return Padding(
                        padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
                        child: GovtFilterChip(
                          label: range.label,
                          isSelected: isSelected,
                          onSelected: (_) {
                            onFilterChanged(activeFilter.copyWith(dateRange: range));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // Section 3: Dropdown Filter Controls Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final isTablet = constraints.maxWidth >= 600 && !isDesktop;

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(child: _buildDepartmentDropdown()),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(child: _buildStatusDropdown()),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(child: _buildPriorityDropdown()),
                  ],
                );
              } else if (isTablet) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildCategoryDropdown()),
                        CivicFixSpacing.hSpaceMd,
                        Expanded(child: _buildDepartmentDropdown()),
                      ],
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Row(
                      children: [
                        Expanded(child: _buildStatusDropdown()),
                        CivicFixSpacing.hSpaceMd,
                        Expanded(child: _buildPriorityDropdown()),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCategoryDropdown(),
                    CivicFixSpacing.vSpaceSm,
                    _buildDepartmentDropdown(),
                    CivicFixSpacing.vSpaceSm,
                    _buildStatusDropdown(),
                    CivicFixSpacing.vSpaceSm,
                    _buildPriorityDropdown(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _buildCategoryDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<String?>(
        value: activeFilter.categoryId,
        isExpanded: true,
        hint: Text('All Categories', style: CivicFixTypography.bodySmall),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Categories', style: CivicFixTypography.bodySmall),
          ),
          ...CivicCategory.defaultCategories.map((cat) {
            return DropdownMenuItem(
              value: cat.id,
              child: Text(
                cat.name,
                style: CivicFixTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (val) {
          onFilterChanged(activeFilter.copyWith(
            categoryId: val,
            clearCategory: val == null,
          ));
        },
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<String?>(
        value: activeFilter.departmentId,
        isExpanded: true,
        hint: Text('All Departments', style: CivicFixTypography.bodySmall),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Departments', style: CivicFixTypography.bodySmall),
          ),
          ...GovtDepartmentModel.defaultDepartments.map((dept) {
            return DropdownMenuItem(
              value: dept.id,
              child: Text(
                dept.name,
                style: CivicFixTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (val) {
          onFilterChanged(activeFilter.copyWith(
            departmentId: val,
            clearDepartment: val == null,
          ));
        },
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<ComplaintStatus?>(
        value: activeFilter.status,
        isExpanded: true,
        hint: Text('All Statuses', style: CivicFixTypography.bodySmall),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Statuses', style: CivicFixTypography.bodySmall),
          ),
          ...ComplaintStatus.values.where((s) => s != ComplaintStatus.rejected).map((status) {
            return DropdownMenuItem(
              value: status,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: status.badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  CivicFixSpacing.hSpaceSm,
                  Text(status.label, style: CivicFixTypography.bodySmall),
                ],
              ),
            );
          }),
        ],
        onChanged: (val) {
          onFilterChanged(activeFilter.copyWith(
            status: val,
            clearStatus: val == null,
          ));
        },
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return _buildDropdownContainer(
      child: DropdownButton<ComplaintPriority?>(
        value: activeFilter.priority,
        isExpanded: true,
        hint: Text('All Priorities', style: CivicFixTypography.bodySmall),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Priorities', style: CivicFixTypography.bodySmall),
          ),
          ...ComplaintPriority.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(p.label, style: CivicFixTypography.bodySmall),
            );
          }),
        ],
        onChanged: (val) {
          onFilterChanged(activeFilter.copyWith(
            priority: val,
            clearPriority: val == null,
          ));
        },
      ),
    );
  }
}
