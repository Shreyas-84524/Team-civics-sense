import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import 'dashboard_card.dart';

/// Clean custom visualization displaying grievance workload across all 9 municipal categories.
class CategoryBreakdownWidget extends StatelessWidget {
  final List<CategoryDistributionItem> items;
  final ValueChanged<String>? onCategorySelected;

  const CategoryBreakdownWidget({
    super.key,
    required this.items,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Municipal Category Distribution',
      subtitle: 'Workload volume across 9 civil infrastructure domains',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTwoColumn = constraints.maxWidth >= 540;

          if (isTwoColumn) {
            final half = (items.length / 2).ceil();
            final leftColumn = items.take(half).toList();
            final rightColumn = items.skip(half).toList();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildItemList(leftColumn)),
                CivicFixSpacing.hSpaceXl,
                Expanded(child: _buildItemList(rightColumn)),
              ],
            );
          }

          return _buildItemList(items);
        },
      ),
    );
  }

  Widget _buildItemList(List<CategoryDistributionItem> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => CivicFixSpacing.vSpaceMd,
      itemBuilder: (context, index) {
        final item = list[index];
        return InkWell(
          onTap: () => onCategorySelected?.call(item.category.id),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        item.category.icon,
                        size: 14,
                        color: GovtThemeTokens.primary,
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Expanded(
                      child: Text(
                        item.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${item.count} (${item.percentage.toStringAsFixed(0)}%)',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.percentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5ECE8),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.count > 0 ? GovtThemeTokens.primary : GovtThemeTokens.border,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
