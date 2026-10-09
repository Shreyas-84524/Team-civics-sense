import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/certificate_model.dart';
import '../models/complaint_model.dart';
import '../models/reward_model.dart';
import '../repositories/certificate_repository.dart';
import '../repositories/complaint_repository.dart';
import '../repositories/repository_locator.dart';
import '../repositories/rewards_repository.dart';
import '../repositories/user_repository.dart';
import 'achievement_evaluator.dart';
import 'certificate_pdf_generator.dart';

/// Result returned from requesting certificate issuance.
class CertificateIssuanceResult {
  final bool granted;
  final CivicCertificate? certificate;
  final String reason;
  final Uint8List? pdfBytes;

  const CertificateIssuanceResult({
    required this.granted,
    this.certificate,
    required this.reason,
    this.pdfBytes,
  });

  @override
  String toString() => 'CertificateIssuanceResult(granted: $granted, cert: ${certificate?.certificateId}, reason: $reason)';
}

/// Centralized, secure backend certificate issuance & eligibility validator.
class CertificateIssuanceService {
  static CertificateIssuanceService? _instance;
  static CertificateIssuanceService get instance => _instance ??= CertificateIssuanceService();

  final CertificateRepository? _certificateRepository;
  final UserRepository? _userRepository;
  final ComplaintRepository? _complaintRepository;
  final RewardsRepository? _rewardsRepository;

  CertificateIssuanceService({
    CertificateRepository? certificateRepository,
    UserRepository? userRepository,
    ComplaintRepository? complaintRepository,
    RewardsRepository? rewardsRepository,
  })  : _certificateRepository = certificateRepository,
        _userRepository = userRepository,
        _complaintRepository = complaintRepository,
        _rewardsRepository = rewardsRepository;

  CertificateRepository get _certRepo =>
      _certificateRepository ?? RepositoryLocator.certificateRepository;
  UserRepository get _userRepo =>
      _userRepository ?? RepositoryLocator.userRepository;
  ComplaintRepository get _complaintRepo =>
      _complaintRepository ?? RepositoryLocator.complaintRepository;
  RewardsRepository get _rewardsRepo =>
      _rewardsRepository ?? RepositoryLocator.rewardsRepository;

  // ===========================================================================
  // ELIGIBILITY EVALUATION (TRUSTED BACKEND LOGIC)
  // ===========================================================================

  /// Checks if a citizen is eligible for a Civic Level Tier certificate.
  /// Minimum tier for official certificate is Level 2 (Civic Contributor • 100+ points).
  Future<bool> isEligibleForLevelCertificate({
    required String citizenId,
    required CivicLevel targetLevel,
  }) async {
    if (targetLevel.number < 2) return false; // Level 1 is starter tier

    final user = await _userRepo.getCurrentUser();
    if (user.id != citizenId) return false;

    // Must have authoritative points >= target level minimum
    return user.civicPoints >= targetLevel.minimum;
  }

  /// Checks if a citizen is eligible for an Achievement Milestone certificate.
  Future<bool> isEligibleForAchievementCertificate({
    required String citizenId,
    required String achievementId,
  }) async {
    final user = await _userRepo.getCurrentUser();
    if (user.id != citizenId) return false;

    final complaints = await _complaintRepo.getCitizenComplaints(citizenId);
    final data = await _rewardsRepo.getRewardData(citizenId);

    final evaluated = AchievementEvaluator.evaluateAchievements(
      user: user,
      complaints: complaints,
      existingAchievements: data.achievements,
    );

    final target = evaluated.firstWhere((a) => a.id == achievementId, orElse: () => CivicAchievement.defaultAchievements().first);
    return target.isUnlocked;
  }

  // ===========================================================================
  // IDEMPOTENT CERTIFICATE ISSUANCE
  // ===========================================================================

