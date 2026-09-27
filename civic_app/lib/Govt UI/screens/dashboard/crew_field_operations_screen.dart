import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_crew_work_service.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../auth/government_access_denied_screen.dart';
import '../../widgets/dashboard/sections/crew/crew_activity_section.dart';
import '../../widgets/dashboard/sections/crew/crew_awaiting_review_section.dart';
import '../../widgets/dashboard/sections/crew/crew_completed_section.dart';
import '../../widgets/dashboard/sections/crew/crew_evidence_submission_dialog.dart';
import '../../widgets/dashboard/sections/crew/crew_field_header.dart';
import '../../widgets/dashboard/sections/crew/crew_job_detail_dialog.dart';
import '../../widgets/dashboard/sections/crew/crew_job_queue_section.dart';
import '../../widgets/dashboard/sections/crew/crew_kpi_summary_section.dart';
import '../../widgets/dashboard/sections/crew/crew_map_section.dart';
import '../../widgets/dashboard/sections/crew/crew_report_issue_dialog.dart';

/// Phase 8 — Department Crew / Field Operations UI Screen.
///
/// Frontline mobile-first operational workspace for field technicians / junior engineers:
/// - Strictly scoped to 1 Ward × 1 Department × 1 Crew Member
/// - Minimal, fast, field-friendly, action-oriented
/// - Direct workflow execution: Start Job, Capture Evidence (Before/After), Submit for Verification
/// - Handles Rework orders from Ward Department Lead with resume actions
/// - Logs on-site issue / blockage reports without unauthorized routing
/// - GIS Spatial Telemetry strictly for this technician's assigned tasks
/// - Scoped immutable activity audit trail
class CrewFieldOperationsScreen extends StatefulWidget {
  final GovtUserModel? user;
  final GovernmentCrewWorkService? workService;

  const CrewFieldOperationsScreen({
    super.key,
    this.user,
    this.workService,
  });

  @override
  State<CrewFieldOperationsScreen> createState() =>
      _CrewFieldOperationsScreenState();
}

class _CrewFieldOperationsScreenState extends State<CrewFieldOperationsScreen> {
  late final GovernmentCrewWorkService _workService;
  final ScrollController _scrollController = ScrollController();

  CrewWorkdeskData? _workdeskData;
  bool _isLoading = true;
  String? _errorMessage;

  // Active Navigation Tab
  // 0: My Jobs, 1: In Progress, 2: Awaiting Review, 3: Completed, 4: Map, 5: Activity
  int _activeNavIndex = 0;

