/// Standard Geohash (Morton code / Base32) implementation for spatial chunking.
///
/// Divides geographic space into hierarchical bounding boxes.
/// Precision 5 corresponds to ~4.9 km x 4.6 km cells at Mumbai latitude (~19° N),
/// which perfectly partitions the Greater Mumbai metropolitan region into ~30 cells.
class GeohashUtils {
  GeohashUtils._();

  static const String base32Alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Standard Precision 5 cell size in degrees (~0.0439° lat, ~0.0439° lng).
  static const double cellLatSpanPrecision5 = 180.0 / 4096.0; // 0.0439453125° (~4.88 km)
  static const double cellLngSpanPrecision5 = 360.0 / 8192.0; // 0.0439453125° (~4.61 km at 19°N)

  /// Encodes [latitude] and [longitude] to a geohash string with [precision] (default 5).
  static String encode(double latitude, double longitude, {int precision = 5}) {
    if (latitude.isNaN || longitude.isNaN || latitude.isInfinite || longitude.isInfinite) {
      return '';
    }
    final lat = latitude.clamp(-90.0, 90.0);
    final lng = longitude.clamp(-180.0, 180.0);

    double minLat = -90.0;
    double maxLat = 90.0;
    double minLng = -180.0;
    double maxLng = 180.0;

    final buffer = StringBuffer();
    bool isEven = true;
    int bit = 0;
    int ch = 0;

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2.0;
        if (lng >= mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2.0;
        if (lat >= mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(base32Alphabet[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  /// Decodes a [geohash] string into geographic bounding box [minLat, minLng, maxLat, maxLng].
  static SpatialBounds decodeBounds(String geohash) {
    if (geohash.isEmpty) {
      return const SpatialBounds(minLat: -90, minLng: -180, maxLat: 90, maxLng: 180);
    }

    double minLat = -90.0;
    double maxLat = 90.0;
    double minLng = -180.0;
    double maxLng = 180.0;
    bool isEven = true;

    final lower = geohash.toLowerCase();
    for (int i = 0; i < lower.length; i++) {
      final c = lower[i];
      final cd = base32Alphabet.indexOf(c);
      if (cd == -1) continue;

      for (int mask = 16; mask > 0; mask >>= 1) {
        if (isEven) {
          final mid = (minLng + maxLng) / 2.0;
          if ((cd & mask) != 0) {
            minLng = mid;
          } else {
            maxLng = mid;
          }
        } else {
          final mid = (minLat + maxLat) / 2.0;
          if ((cd & mask) != 0) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        isEven = !isEven;
      }
    }

    return SpatialBounds(
      minLat: minLat,
      minLng: minLng,
      maxLat: maxLat,
      maxLng: maxLng,
    );
  }

  /// Calculates all unique precision-5 spatial chunk IDs intersecting the given bounding box
  /// plus an optional surrounding [bufferRatio] (default 0.25 = 25% margin).
  static List<String> getChunksForBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    double bufferRatio = 0.25,
    int precision = 5,
  }) {
    if (minLat > maxLat) {
      final tmp = minLat;
      minLat = maxLat;
      maxLat = tmp;
    }
    if (minLng > maxLng) {
      final tmp = minLng;
      minLng = maxLng;
      maxLng = tmp;
    }

    // Apply prefetch margin buffer
    final latDelta = (maxLat - minLat).abs();
    final lngDelta = (maxLng - minLng).abs();
    final latBuffer = latDelta * bufferRatio;
    final lngBuffer = lngDelta * bufferRatio;

    final bufferedMinLat = (minLat - latBuffer).clamp(-90.0, 90.0);
    final bufferedMaxLat = (maxLat + latBuffer).clamp(-90.0, 90.0);
    final bufferedMinLng = (minLng - lngBuffer).clamp(-180.0, 180.0);
    final bufferedMaxLng = (maxLng + lngBuffer).clamp(-180.0, 180.0);

    // Grid step size: half the cell dimension ensures every cell in the range is sampled
    final stepLat = cellLatSpanPrecision5 * 0.75;
    final stepLng = cellLngSpanPrecision5 * 0.75;

    final Set<String> chunks = {};

    double currentLat = bufferedMinLat;
    while (currentLat <= bufferedMaxLat + stepLat) {
      double currentLng = bufferedMinLng;
      while (currentLng <= bufferedMaxLng + stepLng) {
        final hash = encode(currentLat, currentLng, precision: precision);
        if (hash.isNotEmpty) {
          chunks.add(hash);
        }
        currentLng += stepLng;
      }
      currentLat += stepLat;
    }

    // Ensure corners are always explicitly sampled
    chunks.add(encode(bufferedMinLat, bufferedMinLng, precision: precision));
    chunks.add(encode(bufferedMinLat, bufferedMaxLng, precision: precision));
    chunks.add(encode(bufferedMaxLat, bufferedMinLng, precision: precision));
    chunks.add(encode(bufferedMaxLat, bufferedMaxLng, precision: precision));

    final sorted = chunks.toList()..sort();
    return sorted;
  }
}

/// Geographic bounding box representation.
class SpatialBounds {
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  const SpatialBounds({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  double get centerLat => (minLat + maxLat) / 2.0;
  double get centerLng => (minLng + maxLng) / 2.0;
  double get south => minLat;
  double get north => maxLat;
  double get west => minLng;
  double get east => maxLng;

  bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  @override
  String toString() => 'SpatialBounds(min: [$minLat, $minLng], max: [$maxLat, $maxLng])';
}
