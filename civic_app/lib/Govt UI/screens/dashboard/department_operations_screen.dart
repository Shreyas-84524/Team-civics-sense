import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_department_lead_dashboard_service.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../auth/government_access_denied_screen.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_assign_dialog.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_awaiting_verification_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_complaint_detail_dialog.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_complaint_queue_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_completed_work_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_crew_workload_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_critical_complaints_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_kpi_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_manual_verification_dialog.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_manual_verification_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_map_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_operations_funnel_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_recent_activity_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_routing_dialog.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_routing_requests_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_sla_monitor_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_unassigned_section.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_verification_dialog.dart';

/// Phase 7 — Ward Department Lead Operations Dashboard Screen.
///
/// Authoritative Operational Command Center for the Ward Department Lead role:
/// - Strictly scoped to 1 Ward × 1 Department × 5 Authorized Crew Members
/// - Immutable Ward and Department authority from session
/// - Unassigned complaint triage and ground crew technician dispatch
/// - Crew workload monitoring and capacity management
/// - 48-Hour SLA monitoring, overdue tracking, and breakdown analytics
/// - Wrong-Department reassignment ticket creation without self-approval authority
/// - Completion verification, resolution certification, and return-for-rework workflow
/// - GIS Spatial telemetry and grievance hotspots strictly within this unit
/// - Unit-scoped immutable audit activity trail
class DepartmentOperationsScreen extends StatefulWidget {
  final GovtUserModel? user;
  final GovernmentDepartmentLeadDashboardService? dashboardService;

  const DepartmentOperationsScreen({
    super.key,
    this.user,
    this.dashboardService,
  });

  @override
  State<DepartmentOperationsScreen> createState() =>
      _DepartmentOperationsScreenState();
}

