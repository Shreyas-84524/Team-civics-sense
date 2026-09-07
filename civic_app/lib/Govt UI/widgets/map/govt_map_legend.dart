import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/models/hazard_model.dart';
import '../../theme/govt_theme_tokens.dart';

/// Clean, informative GIS legend displaying category icons, status color codes, and severity indicators.
class GovtMapLegend extends StatelessWidget {
  final VoidCallback? onClose;

  const GovtMapLegend({
    super.key,
    this.onClose,
  });

  static const List<Map<String, dynamic>> _hazardCategoryLegends = [
    {'name': 'Road Damage', 'icon': Icons.edit_road_rounded},
    {'name': 'Waterlogging', 'icon': Icons.water_drop_rounded},
    {'name': 'Open Manhole', 'icon': Icons.warning_amber_rounded},
    {'name': 'Garbage', 'icon': Icons.delete_outline_rounded},
    {'name': 'Drainage', 'icon': Icons.waves_rounded},
    {'name': 'Street Light', 'icon': Icons.lightbulb_outline_rounded},
    {'name': 'Other', 'icon': Icons.report_problem_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 16, color: GovtThemeTokens.primary),
                    CivicFixSpacing.hSpaceXs,
                    Flexible(
                      child: Text(
                        'GIS Map Legend',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close_rounded, size: 16, color: GovtThemeTokens.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.border, height: 1),
          CivicFixSpacing.vSpaceSm,

          // Categories
          Text(
            'HAZARD CATEGORIES',
            style: CivicFixTypography.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: GovtThemeTokens.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          ..._hazardCategoryLegends.map((cat) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData, size: 14, color: GovtThemeTokens.primary),
                  CivicFixSpacing.hSpaceSm,
                  Text(
                    cat['name'] as String,
                    style: CivicFixTypography.caption.copyWith(
                      fontSize: 11,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.border, height: 1),
          CivicFixSpacing.vSpaceSm,

          // Status Lifecycle
          Text(
            'LIFECYCLE STATUS',
            style: CivicFixTypography.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: GovtThemeTokens.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          ...ComplaintStatus.values.where((s) => s != ComplaintStatus.rejected).map((status) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
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
                  Text(
                    status.label,
                    style: CivicFixTypography.caption.copyWith(
                      fontSize: 11,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.border, height: 1),
          CivicFixSpacing.vSpaceSm,

          // Severity tags
          Text(
            'PRIORITY SEVERITY',
            style: CivicFixTypography.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: GovtThemeTokens.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Wrap(
            spacing: CivicFixSpacing.xs,
            runSpacing: CivicFixSpacing.xs,
            children: [
              _buildSeverityBadge('P1 Critical', HazardSeverity.critical.color),
              _buildSeverityBadge('P2 High', HazardSeverity.high.color),
              _buildSeverityBadge('P3 Med', HazardSeverity.medium.color),
              _buildSeverityBadge('P4 Low', HazardSeverity.low.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
