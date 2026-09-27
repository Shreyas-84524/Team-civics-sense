import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'govt_search_field.dart';

/// Configuration definition for a dropdown filter within [GovernmentFilterBar].
class GovtDropdownFilterConfig<T> {
  final String label;
  final T? selectedValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const GovtDropdownFilterConfig({
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    this.icon,
  });
}

/// Dynamic, reusable filter toolbar for municipal lists, tables, and dashboards.
class GovernmentFilterBar extends StatelessWidget {
  final String? searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final List<GovtDropdownFilterConfig<dynamic>> dropdownFilters;
  final List<Widget>? customChips;
  final VoidCallback? onClearAll;
  final int activeFilterCount;
  final Widget? trailingAction;
  final bool showSearch;

  const GovernmentFilterBar({
    super.key,
    this.searchQuery,
    this.onSearchChanged,
    this.searchHint = 'Search records...',
    this.dropdownFilters = const [],
    this.customChips,
    this.onClearAll,
    this.activeFilterCount = 0,
    this.trailingAction,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.lg,
        vertical: CivicFixSpacing.md,
      ),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Search & Dropdown Filters
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSearch)
                  GovtSearchField(
                    width: double.infinity,
                    hintText: searchHint,
                    onChanged: onSearchChanged,
                  ),
                if (dropdownFilters.isNotEmpty) ...[
                  CivicFixSpacing.vSpaceSm,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dropdownFilters
                          .map((config) => Padding(
                                padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
                                child: _buildDropdown(config),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                if (showSearch) ...[
                  GovtSearchField(
                    width: 280,
                    hintText: searchHint,
                    onChanged: onSearchChanged,
                  ),
                  CivicFixSpacing.hSpaceMd,
                ],
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dropdownFilters
                          .map((config) => Padding(
                                padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
                                child: _buildDropdown(config),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                if (activeFilterCount > 0 && onClearAll != null) ...[
                  CivicFixSpacing.hSpaceSm,
                  TextButton.icon(
                    onPressed: onClearAll,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 14),
                    label: Text('Reset ($activeFilterCount)'),
                    style: TextButton.styleFrom(
                      foregroundColor: GovtThemeTokens.textSecondary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
                if (trailingAction != null) ...[
                  CivicFixSpacing.hSpaceSm,
                  trailingAction!,
                ],
              ],
            ),

          // Row 2: Filter Chips & Active Count (if custom chips provided)
          if (customChips != null && customChips!.isNotEmpty) ...[
            CivicFixSpacing.vSpaceSm,
            const Divider(color: GovtThemeTokens.borderLight, height: 1),
            CivicFixSpacing.vSpaceSm,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...customChips!,
                  if (activeFilterCount > 0 && isMobile && onClearAll != null) ...[
                    CivicFixSpacing.hSpaceSm,
                    TextButton(
                      onPressed: onClearAll,
                      child: Text(
                        'Reset ($activeFilterCount)',
                        style: GovtTypography.caption.copyWith(
                          color: GovtThemeTokens.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown(GovtDropdownFilterConfig<dynamic> config) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.sm),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.chipRadius,
        border: Border.all(
          color: config.selectedValue != null
              ? GovtThemeTokens.primary
              : GovtThemeTokens.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: config.selectedValue,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config.icon != null) ...[
                Icon(config.icon, size: 14, color: GovtThemeTokens.textSecondary),
                const SizedBox(width: 4),
              ],
              Text(
                config.label,
                style: GovtTypography.caption.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: GovtThemeTokens.textSecondary,
          ),
          items: config.items
              .map((item) => DropdownMenuItem<dynamic>(
                    value: item.value,
                    child: item.child,
                  ))
              .toList(),
          onChanged: (dynamic val) {
            config.onChanged(val);
          },
          style: GovtTypography.bodySmall.copyWith(
            color: GovtThemeTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
