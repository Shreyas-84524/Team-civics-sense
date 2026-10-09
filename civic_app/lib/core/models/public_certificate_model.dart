import 'certificate_model.dart';

/// Validation lifecycle state for public certificate verification.
enum CertificateValidationState {
  /// Authentic active certificate issued by CivicFix.
  valid,

  /// Authentic certificate that was formally revoked by civic authority.
  revoked,

  /// Verification slug not found, malformed, or tampered.
  invalid,

  /// Async verification in progress.
  loading,

  /// Network, timeout, or server connectivity error.
  error,
}

/// Publicly shareable, privacy-safe certificate data model.
///
/// Strictly excludes sensitive PII (UIDs, phone numbers, email addresses, private DB IDs).
class PublicCertificateData {
  final String certificateId;
  final String recipientDisplayName;
  final String certificateType;
  final String certificateTitle;
  final String civicLevel;
  final int pointsAtIssue;
  final int verifiedComplaintsAtIssue;
  final int resolvedComplaintsAtIssue;
  final String achievementReason;
  final String awardImportance;
  final DateTime issuedAt;
  final String status; // 'VALID' | 'REVOKED'
  final String verificationSlug;
  final int certificateVersion;
  final String? revocationReason;
  final DateTime? revokedAt;

  const PublicCertificateData({
    required this.certificateId,
    required this.recipientDisplayName,
    required this.certificateType,
    required this.certificateTitle,
    required this.civicLevel,
    required this.pointsAtIssue,
    required this.verifiedComplaintsAtIssue,
    required this.resolvedComplaintsAtIssue,
    required this.achievementReason,
    required this.awardImportance,
    required this.issuedAt,
    required this.status,
    required this.verificationSlug,
    this.certificateVersion = 1,
    this.revocationReason,
    this.revokedAt,
  });

  bool get isValid => status.toUpperCase() == 'VALID';
  bool get isRevoked => status.toUpperCase() == 'REVOKED';

  /// Transforms internal [CivicCertificate] into privacy-safe [PublicCertificateData].
  factory PublicCertificateData.fromCertificate(CivicCertificate cert) {
    return PublicCertificateData(
      certificateId: cert.certificateId,
      recipientDisplayName: cert.recipientDisplayName,
      certificateType: cert.certificateType,
      certificateTitle: cert.certificateTitle,
      civicLevel: cert.civicLevel,
      pointsAtIssue: cert.pointsAtIssue,
      verifiedComplaintsAtIssue: cert.verifiedComplaintsAtIssue,
      resolvedComplaintsAtIssue: cert.resolvedComplaintsAtIssue,
      achievementReason: cert.achievementReason,
      awardImportance: deriveAwardImportance(cert),
      issuedAt: cert.issuedAt,
      status: cert.status.toUpperCase(),
      verificationSlug: cert.verificationSlug,
      certificateVersion: cert.certificateVersion,
      revocationReason: cert.revocationReason,
      revokedAt: cert.revokedAt,
    );
  }

  /// Explains why the certificate was issued and its civic importance for employers/NGOs.
  static String deriveAwardImportance(CivicCertificate cert) {
    if (cert.certificateType == 'civic_level_tier') {
      return 'Official recognition awarded by Municipal Civic Governance for sustained citizen engagement, active civic problem reporting, and verifiable community impact.';
    } else {
      return 'Special civic milestone recognition awarded for exemplary verified contributions to community infrastructure, ground reporting, or collective civic problem solving.';
    }
  }

  Map<String, dynamic> toJson() => {
        'certificateId': certificateId,
        'recipientDisplayName': recipientDisplayName,
        'certificateType': certificateType,
        'certificateTitle': certificateTitle,
        'civicLevel': civicLevel,
        'pointsAtIssue': pointsAtIssue,
        'verifiedComplaintsAtIssue': verifiedComplaintsAtIssue,
        'resolvedComplaintsAtIssue': resolvedComplaintsAtIssue,
        'achievementReason': achievementReason,
        'awardImportance': awardImportance,
        'issuedAt': issuedAt.toIso8601String(),
        'status': status,
        'verificationSlug': verificationSlug,
        'certificateVersion': certificateVersion,
        if (revocationReason != null) 'revocationReason': revocationReason,
        if (revokedAt != null) 'revokedAt': revokedAt?.toIso8601String(),
      };

  factory PublicCertificateData.fromJson(Map<String, dynamic> json) {
    return PublicCertificateData(
      certificateId: json['certificateId'] as String? ?? '',
      recipientDisplayName: json['recipientDisplayName'] as String? ?? 'Citizen',
      certificateType: json['certificateType'] as String? ?? 'civic_level_tier',
      certificateTitle: json['certificateTitle'] as String? ?? 'Civic Certificate',
      civicLevel: json['civicLevel'] as String? ?? 'Civic Contributor',
      pointsAtIssue: (json['pointsAtIssue'] as num?)?.toInt() ?? 0,
      verifiedComplaintsAtIssue: (json['verifiedComplaintsAtIssue'] as num?)?.toInt() ?? 0,
      resolvedComplaintsAtIssue: (json['resolvedComplaintsAtIssue'] as num?)?.toInt() ?? 0,
      achievementReason: json['achievementReason'] as String? ?? '',
      awardImportance: json['awardImportance'] as String? ??
          'Official recognition awarded for verified civic participation.',
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: (json['status'] as String? ?? 'VALID').toUpperCase(),
      verificationSlug: json['verificationSlug'] as String? ?? '',
      certificateVersion: (json['certificateVersion'] as num?)?.toInt() ?? 1,
      revocationReason: json['revocationReason'] as String?,
      revokedAt: json['revokedAt'] != null ? DateTime.tryParse(json['revokedAt'] as String) : null,
    );
  }
}

/// Response object from verifying a certificate slug.
class PublicVerificationResult {
  final CertificateValidationState state;
  final PublicCertificateData? certificate;
  final String message;
  final DateTime verifiedAt;

  const PublicVerificationResult({
    required this.state,
    this.certificate,
    required this.message,
    required this.verifiedAt,
  });

  bool get isValid => state == CertificateValidationState.valid;
  bool get isRevoked => state == CertificateValidationState.revoked;
  bool get isInvalid => state == CertificateValidationState.invalid;
  bool get isError => state == CertificateValidationState.error;
}
