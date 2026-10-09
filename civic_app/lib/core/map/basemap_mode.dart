import 'package:flutter/material.dart';

/// Available basemap styles for the CivicFix mapping interface.
enum BasemapMode {
  /// Default MapTiler Streets vector basemap with road networks and landmarks.
  streets('streets-v2', 'Streets', Icons.map_outlined, 'Detailed vector road networks, wards, and civic infrastructure'),

  /// MapTiler pure global high-resolution satellite imagery.
  satellite('satellite', 'Satellite', Icons.satellite_alt_outlined, 'High-resolution aerial and satellite photographic imagery'),

  /// MapTiler Hybrid combining satellite imagery with vector street and locality labels.
  hybrid('hybrid', 'Hybrid', Icons.layers_outlined, 'Satellite imagery overlaid with street names, borders, and locality labels');

  /// MapTiler style preset identifier used in style URLs.
  final String styleId;

  /// User-facing label for UI selectors.
  final String label;

  /// Material icon representing this map mode.
  final IconData icon;

  /// Short description of the basemap mode.
  final String description;

  const BasemapMode(this.styleId, this.label, this.icon, this.description);

  /// Resolves a [BasemapMode] from a string name or style identifier.
  static BasemapMode fromString(String? value) {
    if (value == null) return BasemapMode.streets;
    final normalized = value.toLowerCase().trim();
    for (final mode in BasemapMode.values) {
      if (mode.name.toLowerCase() == normalized || mode.styleId.toLowerCase() == normalized) {
        return mode;
      }
    }
    return BasemapMode.streets;
  }
}
