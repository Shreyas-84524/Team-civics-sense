import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_lead_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Operational Workflow Funnel Section for Ward Department Lead.
/// Displays a visual pipeline across the grievance lifecycle stages:
/// New / Unassigned -> Assigned -> Accepted -> In Progress -> Awaiting Verification -> Resolved.
class DepartmentLeadOperationsFunnelSection extends StatelessWidget {
  final DepartmentLeadOperationsFunnel funnel;
  final bool isLoading;

  const DepartmentLeadOperationsFunnelSection({
    super.key,
    required this.funnel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    final totalActive = funnel.newUnassigned +
        funnel.assigned +
        funnel.inProgress +
        funnel.awaitingVerification +
        funnel.resolved;

    final stages = [
      _FunnelStage(
        label: 'New / Unassigned',
        count: funnel.newUnassigned,
        color: const Color(0xFFF59E0B),
        icon: Icons.assignment_late_outlined,
      ),
      _FunnelStage(
        label: 'Assigned',
        count: funnel.assigned,
        color: const Color(0xFF3B82F6),
        icon: Icons.assignment_ind_outlined,
      ),
      _FunnelStage(
        label: 'Accepted',
        count: funnel.accepted,
        color: const Color(0xFF0EA5E9),
        icon: Icons.thumb_up_alt_outlined,
      ),
      _FunnelStage(
        label: 'In Progress',
        count: funnel.inProgress,
        color: const Color(0xFF6366F1),
        icon: Icons.engineering_outlined,
      ),
      _FunnelStage(
        label: 'Awaiting Verification',
        count: funnel.awaitingVerification,
        color: const Color(0xFF8B5CF6),
        icon: Icons.fact_check_outlined,
      ),
      _FunnelStage(
        label: 'Resolved',
        count: funnel.resolved,
        color: const Color(0xFF10B981),
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.alt_route_rounded,
                    color: GovtThemeTokens.primary, size: 18),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPERATIONAL WORKFLOW FUNNEL',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'End-to-end active complaint lifecycle distribution for this ward unit',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '$totalActive Total Unit Complaints',
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
          if (isMobile) ...[
            Column(
              children: stages
                  .map((stage) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: CivicFixSpacing.sm),
                        child: _buildStageTile(stage, totalActive),
                      ))
                  .toList(),
            ),
          ] else ...[
            Row(
              children: List.generate(stages.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: GovtThemeTokens.textMuted,
                    ),
                  );
                }
                final stageIndex = index ~/ 2;
                final stage = stages[stageIndex];
                return Expanded(
                  child: _buildStageCard(stage, totalActive),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageCard(_FunnelStage stage, int total) {
    final percentage = total > 0 ? (stage.count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.md,
        vertical: CivicFixSpacing.md,
      ),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stage.color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stage.icon, size: 16, color: stage.color),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: CivicFixTypography.caption.copyWith(
                  color: stage.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Text(
            '${stage.count}',
            style: CivicFixTypography.h2.copyWith(
              color: stage.color,
              fontWeight: FontWeight.w800,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            stage.label,
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStageTile(_FunnelStage stage, int total) {
    final percentage = total > 0 ? (stage.count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stage.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(stage.icon, size: 16, color: stage.color),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Text(
              stage.label,
              style: CivicFixTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: GovtThemeTokens.textPrimary,
              ),
            ),
          ),
          Text(
            '${stage.count}',
            style: CivicFixTypography.h3.copyWith(
              color: stage.color,
              fontWeight: FontWeight.w800,
            ),
          ),
          CivicFixSpacing.hSpaceSm,
          Text(
            '(${percentage.toStringAsFixed(0)}%)',
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelStage {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _FunnelStage({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}