  /// Issues an official Civic Level Tier certificate idempotently.
  Future<CertificateIssuanceResult> issueLevelCertificate({
    required String citizenId,
    CivicLevel? requestedLevel,
    String baseUrl = CertificatePdfGenerator.defaultBaseUrl,
  }) async {
    final user = await _userRepo.getCurrentUser();
    if (user.id != citizenId) {
      return const CertificateIssuanceResult(
        granted: false,
        reason: 'Unauthorized: citizen identity mismatch',
      );
    }

    final effectivePoints = user.civicPoints;
    final currentLevel = CivicLevel.forPoints(effectivePoints);
    final targetLevel = requestedLevel ?? currentLevel;

    // 1. Eligibility Check
    if (targetLevel.number < 2 || effectivePoints < targetLevel.minimum) {
      return CertificateIssuanceResult(
        granted: false,
        reason: 'Ineligible: Requires at least ${targetLevel.minimum} Civic Points for ${targetLevel.title} (Current: $effectivePoints pts)',
      );
    }

    final milestoneKey = 'level_${targetLevel.number}';
    final certificateId = CivicCertificate.generateDeterministicId(
      recipientUid: citizenId,
      certificateType: 'civic_level_tier',
      milestoneKey: milestoneKey,
    );

    // 2. Idempotency Check: already issued?
    final existingCert = await _certRepo.getCertificateById(certificateId);
    if (existingCert != null) {
      final pdfBytes = await CertificatePdfGenerator.generateCertificatePdf(
        certificate: existingCert,
        baseUrl: baseUrl,
      );
      return CertificateIssuanceResult(
        granted: true,
        certificate: existingCert,
        pdfBytes: pdfBytes,
        reason: 'Certificate already issued for ${targetLevel.title}',
      );
    }

    // 3. Collect authoritative snapshot metrics
    final complaints = await _complaintRepo.getCitizenComplaints(citizenId);
    final verifiedCount = complaints.where((c) =>
        c.isEvidenceVerified ||
        c.departmentVerificationStatus == 'passed' ||
        c.status == ComplaintStatus.verified ||
        c.status == ComplaintStatus.assigned ||
        c.status == ComplaintStatus.inProgress ||
        c.status == ComplaintStatus.resolved ||
        c.status == ComplaintStatus.closed).length;
    final resolvedCount = complaints.where((c) =>
        c.status == ComplaintStatus.resolved ||
        c.status == ComplaintStatus.closed).length;

    final issuedAt = DateTime.now();
    final slug = CivicCertificate.generateVerificationSlug(
      recipientUid: citizenId,
      certificateType: 'civic_level_tier',
      milestoneKey: milestoneKey,
      issuedAt: issuedAt,
    );

    final storagePath = 'civic-certificates/$certificateId/certificate.pdf';
    final displayName = user.fullName.isNotEmpty ? user.fullName : 'Civic Contributor';

    // 4. Create Certificate Record
    final certificate = CivicCertificate(
      certificateId: certificateId,
      recipientUid: citizenId,
      recipientDisplayName: displayName,
      certificateType: 'civic_level_tier',
      certificateTitle: '${targetLevel.title} Certificate of Recognition',
      civicLevel: 'Level ${targetLevel.number} • ${targetLevel.title}',
      pointsAtIssue: effectivePoints,
      verifiedComplaintsAtIssue: verifiedCount,
      resolvedComplaintsAtIssue: resolvedCount,
      achievementReason: 'Awarded for achieving ${targetLevel.title} (${targetLevel.number}) with $effectivePoints Civic Points.',
      issuedAt: issuedAt,
      status: 'valid',
      verificationSlug: slug,
      pdfStoragePath: storagePath,
      certificateVersion: 1,
      createdAt: issuedAt,
      metadata: {
        'levelNumber': targetLevel.number,
        'levelTitle': targetLevel.title,
      },
    );

    // 5. Generate PDF
    final pdfBytes = await CertificatePdfGenerator.generateCertificatePdf(
      certificate: certificate,
      baseUrl: baseUrl,
    );

    // 6. Persist Certificate
    await _certRepo.saveCertificate(certificate);

    return CertificateIssuanceResult(
      granted: true,
      certificate: certificate,
      pdfBytes: pdfBytes,
      reason: 'Successfully issued ${targetLevel.title} Certificate of Recognition',
    );
  }

