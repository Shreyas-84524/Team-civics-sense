import 'package:flutter/material.dart';
import '../../../core/auth/auth_service_locator.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/models/complaint_routing_ticket_model.dart';
import '../../../core/models/government_audit_log_model.dart';
import '../../../core/repositories/repository_locator.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/services/complaint_routing_service.dart';
import '../../../core/services/government_audit_service.dart';
import '../../../core/services/government_authorization_service.dart';
import '../../../core/services/government_hierarchy_repository.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_complaint_visibility_service.dart';
import '../../services/government_crew_work_service.dart';
import '../../services/government_department_lead_dashboard_service.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_responsive.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/government_app_shell.dart';
import '../../widgets/common/government_error_state.dart';
import '../../widgets/common/government_page_header.dart';
import '../../widgets/common/govt_breadcrumbs.dart';
import '../../widgets/common/govt_loading_states.dart';
import '../../widgets/complaints/ai_authenticity_card.dart';
import '../../widgets/complaints/shared/government_complaint_action_bar.dart';
import '../../widgets/complaints/shared/government_complaint_audit_section.dart';
import '../../widgets/complaints/shared/government_complaint_location_card.dart';
import '../../widgets/complaints/shared/government_complaint_overview_card.dart';
import '../../widgets/complaints/shared/government_complaint_sla_card.dart';
import '../../widgets/complaints/shared/government_complaint_timeline.dart';
import '../../widgets/complaints/shared/government_evidence_gallery.dart';
import '../../widgets/complaints/shared/government_routing_history_section.dart';
import '../../widgets/dashboard/sections/crew/crew_evidence_submission_dialog.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_assign_dialog.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_routing_dialog.dart';
import '../../widgets/dashboard/sections/department_lead/department_lead_verification_dialog.dart';

/// Consolidated, Standardized Government Complaint Detail Screen across all 6 roles.
/// Route: `/government/complaints/:complaintId` and `/govt/complaint-details`.
class GovtComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel? complaint;
  final String? complaintId;
  final GovtUserModel? user;
  final GovtComplaintRepository? repository;
  final GovernmentHierarchyRepository? hierarchyRepo;
  final ComplaintRoutingService? routingService;
  final GovernmentAuditService? auditService;
  final GovernmentAuthorizationService? authService;

  const GovtComplaintDetailsScreen({
    super.key,
    this.complaint,
    this.complaintId,
    this.user,
    this.repository,
    this.hierarchyRepo,
    this.routingService,
    this.auditService,
    this.authService,
  });

  @override
  State<GovtComplaintDetailsScreen> createState() => _GovtComplaintDetailsScreenState();
}

class _GovtComplaintDetailsScreenState extends State<GovtComplaintDetailsScreen> {
  late final GovtComplaintRepository _repository;
  late final GovernmentHierarchyRepository _hierarchyRepo;
  late final ComplaintRoutingService _routingService;
  late final GovernmentAuditService _auditService;
  late final GovernmentAuthorizationService _authService;
  late final GovernmentComplaintVisibilityService _visibilityService;

  GovtUserModel? _currentUser;
  ComplaintModel? _complaint;
  List<ComplaintRoutingTicket> _routingTickets = [];
  List<GovernmentAuditLog> _auditLogs = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasJurisdiction = true;
  String? _zoneName;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? RepositoryLocator.govtComplaintRepository;
    _hierarchyRepo = widget.hierarchyRepo ?? LocalGovernmentHierarchyRepository();
    _auditService = widget.auditService ?? DefaultGovernmentAuditService();
    _routingService = widget.routingService ?? ComplaintRoutingService();
    _authService = widget.authService ?? GovernmentAuthorizationService(hierarchyRepo: _hierarchyRepo);
    _visibilityService = GovernmentComplaintVisibilityService(
      hierarchyRepo: _hierarchyRepo,
      authService: _authService,
    );

