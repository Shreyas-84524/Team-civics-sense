import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Critical Complaints Section for Central Department HOD command center.
/// Highlights high and emergency priority complaints across all 24 wards for the department.
class DepartmentCriticalComplaintsSection extends StatelessWidget {
  final List<ComplaintModel> criticalComplaints;
  final bool isLoading;
  final ValueChanged<ComplaintModel>? onComplaintTapped;

  const DepartmentCriticalComplaintsSection({
    super.key,
    required this.criticalComplaints,
    this.isLoading = false,
    this.onComplaintTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

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
                  color: GovtThemeTokens.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: GovtThemeTokens.error, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRITICAL & EMERGENCY GRIEVANCES',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'High-priority, hazardous, and escalated departmental complaints requiring central monitoring',
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
                  '${criticalComplaints.length} Critical',
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
          else if (criticalComplaints.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 44, color: GovtThemeTokens.success),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No critical or emergency grievances in your department.',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'All high-priority operational workflows are currently under control.',
                      style: CivicFixTypography.captionMedium
                          .copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildComplaintsTable(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildComplaintsTable(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
        ),
        dataRowMinHeight: 56,
        dataRowMaxHeight: 64,
        horizontalMargin: 16,
        columnSpacing: 24,
        columns: [
          DataColumn(
            label: Text(
              'TICKET / WARD',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'TITLE & DETAILS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'PRIORITY',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'STATUS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'SUBMITTED',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'ACTION',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
        ],
        rows: criticalComplaints.map((c) {
          final wardCode = c.wardId ?? 'A';

          return DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.ticketNumber.isNotEmpty
                          ? c.ticketNumber
                          : c.id.substring(0, 8),
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ward $wardCode',
                        style: CivicFixTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      Text(
                        c.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
              ),
              DataCell(
                GovtStatusBadge.complaint(c.status, isCompact: true),
              ),
              DataCell(
                Text(
                  _formatDate(c.createdAt),
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
              DataCell(
                ElevatedButton(
                  onPressed: () => onComplaintTapped?.call(c),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Inspect'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
