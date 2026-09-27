/// BMC Municipal Department Model.
///
/// 18 Technical Departments covering all civic disciplines.
class CivicDepartment {
  final String departmentId;
  final String departmentCode;
  final String displayName;
  final String description;
  final bool active;
  final bool citizenComplaintEnabled;
  final String defaultLeadDesignation;

  const CivicDepartment({
    required this.departmentId,
    required this.departmentCode,
    required this.displayName,
    required this.description,
    this.active = true,
    this.citizenComplaintEnabled = true,
    required this.defaultLeadDesignation,
  });

  factory CivicDepartment.fromJson(Map<String, dynamic> json) {
    return CivicDepartment(
      departmentId: json['departmentId'] as String? ?? '',
      departmentCode: json['departmentCode'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      citizenComplaintEnabled: json['citizenComplaintEnabled'] as bool? ?? true,
      defaultLeadDesignation: json['defaultLeadDesignation'] as String? ?? 'Executive Engineer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'departmentCode': departmentCode,
      'displayName': displayName,
      'description': description,
      'active': active,
      'citizenComplaintEnabled': citizenComplaintEnabled,
      'defaultLeadDesignation': defaultLeadDesignation,
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory CivicDepartment.fromMap(Map<String, dynamic> map) => CivicDepartment.fromJson(map);
}
