import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../constants/app_colors.dart';
import '../location/location_model.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import 'geo_projection.dart';
import 'map_config.dart';
import 'map_constants.dart';
import 'spatial_data_service.dart';

/// Reusable civic map canvas integrating real MapTiler vector basemaps via MapLibre,
/// supporting real geographic coordinate projection, GeoJSON sources, interactive markers, and GPS location.
class CivicMapCanvas extends StatefulWidget {
  final List<HazardModel> hazards;
  final List<ComplaintModel>? complaints;
  final HazardModel? selectedHazard;
  final ValueChanged<HazardModel>? onHazardSelected;
  final CivicLocation? userLocation;
  final VoidCallback? onMapTap;
  final Widget Function(HazardModel hazard, bool isSelected, VoidCallback onTap)? markerBuilder;
  final Widget Function(CivicLocation location)? userLocationBuilder;
  final void Function(MapLibreMapController controller)? onMapCreated;
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final TransformationController? transformationController;
  final SpatialDataService spatialDataService;
  final bool enableClustering;
  final bool showHeatmap;
  final bool showPointsLayer;
  final SpatialTimeFilter? timeFilter;

  const CivicMapCanvas({
    super.key,
    this.hazards = const [],
    this.complaints,
    this.selectedHazard,
    this.onHazardSelected,
    this.userLocation,
    this.onMapTap,
    this.markerBuilder,
    this.userLocationBuilder,
    this.onMapCreated,
    this.initialLatitude = MapConstants.mumbaiLatitude,
    this.initialLongitude = MapConstants.mumbaiLongitude,
    this.initialZoom = MapConstants.defaultInitialZoom,
    this.transformationController,
    this.spatialDataService = const SpatialDataService(),
    this.enableClustering = true,
    this.showHeatmap = true,
    this.showPointsLayer = true,
    this.timeFilter,
  });

  @override
  State<CivicMapCanvas> createState() => CivicMapCanvasState();
}

class CivicMapCanvasState extends State<CivicMapCanvas> {
  MapLibreMapController? _mapController;
  late double _currentLat;
  late double _currentLng;
  late double _currentZoom;
  bool _hasAddedSpatialSource = false;
  bool _hasRegisteredLayers = false;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLatitude;
    _currentLng = widget.initialLongitude;
    _currentZoom = widget.initialZoom;

