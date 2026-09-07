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

            // Mock Map Pins / Clusters
            Positioned(
              left: 120,
              top: 80,
              child: _buildMapPin(
                label: 'Road Hazard (P1)',
                color: GovtThemeTokens.error,
                icon: Icons.warning_amber_rounded,
              ),
            ),
            Positioned(
              right: 140,
              top: 130,
              child: _buildMapPin(
                label: 'Water Leak',
                color: GovtThemeTokens.info,
                icon: Icons.water_drop_rounded,
              ),
            ),
            Positioned(
              left: 220,
              bottom: 100,
              child: _buildMapPin(
                label: 'Drainage Block',
                color: GovtThemeTokens.alert,
                icon: Icons.waves_rounded,
              ),
            ),
            Positioned(
              right: 80,
              bottom: 90,
              child: _buildMapPin(
                label: 'Waste Cluster',
                color: GovtThemeTokens.secondary,
                icon: Icons.delete_outline_rounded,
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
                      decoration: const BoxDecoration(
                        color: GovtThemeTokens.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      '$activeHazardsCount Active Geo-Hazards in Ward 14',
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

  Widget _buildMapPin({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: GovtThemeTokens.border),
            boxShadow: GovtThemeTokens.cardShadow,
          ),
          child: Text(
            label,
            style: CivicFixTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ],
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
