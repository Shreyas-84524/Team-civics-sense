import 'package:flutter/material.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../../core/location/location_model.dart';
import '../../../core/map/civic_map_canvas.dart';
import '../../../core/map/map_constants.dart';
import '../../../core/models/hazard_model.dart';
import 'govt_hazard_marker.dart';

/// Government GIS Map Canvas providing real MapTiler vector basemaps via MapLibre,
/// supporting Mumbai municipal administrative boundaries, pan, zoom, and hazard markers.
class GovtMapCanvas extends StatelessWidget {
  final List<HazardModel> hazards;
  final HazardModel? selectedHazard;
  final ValueChanged<HazardModel> onHazardSelected;
  final TransformationController transformationController;
  final CivicLocation? userLocation;
  final VoidCallback? onMapTap;
  final GlobalKey<CivicMapCanvasState>? mapCanvasKey;

  const GovtMapCanvas({
    super.key,
    required this.hazards,
    this.selectedHazard,
    required this.onHazardSelected,
    required this.transformationController,
    this.userLocation,
    this.onMapTap,
    this.mapCanvasKey,
  });

  /// Reference Mumbai municipal GIS center coordinates.
  static const double centerLat = MapConstants.mumbaiLatitude;
  static const double centerLng = MapConstants.mumbaiLongitude;

  @override
  Widget build(BuildContext context) {
    return CivicMapCanvas(
      key: mapCanvasKey,
      hazards: hazards,
      selectedHazard: selectedHazard,
      onHazardSelected: onHazardSelected,
      userLocation: userLocation,
      onMapTap: onMapTap,
      transformationController: transformationController,
      initialLatitude: centerLat,
      initialLongitude: centerLng,
      initialZoom: MapConstants.defaultInitialZoom,
      markerBuilder: (hazard, isSelected, onTap) {
        return GovtHazardMarker(
          hazard: hazard,
          isSelected: isSelected,
          onTap: onTap,
        );
      },
      userLocationBuilder: (loc) => _buildGovtUserLocationMarker(loc),
    );
  }

  Widget _buildGovtUserLocationMarker(CivicLocation loc) {
    return Semantics(
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GovtThemeTokens.info,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
