import '../../core/models/government_role.dart';
import '../models/govt_user_model.dart';
import '../widgets/common/govt_jurisdiction_badge.dart';

/// Centralized Resolver for Municipal Jurisdictions (Zones, Wards, Departments).
///
/// Converts raw backend IDs (`ZONE_4`, `N`, `maintenance_roads`) into canonical,
/// human-readable municipal titles and provides standardized UI badges.
class GovernmentJurisdictionResolver {
  GovernmentJurisdictionResolver._();

  // Canonical Zone mapping
  static const Map<String, String> _zoneDisplayNames = {
    'ZONE_1': 'Zone 1',
    'ZONE_2': 'Zone 2',
    'ZONE_3': 'Zone 3',
    'ZONE_4': 'Zone 4',
    'ZONE_5': 'Zone 5',
    'ZONE_6': 'Zone 6',
    'ZONE_7': 'Zone 7',
    '1': 'Zone 1',
    '2': 'Zone 2',
    '3': 'Zone 3',
    '4': 'Zone 4',
    '5': 'Zone 5',
    '6': 'Zone 6',
    '7': 'Zone 7',
  };

  // Canonical Department mapping
  static const Map<String, String> _departmentDisplayNames = {
    'maintenance_roads': 'Maintenance & Roads',
    'dept_roads': 'Maintenance & Roads',
    'roads': 'Maintenance & Roads',
    'water_works': 'Water Works & Supply',
    'dept_water': 'Water Works & Supply',
    'water': 'Water Works & Supply',
    'solid_waste_management': 'Solid Waste Management',
    'dept_swm': 'Solid Waste Management',
    'swm': 'Solid Waste Management',
    'building_factory': 'Building & Factory',
    'garden_trees': 'Gardens & Trees',
    'storm_water_drain': 'Storm Water Drains',
    'public_health': 'Public Health & Sanitation',
    'sewerage_operations': 'Sewerage Operations',
    'traffic_coordination': 'Traffic Coordination',
    'disaster_management': 'Disaster Management',
    'estate_land': 'Estate & Land Management',
    'assessment_collection': 'Assessment & Collection',
    'education_schools': 'Municipal Education',
    'it_smart_governance': 'IT & Smart Governance',
    'environment_climate': 'Environment & Climate',
    'fire_safety': 'Fire Brigade & Safety',
    'legal_compliance': 'Legal & Compliance',
    'vigilance_anti_corruption': 'Vigilance & Oversight',
  };

  /// Resolves human-readable Zone label (e.g. `'ZONE_4'` -> `'Zone 4'`).
  static String resolveZone(String? zoneId) {
    if (zoneId == null || zoneId.trim().isEmpty) return '';
    final cleaned = zoneId.trim().toUpperCase();
    if (_zoneDisplayNames.containsKey(cleaned)) {
      return _zoneDisplayNames[cleaned]!;
    }
    final numMatch = RegExp(r'[0-9]+').firstMatch(cleaned);
    if (numMatch != null) {
      final numVal = int.tryParse(numMatch.group(0)!);
      if (numVal != null) {
        return 'Zone $numVal';
      }
    }
    return 'Zone $zoneId';
  }

  /// Resolves human-readable Ward label (e.g. `'N'` -> `'N Ward'`).
  static String resolveWard(String? wardId) {
    if (wardId == null || wardId.trim().isEmpty) return '';
    final trimmed = wardId.trim();
    if (trimmed.toLowerCase().contains('ward')) {
      return trimmed;
    }
    final cleaned = trimmed.toUpperCase();
    final match = RegExp(r'^WARD_?([A-Z0-9]+)$').firstMatch(cleaned);
    if (match != null) {
      return '${match.group(1)} Ward';
    }
    return '$cleaned Ward';
  }

  /// Resolves human-readable Department label (e.g. `'dept_swm'` -> `'Solid Waste Management'`).
  static String resolveDepartment(String? deptId, [String fallback = '']) {
    if (fallback.isNotEmpty) return fallback;
    if (deptId == null || deptId.trim().isEmpty) {
      return 'General Administration';
    }
    final normalized = deptId.trim().toLowerCase();
    if (_departmentDisplayNames.containsKey(normalized)) {
      return _departmentDisplayNames[normalized]!;
    }
    return deptId.replaceAll('_', ' ').toUpperCase();
  }

