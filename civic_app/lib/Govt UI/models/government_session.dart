import 'package:flutter/foundation.dart';
import '../../core/models/government_role.dart';
import '../../core/routing/app_routes.dart';
import 'govt_user_model.dart';

/// Centralized representation of an active, authenticated Municipal Government Officer Session.
///
/// Encapsulates the verified [GovtUserModel], authenticated identity,
/// canonical landing route, and route-level authorization rules.
@immutable
class GovernmentSession {
  final GovtUserModel user;
  final String? firebaseAuthUid;

  const GovernmentSession({
    required this.user,
    this.firebaseAuthUid,
  });

  /// Factory constructor to construct a session from a [GovtUserModel].
  factory GovernmentSession.fromUser(
    GovtUserModel user, {
    String? firebaseAuthUid,
  }) =>
      GovernmentSession(
        user: user,
        firebaseAuthUid: firebaseAuthUid,
      );

  // ===========================================================================
  // SESSION IDENTITY & JURISDICTION ACCESSORS
  // ===========================================================================

  String get userId => user.id;
  String get employeeId => user.employeeId;
  String get fullName => user.fullName;
  String get email => user.email;
  GovernmentRole get role => user.govtRole;
  String get roleId => role.id;
  String get displayDesignation => user.displayDesignation;

  String? get zoneId => user.zoneId;
  String? get wardId => user.wardId;
  String? get departmentId => user.departmentId;
  String get departmentName => user.departmentName;

  String? get administrativeSupervisorId => user.administrativeSupervisorId;
  String? get technicalSupervisorId => user.technicalSupervisorId;
  bool get active => user.active;
  List<String> get permissions => user.permissions;

  bool get isSuperAdmin => role.isSuperAdmin;
  bool get isZonalDmc => role.isZonalDmc;
  bool get isCentralHod => role.isCentralHod;
  bool get isWardOfficer => role.isWardOfficer;
  bool get isWardLead => role.isWardLead;
  bool get isCrew => role.isCrew;

  // ===========================================================================
  // ROLE-BASED LANDING ROUTES (Phase 2 Canonical)
  // ===========================================================================

  /// Resolves the canonical landing route for a specific [GovernmentRole].
  static String getLandingRouteForRole(GovernmentRole role) {
    switch (role) {
      case GovernmentRole.governmentSuperAdmin:
        return AppRoutes.governmentDashboard;
      case GovernmentRole.zonalDmc:
        return AppRoutes.governmentZone;
      case GovernmentRole.centralDepartmentHod:
        return AppRoutes.governmentDepartment;
      case GovernmentRole.wardOfficer:
        return AppRoutes.governmentWard;
      case GovernmentRole.wardDepartmentLead:
        return AppRoutes.governmentDepartmentOperations;
      case GovernmentRole.departmentCrew:
        return AppRoutes.governmentWork;
    }
  }

  /// The default landing route for this active session.
  String get landingRoute => getLandingRouteForRole(role);

  // ===========================================================================
  // ROUTE-LEVEL AUTHORIZATION MATRIX
  // ===========================================================================

  /// Returns the list of [GovernmentRole]s permitted to access [routeName].
  static List<GovernmentRole>? getAllowedRolesForRoute(String routeName) {
    switch (routeName) {
      // Role-specific Landing Destinations
      case AppRoutes.governmentDashboard:
      case AppRoutes.govtDashboard:
        return const [
          GovernmentRole.governmentSuperAdmin,
        ];

      case AppRoutes.governmentZone:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.zonalDmc,
        ];

      case AppRoutes.governmentDepartment:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.centralDepartmentHod,
        ];

      case AppRoutes.governmentWard:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.zonalDmc,
          GovernmentRole.wardOfficer,
        ];

      case AppRoutes.governmentDepartmentOperations:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.centralDepartmentHod,
          GovernmentRole.wardOfficer,
          GovernmentRole.wardDepartmentLead,
        ];

      case AppRoutes.governmentWork:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.wardDepartmentLead,
          GovernmentRole.departmentCrew,
        ];

      // Operational & Module Routes
      case AppRoutes.governmentComplaints:
      case AppRoutes.govtComplaints:
      case AppRoutes.govtComplaintDetails:
      case AppRoutes.govtComplaintAssignment:
      case AppRoutes.govtStatusUpdate:
      case AppRoutes.governmentOperations:
      case AppRoutes.governmentSettings:
      case AppRoutes.govtProfile:
      case AppRoutes.govtHazardMap:
        return GovernmentRole.values; // Accessible to all authenticated officers (scoped by data)

      case AppRoutes.governmentAnalytics:
      case AppRoutes.govtAnalytics:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.zonalDmc,
          GovernmentRole.centralDepartmentHod,
          GovernmentRole.wardOfficer,
          GovernmentRole.wardDepartmentLead,
        ];

      case AppRoutes.governmentEscalations:
      case AppRoutes.governmentStaff:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.zonalDmc,
          GovernmentRole.centralDepartmentHod,
          GovernmentRole.wardOfficer,
          GovernmentRole.wardDepartmentLead,
        ];

      case AppRoutes.governmentAudit:
        return const [
          GovernmentRole.governmentSuperAdmin,
          GovernmentRole.zonalDmc,
        ];

      default:
        return null; // Public or uncategorized
    }
  }

  /// Validates whether this session is authorized to navigate to [routeName].
  bool isAuthorizedForRoute(String routeName) {
    if (!active) return false;
    if (isSuperAdmin) return true; // Super Admin has apex access

    final allowed = getAllowedRolesForRoute(routeName);
    if (allowed == null) return true; // No restriction defined

    return allowed.contains(role);
  }

  bool hasPermission(String permission) => user.hasPermission(permission);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GovernmentSession &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          firebaseAuthUid == other.firebaseAuthUid;

  @override
  int get hashCode => user.hashCode ^ (firebaseAuthUid?.hashCode ?? 0);
}
