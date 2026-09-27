import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/government_audit_log_model.dart';
import '../../../theme/govt_theme_tokens.dart';

/// Standardized immutable audit activity list for a single complaint.
class GovernmentComplaintAuditSection extends StatelessWidget {
  final List<GovernmentAuditLog> auditLogs;

  const GovernmentComplaintAuditSection({
    super.key,
    required this.auditLogs,
  });

  @override
  Widget build(BuildContext context) {
    if (auditLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GovtThemeTokens.borderLight),
        ),
        alignment: Alignment.center,
        child: Text(
          'No administrative audit records logged for this grievance yet.',
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: auditLogs.length,
      separatorBuilder: (context, index) =>
          const Divider(color: GovtThemeTokens.divider, height: 1),
      itemBuilder: (context, index) {
        final log = auditLogs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.sm,
            vertical: CivicFixSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getActionColor(log.action).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(log.action),
                  size: 14,
                  color: _getActionColor(log.action),
                ),
              ),
              CivicFixSpacing.hSpaceSm,
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
                      'Actor: ${log.actorName} (${log.actorRole.replaceAll("_", " ")})',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (log.details.isNotEmpty) ...[
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        log.details.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
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
      case GovernmentAuditActions.complaintCreated:
        return 'Complaint Received';
      case GovernmentAuditActions.crewAssigned:
        return 'Crew Assigned';
      case GovernmentAuditActions.statusUpdated:
        return 'Status Updated';
      case GovernmentAuditActions.resolutionSubmitted:
        return 'Work Submitted for Verification';
      case GovernmentAuditActions.resolutionVerified:
        return 'Resolution Certified & Closed';
      case GovernmentAuditActions.reassignmentRequested:
        return 'Routing Reassignment Requested';
      case GovernmentAuditActions.reassignmentApproved:
        return 'Routing Reassignment Approved';
      case GovernmentAuditActions.reassignmentRejected:
        return 'Routing Reassignment Rejected';
      case GovernmentAuditActions.complaintRejected:
        return 'Grievance Rejected';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }
}