  /// Formats the single authoritative jurisdiction context summary for [user].
  static String resolveContextSummary(GovtUserModel user) {
    final role = user.govtRole;
    switch (role) {
      case GovernmentRole.governmentSuperAdmin:
        return 'Mumbai Citywide';

      case GovernmentRole.zonalDmc:
        final zone = resolveZone(user.zoneId);
        return zone.isNotEmpty ? zone : 'Zonal Command';

      case GovernmentRole.centralDepartmentHod:
        final dept = resolveDepartment(user.departmentId, user.departmentName);
        return '$dept · Citywide';

      case GovernmentRole.wardOfficer:
        final ward = resolveWard(user.wardId);
        return ward.isNotEmpty ? ward : 'Ward Operations';

      case GovernmentRole.wardDepartmentLead:
      case GovernmentRole.departmentCrew:
        final ward = resolveWard(user.wardId);
        final dept = resolveDepartment(user.departmentId, user.departmentName);
        if (ward.isNotEmpty && dept.isNotEmpty) {
          return '$ward · $dept';
        }
        return ward.isNotEmpty ? ward : dept;
    }
  }

  /// Resolves the list of compact [GovtJurisdictionBadge]s appropriate for [user]'s role.
  static List<GovtJurisdictionBadge> resolveBadges(
    GovtUserModel user, {
    bool isCompact = true,
    bool withBrackets = false,
    bool uppercase = false,
  }) {
    final role = user.govtRole;
    final badges = <GovtJurisdictionBadge>[];

    switch (role) {
      case GovernmentRole.governmentSuperAdmin:
        badges.add(GovtJurisdictionBadge.zone(
          'Citywide',
          isCompact: isCompact,
          showIcon: true,
          withBrackets: withBrackets,
          uppercase: uppercase,
        ));
        break;

      case GovernmentRole.zonalDmc:
        final zone = resolveZone(user.zoneId);
        if (zone.isNotEmpty) {
          badges.add(GovtJurisdictionBadge.zone(
            zone,
            isCompact: isCompact,
            showIcon: true,
            withBrackets: withBrackets,
            uppercase: uppercase,
          ));
        }
        break;

      case GovernmentRole.centralDepartmentHod:
        final dept = resolveDepartment(user.departmentId, user.departmentName);
        if (dept.isNotEmpty) {
          badges.add(GovtJurisdictionBadge.department(
            dept,
            isCompact: isCompact,
            showIcon: true,
            withBrackets: withBrackets,
            uppercase: uppercase,
          ));
        }
        badges.add(GovtJurisdictionBadge.zone(
          'Citywide',
          isCompact: isCompact,
          showIcon: false,
          withBrackets: withBrackets,
          uppercase: uppercase,
        ));
        break;

      case GovernmentRole.wardOfficer:
        final ward = resolveWard(user.wardId);
        if (ward.isNotEmpty) {
          badges.add(GovtJurisdictionBadge.ward(
            ward,
            isCompact: isCompact,
            showIcon: true,
            withBrackets: withBrackets,
            uppercase: uppercase,
          ));
        }
        break;

      case GovernmentRole.wardDepartmentLead:
      case GovernmentRole.departmentCrew:
        final ward = resolveWard(user.wardId);
        final dept = resolveDepartment(user.departmentId, user.departmentName);
        if (ward.isNotEmpty) {
          badges.add(GovtJurisdictionBadge.ward(
            ward,
            isCompact: isCompact,
            showIcon: true,
            withBrackets: withBrackets,
            uppercase: uppercase,
          ));
        }
        if (dept.isNotEmpty) {
          badges.add(GovtJurisdictionBadge.department(
            dept,
            isCompact: isCompact,
            showIcon: true,
            withBrackets: withBrackets,
            uppercase: uppercase,
          ));
        }
        break;
    }

    return badges;
  }
}
