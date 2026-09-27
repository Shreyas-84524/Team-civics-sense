import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/government_audit_log_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../../theme/govt_typography.dart';
import '../../common/government_data_table.dart';
import '../../common/government_error_state.dart';
import '../../common/government_section_header.dart';
import '../../common/govt_empty_state.dart';
import '../../common/govt_jurisdiction_badge.dart';

/// Section presenting chronological immutable audit logs of administrative actions.
class RecentAdministrativeActivitySection extends StatelessWidget {
  final List<GovernmentAuditLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onViewComplaint;

  const RecentAdministrativeActivitySection({
    super.key,
    required this.logs,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GovernmentSectionHeader(
            title: 'Recent Administrative Activity',
            subtitle: 'Immutable audit ledger of municipal state transitions and assignments',
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.errorLight),
            ),
            child: GovernmentErrorState(
              title: 'Unable to Load Audit Activity',
              message: errorMessage!,
              onRetry: onRetry,
              isCompact: true,
            ),
          ),
        ],
      );
    }

    if (logs.isEmpty && !isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GovernmentSectionHeader(
            title: 'Recent Administrative Activity',
            subtitle: 'Immutable audit ledger of municipal state transitions and assignments',
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.xl),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: GovtEmptyState.noAuditRecords(),
          ),
        ],
      );
    }

    final columns = [
      const GovtDataColumn(label: 'Timestamp', width: 140),
      const GovtDataColumn(label: 'Officer', width: 170),
      const GovtDataColumn(label: 'Role / Designation', width: 150),
      const GovtDataColumn(label: 'Action Taken', width: 190),
      const GovtDataColumn(label: 'Complaint ID', width: 130),
      const GovtDataColumn(label: 'Ward', width: 85),
      const GovtDataColumn(label: 'Department', width: 150),
    ];

    final rows = logs.take(10).map((log) {
      final timeStr = DateFormatter.formatRelative(log.timestamp);
      final wardStr = log.wardId ?? '—';
      final deptStr = log.departmentId ?? '—';

      return [
        // Timestamp
        Text(
          timeStr,
          style: GovtTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
        ),
        // Officer
        Text(
          log.actorName.isNotEmpty ? log.actorName : log.actorId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        // Role
        Text(
          _formatRoleLabel(log.actorRole),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GovtTypography.caption.copyWith(color: GovtThemeTokens.textPrimary),
        ),
        // Action Taken
        _buildActionBadge(log.action),
        // Complaint ID
        InkWell(
          onTap: onViewComplaint != null ? () => onViewComplaint!(log.complaintId) : null,
          child: Text(
            log.complaintId,
            style: GovtTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.primary,
              fontFamily: 'monospace',
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        // Ward
        GovtJurisdictionBadge.ward(wardStr, isCompact: true, withBrackets: false),
        // Department
        Text(
          deptStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GovtTypography.bodySmall,
        ),
      ];
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GovernmentSectionHeader(
          title: 'Recent Administrative Activity',
          subtitle: 'Immutable audit ledger of municipal state transitions and assignments',
          count: logs.length,
        ),
        CivicFixSpacing.vSpaceSm,
        GovernmentDataTable(
          columns: columns,
          rows: rows,
          isLoading: isLoading,
          title: 'Administrative Security & Audit Log',
          totalCount: logs.length,
          pageSize: 10,
          minWidth: 1050,
        ),
      ],
    );
  }

  Widget _buildActionBadge(String action) {
    Color bg = GovtThemeTokens.surfaceMuted;
    Color fg = GovtThemeTokens.textPrimary;
    IconData icon = Icons.receipt_long_rounded;

    final lower = action.toLowerCase();
    if (lower.contains('assigned') || lower.contains('crew')) {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF2563EB);
      icon = Icons.person_pin_rounded;
    } else if (lower.contains('reassignment') || lower.contains('routing')) {
      bg = const Color(0xFFFEF8EC);
      fg = const Color(0xFFD97706);
      icon = Icons.swap_horiz_rounded;
    } else if (lower.contains('verified') || lower.contains('approved') || lower.contains('resolved')) {
      bg = const Color(0xFFECFDF5);
      fg = GovtThemeTokens.success;
      icon = Icons.check_circle_outline_rounded;
    } else if (lower.contains('rejected') || lower.contains('flagged')) {
      bg = const Color(0xFFFDE8E8);
      fg = GovtThemeTokens.error;
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            _humanizeAction(action),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  String _humanizeAction(String action) {
    switch (action) {
      case GovernmentAuditActions.complaintCreated:
        return 'Grievance Registered';
      case GovernmentAuditActions.reassignmentRequested:
        return 'Reassignment Requested';
      case GovernmentAuditActions.reassignmentApproved:
        return 'Reassignment Approved';
      case GovernmentAuditActions.reassignmentRejected:
        return 'Reassignment Rejected';
      case GovernmentAuditActions.crewAssigned:
        return 'Crew Mobilized';
      case GovernmentAuditActions.statusUpdated:
        return 'Status Updated';
      case GovernmentAuditActions.resolutionSubmitted:
        return 'Work Submitted';
      case GovernmentAuditActions.resolutionVerified:
        return 'Work Verified';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'government_super_admin':
        return 'Municipal Commissioner';
      case 'zonal_dmc':
        return 'Zonal DMC';
      case 'central_department_hod':
        return 'Central HOD';
      case 'ward_officer':
        return 'Ward Officer';
      case 'ward_department_lead':
        return 'Ward Dept Lead';
      case 'department_crew':
        return 'Field Crew';
      default:
        return role.replaceAll('_', ' ');
    }
  }
}
