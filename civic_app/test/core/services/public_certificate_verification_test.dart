import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/models/certificate_model.dart';
import 'package:civic_app/core/models/public_certificate_model.dart';
import 'package:civic_app/core/repositories/certificate_repository.dart';
import 'package:civic_app/core/services/public_certificate_verification_service.dart';

class MockCertificateRepository implements CertificateRepository {
  final Map<String, CivicCertificate> _slugIndex = {};

  void addCertificate(CivicCertificate cert) {
    _slugIndex[cert.verificationSlug] = cert;
  }

  @override
  Future<CivicCertificate?> getCertificateByVerificationSlug(String verificationSlug) async {
    return _slugIndex[verificationSlug];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CIVICFIX REWARDS & GAMIFICATION — CERTIFICATE SYSTEM PHASE 2 (VERIFICATION LOGIC & SECURITY)', () {
    late MockCertificateRepository mockRepo;
    late PublicCertificateVerificationService service;

    final validCert = CivicCertificate(
      certificateId: 'cert_cit_101_civic_level_tier_level_3',
      recipientUid: 'secret_firebase_uid_99999',
      recipientDisplayName: 'Priya Sharma',
      certificateType: 'civic_level_tier',
      certificateTitle: 'Civic Champion Certificate of Recognition',
      civicLevel: 'Level 3 • Civic Champion',
      pointsAtIssue: 350,
      verifiedComplaintsAtIssue: 12,
      resolvedComplaintsAtIssue: 9,
      achievementReason: 'Awarded for achieving Civic Champion standing with 350+ points',
      issuedAt: DateTime(2026, 10, 8, 14, 30),
      status: 'valid',
      verificationSlug: 'v_abc1234567890abcdef12345',
      pdfStoragePath: 'civic-certificates/cert_1/certificate.pdf',
      createdAt: DateTime(2026, 10, 8, 14, 30),
    );

    final revokedCert = CivicCertificate(
      certificateId: 'cert_cit_102_achievement_milestone_evidence_expert',
      recipientUid: 'secret_firebase_uid_88888',
      recipientDisplayName: 'Rahul Verma',
      certificateType: 'achievement_milestone',
      certificateTitle: 'Evidence Expert Certificate of Recognition',
      civicLevel: 'Level 2 • Civic Contributor',
      pointsAtIssue: 180,
      verifiedComplaintsAtIssue: 5,
      resolvedComplaintsAtIssue: 4,
      achievementReason: 'Awarded for submitting verified reports with photographic proof',
      issuedAt: DateTime(2026, 9, 15, 10, 0),
      status: 'revoked',
      verificationSlug: 'v_revoked1234567890abcdef1',
      pdfStoragePath: 'civic-certificates/cert_2/certificate.pdf',
      revocationReason: 'Flagged for fraudulent photo submission during administrative audit',
      revokedAt: DateTime(2026, 10, 1, 12, 0),
      createdAt: DateTime(2026, 9, 15, 10, 0),
    );

    setUp(() {
      mockRepo = MockCertificateRepository();
      mockRepo.addCertificate(validCert);
      mockRepo.addCertificate(revokedCert);
      service = PublicCertificateVerificationService(certificateRepository: mockRepo);
    });

    test('VALID CERTIFICATE: Valid slug returns verified state with privacy-safe public data', () async {
      final result = await service.verifyCertificate('v_abc1234567890abcdef12345');

      expect(result.state, equals(CertificateValidationState.valid));
      expect(result.isValid, isTrue);
      expect(result.certificate, isNotNull);

      final pubData = result.certificate!;
      expect(pubData.recipientDisplayName, equals('Priya Sharma'));
      expect(pubData.certificateTitle, equals('Civic Champion Certificate of Recognition'));
      expect(pubData.civicLevel, equals('Level 3 • Civic Champion'));
      expect(pubData.pointsAtIssue, equals(350));
      expect(pubData.verifiedComplaintsAtIssue, equals(12));
      expect(pubData.resolvedComplaintsAtIssue, equals(9));
      expect(pubData.status, equals('VALID'));
      expect(pubData.awardImportance, contains('Municipal Civic Governance'));
    });

    test('REVOKED CERTIFICATE: Revoked slug returns revoked state and historical details', () async {
      final result = await service.verifyCertificate('v_revoked1234567890abcdef1');

      expect(result.state, equals(CertificateValidationState.revoked));
      expect(result.isRevoked, isTrue);
      expect(result.isValid, isFalse);
      expect(result.certificate, isNotNull);

      final pubData = result.certificate!;
      expect(pubData.recipientDisplayName, equals('Rahul Verma'));
      expect(pubData.status, equals('REVOKED'));
      expect(pubData.revocationReason, equals('Flagged for fraudulent photo submission during administrative audit'));
      expect(pubData.revokedAt, isNotNull);
    });

    test('INVALID SLUG: Non-existent slug returns invalid state with safe message', () async {
      final result = await service.verifyCertificate('v_nonexistent_slug_99999');

      expect(result.state, equals(CertificateValidationState.invalid));
      expect(result.isInvalid, isTrue);
      expect(result.certificate, isNull);
      expect(result.message, equals('No valid CivicFix certificate was found for this verification reference.'));
    });

    test('TAMPERED / MALFORMED SLUG: Path traversal, sql injection, or empty slugs return invalid', () async {
      final emptyResult = await service.verifyCertificate('');
      expect(emptyResult.state, equals(CertificateValidationState.invalid));

      final nullResult = await service.verifyCertificate(null);
      expect(nullResult.state, equals(CertificateValidationState.invalid));

      final shortResult = await service.verifyCertificate('ab');
      expect(shortResult.state, equals(CertificateValidationState.invalid));

      final injectionResult = await service.verifyCertificate('../../etc/passwd');
      expect(injectionResult.state, equals(CertificateValidationState.invalid));

      final scriptResult = await service.verifyCertificate('<script>alert(1)</script>');
      expect(scriptResult.state, equals(CertificateValidationState.invalid));
    });

    test('SECURITY & PRIVACY CHECK: PublicCertificateData does not expose private PII', () {
      final pubData = PublicCertificateData.fromCertificate(validCert);
      final json = pubData.toJson();

      // Ensure NO private fields are serialized
      expect(json.containsKey('recipientUid'), isFalse);
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json.containsKey('pdfStoragePath'), isFalse);

      // Verify JSON roundtrip
      final restored = PublicCertificateData.fromJson(json);
      expect(restored.certificateId, equals(pubData.certificateId));
      expect(restored.recipientDisplayName, equals(pubData.recipientDisplayName));
      expect(restored.pointsAtIssue, equals(pubData.pointsAtIssue));
    });
  });
}