  // Filters inside work queue
  String _activeQueueTab = 'all'; // 'all', 'in_progress', 'critical', 'sla_risk'
  ComplaintPriority? _selectedPriority;
  ComplaintStatus? _selectedStatus;
  String? _selectedSla;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _workService = widget.workService ?? GovernmentCrewWorkService();
    _loadWorkdesk();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _resolveCrewId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.employeeId != null && activeUser!.employeeId.isNotEmpty) {
      return activeUser.employeeId;
    }
    if (activeUser?.id != null && activeUser!.id.isNotEmpty) {
      return activeUser.id;
    }
    return 'GOV-CREW-N-MAINTENANCE-01';
  }

  String _resolveWardId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.wardId != null && activeUser!.wardId!.isNotEmpty) {
      return activeUser.wardId!;
    }
    return 'N';
  }

  String _resolveDepartmentId() {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (activeUser?.departmentId != null &&
        activeUser!.departmentId!.isNotEmpty) {
      return activeUser.departmentId!;
    }
    return 'maintenance_roads';
  }

  Future<void> _loadWorkdesk() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final crewId = _resolveCrewId();
    final wardId = _resolveWardId();
    final deptId = _resolveDepartmentId();

    try {
      final data = await _workService.loadCrewWorkdesk(
        crewId: crewId,
        wardId: wardId,
        departmentId: deptId,
        priorityFilter: _selectedPriority,
        statusFilter: _selectedStatus,
        slaFilter: _selectedSla,
        searchQuery: _searchQuery,
        activeTab: _activeQueueTab,
      );

      if (mounted) {
        setState(() {
          _workdeskData = data;
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

  // Workflow Dialogs
  void _openJobDetails(CrewJobItem job) {
    showDialog(
      context: context,
      builder: (ctx) => CrewJobDetailDialog(
        job: job,
        onStartJob: () => _handleStartJob(job),
        onSubmitCompletion: () => _openEvidenceSubmissionDialog(job),
        onReportIssue: () => _openReportIssueDialog(job),
        onResumeRework: () => _handleResumeRework(job),
      ),
    );
  }

  Future<void> _handleStartJob(CrewJobItem job) async {
    try {
      final crewId = _resolveCrewId();
      await _workService.startJob(
        complaintId: job.id,
        crewId: crewId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Job #${job.ticketNumber} started. Status moved to In Progress.'),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
        _loadWorkdesk();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting job: $e'),
            backgroundColor: GovtThemeTokens.alert,
          ),
        );
      }
    }
  }

  void _openEvidenceSubmissionDialog(CrewJobItem job) {
    showDialog(
      context: context,
      builder: (ctx) => CrewEvidenceSubmissionDialog(
        complaint: job.complaint,
        crewId: _resolveCrewId(),
        onSubmitCompletion: ({
          required beforePhotoUrl,
          required afterPhotoUrl,
          duringPhotoUrl,
          required workRemarks,
        }) async {
          await _workService.submitWorkCompletion(
            complaintId: job.id,
            crewId: _resolveCrewId(),
            beforePhotoUrl: beforePhotoUrl,
            afterPhotoUrl: afterPhotoUrl,
            duringPhotoUrl: duringPhotoUrl,
            workRemarks: workRemarks,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Work completion for #${job.ticketNumber} submitted to Department Lead.'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            _loadWorkdesk();
          }
        },
      ),
    );
  }

  void _openReportIssueDialog(CrewJobItem job) {
    showDialog(
      context: context,
      builder: (ctx) => CrewReportIssueDialog(
        complaint: job.complaint,
        crewId: _resolveCrewId(),
        onReportIssue: ({
          required reasonCategory,
          required details,
        }) async {
          await _workService.reportBlockedIssue(
            complaintId: job.id,
            crewId: _resolveCrewId(),
            reasonCategory: reasonCategory,
            details: details,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Field report logged for #${job.ticketNumber}: [$reasonCategory].'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
            _loadWorkdesk();
          }
        },
      ),
    );
  }

  Future<void> _handleResumeRework(CrewJobItem job) async {
    try {
      final crewId = _resolveCrewId();
      await _workService.resumeWorkAfterRework(
        complaintId: job.id,
        crewId: crewId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rework resumed for #${job.ticketNumber}. Work in progress.'),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
        _loadWorkdesk();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming rework: $e'),
            backgroundColor: GovtThemeTokens.alert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;

    // Strict Role Access Control Gate (department_crew and super_admin only)
    if (activeUser == null || (!activeUser.isCrew && !activeUser.isSuperAdmin)) {
      return GovernmentAccessDeniedScreen(user: activeUser);
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    final deptName =
        _workdeskData?.department.displayName ?? 'Field Operations';
    final wardCode = _workdeskData?.ward.wardCode ?? _resolveWardId();

    const breadcrumbs = [
      GovtBreadcrumbItem(label: 'Home', route: AppRoutes.governmentWork),
      GovtBreadcrumbItem(label: 'My Work'),
    ];

    final mainContent = _isLoading
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
                        'Failed to load field workdesk',
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
                        onPressed: _loadWorkdesk,
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadWorkdesk,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with Badges
                      CrewFieldHeader(
                        crewUser: _workdeskData!.crewUser,
                        wardCode: wardCode,
                        departmentName: deptName,
                        onRefresh: _loadWorkdesk,
                      ),

                      // Desktop / Tablet Tab Switcher Bar
                      if (!isMobile) _buildDesktopNavTabs(),

                      Padding(
                        padding: const EdgeInsets.all(CivicFixSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Top KPI Summary Grid
                            CrewKpiSummarySection(
                              metrics: _workdeskData!.kpiMetrics,
                              onKpiTapped: (tabKey) {
                                if (tabKey == 'in_progress') {
                                  setState(() {
                                    _activeNavIndex = 0;
                                    _activeQueueTab = 'in_progress';
                                  });
                                } else if (tabKey == 'critical') {
                                  setState(() {
                                    _activeNavIndex = 0;
                                    _activeQueueTab = 'critical';
                                  });
                                } else if (tabKey == 'sla_risk') {
                                  setState(() {
                                    _activeNavIndex = 0;
                                    _activeQueueTab = 'sla_risk';
                                  });
                                } else if (tabKey == 'awaiting_review') {
                                  setState(() => _activeNavIndex = 2);
                                } else if (tabKey == 'completed') {
                                  setState(() => _activeNavIndex = 3);
                                } else {
                                  setState(() {
                                    _activeNavIndex = 0;
                                    _activeQueueTab = 'all';
                                  });
                                }
                                _loadWorkdesk();
                              },
                            ),
                            CivicFixSpacing.vSpaceLg,

                            // 2. Active Tab Content
                            _buildActiveTabContent(),
                            CivicFixSpacing.vSpaceXxl,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

    // Mobile viewport presentation with compact bottom navigation bar
    if (isMobile) {
      return Scaffold(
        backgroundColor: GovtThemeTokens.surfaceMuted,
        body: SafeArea(child: mainContent),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _activeNavIndex,
          onTap: (index) {
            setState(() => _activeNavIndex = index);
            if (index == 0) {
              _activeQueueTab = 'all';
              _loadWorkdesk();
            } else if (index == 1) {
              _activeQueueTab = 'in_progress';
              _loadWorkdesk();
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: GovtThemeTokens.primary,
          unselectedItemColor: GovtThemeTokens.textMuted,
          selectedLabelStyle: CivicFixTypography.captionMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          unselectedLabelStyle: CivicFixTypography.caption.copyWith(
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'My Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.engineering_outlined),
              activeIcon: Icon(Icons.engineering_rounded),
              label: 'In Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              activeIcon: Icon(Icons.fact_check_rounded),
              label: 'Review',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined),
              activeIcon: Icon(Icons.task_alt_rounded),
              label: 'Completed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Activity',
            ),
          ],
        ),
      );
    }

    // Tablet & Desktop presentation wrapped inside GovernmentAppShell
    return GovernmentAppShell(
      title: 'My Work — $deptName',
      subtitle: 'Assigned field operations for $deptName ($wardCode Ward)',
      breadcrumbs: breadcrumbs,
      selectedIndex: 5,
      body: mainContent,
    );
  }

  Widget _buildDesktopNavTabs() {
    final tabs = [
      {'label': 'My Jobs', 'icon': Icons.assignment_outlined, 'index': 0},
      {'label': 'In Progress', 'icon': Icons.engineering_outlined, 'index': 1},
      {'label': 'Awaiting Review', 'icon': Icons.fact_check_outlined, 'index': 2},
      {'label': 'Completed Work', 'icon': Icons.task_alt_outlined, 'index': 3},
      {'label': 'Field Map', 'icon': Icons.map_outlined, 'index': 4},
      {'label': 'My Activity', 'icon': Icons.receipt_long_outlined, 'index': 5},
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
          children: tabs.map((tab) {
            final idx = tab['index'] as int;
            final isSelected = _activeNavIndex == idx;
            final label = tab['label'] as String;
            final icon = tab['icon'] as IconData;

            return Padding(
              padding: const EdgeInsets.only(right: CivicFixSpacing.sm),
              child: ChoiceChip(
                avatar: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : GovtThemeTokens.primary,
                ),
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _activeNavIndex = idx);
                  if (idx == 0) {
                    _activeQueueTab = 'all';
                    _loadWorkdesk();
                  } else if (idx == 1) {
                    _activeQueueTab = 'in_progress';
                    _loadWorkdesk();
                  }
                },
                selectedColor: GovtThemeTokens.primary,
                labelStyle: CivicFixTypography.captionMedium.copyWith(
                  color: isSelected ? Colors.white : GovtThemeTokens.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                backgroundColor: GovtThemeTokens.surfaceMuted,
                side: BorderSide(
                  color: isSelected
                      ? GovtThemeTokens.primary
                      : GovtThemeTokens.borderLight,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeNavIndex) {
      case 0:
      case 1:
        return CrewJobQueueSection(
          jobs: _activeNavIndex == 1
              ? _workdeskData!.inProgressJobs
              : _workdeskData!.filteredJobs,
          activeTab: _activeQueueTab,
          selectedPriority: _selectedPriority,
          selectedStatus: _selectedStatus,
          selectedSla: _selectedSla,
          searchQuery: _searchQuery,
          onTabChanged: (tab) {
            setState(() => _activeQueueTab = tab);
            _loadWorkdesk();
          },
          onPriorityChanged: (p) {
            setState(() => _selectedPriority = p);
            _loadWorkdesk();
          },
          onStatusChanged: (s) {
            setState(() => _selectedStatus = s);
            _loadWorkdesk();
          },
          onSlaChanged: (sla) {
            setState(() => _selectedSla = sla);
            _loadWorkdesk();
          },
          onSearchChanged: (q) {
            setState(() => _searchQuery = q);
            _loadWorkdesk();
          },
          onResetFilters: () {
            setState(() {
              _selectedPriority = null;
              _selectedStatus = null;
              _selectedSla = null;
              _searchQuery = '';
              _activeQueueTab = 'all';
            });
            _loadWorkdesk();
          },
          onViewDetails: _openJobDetails,
          onStartJob: _handleStartJob,
        );

      case 2:
        return CrewAwaitingReviewSection(
          awaitingJobs: _workdeskData!.awaitingReviewJobs,
          onViewDetails: _openJobDetails,
        );

      case 3:
        return CrewCompletedSection(
          completedJobs: _workdeskData!.completedJobs,
          onViewDetails: _openJobDetails,
        );

      case 4:
        return CrewMapSection(
          jobs: _workdeskData!.allMyJobs,
          onViewDetails: _openJobDetails,
        );

      case 5:
        return CrewActivitySection(
          auditLogs: _workdeskData!.myActivityLogs,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
