import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service_locator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/complaint_model.dart';
import '../../../../core/routing/app_routes.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_crew_work_service.dart';
import '../../../core/services/complaint_routing_service.dart';
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
import '../../widgets/dashboard/sections/crew/crew_field_officer_assignment_dialog.dart';

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

  const CrewFieldOperationsScreen({super.key, this.user, this.workService});

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
  String _activeQueueTab =
      'all'; // 'all', 'in_progress', 'critical', 'sla_risk'
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
      final data = await _workService
          .loadCrewWorkdesk(
            crewId: crewId,
            wardId: wardId,
            departmentId: deptId,
            priorityFilter: _selectedPriority,
            statusFilter: _selectedStatus,
            slaFilter: _selectedSla,
            searchQuery: _searchQuery,
            activeTab: _activeQueueTab,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw StateError(
              'The workdesk took too long to respond. Check your connection and retry.',
            ),
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
        onAssignExecutionOfficer: () => _openExecutionOfficerAssignment(job),
      ),
    );
  }

  Future<void> _openExecutionOfficerAssignment(CrewJobItem job) async {
    final user = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    if (user == null) return;
    final routing = ComplaintRoutingService();
    routing.registerComplaint(job.complaint);
    if (kDebugMode) {
      debugPrint(
        '[CrewFieldOps] Opening execution officer assignment dialog. '
        'complaint.id: ${job.complaint.id}, job.id: ${job.id}, '
        'ticketNumber: ${job.complaint.ticketNumber}, localId: ${job.complaint.localId}',
      );
    }
    final officers = await routing.getEligibleFieldOfficers(
      wardId: job.complaint.wardId ?? job.complaint.location.ward ?? _resolveWardId(),
      departmentId: job.complaint.assignedDepartmentId ?? user.departmentId ?? job.complaint.category.id,
      juniorEngineerId: _resolveCrewId(),
    );
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (ctx) => CrewFieldOfficerAssignmentDialog(
        complaint: job.complaint,
        officers: officers,
        onAssign: (officerId, notes) async {
          final targetComplaintId = job.complaint.id.isNotEmpty ? job.complaint.id : job.id;
          await routing.assignFieldOfficer(
            complaintId: targetComplaintId,
            juniorEngineerId: _resolveCrewId(),
            fieldOfficerId: officerId,
            assignmentNotes: notes,
          );
        },
      ),
    );
    if (mounted) _loadWorkdesk();
  }

  Future<void> _handleStartJob(CrewJobItem job) async {
    try {
      final crewId = _resolveCrewId();
      if (kDebugMode) {
        debugPrint(
          '[CrewFieldOps] Starting job: complaintId=${job.id}, ticketNumber=${job.ticketNumber}, crewId=$crewId',
        );
      }
      await _workService.startJob(complaintId: job.id, crewId: crewId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Job #${job.ticketNumber} started. Status moved to In Progress.',
            ),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
        _loadWorkdesk();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrewFieldOps] Error starting job: $e');
      }
      if (mounted) {
        final errStr = e.toString();
        final userMsg = (errStr.contains('Security Violation') ||
                errStr.contains('not assigned') ||
                errStr.contains('not authorized'))
            ? 'You are not assigned to this job.'
            : errStr
                .replaceFirst('Exception: ', '')
                .replaceFirst('StateError: ', '')
                .replaceFirst('ArgumentError: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMsg),
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
        onSubmitCompletion:
            ({
              required beforePhotoUrl,
              required afterPhotoUrl,
              duringPhotoUrl,
              required workRemarks,
            }) async {
              try {
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
                        'Work completion for #${job.ticketNumber} submitted to Department Lead.',
                      ),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  _loadWorkdesk();
                }
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('[CrewFieldOps] Error submitting completion: $e');
                }
                if (mounted) {
                  final errStr = e.toString();
                  final userMsg = (errStr.contains('Security Violation') ||
                          errStr.contains('not assigned') ||
                          errStr.contains('not authorized'))
                      ? 'You are not assigned to this job.'
                      : errStr
                          .replaceFirst('Exception: ', '')
                          .replaceFirst('StateError: ', '')
                          .replaceFirst('ArgumentError: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userMsg),
                      backgroundColor: GovtThemeTokens.alert,
                    ),
                  );
                }
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
        onReportIssue: ({required reasonCategory, required details}) async {
          try {
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
                    'Field report logged for #${job.ticketNumber}: [$reasonCategory].',
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
              _loadWorkdesk();
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[CrewFieldOps] Error reporting issue: $e');
            }
            if (mounted) {
              final errStr = e.toString();
              final userMsg = (errStr.contains('Security Violation') ||
                      errStr.contains('not assigned') ||
                      errStr.contains('not authorized'))
                  ? 'You are not assigned to this job.'
                  : errStr
                      .replaceFirst('Exception: ', '')
                      .replaceFirst('StateError: ', '')
                      .replaceFirst('ArgumentError: ', '');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(userMsg),
                  backgroundColor: GovtThemeTokens.alert,
                ),
              );
            }
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
              'Rework resumed for #${job.ticketNumber}. Work in progress.',
            ),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
        _loadWorkdesk();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrewFieldOps] Error resuming rework: $e');
      }
      if (mounted) {
        final errStr = e.toString();
        final userMsg = (errStr.contains('Security Violation') ||
                errStr.contains('not assigned') ||
                errStr.contains('not authorized'))
            ? 'You are not assigned to this job.'
            : errStr
                .replaceFirst('Exception: ', '')
                .replaceFirst('StateError: ', '')
                .replaceFirst('ArgumentError: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMsg),
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
    if (activeUser == null ||
        (!activeUser.isCrew && !activeUser.isSuperAdmin)) {
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
              valueColor: AlwaysStoppedAnimation<Color>(
                GovtThemeTokens.primary,
              ),
            ),
          )
        : _errorMessage != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: GovtThemeTokens.alert,
                  ),
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
        : _workdeskData == null
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                GovtThemeTokens.primary,
              ),
            ),
          )
        : Builder(
            builder: (context) {
              // Use one bounded viewport for the whole workdesk. The shell gives
              // this body a finite height, so ListView avoids the unbounded
              // shrink-wrapping path that previously blanked the web page.
              final scrollableContent = ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      CrewFieldHeader(
                        crewUser: _workdeskData!.crewUser,
                        wardCode: wardCode,
                        departmentName: deptName,
                        onRefresh: _loadWorkdesk,
                      ),

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
                ],
              );

              if (isMobile) {
                return RefreshIndicator(
                  onRefresh: _loadWorkdesk,
                  child: scrollableContent,
                );
              }
              return scrollableContent;
            },
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
      selectedIndex: 0,
      body: mainContent,
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
        return CrewActivitySection(auditLogs: _workdeskData!.myActivityLogs);

      default:
        return const SizedBox.shrink();
    }
  }
}
