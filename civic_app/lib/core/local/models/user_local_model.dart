import '../../models/user_model.dart';

/// Local persistence model for citizen user profile stored in Hive.
class UserLocalModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final int civicPoints;
  final int reportsSubmitted;
  final int reportsResolved;
  final List<String> badges;
  final String languageCode;
  final String wardNumber;
  final String role;

  const UserLocalModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.civicPoints = 0,
    this.reportsSubmitted = 0,
    this.reportsResolved = 0,
    this.badges = const [],
    this.languageCode = 'en',
    this.wardNumber = 'Ward 14 (Central)',
    this.role = 'citizen',
  });

  /// Map from Domain Model [UserModel] -> [UserLocalModel]
  factory UserLocalModel.fromDomain(UserModel user) {
    return UserLocalModel(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      civicPoints: user.civicPoints,
      reportsSubmitted: user.reportsSubmitted,
      reportsResolved: user.reportsResolved,
      badges: List.unmodifiable(user.badges),
      languageCode: user.languageCode,
      wardNumber: user.wardNumber,
      role: user.role,
    );
  }

  /// Map from [UserLocalModel] -> Domain Model [UserModel]
  UserModel toDomain() {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      civicPoints: civicPoints,
      reportsSubmitted: reportsSubmitted,
      reportsResolved: reportsResolved,
      badges: badges,
      languageCode: languageCode,
      wardNumber: wardNumber,
      role: role,
    );
  }

  UserLocalModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    int? civicPoints,
    int? reportsSubmitted,
    int? reportsResolved,
    List<String>? badges,
    String? languageCode,
    String? wardNumber,
    String? role,
  }) {
    return UserLocalModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      civicPoints: civicPoints ?? this.civicPoints,
      reportsSubmitted: reportsSubmitted ?? this.reportsSubmitted,
      reportsResolved: reportsResolved ?? this.reportsResolved,
      badges: badges ?? this.badges,
      languageCode: languageCode ?? this.languageCode,
      wardNumber: wardNumber ?? this.wardNumber,
      role: role ?? this.role,
    );
  }
}
