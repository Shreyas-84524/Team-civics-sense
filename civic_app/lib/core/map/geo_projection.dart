import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Standard Web Mercator (EPSG:3857) projection math for pixel-accurate map coordinate conversions.
class GeoProjection {
  GeoProjection._();

  /// Converts a geographic [latitude], [longitude] to screen pixel [Offset]
  /// based on map [centerLatitude], [centerLongitude], [zoom], and viewport [screenSize].
  static Offset latLngToScreenOffset({
    required double latitude,
    required double longitude,
    required double centerLatitude,
    required double centerLongitude,
    required double zoom,
    required Size screenSize,
  }) {
    final double scale = 256.0 * math.pow(2.0, zoom);

    // Longitude calculation (linear in Web Mercator)
    final double xDiff = (longitude - centerLongitude) / 360.0;
    final double screenX = (screenSize.width / 2.0) + (xDiff * scale);

    // Latitude calculation (Mercator projection)
    final double centerLatRad = _clipLat(centerLatitude) * math.pi / 180.0;
    final double targetLatRad = _clipLat(latitude) * math.pi / 180.0;

    final double centerMercY = math.log(math.tan(math.pi / 4.0 + centerLatRad / 2.0));
    final double targetMercY = math.log(math.tan(math.pi / 4.0 + targetLatRad / 2.0));

    final double yDiff = (targetMercY - centerMercY) / (2.0 * math.pi);
    final double screenY = (screenSize.height / 2.0) - (yDiff * scale);

    return Offset(screenX, screenY);
  }

  /// Converts a screen pixel [Offset] back to geographic [LatLng]
  /// based on map [centerLatitude], [centerLongitude], [zoom], and viewport [screenSize].
  static LatLng screenOffsetToLatLng({
    required Offset screenOffset,
    required double centerLatitude,
    required double centerLongitude,
    required double zoom,
    required Size screenSize,
  }) {
    final double scale = 256.0 * math.pow(2.0, zoom);

    // Longitude from X offset
    final double xDiff = (screenOffset.dx - (screenSize.width / 2.0)) / scale;
    final double lng = centerLongitude + (xDiff * 360.0);

    // Latitude from Y offset
    final double centerLatRad = _clipLat(centerLatitude) * math.pi / 180.0;
    final double centerMercY = math.log(math.tan(math.pi / 4.0 + centerLatRad / 2.0));

    final double yDiff = ((screenSize.height / 2.0) - screenOffset.dy) / scale;
    final double targetMercY = centerMercY + (yDiff * 2.0 * math.pi);

    final double targetLatRad = 2.0 * (math.atan(math.exp(targetMercY)) - (math.pi / 4.0));
    final double lat = targetLatRad * 180.0 / math.pi;

    return LatLng(_clipLat(lat), _wrapLng(lng));
  }

  static double _clipLat(double lat) {
    return lat.clamp(-85.05112878, 85.05112878);
  }

  static double _wrapLng(double lng) {
    var wrapped = lng;
    while (wrapped < -180.0) {
      wrapped += 360.0;
    }
    while (wrapped > 180.0) {
      wrapped -= 360.0;
    }
    return wrapped;
  }
}
