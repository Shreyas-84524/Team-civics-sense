import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/widgets/civic_fix_button.dart';

enum ComplaintSortOption {
  recentlyUpdated,
  newestFirst,
  oldestFirst;

  String get label {
    switch (this) {
      case ComplaintSortOption.recentlyUpdated:
        return 'Recently Updated';
      case ComplaintSortOption.newestFirst:
        return 'Newest First';
      case ComplaintSortOption.oldestFirst:
        return 'Oldest First';
    }
  }
}

class ComplaintFilterCriteria {
  final ComplaintStatus? status;
  final CivicCategory? category;
  final ComplaintSortOption sortOption;

  const ComplaintFilterCriteria({
    this.status,
    this.category,
    this.sortOption = ComplaintSortOption.recentlyUpdated,
  });

  bool get hasActiveFilters =>
      status != null ||
      category != null ||
      sortOption != ComplaintSortOption.recentlyUpdated;

  ComplaintFilterCriteria copyWith({
    ComplaintStatus? status,
    bool clearStatus = false,
    CivicCategory? category,
    bool clearCategory = false,
    ComplaintSortOption? sortOption,
  }) {
    return ComplaintFilterCriteria(
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

/// Bottom Sheet modal for advanced complaint filtering and sorting.
class ComplaintFilterBottomSheet extends StatefulWidget {
  final ComplaintFilterCriteria initialCriteria;
  final ValueChanged<ComplaintFilterCriteria> onApply;

  const ComplaintFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required ComplaintFilterCriteria initialCriteria,
    required ValueChanged<ComplaintFilterCriteria> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ComplaintFilterBottomSheet(
        initialCriteria: initialCriteria,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ComplaintFilterBottomSheet> createState() => _ComplaintFilterBottomSheetState();
}

class _ComplaintFilterBottomSheetState extends State<ComplaintFilterBottomSheet> {
  late ComplaintStatus? _selectedStatus;
  late CivicCategory? _selectedCategory;
  late ComplaintSortOption _selectedSort;

  final List<ComplaintStatus> _statuses = [
    ComplaintStatus.reported,
    ComplaintStatus.verified,
    ComplaintStatus.assigned,
    ComplaintStatus.inProgress,
    ComplaintStatus.resolved,
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialCriteria.status;
    _selectedCategory = widget.initialCriteria.category;
    _selectedSort = widget.initialCriteria.sortOption;
  }

  void _clearAll() {
    setState(() {
      _selectedStatus = null;
      _selectedCategory = null;
      _selectedSort = ComplaintSortOption.recentlyUpdated;
    });
  }

  void _apply() {
    widget.onApply(
      ComplaintFilterCriteria(
        status: _selectedStatus,
        category: _selectedCategory,
        sortOption: _selectedSort,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: CivicFixColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CivicFixSpacing.lg,
              CivicFixSpacing.md,
              CivicFixSpacing.lg,
              CivicFixSpacing.sm,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CivicFixColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                CivicFixSpacing.vSpaceMd,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter & Sort',
                      style: CivicFixTypography.h3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close Filters',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CivicFixColors.border),

          // Scrollable Filter Sections
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(CivicFixSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Status Section
                  _buildSectionTitle('Complaint Status'),
                  CivicFixSpacing.vSpaceSm,
                  Wrap(
                    spacing: CivicFixSpacing.sm,
                    runSpacing: CivicFixSpacing.sm,
                    children: [
                      _buildChoiceChip(
                        label: 'All Statuses',
                        isSelected: _selectedStatus == null,
                        onSelected: () => setState(() => _selectedStatus = null),
                      ),
                      ..._statuses.map(
                        (status) => _buildChoiceChip(
                          label: status.label,
                          isSelected: _selectedStatus == status,
                          onSelected: () => setState(() => _selectedStatus = status),
                        ),
                      ),
                    ],
                  ),
                  CivicFixSpacing.vSpaceXl,

                  // 2. Category Section
                  _buildSectionTitle('Issue Category'),
                  CivicFixSpacing.vSpaceSm,
                  Wrap(
                    spacing: CivicFixSpacing.sm,
                    runSpacing: CivicFixSpacing.sm,
                    children: [
                      _buildChoiceChip(
                        label: 'All Categories',
                        isSelected: _selectedCategory == null,
                        onSelected: () => setState(() => _selectedCategory = null),
                      ),
                      ...CivicCategory.defaultCategories.map(
                        (category) => _buildChoiceChip(
                          label: category.name,
                          icon: category.icon,
                          isSelected: _selectedCategory?.id == category.id,
                          onSelected: () => setState(() => _selectedCategory = category),
                        ),
                      ),
                    ],
                  ),
                  CivicFixSpacing.vSpaceXl,

                  // 3. Sorting Section
                  _buildSectionTitle('Sort By'),
                  CivicFixSpacing.vSpaceSm,
                  Wrap(
                    spacing: CivicFixSpacing.sm,
                    runSpacing: CivicFixSpacing.sm,
                    children: ComplaintSortOption.values.map(
                      (option) => _buildChoiceChip(
                        label: option.label,
                        isSelected: _selectedSort == option,
                        onSelected: () => setState(() => _selectedSort = option),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar: Clear & Apply
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            decoration: BoxDecoration(
              color: CivicFixColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CivicFixColors.primaryText,
                      side: const BorderSide(color: CivicFixColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: CivicFixRadius.buttonRadius,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.md),
                    ),
                    child: const Text('Clear Filters'),
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: CivicFixButton(
                    text: 'Apply Filters',
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: CivicFixTypography.bodySmallMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: CivicFixColors.primaryText,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : CivicFixColors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: CivicFixColors.primary,
      backgroundColor: CivicFixColors.surface,
      labelStyle: CivicFixTypography.captionMedium.copyWith(
        color: isSelected ? Colors.white : CivicFixColors.primaryText,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? CivicFixColors.primary : CivicFixColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: CivicFixRadius.chipRadius,
      ),
      showCheckmark: false,
    );
  }
}
