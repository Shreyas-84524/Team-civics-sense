import 'package:flutter/foundation.dart';
import 'basemap_mode.dart';
import 'map_constants.dart';

/// Centralized configuration provider for MapTiler API integration and MapLibre style URLs.
class MapConfig {
  MapConfig._();

  /// Environment variable key name for build-time injection.
  static const String envKey = 'MAPTILER_API_KEY';

  /// Compile-time injected MapTiler API key via `--dart-define=MAPTILER_API_KEY=...` or default configuration.
  static const String _envApiKey = String.fromEnvironment(envKey, defaultValue: '');

  /// Runtime override for testing or dynamic configuration.
  static String? _overrideApiKey;

  /// Retrieves the active MapTiler API key.
  static String get apiKey {
    if (_overrideApiKey != null) {
      return _overrideApiKey!.trim();
    }
    return _envApiKey.trim();
  }

  static bool _hasLoggedNotice = false;

  /// Whether a valid MapTiler API key is configured.
  static bool get isConfigured {
    final key = apiKey;
    final configured = key.isNotEmpty &&
        key != 'YOUR_MAPTILER_API_KEY' &&
        key != 'PLACEHOLDER';
    if (!configured && kDebugMode && !_hasLoggedNotice) {
      _hasLoggedNotice = true;
      debugPrint('[MapConfig] MAP ENGINE = FALLBACK (No MapTiler key detected; pass --dart-define=MAPTILER_API_KEY=<key>)');
    } else if (configured && kDebugMode && !_hasLoggedNotice) {
      _hasLoggedNotice = true;
      debugPrint('[MapConfig] MAP ENGINE = MAPLIBRE (MapTiler key active: $maskedKey)');
    }
    return configured;
  }

  /// Generates the complete MapTiler vector or raster style JSON URL with the configured API key.
  ///
  /// Supports explicit [BasemapMode] or raw [style] identifier.
  /// Returns `null` if the API key is not configured.
  static String? getStyleUrl({String style = MapConstants.defaultStyle, BasemapMode? mode}) {
    if (!isConfigured) return null;
    final styleId = mode != null ? mode.styleId : style;
    return 'https://api.maptiler.com/maps/$styleId/style.json?key=$apiKey';
  }

  /// Returns a safely masked string of the active key for diagnostics without exposing secrets.
  static String get maskedKey {
    final key = apiKey;
    if (key.isEmpty) return '(not configured)';
    if (key.length <= 6) return '***';
    return '${key.substring(0, 3)}...${key.substring(key.length - 3)}';
  }

  /// Sets a temporary API key for unit/integration testing or dynamic injection.
  @visibleForTesting
  static void setApiKeyForTesting(String? key) {
    _overrideApiKey = key;
  }

  /// Resets testing overrides.
  @visibleForTesting
  static void resetForTesting() {
    _overrideApiKey = null;
  }
}
