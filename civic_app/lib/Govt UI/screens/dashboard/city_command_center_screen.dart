import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_city_dashboard_service.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_filter_bar.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../../widgets/common/govt_jurisdiction_badge.dart';
import '../../widgets/common/govt_role_badge.dart';
import '../auth/government_access_denied_screen.dart';
import '../../widgets/dashboard/sections/city_attention_section.dart';
import '../../widgets/dashboard/sections/city_complaint_map_section.dart';
import '../../widgets/dashboard/sections/city_complaint_trend_section.dart';
import '../../widgets/dashboard/sections/city_kpi_section.dart';
import '../../widgets/dashboard/sections/city_operations_overview_section.dart';
import '../../widgets/dashboard/sections/critical_complaints_section.dart';
import '../../widgets/dashboard/sections/department_performance_section.dart';
import '../../widgets/dashboard/sections/escalation_overview_section.dart';
import '../../widgets/dashboard/sections/personnel_overview_section.dart';
import '../../widgets/dashboard/sections/recent_administrative_activity_section.dart';
import '../../widgets/dashboard/sections/routing_requests_section.dart';
import '../../widgets/dashboard/sections/sla_breaches_section.dart';
import '../../widgets/dashboard/sections/zone_performance_section.dart';
import '../../widgets/dashboard/sections/ward_performance_section.dart';

/// Phase 3 — Municipal Commissioner & Government Super Admin City Command Center.
///
/// Provides executive, real-time, citywide oversight across all:
/// - 7 Administrative Zones
/// - 24 Municipal Wards
/// - 18 Technical Departments
/// - 432 Ward-Department Operational Units
/// - 2,642 Verified Government Identities
class CityCommandCenterScreen extends StatefulWidget {
  final GovtUserModel? user;
  final GovernmentCityDashboardService? dashboardService;

  const CityCommandCenterScreen({
    super.key,
    this.user,
    this.dashboardService,
  });

  @override
  State<CityCommandCenterScreen> createState() => _CityCommandCenterScreenState();
}

class _CityCommandCenterScreenState extends State<CityCommandCenterScreen> {
  late final GovernmentCityDashboardService _dashboardService;
  final ScrollController _scrollController = ScrollController();

  CitywideDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  // Global Multi-Criteria Filters
  String? _selectedZone;
  String? _selectedWard;
  String? _selectedDepartment;
  ComplaintPriority? _selectedPriority;
  ComplaintStatus? _selectedStatus;
  String _searchQuery = '';
  int _trendDays = 7;

