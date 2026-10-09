import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../../core/widgets/supabase_evidence_image.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Work Awaiting Verification" Section for Ward Department Lead Operations Center.
/// Displays complaints where the field crew technician has submitted completion evidence
/// and the Lead must review, certify resolution, or return for rework.
class DepartmentLeadAwaitingVerificationSection extends StatelessWidget {
  final List<ComplaintModel> awaitingVerificationComplaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel> onReviewWork;

  const DepartmentLeadAwaitingVerificationSection({
    super.key,
    required this.awaitingVerificationComplaints,
    this.isLoading = false,
    required this.onReviewWork,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: awaitingVerificationComplaints.isNotEmpty
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORK AWAITING VERIFICATION',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Field crew submitted completion reports ready for administrative review & sign-off',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: awaitingVerificationComplaints.isNotEmpty
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                      : GovtThemeTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: awaitingVerificationComplaints.isNotEmpty
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                        : GovtThemeTokens.borderLight,
                  ),
                ),
                child: Text(
                  '${awaitingVerificationComplaints.length} Awaiting Sign-off',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: awaitingVerificationComplaints.isNotEmpty
                        ? const Color(0xFF7C3AED)
                        : GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (awaitingVerificationComplaints.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: CivicFixSpacing.lg, vertical: CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.task_alt_rounded,
                      size: 40, color: Color(0xFF10B981)),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'No Work Awaiting Verification',
                    style: CivicFixTypography.bodyMedium.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'All completed field jobs have been verified and certified closed.',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: awaitingVerificationComplaints.length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (ctx, i) {
                final c = awaitingVerificationComplaints[i];
                return _buildMobileCard(c);
              },
            )
          else
            _buildDesktopTable(context),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final now = DateTime.now();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2), // Complaint
          1: FlexColumnWidth(1.6), // Crew Member
          2: FlexColumnWidth(1.2), // Before Evidence
          3: FlexColumnWidth(1.2), // After Evidence
          4: FlexColumnWidth(1.3), // Completed At
          5: FlexColumnWidth(1.3), // SLA Status
          6: FlexColumnWidth(1.4), // Primary Action
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
            ),
            children: [
              _tableHeader('COMPLAINT'),
              _tableHeader('CREW MEMBER'),
              _tableHeader('BEFORE'),
              _tableHeader('AFTER'),
              _tableHeader('COMPLETED AT'),
              _tableHeader('SLA STATUS'),
              _tableHeader('ACTION'),
            ],
          ),
          ...awaitingVerificationComplaints.map((c) {
            final elapsed = now.difference(c.slaStartedAt).inHours;
            final isBreached = elapsed > 48;

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight),
                ),
              ),
              children: [
                // Complaint
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        c.title,
                        style: CivicFixTypography.bodySmall.copyWith(
                          color: GovtThemeTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Crew Member
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    c.assignedTo ?? c.assignedCrewMemberId ?? 'Field Crew',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Before Evidence
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: GovtThemeTokens.borderLight),
                    ),
                    child: (c.imageUrls.isNotEmpty || (c.beforeWorkPhoto != null && c.beforeWorkPhoto!.isNotEmpty))
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SupabaseEvidenceImage(
                              imagePath: c.beforeWorkPhoto ?? c.imageUrls.first,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image_not_supported_outlined,
                            size: 18, color: GovtThemeTokens.textMuted),
                  ),
                ),

                // After Evidence
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: (c.afterWorkPhoto != null && c.afterWorkPhoto!.isNotEmpty) || c.imageUrls.length > 1
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SupabaseEvidenceImage(
                              imagePath: c.afterWorkPhoto ?? (c.imageUrls.length > 1 ? c.imageUrls[1] : ''),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: Color(0xFF10B981)),
                  ),
                ),

                // Completed At
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${c.updatedAt.day}/${c.updatedAt.month}/${c.updatedAt.year}\n${c.updatedAt.hour}:${c.updatedAt.minute.toString().padLeft(2, '0')}',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),

                // SLA Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isBreached
                          ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isBreached ? 'Breached' : 'Within SLA',
                      style: CivicFixTypography.caption.copyWith(
                        color: isBreached
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

                // Action
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.fact_check_outlined, size: 14),
                    label: const Text('REVIEW WORK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      textStyle: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => onReviewWork(c),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCard(ComplaintModel c) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.fact_check_outlined, size: 12),
                label: const Text('REVIEW WORK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                onPressed: () => onReviewWork(c),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            c.title,
            style: CivicFixTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Crew: ${c.assignedTo ?? c.assignedCrewMemberId ?? "Squad"} · Submitted: ${c.updatedAt.day}/${c.updatedAt.month}',
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md, vertical: CivicFixSpacing.sm),
      child: Text(
        text,
        style: CivicFixTypography.captionMedium.copyWith(
          color: GovtThemeTokens.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
