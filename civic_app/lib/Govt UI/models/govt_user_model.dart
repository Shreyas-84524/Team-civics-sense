import '../../core/models/government_role.dart';

/// BMC Government Officer / Municipal Personnel Model.
///
/// Hierarchical Matrix Governance Roles:
/// 1. `government_super_admin` - Apex Leadership (Municipal Commissioner & Addl. MC)
/// 2. `zonal_dmc` - Zonal Deputy Municipal Commissioners (Zones 1-7)
/// 3. `central_department_hod` - Central Department Heads & Chief Engineers (18 Depts)
/// 4. `ward_officer` - Assistant Municipal Commissioners / AMCs (24 Wards)
/// 5. `ward_department_lead` - Ward Departmental Leads / Executive Engineers (432 Units)
/// 6. `department_crew` - Field Sub-Engineers, JEs & Maintenance Crews (2,160 Technicians)
class GovtUserModel {
  final String id;
  final String fullName;
  final String email;
  final String employeeId;
  final String phone;
  final String role;
  final String displayDesignation;
  final String? wardId;
  final String? zoneId;
  final String? departmentId;
  final String departmentName;
  final String? administrativeSupervisorId;
  final String? technicalSupervisorId;
  final bool active;
  final bool isSynthetic;
  final String organization;
  final String? avatarUrl;
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Backward-compatibility getters
  String get designation => displayDesignation;
  String get assignedWard => wardId ?? '';
  String? get supervisorId => administrativeSupervisorId;
  GovernmentRole get govtRole => GovernmentRole.fromString(role);

  bool get isSuperAdmin => govtRole.isSuperAdmin;
  bool get isZonalDmc => govtRole.isZonalDmc;
  bool get isCentralHod => govtRole.isCentralHod;
  bool get isWardOfficer => govtRole.isWardOfficer;
  bool get isWardLead => govtRole.isWardLead;
  bool get isCrew => govtRole.isCrew;

  const GovtUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.employeeId,
    String? departmentId,
    this.departmentName = '',
    String? designation,
    String? displayDesignation,
    String? assignedWard,
    String? wardId,
    this.zoneId,
    this.administrativeSupervisorId,
    this.technicalSupervisorId,
    this.active = true,
    this.isSynthetic = false,
    this.phone = '+91 22 2262 0251',
    this.organization = 'Brihanmumbai Municipal Corporation (BMC)',
    this.avatarUrl,
    this.role = 'government',
    this.permissions = const [
      'view_complaints',
      'update_status',
      'assign_officer',
      'view_analytics',
      'view_hazard_map',
    ],
    this.createdAt,
    this.updatedAt,
  })  : departmentId = departmentId ?? '',
        displayDesignation = displayDesignation ?? designation ?? 'Municipal Officer',
        wardId = wardId ?? (assignedWard != '' ? assignedWard : null);

  /// Derives initials for avatar fallback (e.g. "Arun Deshmukh" -> "AD").
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'GO';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts.first.isNotEmpty ? parts.first[0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool hasPermission(String permission) {
    if (permissions.contains('all') || permissions.contains('admin_override')) {
      return true;
    }
    return permissions.contains(permission);
  }

  GovtUserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? employeeId,
    String? departmentId,
    String? departmentName,
    String? designation,
    String? displayDesignation,
    String? assignedWard,
    String? wardId,
    String? zoneId,
    String? administrativeSupervisorId,
    String? technicalSupervisorId,
    bool? active,
    bool? isSynthetic,
    String? phone,
    String? organization,
    String? avatarUrl,
    String? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GovtUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      displayDesignation: displayDesignation ?? designation ?? this.displayDesignation,
      wardId: wardId ?? assignedWard ?? this.wardId,
      zoneId: zoneId ?? this.zoneId,
      administrativeSupervisorId:
          administrativeSupervisorId ?? this.administrativeSupervisorId,
      technicalSupervisorId: technicalSupervisorId ?? this.technicalSupervisorId,
      active: active ?? this.active,
      isSynthetic: isSynthetic ?? this.isSynthetic,
      phone: phone ?? this.phone,
      organization: organization ?? this.organization,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GovtUserModel.fromJson(Map<String, dynamic> json) {
    final dId = json['departmentId'] as String?;
    final wId = json['wardId'] as String?;
    return GovtUserModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      departmentId: dId ?? (json['department'] as String?),
      departmentName: json['departmentName'] as String? ?? '',
      displayDesignation: json['displayDesignation'] as String? ?? json['designation'] as String?,
      wardId: wId ?? (json['assignedWard'] as String?),
      zoneId: json['zoneId'] as String?,
      administrativeSupervisorId: json['administrativeSupervisorId'] as String? ??
          json['supervisorId'] as String?,
      technicalSupervisorId: json['technicalSupervisorId'] as String?,
      active: json['active'] as bool? ?? true,
      isSynthetic: json['isSynthetic'] as bool? ?? false,
      phone: json['phone'] as String? ?? '+91 22 2262 0251',
      organization: json['organization'] as String? ?? 'Brihanmumbai Municipal Corporation (BMC)',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? GovernmentRole.wardDepartmentLeadId,
      permissions: List<String>.from(json['permissions'] as List<dynamic>? ?? const []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : DateTime.tryParse(json['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'employeeId': employeeId,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'displayDesignation': displayDesignation,
      'designation': displayDesignation,
      'wardId': wardId,
      'assignedWard': wardId ?? '',
      'zoneId': zoneId,
      'administrativeSupervisorId': administrativeSupervisorId,
      'technicalSupervisorId': technicalSupervisorId,
      'supervisorId': administrativeSupervisorId,
      'active': active,
      'isSynthetic': isSynthetic,
      'phone': phone,
      'organization': organization,
      'avatarUrl': avatarUrl,
      'role': role,
      'permissions': permissions,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory GovtUserModel.fromMap(Map<String, dynamic> map) => GovtUserModel.fromJson(map);
}
