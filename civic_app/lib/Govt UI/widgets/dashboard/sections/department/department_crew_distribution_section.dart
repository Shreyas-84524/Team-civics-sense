import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Department Crew Distribution & Workload Section for Central Department HOD command center.
/// Shows crew deployment and active tasks across all 24 ward operational units (5 crew per ward = 120 total).
class DepartmentCrewDistributionSection extends StatefulWidget {
  final List<WardCrewDistributionData> crewDistribution;
  final bool isLoading;

  const DepartmentCrewDistributionSection({
    super.key,
    required this.crewDistribution,
    this.isLoading = false,
  });

  @override
  State<DepartmentCrewDistributionSection> createState() =>
      _DepartmentCrewDistributionSectionState();
}

class _DepartmentCrewDistributionSectionState
    extends State<DepartmentCrewDistributionSection> {
  String _searchQuery = '';

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
                  color: GovtThemeTokens.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups_outlined,
                    color: GovtThemeTokens.info, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIELD CREW DISTRIBUTION & WORKLOAD (120 TECHNICIANS)',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Operational crew deployment and task dispatch across all 24 ward units (5 crew per ward)',
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
                  color: GovtThemeTokens.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.info.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.crewDistribution.length} Ward Units',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (!widget.isLoading && widget.crewDistribution.isNotEmpty) ...[
            SizedBox(
              width: isMobile ? double.infinity : 280,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: CivicFixTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search ward name or code...',
                  hintStyle: CivicFixTypography.bodySmall
                      .copyWith(color: GovtThemeTokens.textMuted),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: GovtThemeTokens.textSecondary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GovtThemeTokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GovtThemeTokens.border),
                  ),
                ),
              ),
            ),
            CivicFixSpacing.vSpaceMd,
          ],

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(CivicFixSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (widget.crewDistribution.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 40, color: GovtThemeTokens.textMuted),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No crew distribution data available.',
                      style: CivicFixTypography.bodyMedium
                          .copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildCrewTable(context, isMobile),
        ],
      ),
    );
  }

  List<WardCrewDistributionData> get _filteredCrewList {
    if (_searchQuery.trim().isEmpty) return widget.crewDistribution;
    final q = _searchQuery.toLowerCase().trim();
    return widget.crewDistribution.where((c) {
      return c.wardCode.toLowerCase().contains(q) ||
          c.wardName.toLowerCase().contains(q) ||
          c.zone.displayName.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildCrewTable(BuildContext context, bool isMobile) {
    final list = _filteredCrewList;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Text(
            'No ward crew units match "$_searchQuery"',
            style: CivicFixTypography.bodyMedium
                .copyWith(color: GovtThemeTokens.textSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          GovtThemeTokens.surfaceVariant.withValues(alpha: 0.5),
        ),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        horizontalMargin: 16,
        columnSpacing: 24,
        columns: [
          DataColumn(
            label: Text(
              'WARD UNIT',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'ZONE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'CREW SIZE',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'ASSIGNED JOBS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'IN-PROGRESS',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'VERIFICATION',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'STANDBY CREW',
              style: CivicFixTypography.captionMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: GovtThemeTokens.textSecondary,
              ),
            ),
            numeric: true,
          ),
        ],
        rows: list.map((c) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.wardCode,
                        style: CivicFixTypography.caption.copyWith(
                          fontWeight: FontWeight.w800,
                          color: GovtThemeTokens.primaryDark,
                        ),
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Text(
                      c.wardName,
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  c.zone.displayName,
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${c.crewMembers.length} Crew',
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${c.assignedJobsCount}',
                  style: CivicFixTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${c.inProgressJobsCount}',
                  style: CivicFixTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.info,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${c.awaitingVerificationJobsCount}',
                  style: CivicFixTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.warning,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.availableCrewCount > 0
                        ? GovtThemeTokens.success.withValues(alpha: 0.1)
                        : GovtThemeTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${c.availableCrewCount} Available',
                    style: CivicFixTypography.captionMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.availableCrewCount > 0
                          ? GovtThemeTokens.success
                          : GovtThemeTokens.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
