import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Interactive Department x Ward Matrix cross-tabulation grid for Zonal DMC.
/// Enables switching views between Volume, SLA Compliance %, and Critical Grievances.
class ZoneDepartmentWardMatrixSection extends StatefulWidget {
  final DepartmentWardMatrixData? matrixData;
  final bool isLoading;

  const ZoneDepartmentWardMatrixSection({
    super.key,
    this.matrixData,
    this.isLoading = false,
  });

  @override
  State<ZoneDepartmentWardMatrixSection> createState() => _ZoneDepartmentWardMatrixSectionState();
}

class _ZoneDepartmentWardMatrixSectionState extends State<ZoneDepartmentWardMatrixSection> {
  DepartmentWardMatrixMode _selectedMode = DepartmentWardMatrixMode.volume;

  @override
  Widget build(BuildContext context) {
    final data = widget.matrixData;

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
          // Header & Mode Switcher
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_on_rounded, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT × WARD OPERATIONAL MATRIX',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Cross-sectional analysis across 18 departments and all ${data?.wards.length ?? 0} zone wards',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceMd,

          // Mode Toggle Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DepartmentWardMatrixMode.values.map((mode) {
                final isSelected = _selectedMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(mode.displayName),
                    selected: isSelected,
                    selectedColor: GovtThemeTokens.primary,
                    backgroundColor: GovtThemeTokens.surfaceMuted,
                    labelStyle: CivicFixTypography.captionMedium.copyWith(
                      color: isSelected ? Colors.white : GovtThemeTokens.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMode = mode);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (data == null || data.departments.isEmpty || data.wards.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Text(
                  'No matrix data available for this zone.',
                  style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                ),
              ),
            )
          else
            _buildMatrixGrid(context, data),
        ],
      ),
    );
  }

  Widget _buildMatrixGrid(BuildContext context, DepartmentWardMatrixData data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: GovtThemeTokens.borderLight,
          width: 1,
          borderRadius: BorderRadius.circular(4),
        ),
        children: [
          // 1. Header Row (Ward Names)
          TableRow(
            decoration: const BoxDecoration(color: GovtThemeTokens.surfaceMuted),
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                constraints: const BoxConstraints(minWidth: 200),
                child: Text(
                  'TECHNICAL DEPARTMENT',
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: GovtThemeTokens.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...data.wards.map(
                (w) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minWidth: 110),
                  child: Column(
                    children: [
                      Text(
                        'Ward ${w.wardCode}',
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.primaryDark,
                        ),
                      ),
                      Text(
                        w.wardName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.caption.copyWith(
                          fontSize: 9,
                          color: GovtThemeTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Department Rows
          ...data.departments.map((dept) {
            return TableRow(
              children: [
                // Department Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept.displayName,
                        style: CivicFixTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      Text(
                        dept.departmentCode,
                        style: CivicFixTypography.caption.copyWith(
                          fontSize: 10,
                          color: GovtThemeTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cells per ward
                ...data.wards.map((ward) {
                  final cell = data.getCell(dept.departmentId, ward.wardId);
                  return _buildMatrixCell(cell);
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatrixCell(DepartmentWardMatrixCell? cell) {
    if (cell == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        child: const Text('-', style: TextStyle(color: GovtThemeTokens.textMuted)),
      );
    }

    String displayText = '';
    Color textColor = GovtThemeTokens.textPrimary;
    Color cellBgColor = Colors.transparent;

    switch (_selectedMode) {
      case DepartmentWardMatrixMode.volume:
        displayText = '${cell.openCount} / ${cell.totalCount}';
        if (cell.openCount > 5) {
          cellBgColor = GovtThemeTokens.primary.withValues(alpha: 0.12);
          textColor = GovtThemeTokens.primaryDark;
        } else if (cell.openCount > 0) {
          cellBgColor = GovtThemeTokens.primary.withValues(alpha: 0.05);
        }
        break;

      case DepartmentWardMatrixMode.slaCompliance:
        if (cell.slaComplianceRate != null) {
          displayText = '${cell.slaComplianceRate!.toStringAsFixed(0)}%';
          if (cell.slaComplianceRate! >= 80) {
            cellBgColor = GovtThemeTokens.successLight;
            textColor = GovtThemeTokens.success;
          } else if (cell.slaComplianceRate! >= 70) {
            cellBgColor = GovtThemeTokens.warningLight;
            textColor = GovtThemeTokens.warning;
          } else {
            cellBgColor = GovtThemeTokens.errorLight;
            textColor = GovtThemeTokens.error;
          }
        } else {
          displayText = 'N/A';
          textColor = GovtThemeTokens.textMuted;
        }
        break;

      case DepartmentWardMatrixMode.critical:
        displayText = '${cell.criticalCount}';
        if (cell.criticalCount > 0) {
          cellBgColor = GovtThemeTokens.errorLight;
          textColor = GovtThemeTokens.error;
        } else {
          textColor = GovtThemeTokens.textMuted;
        }
        break;
    }

    return Container(
      color: cellBgColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: CivicFixTypography.captionMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
