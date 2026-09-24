import 'package:maplibre_gl/maplibre_gl.dart';

/// Centralized geographic constants for Mumbai basemap rendering and navigation.
class MapConstants {
  MapConstants._();

  /// Default Mumbai geographical center latitude.
  static const double mumbaiLatitude = 19.0760;

  /// Default Mumbai geographical center longitude.
  static const double mumbaiLongitude = 72.8777;

  /// Default Mumbai geographical center as a MapLibre [LatLng].
  static const LatLng mumbaiCenter = LatLng(mumbaiLatitude, mumbaiLongitude);

  /// Initial zoom level providing a clear overview of Mumbai and its neighborhoods.
  static const double defaultInitialZoom = 11.5;

  /// Minimum zoom level preventing excessive zoom out.
  static const double minZoom = 4.0;

  /// Maximum zoom level allowing detailed street-level inspection.
  static const double maxZoom = 18.0;

  /// Default zoom level when focusing on a specific hazard marker or user GPS position.
  static const double focusedZoom = 15.0;

  /// Mumbai Metropolitan Region (MMR) bounding coordinates for spatial boundaries.
  static const double mmrSouthLat = 18.8800;
  static const double mmrNorthLat = 19.3200;
  static const double mmrWestLng = 72.7500;
  static const double mmrEastLng = 73.0800;

  /// Default MapTiler style preset for civic infrastructure inspection.
  static const String defaultStyle = 'streets-v2';

  /// Stable GeoJSON source identifier for CivicFix spatial datasets.
  static const String spatialSourceId = 'civicfix-spatial-points';

  /// Layer identifier for individual unclustered civic point markers.
  static const String unclusteredPointsLayerId = 'civicfix-unclustered-points';

  /// Layer identifier for clustered civic spatial circles.
  static const String clusterPointsLayerId = 'civicfix-clustered-points';

  /// Layer identifier for cluster count text labels.
  static const String clusterCountLayerId = 'civicfix-cluster-count';

  /// Layer identifier reserved for future spatial heatmap layer.
  static const String heatmapLayerId = 'civicfix-heatmap-layer';
}
