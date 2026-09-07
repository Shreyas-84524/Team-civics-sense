import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../theme/govt_theme_tokens.dart';
import 'dashboard_card.dart';

/// Attention Required panel displaying critical, unassigned, and unverified grievances.
class AttentionRequiredCard extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final ValueChanged<ComplaintModel>? onInspect;
  final VoidCallback? onViewAll;

  const AttentionRequiredCard({
    super.key,
    required this.complaints,
    this.onInspect,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Action & Triage Required',
      subtitle: '${complaints.length} priority grievances awaiting officer intervention',
      headerAction: onViewAll != null
          ? TextButton.icon(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text('View All', style: TextStyle(fontSize: 12)),
            )
          : null,
      child: complaints.isEmpty
          ? Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: GovtThemeTokens.secondary,
                    size: 36,
                  ),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'All urgent civic grievances have been triaged.',
                    style: CivicFixTypography.bodySmall.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: complaints.length,
              separatorBuilder: (context, index) => const Divider(
                color: GovtThemeTokens.border,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final c = complaints[index];
                final isUrgent = c.priority == ComplaintPriority.emergency;

                return InkWell(
                  onTap: () => onInspect?.call(c),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: isUrgent ? const Color(0xFFFEF2F2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isUrgent
                          ? Border.all(color: const Color(0xFFFCA5A5), width: 1)
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.priority.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            c.category.icon,
                            color: c.priority.color,
                            size: 18,
                          ),
                        ),
                        CivicFixSpacing.hSpaceMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    c.ticketNumber,
                                    style: CivicFixTypography.captionMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: GovtThemeTokens.primary,
                                    ),
                                  ),
                                  PriorityBadge(priority: c.priority, isCompact: true),
                                  StatusBadge(status: c.status, isCompact: true),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CivicFixTypography.bodySmallMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${c.location.address} • ${DateFormatter.formatRelative(c.createdAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CivicFixTypography.caption.copyWith(
                                        color: GovtThemeTokens.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (c.assignedTo == null) ...[
                                    CivicFixSpacing.hSpaceXs,
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Unassigned',
                                        style: CivicFixTypography.caption.copyWith(
                                          color: const Color(0xFF92400E),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        CivicFixSpacing.hSpaceSm,
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          tooltip: 'Inspect Grievance',
                          onPressed: () => onInspect?.call(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
