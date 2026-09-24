import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:civic_app/core/map/map_config.dart';
import 'package:civic_app/core/map/map_constants.dart';

void main() {
  group('MapConstants Unit Tests', () {
    test('Mumbai geographic coordinates and bounds are valid', () {
      expect(MapConstants.mumbaiLatitude, equals(19.0760));
      expect(MapConstants.mumbaiLongitude, equals(72.8777));
      expect(MapConstants.mumbaiCenter, equals(const LatLng(19.0760, 72.8777)));
      expect(MapConstants.defaultInitialZoom, inInclusiveRange(10.0, 14.0));
      expect(MapConstants.minZoom, lessThan(MapConstants.maxZoom));
      expect(MapConstants.mmrSouthLat, lessThan(MapConstants.mmrNorthLat));
      expect(MapConstants.mmrWestLng, lessThan(MapConstants.mmrEastLng));
      expect(MapConstants.defaultStyle, equals('streets-v2'));
    });
  });

  group('MapConfig Unit Tests', () {
    tearDown(() {
      MapConfig.resetForTesting();
    });

    test('isConfigured returns false when no key is set or is placeholder', () {
      MapConfig.setApiKeyForTesting('');
      expect(MapConfig.isConfigured, isFalse);
      expect(MapConfig.getStyleUrl(), isNull);
      expect(MapConfig.maskedKey, equals('(not configured)'));

      MapConfig.setApiKeyForTesting('YOUR_MAPTILER_API_KEY');
      expect(MapConfig.isConfigured, isFalse);
      expect(MapConfig.getStyleUrl(), isNull);
    });

    test('getStyleUrl generates valid MapTiler style URL when key is set', () {
      MapConfig.setApiKeyForTesting('test_api_key_123456');
      expect(MapConfig.isConfigured, isTrue);
      expect(
        MapConfig.getStyleUrl(),
        equals('https://api.maptiler.com/maps/streets-v2/style.json?key=test_api_key_123456'),
      );
      expect(
        MapConfig.getStyleUrl(style: 'basic-v2'),
        equals('https://api.maptiler.com/maps/basic-v2/style.json?key=test_api_key_123456'),
      );
      expect(MapConfig.maskedKey, equals('tes...456'));
    });

    test('maskedKey masks secrets safely', () {
      MapConfig.setApiKeyForTesting('abc');
      expect(MapConfig.maskedKey, equals('***'));

      MapConfig.setApiKeyForTesting('abcdefghijklmnop');
      expect(MapConfig.maskedKey, equals('abc...nop'));
    });
  });
}
