/// Visual quality rating of submitted civic evidence photographic material.
enum AiImageQuality {
  poor,
  acceptable,
  good;

  static AiImageQuality? fromString(String? value) {
    if (value == null) return null;
    final clean = value.trim().toLowerCase();
    switch (clean) {
      case 'poor':
        return AiImageQuality.poor;
      case 'acceptable':
        return AiImageQuality.acceptable;
      case 'good':
        return AiImageQuality.good;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case AiImageQuality.poor:
        return 'Poor';
      case AiImageQuality.acceptable:
        return 'Acceptable';
      case AiImageQuality.good:
        return 'Good';
    }
  }
}

/// Civic and public safety hazard severity levels evaluated by AI.
enum AiHazardSeverity {
  none,
  low,
  medium,
  high,
  unknown;

  static AiHazardSeverity fromString(String? value) {
    if (value == null) return AiHazardSeverity.unknown;
    final clean = value.trim().toLowerCase();
    switch (clean) {
      case 'none':
        return AiHazardSeverity.none;
      case 'low':
        return AiHazardSeverity.low;
      case 'medium':
        return AiHazardSeverity.medium;
      case 'high':
        return AiHazardSeverity.high;
      case 'critical':
        return AiHazardSeverity.high;
      case 'unknown':
      default:
        return AiHazardSeverity.unknown;
    }
  }

  String get label {
    switch (this) {
      case AiHazardSeverity.none:
        return 'None';
      case AiHazardSeverity.low:
        return 'Low';
      case AiHazardSeverity.medium:
        return 'Medium';
      case AiHazardSeverity.high:
        return 'High';
      case AiHazardSeverity.unknown:
        return 'Unknown';
    }
  }
}

/// Specific municipal hazard classification visible in citizen evidence.
enum AiHazardType {
  pothole,
  roadDamage,
  garbageOverflow,
  openDrain,
  waterlogging,
  damagedStreetlight,
  fallenTree,
  exposedWire,
  brokenPublicInfrastructure,
  trafficObstruction,
  fireOrSmoke,
  other,
  none,
  unknown;

  static AiHazardType fromString(String? value) {
    if (value == null) return AiHazardType.unknown;
    final clean = value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    switch (clean) {
      case 'pothole':
        return AiHazardType.pothole;
      case 'roaddamage':
        return AiHazardType.roadDamage;
      case 'garbageoverflow':
      case 'garbage':
      case 'waste':
        return AiHazardType.garbageOverflow;
      case 'opendrain':
      case 'openmanhole':
      case 'manhole':
        return AiHazardType.openDrain;
      case 'waterlogging':
      case 'flooding':
        return AiHazardType.waterlogging;
      case 'damagedstreetlight':
      case 'brokenstreetlight':
      case 'streetlight':
        return AiHazardType.damagedStreetlight;
      case 'fallentree':
      case 'tree':
        return AiHazardType.fallenTree;
      case 'exposedwire':
      case 'electricwire':
      case 'wire':
        return AiHazardType.exposedWire;
      case 'brokenpublicinfrastructure':
      case 'infrastructure':
      case 'publicinfrastructure':
        return AiHazardType.brokenPublicInfrastructure;
      case 'trafficobstruction':
      case 'obstruction':
        return AiHazardType.trafficObstruction;
      case 'fireorsmoke':
      case 'fire':
      case 'smoke':
        return AiHazardType.fireOrSmoke;
      case 'other':
        return AiHazardType.other;
      case 'none':
        return AiHazardType.none;
      case 'unknown':
      default:
        return AiHazardType.unknown;
    }
  }

  String get rawValue {
    switch (this) {
      case AiHazardType.pothole:
        return 'pothole';
      case AiHazardType.roadDamage:
        return 'road_damage';
      case AiHazardType.garbageOverflow:
        return 'garbage_overflow';
      case AiHazardType.openDrain:
        return 'open_drain';
      case AiHazardType.waterlogging:
        return 'waterlogging';
      case AiHazardType.damagedStreetlight:
        return 'damaged_streetlight';
      case AiHazardType.fallenTree:
        return 'fallen_tree';
      case AiHazardType.exposedWire:
        return 'exposed_wire';
      case AiHazardType.brokenPublicInfrastructure:
        return 'broken_public_infrastructure';
      case AiHazardType.trafficObstruction:
        return 'traffic_obstruction';
      case AiHazardType.fireOrSmoke:
        return 'fire_or_smoke';
      case AiHazardType.other:
        return 'other';
      case AiHazardType.none:
        return 'none';
      case AiHazardType.unknown:
        return 'unknown';
    }
  }
}
