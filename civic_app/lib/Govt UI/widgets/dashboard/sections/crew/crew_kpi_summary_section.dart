import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_crew_work_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Top field KPI summary cards for Department Crew workspace (Assigned, In Progress, Completed).
class CrewKpiSummarySection extends StatelessWidget {
  final CrewKpiMetrics metrics;
  final void Function(String tabKey)? onKpiTapped;

  const CrewKpiSummarySection({
    super.key,
    required this.metrics,
    this.onKpiTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 480) {
          crossAxisCount = 1;
        }

        final cards = [
          _CrewKpiCard(
            title: 'Assigned',
            value: '${metrics.assignedToday}',
            icon: Icons.assignment_outlined,
            accentColor: const Color(0xFF3B82F6),
            tabKey: 'all',
            onTap: onKpiTapped,
          ),
          _CrewKpiCard(
            title: 'In Progress',
            value: '${metrics.inProgressCount}',
            icon: Icons.engineering_rounded,
            accentColor: const Color(0xFFF59E0B),
            tabKey: 'in_progress',
            onTap: onKpiTapped,
          ),
          _CrewKpiCard(
            title: 'Completed',
            value: '${metrics.completedToday}',
            icon: Icons.check_circle_outline_rounded,
            accentColor: const Color(0xFF10B981),
            tabKey: 'completed',
            onTap: onKpiTapped,
          ),
        ];

        final spacing = CivicFixSpacing.md;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final itemWidth = ((width - totalSpacing) / crossAxisCount)
            .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (c) => SizedBox(
                  width: itemWidth > 0 ? itemWidth : width,
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _CrewKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String tabKey;
  final void Function(String tabKey)? onTap;

  const _CrewKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.tabKey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(tabKey) : null,
        borderRadius: GovtThemeTokens.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: GovtThemeTokens.cardRadius,
            border: Border.all(color: GovtThemeTokens.border),
            boxShadow: GovtThemeTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: GovtThemeTokens.textMuted,
                    ),
                ],
              ),
              CivicFixSpacing.vSpaceSm,
              Text(
                value,
                style: CivicFixTypography.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.textPrimary,
                ),
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
