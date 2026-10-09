import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_ward_dashboard_service.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_filter_bar.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../auth/government_access_denied_screen.dart';
import '../../widgets/dashboard/sections/ward/ward_attention_section.dart';
import '../../widgets/dashboard/sections/ward/ward_complaint_queue_section.dart';
import '../../widgets/dashboard/sections/ward/ward_crew_distribution_section.dart';
import '../../widgets/dashboard/sections/ward/ward_critical_complaints_section.dart';
import '../../widgets/dashboard/sections/ward/ward_department_performance_section.dart';
import '../../widgets/dashboard/sections/ward/ward_escalation_center_section.dart';
import '../../widgets/dashboard/sections/ward/ward_kpi_section.dart';
import '../../widgets/dashboard/sections/ward/ward_lead_directory_section.dart';
import '../../widgets/dashboard/sections/ward/ward_operations_map_section.dart';
import '../../widgets/dashboard/sections/ward/ward_operations_overview_section.dart';
import '../../widgets/dashboard/sections/ward/ward_personnel_overview_section.dart';
import '../../widgets/dashboard/sections/ward/ward_recent_activity_section.dart';
import '../../widgets/dashboard/sections/ward/ward_routing_requests_section.dart';
import '../../widgets/dashboard/sections/ward/ward_sla_monitoring_section.dart';
import '../../widgets/dashboard/sections/ward/ward_trend_section.dart';

/// Phase 6 — Assistant Commissioner / Ward Officer Command Center Screen.
///
/// Provides complete administrative oversight across all 18 municipal departments
/// within the single authoritative Ward:
/// - Single Ward isolation strictly enforced (session.wardId)
/// - 18 Municipal Departments performance tracking
/// - Wrong-Department Routing Request Center (Approve / Reject workflows)
/// - Ward-wide complaint queue & critical emergencies register
/// - SLA monitoring and overdue enforcement
/// - Technical and administrative escalations center
/// - Personnel overview (1 Ward Officer, 18 Leads, 90 Crew = 109 staff)
/// - 18 Ward Department Leads directory
/// - 90 Field crew members distribution and workload status
/// - Ward GIS spatial hazard and grievance telemetry
/// - 7/30/90 days grievance volume progression trends
/// - Ward-scoped immutable audit trail
class WardCommandCenterScreen extends StatefulWidget {
  final GovtUserModel? user;
  final GovernmentWardDashboardService? dashboardService;

  const WardCommandCenterScreen({
    super.key,
    this.user,
    this.dashboardService,
  });

  @override
  State<WardCommandCenterScreen> createState() => _WardCommandCenterScreenState();
}

class _WardCommandCenterScreenState extends State<WardCommandCenterScreen> {
  late final GovernmentWardDashboardService _dashboardService;
  final ScrollController _scrollController = ScrollController();

  // Section Keys for Quick Navigation
  final GlobalKey _kpiKey = GlobalKey();
  final GlobalKey _departmentsKey = GlobalKey();
  final GlobalKey _routingKey = GlobalKey();
  final GlobalKey _complaintsKey = GlobalKey();
  final GlobalKey _criticalKey = GlobalKey();
  final GlobalKey _slaKey = GlobalKey();
  final GlobalKey _escalationsKey = GlobalKey();
  final GlobalKey _personnelKey = GlobalKey();
  final GlobalKey _leadsKey = GlobalKey();
  final GlobalKey _crewKey = GlobalKey();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _trendKey = GlobalKey();
  final GlobalKey _auditKey = GlobalKey();

  WardDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  // Global Ward Multi-Criteria Filters
  String? _selectedDepartment;
  ComplaintPriority? _selectedPriority;
  ComplaintStatus? _selectedStatus;
  String _searchQuery = '';
  bool _slaBreachedOnly = false;

