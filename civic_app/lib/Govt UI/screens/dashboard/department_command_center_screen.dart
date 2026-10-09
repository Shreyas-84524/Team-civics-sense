import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/civic_ward_model.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_department_dashboard_service.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_filter_bar.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../auth/government_access_denied_screen.dart';
import '../../widgets/dashboard/sections/department/department_attention_section.dart';
import '../../widgets/dashboard/sections/department/department_crew_distribution_section.dart';
import '../../widgets/dashboard/sections/department/department_critical_complaints_section.dart';
import '../../widgets/dashboard/sections/department/department_escalation_center_section.dart';
import '../../widgets/dashboard/sections/department/department_kpi_section.dart';
import '../../widgets/dashboard/sections/department/department_lead_directory_section.dart';
import '../../widgets/dashboard/sections/department/department_operations_map_section.dart';
import '../../widgets/dashboard/sections/department/department_operations_overview_section.dart';
import '../../widgets/dashboard/sections/department/department_personnel_overview_section.dart';
import '../../widgets/dashboard/sections/department/department_recent_activity_section.dart';
import '../../widgets/dashboard/sections/department/department_routing_requests_section.dart';
import '../../widgets/dashboard/sections/department/department_sla_monitoring_section.dart';
import '../../widgets/dashboard/sections/department/department_trend_section.dart';
import '../../widgets/dashboard/sections/department/department_ward_performance_section.dart';
import '../../widgets/dashboard/sections/department/department_ward_unit_drilldown_dialog.dart';
import '../../widgets/dashboard/sections/department/department_zone_breakdown_section.dart';

/// Phase 5 — Central Department HOD (Chief Engineer) Command Center Screen.
///
/// Provides executive technical oversight strictly across the HOD's assigned Department:
/// - Single Department isolation across ALL 24 wards & 7 zones
/// - 24 Ward Operational Units performance tracking
/// - 7 Zonal aggregation breakdown
/// - Deterministic ward unit drill-down dialog
/// - Departmental SLA monitoring & breach repository
/// - Inter-department routing requests (source/destination)
/// - Technical Escalation Center for direct intervention
/// - Personnel overview (1 HOD, 24 Leads, 120 Crew = 145 staff)
/// - 24 Ward Leads directory with contact details
/// - 120 Technicians field crew distribution across 24 wards
/// - Department spatial GIS hazard distribution
/// - 7/30/90 days grievance volume trends
/// - Department-scoped immutable audit trail
class DepartmentCommandCenterScreen extends StatefulWidget {
  final GovtUserModel? user;
  final GovernmentDepartmentDashboardService? dashboardService;

  const DepartmentCommandCenterScreen({
    super.key,
    this.user,
    this.dashboardService,
  });

  @override
  State<DepartmentCommandCenterScreen> createState() =>
      _DepartmentCommandCenterScreenState();
}

