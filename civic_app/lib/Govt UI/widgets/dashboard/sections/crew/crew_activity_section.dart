import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/government_audit_log_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Section displaying immutable audit activity log strictly involving current crew technician.
class CrewActivitySection extends StatelessWidget {
  final List<GovernmentAuditLog> auditLogs;

  const CrewActivitySection({
    super.key,
    required this.auditLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
            CivicFixSpacing.hSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY OPERATIONAL ACTIVITY LOG',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Immutable audit trail of actions, state updates, and evidence submissions (${auditLogs.length})',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceMd,

        if (auditLogs.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xxl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history_outlined,
                  size: 48,
                  color: GovtThemeTokens.textMuted,
                ),
                CivicFixSpacing.vSpaceMd,
                Text(
                  'No recent activity recorded',
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  'Your dispatched assignments, work progress, and completion submissions will be logged here.',
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
              boxShadow: GovtThemeTokens.cardShadow,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: auditLogs.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: GovtThemeTokens.divider, height: 1),
              itemBuilder: (context, index) {
                final log = auditLogs[index];
                return Padding(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getActionColor(log.action).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getActionIcon(log.action),
                          size: 16,
                          color: _getActionColor(log.action),
                        ),
                      ),
                      CivicFixSpacing.hSpaceMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatActionLabel(log.action),
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: GovtThemeTokens.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: CivicFixTypography.caption.copyWith(
                                    color: GovtThemeTokens.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              'Grievance ID: ${log.complaintId} · Actor: ${log.actorName} (${log.actorRole})',
                              style: CivicFixTypography.caption.copyWith(
                                color: GovtThemeTokens.textSecondary,
                              ),
                            ),
                            if (log.details.isNotEmpty) ...[
                              CivicFixSpacing.vSpaceXs,
                              Text(
                                log.details.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: CivicFixTypography.caption.copyWith(
                                  color: GovtThemeTokens.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case GovernmentAuditActions.crewAssigned:
        return Icons.person_add_alt_1_rounded;
      case GovernmentAuditActions.statusUpdated:
        return Icons.update_rounded;
      case GovernmentAuditActions.resolutionSubmitted:
        return Icons.send_rounded;
      case GovernmentAuditActions.resolutionVerified:
        return Icons.verified_rounded;
      case GovernmentAuditActions.reassignmentRequested:
        return Icons.swap_horiz_rounded;
      case GovernmentAuditActions.reassignmentApproved:
        return Icons.check_circle_outline_rounded;
      case GovernmentAuditActions.reassignmentRejected:
        return Icons.cancel_outlined;
      case GovernmentAuditActions.complaintRejected:
        return Icons.block_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case GovernmentAuditActions.crewAssigned:
        return const Color(0xFF3B82F6);
      case GovernmentAuditActions.statusUpdated:
        return const Color(0xFFD97706);
      case GovernmentAuditActions.resolutionSubmitted:
        return const Color(0xFF8B5CF6);
      case GovernmentAuditActions.resolutionVerified:
      case GovernmentAuditActions.reassignmentApproved:
        return const Color(0xFF10B981);
      case GovernmentAuditActions.reassignmentRequested:
        return const Color(0xFFF97316);
      case GovernmentAuditActions.reassignmentRejected:
      case GovernmentAuditActions.complaintRejected:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatActionLabel(String action) {
    switch (action) {
      case GovernmentAuditActions.crewAssigned:
        return 'Grievance Assigned to Crew';
      case GovernmentAuditActions.statusUpdated:
        return 'Field Status / Evidence Updated';
      case GovernmentAuditActions.resolutionSubmitted:
        return 'Work Submitted for Verification';
      case GovernmentAuditActions.resolutionVerified:
        return 'Resolution Certified by Lead';
      case GovernmentAuditActions.reassignmentRequested:
        return 'Wrong Department Reported';
      case GovernmentAuditActions.reassignmentApproved:
        return 'Reassignment Approved';
      case GovernmentAuditActions.reassignmentRejected:
        return 'Reassignment Rejected';
      case GovernmentAuditActions.complaintRejected:
        return 'Complaint Rejected';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }
}
