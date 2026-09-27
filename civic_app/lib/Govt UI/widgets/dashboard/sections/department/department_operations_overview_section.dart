import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Department grievance operations pipeline overview for Central Department HOD.
class DepartmentOperationsOverviewSection extends StatelessWidget {
  final DepartmentOperationsOverviewData? overview;
  final bool isLoading;

  const DepartmentOperationsOverviewSection({
    super.key,
    this.overview,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final total = o?.totalActiveComplaints ?? 0;

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_tree_outlined, color: GovtThemeTokens.primary, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEPARTMENT OPERATIONS PIPELINE',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Live lifecycle stage distribution across all 24 municipal ward units',
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '$total Active Grievances',
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

          // 5-Stage Lifecycle Funnel
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.lg),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else ...[
            _buildPipelineStages(context, o),
            CivicFixSpacing.vSpaceLg,
            _buildSummaryRow(context, o),
          ],
        ],
      ),
    );
  }

  Widget _buildPipelineStages(BuildContext context, DepartmentOperationsOverviewData? o) {
    final stages = [
      _PipelineStage(
        label: 'Submitted',
        count: o?.submittedCount ?? 0,
        color: const Color(0xFF64748B),
        icon: Icons.inbox_rounded,
      ),
      _PipelineStage(
        label: 'Acknowledged',
        count: o?.acknowledgedCount ?? 0,
        color: const Color(0xFF0284C7),
        icon: Icons.mark_email_read_rounded,
      ),
      _PipelineStage(
        label: 'Assigned',
        count: o?.assignedCount ?? 0,
        color: const Color(0xFFD97706),
        icon: Icons.person_search_rounded,
      ),
      _PipelineStage(
        label: 'In Progress',
        count: o?.inProgressCount ?? 0,
        color: const Color(0xFFE65100),
        icon: Icons.build_circle_outlined,
      ),
      _PipelineStage(
        label: 'Awaiting Verify',
        count: o?.awaitingVerificationCount ?? 0,
        color: const Color(0xFF7C3AED),
        icon: Icons.fact_check_outlined,
      ),
      _PipelineStage(
        label: 'Resolved',
        count: o?.resolvedCount ?? 0,
        color: const Color(0xFF16A34A),
        icon: Icons.check_circle_rounded,
      ),
    ];

    final isMobile = GovtResponsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: stages
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildStageCard(s),
                ))
            .toList(),
      );
    }

    return Row(
      children: stages.asMap().entries.map((entry) {
        final idx = entry.key;
        final stage = entry.value;
        final isLast = idx == stages.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(child: _buildStageCard(stage)),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right_rounded, color: GovtThemeTokens.textMuted.withValues(alpha: 0.5), size: 18),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStageCard(_PipelineStage s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  s.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(s.icon, color: s.color, size: 14),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            '${s.count}',
            style: CivicFixTypography.h3.copyWith(
              color: s.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, DepartmentOperationsOverviewData? o) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        alignment: WrapAlignment.spaceAround,
        children: [
          _summaryPill('Created Today', '+${o?.createdTodayCount ?? 0}', GovtThemeTokens.info),
          _summaryPill('Resolved Today', '${o?.resolvedTodayCount ?? 0}', GovtThemeTokens.success),
          _summaryPill('Critical Unresolved', '${o?.criticalUnresolvedCount ?? 0}',
              (o?.criticalUnresolvedCount ?? 0) > 0 ? GovtThemeTokens.error : GovtThemeTokens.textMuted),
          _summaryPill('Active SLA Breaches', '${o?.slaBreachesCount ?? 0}',
              (o?.slaBreachesCount ?? 0) > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        CivicFixSpacing.hSpaceSm,
        Text(
          '$label: ',
          style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
        ),
        Text(
          value,
          style: CivicFixTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PipelineStage {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _PipelineStage({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}
