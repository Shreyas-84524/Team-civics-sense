import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/civic_ward_model.dart';
import '../../../../services/government_department_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Modal dialog providing comprehensive supervisory drill-down for a single Ward Unit
/// from the Central Department HOD Command Center.
class DepartmentWardUnitDrilldownDialog extends StatefulWidget {
  final CivicWard ward;
  final String departmentId;
  final GovernmentDepartmentDashboardService? dashboardService;
  final ValueChanged<String>? onViewComplaint;

  const DepartmentWardUnitDrilldownDialog({
    super.key,
    required this.ward,
    required this.departmentId,
    this.dashboardService,
    this.onViewComplaint,
  });

  static Future<void> show(
    BuildContext context, {
    required CivicWard ward,
    required String departmentId,
    GovernmentDepartmentDashboardService? dashboardService,
    ValueChanged<String>? onViewComplaint,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DepartmentWardUnitDrilldownDialog(
        ward: ward,
        departmentId: departmentId,
        dashboardService: dashboardService,
        onViewComplaint: onViewComplaint,
      ),
    );
  }

  @override
  State<DepartmentWardUnitDrilldownDialog> createState() => _DepartmentWardUnitDrilldownDialogState();
}

class _DepartmentWardUnitDrilldownDialogState extends State<DepartmentWardUnitDrilldownDialog> {
  late final GovernmentDepartmentDashboardService _service;
  WardDepartmentUnitDetailData? _unitData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.dashboardService ?? GovernmentDepartmentDashboardService();
    _loadUnitData();
  }

  Future<void> _loadUnitData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getWardUnitDetailOverview(
        departmentId: widget.departmentId,
        wardId: widget.ward.wardId,
      );
      if (mounted) {
        setState(() {
          _unitData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);
    final isTablet = GovtResponsive.isTablet(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : (isTablet ? 32 : 64),
        vertical: isMobile ? 16 : 32,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: GovtThemeTokens.elevatedShadow,
          border: Border.all(color: GovtThemeTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildDialogHeader(context),
            const Divider(color: GovtThemeTokens.divider, height: 1),

            // Body Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: GovtThemeTokens.primary),
                    )
                  : (_errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 36),
                              CivicFixSpacing.vSpaceMd,
                              Text(_errorMessage!, style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.error)),
                              CivicFixSpacing.vSpaceMd,
                              ElevatedButton.icon(
                                onPressed: _loadUnitData,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _buildUnitDetailsContent(context)),
            ),

            // Footer
            const Divider(color: GovtThemeTokens.divider, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.lg, vertical: CivicFixSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Central Department Head of Department Supervisory Scope',
                    style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GovtThemeTokens.textSecondary,
                      side: const BorderSide(color: GovtThemeTokens.border),
                      shape: RoundedRectangleBorder(borderRadius: GovtThemeTokens.buttonRadius),
                    ),
                    child: const Text('Close Overview'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GovtThemeTokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment_rounded, color: GovtThemeTokens.primary, size: 24),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ward ${widget.ward.wardCode} — ${widget.ward.wardName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CivicFixTypography.h3.copyWith(
                          color: GovtThemeTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CivicFixSpacing.hSpaceSm,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primaryDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.ward.zoneId,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Department Ward Operational Unit Audit & Personnel Oversight',
                  style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: GovtThemeTokens.textMuted),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDetailsContent(BuildContext context) {
    final data = _unitData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KPI Metric Badges Row
          _buildKpiRow(data),
          CivicFixSpacing.vSpaceLg,

          // 2. Department Lead Profile & 5 Crew Members
          _buildPersonnelCard(data),
          CivicFixSpacing.vSpaceLg,

          // 3. Recent Unit Complaints Table
          _buildRecentComplaintsSection(data),
        ],
      ),
    );
  }

  Widget _buildKpiRow(WardDepartmentUnitDetailData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 600 ? 4 : 2;

        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: CivicFixSpacing.md,
          mainAxisSpacing: CivicFixSpacing.md,
          childAspectRatio: 2.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _kpiTile('Open Complaints', '${data.openComplaints}', GovtThemeTokens.primary, Icons.pending_actions_rounded),
            _kpiTile('Critical Hazards', '${data.criticalComplaints}',
                data.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.success, Icons.emergency_rounded),
            _kpiTile('SLA Compliance', data.slaComplianceRate != null ? '${data.slaComplianceRate!.toStringAsFixed(1)}%' : 'N/A',
                (data.slaComplianceRate ?? 100) >= 80 ? GovtThemeTokens.success : GovtThemeTokens.warning, Icons.verified_user_outlined),
            _kpiTile('Total Resolved', '${data.resolvedComplaints}', GovtThemeTokens.success, Icons.task_alt_rounded),
          ],
        );
      },
    );
  }

  Widget _kpiTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 11)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.h3.copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonnelCard(WardDepartmentUnitDetailData data) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WARD OPERATIONAL PERSONNEL',
                style: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '1 Lead · ${data.crewMembers.length} Crew',
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          // Ward Lead Card
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.sm),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GovtThemeTokens.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: GovtThemeTokens.primary.withValues(alpha: 0.1),
                  child: Text(
                    data.lead.initials,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.lead.fullName,
                        style: CivicFixTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      Text(
                        '${data.lead.displayDesignation} · ${data.lead.employeeId}',
                        style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  data.lead.phone,
                  style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.primaryDark),
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          Text(
            'Assigned Technical Maintenance Crew (${data.crewMembers.length}):',
            style: CivicFixTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textSecondary,
            ),
          ),
          CivicFixSpacing.vSpaceSm,
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: data.crewMembers.map((c) {
              return Chip(
                avatar: const Icon(Icons.build_circle_outlined, size: 14, color: GovtThemeTokens.secondary),
                label: Text('${c.fullName} (${c.employeeId})', style: const TextStyle(fontSize: 11)),
                backgroundColor: GovtThemeTokens.surface,
                side: const BorderSide(color: GovtThemeTokens.borderLight),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentComplaintsSection(WardDepartmentUnitDetailData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT UNIT GRIEVANCES',
          style: CivicFixTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: GovtThemeTokens.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        CivicFixSpacing.vSpaceSm,
        if (data.recentComplaints.isEmpty)
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No grievances reported in this ward unit.',
              style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textMuted),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.recentComplaints.length,
            separatorBuilder: (context, index) => const Divider(color: GovtThemeTokens.divider, height: 1),
            itemBuilder: (context, index) {
              final c = data.recentComplaints[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                title: Text(
                  c.title,
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id} · ${c.location.address}',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
                    CivicFixSpacing.hSpaceSm,
                    GovtStatusBadge.complaint(c.status, isCompact: true),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
