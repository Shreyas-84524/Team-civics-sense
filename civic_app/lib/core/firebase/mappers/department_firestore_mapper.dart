import 'package:flutter/material.dart';
import '../../../Govt UI/models/department_model.dart';

/// Bidirectional mapper for Municipal Departments and Officers to/from Cloud Firestore documents.
class DepartmentFirestoreMapper {
  DepartmentFirestoreMapper._();

  /// Converts a [GovtDepartmentModel] into a Firestore map.
  static Map<String, dynamic> departmentToFirestore(GovtDepartmentModel dept) {
    return {
      'name': dept.name,
      'code': dept.code,
      'description': dept.description,
      'activeComplaintsCount': dept.activeComplaintsCount,
      'assignedPersonnelCount': dept.assignedPersonnelCount,
      'active': true,
    };
  }

  /// Converts a Firestore document map into a [GovtDepartmentModel].
  static GovtDepartmentModel departmentFromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final defaultMatch = GovtDepartmentModel.defaultDepartments.firstWhere(
      (d) => d.id == documentId || d.code == data['code'],
      orElse: () => const GovtDepartmentModel(
        id: 'dept_general',
        name: 'Public Works',
        code: 'PWD-GEN',
        icon: Icons.business_rounded,
        description: 'General municipal infrastructure.',
      ),
    );

    return GovtDepartmentModel(
      id: documentId,
      name: data['name'] as String? ?? defaultMatch.name,
      code: data['code'] as String? ?? defaultMatch.code,
      icon: defaultMatch.icon,
      description: data['description'] as String? ?? defaultMatch.description,
      activeComplaintsCount: data['activeComplaintsCount'] as int? ?? defaultMatch.activeComplaintsCount,
      assignedPersonnelCount: data['assignedPersonnelCount'] as int? ?? defaultMatch.assignedPersonnelCount,
    );
  }

  /// Converts a [GovtOfficerModel] into a Firestore map.
  static Map<String, dynamic> officerToFirestore(GovtOfficerModel officer) {
    return {
      'name': officer.name,
      'departmentId': officer.departmentId,
      'designation': officer.designation,
      'phone': officer.phone,
      'assignedZone': officer.assignedZone,
      'isAvailable': officer.isAvailable,
    };
  }

  /// Converts a Firestore document map into a [GovtOfficerModel].
  static GovtOfficerModel officerFromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return GovtOfficerModel(
      id: documentId,
      name: data['name'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      designation: data['designation'] as String? ?? 'Officer',
      phone: data['phone'] as String? ?? '+91 98000 00000',
      assignedZone: data['assignedZone'] as String? ?? 'Ward 14 (Central)',
      isAvailable: data['isAvailable'] as bool? ?? true,
    );
  }
}
