import 'package:flutter/foundation.dart';
import '../models/public_certificate_model.dart';
import '../repositories/certificate_repository.dart';
import '../repositories/repository_locator.dart';

/// Centralized service for validating public certificate verification slugs without authentication.
class PublicCertificateVerificationService {
  final CertificateRepository _certificateRepo;

  PublicCertificateVerificationService({
    CertificateRepository? certificateRepository,
  }) : _certificateRepo = certificateRepository ?? RepositoryLocator.certificateRepository;

  /// Validates a verification slug against authoritative records and returns a privacy-safe result.
  Future<PublicVerificationResult> verifyCertificate(String? verificationSlug) async {
    final now = DateTime.now();

    // 1. Sanitize & validate slug format
    final slug = (verificationSlug ?? '').trim();
    if (slug.isEmpty) {
      return PublicVerificationResult(
        state: CertificateValidationState.invalid,
        certificate: null,
        message: 'No verification reference provided.',
        verifiedAt: now,
      );
    }

    // Slug format guard: must match alphanumeric characters, underscores, and hyphens (length 4 to 64)
    final slugPattern = RegExp(r'^[a-zA-Z0-9_-]{4,64}$');
    if (!slugPattern.hasMatch(slug)) {
      return PublicVerificationResult(
        state: CertificateValidationState.invalid,
        certificate: null,
        message: 'No valid CivicFix certificate was found for this verification reference.',
        verifiedAt: now,
      );
    }

    // 2. Query repository by verification slug
    try {
      final cert = await _certificateRepo.getCertificateByVerificationSlug(slug);

      // Certificate not found
      if (cert == null) {
        return PublicVerificationResult(
          state: CertificateValidationState.invalid,
          certificate: null,
          message: 'No valid CivicFix certificate was found for this verification reference.',
          verifiedAt: now,
        );
      }

      // Convert to sanitized, privacy-safe public data
      final publicData = PublicCertificateData.fromCertificate(cert);

      // Check Revocation Status
      if (cert.isRevoked) {
        return PublicVerificationResult(
          state: CertificateValidationState.revoked,
          certificate: publicData,
          message: 'This certificate is no longer considered valid by CivicFix.',
          verifiedAt: now,
        );
      }

      // Valid Certificate
      if (cert.isValid) {
        return PublicVerificationResult(
          state: CertificateValidationState.valid,
          certificate: publicData,
          message: 'Certificate Verified — Authentic CivicFix Achievement',
          verifiedAt: now,
        );
      }

      // Unknown/other status defaults to invalid
      return PublicVerificationResult(
        state: CertificateValidationState.invalid,
        certificate: null,
        message: 'No valid CivicFix certificate was found for this verification reference.',
        verifiedAt: now,
      );
    } catch (e) {
      debugPrint('[PublicCertificateVerificationService] Error verifying slug $slug: $e');
      return PublicVerificationResult(
        state: CertificateValidationState.error,
        certificate: null,
        message: 'Unable to verify certificate authenticity at this time. Please check connectivity and try again.',
        verifiedAt: now,
      );
    }
  }
}
