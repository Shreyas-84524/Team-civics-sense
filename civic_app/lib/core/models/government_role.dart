/// BMC-Style Hierarchical Government Roles.
///
/// Exactly 6 backend role identifiers:
/// - `government_super_admin` (Apex Leadership: Municipal Commissioner & Addl. MC)
/// - `zonal_dmc` (Zonal Deputy Municipal Commissioners)
/// - `central_department_hod` (Central Department Heads & Chief Engineers)
/// - `ward_officer` (Assistant Municipal Commissioners / Ward Officers)
/// - `ward_department_lead` (Ward Departmental Leads / Executive Engineers)
/// - `department_crew` (Sub-Engineers, Junior Engineers & Ground Crews)
enum GovernmentRole {
  governmentSuperAdmin('government_super_admin'),
  zonalDmc('zonal_dmc'),
  centralDepartmentHod('central_department_hod'),
  wardOfficer('ward_officer'),
  wardDepartmentLead('ward_department_lead'),
  departmentCrew('department_crew');

  final String id;
  const GovernmentRole(this.id);

  static const String superAdminId = 'government_super_admin';
  static const String zonalDmcId = 'zonal_dmc';
  static const String centralDepartmentHodId = 'central_department_hod';
  static const String wardOfficerId = 'ward_officer';
  static const String wardDepartmentLeadId = 'ward_department_lead';
  static const String departmentCrewId = 'department_crew';

  static const List<String> allRoleIds = [
    superAdminId,
    zonalDmcId,
    centralDepartmentHodId,
    wardOfficerId,
    wardDepartmentLeadId,
    departmentCrewId,
  ];

  static GovernmentRole fromString(String? role) {
    if (role == null) return GovernmentRole.wardDepartmentLead;
    final normalized = role.trim().toLowerCase();
    for (final r in GovernmentRole.values) {
      if (r.id == normalized) return r;
    }
    // Fallback for legacy role string
    if (normalized == 'super_admin' || normalized == 'government_super_admin') {
      return GovernmentRole.governmentSuperAdmin;
    }
    if (normalized == 'government' || normalized == 'officer') {
      return GovernmentRole.wardDepartmentLead;
    }
    return GovernmentRole.wardDepartmentLead;
  }

  String get displayName {
    switch (this) {
      case GovernmentRole.governmentSuperAdmin:
        return 'Municipal Commissioner / Super Admin';
      case GovernmentRole.zonalDmc:
        return 'Zonal Deputy Municipal Commissioner';
      case GovernmentRole.centralDepartmentHod:
        return 'Central Department Head of Department';
      case GovernmentRole.wardOfficer:
        return 'Assistant Municipal Commissioner (Ward Officer)';
      case GovernmentRole.wardDepartmentLead:
        return 'Ward Department Lead';
      case GovernmentRole.departmentCrew:
        return 'Department Ground Crew';
    }
  }

  bool get isSuperAdmin => this == GovernmentRole.governmentSuperAdmin;
  bool get isZonalDmc => this == GovernmentRole.zonalDmc;
  bool get isCentralHod => this == GovernmentRole.centralDepartmentHod;
  bool get isWardOfficer => this == GovernmentRole.wardOfficer;
  bool get isWardLead => this == GovernmentRole.wardDepartmentLead;
  bool get isCrew => this == GovernmentRole.departmentCrew;

  /// Administrative oversight level (higher numbers have higher jurisdiction)
  int get hierarchyLevel {
    switch (this) {
      case GovernmentRole.governmentSuperAdmin:
        return 6;
      case GovernmentRole.zonalDmc:
        return 5;
      case GovernmentRole.centralDepartmentHod:
        return 4;
      case GovernmentRole.wardOfficer:
        return 3;
      case GovernmentRole.wardDepartmentLead:
        return 2;
      case GovernmentRole.departmentCrew:
        return 1;
    }
  }
}
