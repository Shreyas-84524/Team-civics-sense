import 'package:flutter/foundation.dart';
import '../models/certificate_model.dart';
import 'certificate_repository.dart';

/// In-memory and local repository for caching Civic Certificates.
class HiveCertificateRepository implements CertificateRepository {
  final Map<String, CivicCertificate> _certificatesById = {};
  final Map<String, List<String>> _userCertificates = {};
  final Map<String, String> _slugToId = {};

  @override
  Future<List<CivicCertificate>> getCertificatesForUser(String recipientUid) async {
    final ids = _userCertificates[recipientUid] ?? [];
    return ids
        .map((id) => _certificatesById[id])
        .whereType<CivicCertificate>()
        .toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  @override
  Future<CivicCertificate?> getCertificateById(String certificateId) async {
    return _certificatesById[certificateId];
  }

  @override
  Future<CivicCertificate?> getCertificateByVerificationSlug(String slug) async {
    final id = _slugToId[slug];
    if (id != null) return _certificatesById[id];
    return _certificatesById.values.cast<CivicCertificate?>().firstWhere(
          (c) => c?.verificationSlug == slug,
          orElse: () => null,
        );
  }

  @override
  Future<CivicCertificate> saveCertificate(CivicCertificate certificate) async {
    _certificatesById[certificate.certificateId] = certificate;
    _userCertificates.putIfAbsent(certificate.recipientUid, () => []).add(certificate.certificateId);
    _slugToId[certificate.verificationSlug] = certificate.certificateId;
    return certificate;
  }

  @override
  Future<void> updateCertificateStatus(
    String certificateId, {
    required String status,
    String? reason,
  }) async {
    final existing = _certificatesById[certificateId];
    if (existing != null) {
      final updated = existing.copyWith(
        status: status,
        revocationReason: reason,
        revokedAt: status.toLowerCase() == 'revoked' ? DateTime.now() : null,
      );
      _certificatesById[certificateId] = updated;
    }
  }

  @visibleForTesting
  void clear() {
    _certificatesById.clear();
    _userCertificates.clear();
    _slugToId.clear();
  }
}
