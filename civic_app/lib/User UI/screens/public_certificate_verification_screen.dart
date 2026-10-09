import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/public_certificate_model.dart';
import '../../core/services/public_certificate_verification_service.dart';
import '../../core/widgets/civic_fix_card.dart';

/// Publicly accessible verification portal for CivicFix achievement certificates.
///
/// Operates without authentication, fetching and rendering only safe public data.
class PublicCertificateVerificationScreen extends StatefulWidget {
  final String verificationSlug;
  final PublicCertificateVerificationService? verificationService;

  const PublicCertificateVerificationScreen({
    super.key,
    required this.verificationSlug,
    this.verificationService,
  });

  @override
  State<PublicCertificateVerificationScreen> createState() =>
      _PublicCertificateVerificationScreenState();
}

class _PublicCertificateVerificationScreenState
    extends State<PublicCertificateVerificationScreen> {
  late final PublicCertificateVerificationService _service;
  PublicVerificationResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.verificationService ?? PublicCertificateVerificationService();
    _verify();
  }

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    final result = await _service.verifyCertificate(widget.verificationSlug);
    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.canvas,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: CivicFixColors.primary, size: 22),
            CivicFixSpacing.hSpaceSm,
            const Text(
              'CivicFix Verification Portal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: CivicFixColors.primaryText,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CivicFixColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _isLoading
                ? _buildLoadingState()
                : _result != null
                    ? _buildResultContent(_result!)
                    : _buildInvalidState(null),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CivicFixSpacing.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(CivicFixColors.primary),
              ),
            ),
            CivicFixSpacing.vSpaceLg,
            Text(
              'Verifying Certificate Authenticity...',
              style: CivicFixTypography.h3,
              textAlign: TextAlign.center,
            ),
            CivicFixSpacing.vSpaceSm,
            Text(
              'Validating cryptographic verification slug with municipal records.',
              style: CivicFixTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(PublicVerificationResult result) {
    switch (result.state) {
      case CertificateValidationState.valid:
        return _buildValidState(result.certificate!);
      case CertificateValidationState.revoked:
        return _buildRevokedState(result.certificate);
      case CertificateValidationState.invalid:
        return _buildInvalidState(result.message);
      case CertificateValidationState.error:
        return _buildErrorState(result.message);
      case CertificateValidationState.loading:
        return _buildLoadingState();
    }
  }

  // ===========================================================================
  // 1. VALID CERTIFICATE STATE
  // ===========================================================================
  Widget _buildValidState(PublicCertificateData cert) {
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trust Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CivicFixColors.successLight,
              border: Border.all(color: CivicFixColors.successBorder),
              borderRadius: CivicFixRadius.cardRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: CivicFixColors.success, size: 28),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Certificate Verified',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CivicFixColors.success,
                        ),
                      ),
                      Text(
                        'Authentic CivicFix Achievement Record',
                        style: CivicFixTypography.bodySmall.copyWith(color: CivicFixColors.success),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CivicFixColors.success,
                    borderRadius: CivicFixRadius.chipRadius,
                  ),
                  child: const Text(
                    'VALID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Certificate Presentation Card
          CivicFixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Seal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CivicFixColors.secondaryContainer,
                        borderRadius: CivicFixRadius.buttonRadius,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: CivicFixColors.primary,
                        size: 32,
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert.certificateTitle,
                            style: CivicFixTypography.h2.copyWith(fontSize: 18),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Awarded to ${cert.recipientDisplayName}',
                            style: CivicFixTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CivicFixColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,
                const Divider(height: 1, color: CivicFixColors.border),
                CivicFixSpacing.vSpaceMd,

                // Metadata Rows
                _buildInfoRow('Recipient', cert.recipientDisplayName),
                CivicFixSpacing.vSpaceSm,
                _buildInfoRow('Civic Level / Tier', cert.civicLevel),
                CivicFixSpacing.vSpaceSm,
                _buildInfoRow('Certificate ID', cert.certificateId),
                CivicFixSpacing.vSpaceSm,
                _buildInfoRow('Date of Issue', dateFormat.format(cert.issuedAt)),
                CivicFixSpacing.vSpaceSm,
                _buildInfoRow('Status', 'VALID / ACTIVE', isStatusValid: true),
                CivicFixSpacing.vSpaceLg,

                // Snapshot Metrics
                const Text(
                  'Verified Civic Impact at Issue',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CivicFixColors.primaryText),
                ),
                CivicFixSpacing.vSpaceSm,
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile('Civic Points', '+${cert.pointsAtIssue}', Icons.stars_rounded),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: _buildMetricTile('Verified Reports', '${cert.verifiedComplaintsAtIssue}', Icons.fact_check_rounded),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: _buildMetricTile('Resolved Reports', '${cert.resolvedComplaintsAtIssue}', Icons.task_alt_rounded),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceLg,

                // Why Awarded
                const Text(
                  'Why this certificate was awarded',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CivicFixColors.primaryText),
                ),
                CivicFixSpacing.vSpaceXs,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CivicFixColors.surfaceContainer,
                    borderRadius: CivicFixRadius.chipRadius,
                    border: Border.all(color: CivicFixColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.achievementReason,
                        style: CivicFixTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        cert.awardImportance,
                        style: CivicFixTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Municipal Authority Footer
          _buildAuthorityFooter(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. REVOKED CERTIFICATE STATE
  // ===========================================================================
  Widget _buildRevokedState(PublicCertificateData? cert) {
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Revocation Warning Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CivicFixColors.errorLight,
              border: Border.all(color: CivicFixColors.error),
              borderRadius: CivicFixRadius.cardRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gpp_bad_rounded, color: CivicFixColors.error, size: 32),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CERTIFICATE REVOKED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CivicFixColors.error,
                          letterSpacing: 0.5,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      const Text(
                        'This certificate is no longer considered valid by CivicFix.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CivicFixColors.error,
                        ),
                      ),
                      if (cert?.revocationReason != null && cert!.revocationReason!.isNotEmpty) ...[
                        CivicFixSpacing.vSpaceXs,
                        Text(
                          'Reason: ${cert.revocationReason}',
                          style: const TextStyle(fontSize: 12, color: CivicFixColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          if (cert != null) ...[
            CivicFixCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historical Record Reference',
                    style: CivicFixTypography.h3.copyWith(fontSize: 16),
                  ),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'The following achievement was previously recorded but has been invalidated by municipal administration:',
                    style: CivicFixTypography.bodySmall,
                  ),
                  CivicFixSpacing.vSpaceMd,
                  const Divider(height: 1, color: CivicFixColors.border),
                  CivicFixSpacing.vSpaceMd,
                  _buildInfoRow('Recipient', cert.recipientDisplayName),
                  CivicFixSpacing.vSpaceSm,
                  _buildInfoRow('Original Title', cert.certificateTitle),
                  CivicFixSpacing.vSpaceSm,
                  _buildInfoRow('Certificate ID', cert.certificateId),
                  CivicFixSpacing.vSpaceSm,
                  _buildInfoRow('Date of Original Issue', dateFormat.format(cert.issuedAt)),
                  if (cert.revokedAt != null) ...[
                    CivicFixSpacing.vSpaceSm,
                    _buildInfoRow('Date of Revocation', dateFormat.format(cert.revokedAt!)),
                  ],
                  CivicFixSpacing.vSpaceSm,
                  _buildInfoRow('Current Status', 'REVOKED (INVALID)', isStatusValid: false),
                ],
              ),
            ),
            CivicFixSpacing.vSpaceLg,
          ],

          _buildAuthorityFooter(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. INVALID / NOT FOUND STATE
  // ===========================================================================
  Widget _buildInvalidState(String? customMessage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CivicFixColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: CivicFixColors.border),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: CivicFixColors.warning,
              size: 48,
            ),
          ),
          CivicFixSpacing.vSpaceLg,
          Text(
            'Certificate Not Verified',
            style: CivicFixTypography.h2,
            textAlign: TextAlign.center,
          ),
          CivicFixSpacing.vSpaceSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              customMessage ??
                  'No valid CivicFix certificate was found for this verification reference.',
              style: CivicFixTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CivicFixColors.surfaceContainer,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.border),
            ),
            child: const Text(
              'Please ensure the QR code was scanned directly from an authentic CivicFix document or verification URL.',
              style: TextStyle(fontSize: 12, color: CivicFixColors.secondaryText),
              textAlign: TextAlign.center,
            ),
          ),
          CivicFixSpacing.vSpaceXl,
          _buildAuthorityFooter(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. ERROR STATE
  // ===========================================================================
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CivicFixSpacing.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: CivicFixColors.textSecondary, size: 48),
            CivicFixSpacing.vSpaceLg,
            Text(
              'Verification Connectivity Error',
              style: CivicFixTypography.h3,
              textAlign: TextAlign.center,
            ),
            CivicFixSpacing.vSpaceSm,
            Text(
              message,
              style: CivicFixTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            CivicFixSpacing.vSpaceLg,
            ElevatedButton.icon(
              onPressed: _verify,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Verification'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildInfoRow(String label, String value, {bool? isStatusValid}) {
    Color valueColor = CivicFixColors.primaryText;
    if (isStatusValid != null) {
      valueColor = isStatusValid ? CivicFixColors.success : CivicFixColors.error;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CivicFixColors.secondaryText),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: CivicFixColors.surfaceContainer,
        borderRadius: CivicFixRadius.chipRadius,
        border: Border.all(color: CivicFixColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: CivicFixColors.primary, size: 20),
          CivicFixSpacing.vSpaceXs,
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: CivicFixColors.primaryText),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: CivicFixColors.secondaryText),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorityFooter() {
    return Column(
      children: [
        const Divider(height: 1, color: CivicFixColors.border),
        CivicFixSpacing.vSpaceMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_rounded, color: CivicFixColors.secondaryText, size: 16),
            CivicFixSpacing.hSpaceSm,
            const Text(
              'Official CivicFix Municipal Governance Portal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CivicFixColors.secondaryText),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceXs,
        const Text(
          'Valid for verification by educational institutions, employers, and civic organizations.',
          style: TextStyle(fontSize: 10, color: CivicFixColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
