import 'package:flutter/material.dart';
import '../../../core/models/government_role.dart';
import '../../models/govt_user_model.dart';

/// Reusable widget for conditional UI presentation based on government role & permissions.
///
/// NOTE: Presentation-layer visibility is purely for UX ergonomics and clutter reduction.
/// Authoritative access control is strictly enforced by backend services and Firestore rules.
class GovtRoleVisibility extends StatelessWidget {
  final Widget child;
  final GovtUserModel? user;
  final List<GovernmentRole>? allowedRoles;
  final String? requiredPermission;
  final Widget fallback;

  const GovtRoleVisibility({
    super.key,
    required this.child,
    this.user,
    this.allowedRoles,
    this.requiredPermission,
    this.fallback = const SizedBox.shrink(),
  });

  /// Static helper to check whether a user satisfies role and permission requirements.
  static bool canView({
    GovtUserModel? user,
    List<GovernmentRole>? allowedRoles,
    String? requiredPermission,
  }) {
    if (user == null) return false;

    // Check Role
    if (allowedRoles != null && allowedRoles.isNotEmpty) {
      if (!allowedRoles.contains(user.govtRole)) {
        return false;
      }
    }

    // Check Permission
    if (requiredPermission != null && requiredPermission.isNotEmpty) {
      if (!user.hasPermission(requiredPermission)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (canView(
      user: user,
      allowedRoles: allowedRoles,
      requiredPermission: requiredPermission,
    )) {
      return child;
    }
    return fallback;
  }
}
