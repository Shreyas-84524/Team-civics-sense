import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/mappers/canonical_display_mappers.dart';
import '../../../core/map/basemap_mode.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Modal bottom sheet allowing citizens and operators to toggle between
/// Streets, Satellite, and Hybrid basemap imagery styles.
class BasemapSelectorSheet extends StatelessWidget {
  final BasemapMode currentMode;
  final ValueChanged<BasemapMode> onModeSelected;

  const BasemapSelectorSheet({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  /// Shows the [BasemapSelectorSheet] in a standard modal bottom sheet.
  static Future<BasemapMode?> show(
    BuildContext context, {
    required BasemapMode currentMode,
    required ValueChanged<BasemapMode> onModeSelected,
  }) {
    return showModalBottomSheet<BasemapMode>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BasemapSelectorSheet(
          currentMode: currentMode,
          onModeSelected: onModeSelected,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: CivicFixSpacing.lg,
            right: CivicFixSpacing.lg,
            top: CivicFixSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + CivicFixSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.basemapStyle ?? 'Basemap Style',
                          style: CivicFixTypography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: CivicFixColors.primaryText,
                          ),
                        ),
                        CivicFixSpacing.vSpaceXs,
                        Text(
                          l10n?.chooseMapViewMode ?? 'Choose map view and imagery mode',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: CivicFixColors.secondaryText),
                    tooltip: l10n?.close ?? 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceLg,

              // Basemap mode options
              ...BasemapMode.values.map((mode) {
                final isSelected = mode == currentMode;
                final modeLabel = localizedBasemapMode(mode, context: context, l10n: l10n);
                final modeDescription = localizedBasemapModeDescription(mode, context: context, l10n: l10n);

                return Padding(
                  padding: const EdgeInsets.only(bottom: CivicFixSpacing.md),
                  child: Material(
                    color: isSelected
                        ? CivicFixColors.primary.withValues(alpha: 0.08)
                        : CivicFixColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        onModeSelected(mode);
                        Navigator.of(context).pop(mode);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(CivicFixSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? CivicFixColors.primary : CivicFixColors.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? CivicFixColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: CivicFixColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                mode.icon,
                                color: isSelected ? Colors.white : CivicFixColors.primary,
                                size: 24,
                              ),
                            ),
                            CivicFixSpacing.hSpaceMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    modeLabel,
                                    style: CivicFixTypography.bodySmallMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? CivicFixColors.primary : CivicFixColors.primaryText,
                                    ),
                                  ),
                                  CivicFixSpacing.vSpaceXs,
                                  Text(
                                    modeDescription,
                                    style: CivicFixTypography.caption.copyWith(
                                      color: CivicFixColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: CivicFixColors.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
