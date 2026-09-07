import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/civic_fix_outlined_button.dart';

/// Filter selection bottom sheet for the Hazard Map screen.
class MapFilterSheet extends StatefulWidget {
  final String? selectedCategoryId;
  final ComplaintStatus? selectedStatus;
  final Function(String? categoryId, ComplaintStatus? status) onApply;

  const MapFilterSheet({
    super.key,
    this.selectedCategoryId,
    this.selectedStatus,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required String? selectedCategoryId,
    required ComplaintStatus? selectedStatus,
    required Function(String? categoryId, ComplaintStatus? status) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapFilterSheet(
        selectedCategoryId: selectedCategoryId,
        selectedStatus: selectedStatus,
        onApply: onApply,
      ),
    );
  }

  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  late String? _selectedCategoryId;
  late ComplaintStatus? _selectedStatus;

  final List<Map<String, dynamic>> _mapCategories = [
    {'id': 'all', 'name': 'All Categories', 'icon': Icons.apps_rounded},
    {'id': 'cat_roads', 'name': 'Road Damage', 'icon': Icons.edit_road_rounded},
    {'id': 'cat_water', 'name': 'Waterlogging', 'icon': Icons.water_drop_rounded},
    {'id': 'cat_manhole', 'name': 'Open Manhole', 'icon': Icons.warning_amber_rounded},
    {'id': 'cat_garbage', 'name': 'Garbage', 'icon': Icons.delete_outline_rounded},
    {'id': 'cat_drainage', 'name': 'Drainage', 'icon': Icons.waves_rounded},
    {'id': 'cat_lights', 'name': 'Street Light', 'icon': Icons.lightbulb_outline_rounded},
    {'id': 'cat_other', 'name': 'Other', 'icon': Icons.category_rounded},
  ];

  final List<Map<String, dynamic>> _statusFilters = [
    {'status': null, 'label': 'All Statuses'},
    {'status': ComplaintStatus.reported, 'label': 'Reported'},
    {'status': ComplaintStatus.verified, 'label': 'Verified'},
    {'status': ComplaintStatus.assigned, 'label': 'Assigned'},
    {'status': ComplaintStatus.inProgress, 'label': 'In Progress'},
    {'status': ComplaintStatus.resolved, 'label': 'Resolved'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedStatus = widget.selectedStatus;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedStatus = null;
    });
  }

  void _applyFilters() {
    widget.onApply(
      _selectedCategoryId == 'all' ? null : _selectedCategoryId,
      _selectedStatus,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CivicFixColors.surface,
        borderRadius: CivicFixRadius.sheetRadius,
      ),
      padding: EdgeInsets.only(
        left: CivicFixSpacing.lg,
        right: CivicFixSpacing.lg,
        top: CivicFixSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + CivicFixSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Civic Issues',
                style: CivicFixTypography.h3,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: CivicFixColors.secondaryText),
                tooltip: 'Close filter',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // 1. Category Filter Section
          Text(
            'Hazard Category',
            style: CivicFixTypography.bodySmallMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: CivicFixColors.primaryText,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: _mapCategories.map((cat) {
              final catId = cat['id'] as String;
              final isSelected = (_selectedCategoryId == null && catId == 'all') ||
                  _selectedCategoryId == catId ||
                  (_selectedCategoryId != null &&
                      _selectedCategoryId!.toLowerCase().contains(cat['name'].toString().toLowerCase().split(' ').first));

              return FilterChip(
                avatar: Icon(
                  cat['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : CivicFixColors.primary,
                ),
                label: Text(cat['name'] as String),
                selected: isSelected,
                selectedColor: CivicFixColors.primary,
                backgroundColor: CivicFixColors.surfaceMuted,
                labelStyle: CivicFixTypography.captionMedium.copyWith(
                  color: isSelected ? Colors.white : CivicFixColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: CivicFixRadius.chipRadius,
                  side: BorderSide(
                    color: isSelected ? CivicFixColors.primary : CivicFixColors.border,
                  ),
                ),
                showCheckmark: false,
                onSelected: (_) {
                  setState(() {
                    _selectedCategoryId = catId == 'all' ? null : catId;
                  });
                },
              );
            }).toList(),
          ),
          CivicFixSpacing.vSpaceLg,

          // 2. Status Filter Section
          Text(
            'Issue Status',
            style: CivicFixTypography.bodySmallMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: CivicFixColors.primaryText,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: _statusFilters.map((st) {
              final ComplaintStatus? status = st['status'] as ComplaintStatus?;
              final isSelected = _selectedStatus == status;

              return FilterChip(
                label: Text(st['label'] as String),
                selected: isSelected,
                selectedColor: CivicFixColors.secondary,
                backgroundColor: CivicFixColors.surfaceMuted,
                labelStyle: CivicFixTypography.captionMedium.copyWith(
                  color: isSelected ? Colors.white : CivicFixColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: CivicFixRadius.chipRadius,
                  side: BorderSide(
                    color: isSelected ? CivicFixColors.secondary : CivicFixColors.border,
                  ),
                ),
                showCheckmark: false,
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
              );
            }).toList(),
          ),
          CivicFixSpacing.vSpaceXxl,

          // Action Buttons: Clear Filters & Apply
          Row(
            children: [
              Expanded(
                child: CivicFixOutlinedButton(
                  text: 'Clear Filters',
                  onPressed: _clearFilters,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: CivicFixButton(
                  text: 'Apply Filters',
                  onPressed: _applyFilters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
