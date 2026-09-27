import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Zonal Escalation Center for managing escalated complaints in the DMC's zone.
class ZoneEscalationCenterSection extends StatelessWidget {
  final List<ComplaintModel> escalations;
  final bool isLoading;
  final ValueChanged<String>? onViewComplaint;

  const ZoneEscalationCenterSection({
    super.key,
    required this.escalations,
    this.isLoading = false,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
    final count = escalations.length;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: count > 0 ? GovtThemeTokens.warning.withValues(alpha: 0.4) : GovtThemeTokens.border,
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
                  color: (count > 0 ? GovtThemeTokens.warning : GovtThemeTokens.success).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: count > 0 ? GovtThemeTokens.warning : GovtThemeTokens.success,
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONAL ESCALATION CENTER',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Grievances escalated due to SLA breaches or critical emergencies requiring DMC oversight',
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
                  color: (count > 0 ? GovtThemeTokens.warning : GovtThemeTokens.success).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (count > 0 ? GovtThemeTokens.warning : GovtThemeTokens.success).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$count Escalated',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: count > 0 ? GovtThemeTokens.warning : GovtThemeTokens.success,
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
          else if (escalations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.shield_outlined, color: GovtThemeTokens.success, size: 40),
                    CivicFixSpacing.vSpaceMd,
                    Text(
                      'Zero Active Zonal Escalations',
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.success,
                      ),
                    ),
                    Text(
                      'All grievances are progressing normally through ward workflows without escalation.',
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
              itemCount: escalations.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
              itemBuilder: (context, index) {
                final c = escalations[index];
                return _buildEscalationTile(context, c);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEscalationTile(BuildContext context, ComplaintModel complaint) {
    final now = DateTime.now();
    final elapsed = now.difference(complaint.slaStartedAt).inHours;
    final isOverdue = elapsed > 48;

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
                  color: isOverdue ? GovtThemeTokens.errorLight : GovtThemeTokens.warningLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOverdue ? 'SLA EXPIRED (${elapsed}h)' : 'EMERGENCY DISPATCH',
                  style: CivicFixTypography.caption.copyWith(
                    color: isOverdue ? GovtThemeTokens.error : GovtThemeTokens.warning,
                    fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textPrimary,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Row(
            children: [
              Text(
                'Ward ${complaint.location.ward ?? complaint.wardId ?? 'N/A'} · ${complaint.effectiveDepartment}',
                style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
              ),
              const Spacer(),
              if (onViewComplaint != null)
                TextButton(
                  onPressed: () => onViewComplaint!(complaint.id),
                  child: const Text('Review Escalation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
