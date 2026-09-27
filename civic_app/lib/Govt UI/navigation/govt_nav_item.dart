import 'package:flutter/material.dart';
import '../../core/models/government_role.dart';

/// Reusable navigation item model for Government Sidebar & App Shell.
class GovtNavItem {
  final String title;
  final IconData icon;
  final IconData? selectedIcon;
  final int index;
  final String routeName;
  final int? badgeCount;
  final String? badgeLabel;
  final String? requiredPermission;
  final List<GovernmentRole>? allowedRoles;
  final String? group;
  final bool isDisabled;

  const GovtNavItem({
    required this.title,
    required this.icon,
    IconData? selectedIcon,
    this.index = 0,
    required this.routeName,
    this.badgeCount,
    this.badgeLabel,
    this.requiredPermission,
    this.allowedRoles,
    this.group,
    this.isDisabled = false,
  }) : selectedIcon = selectedIcon ?? icon;

  /// Alias for routeName
  String get route => routeName;

  /// Returns true if this nav item is visible for the given user role and permissions.
  bool isVisibleFor({
    GovernmentRole? role,
    List<String>? permissions,
  }) {
    // 1. Role Check
    if (allowedRoles != null && allowedRoles!.isNotEmpty) {
      if (role == null) return false;
      if (!allowedRoles!.contains(role)) return false;
    }

    // 2. Permission Check
    if (requiredPermission != null && requiredPermission!.isNotEmpty) {
      if (permissions == null) return false;
      if (permissions.contains('all') || permissions.contains('admin_override')) {
        return true;
      }
      if (!permissions.contains(requiredPermission)) return false;
    }

    return true;
  }
}