  final Set<String> _dismissedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? GovernmentWardDashboardService();
    _loadDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _resolveWardId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.wardId != null && activeUser!.wardId!.isNotEmpty) {
      return activeUser.wardId!;
    }
    return 'N'; // Default canonical ward if unspecified
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final wardId = _resolveWardId();

    try {
      final data = await _dashboardService.loadWardDashboard(
        wardId: wardId,
        departmentFilter: _selectedDepartment,
        priorityFilter: _selectedPriority,
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
        slaBreachedOnly: _slaBreachedOnly,
      );

      if (mounted) {
        setState(() {
          _dashboardData = data;
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

  void _onDepartmentFilterChanged(String? dept) {
    setState(() {
      _selectedDepartment = (dept == 'all' || dept == null) ? null : dept;
    });
    _loadDashboard();
  }

  void _onPriorityFilterChanged(ComplaintPriority? p) {
    setState(() {
      _selectedPriority = p;
    });
    _loadDashboard();
  }

  void _onStatusFilterChanged(ComplaintStatus? s) {
    setState(() {
      _selectedStatus = s;
    });
    _loadDashboard();
  }

  void _onResetFilters() {
    setState(() {
      _selectedDepartment = null;
      _selectedPriority = null;
      _selectedStatus = null;
      _searchQuery = '';
      _slaBreachedOnly = false;
    });
    _loadDashboard();
  }

  void _navigateToComplaintDetails(String complaintId) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtComplaintDetails,
      arguments: complaintId,
    );
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

  @override
  Widget build(BuildContext context) {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;

    // Strict Role-Based Authorization Gate (Strictly ward_officer role only)
    if (activeUser == null || !activeUser.isWardOfficer) {
      return GovernmentAccessDeniedScreen(user: activeUser);
    }

    final wardCode = _dashboardData?.ward.wardCode ?? _resolveWardId();
    final wardName = _dashboardData?.ward.wardName ?? '$wardCode Ward';

    const breadcrumbs = [
      GovtBreadcrumbItem(label: 'Home', route: AppRoutes.governmentWard),
      GovtBreadcrumbItem(label: 'Ward Command Center'),
    ];

    final allDepartments = _dashboardData?.allDepartments ?? [];

    final activeAlerts = _dashboardData?.alerts
            .where((a) => !_dismissedAlertIds.contains(a.id))
            .toList() ??
        [];

    final activeFilterCount =
        (_selectedDepartment != null && _selectedDepartment != 'all' ? 1 : 0) +
            (_selectedPriority != null ? 1 : 0) +
            (_selectedStatus != null ? 1 : 0) +
            (_searchQuery.isNotEmpty ? 1 : 0) +
            (_slaBreachedOnly ? 1 : 0);

    return GovernmentAppShell(
      title: '$wardCode Ward Command Center',
      subtitle: 'Assistant Commissioner · $wardName',
      breadcrumbs: breadcrumbs,
      selectedIndex: 0,
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
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: GovtThemeTokens.primary,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header with Refresh Action
              GovernmentPageHeader(
                title: '$wardName Command Center',
                subtitle:
                    'Administrative oversight of CivicFix operations across all municipal departments in this ward.',
                breadcrumbs: breadcrumbs,
                primaryAction: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadDashboard,
                  icon: _isLoading
                      ? const Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.white)
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_isLoading ? 'Refreshing...' : 'Refresh Feed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: GovtThemeTokens.buttonRadius),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: GovtResponsive.isMobile(context)
                      ? CivicFixSpacing.md
                      : CivicFixSpacing.xl,
                  vertical: CivicFixSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section Quick Jump Buttons
                    _buildSectionNavigation(),

                    CivicFixSpacing.vSpaceLg,

                    // Global Multi-Criteria Ward Filter Bar
                    GovernmentFilterBar(
                      searchHint: 'Search complaints, tickets, departments in $wardName...',
                      searchQuery: _searchQuery,
                      onSearchChanged: (q) {
                        setState(() => _searchQuery = q);
                        _loadDashboard();
                      },
                      dropdownFilters: [
                        // 1. Department Filter (18 Departments)
                        GovtDropdownFilterConfig<String>(
                          label: 'Department',
                          selectedValue: _selectedDepartment,
                          icon: Icons.domain_rounded,
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Departments (${allDepartments.length})'),
                            ),
                            ...allDepartments.map(
                              (d) => DropdownMenuItem(
                                value: d.departmentId,
                                child: Text(d.displayName),
                              ),
                            ),
                          ],
                          onChanged: _onDepartmentFilterChanged,
                        ),

                        // 2. Priority Filter
                        GovtDropdownFilterConfig<ComplaintPriority>(
                          label: 'Priority',
                          selectedValue: _selectedPriority,
                          icon: Icons.flag_rounded,
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Priorities'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintPriority.emergency,
                              child: Text('Emergency'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintPriority.high,
                              child: Text('High Priority'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintPriority.medium,
                              child: Text('Medium Priority'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintPriority.low,
                              child: Text('Low Priority'),
                            ),
                          ],
                          onChanged: _onPriorityFilterChanged,
                        ),

                        // 3. Status Filter
                        GovtDropdownFilterConfig<ComplaintStatus>(
                          label: 'Status',
                          selectedValue: _selectedStatus,
                          icon: Icons.track_changes_rounded,
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Statuses'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintStatus.reported,
                              child: Text('Reported'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintStatus.verified,
                              child: Text('Verified'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintStatus.assigned,
                              child: Text('Assigned'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintStatus.inProgress,
                              child: Text('In Progress'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintStatus.resolved,
                              child: Text('Resolved'),
                            ),
                            DropdownMenuItem(
                              value: ComplaintStatus.rejected,
                              child: Text('Rejected'),
                            ),
                          ],
                          onChanged: _onStatusFilterChanged,
                        ),
                      ],
                      customChips: [
                        FilterChip(
                          label: const Text('SLA Breached Only'),
                          selected: _slaBreachedOnly,
                          onSelected: (val) {
                            setState(() => _slaBreachedOnly = val);
                            _loadDashboard();
                          },
                        ),
                      ],
                      activeFilterCount: activeFilterCount,
                      onClearAll: _onResetFilters,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Error Banner if any
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(CivicFixSpacing.md),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GovtThemeTokens.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: GovtThemeTokens.error),
                            CivicFixSpacing.hSpaceMd,
                            Expanded(
                              child: Text(
                                'Error loading ward dashboard: $_errorMessage',
                                style: CivicFixTypography.bodyMedium.copyWith(color: GovtThemeTokens.error),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadDashboard,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      CivicFixSpacing.vSpaceLg,
                    ],

                    // Section 1: Attention Alerts
                    WardAttentionSection(
                      alerts: activeAlerts,
                      onDismissAlert: (id) {
                        setState(() => _dismissedAlertIds.add(id));
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 2: Ward KPI Grid
                    Container(
                      key: _kpiKey,
                      child: WardKpiSection(
                        metrics: _dashboardData?.kpiMetrics ??
                            const WardKpiMetrics(
                              totalComplaints: 0,
                              openComplaints: 0,
                              criticalComplaints: 0,
                              resolvedToday: 0,
                              resolvedTotal: 0,
                              slaBreachedCount: 0,
                              pendingRoutingRequests: 0,
                              activeEscalationsCount: 0,
                              activePersonnelCount: 109,
                            ),
                        isLoading: _isLoading,
                        onOpenComplaintsTap: () => _scrollToSection(_complaintsKey),
                        onCriticalComplaintsTap: () => _scrollToSection(_criticalKey),
                        onSlaBreachedTap: () => _scrollToSection(_slaKey),
                        onRoutingRequestsTap: () => _scrollToSection(_routingKey),
                        onEscalationsTap: () => _scrollToSection(_escalationsKey),
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 3: Operations Funnel Overview
                    WardOperationsOverviewSection(
                      overview: _dashboardData?.operationsOverview ??
                          const WardOperationsOverviewData(
                            totalActiveComplaints: 0,
                            submittedCount: 0,
                            acknowledgedCount: 0,
                            assignedCount: 0,
                            inProgressCount: 0,
                            awaitingVerificationCount: 0,
                            resolvedCount: 0,
                            criticalUnresolvedCount: 0,
                            slaBreachesCount: 0,
                            createdTodayCount: 0,
                            resolvedTodayCount: 0,
                          ),
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 4: Department Performance (18 Departments)
                    Container(
                      key: _departmentsKey,
                      child: WardDepartmentPerformanceSection(
                        departmentPerformances: _dashboardData?.departmentPerformances ?? [],
                        wardId: wardCode,
                        isLoading: _isLoading,
                        dashboardService: _dashboardService,
                        onViewComplaint: _navigateToComplaintDetails,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 5: Routing Request Center
                    Container(
                      key: _routingKey,
                      child: WardRoutingRequestsSection(
                        routingTickets: _dashboardData?.routingTickets ?? [],
                        wardId: wardCode,
                        isLoading: _isLoading,
                        routingService: _dashboardService.getRoutingService(),
                        allDepartments: allDepartments,
                        onRefreshNeeded: _loadDashboard,
                        onViewComplaint: _navigateToComplaintDetails,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 6: Ward Complaint Queue
                    Container(
                      key: _complaintsKey,
                      child: WardComplaintQueueSection(
                        complaints: _dashboardData?.filteredComplaints ?? [],
                        wardId: wardCode,
                        isLoading: _isLoading,
                        onComplaintTapped: _navigateToComplaintDetails,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 7: Critical & Emergency Complaints
                    Container(
                      key: _criticalKey,
                      child: WardCriticalComplaintsSection(
                        criticalComplaints: _dashboardData?.criticalComplaints ?? [],
                        isLoading: _isLoading,
                        onComplaintTapped: (c) => _navigateToComplaintDetails(c.id),
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 8: SLA Monitoring & Breach Oversight
                    Container(
                      key: _slaKey,
                      child: WardSlaMonitoringSection(
                        slaData: _dashboardData?.slaMonitoringData ??
                            const WardSlaMonitoringData(
                              totalBreached: 0,
                              atRiskCount: 0,
                              breachedItems: [],
                              breachCountByDepartment: {},
                            ),
                        isLoading: _isLoading,
                        onInspectBreach: (item) => _navigateToComplaintDetails(item.complaintId),
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 9: Ward Escalations Center
                    Container(
                      key: _escalationsKey,
                      child: WardEscalationCenterSection(
                        escalations: _dashboardData?.escalations ?? [],
                        isLoading: _isLoading,
                        onDirectIntervention: (item) => _navigateToComplaintDetails(item.id),
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 10: Ward Personnel Overview (109 staff)
                    Container(
                      key: _personnelKey,
                      child: WardPersonnelOverviewSection(
                        personnelSummary: _dashboardData?.personnelSummary ??
                            const WardPersonnelSummary(
                              totalPersonnelCount: 109,
                              leadCount: 18,
                              crewCount: 90,
                              activePersonnelCount: 109,
                              departmentCoverageCount: 18,
                            ),
                        isLoading: _isLoading,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 11: Department Leads Directory (18 Leads)
                    Container(
                      key: _leadsKey,
                      child: WardLeadDirectorySection(
                        departmentLeads: _dashboardData?.departmentLeads ?? [],
                        isLoading: _isLoading,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 12: Field Crew Distribution (90 Technicians)
                    Container(
                      key: _crewKey,
                      child: WardCrewDistributionSection(
                        crewDistribution: _dashboardData?.crewDistribution ?? [],
                        isLoading: _isLoading,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 13: Ward Spatial GIS Map Overview
                    Container(
                      key: _mapKey,
                      child: WardOperationsMapSection(
                        wardId: wardCode,
                        hazards: _dashboardData?.wardHazards ?? [],
                        isLoading: _isLoading,
                        onViewComplaint: _navigateToComplaintDetails,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 14: Ward Grievance Volume Trends
                    Container(
                      key: _trendKey,
                      child: WardTrendSection(
                        timeTrends: _dashboardData?.timeTrends ?? [],
                        isLoading: _isLoading,
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 15: Ward Administrative Audit Trail
                    Container(
                      key: _auditKey,
                      child: WardRecentActivitySection(
                        logs: _dashboardData?.recentAuditLogs ?? [],
                        isLoading: _isLoading,
                        onRetry: _loadDashboard,
                        onViewComplaint: _navigateToComplaintDetails,
                      ),
                    ),

                    CivicFixSpacing.vSpaceXxl,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionNavigation() {
    final items = [
      _NavChipData('Dashboard', Icons.dashboard_outlined, () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut)),
      _NavChipData('Departments', Icons.domain_rounded, () => _scrollToSection(_departmentsKey)),
      _NavChipData('Routing Requests', Icons.alt_route_rounded, () => _scrollToSection(_routingKey)),
      _NavChipData('Complaints', Icons.list_alt_rounded, () => _scrollToSection(_complaintsKey)),
      _NavChipData('Critical', Icons.emergency_rounded, () => _scrollToSection(_criticalKey)),
      _NavChipData('SLA Monitoring', Icons.timer_off_rounded, () => _scrollToSection(_slaKey)),
      _NavChipData('Escalations', Icons.warning_rounded, () => _scrollToSection(_escalationsKey)),
      _NavChipData('Personnel', Icons.people_outline_rounded, () => _scrollToSection(_personnelKey)),
      _NavChipData('GIS Map', Icons.map_outlined, () => _scrollToSection(_mapKey)),
      _NavChipData('Audit Activity', Icons.history_edu_outlined, () => _scrollToSection(_auditKey)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(item.icon, size: 14, color: GovtThemeTokens.primary),
              label: Text(item.label, style: CivicFixTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              backgroundColor: GovtThemeTokens.surface,
              side: BorderSide(color: GovtThemeTokens.border),
              onPressed: item.onTap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavChipData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavChipData(this.label, this.icon, this.onTap);
}
