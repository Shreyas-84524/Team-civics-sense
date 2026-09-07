import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import 'dashboard_card.dart';

/// Clean custom visualization displaying grievance lifecycle distribution.
class StatusDistributionWidget extends StatelessWidget {
  final List<StatusDistributionItem> items;
  final ValueChanged<ComplaintStatus>? onStatusSelected;

  const StatusDistributionWidget({
    super.key,
    required this.items,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.count);

    return DashboardCard(
      title: 'Lifecycle Status Overview',
      subtitle: '$total active and closed municipal grievances tracked',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 14,
              width: double.infinity,
              color: const Color(0xFFE5ECE8),
              child: Row(
                children: items.map((item) {
                  if (item.percentage <= 0) return const SizedBox.shrink();
                  return Expanded(
                    flex: (item.percentage * 10).round().clamp(1, 1000),
                    child: Tooltip(
                      message: '${item.status.label}: ${item.count} (${item.percentage.toStringAsFixed(1)}%)',
                      child: Container(
                        color: item.status.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Status Legends Grid
          Wrap(
            spacing: CivicFixSpacing.lg,
            runSpacing: CivicFixSpacing.md,
            children: items.map((item) {
              return InkWell(
                onTap: () => onStatusSelected?.call(item.status),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      Text(
                        item.status.label,
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      CivicFixSpacing.hSpaceXs,
                      Text(
                        '(${item.count} • ${item.percentage.toStringAsFixed(0)}%)',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
