import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Lightweight, clear GIS heatmap density legend explaining spatial issue concentration.
class HeatmapLegend extends StatelessWidget {
  final VoidCallback? onClose;
  final bool isCompact;

  const HeatmapLegend({
    super.key,
    this.onClose,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : CivicFixColors.primaryText;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : CivicFixColors.secondaryText;
    final borderColor = isDark ? const Color(0xFF334155) : CivicFixColors.border;

    return Semantics(
      label: 'CivicFix Heatmap Density Legend',
      child: Container(
        width: isCompact ? 240 : 270,
        padding: const EdgeInsets.all(CivicFixSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: CivicFixRadius.cardRadius,
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      CivicFixSpacing.hSpaceXs,
                      Flexible(
                        child: Text(
                          'Issue Density Heatmap',
                          overflow: TextOverflow.ellipsis,
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
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
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: subtextColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            CivicFixSpacing.vSpaceSm,

            // Continuous Color Gradient Ramp Bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB), // Low - Blue
                    Color(0xFF10B981), // Med-Low - Emerald Green
                    Color(0xFFF59E0B), // High - Amber
                    Color(0xFFEF4444), // Critical - Vivid Red
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
            CivicFixSpacing.vSpaceXs,

            // Density Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: subtextColor,
                  ),
                ),
                Text(
                  'MEDIUM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: subtextColor,
                  ),
                ),
                Text(
                  'HIGH',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
            CivicFixSpacing.vSpaceSm,

            // Explanatory Subtitle
            Text(
              'Higher intensity represents higher density of reported civic complaints & hazards.',
              style: TextStyle(
                fontSize: 10,
                color: subtextColor,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
