import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_zone_dashboard_service.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_filter_bar.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../../widgets/common/govt_jurisdiction_badge.dart';
import '../../widgets/common/govt_role_badge.dart';
import '../auth/government_access_denied_screen.dart';
import '../../widgets/dashboard/sections/zone/zone_attention_section.dart';
import '../../widgets/dashboard/sections/zone/zone_critical_complaints_section.dart';
import '../../widgets/dashboard/sections/zone/zone_cross_ward_issues_section.dart';
import '../../widgets/dashboard/sections/zone/zone_department_performance_section.dart';
import '../../widgets/dashboard/sections/zone/zone_department_ward_matrix_section.dart';
import '../../widgets/dashboard/sections/zone/zone_escalation_center_section.dart';
import '../../widgets/dashboard/sections/zone/zone_kpi_section.dart';
import '../../widgets/dashboard/sections/zone/zone_operations_map_section.dart';
import '../../widgets/dashboard/sections/zone/zone_operations_overview_section.dart';
import '../../widgets/dashboard/sections/zone/zone_personnel_overview_section.dart';
import '../../widgets/dashboard/sections/zone/zone_recent_activity_section.dart';
import '../../widgets/dashboard/sections/zone/zone_routing_requests_section.dart';
import '../../widgets/dashboard/sections/zone/zone_sla_monitoring_section.dart';
import '../../widgets/dashboard/sections/zone/zone_ward_officer_directory_section.dart';
import '../../widgets/dashboard/sections/zone/zone_ward_performance_section.dart';

/// Phase 4 — Zonal Deputy Municipal Commissioner (DMC) Command Center Screen.
///
/// Provides executive supervisory oversight strictly across the DMC's assigned Zone:
/// - Zonal Wards isolation
/// - 18 Technical Departments performance across zone
/// - Department x Ward operational cross-tabulation matrix
/// - Deterministic ward health scoring & supervisory drill-down dialog
/// - Zonal SLA breaches & escalation center
/// - Inter-department routing requests supervisory monitoring
/// - Cross-ward issues & hotspot coordination
/// - Zonal Ward Officer directory & personnel distribution
/// - Zone GIS telemetry & spatial hazard markers
/// - Zonal audit trail
class ZoneCommandCenterScreen extends StatefulWidget {
  final GovtUserModel? user;
  final GovernmentZoneDashboardService? dashboardService;

  const ZoneCommandCenterScreen({
    super.key,
    this.user,
    this.dashboardService,
  });

  @override
  State<ZoneCommandCenterScreen> createState() => _ZoneCommandCenterScreenState();
}

class _ZoneCommandCenterScreenState extends State<ZoneCommandCenterScreen> {
  late final GovernmentZoneDashboardService _dashboardService;
  final ScrollController _scrollController = ScrollController();

  ZonalDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  // Global Multi-Criteria Zone Filters
  String? _selectedWard;
  String? _selectedDepartment;
  ComplaintPriority? _selectedPriority;
  ComplaintStatus? _selectedStatus;
  String _searchQuery = '';
  bool _slaBreachedOnly = false;

