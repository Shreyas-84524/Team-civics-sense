import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Interactive Map Preview Panel for Government Dashboard and Hazard Screen.
class GovtMapPanel extends StatelessWidget {
  final String title;
  final int activeHazardsCount;
  final VoidCallback? onOpenFullMap;
  final Widget? overlayControls;

  const GovtMapPanel({
    super.key,
    this.title = 'Municipal Hazard GIS View',
    this.activeHazardsCount = 7,
    this.onOpenFullMap,
    this.overlayControls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFFE5ECE8),
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: GovtThemeTokens.cardRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Map Grid Background Pattern Mock
            CustomPaint(
              painter: _MapGridPainter(),
            ),

            // Dynamic Hazard Status Overlay or Empty State
            if (activeHazardsCount == 0)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicFixSpacing.lg,
                    vertical: CivicFixSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surface.withValues(alpha: 0.95),
                    borderRadius: GovtThemeTokens.cardRadius,
                    border: Border.all(color: GovtThemeTokens.border),
                    boxShadow: GovtThemeTokens.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: GovtThemeTokens.secondary, size: 36),
                      CivicFixSpacing.vSpaceSm,
                      Text(
                        'No Active Civic Hazards',
                        style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'No critical geographic hazards reported in this area.',
                        style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicFixSpacing.lg,
                    vertical: CivicFixSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surface.withValues(alpha: 0.95),
                    borderRadius: GovtThemeTokens.cardRadius,
                    border: Border.all(color: GovtThemeTokens.border),
                    boxShadow: GovtThemeTokens.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: GovtThemeTokens.error, size: 36),
                      CivicFixSpacing.vSpaceSm,
                      Text(
                        '$activeHazardsCount Critical Hazards Active',
                        style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Open live GIS map to inspect coordinates & dispatch teams.',
                        style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Status Overlay
            Positioned(
              top: CivicFixSpacing.md,
              left: CivicFixSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CivicFixSpacing.md,
                  vertical: CivicFixSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: GovtThemeTokens.chipRadius,
                  border: Border.all(color: GovtThemeTokens.border),
                  boxShadow: GovtThemeTokens.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activeHazardsCount > 0 ? GovtThemeTokens.error : GovtThemeTokens.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      activeHazardsCount > 0
                          ? '$activeHazardsCount Active Geo-Hazards'
                          : '0 Active Geo-Hazards',
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Optional Full Map Action
            if (onOpenFullMap != null)
              Positioned(
                top: CivicFixSpacing.md,
                right: CivicFixSpacing.md,
                child: ElevatedButton.icon(
                  onPressed: onOpenFullMap,
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: const Text('Open Map View', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.xs + 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: GovtThemeTokens.chipRadius,
                    ),
                  ),
                ),
              ),

            // Overlay controls (bottom)
            if (overlayControls != null)
              Positioned(
                bottom: CivicFixSpacing.md,
                left: CivicFixSpacing.md,
                right: CivicFixSpacing.md,
                child: overlayControls!,
              ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD3E0D8)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(y, 0), Offset(size.width, y), paint);
    }

    // Draw simulated road lines
    final roadPaint = Paint()
      ..color = const Color(0xFFC2D4C9)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.45, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
