import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';

/// Ward Escalation Center: Shows active administrative and technical escalations in the Ward.
class WardEscalationCenterSection extends StatelessWidget {
  final List<WardEscalationItem> escalations;
  final bool isLoading;
  final ValueChanged<WardEscalationItem>? onDirectIntervention;

  const WardEscalationCenterSection({
    super.key,
    required this.escalations,
    this.isLoading = false,
    this.onDirectIntervention,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.warning.withValues(alpha: 0.3)),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_rounded, color: GovtThemeTokens.warning, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'WARD ESCALATION CENTER',
                          style: CivicFixTypography.h3.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: escalations.isNotEmpty ? GovtThemeTokens.warning : GovtThemeTokens.success,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${escalations.length} ESCALATED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Active technical and administrative escalations requiring Ward Officer oversight',
                      style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          CivicFixSpacing.vSpaceLg,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(color: GovtThemeTokens.primary),
              ),
            )
          else if (escalations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: GovtThemeTokens.success, size: 36),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'Zero active escalations in this ward. All high-severity workflows nominal.',
                      style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else if (isMobile)
            _buildMobileList()
          else
            _buildDesktopTable(),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GovtThemeTokens.surfaceMuted),
        headingTextStyle: CivicFixTypography.captionMedium.copyWith(
          color: GovtThemeTokens.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 18,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('COMPLAINT')),
          DataColumn(label: Text('DEPARTMENT')),
          DataColumn(label: Text('PRIORITY')),
          DataColumn(label: Text('ESCALATION STAGE')),
          DataColumn(label: Text('REASON / ISSUE')),
          DataColumn(label: Text('CURRENT OWNER')),
          DataColumn(label: Text('ESCALATED AT')),
          DataColumn(label: Text('WAITING DURATION')),
          DataColumn(label: Text('ACTION')),
        ],
        rows: escalations.map((item) {
          final timeStr = '${item.escalatedAt.day}/${item.escalatedAt.month} ${item.escalatedAt.hour.toString().padLeft(2, '0')}:${item.escalatedAt.minute.toString().padLeft(2, '0')}';
          final waitHours = item.waitingDuration.inHours;

          return DataRow(
            cells: [
              DataCell(
                Text(item.ticketNumber, style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700, color: GovtThemeTokens.primary)),
              ),
              DataCell(Text(item.departmentName, style: CivicFixTypography.bodySmall)),
              DataCell(GovtPriorityBadge.fromPriority(item.priority, isCompact: true)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.escalationStage,
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.warning,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(item.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.caption),
                ),
              ),
              DataCell(Text(item.currentOwner, style: CivicFixTypography.caption)),
              DataCell(Text(timeStr, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted))),
              DataCell(
                Text('${waitHours}h elapsed', style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600, color: waitHours > 24 ? GovtThemeTokens.error : GovtThemeTokens.textSecondary)),
              ),
              DataCell(
                ElevatedButton.icon(
                  onPressed: onDirectIntervention != null ? () => onDirectIntervention!(item) : null,
                  icon: const Icon(Icons.flash_on_rounded, size: 14),
                  label: const Text('Intervene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.warning,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: escalations.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: GovtThemeTokens.warning.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.ticketNumber, style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text(item.escalationStage, style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.warning, fontWeight: FontWeight.w700)),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(item.reason, style: CivicFixTypography.bodySmall),
                CivicFixSpacing.vSpaceXs,
                Text('Dept: ${item.departmentName} · Owner: ${item.currentOwner}', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary)),
                CivicFixSpacing.vSpaceMd,
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onDirectIntervention != null ? () => onDirectIntervention!(item) : null,
                    icon: const Icon(Icons.flash_on_rounded, size: 14),
                    label: const Text('Direct Intervention'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GovtThemeTokens.warning,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
