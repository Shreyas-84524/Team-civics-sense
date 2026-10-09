import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/localization/widgets/civic_fix_translated_text.dart';
import '../../../theme/govt_theme_tokens.dart';
import '../../common/govt_priority_badge.dart';
import '../../common/govt_sla_badge.dart';
import '../../common/govt_status_badge.dart';

/// Reusable Complaint Overview Card for the consolidated complaint detail screen.
/// Shows: ID, Category, Description, Priority, Status, Ward, Zone, Department,
/// Assigned Lead, Assigned Crew, Reported At, Original SLA Start, Current SLA State, Reassignments.
/// Strictly protects citizen sensitive information.
class GovernmentComplaintOverviewCard extends StatelessWidget {
  final ComplaintModel complaint;
  final String? zoneName;

  const GovernmentComplaintOverviewCard({
    super.key,
    required this.complaint,
    this.zoneName,
  });

  @override
  Widget build(BuildContext context) {
    final c = complaint;

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
          Text(
            'Grievance Overview',
            style: CivicFixTypography.h3.copyWith(
              color: GovtThemeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceSm,

          // Top Row / Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'GRIEVANCE #${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id}',
                          style: CivicFixTypography.h3.copyWith(
                            color: GovtThemeTokens.primaryDark,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (c.reassignmentCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${c.reassignmentCount} Transfers',
                              style: CivicFixTypography.caption.copyWith(
                                color: const Color(0xFFC2410C),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    CivicFixSpacing.vSpaceXs,
                    CivicFixTranslatedText(
                      originalText: c.title,
                      contentId: c.id,
                      fieldName: 'title',
                      contentCategory: 'complaint_title',
                      style: CivicFixTypography.h3.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        GovtStatusBadge.complaint(c.status),
                        GovtPriorityBadge.fromPriority(c.priority),
                        GovtSlaBadge.fromDuration(
                          createdAt: c.slaStartedAt,
                          resolvedAt: c.resolvedAt,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              'GRIEVANCE #${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id}',
                              style: CivicFixTypography.h3.copyWith(
                                color: GovtThemeTokens.primaryDark,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (c.reassignmentCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '${c.reassignmentCount} Transfers',
                                  style: CivicFixTypography.caption.copyWith(
                                    color: const Color(0xFFC2410C),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        CivicFixSpacing.vSpaceXs,
                        CivicFixTranslatedText(
                          originalText: c.title,
                          contentId: c.id,
                          fieldName: 'title',
                          contentCategory: 'complaint_title',
                          style: CivicFixTypography.h3.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: GovtThemeTokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      GovtStatusBadge.complaint(c.status),
                      GovtPriorityBadge.fromPriority(c.priority),
                      GovtSlaBadge.fromDuration(
                        createdAt: c.slaStartedAt,
                        resolvedAt: c.resolvedAt,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          // Description
          Text(
            'CITIZEN REPORT DESCRIPTION',
            style: CivicFixTypography.captionMedium.copyWith(
              color: GovtThemeTokens.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          CivicFixTranslatedText(
            originalText: c.description,
            contentId: c.id,
            fieldName: 'description',
            contentCategory: 'complaint_description',
            style: CivicFixTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textSecondary,
              height: 1.4,
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Structured Metadata Grid
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _infoTile('Category', c.category.name, Icons.category_outlined),
              _infoTile('Ward', 'Ward ${c.wardId ?? c.location.ward ?? "N/A"}', Icons.apartment_outlined),
              if (zoneName != null)
                _infoTile('Zone', zoneName!, Icons.map_outlined),
              _infoTile(
                'Department',
                c.departmentName ?? c.assignedDepartmentId ?? 'Unassigned',
                Icons.account_balance_outlined,
              ),
              _infoTile(
                'Assigned Crew',
                c.assignedTo != null && c.assignedTo!.isNotEmpty
                    ? c.assignedTo!
                    : 'Unassigned',
                Icons.engineering_outlined,
              ),
              _infoTile(
                'Reported At',
                '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year} ${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                Icons.calendar_today_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(CivicFixSpacing.sm),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: GovtThemeTokens.textMuted),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
