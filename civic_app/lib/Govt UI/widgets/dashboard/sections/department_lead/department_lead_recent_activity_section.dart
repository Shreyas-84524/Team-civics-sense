import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/government_audit_log_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// "Recent Activity" Audit Section for Ward Department Lead Operations Center.
/// Displays an immutable audit trail of operational actions strictly within this unit.
class DepartmentLeadRecentActivitySection extends StatelessWidget {
  final List<GovernmentAuditLog> auditLogs;
  final bool isLoading;

  const DepartmentLeadRecentActivitySection({
    super.key,
    required this.auditLogs,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
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
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT OPERATIONAL AUDIT ACTIVITY',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Immutable audit log of assignments, transitions, and field operations in this unit',
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
                  color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${auditLogs.length} Unit Logs',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (auditLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Text(
                'No audit actions recorded for this department unit yet.',
                style: CivicFixTypography.caption.copyWith(
                  color: GovtThemeTokens.textMuted,
                ),
              ),
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: auditLogs.take(10).length,
              separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceSm,
              itemBuilder: (ctx, i) {
                final log = auditLogs[i];
                return _buildMobileLogCard(log);
              },
            )
          else
            _buildDesktopTable(auditLogs.take(15).toList()),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<GovernmentAuditLog> logs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.6), // Time
          1: FlexColumnWidth(2.0), // Officer / Actor
          2: FlexColumnWidth(2.2), // Action
          3: FlexColumnWidth(1.6), // Complaint
          4: FlexColumnWidth(2.6), // Details
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
            ),
            children: [
              _tableHeader('TIME'),
              _tableHeader('OFFICER / ACTOR'),
              _tableHeader('ACTION'),
              _tableHeader('COMPLAINT'),
              _tableHeader('DETAILS'),
            ],
          ),
          ...logs.map((log) {
            final formattedAction = _formatActionName(log.action);
            final actionColor = _getActionColor(log.action);

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: GovtThemeTokens.borderLight),
                ),
              ),
              children: [
                // Time
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${log.timestamp.day}/${log.timestamp.month} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Officer
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    '${log.actorName}\n(${log.actorId})',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Action
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formattedAction,
                        style: CivicFixTypography.caption.copyWith(
                          color: actionColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // Complaint
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    log.complaintId,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Details
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CivicFixSpacing.md,
                      vertical: CivicFixSpacing.sm),
                  child: Text(
                    _formatDetails(log.details),
                    style: CivicFixTypography.caption.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileLogCard(GovernmentAuditLog log) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.sm),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getActionColor(log.action),
              shape: BoxShape.circle,
            ),
          ),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatActionName(log.action)} · ${log.complaintId}',
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'By ${log.actorName} · ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatActionName(String action) {
    switch (action) {
      case GovernmentAuditActions.complaintCreated:
        return 'Complaint Received';
      case GovernmentAuditActions.crewAssigned:
        return 'Crew Assigned';
      case GovernmentAuditActions.reassignmentRequested:
        return 'Routing Requested';
      case GovernmentAuditActions.reassignmentApproved:
        return 'Routing Approved';
      case GovernmentAuditActions.reassignmentRejected:
        return 'Routing Rejected';
      case GovernmentAuditActions.resolutionSubmitted:
        return 'Work Submitted';
      case GovernmentAuditActions.resolutionVerified:
        return 'Resolution Verified';
      case GovernmentAuditActions.statusUpdated:
        return 'Status Updated';
      case GovernmentAuditActions.complaintRejected:
        return 'Closed / Rejected';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case GovernmentAuditActions.resolutionVerified:
      case GovernmentAuditActions.reassignmentApproved:
        return const Color(0xFF10B981);
      case GovernmentAuditActions.reassignmentRequested:
      case GovernmentAuditActions.reassignmentRejected:
        return const Color(0xFFF97316);
      case GovernmentAuditActions.crewAssigned:
        return const Color(0xFF3B82F6);
      case GovernmentAuditActions.complaintRejected:
        return const Color(0xFFEF4444);
      default:
        return GovtThemeTokens.primary;
    }
  }

  String _formatDetails(Map<String, dynamic> details) {
    if (details.isEmpty) return 'Standard system event';
    return details.entries.map((e) => '${e.key}: ${e.value}').join(', ');
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
