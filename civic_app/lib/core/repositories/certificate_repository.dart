import '../models/certificate_model.dart';

/// Abstract contract for Civic Achievement Certificate operations.
abstract class CertificateRepository {
  /// Fetches all certificates issued to a specific citizen UID.
  Future<List<CivicCertificate>> getCertificatesForUser(String recipientUid);

  /// Look up a specific certificate by its unique deterministic certificateId.
  Future<CivicCertificate?> getCertificateById(String certificateId);

  /// Look up a certificate by its public verification slug.
  Future<CivicCertificate?> getCertificateByVerificationSlug(String slug);

  /// Saves / persists a newly issued certificate.
  Future<CivicCertificate> saveCertificate(CivicCertificate certificate);

  /// Updates status of a certificate (e.g. valid -> revoked).
  Future<void> updateCertificateStatus(
    String certificateId, {
    required String status,
    String? reason,
  });
}
