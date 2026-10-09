import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/mappers/canonical_display_mappers.dart';
import '../../../core/map/spatial_data_service.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/civic_fix_outlined_button.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Filter selection bottom sheet for the Hazard Map screen.
class MapFilterSheet extends StatefulWidget {
  final String? selectedCategoryId;
  final ComplaintStatus? selectedStatus;
  final SpatialTimeFilter? selectedTimeFilter;
  final Function onApply;

  const MapFilterSheet({
    super.key,
    this.selectedCategoryId,
    this.selectedStatus,
    this.selectedTimeFilter,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required String? selectedCategoryId,
    required ComplaintStatus? selectedStatus,
    SpatialTimeFilter? selectedTimeFilter,
    required Function onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapFilterSheet(
        selectedCategoryId: selectedCategoryId,
        selectedStatus: selectedStatus,
        selectedTimeFilter: selectedTimeFilter,
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
  late SpatialTimeFilter? _selectedTimeFilter;

  final List<Map<String, dynamic>> _mapCategories = [
    {'id': 'all', 'canonicalId': 'all', 'icon': Icons.apps_rounded},
    {'id': 'cat_roads', 'canonicalId': 'roads', 'icon': Icons.edit_road_rounded},
    {'id': 'cat_water', 'canonicalId': 'water', 'icon': Icons.water_drop_rounded},
    {'id': 'cat_manhole', 'canonicalId': 'manholes', 'icon': Icons.warning_amber_rounded},
    {'id': 'cat_garbage', 'canonicalId': 'waste', 'icon': Icons.delete_outline_rounded},
    {'id': 'cat_drainage', 'canonicalId': 'drainage', 'icon': Icons.waves_rounded},
    {'id': 'cat_lights', 'canonicalId': 'streetlights', 'icon': Icons.lightbulb_outline_rounded},
    {'id': 'cat_other', 'canonicalId': 'other', 'icon': Icons.category_rounded},
  ];

  final List<ComplaintStatus?> _statusFilterValues = [
    null,
    ComplaintStatus.reported,
    ComplaintStatus.verified,
    ComplaintStatus.assigned,
    ComplaintStatus.inProgress,
    ComplaintStatus.resolved,
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedStatus = widget.selectedStatus;
    _selectedTimeFilter = widget.selectedTimeFilter;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedStatus = null;
      _selectedTimeFilter = null;
    });
  }

  void _applyFilters() {
    try {
      widget.onApply(
        _selectedCategoryId == 'all' ? null : _selectedCategoryId,
        _selectedStatus,
        _selectedTimeFilter,
      );
    } catch (_) {
      widget.onApply(
        _selectedCategoryId == 'all' ? null : _selectedCategoryId,
        _selectedStatus,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                l10n?.filterCivicIssues ?? 'Filter Civic Issues',
                style: CivicFixTypography.h3,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: CivicFixColors.secondaryText),
                tooltip: l10n?.commonCancel ?? 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,

          // 1. Category Filter Section
          Text(
            l10n?.hazardCategory ?? 'Hazard Category',
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
              final canonicalId = cat['canonicalId'] as String;
              final isAll = canonicalId == 'all';
              final label = isAll
                  ? (l10n?.allCategories ?? 'All Categories')
                  : localizedCategory(canonicalId, context: context, l10n: l10n);

              final isSelected = (_selectedCategoryId == null && catId == 'all') ||
                  _selectedCategoryId == catId ||
                  (_selectedCategoryId != null &&
                      _selectedCategoryId!.toLowerCase().contains(canonicalId.toLowerCase()));

              return FilterChip(
                avatar: Icon(
                  cat['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : CivicFixColors.primary,
                ),
                label: Text(label),
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
            l10n?.issueStatus ?? 'Issue Status',
            style: CivicFixTypography.bodySmallMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: CivicFixColors.primaryText,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: _statusFilterValues.map((status) {
              final isSelected = _selectedStatus == status;
              final label = status == null
                  ? (l10n?.allStatuses ?? 'All Statuses')
                  : localizedComplaintStatus(status, context: context, l10n: l10n);

              return FilterChip(
                label: Text(label),
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
          CivicFixSpacing.vSpaceLg,

          // 3. Time Window Section
          Text(
            l10n?.reportTimeframe ?? 'Report Timeframe',
            style: CivicFixTypography.bodySmallMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: CivicFixColors.primaryText,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: CivicFixSpacing.sm,
            runSpacing: CivicFixSpacing.sm,
            children: SpatialTimeFilter.values.map((tf) {
              final isSelected = (_selectedTimeFilter == null && tf == SpatialTimeFilter.allTime) ||
                  _selectedTimeFilter == tf;

              return FilterChip(
                label: Text(tf.label),
                selected: isSelected,
                selectedColor: CivicFixColors.accent,
                backgroundColor: CivicFixColors.surfaceMuted,
                labelStyle: CivicFixTypography.captionMedium.copyWith(
                  color: isSelected ? Colors.white : CivicFixColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: CivicFixRadius.chipRadius,
                  side: BorderSide(
                    color: isSelected ? CivicFixColors.accent : CivicFixColors.border,
                  ),
                ),
                showCheckmark: false,
                onSelected: (_) {
                  setState(() {
                    _selectedTimeFilter = tf == SpatialTimeFilter.allTime ? null : tf;
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
                  text: l10n?.clearFilters ?? 'Clear Filters',
                  onPressed: _clearFilters,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: CivicFixButton(
                  text: l10n?.applyFilters ?? 'Apply Filters',
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
