/// Government Officer / Administrator User Model.
class GovtUserModel {
  final String id;
  final String fullName;
  final String email;
  final String employeeId;
  final String departmentId;
  final String departmentName;
  final String designation;
  final String assignedWard;
  final String phone;
  final String organization;
  final String? avatarUrl;
  final String role;
  final List<String> permissions;

  const GovtUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.employeeId,
    required this.departmentId,
    required this.departmentName,
    required this.designation,
    required this.assignedWard,
    this.phone = '+91 98765 43210',
    this.organization = 'Municipal Civic Administration',
    this.avatarUrl,
    this.role = 'government',
    this.permissions = const [
      'view_complaints',
      'update_status',
      'assign_officer',
      'view_analytics',
      'view_hazard_map',
    ],
  });

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

  GovtUserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? employeeId,
    String? departmentId,
    String? departmentName,
    String? designation,
    String? assignedWard,
    String? phone,
    String? organization,
    String? avatarUrl,
    String? role,
    List<String>? permissions,
  }) {
    return GovtUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      designation: designation ?? this.designation,
      assignedWard: assignedWard ?? this.assignedWard,
      phone: phone ?? this.phone,
      organization: organization ?? this.organization,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
    );
  }
}
