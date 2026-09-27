import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/government_audit_log_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Zonal Recent Administrative Activity Section displaying zone-isolated audit logs.
class ZoneRecentActivitySection extends StatelessWidget {
  final List<GovernmentAuditLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onViewComplaint;

  const ZoneRecentActivitySection({
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
                      'ZONAL ADMINISTRATIVE AUDIT TRAIL',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Immutable record of status transitions, crew assignments, and transfers in zone',
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
                  '${logs.length} Recent Logs',
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
                    const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 32),
                    CivicFixSpacing.vSpaceSm,
                    Text(errorMessage!, style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.error)),
                    if (onRetry != null) ...[
                      CivicFixSpacing.vSpaceMd,
                      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ],
                ),
              ),
            )
          else if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Text(
                  'No recent administrative activity logged in this zone.',
                  style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(color: GovtThemeTokens.divider, height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_outlined, color: GovtThemeTokens.primary, size: 16),
                      ),
                      CivicFixSpacing.hSpaceMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  log.action.replaceAll('_', ' ').toUpperCase(),
                                  style: CivicFixTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: GovtThemeTokens.textPrimary,
                                  ),
                                ),
                                CivicFixSpacing.hSpaceSm,
                                Text(
                                  'by ${log.actorName} (${log.actorRole})',
                                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                                ),
                              ],
                            ),
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              'Complaint ID: ${log.complaintId} · Ward: ${log.wardId ?? 'N/A'}',
                              style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Text(
                        _formatTimestamp(log.timestamp),
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
