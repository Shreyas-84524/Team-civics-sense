import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Critical Grievances section for Zonal DMC Command Center.
/// Lists high-priority and emergency civic issues requiring zonal escalation or dispatch.
class ZoneCriticalComplaintsSection extends StatelessWidget {
  final List<ComplaintModel> criticalComplaints;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;
  final VoidCallback? onViewAllCritical;

  const ZoneCriticalComplaintsSection({
    super.key,
    required this.criticalComplaints,
    this.isLoading = false,
    this.onViewComplaint,
    this.onViewAllCritical,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: criticalComplaints.isNotEmpty
              ? GovtThemeTokens.error.withValues(alpha: 0.3)
              : GovtThemeTokens.border,
        ),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (criticalComplaints.isNotEmpty ? GovtThemeTokens.error : GovtThemeTokens.success)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emergency_rounded,
                  color: criticalComplaints.isNotEmpty ? GovtThemeTokens.error : GovtThemeTokens.success,
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL CRITICAL GRIEVANCES & HAZARDS',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'High-severity emergencies and public safety hazards within the zone',
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
                  color: (criticalComplaints.isNotEmpty ? GovtThemeTokens.error : GovtThemeTokens.success)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (criticalComplaints.isNotEmpty ? GovtThemeTokens.error : GovtThemeTokens.success)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${criticalComplaints.length} Critical',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: criticalComplaints.isNotEmpty ? GovtThemeTokens.error : GovtThemeTokens.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceLg,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (criticalComplaints.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: GovtThemeTokens.success, size: 40),
                    CivicFixSpacing.vSpaceMd,
                    Text(
                      'Zero Critical Grievances in Zone',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.success,
                      ),
                    ),
                    Text(
                      'All high and emergency priority civic issues in this zone are currently resolved.',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: criticalComplaints.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) {
                final complaint = criticalComplaints[index];
                return _buildComplaintCard(context, complaint);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, ComplaintModel complaint) {
    final now = DateTime.now();
    final elapsedHours = now.difference(complaint.slaStartedAt).inHours;
    final isBreached = elapsedHours > 48;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBreached ? GovtThemeTokens.error.withValues(alpha: 0.4) : GovtThemeTokens.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                complaint.ticketNumber,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              GovtPriorityBadge.fromPriority(complaint.priority, isCompact: true),
              CivicFixSpacing.hSpaceXs,
              GovtStatusBadge.complaint(complaint.status, isCompact: true),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isBreached ? GovtThemeTokens.errorLight : GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isBreached ? GovtThemeTokens.error.withValues(alpha: 0.3) : GovtThemeTokens.borderLight,
                  ),
                ),
                child: Text(
                  isBreached ? '$elapsedHours hrs (BREACHED)' : '$elapsedHours hrs elapsed',
                  style: CivicFixTypography.caption.copyWith(
                    color: isBreached ? GovtThemeTokens.error : GovtThemeTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text(
            complaint.title,
            style: CivicFixTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: GovtThemeTokens.textMuted),
              CivicFixSpacing.hSpaceXs,
              Text(
                'Ward ${complaint.location.ward ?? complaint.wardId ?? 'N/A'} · ${complaint.effectiveDepartment}',
                style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
              ),
              const Spacer(),
              if (onViewComplaint != null)
                TextButton(
                  onPressed: () => onViewComplaint!(complaint.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
