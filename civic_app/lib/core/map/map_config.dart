import 'package:flutter/foundation.dart';
import 'map_constants.dart';

/// Centralized configuration provider for MapTiler API integration and MapLibre style URLs.
class MapConfig {
  MapConfig._();

  /// Environment variable key name for build-time injection.
  static const String envKey = 'MAPTILER_API_KEY';

  /// Compile-time injected MapTiler API key via `--dart-define=MAPTILER_API_KEY=...`.
  static const String _envApiKey = String.fromEnvironment(envKey, defaultValue: '');

  /// Runtime override for testing or dynamic configuration.
  static String? _overrideApiKey;

  /// Retrieves the active MapTiler API key.
  static String get apiKey {
    if (_overrideApiKey != null && _overrideApiKey!.trim().isNotEmpty) {
      return _overrideApiKey!.trim();
    }
    return _envApiKey.trim();
  }

  /// Whether a valid MapTiler API key is configured.
  static bool get isConfigured {
    final key = apiKey;
    return key.isNotEmpty && key != 'YOUR_MAPTILER_API_KEY' && key != 'PLACEHOLDER';
  }

  /// Generates the complete MapTiler vector style JSON URL with the configured API key.
  ///
  /// Returns `null` if the API key is not configured.
  static String? getStyleUrl({String style = MapConstants.defaultStyle}) {
    if (!isConfigured) return null;
    return 'https://api.maptiler.com/maps/$style/style.json?key=$apiKey';
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
