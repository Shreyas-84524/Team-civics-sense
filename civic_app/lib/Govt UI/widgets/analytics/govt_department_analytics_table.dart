import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../models/analytics_model.dart';
import '../../theme/govt_theme_tokens.dart';
import '../dashboard/dashboard_card.dart';

/// Department-based workload and resolution performance table/card view.
class GovtDepartmentAnalyticsTable extends StatelessWidget {
  final List<DepartmentAnalytics> departments;

  const GovtDepartmentAnalyticsTable({
    super.key,
    required this.departments,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Department Workload & Performance Breakdown',
      subtitle: 'Distribution of civic complaints, pending queues, and resolution index per department',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 760;

          if (isDesktop) {
            return _buildDesktopTable();
          } else {
            return _buildMobileCardList();
          }
        },
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: GovtThemeTokens.cardRadius,
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: ClipRRect(
        borderRadius: GovtThemeTokens.cardRadius,
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3.0), // Department
            1: FlexColumnWidth(1.2), // Total
            2: FlexColumnWidth(1.2), // Pending
            3: FlexColumnWidth(1.4), // In Progress
            4: FlexColumnWidth(1.2), // Resolved
            5: FlexColumnWidth(2.5), // Resolution Rate
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Table Header Row
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFEFF3F0),
                border: Border(bottom: BorderSide(color: GovtThemeTokens.border)),
              ),
              children: [
                _buildHeaderCell('Department'),
                _buildHeaderCell('Total', align: TextAlign.center),
                _buildHeaderCell('Pending', align: TextAlign.center),
                _buildHeaderCell('In Progress', align: TextAlign.center),
                _buildHeaderCell('Resolved', align: TextAlign.center),
                _buildHeaderCell('Resolution Index'),
              ],
            ),

            // Department Data Rows
            ...departments.map((dept) {
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F4F2))),
                ),
                children: [
                  // Department Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md, vertical: 12),
                    child: Text(
                      dept.departmentName,
                      style: CivicFixTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                  ),

                  // Total
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.sm, vertical: 12),
                    child: Text(
                      '${dept.total}',
                      textAlign: TextAlign.center,
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primary,
                      ),
                    ),
                  ),

                  // Pending
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.sm, vertical: 12),
                    child: Text(
                      '${dept.pending}',
                      textAlign: TextAlign.center,
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: dept.pending > 0 ? GovtThemeTokens.alert : GovtThemeTokens.textSecondary,
                        fontWeight: dept.pending > 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),

                  // In Progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.sm, vertical: 12),
                    child: Text(
                      '${dept.inProgress}',
                      textAlign: TextAlign.center,
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: dept.inProgress > 0 ? GovtThemeTokens.info : GovtThemeTokens.textSecondary,
                      ),
                    ),
                  ),

                  // Resolved
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.sm, vertical: 12),
                    child: Text(
                      '${dept.resolved}',
                      textAlign: TextAlign.center,
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: dept.resolved > 0 ? GovtThemeTokens.secondary : GovtThemeTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Resolution Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: dept.resolutionRate,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE5ECE8),
                              valueColor: const AlwaysStoppedAnimation<Color>(GovtThemeTokens.secondary),
                            ),
                          ),
                        ),
                        CivicFixSpacing.hSpaceSm,
                        SizedBox(
                          width: 36,
                          child: Text(
                            dept.formattedResolutionPercentage,
                            textAlign: TextAlign.right,
                            style: CivicFixTypography.captionMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: GovtThemeTokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md, vertical: 10),
      child: Text(
        label,
        textAlign: align,
        style: CivicFixTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: GovtThemeTokens.textSecondary,
          letterSpacing: 0.5,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMobileCardList() {
    return Column(
      children: departments.map((dept) {
        return Container(
          margin: const EdgeInsets.only(bottom: CivicFixSpacing.sm),
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surface,
            borderRadius: GovtThemeTokens.cardRadius,
            border: Border.all(color: GovtThemeTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dept.departmentName,
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${dept.total} Total',
                      style: CivicFixTypography.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.primary,
                      ),
                    ),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip('Pending: ${dept.pending}', GovtThemeTokens.alert),
                  _buildStatusChip('In Progress: ${dept.inProgress}', GovtThemeTokens.info),
                  _buildStatusChip('Resolved: ${dept.resolved}', GovtThemeTokens.secondary),
                ],
              ),
              CivicFixSpacing.vSpaceSm,
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: dept.resolutionRate,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5ECE8),
                        valueColor: const AlwaysStoppedAnimation<Color>(GovtThemeTokens.secondary),
                      ),
                    ),
                  ),
                  CivicFixSpacing.hSpaceSm,
                  Text(
                    dept.formattedResolutionPercentage,
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
