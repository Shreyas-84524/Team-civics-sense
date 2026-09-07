import 'package:flutter/material.dart';
import '../../../core/location/location_model.dart';
import '../../../core/models/hazard_model.dart';
import '../../theme/govt_theme_tokens.dart';
import 'govt_hazard_marker.dart';

/// Interactive GIS Vector Map Canvas with custom coordinate translation and hazard marker placement.
class GovtMapCanvas extends StatelessWidget {
  final List<HazardModel> hazards;
  final HazardModel? selectedHazard;
  final ValueChanged<HazardModel> onHazardSelected;
  final TransformationController transformationController;
  final CivicLocation? userLocation;
  final VoidCallback? onMapTap;

  const GovtMapCanvas({
    super.key,
    required this.hazards,
    this.selectedHazard,
    required this.onHazardSelected,
    required this.transformationController,
    this.userLocation,
    this.onMapTap,
  });

  // Reference GIS center coordinate (Bengaluru Central Ward 14 reference)
  static const double centerLat = 12.9730;
  static const double centerLng = 77.5960;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 800,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 600,
        );

        return GestureDetector(
          onTap: onMapTap,
          child: Container(
            color: const Color(0xFFE5ECE8),
            child: InteractiveViewer(
              transformationController: transformationController,
              boundaryMargin: const EdgeInsets.all(400),
              minScale: 0.5,
              maxScale: 3.0,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base GIS Vector Topography Painter
                    Positioned.fill(
                      child: CustomPaint(
                        size: size,
                        painter: _GovtGisMapPainter(),
                      ),
                    ),

                    // User GPS Position Marker (if located)
                    if (userLocation != null)
                      _buildUserLocationMarker(size, userLocation!),

                    // Render Hazard Markers
                    ...hazards.map((hazard) {
                      final latDiff = hazard.latitude - centerLat;
                      final lngDiff = hazard.longitude - centerLng;

                      final double markerX = (size.width / 2) + (lngDiff * 18000);
                      final double markerY = (size.height / 2) - (latDiff * 18000);

                      final clampedX = markerX.clamp(20.0, (size.width - 60.0).clamp(20.0, double.infinity));
                      final clampedY = markerY.clamp(20.0, (size.height - 60.0).clamp(20.0, double.infinity));

                      final isSelected = selectedHazard?.id == hazard.id;

                      return Positioned(
                        left: clampedX,
                        top: clampedY,
                        child: GovtHazardMarker(
                          hazard: hazard,
                          isSelected: isSelected,
                          onTap: () => onHazardSelected(hazard),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserLocationMarker(Size size, CivicLocation loc) {
    final latDiff = loc.latitude - centerLat;
    final lngDiff = loc.longitude - centerLng;
    final double markerX = (size.width / 2) + (lngDiff * 18000);
    final double markerY = (size.height / 2) - (latDiff * 18000);
    final clampedX = markerX.clamp(20.0, (size.width - 40.0).clamp(20.0, double.infinity));
    final clampedY = markerY.clamp(20.0, (size.height - 40.0).clamp(20.0, double.infinity));

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: Semantics(
        label: 'Your Current Government Inspection Location',
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GovtThemeTokens.info.withValues(alpha: 0.2),
                ),
              ),
              // White border circle
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              // Blue center dot
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: GovtThemeTokens.info,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Vector Painter rendering municipal ward zones, arterial roads, water channels, and parks.
class _GovtGisMapPainter extends CustomPainter {
  const _GovtGisMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Grid & Land Parcels
    final gridPaint = Paint()
      ..color = const Color(0xFFD6E2DB)
      ..strokeWidth = 1.0;

    const double step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Municipal Parks & Green Belts
    final greenPaint = Paint()
      ..color = const Color(0xFFCDE2D3)
      ..style = PaintingStyle.fill;

    // Central Botanical Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.45, size.height * 0.42, size.width * 0.25, size.height * 0.2),
        const Radius.circular(20),
      ),
      greenPaint,
    );

    // North Sector Green Space
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.15, size.width * 0.25, size.height * 0.18),
        const Radius.circular(16),
      ),
      greenPaint,
    );

    // 3. Water Canal / River Feature
    final waterPaint = Paint()
      ..color = const Color(0xFFBDDCE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.35, size.height * 0.68,
        size.width * 0.65, size.height * 0.85,
        size.width, size.height * 0.76,
      );
    canvas.drawPath(riverPath, waterPaint);

    // 4. Secondary Residential Streets
    final streetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square;

    // Horizontal residential streets
    for (double y = 100; y < size.height; y += 120) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }
    // Vertical cross streets
    for (double x = 120; x < size.width; x += 140) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
    }

    // 5. Major Arterial Highways
    final arterialPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Main East-West Expressway
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      arterialPaint,
    );

    // Main North-South Corridor
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      arterialPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