  // Partial Error Tracking
  final String? _auditErrorMessage = null;
  final Set<String> _dismissedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? GovernmentCityDashboardService();
    _loadDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dashboardService.loadCitywideDashboard(
        zoneFilter: _selectedZone,
        wardFilter: _selectedWard,
        departmentFilter: _selectedDepartment,
        priorityFilter: _selectedPriority,
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
        trendDays: _trendDays,
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
      _selectedZone = zone;
      // Dependent Filter: Reset ward filter if selected ward is not in newly selected zone
      _selectedWard = null;
    });
    _loadDashboard();
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
      _selectedZone = null;
      _selectedWard = null;
      _selectedDepartment = null;
      _selectedPriority = null;
      _selectedStatus = null;
      _searchQuery = '';
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

    // Strict Matrix Authorization Gate
    if (activeUser == null || !activeUser.isSuperAdmin) {
      return GovernmentAccessDeniedScreen(user: activeUser);
    }

    const breadcrumbs = [
      GovtBreadcrumbItem(label: 'Home', route: AppRoutes.governmentDashboard),
      GovtBreadcrumbItem(label: 'City Command Center'),
    ];

    // Filter available wards dynamically based on selected zone (Dependent Filtering)
    final allWards = _dashboardData?.wardMetrics.map((w) => w.ward).toList() ?? [];
    final availableWards = (_selectedZone != null && _selectedZone != 'all')
        ? allWards.where((w) => w.zoneId.toLowerCase() == _selectedZone!.toLowerCase()).toList()
        : allWards;

    // Filter active alerts excluding dismissed ones
    final activeAlerts = _dashboardData?.alerts
            .where((a) => !_dismissedAlertIds.contains(a.id))
            .toList() ??
        [];

    final activeFilterCount = (_selectedZone != null && _selectedZone != 'all' ? 1 : 0) +
        (_selectedWard != null && _selectedWard != 'all' ? 1 : 0) +
        (_selectedDepartment != null && _selectedDepartment != 'all' ? 1 : 0) +
        (_selectedPriority != null ? 1 : 0) +
        (_selectedStatus != null ? 1 : 0) +
        (_searchQuery.isNotEmpty ? 1 : 0);

    return GovernmentAppShell(
      title: 'City Command Center',
      subtitle: 'Municipal Commissioner & Apex Super Admin · Mumbai',
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
        } else if (index == 5) {
          Navigator.pushNamed(context, AppRoutes.governmentOperations);
        } else if (index == 6) {
          Navigator.pushNamed(context, AppRoutes.governmentEscalations);
        } else if (index == 7) {
          Navigator.pushNamed(context, AppRoutes.governmentStaff);
        } else if (index == 8) {
          Navigator.pushNamed(context, AppRoutes.governmentAudit);
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
                title: 'City Command Center',
                subtitle: 'Citywide operational overview across all CivicFix wards and municipal departments.',
                breadcrumbs: breadcrumbs,
                jurisdictionBadge: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    GovtJurisdictionBadge.role('CITYWIDE', isCompact: true),
                    GovtJurisdictionBadge.ward('24 WARDS', isCompact: true),
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
                    // Global Dependent Filter Bar
                    GovernmentFilterBar(
                      searchHint: 'Search grievances, tickets, wards, departments...',
                      searchQuery: _searchQuery,
                      onSearchChanged: (q) {
                        setState(() => _searchQuery = q);
                        _loadDashboard();
                      },
                      dropdownFilters: [
                        // 1. Zone Filter
                        GovtDropdownFilterConfig<String>(
                          label: 'Zone',
                          selectedValue: _selectedZone,
                          icon: Icons.domain_rounded,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Zones (7)')),
                            DropdownMenuItem(value: 'ZONE_1', child: Text('Zone 1 (City South)')),
                            DropdownMenuItem(value: 'ZONE_2', child: Text('Zone 2 (City Central)')),
                            DropdownMenuItem(value: 'ZONE_3', child: Text('Zone 3 (Western South)')),
                            DropdownMenuItem(value: 'ZONE_4', child: Text('Zone 4 (Western North)')),
                            DropdownMenuItem(value: 'ZONE_5', child: Text('Zone 5 (Eastern South)')),
                            DropdownMenuItem(value: 'ZONE_6', child: Text('Zone 6 (Eastern North)')),
                            DropdownMenuItem(value: 'ZONE_7', child: Text('Zone 7 (Northern)')),
                          ],
                          onChanged: _onZoneFilterChanged,
                        ),

                        // 2. Dependent Ward Filter
                        GovtDropdownFilterConfig<String>(
                          label: 'Ward',
                          selectedValue: _selectedWard,
                          icon: Icons.location_city_rounded,
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(
                                _selectedZone != null && _selectedZone != 'all'
                                    ? 'All Zone Wards (${availableWards.length})'
                                    : 'All Wards (24)',
                              ),
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

                        // 3. Department Filter (18 Departments)
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

                        // 4. Priority Filter
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

                        // 5. Status Filter
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

                    // Section 1: City Attention Center (Urgent Alerts)
                    if (activeAlerts.isNotEmpty) ...[
                      CityAttentionSection(
                        alerts: activeAlerts,
                        onDismissAlert: (id) {
                          setState(() => _dismissedAlertIds.add(id));
                        },
                        onAlertAction: (alert) {
                          if (alert.id == 'alert_critical') {
                            _navigateToComplaintsList(priority: ComplaintPriority.emergency);
                          } else if (alert.id == 'alert_routing') {
                            // Scroll to routing section
                            _scrollController.animateTo(
                              1800,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                      CivicFixSpacing.vSpaceLg,
                    ],

                    // Section 2: Top Citywide KPI Grid (8 metrics)
                    CityKpiSection(
                      metrics: _dashboardData?.kpiMetrics,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: _loadDashboard,
                      onOpenComplaintsTap: () => _navigateToComplaintsList(),
                      onCriticalComplaintsTap: () =>
                          _navigateToComplaintsList(priority: ComplaintPriority.emergency),
                      onSlaBreachedTap: () {
                        _scrollController.animateTo(
                          1400,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      onRoutingRequestsTap: () {
                        _scrollController.animateTo(
                          1800,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      onPersonnelTap: () {
                        _scrollController.animateTo(
                          2200,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 3: City Operations Overview
                    CityOperationsOverviewSection(
                      data: _dashboardData?.operationsOverview,
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 4: Zone Performance (All 7 Zones)
                    ZonePerformanceSection(
                      zoneMetrics: _dashboardData?.zoneMetrics ?? const [],
                      isLoading: _isLoading,
                      onViewZone: (zoneId) {
                        setState(() {
                          _selectedZone = zoneId;
                        });
                        _loadDashboard();
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 5: Ward Performance (All 24 Wards)
                    WardPerformanceSection(
                      wardMetrics: _dashboardData?.wardMetrics ?? const [],
                      isLoading: _isLoading,
                      onViewWard: (wardId) {
                        setState(() {
                          _selectedWard = wardId;
                        });
                        _loadDashboard();
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 6: Department Performance (All 18 Departments)
                    DepartmentPerformanceSection(
                      departmentMetrics: _dashboardData?.departmentMetrics ?? const [],
                      isLoading: _isLoading,
                      onViewDepartment: (deptId) {
                        setState(() {
                          _selectedDepartment = deptId;
                        });
                        _loadDashboard();
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 7: Citywide Complaint Trend
                    CityComplaintTrendSection(
                      timeTrends: _dashboardData?.timeTrends ?? const [],
                      isLoading: _isLoading,
                      onRangeDaysChanged: (days) {
                        setState(() => _trendDays = days);
                        _loadDashboard();
                      },
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 8: Critical Complaints Panel
                    CriticalComplaintsSection(
                      criticalComplaints: _dashboardData?.criticalComplaints ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                      onViewAllCritical: () =>
                          _navigateToComplaintsList(priority: ComplaintPriority.emergency),
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 9: SLA Breaches Center
                    SlaBreachesSection(
                      slaBreachedComplaints: _dashboardData?.slaBreachedComplaints ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 10: Pending Routing Requests (Wrong Department Transfers)
                    RoutingRequestsSection(
                      tickets: _dashboardData?.pendingRoutingTickets ?? const [],
                      isLoading: _isLoading,
                      onTicketReviewed: _loadDashboard,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 11: Escalations Overview
                    EscalationOverviewSection(
                      escalatedComplaints: _dashboardData?.slaBreachedComplaints ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 12: Personnel Overview & Hierarchy Roster (2,642)
                    PersonnelOverviewSection(
                      summary: _dashboardData?.personnelSummary ??
                          const PersonnelSummary(
                            superAdminCount: 1,
                            zonalDmcCount: 7,
                            centralHodCount: 18,
                            wardOfficerCount: 24,
                            wardLeadCount: 432,
                            crewCount: 2160,
                            totalPersonnelCount: 2642,
                            personnelByZone: {},
                            personnelByDepartment: {},
                            personnelByRole: {},
                            activeAccountsCount: 2642,
                            integrityMatch: true,
                          ),
                      isLoading: _isLoading,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 13: Citywide Complaint Map
                    CityComplaintMapSection(
                      hazards: _dashboardData?.citywideHazards ?? const [],
                      isLoading: _isLoading,
                      onViewComplaint: _navigateToComplaintDetails,
                    ),

                    CivicFixSpacing.vSpaceXl,

                    // Section 14: Recent Administrative Activity (Audit Logs)
                    RecentAdministrativeActivitySection(
                      logs: _dashboardData?.recentAuditLogs ?? const [],
                      isLoading: _isLoading,
                      errorMessage: _auditErrorMessage,
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