    widget.transformationController?.addListener(_handleTransformChanged);
  }

  @override
  void didUpdateWidget(covariant CivicMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController?.removeListener(_handleTransformChanged);
      widget.transformationController?.addListener(_handleTransformChanged);
    }
    if (oldWidget.hazards != widget.hazards ||
        oldWidget.complaints != widget.complaints ||
        oldWidget.timeFilter != widget.timeFilter ||
        oldWidget.showHeatmap != widget.showHeatmap) {
      syncSpatialGeoJsonSource();
    }
  }

  /// Synchronizes the current complaints/hazards spatial dataset with MapLibre's GeoJSON source.
  Future<void> syncSpatialGeoJsonSource() async {
    if (_mapController == null) return;

    final geoJson = currentGeoJson;

    try {
      if (_hasAddedSpatialSource) {
        await _mapController!.setGeoJsonSource(MapConstants.spatialSourceId, geoJson);
      } else {
        await _mapController!.addSource(
          MapConstants.spatialSourceId,
          GeojsonSourceProperties(
            data: geoJson,
            cluster: widget.enableClustering,
            clusterMaxZoom: 14,
            clusterRadius: 50,
          ),
        );
        _hasAddedSpatialSource = true;
      }

      if (_hasAddedSpatialSource && !_hasRegisteredLayers) {
        await _registerSpatialLayers();
      }
    } catch (e) {
      debugPrint('[CivicMapCanvas] GeoJSON spatial sync note: $e');
    }
  }

  /// Registers GPU-accelerated heatmap, cluster, and point layers on the active MapLibre source.
  Future<void> _registerSpatialLayers() async {
    if (_mapController == null || _hasRegisteredLayers) return;

    try {
      // 1. Native Heatmap Density Layer
      if (widget.showHeatmap) {
        await _mapController!.addHeatmapLayer(
          MapConstants.spatialSourceId,
          MapConstants.heatmapLayerId,
          const HeatmapLayerProperties(
            heatmapWeight: 1.0,
            heatmapIntensity: [
              'interpolate',
              ['linear'],
              ['zoom'],
              0,
              1.0,
              9,
              1.5,
              15,
              3.0,
            ],
            heatmapColor: [
              'interpolate',
              ['linear'],
              ['heatmap-density'],
              0,
              'rgba(0, 0, 0, 0)',
              0.2,
              'rgba(37, 99, 235, 0.5)',
              0.4,
              'rgba(16, 185, 129, 0.7)',
              0.7,
              'rgba(245, 158, 11, 0.85)',
              1.0,
              'rgba(239, 68, 68, 0.95)',
            ],
            heatmapRadius: [
              'interpolate',
              ['linear'],
              ['zoom'],
              0,
              4,
              9,
              16,
              14,
              28,
              18,
              45,
            ],
            heatmapOpacity: [
              'interpolate',
              ['linear'],
              ['zoom'],
              7,
              0.85,
              13,
              0.75,
              16,
              0.35,
              18,
              0.1,
            ],
          ),
          maxzoom: 18.0,
        );
      }

      // 2. Clustered Points Layer (grouped circle badges)
      if (widget.enableClustering) {
        await _mapController!.addCircleLayer(
          MapConstants.spatialSourceId,
          MapConstants.clusterPointsLayerId,
          const CircleLayerProperties(
            circleColor: [
              'step',
              ['get', 'point_count'],
              '#38BDF8',
              10,
              '#F59E0B',
              30,
              '#EF4444',
            ],
            circleRadius: [
              'step',
              ['get', 'point_count'],
              16,
              10,
              22,
              30,
              28,
            ],
            circleOpacity: 0.85,
            circleStrokeWidth: 2.0,
            circleStrokeColor: '#FFFFFF',
          ),
          filter: ['has', 'point_count'],
          maxzoom: 14.5,
        );

        // 3. Cluster Count Text Label Layer
        await _mapController!.addSymbolLayer(
          MapConstants.spatialSourceId,
          MapConstants.clusterCountLayerId,
          const SymbolLayerProperties(
            textField: '{point_count_abbreviated}',
            textSize: 12,
            textColor: '#FFFFFF',
          ),
          filter: ['has', 'point_count'],
          maxzoom: 14.5,
        );
      }

      // 4. Unclustered Point Markers (detailed street zoom)
      if (widget.showPointsLayer) {
        await _mapController!.addCircleLayer(
          MapConstants.spatialSourceId,
          MapConstants.unclusteredPointsLayerId,
          const CircleLayerProperties(
            circleColor: [
              'match',
              ['get', 'severity'],
              'critical',
              '#DC2626',
              'high',
              '#EA580C',
              'medium',
              '#D97706',
              'low',
              '#2563EB',
              '#2563EB',
            ],
            circleRadius: 6.0,
            circleOpacity: 0.9,
            circleStrokeWidth: 1.5,
            circleStrokeColor: '#FFFFFF',
          ),
          filter: [
            '!',
            ['has', 'point_count'],
          ],
          minzoom: 12.0,
        );
      }

      _hasRegisteredLayers = true;
    } catch (e) {
      debugPrint('[CivicMapCanvas] Layer registration note: $e');
    }
  }

  /// Returns the active GeoJSON FeatureCollection dictionary representing visible spatial features.
  Map<String, dynamic> get currentGeoJson => widget.spatialDataService.buildFeatureCollection(
        complaints: widget.complaints,
        hazards: widget.hazards,
        timeFilter: widget.timeFilter,
      );

  @override
  void dispose() {
    widget.transformationController?.removeListener(_handleTransformChanged);
    super.dispose();
  }

  void _handleTransformChanged() {
    if (widget.transformationController == null) return;
    final matrix = widget.transformationController!.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    // Calculate approximate zoom delta from transformation matrix scale
    final zoomDelta = (scale > 0) ? (scale - 1.0) * 1.5 : 0.0;
    final newZoom = (widget.initialZoom + zoomDelta).clamp(MapConstants.minZoom, MapConstants.maxZoom);

    // Approximate pan translation in meters/degrees
    final centerOffset = Offset(translation.x, translation.y);
    if (mounted) {
      setState(() {
        _currentZoom = newZoom;
        // Shift center slightly with pan if matrix translation is active
        if (centerOffset.distance > 5) {
          _currentLng = widget.initialLongitude - (translation.x / (256.0 * (1 << newZoom.toInt()))) * 360.0;
        }
      });
    }
  }

  /// Programmatically animates the map camera to a target coordinate and zoom.
  Future<void> animateTo({
    required double latitude,
    required double longitude,
    double? zoom,
  }) async {
    final targetZoom = zoom ?? _currentZoom;
    setState(() {
      _currentLat = latitude;
      _currentLng = longitude;
      _currentZoom = targetZoom;
    });

    if (_mapController != null) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(latitude, longitude),
            targetZoom,
          ),
        );
      } catch (e) {
        debugPrint('[CivicMapCanvas] Camera animation notice: $e');
      }
    }
  }

  /// Programmatically zooms in by 1 zoom level.
  Future<void> zoomIn() async {
    final nextZoom = (_currentZoom + 1.0).clamp(MapConstants.minZoom, MapConstants.maxZoom);
    setState(() => _currentZoom = nextZoom);
    if (_mapController != null) {
      try {
        await _mapController!.animateCamera(CameraUpdate.zoomIn());
      } catch (_) {}
    }
  }

  /// Programmatically zooms out by 1 zoom level.
  Future<void> zoomOut() async {
    final nextZoom = (_currentZoom - 1.0).clamp(MapConstants.minZoom, MapConstants.maxZoom);
    setState(() => _currentZoom = nextZoom);
    if (_mapController != null) {
      try {
        await _mapController!.animateCamera(CameraUpdate.zoomOut());
      } catch (_) {}
    }
  }

  /// Recenter the map on Mumbai central coordinates.
  Future<void> recenterMumbai() async {
    await animateTo(
      latitude: MapConstants.mumbaiLatitude,
      longitude: MapConstants.mumbaiLongitude,
      zoom: MapConstants.defaultInitialZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 800,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 600,
        );

        final isConfigured = MapConfig.isConfigured;
        final styleUrl = MapConfig.getStyleUrl();

        return GestureDetector(
          onTap: widget.onMapTap,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Basemap Layer: Real MapLibreMap when configured and available
              if (isConfigured && styleUrl != null)
                _buildMapLibreView(styleUrl)
              else
                _buildFallbackBasemap(size),

              // 2. User GPS Location Marker (if located)
              if (widget.userLocation != null)
                _buildUserLocationMarker(size, widget.userLocation!),

              // 3. Geotagged Civic Hazard Markers
              ...widget.hazards.map((hazard) {
                return _buildHazardMarker(size, hazard);
              }),

              // 4. Missing API Key Developer Notification Banner (if not configured)
              if (!isConfigured)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: _buildDevNoticeBanner(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapLibreView(String styleUrl) {
    return MapLibreMap(
      key: const ValueKey('civic_maplibre_basemap'),
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentLat, _currentLng),
        zoom: _currentZoom,
      ),
      styleString: styleUrl,
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      onStyleLoadedCallback: () {
        syncSpatialGeoJsonSource();
      },
      onCameraMove: (position) {
        if (mounted) {
          setState(() {
            _currentLat = position.target.latitude;
            _currentLng = position.target.longitude;
            _currentZoom = position.zoom;
          });
        }
      },
      onMapClick: (_, point) {
        widget.onMapTap?.call();
      },
      trackCameraPosition: true,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      myLocationEnabled: false,
      minMaxZoomPreference: const MinMaxZoomPreference(
        MapConstants.minZoom,
        MapConstants.maxZoom,
      ),
    );
  }

  Widget _buildFallbackBasemap(Size size) {
    return Container(
      color: const Color(0xFFE8ECE9),
      child: CustomPaint(
        size: size,
        painter: _MumbaiBasemapPainter(
          hazards: widget.hazards,
          centerLat: _currentLat,
          centerLng: _currentLng,
          zoom: _currentZoom,
          showHeatmap: widget.showHeatmap,
        ),
      ),
    );
  }

  Widget _buildDevNoticeBanner() {
    return Semantics(
      label: 'Map configuration notice',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'MapTiler vector basemap active (pass --dart-define=MAPTILER_API_KEY=key for live tiles)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardMarker(Size size, HazardModel hazard) {
    final screenOffset = GeoProjection.latLngToScreenOffset(
      latitude: hazard.latitude,
      longitude: hazard.longitude,
      centerLatitude: _currentLat,
      centerLongitude: _currentLng,
      zoom: _currentZoom,
      screenSize: size,
    );

    // Keep marker comfortably visible and safely away from top search bar and bottom-right floating controls
    final clampedX = screenOffset.dx.clamp(120.0, (size.width - 160.0).clamp(120.0, double.infinity));
    final clampedY = screenOffset.dy.clamp(100.0, (size.height - 180.0).clamp(100.0, double.infinity));

    final isOffscreen = (screenOffset.dx - clampedX).abs() > 1.0 || (screenOffset.dy - clampedY).abs() > 1.0;
    final index = widget.hazards.indexOf(hazard);
    final double spreadX;
    final double spreadY;
    if (isOffscreen && index >= 0) {
      final col = index % 3;
      final row = index ~/ 3;
      spreadX = (col * 120.0) - 120.0;
      spreadY = (row * 90.0) - 80.0;
    } else {
      spreadX = 0.0;
      spreadY = 0.0;
    }

    final posX = (clampedX + spreadX).clamp(60.0, (size.width - 120.0).clamp(60.0, double.infinity));
    final posY = (clampedY + spreadY).clamp(80.0, (size.height - 160.0).clamp(80.0, double.infinity));

    final isSelected = widget.selectedHazard?.id == hazard.id;

    if (widget.markerBuilder != null) {
      return Positioned(
        left: posX,
        top: posY,
        child: widget.markerBuilder!(
          hazard,
          isSelected,
          () => widget.onHazardSelected?.call(hazard),
        ),
      );
    }

    return Positioned(
      left: posX,
      top: posY,
      child: _DefaultHazardMarker(
        hazard: hazard,
        isSelected: isSelected,
        onTap: () => widget.onHazardSelected?.call(hazard),
      ),
    );
  }

  Widget _buildUserLocationMarker(Size size, CivicLocation loc) {
    final screenOffset = GeoProjection.latLngToScreenOffset(
      latitude: loc.latitude,
      longitude: loc.longitude,
      centerLatitude: _currentLat,
      centerLongitude: _currentLng,
      zoom: _currentZoom,
      screenSize: size,
    );

    final clampedX = screenOffset.dx.clamp(20.0, (size.width - 40.0).clamp(20.0, double.infinity));
    final clampedY = screenOffset.dy.clamp(20.0, (size.height - 40.0).clamp(20.0, double.infinity));

    if (widget.userLocationBuilder != null) {
      return Positioned(
        left: clampedX,
        top: clampedY,
        child: widget.userLocationBuilder!(loc),
      );
    }

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: Semantics(
        label: 'Your Current GPS Location',
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CivicFixColors.info.withValues(alpha: 0.25),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CivicFixColors.info,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback standard marker when no custom builder is supplied.
class _DefaultHazardMarker extends StatelessWidget {
  final HazardModel hazard;
  final bool isSelected;
  final VoidCallback onTap;

  const _DefaultHazardMarker({
    required this.hazard,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? hazard.statusColor : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: hazard.statusColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          hazard.categoryIcon,
          size: 18,
          color: isSelected ? Colors.white : hazard.statusColor,
        ),
      ),
    );
  }
}

/// Geometric basemap painter for Mumbai geographic orientation during offline/testing fallback.
class _MumbaiBasemapPainter extends CustomPainter {
  final List<HazardModel> hazards;
  final double centerLat;
  final double centerLng;
  final double zoom;
  final bool showHeatmap;

  _MumbaiBasemapPainter({
    this.hazards = const [],
    this.centerLat = MapConstants.mumbaiLatitude,
    this.centerLng = MapConstants.mumbaiLongitude,
    this.zoom = MapConstants.defaultInitialZoom,
    this.showHeatmap = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Arabian Sea / Coastline / Thane Creek Waterways
    final waterPaint = Paint()
      ..color = const Color(0xFFCCE2EE)
      ..style = PaintingStyle.fill;

    // Western Arabian Sea Coast
    final westCoast = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.22, 0)
      ..cubicTo(
        size.width * 0.18, size.height * 0.35,
        size.width * 0.26, size.height * 0.65,
        size.width * 0.12, size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(westCoast, waterPaint);

    // Eastern Thane Creek / Mumbai Harbour
    final eastCreek = Path()
      ..moveTo(size.width * 0.78, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.85, size.height)
      ..cubicTo(
        size.width * 0.72, size.height * 0.7,
        size.width * 0.82, size.height * 0.3,
        size.width * 0.78, 0,
      )
      ..close();
    canvas.drawPath(eastCreek, waterPaint);

    // 2. Sanjay Gandhi National Park / Aarey Greenery (North Mumbai)
    final greenPaint = Paint()
      ..color = const Color(0xFFD4E8D8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.42, size.height * 0.12, size.width * 0.26, size.height * 0.22),
        const Radius.circular(20),
      ),
      greenPaint,
    );

    // 3. Arterial Highways (Western & Eastern Express Highways)
    final wehPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final eehPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Western Express Highway
    final wehPath = Path()
      ..moveTo(size.width * 0.34, 0)
      ..cubicTo(
        size.width * 0.35, size.height * 0.4,
        size.width * 0.38, size.height * 0.7,
        size.width * 0.25, size.height,
      );
    canvas.drawPath(wehPath, wehPaint);

    // Eastern Express Highway
    final eehPath = Path()
      ..moveTo(size.width * 0.65, 0)
      ..cubicTo(
        size.width * 0.62, size.height * 0.4,
        size.width * 0.58, size.height * 0.7,
        size.width * 0.32, size.height,
      );
    canvas.drawPath(eehPath, eehPaint);

    // 4. Bandra-Worli Sea Link & Coastal Road
    final seaLinkPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final seaLink = Path()
      ..moveTo(size.width * 0.28, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.20, size.height * 0.72,
        size.width * 0.26, size.height * 0.82,
      );
    canvas.drawPath(seaLink, seaLinkPaint);

    // 5. Fallback Soft Heatmap Density Halos (when showHeatmap is enabled in offline/test fallback)
    if (showHeatmap && hazards.isNotEmpty) {
      for (final h in hazards) {
        final screenOffset = GeoProjection.latLngToScreenOffset(
          latitude: h.latitude,
          longitude: h.longitude,
          centerLatitude: centerLat,
          centerLongitude: centerLng,
          zoom: zoom,
          screenSize: size,
        );

        if (screenOffset.dx >= -50 &&
            screenOffset.dx <= size.width + 50 &&
            screenOffset.dy >= -50 &&
            screenOffset.dy <= size.height + 50) {
          final haloRadius = (35.0 + (zoom - 10) * 4).clamp(20.0, 70.0);
          final haloPaint = Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xFFEF4444).withValues(alpha: 0.35),
                const Color(0xFFF59E0B).withValues(alpha: 0.20),
                const Color(0xFF10B981).withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 0.75, 1.0],
            ).createShader(Rect.fromCircle(center: screenOffset, radius: haloRadius));

          canvas.drawCircle(screenOffset, haloRadius, haloPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MumbaiBasemapPainter oldDelegate) {
    return oldDelegate.hazards != hazards ||
        oldDelegate.centerLat != centerLat ||
        oldDelegate.centerLng != centerLng ||
        oldDelegate.zoom != zoom ||
        oldDelegate.showHeatmap != showHeatmap;
  }
}



