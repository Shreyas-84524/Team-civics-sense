import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/government_audit_log_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Ward Recent Administrative Activity Section displaying ward-isolated immutable audit logs.
class WardRecentActivitySection extends StatelessWidget {
  final List<GovernmentAuditLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onViewComplaint;

  const WardRecentActivitySection({
    super.key,
    required this.logs,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onViewComplaint,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_edu_outlined, color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WARD ADMINISTRATIVE AUDIT TRAIL',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Immutable record of status transitions, crew assignments, and department transfers in this ward',
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
                  color: GovtThemeTokens.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${logs.length} Ward Logs',
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
          CivicFixSpacing.vSpaceLg,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.lg),
                child: Column(
                  children: [
                    Text(errorMessage!, style: CivicFixTypography.bodyMedium.copyWith(color: GovtThemeTokens.error)),
                    if (onRetry != null) ...[
                      CivicFixSpacing.vSpaceSm,
                      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ],
                ),
              ),
            )
          else if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.lg),
                child: Column(
                  children: [
                    const Icon(Icons.history_toggle_off, size: 40, color: GovtThemeTokens.textMuted),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No recent administrative logs in this ward.',
                      style: CivicFixTypography.bodyMedium.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceSm,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogItem(context, log);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, GovernmentAuditLog log) {
    final detailsText = log.details['notes']?.toString() ??
        log.details['reason']?.toString() ??
        log.details['description']?.toString() ??
        log.details['message']?.toString() ??
        (log.details.isNotEmpty ? log.details.values.join(' · ') : log.action);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getActionColor(log.action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
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
                      log.actorName.isNotEmpty ? log.actorName : 'System Engine',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.action.toUpperCase(),
                        style: CivicFixTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _getActionColor(log.action),
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  detailsText,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  _formatTimestamp(log.timestamp),
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (log.complaintId.isNotEmpty && onViewComplaint != null) ...[
            CivicFixSpacing.hSpaceSm,
            IconButton(
              onPressed: () => onViewComplaint!(log.complaintId),
              icon: const Icon(Icons.open_in_new, size: 16),
              tooltip: 'Inspect Target',
              color: GovtThemeTokens.primary,
            ),
          ],
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('create') || a.contains('add')) return GovtThemeTokens.success;
    if (a.contains('assign') || a.contains('update')) return GovtThemeTokens.info;
    if (a.contains('route') || a.contains('transfer')) return GovtThemeTokens.warning;
    if (a.contains('escalat') || a.contains('breach') || a.contains('delete')) {
      return GovtThemeTokens.error;
    }
    return GovtThemeTokens.primary;
  }

  IconData _getActionIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('create') || a.contains('add')) return Icons.add_circle_outline;
    if (a.contains('assign')) return Icons.person_add_outlined;
    if (a.contains('update') || a.contains('status')) return Icons.update_outlined;
    if (a.contains('route') || a.contains('transfer')) return Icons.swap_horiz_outlined;
    if (a.contains('escalat') || a.contains('breach')) return Icons.warning_amber_rounded;
    return Icons.history;
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