    _currentUser = widget.user ?? AuthServiceLocator.govtAuth.currentUser;
    _complaint = widget.complaint;
    _isLoading = _complaint == null;
    _loadFullDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_complaint == null && widget.complaint == null && widget.complaintId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ComplaintModel) {
        _complaint = args;
        _isLoading = false;
        _loadFullDetails();
      } else if (args is String) {
        _loadById(args);
      }
    }
  }

  Future<void> _loadById(String id) async {
    final c = await _repository.getComplaintById(id);
    if (mounted) {
      setState(() {
        _complaint = c;
        _isLoading = false;
      });
      await _loadFullDetails();
    }
  }

  Future<void> _loadFullDetails() async {
    if (_complaint == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

    try {
      // 1. Resolve User
      _currentUser ??= AuthServiceLocator.govtAuth.currentUser ??
          const GovtUserModel(
            id: 'GOV-SUPER-ADMIN-01',
            employeeId: 'EMP-001',
            fullName: 'Municipal Commissioner',
            email: 'commissioner@mcgm.gov.in',
            role: 'super_admin',
            wardId: 'A',
            departmentId: 'dept_admin',
            departmentName: 'General Administration',
            displayDesignation: 'Municipal Commissioner & CEO',
            active: true,
          );

      // 2. Resolve Complaint
      if (_complaint == null) {
        if (widget.complaint != null) {
          _complaint = widget.complaint;
        } else if (widget.complaintId != null) {
          _complaint = await _repository.getComplaintById(widget.complaintId!);
        }
      }

      if (_complaint == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Grievance record could not be found or has been archived.';
          });
        }
        return;
      }

      // 3. Deep Link Jurisdiction & Visibility Check
      final isVisible = await _visibilityService.canViewComplaint(
        user: _currentUser!,
        complaint: _complaint!,
      );

      if (!isVisible) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasJurisdiction = false;
          });
        }
        return;
      }

      // 4. Resolve Zone Name
      final wardCode = _complaint!.wardId ?? _complaint!.location.ward;
      if (wardCode != null) {
        final ward = await _hierarchyRepo.getWardById(wardCode);
        if (ward != null) {
          final zone = await _hierarchyRepo.getZoneById(ward.zoneId);
          _zoneName = zone?.displayName;
        }
      }

      // 5. Load Routing History
      _routingTickets = await _routingService.getTicketsForComplaint(_complaint!.id);

      // 6. Load Audit Logs for this complaint
      final allLogs = await _auditService.getLogsForComplaint(_complaint!.id);
      _auditLogs = allLogs;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasJurisdiction = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load grievance details: $e';
        });
      }
    }
  }

  List<GovernmentEvidenceItem> _buildEvidenceItems(ComplaintModel c) {
    final List<GovernmentEvidenceItem> items = [];

    // Citizen Evidence
    for (int i = 0; i < c.imageUrls.length; i++) {
      items.add(
        GovernmentEvidenceItem(
          imageUrl: c.imageUrls[i],
          title: 'Citizen Report Evidence #${i + 1}',
          stage: 'citizen',
          timestamp: c.createdAt,
        ),
      );
    }

    return items;
  }

  List<GovtBreadcrumbItem> _buildBreadcrumbs(ComplaintModel c) {
    final ward = c.wardId ?? c.location.ward ?? 'Ward';
    final dept = c.departmentName ?? c.assignedDepartmentId ?? 'Department';
    final tkt = c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id;

    if (_currentUser?.isSuperAdmin == true) {
      return [
        const GovtBreadcrumbItem(label: 'City Command', route: '/government/dashboard'),
        GovtBreadcrumbItem(label: 'Ward $ward', route: '/government/ward'),
        GovtBreadcrumbItem(label: dept, route: '/government/department-operations'),
        GovtBreadcrumbItem(label: 'Ticket #$tkt'),
      ];
    }

    if (_currentUser?.isZonalDmc == true) {
      return [
        const GovtBreadcrumbItem(label: 'Zone Command', route: '/government/zone'),
        GovtBreadcrumbItem(label: 'Ward $ward', route: '/government/ward'),
        GovtBreadcrumbItem(label: 'Ticket #$tkt'),
      ];
    }

    if (_currentUser?.isCentralHod == true) {
      return [
        GovtBreadcrumbItem(label: dept, route: '/government/department'),
        GovtBreadcrumbItem(label: 'Ward $ward', route: '/government/ward'),
        GovtBreadcrumbItem(label: 'Ticket #$tkt'),
      ];
    }

    if (_currentUser?.isWardLead == true) {
      return [
        const GovtBreadcrumbItem(label: 'Unit Operations', route: '/government/department-operations'),
        GovtBreadcrumbItem(label: 'Ticket #$tkt'),
      ];
    }

    if (_currentUser?.isCrew == true) {
      return [
        const GovtBreadcrumbItem(label: 'My Work', route: '/government/work'),
        GovtBreadcrumbItem(label: 'Ticket #$tkt'),
      ];
    }

    return [
      GovtBreadcrumbItem(label: 'Ward $ward', route: '/government/ward'),
      GovtBreadcrumbItem(label: 'Ticket #$tkt'),
    ];
  }

  // Action Handlers
  Future<void> _handleStartWork() async {
    if (_complaint == null || _currentUser == null) return;
    try {
      final crewService = GovernmentCrewWorkService(
        complaintRepo: _repository,
        hierarchyRepo: _hierarchyRepo,
        routingService: _routingService,
        auditService: _auditService,
        authService: _authService,
      );
      final updated = await crewService.startJob(
        complaintId: _complaint!.id,
        crewId: _currentUser!.employeeId,
      );
      setState(() => _complaint = updated);
      await _loadFullDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field work commenced successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start work: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmitCompletion() async {
    if (_complaint == null || _currentUser == null) return;
    final crewService = GovernmentCrewWorkService(
      complaintRepo: _repository,
      hierarchyRepo: _hierarchyRepo,
      routingService: _routingService,
      auditService: _auditService,
      authService: _authService,
    );

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => CrewEvidenceSubmissionDialog(
        complaint: _complaint!,
        crewId: _currentUser!.employeeId,
        onSubmitCompletion: ({
          required String beforePhotoUrl,
          required String afterPhotoUrl,
          String? duringPhotoUrl,
          required String workRemarks,
        }) async {
          final updated = await crewService.submitWorkCompletion(
            complaintId: _complaint!.id,
            crewId: _currentUser!.employeeId,
            beforePhotoUrl: beforePhotoUrl,
            duringPhotoUrl: duringPhotoUrl,
            afterPhotoUrl: afterPhotoUrl,
            workRemarks: workRemarks,
          );
          setState(() => _complaint = updated);
        },
      ),
    );

    if (success == true) {
      await _loadFullDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work submitted for supervisor verification.')),
        );
      }
    }
  }

  void _showVerifyDialog() {
    if (_complaint == null) return;
    final c = _complaint!;
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verify Grievance ${c.ticketNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that this complaint is verified for departmental triage and action.',
              style: TextStyle(fontSize: 13),
            ),
            CivicFixSpacing.vSpaceMd,
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Verification Notes (Optional)',
                hintText: 'e.g. Field inspection confirmed issue validity.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _repository.verifyComplaint(
                complaintId: c.id,
                notes: notesController.text.trim(),
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Grievance ${c.ticketNumber} marked as Verified.')),
                  );
                  await _loadFullDetails();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GovtThemeTokens.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Confirm Verification'),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog() {
    if (_complaint == null) return;
    final c = _complaint!;
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Flag Grievance ${c.ticketNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flag this complaint for administrative review or moderation.',
              style: TextStyle(fontSize: 13),
            ),
            CivicFixSpacing.vSpaceMd,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Flag Reason',
                hintText: 'e.g. Inappropriate content or spam report.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _repository.flagComplaint(
                complaintId: c.id,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : 'Administrative review required',
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Grievance ${c.ticketNumber} flagged for review.')),
                  );
                  await _loadFullDetails();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GovtThemeTokens.alert,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Confirm Flag'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAssignCrew() async {
    if (_complaint == null || _currentUser == null) return;

    if (_currentUser?.isWardLead == true) {
      final leadService = GovernmentDepartmentLeadDashboardService(
        complaintRepo: _repository,
        hierarchyRepo: _hierarchyRepo,
        routingService: _routingService,
        auditService: _auditService,
        authService: _authService,
      );

      final allCrew = await _hierarchyRepo.getUsers(
        role: 'department_crew',
        wardId: _complaint!.wardId,
        departmentId: _complaint!.assignedDepartmentId,
      );

      final workloads = allCrew.map((c) => CrewWorkloadItem(
        crewUser: c,
        assignedJobs: 1,
        inProgress: 0,
        awaitingVerification: 0,
        completedToday: 0,
        isAvailable: true,
      )).toList();

      if (!mounted) return;

      final success = await showDialog<bool>(
        context: context,
        builder: (ctx) => DepartmentLeadAssignDialog(
          complaint: _complaint!,
          crewWorkloads: workloads,
          leadId: _currentUser!.employeeId,
          onAssignConfirmed: (crewId) async {
            final updated = await leadService.assignCrewMember(
              complaintId: _complaint!.id,
              leadId: _currentUser!.employeeId,
              crewMemberId: crewId,
            );
            setState(() => _complaint = updated);
          },
        ),
      );

      if (success == true) {
        await _loadFullDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crew technician dispatched successfully.')),
          );
        }
      }
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.govtComplaintAssignment,
        arguments: _complaint,
      ).then((_) => _loadFullDetails());
    }
  }

  Future<void> _handleRaiseWrongDepartment() async {
    if (_complaint == null || _currentUser == null) return;
    final leadService = GovernmentDepartmentLeadDashboardService(
      complaintRepo: _repository,
      hierarchyRepo: _hierarchyRepo,
      routingService: _routingService,
      auditService: _auditService,
      authService: _authService,
    );

    final departments = await _hierarchyRepo.getDepartments();

    if (!mounted) return;

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => DepartmentLeadRoutingDialog(
        complaint: _complaint!,
        sourceDepartmentId: _complaint!.assignedDepartmentId ?? _currentUser!.departmentId ?? 'maintenance_roads',
        allDepartments: departments,
        onTicketSubmitted: ({
          required String suggestedDepartmentId,
          required String reason,
          String? remarks,
        }) async {
          await leadService.raiseRoutingRequest(
            complaintId: _complaint!.id,
            sourceLeadId: _currentUser!.employeeId,
            suggestedDepartmentId: suggestedDepartmentId,
            reason: reason,
            remarks: remarks,
          );
        },
      ),
    );

    if (success == true) {
      await _loadFullDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reassignment request submitted to Ward Officer.')),
        );
      }
    }
  }

  Future<void> _handleApproveRouting() async {
    if (_complaint == null || _currentUser == null) return;
    final pendingTickets = _routingTickets.where((t) => t.isPending).toList();
    if (pendingTickets.isEmpty) return;
    final activeTicket = pendingTickets.first;

    try {
      await _routingService.reviewRoutingTicket(
        ticketId: activeTicket.id,
        reviewerId: _currentUser!.employeeId,
        approve: true,
        reviewNotes: 'Reassignment approved by Ward Officer.',
      );
      await _loadFullDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department transfer approved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve transfer: $e')),
        );
      }
    }
  }

  Future<void> _handleRejectRouting() async {
    if (_complaint == null || _currentUser == null) return;
    final pendingTickets = _routingTickets.where((t) => t.isPending).toList();
    if (pendingTickets.isEmpty) return;
    final activeTicket = pendingTickets.first;

    try {
      await _routingService.reviewRoutingTicket(
        ticketId: activeTicket.id,
        reviewerId: _currentUser!.employeeId,
        approve: false,
        reviewNotes: 'Reassignment rejected; jurisdiction remains with current department.',
      );
      await _loadFullDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department transfer request rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject transfer: $e')),
        );
      }
    }
  }

  Future<void> _handleVerifyCompletion() async {
    if (_complaint == null || _currentUser == null) return;
    final leadService = GovernmentDepartmentLeadDashboardService(
      complaintRepo: _repository,
      hierarchyRepo: _hierarchyRepo,
      routingService: _routingService,
      auditService: _auditService,
      authService: _authService,
    );

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => DepartmentLeadVerificationDialog(
        complaint: _complaint!,
        leadId: _currentUser!.employeeId,
        onVerificationCompleted: ({
          required String notes,
          bool returnForRework = false,
          String? reworkReason,
        }) async {
          await leadService.verifyCompletion(
            complaintId: _complaint!.id,
            leadId: _currentUser!.employeeId,
            notes: notes,
            returnForRework: returnForRework,
            reworkReason: reworkReason,
          );
        },
      ),
    );

    if (success == true) {
      await _loadFullDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance verified and marked resolved.')),
        );
      }
    }
  }

  void _handleUpdateStatus() {
    if (_complaint == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.govtStatusUpdate,
      arguments: _complaint,
    ).then((_) => _loadFullDetails());
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = GovtResponsive.isMobile(context);

    if (_isLoading) {
      return const GovernmentAppShell(
        title: 'Grievance Record',
        subtitle: 'Loading operational complaint telemetry...',
        body: Padding(
          padding: EdgeInsets.all(CivicFixSpacing.xl),
          child: GovtPageLoader(message: 'Loading grievance record...'),
        ),
      );
    }

    if (!_hasJurisdiction) {
      return GovernmentAppShell(
        title: 'Access Restricted',
        subtitle: 'Jurisdiction Check Required',
        body: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.xxl),
          child: GovernmentErrorState(
            title: 'Jurisdiction Boundary Restriction',
            message:
                'You do not have administrative or operational jurisdiction to inspect grievance #${widget.complaintId ?? widget.complaint?.id ?? ""}. Access is restricted strictly to authorized ward, zonal, or departmental personnel.',
            onRetry: _loadFullDetails,
          ),
        ),
      );
    }

    if (_errorMessage != null || _complaint == null) {
      return GovernmentAppShell(
        title: 'Grievance Record',
        subtitle: 'Grievance Inspection',
        body: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.xxl),
          child: GovernmentErrorState(
            title: 'Grievance Not Found',
            message: _errorMessage ?? 'The requested complaint record could not be loaded.',
            onRetry: _loadFullDetails,
          ),
        ),
      );
    }

    final c = _complaint!;
    final breadcrumbs = _buildBreadcrumbs(c);
    final evidenceItems = _buildEvidenceItems(c);
    final activeTicket = _routingTickets.where((t) => t.isPending).firstOrNull;

    final permittedActions = _visibilityService.getPermittedActions(
      user: _currentUser!,
      complaint: c,
      activeTicket: activeTicket,
    );

    final content = SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? CivicFixSpacing.md : CivicFixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          GovernmentPageHeader(
            title: 'Grievance ${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id}',
            subtitle: '${c.category.name} · Ward ${c.wardId ?? c.location.ward ?? "N/A"} · ${c.departmentName ?? c.assignedDepartmentId ?? "General"}',
            breadcrumbs: breadcrumbs,
          ),
          CivicFixSpacing.vSpaceMd,

          // Action Bar (Role & State aware)
          GovernmentComplaintActionBar(
            permittedActions: permittedActions,
            onVerify: _showVerifyDialog,
            onFlag: _showFlagDialog,
            onStartWork: _handleStartWork,
            onSubmitCompletion: _handleSubmitCompletion,
            onAssignCrew: _handleAssignCrew,
            onReassignCrew: _handleAssignCrew,
            onRaiseWrongDepartment: _handleRaiseWrongDepartment,
            onApproveRouting: _handleApproveRouting,
            onRejectRouting: _handleRejectRouting,
            onVerifyCompletion: _handleVerifyCompletion,
            onReturnForRework: _handleVerifyCompletion,
            onUpdateStatus: _handleUpdateStatus,
          ),
          CivicFixSpacing.vSpaceLg,

          // Overview Card
          GovernmentComplaintOverviewCard(
            complaint: c,
            zoneName: _zoneName,
          ),
          CivicFixSpacing.vSpaceLg,

          // Department & Crew Assignment Card
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
              boxShadow: GovtThemeTokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department & Crew Assignment',
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Operational ownership and unit execution assignment',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: GovtThemeTokens.info, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned Department', style: CivicFixTypography.caption),
                          Text(
                            c.effectiveDepartment,
                            style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF3F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_pin_rounded, color: GovtThemeTokens.secondary, size: 20),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Field Lead / Crew', style: CivicFixTypography.caption),
                          Text(
                            c.assignedTo ?? (c.assignedCrewMemberId != null ? 'Crew (${c.assignedCrewMemberId})' : 'Pending Assignment'),
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.assignedTo != null || c.assignedCrewMemberId != null
                                  ? GovtThemeTokens.textPrimary
                                  : GovtThemeTokens.alert,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Location & SLA Grid
          if (isMobile) ...[
            GovernmentComplaintLocationCard(complaint: c),
            CivicFixSpacing.vSpaceLg,
            GovernmentComplaintSlaCard(complaint: c),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: GovernmentComplaintLocationCard(complaint: c)),
                CivicFixSpacing.hSpaceLg,
                Expanded(child: GovernmentComplaintSlaCard(complaint: c)),
              ],
            ),
          ],
          CivicFixSpacing.vSpaceLg,

          // Photo & Geographic Evidence Gallery + AI Authenticity Card
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
              boxShadow: GovtThemeTokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo & Geographic Evidence',
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  '${c.imageUrls.length} image attachments provided',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,
                GovernmentEvidenceGallery(
                  title: 'MULTI-STAGE PHOTOGRAPHIC EVIDENCE (${evidenceItems.length})',
                  evidenceItems: evidenceItems,
                ),
                CivicFixSpacing.vSpaceLg,
                AiAuthenticityCard.fromComplaint(c),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Routing History Section
          if (_routingTickets.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.lg),
              decoration: BoxDecoration(
                color: GovtThemeTokens.surface,
                borderRadius: GovtThemeTokens.cardRadius,
                border: Border.all(color: GovtThemeTokens.border),
                boxShadow: GovtThemeTokens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEPARTMENT TRANSFER & ROUTING HISTORY',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    'Audit record of cross-department reassignment requests and officer adjudications',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                  CivicFixSpacing.vSpaceMd,
                  const Divider(color: GovtThemeTokens.divider, height: 1),
                  CivicFixSpacing.vSpaceMd,
                  GovernmentRoutingHistorySection(routingTickets: _routingTickets),
                ],
              ),
            ),
            CivicFixSpacing.vSpaceLg,
          ],

          // Lifecycle Timeline
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: GovtThemeTokens.cardRadius,
              border: Border.all(color: GovtThemeTokens.border),
              boxShadow: GovtThemeTokens.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status & Audit Trail',
                  style: CivicFixTypography.h3.copyWith(
                    color: GovtThemeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'COMPLAINT LIFECYCLE TIMELINE · Chronological sequence of citizen submissions, triage, assignments, and field events',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textSecondary,
                  ),
                ),
                CivicFixSpacing.vSpaceMd,
                const Divider(color: GovtThemeTokens.divider, height: 1),
                CivicFixSpacing.vSpaceMd,
                GovernmentComplaintTimeline(timeline: c.timeline),
              ],
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Audit Section
          if (_auditLogs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.lg),
              decoration: BoxDecoration(
                color: GovtThemeTokens.surface,
                borderRadius: GovtThemeTokens.cardRadius,
                border: Border.all(color: GovtThemeTokens.border),
                boxShadow: GovtThemeTokens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IMMUTABLE ADMINISTRATIVE AUDIT LOG',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    'Cryptographically traceable event log of all officer interactions with this record',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                  CivicFixSpacing.vSpaceMd,
                  const Divider(color: GovtThemeTokens.divider, height: 1),
                  CivicFixSpacing.vSpaceMd,
                  GovernmentComplaintAuditSection(auditLogs: _auditLogs),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return GovernmentAppShell(
      title: 'Grievance #${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id}',
      subtitle: '${c.category.name} · Ward ${c.wardId ?? c.location.ward ?? "N/A"}',
      breadcrumbs: breadcrumbs,
      body: content,
    );
  }
}
