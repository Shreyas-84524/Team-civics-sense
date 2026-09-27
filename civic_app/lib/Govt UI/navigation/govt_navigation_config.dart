import 'package:flutter/material.dart';
import '../../core/models/government_role.dart';
import '../models/govt_user_model.dart';
import 'govt_nav_item.dart';

/// Central navigation registry and role-aware configuration for CivicFix Government Portal.
class GovtNavigationConfig {
  GovtNavigationConfig._();

  /// Canonical core navigation items (fully compatible with existing tests & screens).
  static const List<GovtNavItem> defaultNavItems = [
    GovtNavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      index: 0,
      routeName: '/govt/dashboard',
      group: 'Core',
    ),
    GovtNavItem(
      title: 'Complaints',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      index: 1,
      routeName: '/govt/complaints',
      badgeCount: 24,
      group: 'Core',
    ),
    GovtNavItem(
      title: 'Hazard Map',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      index: 2,
      routeName: '/govt/hazard-map',
      group: 'Core',
    ),
    GovtNavItem(
      title: 'Analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      index: 3,
      routeName: '/govt/analytics',
      group: 'Management',
      allowedRoles: [
        GovernmentRole.governmentSuperAdmin,
        GovernmentRole.zonalDmc,
        GovernmentRole.centralDepartmentHod,
        GovernmentRole.wardOfficer,
        GovernmentRole.wardDepartmentLead,
      ],
    ),
    GovtNavItem(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      index: 4,
      routeName: '/govt/profile',
      group: 'System',
    ),
  ];

  /// Comprehensive government navigation items including Phase 1 extended routes.
  static const List<GovtNavItem> allNavItems = [
    // --- Group: Operations / Core ---
    GovtNavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      index: 0,
      routeName: '/government/dashboard',
      group: 'Operations',
    ),
    GovtNavItem(
      title: 'Complaints',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      index: 1,
      routeName: '/government/complaints',
      badgeCount: 24,
      group: 'Operations',
      requiredPermission: 'view_complaints',
    ),
    GovtNavItem(
      title: 'Hazard Map',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      index: 2,
      routeName: '/govt/hazard-map',
      group: 'Operations',
      requiredPermission: 'view_hazard_map',
    ),
    GovtNavItem(
      title: 'Operations',
      icon: Icons.engineering_outlined,
      selectedIcon: Icons.engineering_rounded,
      index: 5,
      routeName: '/government/operations',
      group: 'Operations',
      allowedRoles: [
        GovernmentRole.governmentSuperAdmin,
        GovernmentRole.zonalDmc,
        GovernmentRole.centralDepartmentHod,
        GovernmentRole.wardOfficer,
        GovernmentRole.wardDepartmentLead,
        GovernmentRole.departmentCrew,
      ],
    ),

    // --- Group: Management & Oversight ---
    GovtNavItem(
      title: 'Analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      index: 3,
      routeName: '/government/analytics',
      group: 'Management',
      requiredPermission: 'view_analytics',
      allowedRoles: [
        GovernmentRole.governmentSuperAdmin,
        GovernmentRole.zonalDmc,
        GovernmentRole.centralDepartmentHod,
        GovernmentRole.wardOfficer,
        GovernmentRole.wardDepartmentLead,
      ],
    ),
    GovtNavItem(
      title: 'Escalations',
      icon: Icons.priority_high_rounded,
      selectedIcon: Icons.warning_rounded,
      index: 6,
      routeName: '/government/escalations',
      badgeCount: 3,
      badgeLabel: 'Breached',
      group: 'Management',
      allowedRoles: [
        GovernmentRole.governmentSuperAdmin,
        GovernmentRole.zonalDmc,
        GovernmentRole.centralDepartmentHod,
        GovernmentRole.wardOfficer,
      ],
    ),
    GovtNavItem(
      title: 'Staff',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      index: 7,
      routeName: '/government/staff',
      group: 'Management',
      allowedRoles: [
        GovernmentRole.governmentSuperAdmin,
        GovernmentRole.zonalDmc,
        GovernmentRole.centralDepartmentHod,
        GovernmentRole.wardOfficer,
        GovernmentRole.wardDepartmentLead,
      ],
    ),
    GovtNavItem(
      title: 'Audit Logs',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      index: 8,
      routeName: '/government/audit',
      group: 'Management',
      allowedRoles: [
        GovernmentRole.governmentSuperAdmin,
        GovernmentRole.zonalDmc,
        GovernmentRole.centralDepartmentHod,
        GovernmentRole.wardOfficer,
      ],
    ),

    // --- Group: System ---
    GovtNavItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      index: 4,
      routeName: '/government/settings',
      group: 'System',
    ),
  ];

  /// Filters items based on the given user model (role and permissions).
  static List<GovtNavItem> getItemsForUser(GovtUserModel? user, {bool useExtended = false}) {
    final source = useExtended ? allNavItems : defaultNavItems;
    if (user == null) return source;

    return source.where((item) {
      return item.isVisibleFor(
        role: user.govtRole,
        permissions: user.permissions,
      );
    }).toList();
  }

  /// Filters items based on the given government role.
  static List<GovtNavItem> getItemsForRole(GovernmentRole role, {bool useExtended = true}) {
    final source = useExtended ? allNavItems : defaultNavItems;
    return source.where((item) {
      return item.isVisibleFor(role: role);
    }).toList();
  }

  /// Groups items by their designated group title.
  static Map<String, List<GovtNavItem>> groupItems(List<GovtNavItem> items) {
    final Map<String, List<GovtNavItem>> grouped = {};
    for (final item in items) {
      final grp = item.group ?? 'General';
      grouped.putIfAbsent(grp, () => []).add(item);
    }
    return grouped;
  }
}
