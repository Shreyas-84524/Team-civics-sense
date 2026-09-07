/// Citizen profile model with civic points, statistics, and preferences.
class UserModel {
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

  const UserModel({
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

  /// Derives user initials for avatar fallback (e.g. "Shreyas Shigwan" -> "SS").
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'CF';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts.first.isNotEmpty ? parts.first[0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Human-readable display language name.
  String get languageName {
    switch (languageCode) {
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'mr':
        return 'मराठी (Marathi)';
      case 'en':
      default:
        return 'English';
    }
  }

  UserModel copyWith({
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
    return UserModel(
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
