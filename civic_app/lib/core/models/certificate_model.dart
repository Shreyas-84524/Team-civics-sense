import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Canonical Certificate Model for verifiable CivicFix achievements.
class CivicCertificate {
  final String certificateId;
  final String recipientUid;
  final String recipientDisplayName;
  final String certificateType; // 'civic_level_tier' | 'achievement_milestone'
  final String certificateTitle;
  final String civicLevel;
  final int pointsAtIssue;
  final int verifiedComplaintsAtIssue;
  final int resolvedComplaintsAtIssue;
  final String achievementReason;
  final DateTime issuedAt;
  final String status; // 'valid' | 'revoked'
  final String verificationSlug;
  final String pdfStoragePath;
  final int certificateVersion;
  final DateTime createdAt;
  final String? revocationReason;
  final DateTime? revokedAt;
  final Map<String, dynamic> metadata;

  const CivicCertificate({
    required this.certificateId,
    required this.recipientUid,
    required this.recipientDisplayName,
    required this.certificateType,
    required this.certificateTitle,
    required this.civicLevel,
    required this.pointsAtIssue,
    required this.verifiedComplaintsAtIssue,
    required this.resolvedComplaintsAtIssue,
    required this.achievementReason,
    required this.issuedAt,
    this.status = 'valid',
    required this.verificationSlug,
    required this.pdfStoragePath,
    this.certificateVersion = 1,
    required this.createdAt,
    this.revocationReason,
    this.revokedAt,
    this.metadata = const {},
  });

  bool get isValid => status.toLowerCase() == 'valid';
  bool get isRevoked => status.toLowerCase() == 'revoked';

  /// Generates a deterministic, URL-safe verification slug.
  static String generateVerificationSlug({
    required String recipientUid,
    required String certificateType,
    required String milestoneKey,
    required DateTime issuedAt,
  }) {
    final raw = '$recipientUid:$certificateType:$milestoneKey:${issuedAt.millisecondsSinceEpoch}';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return 'v_${digest.toString().substring(0, 24)}';
  }

  /// Generates a deterministic certificate ID for idempotency.
  static String generateDeterministicId({
    required String recipientUid,
    required String certificateType,
    required String milestoneKey,
  }) {
    final sanitizedType = certificateType.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final sanitizedKey = milestoneKey.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return 'cert_${recipientUid}_${sanitizedType}_$sanitizedKey';
  }

  CivicCertificate copyWith({
    String? certificateId,
    String? recipientUid,
    String? recipientDisplayName,
    String? certificateType,
    String? certificateTitle,
    String? civicLevel,
    int? pointsAtIssue,
    int? verifiedComplaintsAtIssue,
    int? resolvedComplaintsAtIssue,
    String? achievementReason,
    DateTime? issuedAt,
    String? status,
    String? verificationSlug,
    String? pdfStoragePath,
    int? certificateVersion,
    DateTime? createdAt,
    String? revocationReason,
    DateTime? revokedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CivicCertificate(
      certificateId: certificateId ?? this.certificateId,
      recipientUid: recipientUid ?? this.recipientUid,
      recipientDisplayName: recipientDisplayName ?? this.recipientDisplayName,
      certificateType: certificateType ?? this.certificateType,
      certificateTitle: certificateTitle ?? this.certificateTitle,
      civicLevel: civicLevel ?? this.civicLevel,
      pointsAtIssue: pointsAtIssue ?? this.pointsAtIssue,
      verifiedComplaintsAtIssue: verifiedComplaintsAtIssue ?? this.verifiedComplaintsAtIssue,
      resolvedComplaintsAtIssue: resolvedComplaintsAtIssue ?? this.resolvedComplaintsAtIssue,
      achievementReason: achievementReason ?? this.achievementReason,
      issuedAt: issuedAt ?? this.issuedAt,
      status: status ?? this.status,
      verificationSlug: verificationSlug ?? this.verificationSlug,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      certificateVersion: certificateVersion ?? this.certificateVersion,
      createdAt: createdAt ?? this.createdAt,
      revocationReason: revocationReason ?? this.revocationReason,
      revokedAt: revokedAt ?? this.revokedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'certificateId': certificateId,
        'recipientUid': recipientUid,
        'recipientDisplayName': recipientDisplayName,
        'certificateType': certificateType,
        'certificateTitle': certificateTitle,
        'civicLevel': civicLevel,
        'pointsAtIssue': pointsAtIssue,
        'verifiedComplaintsAtIssue': verifiedComplaintsAtIssue,
        'resolvedComplaintsAtIssue': resolvedComplaintsAtIssue,
        'achievementReason': achievementReason,
        'issuedAt': issuedAt.toIso8601String(),
        'status': status,
        'verificationSlug': verificationSlug,
        'pdfStoragePath': pdfStoragePath,
        'certificateVersion': certificateVersion,
        'createdAt': createdAt.toIso8601String(),
        if (revocationReason != null) 'revocationReason': revocationReason,
        if (revokedAt != null) 'revokedAt': revokedAt!.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory CivicCertificate.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return CivicCertificate(
      certificateId: json['certificateId'] as String? ?? json['id'] as String? ?? '',
      recipientUid: json['recipientUid'] as String? ?? '',
      recipientDisplayName: json['recipientDisplayName'] as String? ?? 'CivicFix Citizen',
      certificateType: json['certificateType'] as String? ?? 'civic_level_tier',
      certificateTitle: json['certificateTitle'] as String? ?? 'Certificate of Civic Recognition',
      civicLevel: json['civicLevel'] as String? ?? 'Civic Contributor',
      pointsAtIssue: (json['pointsAtIssue'] as num?)?.toInt() ?? 0,
      verifiedComplaintsAtIssue: (json['verifiedComplaintsAtIssue'] as num?)?.toInt() ?? 0,
      resolvedComplaintsAtIssue: (json['resolvedComplaintsAtIssue'] as num?)?.toInt() ?? 0,
      achievementReason: json['achievementReason'] as String? ?? 'Outstanding civic participation and neighborhood stewardship.',
      issuedAt: parseDate(json['issuedAt']),
      status: json['status'] as String? ?? 'valid',
      verificationSlug: json['verificationSlug'] as String? ?? '',
      pdfStoragePath: json['pdfStoragePath'] as String? ?? '',
      certificateVersion: (json['certificateVersion'] as num?)?.toInt() ?? 1,
      createdAt: parseDate(json['createdAt']),
      revocationReason: json['revocationReason'] as String?,
      revokedAt: json['revokedAt'] != null ? parseDate(json['revokedAt']) : null,
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : const {},
    );
  }
}
