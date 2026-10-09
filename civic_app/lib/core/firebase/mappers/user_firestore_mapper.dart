import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Govt UI/models/govt_user_model.dart';
import '../../models/user_model.dart';
import 'firestore_mapper_helpers.dart';

/// Bidirectional mapper for [UserModel] and [GovtUserModel] to/from Cloud Firestore documents.
class UserFirestoreMapper {
  UserFirestoreMapper._();

  /// Converts a citizen [UserModel] into a Firestore map.
  static Map<String, dynamic> citizenToFirestore(UserModel user, {bool isCreate = false}) {
    final Map<String, dynamic> map = {
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'avatarUrl': user.avatarUrl,
      'civicPoints': user.civicPoints,
      'reportsSubmitted': user.reportsSubmitted,
      'reportsResolved': user.reportsResolved,
      'badges': user.badges,
      'languageCode': user.languageCode,
      'wardNumber': user.wardNumber,
      'role': 'citizen',
      'phoneVerified': user.phoneVerified,
      'phoneVerifiedAt': user.phoneVerifiedAt != null ? Timestamp.fromDate(user.phoneVerifiedAt!) : null,
    };

    if (isCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
    } else {
      map['updatedAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Converts a Firestore document map into a citizen [UserModel].
  static UserModel citizenFromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    DateTime? phoneVerifiedAt;
    final rawPhoneVerifiedAt = data['phoneVerifiedAt'];
    if (rawPhoneVerifiedAt is Timestamp) {
      phoneVerifiedAt = rawPhoneVerifiedAt.toDate();
    } else if (rawPhoneVerifiedAt is String) {
      phoneVerifiedAt = DateTime.tryParse(rawPhoneVerifiedAt);
    }

    return UserModel(
      id: documentId,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      civicPoints: (data['civicPoints'] as num?)?.toInt() ?? 0,
      reportsSubmitted: (data['reportsSubmitted'] as num?)?.toInt() ?? 0,
      reportsResolved: (data['reportsResolved'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(data['badges'] as List<dynamic>? ?? const []),
      languageCode: data['languageCode'] as String? ?? 'en',
      wardNumber: data['wardNumber'] as String? ?? 'Ward 14 (Central)',
      role: data['role'] as String? ?? 'citizen',
      phoneVerified: data['phoneVerified'] as bool? ?? false,
      phoneVerifiedAt: phoneVerifiedAt,
    );
  }

  /// Converts a [GovtUserModel] into a Firestore map.
  static Map<String, dynamic> govtUserToFirestore(GovtUserModel user, {bool isCreate = false}) {
    final Map<String, dynamic> map = {
      'fullName': user.fullName,
      'email': user.email,
      'employeeId': user.employeeId,
      'departmentId': user.departmentId,
      'departmentName': user.departmentName,
      'designation': user.designation,
      'displayDesignation': user.displayDesignation,
      'assignedWard': user.assignedWard,
      'wardId': user.wardId,
      'zoneId': user.zoneId,
      'administrativeSupervisorId': user.administrativeSupervisorId,
      'technicalSupervisorId': user.technicalSupervisorId,
      'phone': user.phone,
      'organization': user.organization,
      'avatarUrl': user.avatarUrl,
      'role': user.role,
      'permissions': user.permissions,
      'active': user.active,
      'isSynthetic': user.isSynthetic,
    };

    if (isCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
    } else {
      map['updatedAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Converts a Firestore document map into a [GovtUserModel].
  static GovtUserModel govtUserFromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return GovtUserModel(
      id: documentId,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      departmentName: data['departmentName'] as String? ?? '',
      designation: data['designation'] as String? ?? '',
      displayDesignation: data['displayDesignation'] as String? ?? data['designation'] as String?,
      assignedWard: data['assignedWard'] as String? ?? '',
      wardId: data['wardId'] as String? ?? (data['assignedWard'] as String?),
      zoneId: data['zoneId'] as String?,
      administrativeSupervisorId: data['administrativeSupervisorId'] as String? ??
          data['supervisorId'] as String?,
      technicalSupervisorId: data['technicalSupervisorId'] as String?,
      active: data['active'] as bool? ?? true,
      isSynthetic: data['isSynthetic'] as bool? ?? false,
      phone: data['phone'] as String? ?? '+91 98765 43210',
      organization: data['organization'] as String? ?? 'Municipal Civic Administration',
      avatarUrl: data['avatarUrl'] as String?,
      role: data['role'] as String? ?? 'government',
      permissions: List<String>.from(data['permissions'] as List<dynamic>? ?? const [
        'view_complaints',
        'update_status',
        'assign_officer',
        'view_analytics',
        'view_hazard_map',
      ]),
      createdAt: FirestoreMapperHelpers.timestampToDateTime(data['createdAt']),
      updatedAt: FirestoreMapperHelpers.timestampToDateTime(data['updatedAt']),
    );
  }
}

