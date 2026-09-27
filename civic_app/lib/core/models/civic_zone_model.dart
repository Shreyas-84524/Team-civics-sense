/// BMC Administrative Zone Model.
///
/// Mumbai is partitioned into 7 administrative zones (ZONE_1 through ZONE_7).
class CivicZone {
  final String zoneId;
  final int zoneNumber;
  final String displayName;
  final bool active;

  const CivicZone({
    required this.zoneId,
    required this.zoneNumber,
    required this.displayName,
    this.active = true,
  });

  factory CivicZone.fromJson(Map<String, dynamic> json) {
    return CivicZone(
      zoneId: json['zoneId'] as String? ?? '',
      zoneNumber: json['zoneNumber'] as int? ?? 1,
      displayName: json['displayName'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneId': zoneId,
      'zoneNumber': zoneNumber,
      'displayName': displayName,
      'active': active,
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory CivicZone.fromMap(Map<String, dynamic> map) => CivicZone.fromJson(map);
}
