import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/civic_ward_model.dart';
import '../../../../services/government_zone_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Modal dialog providing comprehensive supervisory drill-down for a single Ward
/// from the Deputy Municipal Commissioner's Zonal Command Center.
class ZoneWardDrilldownDialog extends StatefulWidget {
  final CivicWard ward;
  final String zoneId;
  final GovernmentZoneDashboardService? dashboardService;
  final ValueChanged<String>? onViewComplaint;

  const ZoneWardDrilldownDialog({
    super.key,
    required this.ward,
    required this.zoneId,
    this.dashboardService,
    this.onViewComplaint,
  });

  static Future<void> show(
    BuildContext context, {
    required CivicWard ward,
    required String zoneId,
    GovernmentZoneDashboardService? dashboardService,
    ValueChanged<String>? onViewComplaint,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ZoneWardDrilldownDialog(
        ward: ward,
        zoneId: zoneId,
        dashboardService: dashboardService,
        onViewComplaint: onViewComplaint,
      ),
    );
  }

  @override
  State<ZoneWardDrilldownDialog> createState() => _ZoneWardDrilldownDialogState();
}

class _ZoneWardDrilldownDialogState extends State<ZoneWardDrilldownDialog> {
  late final GovernmentZoneDashboardService _service;
  WardDetailOverviewData? _wardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.dashboardService ?? GovernmentZoneDashboardService();
    _loadWardData();
  }

  Future<void> _loadWardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getWardDetailOverview(
        zoneId: widget.zoneId,
        wardId: widget.ward.wardId,
      );
      if (mounted) {
        setState(() {
          _wardData = data;
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
                                onPressed: _loadWardData,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _buildWardDetailsContent(context)),
            ),

            // Footer
            const Divider(color: GovtThemeTokens.divider, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.lg, vertical: CivicFixSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deputy Municipal Commissioner Supervisory Scope',
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
            child: const Icon(Icons.location_city_rounded, color: GovtThemeTokens.primary, size: 24),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ward ${widget.ward.wardCode} — ${widget.ward.wardName}',
                      style: CivicFixTypography.h3.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
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
                  'Comprehensive Ward Administrative & Technical Operational Audit',
                  style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: GovtThemeTokens.textSecondary),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildWardDetailsContent(BuildContext context) {
    final data = _wardData!;
    final isMobile = GovtResponsive.isMobile(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: KPI Stat Chips
          Wrap(
            spacing: CivicFixSpacing.md,
            runSpacing: CivicFixSpacing.md,
            children: [
              _buildStatChip('Open Complaints', '${data.openComplaints}', Icons.pending_actions_rounded, GovtThemeTokens.primary),
              _buildStatChip('Critical Grievances', '${data.criticalComplaints}', Icons.emergency_rounded, data.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
              _buildStatChip('Resolved Today', '${data.resolvedComplaints}', Icons.task_alt_rounded, GovtThemeTokens.success),
              _buildStatChip('SLA Compliance', data.slaComplianceRate != null ? '${data.slaComplianceRate!.toStringAsFixed(1)}%' : 'N/A', Icons.verified_user_outlined, (data.slaComplianceRate ?? 100) >= 80 ? GovtThemeTokens.success : GovtThemeTokens.warning),
              _buildStatChip('SLA Breaches', '${data.slaBreachedComplaints}', Icons.timer_off_outlined, data.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
              _buildStatChip('Assigned Crew', '${data.crewCount}', Icons.groups_rounded, GovtThemeTokens.textSecondary),
            ],
          ),

          CivicFixSpacing.vSpaceLg,

          // Row 2: Ward Officer in charge
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GovtThemeTokens.borderLight),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: GovtThemeTokens.primary,
                  radius: 20,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WARD OFFICER / ASSISTANT COMMISSIONER',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        data.wardOfficer?.fullName ?? 'Assistant Commissioner (${widget.ward.wardCode})',
                        style: CivicFixTypography.bodySmall.copyWith(
                          color: GovtThemeTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Employee ID: ${data.wardOfficer?.employeeId ?? 'EMP-WO-${widget.ward.wardCode}'} · Email: ${data.wardOfficer?.email ?? 'ac.${widget.ward.wardCode.toLowerCase()}@mcgm.gov.in'}',
                        style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          CivicFixSpacing.vSpaceLg,

          // Row 3: Department Breakdown & Recent Complaints Grid
          if (isMobile) ...[
            _buildDepartmentBreakdownCard(data),
            CivicFixSpacing.vSpaceLg,
            _buildRecentComplaintsCard(data),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildDepartmentBreakdownCard(data),
                ),
                CivicFixSpacing.hSpaceLg,
                Expanded(
                  flex: 6,
                  child: _buildRecentComplaintsCard(data),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      width: 135,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          CivicFixSpacing.hSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10),
                ),
                Text(
                  value,
                  style: CivicFixTypography.bodySmall.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBreakdownCard(WardDetailOverviewData data) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded, size: 16, color: GovtThemeTokens.primary),
              CivicFixSpacing.hSpaceSm,
              Text(
                'DEPARTMENT BREAKDOWN',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          if (data.departmentBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.md),
              child: Text(
                'No complaints registered in this ward.',
                style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
              ),
            )
          else
            ...data.departmentBreakdown.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: GovtThemeTokens.borderLight),
                        ),
                        child: Text(
                          '${e.value}',
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildRecentComplaintsCard(WardDetailOverviewData data) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 16, color: GovtThemeTokens.primary),
              CivicFixSpacing.hSpaceSm,
              Text(
                'RECENT WARD COMPLAINTS',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: GovtThemeTokens.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${data.recentComplaints.length} Shown',
                style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          if (data.recentComplaints.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.md),
              child: Text(
                'No complaints logged yet.',
                style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.recentComplaints.length,
              separatorBuilder: (context, index) => const Divider(color: GovtThemeTokens.divider, height: 1),
              itemBuilder: (context, index) {
                final complaint = data.recentComplaints[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.ticketNumber,
                              style: CivicFixTypography.caption.copyWith(
                                color: GovtThemeTokens.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              complaint.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CivicFixTypography.bodySmall.copyWith(
                                color: GovtThemeTokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              complaint.effectiveDepartment,
                              style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      GovtPriorityBadge.fromPriority(complaint.priority, isCompact: true),
                      CivicFixSpacing.hSpaceXs,
                      GovtStatusBadge.complaint(complaint.status, isCompact: true),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
