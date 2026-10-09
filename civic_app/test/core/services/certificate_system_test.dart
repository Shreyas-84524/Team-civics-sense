import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/certificate_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/repositories/hive_certificate_repository.dart';
import 'package:civic_app/core/repositories/rewards_repository.dart';
import 'package:civic_app/core/repositories/user_repository.dart';
import 'package:civic_app/core/services/certificate_issuance_service.dart';
import 'package:civic_app/User UI/widgets/rewards/my_certificates_section.dart';

class MockUserRepository implements UserRepository {
  UserModel _user;
  final ValueNotifier<UserModel> _notifier;

  MockUserRepository(this._user) : _notifier = ValueNotifier<UserModel>(_user);

  @override
  Future<UserModel> getCurrentUser() async => _user;

  @override
  ValueNotifier<UserModel> getUserListenable() => _notifier;

  void updateUser(UserModel updated) {
    _user = updated;
    _notifier.value = updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockComplaintRepository implements ComplaintRepository {
  final List<ComplaintModel> _complaints = [];

  void setComplaints(List<ComplaintModel> list) {
    _complaints.clear();
    _complaints.addAll(list);
  }

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async => _complaints;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRewardsRepository implements RewardsRepository {
  @override
  Future<RewardDataModel> getRewardData(String userId) async {
    return RewardDataModel(
      userId: userId,
      currentPoints: 0,
      reportsSubmitted: 0,
      reportsResolved: 0,
      achievements: CivicAchievement.defaultAchievements(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CIVICFIX REWARDS & GAMIFICATION — CERTIFICATE SYSTEM PHASE 1', () {
    late HiveCertificateRepository certRepo;
    late MockUserRepository userRepo;
    late MockComplaintRepository complaintRepo;
    late MockRewardsRepository rewardsRepo;
    late CertificateIssuanceService issuanceService;

    const testCitizenId = 'citizen_cert_qa_001';

    setUp(() {
      certRepo = HiveCertificateRepository();
      certRepo.clear();

      const eligibleUser = UserModel(
        id: testCitizenId,
        fullName: 'Devendra Joshi',
        email: 'devendra@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
        civicPoints: 320, // Level 3 Civic Champion
        reportsSubmitted: 5,
        reportsResolved: 3,
      );

      userRepo = MockUserRepository(eligibleUser);
      complaintRepo = MockComplaintRepository();
      rewardsRepo = MockRewardsRepository();

      issuanceService = CertificateIssuanceService(
        certificateRepository: certRepo,
        userRepository: userRepo,
        complaintRepository: complaintRepo,
        rewardsRepository: rewardsRepo,
      );
    });

    test('Eligible user can successfully issue an official Level certificate with PDF and QR', () async {
      final result = await issuanceService.issueLevelCertificate(
        citizenId: testCitizenId,
        requestedLevel: CivicLevel.forPoints(320), // Level 3
      );

      expect(result.granted, isTrue);
      expect(result.certificate, isNotNull);

      final cert = result.certificate!;
      expect(cert.recipientUid, equals(testCitizenId));
      expect(cert.recipientDisplayName, equals('Devendra Joshi'));
      expect(cert.certificateTitle, contains('Civic Champion'));
      expect(cert.civicLevel, contains('Level 3'));
      expect(cert.pointsAtIssue, equals(320));
      expect(cert.status, equals('valid'));
      expect(cert.isValid, isTrue);
      expect(cert.isRevoked, isFalse);

      // Verify QR Slug and Storage Path
      expect(cert.verificationSlug, startsWith('v_'));
      expect(cert.pdfStoragePath, equals('civic-certificates/${cert.certificateId}/certificate.pdf'));

      // Verify PDF Generation
      expect(result.pdfBytes, isNotNull);
      expect(result.pdfBytes!.isNotEmpty, isTrue);
      // PDF Magic Header: %PDF-
      final header = String.fromCharCodes(result.pdfBytes!.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('Ineligible user (Level 1 / insufficient points) is strictly denied certificate issuance', () async {
      // Setup user with only 50 points (Level 1 Civic Starter)
      userRepo.updateUser(const UserModel(
        id: 'starter_citizen',
        fullName: 'Starter Citizen',
        email: 'starter@civicfix.org',
        phone: '+919876543210',
        role: 'citizen',
        civicPoints: 50,
      ));

      final starterService = CertificateIssuanceService(
        certificateRepository: certRepo,
        userRepository: userRepo,
        complaintRepository: complaintRepo,
        rewardsRepository: rewardsRepo,
      );

      final result = await starterService.issueLevelCertificate(
        citizenId: 'starter_citizen',
        requestedLevel: CivicLevel.forPoints(150), // Requesting Level 2
      );

      expect(result.granted, isFalse);
      expect(result.certificate, isNull);
      expect(result.reason, contains('Ineligible'));
    });

    test('Idempotent Generation: Repeated certificate request returns existing record without duplication', () async {
      // First issuance
      final r1 = await issuanceService.issueLevelCertificate(
        citizenId: testCitizenId,
        requestedLevel: CivicLevel.forPoints(320),
      );
      expect(r1.granted, isTrue);

      final certCountBefore = (await certRepo.getCertificatesForUser(testCitizenId)).length;
      expect(certCountBefore, equals(1));

      // Second issuance for same level
      final r2 = await issuanceService.issueLevelCertificate(
        citizenId: testCitizenId,
        requestedLevel: CivicLevel.forPoints(320),
      );
      expect(r2.granted, isTrue);
      expect(r2.certificate!.certificateId, equals(r1.certificate!.certificateId));

      final certCountAfter = (await certRepo.getCertificatesForUser(testCitizenId)).length;
      expect(certCountAfter, equals(1)); // Zero duplicates!
    });

    test('Certificate snapshot accurately captures authoritative complaint counts', () async {
      // Add 2 verified complaints and 1 resolved complaint
      complaintRepo.setComplaints([
        ComplaintModel(
          id: 'c1',
          citizenId: testCitizenId,
          ticketNumber: 'CF-2026-C1',
          title: 'Issue 1',
          description: 'Desc',
          category: CivicCategory.defaultCategories.first,
          status: ComplaintStatus.resolved,
          priority: ComplaintPriority.high,
          location: const CivicLocation(latitude: 19.076, longitude: 72.877, address: 'Mumbai'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          evidenceVerificationStatus: 'passed',
        ),
        ComplaintModel(
          id: 'c2',
          citizenId: testCitizenId,
          ticketNumber: 'CF-2026-C2',
          title: 'Issue 2',
          description: 'Desc',
          category: CivicCategory.defaultCategories.first,
          status: ComplaintStatus.verified,
          priority: ComplaintPriority.medium,
          location: const CivicLocation(latitude: 19.076, longitude: 72.877, address: 'Mumbai'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          evidenceVerificationStatus: 'passed',
        ),
      ]);

      final result = await issuanceService.issueLevelCertificate(
        citizenId: testCitizenId,
        requestedLevel: CivicLevel.forPoints(320),
      );

      expect(result.granted, isTrue);
      expect(result.certificate!.verifiedComplaintsAtIssue, equals(2));
      expect(result.certificate!.resolvedComplaintsAtIssue, equals(1));
    });

    test('Revocation Support: Revoking a certificate sets status to revoked and stores reason', () async {
      final result = await issuanceService.issueLevelCertificate(
        citizenId: testCitizenId,
        requestedLevel: CivicLevel.forPoints(320),
      );
      final certId = result.certificate!.certificateId;

      // Revoke certificate
      await issuanceService.revokeCertificate(
        certId,
        reason: 'Violation of community verification standards',
      );

      final updated = await certRepo.getCertificateById(certId);
      expect(updated, isNotNull);
      expect(updated!.status, equals('revoked'));
      expect(updated.isValid, isFalse);
      expect(updated.isRevoked, isTrue);
      expect(updated.revocationReason, contains('Violation of community verification standards'));
      expect(updated.revokedAt, isNotNull);
    });

    testWidgets('MyCertificatesSection renders claimed certificates with valid badge and view modal', (tester) async {
      final sampleCert = CivicCertificate(
        certificateId: 'cert_123',
        recipientUid: testCitizenId,
        recipientDisplayName: 'Devendra Joshi',
        certificateType: 'civic_level_tier',
        certificateTitle: 'Civic Champion Certificate of Recognition',
        civicLevel: 'Level 3 • Civic Champion',
        pointsAtIssue: 320,
        verifiedComplaintsAtIssue: 5,
        resolvedComplaintsAtIssue: 3,
        achievementReason: 'Awarded for exceptional neighborhood contribution.',
        issuedAt: DateTime.now(),
        status: 'valid',
        verificationSlug: 'v_testslug12345678901234',
        pdfStoragePath: 'civic-certificates/cert_123/certificate.pdf',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyCertificatesSection(
              certificates: [sampleCert],
              user: const UserModel(
                id: testCitizenId,
                fullName: 'Devendra Joshi',
                email: 'devendra@civicfix.org',
                phone: '+919876543210',
                role: 'citizen',
                civicPoints: 320,
              ),
              onCertificateGenerated: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Certificate Card
      expect(find.text('My Certificates'), findsOneWidget);
      expect(find.text('Civic Champion Certificate of Recognition'), findsOneWidget);
      expect(find.text('Level 3 • Civic Champion'), findsOneWidget);
      expect(find.text('VALID'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      // Tap View to open details dialog
      await tester.tap(find.text('View'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Details Dialog
      expect(find.text('Awarded to Devendra Joshi'), findsOneWidget);
      expect(find.text('Scan to Verify Authenticity'), findsOneWidget);
      expect(find.text('+320'), findsOneWidget);
    });
  });
}
