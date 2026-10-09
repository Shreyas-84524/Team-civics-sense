import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Manual AI Fallback Verification" Section for Ward Department Lead Operations Center.
/// Displays complaints where Gemini AI verification was temporarily unavailable,
/// requiring the Department Lead to confirm or transfer the grievance.
class DepartmentLeadManualVerificationSection extends StatelessWidget {
  final List<ComplaintModel> manualVerificationComplaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel> onReviewComplaint;

  const DepartmentLeadManualVerificationSection({
    super.key,
    required this.manualVerificationComplaints,
    this.isLoading = false,
    required this.onReviewComplaint,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);
    final count = manualVerificationComplaints.length;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: count > 0
              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
              : GovtThemeTokens.border,
        ),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI FALLBACK — MANUAL DEPARTMENT REVIEW',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Grievances requiring manual departmental confirmation due to temporary AI unavailability',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: count > 0
                      ? const Color(0xFFFEF3C7)
                      : GovtThemeTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: count > 0
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                        : GovtThemeTokens.borderLight,
                  ),
                ),
                child: Text(
                  '$count Awaiting Decision',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: count > 0 ? const Color(0xFFB45309) : GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceMd,

          // Notice Banner
          if (count > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                  CivicFixSpacing.hSpaceSm,
                  Expanded(
                    child: Text(
                      'These complaints were received while the AI verification engine was temporarily offline. '
                      'Review the grievance details to confirm it belongs to your department or transfer it to another BMC department. SLA is active.',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          CivicFixSpacing.vSpaceMd,

          // Complaint List or Empty State
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (manualVerificationComplaints.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GovtThemeTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF10B981),
                    size: 36,
                  ),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'No Pending AI Fallback Reviews',
                    style: CivicFixTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    'All incoming grievances have been processed automatically by the Gemini AI pipeline.',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: manualVerificationComplaints.length,
              separatorBuilder: (_, index) => CivicFixSpacing.vSpaceSm,
              itemBuilder: (context, index) {
                final complaint = manualVerificationComplaints[index];
                return _buildComplaintCard(context, complaint, isMobile);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(
    BuildContext context,
    ComplaintModel complaint,
    bool isMobile,
  ) {
    final ticketNo = complaint.ticketNumber.isNotEmpty
        ? complaint.ticketNumber
        : complaint.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#$ticketNo',
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AI Offline Fallback',
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'SLA Active: ${_formatElapsed(complaint.slaStartedAt)}',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.textMuted,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text(
            complaint.title,
            style: CivicFixTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            complaint.description,
            style: CivicFixTypography.bodyMedium.copyWith(
              color: GovtThemeTokens.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          CivicFixSpacing.vSpaceSm,
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: GovtThemeTokens.textMuted),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  complaint.location.address,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              ElevatedButton.icon(
                onPressed: () => onReviewComplaint(complaint),
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Review & Decide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatElapsed(DateTime startTime) {
    final diff = DateTime.now().difference(startTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
