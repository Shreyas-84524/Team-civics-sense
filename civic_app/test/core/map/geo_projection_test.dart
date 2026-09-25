import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/map/geo_projection.dart';
import 'package:civic_app/core/map/map_constants.dart';

void main() {
  group('GeoProjection Unit Tests', () {
    const size = Size(800, 600);
    const centerLat = MapConstants.mumbaiLatitude;
    const centerLng = MapConstants.mumbaiLongitude;
    const zoom = MapConstants.defaultInitialZoom;

    test('Center coordinates project exactly to screen center', () {
      final offset = GeoProjection.latLngToScreenOffset(
        latitude: centerLat,
        longitude: centerLng,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
        zoom: zoom,
        screenSize: size,
      );

      expect(offset.dx, closeTo(400.0, 0.0001));
      expect(offset.dy, closeTo(300.0, 0.0001));
    });

    test('Roundtrip conversion from LatLng to screen offset and back is lossless', () {
      const testLocations = [
        [19.0760, 72.8777], // Mumbai Center
        [18.9220, 72.8347], // Gateway of India / Colaba
        [19.0596, 72.8295], // Bandra West
        [19.1136, 72.8697], // Andheri East
        [19.0178, 72.8478], // Dadar
      ];

      for (final loc in testLocations) {
        final lat = loc[0];
        final lng = loc[1];

        final screenOffset = GeoProjection.latLngToScreenOffset(
          latitude: lat,
          longitude: lng,
          centerLatitude: centerLat,
          centerLongitude: centerLng,
          zoom: zoom,
          screenSize: size,
        );

        final recovered = GeoProjection.screenOffsetToLatLng(
          screenOffset: screenOffset,
          centerLatitude: centerLat,
          centerLongitude: centerLng,
          zoom: zoom,
          screenSize: size,
        );

        expect(recovered.latitude, closeTo(lat, 0.00001));
        expect(recovered.longitude, closeTo(lng, 0.00001));
      }
    });

    test('Zooming in increases pixel distance between coordinates', () {
      const p1Lat = 19.0760;
      const p1Lng = 72.8777;
      const p2Lat = 19.0596;
      const p2Lng = 72.8295;

      final offZoom10_1 = GeoProjection.latLngToScreenOffset(
        latitude: p1Lat,
        longitude: p1Lng,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
        zoom: 10.0,
        screenSize: size,
      );
      final offZoom10_2 = GeoProjection.latLngToScreenOffset(
        latitude: p2Lat,
        longitude: p2Lng,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
        zoom: 10.0,
        screenSize: size,
      );

      final offZoom12_1 = GeoProjection.latLngToScreenOffset(
        latitude: p1Lat,
        longitude: p1Lng,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
        zoom: 12.0,
        screenSize: size,
      );
      final offZoom12_2 = GeoProjection.latLngToScreenOffset(
        latitude: p2Lat,
        longitude: p2Lng,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
        zoom: 12.0,
        screenSize: size,
      );

      final distZoom10 = (offZoom10_1 - offZoom10_2).distance;
      final distZoom12 = (offZoom12_1 - offZoom12_2).distance;

      // Distance should quadruple when zoom increases by 2
      expect(distZoom12, closeTo(distZoom10 * 4.0, 0.1));
    });
  });
}