  final Set<String> _dismissedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? GovernmentZoneDashboardService();
    _loadDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _resolveZoneId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.zoneId != null && activeUser!.zoneId!.isNotEmpty) {
      return activeUser.zoneId!;
    }
    return 'ZONE_4'; // Default to Zone 4 if unspecified
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final zoneId = _resolveZoneId();

    try {
      final data = await _dashboardService.loadZoneDashboard(
        zoneId: zoneId,
        wardFilter: _selectedWard,
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

  void _onWardFilterChanged(String? ward) {
    setState(() {
      _selectedWard = ward;
    });
    _loadDashboard();
  }

  void _onDepartmentFilterChanged(String? dept) {
    setState(() {
      _selectedDepartment = dept;
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
      _selectedWard = null;
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

  void _navigateToComplaintsList({ComplaintPriority? priority}) {
    Navigator.pushNamed(
      context,
      AppRoutes.govtComplaints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;

    // Strict Role-Based Authorization Gate (Only zonal_dmc allowed)
    if (activeUser == null || !activeUser.isZonalDmc) {
      return GovernmentAccessDeniedScreen(user: activeUser);
    }

    final zoneId = _resolveZoneId();
    final zoneDisplayName = _dashboardData?.zone.displayName ?? zoneId;

    const breadcrumbs = [
      GovtBreadcrumbItem(label: 'Home', route: AppRoutes.governmentZone),
      GovtBreadcrumbItem(label: 'Zone Command Center'),
    ];

    final availableWards = _dashboardData?.zoneWards ?? [];
    final activeAlerts = _dashboardData?.alerts
            .where((a) => !_dismissedAlertIds.contains(a.id))
            .toList() ??
        [];

    final activeFilterCount = (_selectedWard != null && _selectedWard != 'all' ? 1 : 0) +
        (_selectedDepartment != null && _selectedDepartment != 'all' ? 1 : 0) +
        (_selectedPriority != null ? 1 : 0) +
        (_selectedStatus != null ? 1 : 0) +
        (_searchQuery.isNotEmpty ? 1 : 0) +
        (_slaBreachedOnly ? 1 : 0);

    return GovernmentAppShell(
      title: 'Zone Command Center',
      subtitle: 'Deputy Municipal Commissioner · $zoneDisplayName',
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
              // Page Header with Badges and Refresh Action
              GovernmentPageHeader(
                title: '$zoneDisplayName Command Center',
                subtitle: 'Supervisory administrative control and department coordination across ${availableWards.length} municipal wards.',
                breadcrumbs: breadcrumbs,
                jurisdictionBadge: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    GovtJurisdictionBadge.role('ZONAL JURISDICTION', isCompact: true),
                    GovtJurisdictionBadge.zone(zoneDisplayName.toUpperCase(), isCompact: true),
                    GovtJurisdictionBadge.ward('${availableWards.length} WARDS', isCompact: true),
                    GovtJurisdictionBadge.department('18 DEPARTMENTS', isCompact: true),
                  ],
                ),
                statusWidget: GovtRoleBadge(role: activeUser.govtRole),
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
                  horizontal: GovtResponsive.isMobile(context) ? CivicFixSpacing.md : CivicFixSpacing.xl,
                  vertical: CivicFixSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Global Zone-Restricted Filter Bar
                    GovernmentFilterBar(
                      searchHint: 'Search grievances, tickets, wards, departments in $zoneDisplayName...',
                      searchQuery: _searchQuery,
                      onSearchChanged: (q) {
                        setState(() => _searchQuery = q);
                        _loadDashboard();
                      },
                      dropdownFilters: [
                        // 1. Zone Ward Filter (strictly zone wards)
                        GovtDropdownFilterConfig<String>(
                          label: 'Ward',
                          selectedValue: _selectedWard,
                          icon: Icons.location_city_rounded,
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Zone Wards (${availableWards.length})'),
                            ),
                            ...availableWards.map(
                              (w) => DropdownMenuItem(
                                value: w.wardId,
                                child: Text('Ward ${w.wardCode} (${w.wardName})'),
                              ),
                            ),
                          ],
                          onChanged: _onWardFilterChanged,
                        ),

                        // 2. Department Filter (18 Departments)
                        GovtDropdownFilterConfig<String>(
                          label: 'Department',
                          selectedValue: _selectedDepartment,
                          icon: Icons.apartment_rounded,
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Departments (18)')),
                            ...(_dashboardData?.departmentMetrics.map((d) => DropdownMenuItem(
                                      value: d.departmentId,
                                      child: Text('${d.departmentName} (${d.departmentCode})'),
                                    )) ??
                                const []),
                          ],
                          onChanged: _onDepartmentFilterChanged,
                        ),

                        // 3. Priority Filter
                        GovtDropdownFilterConfig<ComplaintPriority>(
                          label: 'Priority',
                          selectedValue: _selectedPriority,
                          icon: Icons.flag_outlined,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All Priorities')),
                            DropdownMenuItem(value: ComplaintPriority.emergency, child: Text('Critical / Emergency')),
                            DropdownMenuItem(value: ComplaintPriority.high, child: Text('High Priority')),
                            DropdownMenuItem(value: ComplaintPriority.medium, child: Text('Medium Priority')),
                            DropdownMenuItem(value: ComplaintPriority.low, child: Text('Low Priority')),
                          ],
                          onChanged: _onPriorityFilterChanged,
                        ),

                        // 4. Status Filter
                        GovtDropdownFilterConfig<ComplaintStatus>(
                          label: 'Status',
                          selectedValue: _selectedStatus,
                          icon: Icons.rule_rounded,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All Statuses')),
                            DropdownMenuItem(value: ComplaintStatus.reported, child: Text('Reported')),
                            DropdownMenuItem(value: ComplaintStatus.verified, child: Text('Verified')),
                            DropdownMenuItem(value: ComplaintStatus.assigned, child: Text('Assigned')),
                            DropdownMenuItem(value: ComplaintStatus.inProgress, child: Text('In Progress')),
                            DropdownMenuItem(value: ComplaintStatus.resolved, child: Text('Resolved')),
                            DropdownMenuItem(value: ComplaintStatus.rejected, child: Text('Rejected')),
                          ],
                          onChanged: _onStatusFilterChanged,
                        ),
                      ],
                      activeFilterCount: activeFilterCount,
                      onClearAll: _onResetFilters,
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Section 1: Zonal Attention Center (Urgent Alerts)
                    if (activeAlerts.isNotEmpty) ...[
                      ZoneAttentionSection(
                        alerts: activeAlerts,
                        onDismissAlert: (id) {
                          setState(() => _dismissedAlertIds.add(id));
                        },
                        onAlertAction: (alert) {
                          if (alert.id == 'alert_zone_critical') {
                            _navigateToComplaintsList(priority: ComplaintPriority.emergency);
                          }
                        },
                      ),
                      CivicFixSpacing.vSpaceLg,
                    ],

                    // Section 2: Top Zonal KPI Metric Strip (8-10 metrics)
                    ZoneKpiSection(
                      metrics: _dashboardData?.kpiMetrics,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: _loadDashboard,
                      onOpenComplaintsTap: () => _navigateToComplaintsList(),
                      onCriticalComplaintsTap: () =>
                          _navigateToComplaintsList(priority: ComplaintPriority.emergency),
                      onSlaBreachedTap: () {
                        _scrollController.animateTo(
                          1800,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      onRoutingRequestsTap: () {
                        _scrollController.animateTo(
                          2200,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      onEscalationsTap: () {
                        _scrollController.animateTo(
                          2500,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 3: Zonal Operations Overview (Pipeline Funnel)
                    ZoneOperationsOverviewSection(
                      data: _dashboardData?.operationsOverview,
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 4: Ward Performance & Health Audit (Zone Wards)
                    ZoneWardPerformanceSection(
                      zoneId: zoneId,
                      wardHealthCards: _dashboardData?.wardHealthCards ?? const [],
                      isLoading: _isLoading,
                      dashboardService: _dashboardService,
                      onFilterByWard: (wardId) {
                        setState(() => _selectedWard = wardId);
                        _loadDashboard();
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 5: Technical Departments Performance in Zone (18 Departments)
                    ZoneDepartmentPerformanceSection(
                      departmentMetrics: _dashboardData?.departmentMetrics ?? const [],
                      isLoading: _isLoading,
                      onFilterByDepartment: (deptId) {
                        setState(() => _selectedDepartment = deptId);
                        _loadDashboard();
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 6: Department x Ward Operational Matrix (Cross-Tabulation Grid)
                    ZoneDepartmentWardMatrixSection(
                      matrixData: _dashboardData?.departmentWardMatrix,
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 7: Critical Grievances & Hazards in Zone
                    ZoneCriticalComplaintsSection(
                      criticalComplaints: _dashboardData?.criticalComplaints ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                      onViewAllCritical: () =>
                          _navigateToComplaintsList(priority: ComplaintPriority.emergency),
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 8: Zonal SLA Monitoring Center (48h Breaches)
                    ZoneSlaMonitoringSection(
                      slaBreachedComplaints: _dashboardData?.slaBreachedComplaints ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 9: Zonal Routing & Reassignment Requests
                    ZoneRoutingRequestsSection(
                      tickets: _dashboardData?.pendingRoutingTickets ?? const [],
                      isLoading: _isLoading,
                      onTicketReviewed: _loadDashboard,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 10: Zonal Escalation Center
                    ZoneEscalationCenterSection(
                      escalations: _dashboardData?.escalations ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 11: Cross-Ward Issues & Hotspot Coordination
                    ZoneCrossWardIssuesSection(
                      issues: _dashboardData?.crossWardIssues ?? const [],
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 12: Zonal Personnel Distribution
                    ZonePersonnelOverviewSection(
                      zonePersonnel: _dashboardData?.zonePersonnel ?? const [],
                      wardCount: availableWards.length,
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 13: Ward Officers Directory (Assistant Commissioners)
                    ZoneWardOfficerDirectorySection(
                      zoneId: zoneId,
                      wardOfficers: _dashboardData?.wardOfficers ?? const [],
                      isLoading: _isLoading,
                      dashboardService: _dashboardService,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 14: Zonal Spatial Hazards & GIS Overview
                    ZoneOperationsMapSection(
                      zoneDisplayName: zoneDisplayName,
                      hazards: _dashboardData?.zoneHazards ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 15: Zonal Administrative Audit Trail
                    ZoneRecentActivitySection(
                      logs: _dashboardData?.recentAuditLogs ?? const [],
                      isLoading: _isLoading,
                      onRetry: _loadDashboard,
                      onViewComplaint: _navigateToComplaintDetails,
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