  /// Issues an official Achievement Milestone certificate idempotently.
  Future<CertificateIssuanceResult> issueAchievementCertificate({
    required String citizenId,
    required String achievementId,
    String baseUrl = CertificatePdfGenerator.defaultBaseUrl,
  }) async {
    final user = await _userRepo.getCurrentUser();
    if (user.id != citizenId) {
      return const CertificateIssuanceResult(
        granted: false,
        reason: 'Unauthorized: citizen identity mismatch',
      );
    }

    final isEligible = await isEligibleForAchievementCertificate(
      citizenId: citizenId,
      achievementId: achievementId,
    );

    if (!isEligible) {
      return CertificateIssuanceResult(
        granted: false,
        reason: 'Ineligible: Achievement $achievementId has not yet been unlocked',
      );
    }

    final certificateId = CivicCertificate.generateDeterministicId(
      recipientUid: citizenId,
      certificateType: 'achievement_milestone',
      milestoneKey: achievementId,
    );

    // Idempotency Check
    final existingCert = await _certRepo.getCertificateById(certificateId);
    if (existingCert != null) {
      final pdfBytes = await CertificatePdfGenerator.generateCertificatePdf(
        certificate: existingCert,
        baseUrl: baseUrl,
      );
      return CertificateIssuanceResult(
        granted: true,
        certificate: existingCert,
        pdfBytes: pdfBytes,
        reason: 'Certificate already issued for achievement $achievementId',
      );
    }

    final complaints = await _complaintRepo.getCitizenComplaints(citizenId);
    final verifiedCount = complaints.where((c) =>
        c.isEvidenceVerified ||
        c.departmentVerificationStatus == 'passed' ||
        c.status == ComplaintStatus.verified ||
        c.status == ComplaintStatus.assigned ||
        c.status == ComplaintStatus.inProgress ||
        c.status == ComplaintStatus.resolved ||
        c.status == ComplaintStatus.closed).length;
    final resolvedCount = complaints.where((c) =>
        c.status == ComplaintStatus.resolved ||
        c.status == ComplaintStatus.closed).length;

    final defaultAchievements = CivicAchievement.defaultAchievements();
    final badge = defaultAchievements.firstWhere((a) => a.id == achievementId, orElse: () => defaultAchievements.first);

    final issuedAt = DateTime.now();
    final slug = CivicCertificate.generateVerificationSlug(
      recipientUid: citizenId,
      certificateType: 'achievement_milestone',
      milestoneKey: achievementId,
      issuedAt: issuedAt,
    );

    final storagePath = 'civic-certificates/$certificateId/certificate.pdf';
    final displayName = user.fullName.isNotEmpty ? user.fullName : 'Civic Contributor';
    final currentLevel = CivicLevel.forPoints(user.civicPoints);

    final certificate = CivicCertificate(
      certificateId: certificateId,
      recipientUid: citizenId,
      recipientDisplayName: displayName,
      certificateType: 'achievement_milestone',
      certificateTitle: '${badge.title} Achievement Certificate',
      civicLevel: 'Level ${currentLevel.number} • ${currentLevel.title}',
      pointsAtIssue: user.civicPoints,
      verifiedComplaintsAtIssue: verifiedCount,
      resolvedComplaintsAtIssue: resolvedCount,
      achievementReason: badge.howToUnlock,
      issuedAt: issuedAt,
      status: 'valid',
      verificationSlug: slug,
      pdfStoragePath: storagePath,
      certificateVersion: 1,
      createdAt: issuedAt,
      metadata: {
        'achievementId': achievementId,
        'badgeTitle': badge.title,
      },
    );

    final pdfBytes = await CertificatePdfGenerator.generateCertificatePdf(
      certificate: certificate,
      baseUrl: baseUrl,
    );

    await _certRepo.saveCertificate(certificate);

    return CertificateIssuanceResult(
      granted: true,
      certificate: certificate,
      pdfBytes: pdfBytes,
      reason: 'Successfully issued ${badge.title} Achievement Certificate',
    );
  }

  /// Revokes an existing certificate with a recorded reason.
  Future<void> revokeCertificate(String certificateId, {String? reason}) async {
    await _certRepo.updateCertificateStatus(
      certificateId,
      status: 'revoked',
      reason: reason ?? 'Certificate revoked by administrative authority',
    );
  }
}
