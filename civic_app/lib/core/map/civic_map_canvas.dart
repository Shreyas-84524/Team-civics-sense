import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../constants/app_colors.dart';
import '../location/location_model.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import 'basemap_mode.dart';
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
  final BasemapMode basemapMode;
  final TransformationController? transformationController;
  final SpatialDataService spatialDataService;
  final bool enableClustering;
  final bool showHeatmap;
  final bool showPointsLayer;
  final SpatialTimeFilter? timeFilter;
  final ValueChanged<LatLngBounds>? onVisibleBoundsChanged;

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
    this.basemapMode = BasemapMode.streets,
    this.transformationController,
    this.spatialDataService = const SpatialDataService(),
    this.enableClustering = true,
    this.showHeatmap = true,
    this.showPointsLayer = true,
    this.timeFilter,
    this.onVisibleBoundsChanged,
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
  int _tapGeneration = 0;
  bool _hasRegisteredLayers = false;
  bool _hasAddedUserLocationSource = false;
  bool _hasRegisteredUserLocationLayers = false;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLatitude;
    _currentLng = widget.initialLongitude;
    _currentZoom = widget.initialZoom;

    widget.transformationController?.addListener(_handleTransformChanged);

    if (kDebugMode) {
      if (MapConfig.isConfigured && MapConfig.getStyleUrl(mode: widget.basemapMode) != null) {
        debugPrint('[CivicMapCanvas] MAP ENGINE = MAPLIBRE | mode = ${widget.basemapMode.label} | key = ${MapConfig.maskedKey}');
      } else {
        debugPrint('[CivicMapCanvas] MAP ENGINE = FALLBACK | key = ${MapConfig.maskedKey}');
      }
    }
  }

  @override
  void didUpdateWidget(covariant CivicMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tapGeneration++;
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController?.removeListener(_handleTransformChanged);
      widget.transformationController?.addListener(_handleTransformChanged);
    }
    if (oldWidget.basemapMode != widget.basemapMode) {
      if (kDebugMode) {
        debugPrint('[CivicMapCanvas] Switching basemap mode to: ${widget.basemapMode.label} (${widget.basemapMode.styleId})');
      }
      _hasAddedSpatialSource = false;
      _hasRegisteredLayers = false;
      _hasAddedUserLocationSource = false;
      _hasRegisteredUserLocationLayers = false;
    }
    if (oldWidget.userLocation != widget.userLocation) {
      syncUserLocationGeoJsonSource();
    }
    if (oldWidget.showHeatmap != widget.showHeatmap ||
        oldWidget.enableClustering != widget.enableClustering ||
        oldWidget.showPointsLayer != widget.showPointsLayer) {
      _rebuildLayers();
    } else if (oldWidget.hazards != widget.hazards ||
        oldWidget.complaints != widget.complaints ||
        oldWidget.timeFilter != widget.timeFilter) {
      syncSpatialGeoJsonSource();
    }
  }

  /// Re-registers spatial layers to reflect updated visibility or clustering configurations.
  Future<void> _rebuildLayers() async {
    if (_mapController == null) return;
    try {
      await _removeSpatialLayers();
      await _registerSpatialLayers();
    } catch (e) {
      debugPrint('[CivicMapCanvas] Layer rebuild notice: $e');
    }
  }

  /// Removes existing spatial layers safely from MapLibre.
  Future<void> _removeSpatialLayers() async {
    if (_mapController == null) return;
    try {
      await _mapController!.removeLayer(MapConstants.unclusteredPointsLayerId);
    } catch (_) {}
    try {
      await _mapController!.removeLayer(MapConstants.clusterCountLayerId);
    } catch (_) {}
    try {
      await _mapController!.removeLayer(MapConstants.clusterPointsLayerId);
    } catch (_) {}
    try {
      await _mapController!.removeLayer(MapConstants.heatmapLayerId);
    } catch (_) {}
    await _removeUserLocationLayers();
    _hasRegisteredLayers = false;
  }

  /// Synchronizes the current complaints/hazards spatial dataset with MapLibre's GeoJSON source.
  Future<void> syncSpatialGeoJsonSource() async {
    if (_mapController == null) return;

    final geoJson = currentGeoJson;

    try {
      if (_hasAddedSpatialSource) {
        try {
          await _mapController!.setGeoJsonSource(MapConstants.spatialSourceId, geoJson);
        } catch (_) {
          // If source was lost (e.g. style reload), reset flags and re-add source
          _hasAddedSpatialSource = false;
          _hasRegisteredLayers = false;
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
          await _registerSpatialLayers();
        }
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
          maxzoom: 15.0,
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
          maxzoom: 15.0,
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
          minzoom: 10.0,
        );
      }

      _hasRegisteredLayers = true;
    } catch (e) {
      debugPrint('[CivicMapCanvas] Layer registration note: $e');
    }
  }

  /// Generates a GeoJSON FeatureCollection representing the user's active GPS coordinate.
  Map<String, dynamic> _buildUserLocationGeoJson(CivicLocation? loc) {
    if (loc == null) {
      return {
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      };
    }
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [loc.longitude, loc.latitude],
          },
          'properties': {
            'accuracy': loc.accuracyMeters,
            'ward': loc.ward ?? '',
            'address': loc.address,
          },
        },
      ],
    };
  }

  /// Synchronizes the current user GPS location with MapLibre's native GeoJSON source.
  Future<void> syncUserLocationGeoJsonSource() async {
    if (_mapController == null) return;

    final userGeoJson = _buildUserLocationGeoJson(widget.userLocation);

    try {
      if (_hasAddedUserLocationSource) {
        try {
          await _mapController!.setGeoJsonSource(MapConstants.userLocationSourceId, userGeoJson);
        } catch (_) {
          _hasAddedUserLocationSource = false;
          _hasRegisteredUserLocationLayers = false;
          await _mapController!.addSource(
            MapConstants.userLocationSourceId,
            GeojsonSourceProperties(data: userGeoJson),
          );
          _hasAddedUserLocationSource = true;
          await _registerUserLocationLayers();
        }
      } else {
        await _mapController!.addSource(
          MapConstants.userLocationSourceId,
          GeojsonSourceProperties(data: userGeoJson),
        );
        _hasAddedUserLocationSource = true;
      }

      if (_hasAddedUserLocationSource && !_hasRegisteredUserLocationLayers) {
        await _registerUserLocationLayers();
      }
    } catch (e) {
      debugPrint('[CivicMapCanvas] User location GeoJSON sync note: $e');
    }
  }

  /// Registers GPU-accelerated circular halo and core dot layers for the user's GPS position.
  Future<void> _registerUserLocationLayers() async {
    if (_mapController == null || _hasRegisteredUserLocationLayers) return;

    try {
      // 1. User Location Accuracy Halo (outer soft blue circle)
      await _mapController!.addCircleLayer(
        MapConstants.userLocationSourceId,
        MapConstants.userLocationHaloLayerId,
        const CircleLayerProperties(
          circleColor: '#0284C7',
          circleRadius: 16.0,
          circleOpacity: 0.22,
          circleStrokeWidth: 1.0,
          circleStrokeColor: '#38BDF8',
          circleStrokeOpacity: 0.45,
        ),
      );

      // 2. User Location Core Dot (white border + blue core)
      await _mapController!.addCircleLayer(
        MapConstants.userLocationSourceId,
        MapConstants.userLocationDotLayerId,
        const CircleLayerProperties(
          circleColor: '#0284C7',
          circleRadius: 6.0,
          circleOpacity: 1.0,
          circleStrokeWidth: 2.5,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      _hasRegisteredUserLocationLayers = true;
    } catch (e) {
      debugPrint('[CivicMapCanvas] User location layer registration note: $e');
    }
  }

  /// Removes existing user location layers safely from MapLibre.
  Future<void> _removeUserLocationLayers() async {
    if (_mapController == null) return;
    try {
      await _mapController!.removeLayer(MapConstants.userLocationDotLayerId);
    } catch (_) {}
    try {
      await _mapController!.removeLayer(MapConstants.userLocationHaloLayerId);
    } catch (_) {}
    _hasRegisteredUserLocationLayers = false;
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
    if (widget.transformationController == null || MapConfig.isConfigured) return;
    final matrix = widget.transformationController!.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    // Calculate approximate zoom delta from transformation matrix scale for fallback painter only
    final zoomDelta = (scale > 0) ? (scale - 1.0) * 1.5 : 0.0;
    final newZoom = (widget.initialZoom + zoomDelta).clamp(MapConstants.minZoom, MapConstants.maxZoom);

    // Approximate pan translation in meters/degrees
    final centerOffset = Offset(translation.x, translation.y);
    if (mounted) {
      setState(() {
        _currentZoom = newZoom;
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
    final targetZoom = (zoom ?? _currentZoom).clamp(MapConstants.minZoom, MapConstants.maxZoom);
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

  /// Returns the currently visible geographical boundaries.
  Future<LatLngBounds?> getVisibleBounds() async {
    if (_mapController != null) {
      try {
        return await _mapController!.getVisibleRegion();
      } catch (e) {
        debugPrint('[CivicMapCanvas] getVisibleRegion query notice: $e');
      }
    }
    return LatLngBounds(
      southwest: LatLng(_currentLat - 0.08, _currentLng - 0.08),
      northeast: LatLng(_currentLat + 0.08, _currentLng + 0.08),
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
        final styleUrl = MapConfig.getStyleUrl(mode: widget.basemapMode);

        final allMarkers = <HazardModel>[...widget.hazards];
        if (widget.complaints != null) {
          for (final complaint in widget.complaints!) {
            final derived = HazardModel.fromComplaint(complaint);
            if (!allMarkers.any((h) => h.id == derived.id || (derived.complaintId != null && h.complaintId == derived.complaintId))) {
              allMarkers.add(derived);
            }
          }
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Basemap Layer: Real MapLibreMap when configured and available
            if (isConfigured && styleUrl != null)
              _buildMapLibreView(styleUrl, allMarkers)
            else
              _buildFallbackBasemap(size, allMarkers),

            // 2. User GPS Location Marker (if located and on-screen)
            if (widget.userLocation != null)
              _buildUserLocationMarker(size, widget.userLocation!),

            // 3. Geotagged Civic Hazard Markers:
            // - In Fallback mode: Render all visible markers as Flutter widgets.
            // - In MapLibre mode: MapLibre native GeoJSON layers render points & clusters;
            //   we render the Flutter overlay marker ONLY for the currently selected/focused hazard.
            if (!isConfigured || styleUrl == null)
              ...allMarkers.map((hazard) {
                return _buildHazardMarker(size, hazard, allMarkers);
              })
            else if (widget.selectedHazard != null)
              _buildHazardMarker(size, widget.selectedHazard!, allMarkers),
          ],
        );
      },
    );
  }

  Widget _buildMapLibreView(String styleUrl, List<HazardModel> allMarkers) {
    return MapLibreMap(
      key: const ValueKey('civic_maplibre_basemap'),
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentLat, _currentLng),
        zoom: _currentZoom,
      ),
      styleString: styleUrl,
      // Interactive circle/symbol taps must also reach our query pipeline.
      featureTapsTriggersMapClick: true,
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      onStyleLoadedCallback: () async {
        _hasAddedSpatialSource = false;
        _hasRegisteredLayers = false;
        _hasAddedUserLocationSource = false;
        _hasRegisteredUserLocationLayers = false;
        await syncSpatialGeoJsonSource();
        await syncUserLocationGeoJsonSource();
        if (_mapController != null) {
          try {
            final bounds = await _mapController!.getVisibleRegion();
            widget.onVisibleBoundsChanged?.call(bounds);
          } catch (_) {}
        }
      },
      onCameraMove: (position) {
        _currentLat = position.target.latitude;
        _currentLng = position.target.longitude;
        _currentZoom = position.zoom;
        if (kDebugMode) {
          debugPrint('[CivicMapCanvas] CAMERA MOVED | zoom = ${position.zoom.toStringAsFixed(1)} | center changed = true');
        }
      },
      onCameraIdle: () async {
        if (mounted) {
          setState(() {});
        }
        if (_mapController != null) {
          try {
            final bounds = await _mapController!.getVisibleRegion();
            widget.onVisibleBoundsChanged?.call(bounds);
          } catch (_) {}
        }
      },
      onMapClick: (point, latLng) {
        _handleMapClick(point, latLng, allMarkers);
      },
      trackCameraPosition: true,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      myLocationEnabled: false,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      minMaxZoomPreference: const MinMaxZoomPreference(
        MapConstants.minZoom,
        MapConstants.maxZoom,
      ),
    );
  }

  Future<void> _handleMapClick(math.Point<double> point, LatLng latLng, List<HazardModel> allMarkers) async {
    final generation = ++_tapGeneration;
    if (kDebugMode) debugPrint('[CivicMapCanvas] tap=$point');
    // 1. Cluster Interaction: If cluster is tapped at low/medium zoom, zoom in to expand (+2.0 zoom) without opening card
    if (_mapController != null && widget.enableClustering) {
      try {
        final clusterFeatures = await _mapController!.queryRenderedFeatures(
          math.Point<double>(point.x, point.y),
          [MapConstants.clusterPointsLayerId, MapConstants.clusterCountLayerId],
          null,
        );
        if (!mounted || generation != _tapGeneration) return;
        if (kDebugMode) {
          debugPrint('[CivicMapCanvas] layers=${[MapConstants.clusterPointsLayerId, MapConstants.clusterCountLayerId]} features=${clusterFeatures.length}');
        }
        if (clusterFeatures.isNotEmpty) {
          widget.onMapTap?.call();
          final nextZoom = (_currentZoom + 2.0).clamp(MapConstants.minZoom, MapConstants.maxZoom);
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, nextZoom),
          );
          return;
        }
      } catch (error) {
        if (kDebugMode) debugPrint('[CivicMapCanvas] cluster query failed: $error');
        return; // Never resolve a cluster to an arbitrary nearby complaint.
      }
    }

    // 2. Unclustered Point Feature Interaction via MapLibre queryRenderedFeatures
    if (_mapController != null && widget.showPointsLayer) {
      try {
        final pointFeatures = await _mapController!.queryRenderedFeatures(
          math.Point<double>(point.x, point.y),
          [MapConstants.unclusteredPointsLayerId],
          null,
        );
        if (!mounted || generation != _tapGeneration) return;
        if (kDebugMode) {
          debugPrint('[CivicMapCanvas] layers=${[MapConstants.unclusteredPointsLayerId]} features=${pointFeatures.length}');
        }
        if (pointFeatures.isNotEmpty) {
          final rawFeature = pointFeatures.first;
          String? featureId;
          String? featureType;
          if (rawFeature is Map) {
            final props = rawFeature['properties'];
            if (props is Map) {
              featureId = props['id']?.toString();
              featureType = props['type']?.toString();
              if (kDebugMode) debugPrint('[CivicMapCanvas] properties=$props');
            }
            featureId ??= rawFeature['id']?.toString();
          }

          if (featureId != null) {
            final byFeature = <String, HazardModel>{
              for (final hazard in widget.hazards) 'hazard:${hazard.id}': hazard,
              for (final complaint in widget.complaints ?? <ComplaintModel>[])
                'complaint:${complaint.id}': HazardModel.fromComplaint(complaint),
            };
            final matched = byFeature['$featureType:$featureId'];
            if (matched != null) {
              if (kDebugMode) debugPrint('[CivicMapCanvas] complaintId=${matched.complaintId} selected=${matched.id}');
              widget.onHazardSelected?.call(matched);
              return;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[CivicMapCanvas] queryRenderedFeatures unclustered point notice: $e');
        return;
      }
    }

    if (_mapController != null) {
      widget.onMapTap?.call();
      return; // Proximity selection is only for the offline painter.
    }

    // 3. Proximity Check Fallback (~40px effective touch tolerance)
    if (allMarkers.isEmpty) {
      widget.onMapTap?.call();
      return;
    }

    const double touchTolerancePx = 40.0;
    final double degreesPerPixel = 360.0 / (256.0 * math.pow(2.0, _currentZoom));
    final double touchToleranceDegrees = touchTolerancePx * degreesPerPixel;

    HazardModel? closest;
    double minDistance = double.infinity;

    for (final hazard in allMarkers) {
      final dLat = hazard.latitude - latLng.latitude;
      final dLng = hazard.longitude - latLng.longitude;
      final dist = math.sqrt(dLat * dLat + dLng * dLng);

      if (dist < minDistance && dist <= touchToleranceDegrees) {
        minDistance = dist;
        closest = hazard;
      }
    }

    if (closest != null) {
      widget.onHazardSelected?.call(closest);
    } else {
      widget.onMapTap?.call();
    }
  }

  Widget _buildFallbackBasemap(Size size, [List<HazardModel>? markers]) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final latLng = GeoProjection.screenOffsetToLatLng(
          screenOffset: details.localPosition,
          centerLatitude: _currentLat,
          centerLongitude: _currentLng,
          zoom: _currentZoom,
          screenSize: size,
        );
        _handleMapClick(
          math.Point<double>(details.localPosition.dx, details.localPosition.dy),
          latLng,
          markers ?? widget.hazards,
        );
      },
      onPanUpdate: (details) {
        final double scale = 256.0 * math.pow(2.0, _currentZoom);
        final double deltaLng = (details.delta.dx / scale) * 360.0;
        final double deltaLat = (details.delta.dy / scale) * 180.0;
        setState(() {
          _currentLng = (_currentLng - deltaLng).clamp(-180.0, 180.0);
          _currentLat = (_currentLat + deltaLat).clamp(-85.0, 85.0);
        });
      },
      child: Container(
        color: const Color(0xFFE8ECE9),
        child: CustomPaint(
          size: size,
          painter: _MumbaiBasemapPainter(
            hazards: markers ?? widget.hazards,
            centerLat: _currentLat,
            centerLng: _currentLng,
            zoom: _currentZoom,
            showHeatmap: widget.showHeatmap,
          ),
        ),
      ),
    );
  }

  Widget _buildHazardMarker(Size size, HazardModel hazard, [List<HazardModel>? markerList]) {
    final screenOffset = GeoProjection.latLngToScreenOffset(
      latitude: hazard.latitude,
      longitude: hazard.longitude,
      centerLatitude: _currentLat,
      centerLongitude: _currentLng,
      zoom: _currentZoom,
      screenSize: size,
    );

    final isConfigured = MapConfig.isConfigured && MapConfig.getStyleUrl() != null;
    final isOffscreen = screenOffset.dx < -30 ||
        screenOffset.dx > size.width + 30 ||
        screenOffset.dy < -30 ||
        screenOffset.dy > size.height + 30;

    // In MapLibre mode or default marker mode when offscreen: do not render offscreen markers
    if (isConfigured || (isOffscreen && widget.markerBuilder == null)) {
      if (isOffscreen) {
        return const SizedBox.shrink();
      }
      final posX = screenOffset.dx - 18.0;
      final posY = screenOffset.dy - 18.0;
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

    // In Fallback / Offline / Custom Marker mode:
    final double posX;
    final double posY;

    if (!isOffscreen) {
      posX = screenOffset.dx - 18.0;
      posY = screenOffset.dy - 18.0;
    } else {
      // If custom marker builder is provided with out-of-bounds mock data in fallback canvas,
      // place in safe interactive canvas area avoiding right/bottom floating action controls
      final int index = markerList != null ? markerList.indexOf(hazard) : 0;
      final safeWidth = math.max(100.0, size.width - 200.0);
      final safeHeight = math.max(100.0, size.height - 220.0);
      final staggeredX = 80.0 + ((index >= 0 ? index : 0) * 55.0) % safeWidth;
      final staggeredY = 100.0 + (((index >= 0 ? index : 0) ~/ 3) * 55.0) % safeHeight;
      posX = staggeredX;
      posY = staggeredY;
    }

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
    final isConfigured = MapConfig.isConfigured && MapConfig.getStyleUrl() != null;

    // In MapLibre mode without custom builder: MapLibre GPU layers render the visual dot.
    // We provide accessibility semantics in the Flutter tree without a drifting overlay.
    if (isConfigured && widget.userLocationBuilder == null) {
      return Semantics(
        label: 'Your Current GPS Location',
        child: const SizedBox.shrink(),
      );
    }

    final screenOffset = GeoProjection.latLngToScreenOffset(
      latitude: loc.latitude,
      longitude: loc.longitude,
      centerLatitude: _currentLat,
      centerLongitude: _currentLng,
      zoom: _currentZoom,
      screenSize: size,
    );

    final isOffscreen = screenOffset.dx < -40 ||
        screenOffset.dx > size.width + 40 ||
        screenOffset.dy < -40 ||
        screenOffset.dy > size.height + 40;

    if (isOffscreen) {
      return const SizedBox.shrink();
    }

    final double posX = screenOffset.dx - 18.0;
    final double posY = screenOffset.dy - 18.0;

    if (widget.userLocationBuilder != null) {
      return Positioned(
        left: posX,
        top: posY,
        child: widget.userLocationBuilder!(loc),
      );
    }

    return Positioned(
      left: posX,
      top: posY,
      child: IgnorePointer(
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



