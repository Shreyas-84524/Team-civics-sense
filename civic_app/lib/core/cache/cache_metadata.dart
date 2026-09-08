/// Metadata describing a cached collection or entity in Hive local storage.
class CacheMetadata {
  final String boxName;
  final DateTime cachedAt;
  final int recordCount;
  final String? version;

  const CacheMetadata({
    required this.boxName,
    required this.cachedAt,
    this.recordCount = 0,
    this.version = '1.0.0',
  });

  /// Check whether the cached data exceeds the specified maximum age threshold.
  bool isStale(Duration maxAge) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }

  /// Age of this cache snapshot.
  Duration get age => DateTime.now().difference(cachedAt);

  /// Human-readable representation of cache freshness.
  String get formattedAge {
    final diff = age;
    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// User-facing banner label describing the cache status.
  String get displayLabel {
    if (age.inMinutes < 2) {
      return 'Updated recently';
    }
    return 'Showing cached information (Saved $formattedAge)';
  }

  Map<String, dynamic> toMap() {
    return {
      'boxName': boxName,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'recordCount': recordCount,
      'version': version,
    };
  }

  factory CacheMetadata.fromMap(Map<String, dynamic> map) {
    return CacheMetadata(
      boxName: map['boxName'] as String? ?? 'general',
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        map['cachedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      recordCount: map['recordCount'] as int? ?? 0,
      version: map['version'] as String? ?? '1.0.0',
    );
  }
}

/// Standardized cache expiration and invalidation policies across CivicFix.
class CachePolicy {
  CachePolicy._();

  /// Complaints cache max retention before stale warning (14 days).
  static const Duration complaintsMaxAge = Duration(days: 14);

  /// Hazards cache max retention (2 hours for real-time safety relevance).
  static const Duration hazardsMaxAge = Duration(hours: 2);

  /// Notifications cache max retention (7 days).
  static const Duration notificationsMaxAge = Duration(days: 7);

  /// User profile cache max retention (30 days).
  static const Duration userProfileMaxAge = Duration(days: 30);

  /// Rewards & perks catalog cache max retention (7 days).
  static const Duration rewardsMaxAge = Duration(days: 7);

  /// Government analytics cache max retention (1 hour).
  static const Duration analyticsMaxAge = Duration(hours: 1);
}
