import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/models/certificate_model.dart';
import 'package:civic_app/core/repositories/certificate_repository.dart';
import 'package:civic_app/core/services/public_certificate_verification_service.dart';
import 'package:civic_app/User UI/screens/public_certificate_verification_screen.dart';

class MockCertificateRepository implements CertificateRepository {
  final Map<String, CivicCertificate> _slugMap = {};

  void addCertificate(CivicCertificate cert) {
    _slugMap[cert.verificationSlug] = cert;
  }

  @override
  Future<CivicCertificate?> getCertificateByVerificationSlug(String verificationSlug) async {
    return _slugMap[verificationSlug];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CIVICFIX REWARDS & GAMIFICATION — PUBLIC CERTIFICATE VERIFICATION SCREEN (PHASE 2 UI)', () {
    late MockCertificateRepository mockRepo;
    late PublicCertificateVerificationService service;

    final validCert = CivicCertificate(
      certificateId: 'cert_cit_501_civic_level_tier_level_4',
      recipientUid: 'secret_uid_501',
      recipientDisplayName: 'Ananya Deshmukh',
      certificateType: 'civic_level_tier',
      certificateTitle: 'Civic Leader Certificate of Recognition',
      civicLevel: 'Level 4 • Civic Leader',
      pointsAtIssue: 620,
      verifiedComplaintsAtIssue: 25,
      resolvedComplaintsAtIssue: 20,
      achievementReason: 'Awarded for achieving Civic Leader status with 600+ civic points',
      issuedAt: DateTime(2026, 10, 5, 11, 0),
      status: 'valid',
      verificationSlug: 'v_valid_leader_slug_12345',
      pdfStoragePath: 'civic-certificates/cert_501/certificate.pdf',
      createdAt: DateTime(2026, 10, 5, 11, 0),
    );

    final revokedCert = CivicCertificate(
      certificateId: 'cert_cit_502_achievement_resolution_champion',
      recipientUid: 'secret_uid_502',
      recipientDisplayName: 'Vikram Singh',
      certificateType: 'achievement_milestone',
      certificateTitle: 'Resolution Champion Certificate of Recognition',
      civicLevel: 'Level 3 • Civic Champion',
      pointsAtIssue: 410,
      verifiedComplaintsAtIssue: 15,
      resolvedComplaintsAtIssue: 12,
      achievementReason: 'Awarded for leading community resolution tracking',
      issuedAt: DateTime(2026, 8, 20, 9, 30),
      status: 'revoked',
      verificationSlug: 'v_revoked_champ_slug_1234',
      pdfStoragePath: 'civic-certificates/cert_502/certificate.pdf',
      revocationReason: 'Ineligible complaint inflation discovered upon audit',
      revokedAt: DateTime(2026, 9, 28, 16, 0),
      createdAt: DateTime(2026, 8, 20, 9, 30),
    );

    setUp(() {
      mockRepo = MockCertificateRepository();
      mockRepo.addCertificate(validCert);
      mockRepo.addCertificate(revokedCert);
      service = PublicCertificateVerificationService(certificateRepository: mockRepo);
    });

    testWidgets('VALID CERTIFICATE: Renders verified badge, recipient, snapshot metrics, and VALID status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PublicCertificateVerificationScreen(
            verificationSlug: 'v_valid_leader_slug_12345',
            verificationService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verified trust banner
      expect(find.text('Certificate Verified'), findsOneWidget);
      expect(find.text('Authentic CivicFix Achievement Record'), findsOneWidget);
      expect(find.text('VALID'), findsOneWidget);

      // Certificate content
      expect(find.text('Civic Leader Certificate of Recognition'), findsOneWidget);
      expect(find.text('Awarded to Ananya Deshmukh'), findsOneWidget);
      expect(find.text('Level 4 • Civic Leader'), findsOneWidget);
      expect(find.text('cert_cit_501_civic_level_tier_level_4'), findsOneWidget);

      // Snapshot Metrics
      expect(find.text('+620'), findsOneWidget);
      expect(find.text('Civic Points'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('Verified Reports'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Resolved Reports'), findsOneWidget);

      // Award Reason
      expect(find.text('Awarded for achieving Civic Leader status with 600+ civic points'), findsOneWidget);
      expect(find.text('Official CivicFix Municipal Governance Portal'), findsOneWidget);
    });

    testWidgets('REVOKED CERTIFICATE: Renders CERTIFICATE REVOKED warning without green verified badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PublicCertificateVerificationScreen(
            verificationSlug: 'v_revoked_champ_slug_1234',
            verificationService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Revoked warning banner
      expect(find.text('CERTIFICATE REVOKED'), findsOneWidget);
      expect(find.text('This certificate is no longer considered valid by CivicFix.'), findsOneWidget);
      expect(find.text('Reason: Ineligible complaint inflation discovered upon audit'), findsOneWidget);

      // Must NOT render green verified status
      expect(find.text('Certificate Verified'), findsNothing);

      // Historical record reference
      expect(find.text('Vikram Singh'), findsOneWidget);
      expect(find.text('Resolution Champion Certificate of Recognition'), findsOneWidget);
      expect(find.text('REVOKED (INVALID)'), findsOneWidget);
    });

    testWidgets('INVALID / UNKNOWN CERTIFICATE: Renders Certificate Not Verified safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PublicCertificateVerificationScreen(
            verificationSlug: 'v_unknown_slug_99999',
            verificationService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Certificate Not Verified'), findsOneWidget);
      expect(find.text('No valid CivicFix certificate was found for this verification reference.'), findsOneWidget);
      expect(find.text('Please ensure the QR code was scanned directly from an authentic CivicFix document or verification URL.'), findsOneWidget);
    });
  });
}
