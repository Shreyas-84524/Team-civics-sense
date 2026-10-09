import '../models/certificate_model.dart';
import '../network/connectivity_service.dart';
import 'certificate_repository.dart';
import 'firebase_certificate_repository.dart';
import 'hive_certificate_repository.dart';

/// Offline-first orchestrator for Civic Certificates.
class OfflineFirstCertificateRepository implements CertificateRepository {
  final HiveCertificateRepository _localRepo;
  final FirebaseCertificateRepository _remoteRepo;
  final ConnectivityService _connectivity;

  OfflineFirstCertificateRepository({
    HiveCertificateRepository? localRepo,
    FirebaseCertificateRepository? remoteRepo,
    ConnectivityService? connectivity,
  })  : _localRepo = localRepo ?? HiveCertificateRepository(),
        _remoteRepo = remoteRepo ?? FirebaseCertificateRepository(),
        _connectivity = connectivity ?? AppConnectivityService();

  @override
  Future<List<CivicCertificate>> getCertificatesForUser(String recipientUid) async {
    final local = await _localRepo.getCertificatesForUser(recipientUid);
    if (_connectivity.isOnline) {
      try {
        final remote = await _remoteRepo.getCertificatesForUser(recipientUid);
        for (final cert in remote) {
          await _localRepo.saveCertificate(cert);
        }
        return remote.isNotEmpty ? remote : local;
      } catch (_) {}
    }
    return local;
  }

  @override
  Future<CivicCertificate?> getCertificateById(String certificateId) async {
    final local = await _localRepo.getCertificateById(certificateId);
    if (local != null) return local;

    if (_connectivity.isOnline) {
      try {
        final remote = await _remoteRepo.getCertificateById(certificateId);
        if (remote != null) {
          await _localRepo.saveCertificate(remote);
          return remote;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<CivicCertificate?> getCertificateByVerificationSlug(String slug) async {
    final local = await _localRepo.getCertificateByVerificationSlug(slug);
    if (local != null) return local;

    if (_connectivity.isOnline) {
      try {
        final remote = await _remoteRepo.getCertificateByVerificationSlug(slug);
        if (remote != null) {
          await _localRepo.saveCertificate(remote);
          return remote;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<CivicCertificate> saveCertificate(CivicCertificate certificate) async {
    await _localRepo.saveCertificate(certificate);
    if (_connectivity.isOnline) {
      try {
        await _remoteRepo.saveCertificate(certificate);
      } catch (_) {}
    }
    return certificate;
  }

  @override
  Future<void> updateCertificateStatus(
    String certificateId, {
    required String status,
    String? reason,
  }) async {
    await _localRepo.updateCertificateStatus(certificateId, status: status, reason: reason);
    if (_connectivity.isOnline) {
      try {
        await _remoteRepo.updateCertificateStatus(certificateId, status: status, reason: reason);
      } catch (_) {}
    }
  }
}
