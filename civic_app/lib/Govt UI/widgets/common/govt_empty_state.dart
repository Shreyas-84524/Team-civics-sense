import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';

/// Reusable civic-styled empty state for government screens and tables.
class GovtEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isCompact;

  const GovtEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.isCompact = false,
  });

  /// Factory for complaints empty state.
  factory GovtEmptyState.noComplaints({VoidCallback? onAction, String? actionLabel}) =>
      GovtEmptyState(
        title: 'No complaints found',
        message: 'No grievances currently match your filter criteria or jurisdiction.',
        icon: Icons.assignment_outlined,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Factory for routing requests empty state.
  factory GovtEmptyState.noRoutingRequests({VoidCallback? onAction}) =>
      GovtEmptyState(
        title: 'No routing requests',
        message: 'All department transfer tickets have been adjudicated.',
        icon: Icons.swap_horiz_rounded,
        actionLabel: onAction != null ? 'Refresh Queue' : null,
        onAction: onAction,
      );

  /// Factory for escalations empty state.
  factory GovtEmptyState.noEscalations() => const GovtEmptyState(
        title: 'No active escalations',
        message: 'All municipal operations are proceeding within statutory SLA deadlines.',
        icon: Icons.verified_user_outlined,
      );

  /// Factory for staff members empty state.
  factory GovtEmptyState.noStaff({VoidCallback? onAddStaff}) => GovtEmptyState(
        title: 'No staff members found',
        message: 'No personnel records exist for the selected department or ward.',
        icon: Icons.people_outline_rounded,
        actionLabel: onAddStaff != null ? 'Add Officer' : null,
        onAction: onAddStaff,
      );

  /// Factory for audit records empty state.
  factory GovtEmptyState.noAuditRecords() => const GovtEmptyState(
        title: 'No audit records',
        message: 'No administrative log entries match the selected timestamp range.',
        icon: Icons.receipt_long_outlined,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? CivicFixSpacing.lg : CivicFixSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: isCompact ? 44 : 56,
              height: isCompact ? 44 : 56,
              decoration: BoxDecoration(
                color: GovtThemeTokens.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: GovtThemeTokens.border),
              ),
              child: Icon(
                icon,
                size: isCompact ? 22 : 28,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            SizedBox(height: isCompact ? CivicFixSpacing.sm : CivicFixSpacing.md),
            Text(
              title,
              style: isCompact
                  ? GovtTypography.cardTitle.copyWith(fontSize: 14)
                  : GovtTypography.sectionTitle.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                style: GovtTypography.bodySmall.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              CivicFixSpacing.vSpaceMd,
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GovtThemeTokens.primary,
                  side: const BorderSide(color: GovtThemeTokens.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicFixSpacing.lg,
                    vertical: CivicFixSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: GovtThemeTokens.buttonRadius,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
