import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/certificate_model.dart';
import '../../../core/models/reward_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/certificate_issuance_service.dart';
import '../../../core/widgets/civic_fix_card.dart';
import '../../../core/widgets/section_header.dart';

/// Section rendering the citizen's issued verifiable certificates with issuance triggers.
class MyCertificatesSection extends StatelessWidget {
  final List<CivicCertificate> certificates;
  final UserModel user;
  final VoidCallback onCertificateGenerated;

  const MyCertificatesSection({
    super.key,
    required this.certificates,
    required this.user,
    required this.onCertificateGenerated,
  });

  @override
  Widget build(BuildContext context) {
    final currentLevel = CivicLevel.forPoints(user.civicPoints);
    final isEligibleForLevelCert = currentLevel.number >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: SectionHeader(
                title: 'My Certificates',
                subtitle: 'Verifiable proof of your community impact & civic milestones',
              ),
            ),
            if (isEligibleForLevelCert)
              TextButton.icon(
                onPressed: () => _handleGenerateLevelCertificate(context, currentLevel),
                icon: const Icon(Icons.workspace_premium_outlined, size: 18, color: CivicFixColors.secondary),
                label: const Text(
                  'Claim Certificate',
                  style: TextStyle(
                    color: CivicFixColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        CivicFixSpacing.vSpaceSm,

        if (certificates.isEmpty)
          CivicFixCard(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.card_membership_rounded,
                    size: 36,
                    color: CivicFixColors.secondaryText.withValues(alpha: 0.5),
                  ),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'No certificates claimed yet',
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      color: CivicFixColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    isEligibleForLevelCert
                        ? 'You have reached ${currentLevel.title}! Tap "Claim Certificate" to generate your official PDF.'
                        : 'Reach Level 2 (Civic Contributor • 100+ pts) or unlock achievement badges to earn official certificates.',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: certificates.length,
            separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
            itemBuilder: (context, index) {
              final cert = certificates[index];
              return _buildCertificateCard(context, cert);
            },
          ),
      ],
    );
  }

  Widget _buildCertificateCard(BuildContext context, CivicCertificate cert) {
    final isValid = cert.isValid;

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Certificate Icon Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isValid
                  ? CivicFixColors.primary.withValues(alpha: 0.1)
                  : CivicFixColors.error.withValues(alpha: 0.1),
              borderRadius: CivicFixRadius.chipRadius,
              border: Border.all(
                color: isValid
                    ? CivicFixColors.primary.withValues(alpha: 0.25)
                    : CivicFixColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              isValid ? Icons.verified_rounded : Icons.cancel_outlined,
              color: isValid ? CivicFixColors.primary : CivicFixColors.error,
              size: 26,
            ),
          ),
          CivicFixSpacing.hSpaceMd,

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.certificateTitle,
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: CivicFixColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  cert.civicLevel,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: CivicFixColors.secondary,
                    fontSize: 11,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Row(
                  children: [
                    Text(
                      'Issued: ${_formatDate(cert.issuedAt)}',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isValid
                            ? CivicFixColors.statusResolvedBg
                            : CivicFixColors.statusRejectedBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isValid ? 'VALID' : 'REVOKED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isValid
                              ? CivicFixColors.secondaryDark
                              : CivicFixColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // View Certificate Button
          ElevatedButton(
            onPressed: () => _showCertificateDetailsDialog(context, cert),
            style: ElevatedButton.styleFrom(
              backgroundColor: CivicFixColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.chipRadius),
            ),
            child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerateLevelCertificate(BuildContext context, CivicLevel level) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('Generating verifiable Civic Certificate...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );

    final result = await CertificateIssuanceService.instance.issueLevelCertificate(
      citizenId: user.id,
      requestedLevel: level,
    );

    if (result.granted && result.certificate != null) {
      scaffold.showSnackBar(
        SnackBar(
          backgroundColor: CivicFixColors.secondary,
          content: Text('Certificate Ready: ${result.certificate!.certificateTitle}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      onCertificateGenerated();
    } else {
      scaffold.showSnackBar(
        SnackBar(
          backgroundColor: CivicFixColors.error,
          content: Text(result.reason),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCertificateDetailsDialog(BuildContext context, CivicCertificate cert) {
    final qrUrl = '${AppConstants.publicBaseUrl}/verify/${cert.verificationSlug}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: CivicFixRadius.cardRadius),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium_rounded, color: CivicFixColors.primary, size: 36),
              CivicFixSpacing.vSpaceSm,
              Text(
                cert.certificateTitle,
                textAlign: TextAlign.center,
                style: CivicFixTypographyTokens.titleMd,
              ),
              CivicFixSpacing.vSpaceSm,
              Text(
                'Awarded to ${cert.recipientDisplayName}',
                style: CivicFixTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CivicFixColors.primaryText,
                ),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                cert.civicLevel,
                style: CivicFixTypography.captionMedium.copyWith(color: CivicFixColors.secondary),
              ),
              CivicFixSpacing.vSpaceMd,

              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: CivicFixColors.border),
                  borderRadius: CivicFixRadius.cardRadius,
                ),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: QrImageView(
                        data: qrUrl,
                        version: QrVersions.auto,
                        size: 140,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    const Text(
                      'Scan to Verify Authenticity',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: CivicFixColors.secondaryText),
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceMd,

              // Snapshot Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatPill('Points', '+${cert.pointsAtIssue}'),
                  _buildStatPill('Verified', '${cert.verifiedComplaintsAtIssue}'),
                  _buildStatPill('Resolved', '${cert.resolvedComplaintsAtIssue}'),
                ],
              ),
              CivicFixSpacing.vSpaceMd,

              Text(
                cert.achievementReason,
                style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              CivicFixSpacing.vSpaceSm,
              Text(
                'Certificate ID: ${cert.certificateId}\nIssued: ${_formatDate(cert.issuedAt)}',
                style: const TextStyle(fontSize: 10, color: CivicFixColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              CivicFixSpacing.vSpaceMd,
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CivicFixColors.surfaceMuted,
        borderRadius: CivicFixRadius.chipRadius,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: CivicFixColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: CivicFixColors.secondaryText),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
