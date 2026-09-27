/// BMC Ward Department Unit Model.
///
/// Represents an operational intersection between an administrative ward
/// and a municipal department (432 units across 24 wards x 18 departments).
///
/// Dual Supervision:
/// - Administrative supervisor: Ward Officer (`GOV-WO-{WARD}`)
/// - Technical supervisor: Central Department HOD (`GOV-HOD-{DEPT}`)
class WardDepartment {
  final String wardDepartmentId;
  final String wardId;
  final String departmentId;
  final String departmentLeadId;
  final List<String> crewMemberIds;
  final String administrativeSupervisorId;
  final String technicalSupervisorId;
  final bool active;

  const WardDepartment({
    required this.wardDepartmentId,
    required this.wardId,
    required this.departmentId,
    required this.departmentLeadId,
    required this.crewMemberIds,
    required this.administrativeSupervisorId,
    required this.technicalSupervisorId,
    this.active = true,
  });

  factory WardDepartment.fromJson(Map<String, dynamic> json) {
    return WardDepartment(
      wardDepartmentId: json['wardDepartmentId'] as String? ?? '',
      wardId: json['wardId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      departmentLeadId: json['departmentLeadId'] as String? ?? '',
      crewMemberIds: List<String>.from(json['crewMemberIds'] as List<dynamic>? ?? const []),
      administrativeSupervisorId: json['administrativeSupervisorId'] as String? ?? '',
      technicalSupervisorId: json['technicalSupervisorId'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wardDepartmentId': wardDepartmentId,
      'wardId': wardId,
      'departmentId': departmentId,
      'departmentLeadId': departmentLeadId,
      'crewMemberIds': crewMemberIds,
      'administrativeSupervisorId': administrativeSupervisorId,
      'technicalSupervisorId': technicalSupervisorId,
      'active': active,
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory WardDepartment.fromMap(Map<String, dynamic> map) => WardDepartment.fromJson(map);
}