class _DepartmentCommandCenterScreenState
    extends State<DepartmentCommandCenterScreen> {
  late final GovernmentDepartmentDashboardService _dashboardService;
  final ScrollController _scrollController = ScrollController();

  DepartmentDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  // Global Multi-Criteria Department Filters
  String? _selectedZone;
  String? _selectedWard;
  ComplaintPriority? _selectedPriority;
  ComplaintStatus? _selectedStatus;
  String _searchQuery = '';
  bool _slaBreachedOnly = false;

  final Set<String> _dismissedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _dashboardService =
        widget.dashboardService ?? GovernmentDepartmentDashboardService();
    _loadDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _resolveDepartmentId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.departmentId != null &&
        activeUser!.departmentId!.isNotEmpty) {
      return activeUser.departmentId!;
    }
    return 'dept_swm'; // Default to Solid Waste Management if unspecified
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final deptId = _resolveDepartmentId();

    try {
      final data = await _dashboardService.loadDepartmentDashboard(
        departmentId: deptId,
        zoneFilter: _selectedZone,
        wardFilter: _selectedWard,
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

  void _onZoneFilterChanged(String? zone) {
    setState(() {
      _selectedZone = (zone == 'all' || zone == null) ? null : zone;
      // If ward is not in selected zone, reset ward
      if (_selectedZone != null && _selectedWard != null) {
        final allWards = _dashboardData?.allWards ?? [];
        final wardInZone = allWards.any((w) =>
            w.wardCode == _selectedWard &&
            w.zoneId.toUpperCase() == _selectedZone!.toUpperCase());
        if (!wardInZone) {
          _selectedWard = null;
        }
      }
    });
    _loadDashboard();
  }

  void _onWardFilterChanged(String? ward) {
    setState(() {
      _selectedWard = (ward == 'all' || ward == null) ? null : ward;
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
      _selectedZone = null;
      _selectedWard = null;
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

  void _openWardUnitDrilldown(String wardCode) {
    final deptId = _resolveDepartmentId();
    final allWards = _dashboardData?.allWards ?? [];
    final ward = allWards.firstWhere(
      (w) =>
          w.wardCode.toLowerCase() == wardCode.toLowerCase() ||
          w.wardId.toLowerCase() == wardCode.toLowerCase(),
      orElse: () => CivicWard(
        wardId: wardCode,
        wardCode: wardCode,
        wardName: 'Ward $wardCode',
        zoneId: 'ZONE_1',
        lat: 19.0760,
        lng: 72.8777,
        pincode: '400001',
      ),
    );

    DepartmentWardUnitDrilldownDialog.show(
      context,
      ward: ward,
      departmentId: deptId,
      dashboardService: _dashboardService,
      onViewComplaint: _navigateToComplaintDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;

    // Strict Role-Based Authorization Gate (Only central_department_hod allowed)
    if (activeUser == null || !activeUser.isCentralHod) {
      return GovernmentAccessDeniedScreen(user: activeUser);
    }

    final deptId = _resolveDepartmentId();
    final deptName = _dashboardData?.department.displayName ?? 'Solid Waste Management';

    const breadcrumbs = [
      GovtBreadcrumbItem(label: 'Home', route: AppRoutes.governmentDepartment),
      GovtBreadcrumbItem(label: 'Department Command Center'),
    ];

    final allZones = _dashboardData?.allZones ?? [];
    final allWards = _dashboardData?.allWards ?? [];

    // Filter available wards based on selected zone
    final availableWards = _selectedZone != null
        ? allWards
            .where((w) =>
                w.zoneId.toUpperCase() == _selectedZone!.toUpperCase())
            .toList()
        : allWards;

    final activeAlerts = _dashboardData?.alerts
            .where((a) => !_dismissedAlertIds.contains(a.id))
            .toList() ??
        [];

    final activeFilterCount =
        (_selectedZone != null && _selectedZone != 'all' ? 1 : 0) +
            (_selectedWard != null && _selectedWard != 'all' ? 1 : 0) +
            (_selectedPriority != null ? 1 : 0) +
            (_selectedStatus != null ? 1 : 0) +
            (_searchQuery.isNotEmpty ? 1 : 0) +
            (_slaBreachedOnly ? 1 : 0);

    return GovernmentAppShell(
      title: 'Department Command Center',
      subtitle: 'Chief Engineer · $deptName',
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
                title: '$deptName Command Center',
                subtitle:
                    'Citywide technical supervision, operational unit management, and service delivery across all 24 municipal wards.',
                breadcrumbs: breadcrumbs,
                primaryAction: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadDashboard,
                  icon: _isLoading
                      ? const Icon(Icons.hourglass_top_rounded,
                          size: 16, color: Colors.white)
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_isLoading ? 'Refreshing...' : 'Refresh Feed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: GovtThemeTokens.buttonRadius),
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
                    // Global Department Multi-Criteria Filter Bar
                    GovernmentFilterBar(
                      searchHint:
                          'Search complaints, tickets, wards in $deptName...',
                      searchQuery: _searchQuery,
                      onSearchChanged: (q) {
                        setState(() => _searchQuery = q);
                        _loadDashboard();
                      },
                      dropdownFilters: [
                        // 1. Zone Filter (7 Zones)
                        GovtDropdownFilterConfig<String>(
                          label: 'Zone',
                          selectedValue: _selectedZone,
                          icon: Icons.public_rounded,
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All Zones (7)'),
                            ),
                            ...allZones.map(
                              (z) => DropdownMenuItem(
                                value: z.zoneId,
                                child: Text(z.displayName),
                              ),
                            ),
                          ],
                          onChanged: _onZoneFilterChanged,
                        ),

                        // 2. Ward Filter (24 Wards, cascaded)
                        GovtDropdownFilterConfig<String>(
                          label: 'Ward',
                          selectedValue: _selectedWard,
                          icon: Icons.location_city_rounded,
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(
                                  'All Wards (${availableWards.length})'),
                            ),
                            ...availableWards.map(
                              (w) => DropdownMenuItem(
                                value: w.wardCode,
                                child: Text('Ward ${w.wardCode} (${w.wardName})'),
                              ),
                            ),
                          ],
                          onChanged: _onWardFilterChanged,
                        ),

                        // 3. Priority Filter
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

                        // 4. Status Filter
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

                    // Error Message Banner if any
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
                            const Icon(Icons.error_outline,
                                color: GovtThemeTokens.error),
                            CivicFixSpacing.hSpaceMd,
                            Expanded(
                              child: Text(
                                'Error loading department dashboard: $_errorMessage',
                                style: CivicFixTypography.bodyMedium.copyWith(
                                    color: GovtThemeTokens.error),
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

                    // Section 1: Department Attention Alerts
                    DepartmentAttentionSection(
                      alerts: activeAlerts,
                      onDismissAlert: (id) {
                        setState(() => _dismissedAlertIds.add(id));
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 2: Department KPI Summary Cards
                    DepartmentKpiSection(
                      metrics: _dashboardData?.kpiMetrics ??
                          const DepartmentKpiMetrics(
                            totalComplaints: 0,
                            openComplaints: 0,
                            criticalComplaints: 0,
                            resolvedToday: 0,
                            resolvedTotal: 0,
                            slaBreachedCount: 0,
                            pendingRoutingRequests: 0,
                            activeWardUnitsCount: 24,
                            activePersonnelCount: 145,
                          ),
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 3: Operations Funnel Overview
                    DepartmentOperationsOverviewSection(
                      overview: _dashboardData?.operationsOverview ??
                          const DepartmentOperationsOverviewData(
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

                    // Section 4: Ward Operational Units Performance (24 Wards)
                    DepartmentWardPerformanceSection(
                      wardUnits: _dashboardData?.wardUnitPerformances ?? [],
                      departmentId: deptId,
                      isLoading: _isLoading,
                      dashboardService: _dashboardService,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 5: Zonal Breakdown (7 Zones)
                    DepartmentZoneBreakdownSection(
                      zoneBreakdowns: _dashboardData?.zoneBreakdowns ?? [],
                      isLoading: _isLoading,
                      onFilterByZone: (zoneId) {
                        _onZoneFilterChanged(zoneId);
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 6: Critical & Emergency Grievances
                    DepartmentCriticalComplaintsSection(
                      criticalComplaints:
                          _dashboardData?.criticalComplaints ?? [],
                      isLoading: _isLoading,
                      onComplaintTapped: (c) {
                        _navigateToComplaintDetails(c.id);
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 7: SLA Monitoring & Breach Oversight
                    DepartmentSlaMonitoringSection(
                      slaData: _dashboardData?.slaMonitoringData ??
                          const DepartmentSlaMonitoringData(
                            totalBreached: 0,
                            atRiskCount: 0,
                            breachedItems: [],
                            breachCountByWard: {},
                            breachCountByZone: {},
                          ),
                      isLoading: _isLoading,
                      onInspectBreach: (item) {
                        _navigateToComplaintDetails(item.complaintId);
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 8: Inter-Departmental Routing & Reassignment
                    DepartmentRoutingRequestsSection(
                      routingTickets: _dashboardData?.routingTickets ?? [],
                      departmentId: deptId,
                      isLoading: _isLoading,
                      onApproveTicket: (ticket) async {
                        try {
                          await _dashboardService
                              .getRoutingService()
                              .reviewRoutingTicket(
                                ticketId: ticket.id,
                                reviewerId: activeUser.id,
                                approve: true,
                              );
                          _loadDashboard();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error approving: $e')),
                            );
                          }
                        }
                      },
                      onRejectTicket: (ticket) async {
                        try {
                          await _dashboardService
                              .getRoutingService()
                              .reviewRoutingTicket(
                                ticketId: ticket.id,
                                reviewerId: activeUser.id,
                                approve: false,
                                reviewNotes: 'Rejected by Central HOD',
                              );
                          _loadDashboard();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error rejecting: $e')),
                            );
                          }
                        }
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 9: Department Technical Escalation Center
                    DepartmentEscalationCenterSection(
                      escalations:
                          _dashboardData?.technicalEscalations ?? [],
                      isLoading: _isLoading,
                      onDirectIntervention: (item) {
                        _navigateToComplaintDetails(item.id);
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 10: Department Personnel Hierarchy Overview
                    DepartmentPersonnelOverviewSection(
                      personnelSummary: _dashboardData?.personnelSummary ??
                          const DepartmentPersonnelSummary(
                            totalPersonnelCount: 145,
                            leadCount: 24,
                            crewCount: 120,
                            activePersonnelCount: 145,
                          ),
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 11: Ward Department Leads Directory (24 Leads)
                    DepartmentLeadDirectorySection(
                      departmentLeads:
                          _dashboardData?.departmentLeads ?? [],
                      isLoading: _isLoading,
                      onInspectUnit: (unit) {
                        _openWardUnitDrilldown(unit.wardCode);
                      },
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 12: Field Crew Distribution (120 Technicians)
                    DepartmentCrewDistributionSection(
                      crewDistribution:
                          _dashboardData?.crewDistribution ?? [],
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 13: Department Spatial GIS Hazard Distribution
                    DepartmentOperationsMapSection(
                      departmentName: deptName,
                      hazards: _dashboardData?.departmentHazards ?? [],
                      isLoading: _isLoading,
                      onViewComplaint: (id) => _navigateToComplaintDetails(id),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 14: Department Grievance Volume Trends
                    DepartmentTrendSection(
                      timeTrends: _dashboardData?.timeTrends ?? [],
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 15: Department Administrative Audit Trail
                    DepartmentRecentActivitySection(
                      logs: _dashboardData?.recentAuditLogs ?? [],
                      isLoading: _isLoading,
                      onRetry: _loadDashboard,
                      onViewComplaint: (id) => _navigateToComplaintDetails(id),
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
}
