import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Department Lead Directory Section for Central Department HOD command center.
/// Shows directory of all 24 Ward Department Unit Leads with direct supervisory contacts.
class DepartmentLeadDirectorySection extends StatefulWidget {
  final List<WardDepartmentUnitPerformanceData> departmentLeads;
  final bool isLoading;
  final ValueChanged<WardDepartmentUnitPerformanceData>? onInspectUnit;

  const DepartmentLeadDirectorySection({
    super.key,
    required this.departmentLeads,
    this.isLoading = false,
    this.onInspectUnit,
  });

  @override
  State<DepartmentLeadDirectorySection> createState() =>
      _DepartmentLeadDirectorySectionState();
}

class _DepartmentLeadDirectorySectionState
    extends State<DepartmentLeadDirectorySection> {
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
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.contact_phone_outlined,
                    color: GovtThemeTokens.primary, size: 20),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WARD DEPARTMENT LEADS DIRECTORY (24 LEADS)',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Direct contacts and operational status for Executive Engineers across all 24 wards',
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
                  color: GovtThemeTokens.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: GovtThemeTokens.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${widget.departmentLeads.length} Leads',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceMd,

          if (!widget.isLoading && widget.departmentLeads.isNotEmpty) ...[
            SizedBox(
              width: isMobile ? double.infinity : 280,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: CivicFixTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search lead name or ward...',
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
          else if (widget.departmentLeads.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(CivicFixSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.person_off_outlined,
                        size: 40, color: GovtThemeTokens.textMuted),
                    CivicFixSpacing.vSpaceSm,
                    Text(
                      'No lead directory data available.',
                      style: CivicFixTypography.bodyMedium
                          .copyWith(color: GovtThemeTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildDirectoryGrid(context, isMobile),
        ],
      ),
    );
  }

  List<WardDepartmentUnitPerformanceData> get _filteredLeads {
    if (_searchQuery.trim().isEmpty) return widget.departmentLeads;
    final q = _searchQuery.toLowerCase().trim();
    return widget.departmentLeads.where((unit) {
      return unit.wardCode.toLowerCase().contains(q) ||
          unit.wardName.toLowerCase().contains(q) ||
          unit.leadName.toLowerCase().contains(q) ||
          unit.zoneDisplayName.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildDirectoryGrid(BuildContext context, bool isMobile) {
    final leads = _filteredLeads;

    if (leads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Text(
            'No ward leads match "$_searchQuery"',
            style: CivicFixTypography.bodyMedium
                .copyWith(color: GovtThemeTokens.textSecondary),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile
            ? 1
            : constraints.maxWidth > 900
                ? 3
                : 2;
        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 12)) /
                crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: leads.map((unit) {
            return SizedBox(
              width: itemWidth,
              child: _buildLeadCard(context, unit),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLeadCard(
      BuildContext context, WardDepartmentUnitPerformanceData unit) {
    final lead = unit.lead;
    final phone = lead?.phone ?? '+91 22 2262 0251';
    final email = lead?.email ??
        'ee.${unit.wardCode.toLowerCase()}@mcgm.gov.in';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: GovtThemeTokens.primaryDark,
                child: Text(
                  unit.wardCode,
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.leadName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GovtThemeTokens.textPrimary,
                      ),
                    ),
                    Text(
                      'Ward ${unit.wardCode} (${unit.zoneDisplayName})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          const Divider(color: GovtThemeTokens.divider, height: 1),
          CivicFixSpacing.vSpaceSm,

          // Contact details
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: GovtThemeTokens.textSecondary),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  phone,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXs,
          Row(
            children: [
              const Icon(Icons.email_outlined,
                  size: 14, color: GovtThemeTokens.textSecondary),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Open', '${unit.openComplaints}'),
              _buildMiniStat('Critical', '${unit.criticalComplaints}',
                  isCritical: unit.criticalComplaints > 0),
              _buildMiniStat('Crew', '${unit.crewCount}'),
              _buildMiniStat('SLA',
                  '${(unit.slaComplianceRate ?? 100).toStringAsFixed(0)}%'),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          // Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onInspectUnit?.call(unit),
              icon: const Icon(Icons.visibility_outlined, size: 14),
              label: const Text('View Ward Unit'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 6),
                textStyle: CivicFixTypography.caption
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, {bool isCritical = false}) {
    return Column(
      children: [
        Text(
          val,
          style: CivicFixTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isCritical
                ? GovtThemeTokens.error
                : GovtThemeTokens.textPrimary,
          ),
        ),
        Text(
          label,
          style: CivicFixTypography.caption.copyWith(
            color: GovtThemeTokens.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
