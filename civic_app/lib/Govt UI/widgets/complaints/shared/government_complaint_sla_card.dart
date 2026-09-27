import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../common/govt_sla_badge.dart';

/// Reusable SLA Tracking & Performance Card.
/// Shows: SLA Target, Elapsed Time, Remaining Time, Breach Warning, and Compliance State.
class GovernmentComplaintSlaCard extends StatelessWidget {
  final ComplaintModel complaint;

  const GovernmentComplaintSlaCard({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final now = DateTime.now();
    final elapsedHours = now.difference(c.slaStartedAt).inHours;
    final targetHours = c.priority == ComplaintPriority.emergency
        ? 24
        : (c.priority == ComplaintPriority.high ? 36 : 48);

    final isResolved = c.status == ComplaintStatus.resolved;
    final isBreached = !isResolved && (elapsedHours > targetHours);
    final remainingHours = (targetHours - elapsedHours).clamp(-999, targetHours);
    final progress = (elapsedHours / targetHours).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(
          color: isBreached
              ? GovtThemeTokens.alert.withValues(alpha: 0.5)
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isBreached ? GovtThemeTokens.alert : GovtThemeTokens.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: isBreached ? GovtThemeTokens.alert : GovtThemeTokens.primary,
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUTORY SLA TRACKING',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Citizen charter statutory turnaround benchmark (${targetHours}h allowed)',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GovtSlaBadge.fromDuration(
                createdAt: c.slaStartedAt,
                resolvedAt: c.resolvedAt,
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // SLA Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Elapsed: ${elapsedHours}h',
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  isResolved
                      ? 'Completed on time'
                      : (isBreached
                          ? '${(elapsedHours - targetHours)}h Overdue'
                          : '${remainingHours}h remaining'),
                  textAlign: TextAlign.end,
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isResolved
                        ? GovtThemeTokens.success
                        : (isBreached ? GovtThemeTokens.alert : GovtThemeTokens.primaryDark),
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isResolved ? 1.0 : progress,
              minHeight: 8,
              backgroundColor: GovtThemeTokens.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                isResolved
                    ? GovtThemeTokens.success
                    : (isBreached
                        ? GovtThemeTokens.alert
                        : (remainingHours <= 8 ? const Color(0xFFF97316) : GovtThemeTokens.primary)),
              ),
            ),
          ),
          CivicFixSpacing.vSpaceMd,

          // SLA Timestamps
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _slaTimestamp(
                'SLA Started',
                '${c.slaStartedAt.day}/${c.slaStartedAt.month} ${c.slaStartedAt.hour}:${c.slaStartedAt.minute.toString().padLeft(2, '0')}',
              ),
              _slaTimestamp(
                'Statutory Target',
                '${targetHours}h (${c.priority.name.toUpperCase()} Priority)',
              ),
              if (c.resolvedAt != null)
                _slaTimestamp(
                  'Resolved At',
                  '${c.resolvedAt!.day}/${c.resolvedAt!.month} ${c.resolvedAt!.hour}:${c.resolvedAt!.minute.toString().padLeft(2, '0')}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slaTimestamp(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
            fontSize: 10,
          ),
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          value,
          style: CivicFixTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}