class _DepartmentOperationsScreenState
    extends State<DepartmentOperationsScreen> {
  late final GovernmentDepartmentLeadDashboardService _dashboardService;
  final ScrollController _scrollController = ScrollController();

  // Section Keys for Quick Navigation Anchoring
  final GlobalKey _kpiKey = GlobalKey();
  final GlobalKey _funnelKey = GlobalKey();
  final GlobalKey _manualVerificationKey = GlobalKey();
  final GlobalKey _unassignedKey = GlobalKey();
  final GlobalKey _complaintsKey = GlobalKey();
  final GlobalKey _crewKey = GlobalKey();
  final GlobalKey _verificationKey = GlobalKey();
  final GlobalKey _slaKey = GlobalKey();
  final GlobalKey _routingKey = GlobalKey();
  final GlobalKey _completedKey = GlobalKey();
  final GlobalKey _criticalKey = GlobalKey();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _activityKey = GlobalKey();

  DepartmentLeadDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _searchDebounce;
  int _loadGeneration = 0;

  // Unit-Level Filters (Ward and Dept are IMMUTABLE from session)
  ComplaintPriority? _selectedPriority;
  ComplaintStatus? _selectedStatus;
  String? _selectedCrew;
  String? _selectedSla;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ??
        GovernmentDepartmentLeadDashboardService();
    _loadDashboard();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _resolveWardId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.wardId != null && activeUser!.wardId!.isNotEmpty) {
      return activeUser.wardId!;
    }
    return 'N'; // Canonical ward fallback
  }

  String _resolveDepartmentId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.departmentId != null &&
        activeUser!.departmentId!.isNotEmpty) {
      return activeUser.departmentId!;
    }
    return 'maintenance_roads'; // Canonical department fallback
  }

  Future<void> _loadDashboard() async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final wardId = _resolveWardId();
    final deptId = _resolveDepartmentId();

    try {
      final data = await _dashboardService.loadDepartmentLeadDashboard(
        wardId: wardId,
        departmentId: deptId,
        priorityFilter: _selectedPriority,
        statusFilter: _selectedStatus,
        crewFilter: _selectedCrew,
        slaFilter: _selectedSla,
        searchQuery: _searchQuery,
      );

      if (mounted && generation == _loadGeneration) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onPriorityChanged(ComplaintPriority? p) {
    setState(() => _selectedPriority = p);
    _loadDashboard();
  }

  void _onStatusChanged(ComplaintStatus? s) {
    setState(() => _selectedStatus = s);
    _loadDashboard();
  }

  void _onCrewChanged(String? c) {
    setState(() => _selectedCrew = c);
    _loadDashboard();
  }

  void _onSlaChanged(String? sla) {
    setState(() => _selectedSla = sla);
    _loadDashboard();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadDashboard);
  }

  void _onResetFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _selectedPriority = null;
      _selectedStatus = null;
      _selectedCrew = null;
      _selectedSla = null;
      _searchQuery = '';
    });
    _loadDashboard();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // Dialog Handlers
  void _openAssignDialog(ComplaintModel complaint) {
    final data = _dashboardData;
    if (data == null) return;

    showDialog(
      context: context,
      builder: (ctx) => DepartmentLeadAssignDialog(
        complaint: complaint,
        crewWorkloads: data.crewWorkload,
        leadId: data.leadUser.employeeId,
        onAssignConfirmed: (crewId) async {
          await _dashboardService.assignCrewMember(
            complaintId: complaint.id,
            leadId: data.leadUser.employeeId,
            crewMemberId: crewId,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Grievance ${complaint.ticketNumber} assigned to crew member $crewId.'),
                backgroundColor: GovtThemeTokens.success,
              ),
            );
            _loadDashboard();
          }
        },
      ),
    );
  }

  void _openReassignDialog(ComplaintModel complaint) {
    _openAssignDialog(complaint);
  }

  void _openRoutingDialog(ComplaintModel complaint) {
    final data = _dashboardData;
    if (data == null) return;

    showDialog(
      context: context,
      builder: (ctx) => DepartmentLeadRoutingDialog(
        complaint: complaint,
        sourceDepartmentId: data.department.departmentId,
        allDepartments: data.allDepartments,
        onTicketSubmitted: ({
          required suggestedDepartmentId,
          required reason,
          remarks,
        }) async {
          await _dashboardService.raiseRoutingRequest(
            complaintId: complaint.id,
            sourceLeadId: data.leadUser.employeeId,
            suggestedDepartmentId: suggestedDepartmentId,
            reason: reason,
            remarks: remarks,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Wrong Department ticket submitted for Ward Officer approval.'),
                backgroundColor: Color(0xFFF97316),
              ),
            );
            _loadDashboard();
          }
        },
      ),
    );
  }

  void _openVerificationDialog(ComplaintModel complaint) {
    final data = _dashboardData;
    if (data == null) return;

    showDialog(
      context: context,
      builder: (ctx) => DepartmentLeadVerificationDialog(
        complaint: complaint,
        leadId: data.leadUser.employeeId,
        onVerificationCompleted: ({
          required notes,
          returnForRework = false,
          reworkReason,
        }) async {
          final success = await _dashboardService.verifyCompletion(
            complaintId: complaint.id,
            leadId: data.leadUser.employeeId,
            notes: notes,
            returnForRework: returnForRework,
            reworkReason: reworkReason,
          );
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(returnForRework
                    ? 'Work returned for field rework.'
                    : 'Grievance certified verified & resolved.'),
                backgroundColor: returnForRework
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            );
            _loadDashboard();
          }
        },
      ),
    );
  }

  void _openManualVerificationDialog(ComplaintModel complaint) {
    final data = _dashboardData;
    if (data == null) return;

    showDialog(
      context: context,
      builder: (ctx) => DepartmentLeadManualVerificationDialog(
        complaint: complaint,
        leadId: data.leadUser.employeeId,
        allDepartments: data.allDepartments,
        onSubmitDecision: ({
          required belongsToCurrentDepartment,
          targetDepartmentId,
          required remarks,
        }) async {
          await _dashboardService.submitHumanVerificationDecision(
            complaintId: complaint.id,
            leadId: data.leadUser.employeeId,
            belongsToCurrentDepartment: belongsToCurrentDepartment,
            targetDepartmentId: targetDepartmentId,
            remarks: remarks,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(belongsToCurrentDepartment
                    ? 'Complaint confirmed for ${data.department.displayName} and auto-routed to Junior Engineer.'
                    : 'Complaint transferred to target department and auto-routed.'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            _loadDashboard();
          }
        },
      ),
    );
  }

  void _openComplaintDetails(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (ctx) => DepartmentLeadComplaintDetailDialog(
        complaint: complaint,
        onAssignCrew: () => _openAssignDialog(complaint),
        onReassignCrew: () => _openReassignDialog(complaint),
        onRaiseRoutingTicket: () => _openRoutingDialog(complaint),
        onVerifyCompletion: () => _openVerificationDialog(complaint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;

    // Strict Role-Based Access Control Gate (Strictly ward_department_lead)
    if (activeUser == null || !activeUser.isWardLead) {
      return GovernmentAccessDeniedScreen(user: activeUser);
    }

    final deptName = _dashboardData?.department.displayName ?? 'Department Operations';
    final wardName = _dashboardData?.ward.wardName ?? '${_resolveWardId()} Ward';
    final wardCode = _dashboardData?.ward.wardCode ?? _resolveWardId();

    final headerTitle = '$deptName — $wardName';
    const headerSubtitle =
        'Operational management of complaints and field crew for this ward department.';

    const breadcrumbs = [
      GovtBreadcrumbItem(
          label: 'Home', route: AppRoutes.governmentDepartmentOperations),
      GovtBreadcrumbItem(label: 'Department Operations'),
    ];

    return GovernmentAppShell(
      title: headerTitle,
      subtitle: headerSubtitle,
      breadcrumbs: breadcrumbs,
      selectedIndex: 5,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.pushNamed(context, AppRoutes.governmentComplaints);
        } else if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.govtHazardMap);
        } else if (index == 3) {
          Navigator.pushNamed(context, AppRoutes.governmentAnalytics);
        } else if (index == 4) {
          Navigator.pushNamed(context, AppRoutes.governmentSettings);
        }
      },
      body: _isLoading && _dashboardData == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(CivicFixSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: GovtThemeTokens.alert),
                        CivicFixSpacing.vSpaceMd,
                        Text(
                          'Failed to load operations dashboard',
                          style: CivicFixTypography.h3,
                        ),
                        CivicFixSpacing.vSpaceSm,
                        Text(
                          _errorMessage!,
                          style: CivicFixTypography.bodySmall.copyWith(
                            color: GovtThemeTokens.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        CivicFixSpacing.vSpaceLg,
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          onPressed: _loadDashboard,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isLoading) const LinearProgressIndicator(),
                      // Page Header with Refresh Action
                      GovernmentPageHeader(
                        primaryAction: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _loadDashboard,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                        title: headerTitle,
                        subtitle: headerSubtitle,
                        breadcrumbs: breadcrumbs,
                      ),

                      // Quick Jump Anchor Bar
                      _buildQuickJumpBar(context),

                      // Dashboard Body Content
                      Padding(
                        padding: EdgeInsets.all(
                          MediaQuery.sizeOf(context).width < 600
                              ? CivicFixSpacing.md
                              : CivicFixSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Top KPI Grid (Section 6)
                            Container(
                              key: _kpiKey,
                              child: DepartmentLeadKpiSection(
                                metrics: _dashboardData!.kpiMetrics,
                                onKpiTapped: (kpiKey) {
                                  if (kpiKey == 'unassigned') {
                                    _scrollToSection(_unassignedKey);
                                  } else if (kpiKey == 'awaiting_verification') {
                                    _scrollToSection(_verificationKey);
                                  } else if (kpiKey == 'critical') {
                                    _scrollToSection(_criticalKey);
                                  } else if (kpiKey == 'resolved_today') {
                                    _scrollToSection(_completedKey);
                                  } else {
                                    _scrollToSection(_complaintsKey);
                                  }
                                },
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 2. Compact Operations Funnel (Section 7)
                            Container(
                              key: _funnelKey,
                              child: DepartmentLeadOperationsFunnelSection(
                                funnel: _dashboardData!.operationsFunnel,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // AI Verification Fallback Review Section
                            Container(
                              key: _manualVerificationKey,
                              child: DepartmentLeadManualVerificationSection(
                                manualVerificationComplaints:
                                    _dashboardData!.manualVerificationComplaints,
                                onReviewComplaint: _openManualVerificationDialog,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 3. Needs Assignment Section (Section 9)
                            Container(
                              key: _unassignedKey,
                              child: DepartmentLeadUnassignedSection(
                                unassignedComplaints:
                                    _dashboardData!.unassignedComplaints,
                                onAssignCrew: _openAssignDialog,
                                onViewDetails: _openComplaintDetails,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 4. Primary Complaint Queue (Section 8)
                            Container(
                              key: _complaintsKey,
                              child: DepartmentLeadComplaintQueueSection(
                                complaints:
                                    _dashboardData!.filteredComplaints,
                                crewMembers: _dashboardData!.crewMembers,
                                selectedPriority: _selectedPriority,
                                selectedStatus: _selectedStatus,
                                selectedCrew: _selectedCrew,
                                selectedSla: _selectedSla,
                                searchQuery: _searchQuery,
                                onPriorityChanged: _onPriorityChanged,
                                onStatusChanged: _onStatusChanged,
                                onCrewChanged: _onCrewChanged,
                                onSlaChanged: _onSlaChanged,
                                onSearchChanged: _onSearchChanged,
                                onResetFilters: _onResetFilters,
                                onViewDetails: _openComplaintDetails,
                                onAssignCrew: _openAssignDialog,
                                onReassignCrew: _openReassignDialog,
                                onRaiseRoutingTicket: _openRoutingDialog,
                                onReviewWork: _openVerificationDialog,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 5. My Crew Workload (Section 11)
                            Container(
                              key: _crewKey,
                              child: DepartmentLeadCrewWorkloadSection(
                                crewWorkloads: _dashboardData!.crewWorkload,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 6. Work Awaiting Verification (Section 17)
                            Container(
                              key: _verificationKey,
                              child: DepartmentLeadAwaitingVerificationSection(
                                awaitingVerificationComplaints: _dashboardData!
                                    .awaitingVerificationComplaints,
                                onReviewWork: _openVerificationDialog,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 7. Department SLA Monitor (Section 16)
                            Container(
                              key: _slaKey,
                              child: DepartmentLeadSlaMonitorSection(
                                slaData: _dashboardData!.slaMonitoringData,
                                onViewComplaint: _openComplaintDetails,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 8. Routing Requests Center (Section 15)
                            Container(
                              key: _routingKey,
                              child: DepartmentLeadRoutingRequestsSection(
                                routingTickets:
                                    _dashboardData!.routingTickets,
                                onViewComplaint: (cmpId) {
                                  final match = _dashboardData!
                                      .allUnitComplaints
                                      .cast<ComplaintModel?>()
                                      .firstWhere(
                                        (c) =>
                                            c?.id == cmpId ||
                                            c?.ticketNumber == cmpId,
                                        orElse: () => null,
                                      );
                                  if (match != null) {
                                    _openComplaintDetails(match);
                                  }
                                },
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 9. Completed Work (Section 21)
                            Container(
                              key: _completedKey,
                              child: DepartmentLeadCompletedWorkSection(
                                completedComplaints:
                                    _dashboardData!.completedComplaints,
                                onViewDetails: _openComplaintDetails,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 10. Critical Complaints (Section 22)
                            Container(
                              key: _criticalKey,
                              child: DepartmentLeadCriticalComplaintsSection(
                                criticalComplaints:
                                    _dashboardData!.criticalComplaints,
                                onAssignCrew: _openAssignDialog,
                                onViewDetails: _openComplaintDetails,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 11. Department GIS Map (Section 23)
                            Container(
                              key: _mapKey,
                              child: DepartmentLeadMapSection(
                                wardId: wardCode,
                                departmentName: deptName,
                                hazards: _dashboardData!.departmentHazards,
                                complaints: _dashboardData!.allUnitComplaints,
                                onViewComplaint: _openComplaintDetails,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXl,

                            // 12. Recent Activity Log (Section 24)
                            Container(
                              key: _activityKey,
                              child: DepartmentLeadRecentActivitySection(
                                auditLogs: _dashboardData!.recentAuditLogs,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXxl,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildQuickJumpBar(BuildContext context) {
    final navItems = [
      _NavAnchor('Overview', _kpiKey, Icons.dashboard_outlined),
      _NavAnchor('Funnel', _funnelKey, Icons.alt_route_rounded),
      _NavAnchor('AI Fallback', _manualVerificationKey, Icons.shield_outlined),
      _NavAnchor('Unassigned', _unassignedKey, Icons.assignment_late_outlined),
      _NavAnchor('Queue', _complaintsKey, Icons.table_chart_outlined),
      _NavAnchor('My Crew', _crewKey, Icons.people_outline_rounded),
      _NavAnchor(
          'Verification', _verificationKey, Icons.fact_check_outlined),
      _NavAnchor('SLA Monitor', _slaKey, Icons.timer_outlined),
      _NavAnchor('Routing', _routingKey, Icons.swap_horiz_rounded),
      _NavAnchor('Completed', _completedKey, Icons.verified_outlined),
      _NavAnchor('Map', _mapKey, Icons.map_outlined),
      _NavAnchor('Activity', _activityKey, Icons.receipt_long_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CivicFixSpacing.xl,
        vertical: CivicFixSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        border: Border(
          bottom: BorderSide(color: GovtThemeTokens.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: navItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
              child: ActionChip(
                avatar: Icon(item.icon, size: 14, color: GovtThemeTokens.primary),
                label: Text(
                  item.label,
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: GovtThemeTokens.surfaceMuted,
                side: BorderSide(color: GovtThemeTokens.borderLight),
                onPressed: () => _scrollToSection(item.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavAnchor {
  final String label;
  final GlobalKey key;
  final IconData icon;

  const _NavAnchor(this.label, this.key, this.icon);
}
