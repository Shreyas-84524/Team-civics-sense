import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/civic_department_model.dart';
import '../../../../services/government_ward_dashboard_service.dart';
import '../../../../theme/govt_responsive.dart';
import '../../../../theme/govt_theme_tokens.dart';
import '../../../common/govt_priority_badge.dart';
import '../../../common/govt_status_badge.dart';

/// Modal dialog providing comprehensive supervisory drill-down for a single Department Unit
/// inside the Ward from the Assistant Commissioner / Ward Officer Command Center.
class WardDepartmentDrilldownDialog extends StatefulWidget {
  final CivicDepartment department;
  final String wardId;
  final GovernmentWardDashboardService? dashboardService;
  final ValueChanged<String>? onViewComplaint;

  const WardDepartmentDrilldownDialog({
    super.key,
    required this.department,
    required this.wardId,
    this.dashboardService,
    this.onViewComplaint,
  });

  static Future<void> show(
    BuildContext context, {
    required CivicDepartment department,
    required String wardId,
    GovernmentWardDashboardService? dashboardService,
    ValueChanged<String>? onViewComplaint,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => WardDepartmentDrilldownDialog(
        department: department,
        wardId: wardId,
        dashboardService: dashboardService,
        onViewComplaint: onViewComplaint,
      ),
    );
  }

  @override
  State<WardDepartmentDrilldownDialog> createState() => _WardDepartmentDrilldownDialogState();
}

class _WardDepartmentDrilldownDialogState extends State<WardDepartmentDrilldownDialog> {
  late final GovernmentWardDashboardService _service;
  WardDepartmentDetailData? _unitData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.dashboardService ?? GovernmentWardDashboardService();
    _loadUnitData();
  }

  Future<void> _loadUnitData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getDepartmentUnitDetailData(
        wardId: widget.wardId,
        departmentId: widget.department.departmentId,
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
                  Expanded(
                    child: Text(
                      'Ward Officer Administrative Inspection · ${widget.department.displayName}',
                      style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${widget.department.displayName} Unit',
                      style: CivicFixTypography.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GovtThemeTokens.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${widget.wardId} WARD',
                        style: CivicFixTypography.captionMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.primaryDark,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Supervisory unit oversight for ${widget.department.displayName} operations in Ward ${widget.wardId}',
                  style: CivicFixTypography.captionMedium.copyWith(color: GovtThemeTokens.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDetailsContent(BuildContext context) {
    final d = _unitData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Lead Information & Unit Metrics
          _buildLeadAndMetrics(context, d),

          CivicFixSpacing.vSpaceLg,

          // Section 2: Authorised Field Crew Members (5 Technicians)
          _buildCrewMembersList(context, d),

          CivicFixSpacing.vSpaceLg,

          // Section 3: Recent Grievances in this Unit
          _buildRecentComplaintsList(context, d),

          CivicFixSpacing.vSpaceLg,

          // Section 4: Routing Requests & Audit Trail
          _buildRoutingAndAuditSection(context, d),
        ],
      ),
    );
  }

  Widget _buildLeadAndMetrics(BuildContext context, WardDepartmentDetailData d) {
    final lead = d.lead;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lead Card
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: GovtThemeTokens.primary,
                      child: Text(
                        lead?.initials ?? 'EE',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead?.fullName ?? 'Executive Engineer',
                            style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            lead?.displayDesignation ?? 'Ward Department Lead',
                            style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,
                const Divider(color: GovtThemeTokens.divider, height: 1),
                CivicFixSpacing.vSpaceSm,
                _infoRow('Employee ID', lead?.employeeId ?? 'GOV-LEAD-${d.ward.wardCode}'),
                _infoRow('Email', lead?.email ?? 'lead@mcgm.gov.in'),
                _infoRow('Phone', lead?.phone ?? '+91 22 2262 0251'),
              ],
            ),
          ),
        ),
        CivicFixSpacing.hSpaceMd,
        // Unit Stats
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATIONAL UNIT KPI SUMMARY',
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricMiniCard('Total', '${d.totalComplaints}', GovtThemeTokens.primary),
                    _metricMiniCard('Open', '${d.openComplaints}', GovtThemeTokens.info),
                    _metricMiniCard('Critical', '${d.criticalComplaints}', d.criticalComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
                    _metricMiniCard('Resolved', '${d.resolvedComplaints}', GovtThemeTokens.success),
                    _metricMiniCard('SLA Breached', '${d.slaBreachedComplaints}', d.slaBreachedComplaints > 0 ? GovtThemeTokens.error : GovtThemeTokens.success),
                    _metricMiniCard('SLA Rate', d.slaComplianceRate != null ? '${d.slaComplianceRate!.toStringAsFixed(1)}%' : 'N/A', GovtThemeTokens.secondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted)),
          CivicFixSpacing.hSpaceSm,
          Flexible(
            child: Text(
              value,
              style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricMiniCard(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: CivicFixTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildCrewMembersList(BuildContext context, WardDepartmentDetailData d) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'AUTHORISED FIELD CREW (${d.crewMembers.length} TECHNICIANS)',
                style: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GovtThemeTokens.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Full Roster Active',
                  style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.success, fontWeight: FontWeight.w600, fontSize: 10),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          if (d.crewMembers.isEmpty)
            Text(
              'No individual crew records registered. Standard allocation: 5 field technicians.',
              style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: d.crewMembers.map((crew) {
                return Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GovtThemeTokens.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.handyman_rounded, color: GovtThemeTokens.textSecondary, size: 16),
                      CivicFixSpacing.hSpaceSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(crew.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text(crew.employeeId, style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentComplaintsList(BuildContext context, WardDepartmentDetailData d) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE & RECENT GRIEVANCES IN UNIT (${d.recentComplaints.length})',
            style: CivicFixTypography.captionMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: GovtThemeTokens.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          CivicFixSpacing.vSpaceMd,
          if (d.recentComplaints.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.md),
              child: Center(
                child: Text('No active complaints in this unit.', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted)),
              ),
            )
          else
            ...d.recentComplaints.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: widget.onViewComplaint != null ? () => widget.onViewComplaint!(c.id) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GovtThemeTokens.borderLight),
                      ),
                      child: Row(
                        children: [
                          Text(c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id,
                              style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, color: GovtThemeTokens.primary)),
                          CivicFixSpacing.hSpaceMd,
                          Expanded(
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CivicFixTypography.bodySmall,
                            ),
                          ),
                          GovtPriorityBadge.fromPriority(c.priority, isCompact: true),
                          CivicFixSpacing.hSpaceSm,
                          GovtStatusBadge.complaint(c.status, isCompact: true),
                        ],
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildRoutingAndAuditSection(BuildContext context, WardDepartmentDetailData d) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Routing requests
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROUTING TICKETS (${d.routingTickets.length})',
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                if (d.routingTickets.isEmpty)
                  Text('Zero pending routing transfers.', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted))
                else
                  ...d.routingTickets.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• Ticket ${t.ticketNumber}: ${t.reason}',
                            style: CivicFixTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                      )),
              ],
            ),
          ),
        ),
        CivicFixSpacing.hSpaceMd,
        // Audit Logs
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GovtThemeTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT UNIT ACTIVITY (${d.recentAuditLogs.length})',
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GovtThemeTokens.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,
                if (d.recentAuditLogs.isEmpty)
                  Text('No recent administrative events recorded.', style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textMuted))
                else
                  ...d.recentAuditLogs.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${l.action.replaceAll('_', ' ')} by ${l.actorName}',
                            style: CivicFixTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
