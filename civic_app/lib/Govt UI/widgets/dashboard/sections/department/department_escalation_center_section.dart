import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Technical Escalation Center for Central Department HOD command center.
/// Central clearinghouse for emergency complaints, multi-ward infrastructural failures, and critical directives.
class DepartmentEscalationCenterSection extends StatelessWidget {
  final List<ComplaintModel> escalations;
  final bool isLoading;
  final ValueChanged<ComplaintModel>? onDirectIntervention;

  const DepartmentEscalationCenterSection({
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
        border: Border.all(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
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
                  color: GovtThemeTokens.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emergency_outlined,
                    color: GovtThemeTokens.error, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT TECHNICAL ESCALATION CENTER',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'High-severity structural issues requiring Chief Engineer directives or taskforce deployment',
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
                  color: GovtThemeTokens.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${escalations.length} Escalations',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (escalations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.lg),
                child: Column(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 40, color: GovtThemeTokens.success),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'Zero Active Technical Escalations',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'No critical structural hazards or unresolved bottlenecks requiring HOD intervention.',
                      style: CivicFixTypography.captionMedium
                          .copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: escalations.length,
              separatorBuilder: (context, index) => CivicFixSpacing.vSpaceSm,
              itemBuilder: (context, index) {
                final item = escalations[index];
                return _buildEscalationItem(context, item, isMobile);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEscalationItem(
      BuildContext context, ComplaintModel item, bool isMobile) {
    final ticketNo = item.ticketNumber.isNotEmpty
        ? item.ticketNumber
        : item.id.substring(0, 8);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ESCALATED',
                        style: CivicFixTypography.caption.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      ticketNo,
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ward ${item.wardId ?? "A"}',
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primaryDark,
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceSm,
                Text(
                  item.title,
                  style: CivicFixTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => onDirectIntervention?.call(item),
                      icon: const Icon(Icons.flash_on, size: 14),
                      label: const Text('Direct Intervention'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GovtThemeTokens.primary,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ESCALATED',
                    style: CivicFixTypography.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ward ${item.wardId ?? "A"}',
                    style: CivicFixTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.primaryDark,
                    ),
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$ticketNo — ${item.title}',
                        style: CivicFixTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                ElevatedButton.icon(
                  onPressed: () => onDirectIntervention?.call(item),
                  icon: const Icon(Icons.flash_on, size: 14),
                  label: const Text('Direct Intervention'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
    );
  }
}
