/// BMC Administrative Ward Model.
///
/// 24 Administrative Wards (A, B, C, D, E, F_NORTH, F_SOUTH, G_NORTH, G_SOUTH,
/// H_EAST, H_WEST, K_EAST, K_WEST, L, M_EAST, M_WEST, N, P_NORTH, P_SOUTH,
/// R_NORTH, R_CENTRAL, R_SOUTH, S, T) assigned to zones.
class CivicWard {
  final String wardId;
  final String wardCode;
  final String wardName;
  final String zoneId;
  final bool active;
  final double lat;
  final double lng;
  final String pincode;

  const CivicWard({
    required this.wardId,
    required this.wardCode,
    required this.wardName,
    required this.zoneId,
    this.active = true,
    required this.lat,
    required this.lng,
    required this.pincode,
  });

  factory CivicWard.fromJson(Map<String, dynamic> json) {
    return CivicWard(
      wardId: json['wardId'] as String? ?? '',
      wardCode: json['wardCode'] as String? ?? '',
      wardName: json['wardName'] as String? ?? '',
      zoneId: json['zoneId'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      lat: (json['lat'] as num?)?.toDouble() ?? 19.0760,
      lng: (json['lng'] as num?)?.toDouble() ?? 72.8777,
      pincode: json['pincode'] as String? ?? '400001',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wardId': wardId,
      'wardCode': wardCode,
      'wardName': wardName,
      'zoneId': zoneId,
      'active': active,
      'lat': lat,
      'lng': lng,
      'pincode': pincode,
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory CivicWard.fromMap(Map<String, dynamic> map) => CivicWard.fromJson(map);
}
