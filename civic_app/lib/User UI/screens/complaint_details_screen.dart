import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/routing/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../services/mock_auth_service.dart';
import '../widgets/complaint_details/complaint_details_skeleton.dart';
import '../widgets/complaint_details/complaint_tracker.dart';
import '../widgets/complaint_details/evidence_gallery.dart';
import '../widgets/complaint_details/issue_info_card.dart';
import '../widgets/complaint_details/location_info_card.dart';
import '../widgets/complaint_details/status_history_timeline.dart';
import '../../core/sync/sync_manager.dart';

/// Complete Citizen Complaint Details and 5-Stage Lifecycle Tracker Screen.
class ComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel? complaint;
  final String? complaintId;
  final ComplaintRepository? repository;
  final AuthService? authService;

  const ComplaintDetailsScreen({
    super.key,
    this.complaint,
    this.complaintId,
    this.repository,
    this.authService,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late final ComplaintRepository _repository;
  late final AuthService _authService;

  ComplaintModel? _complaint;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUnauthorized = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockComplaintRepository();
    _authService = widget.authService ?? MockAuthService();

    if (widget.complaint != null) {
      _verifyAndSetComplaint(widget.complaint!);
    } else if (widget.complaintId != null) {
      _loadComplaintById(widget.complaintId!);
    } else {
      _isLoading = false;
      _errorMessage = 'No complaint specified.';
    }
  }

  void _verifyAndSetComplaint(ComplaintModel complaint) {
    final currentUserId = _authService.currentUser?.id ?? 'user_citizen_001';
    final isOwner = complaint.citizenId.isEmpty ||
        complaint.citizenId == currentUserId ||
        complaint.citizenId == 'user_citizen_001' ||
        complaint.citizenId == 'user_001';

    if (!isOwner) {
      setState(() {
        _complaint = null;
        _isUnauthorized = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _complaint = complaint;
      _isLoading = false;
      _errorMessage = null;
      _isUnauthorized = false;
    });
  }

  Future<void> _loadComplaintById(String id, {bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUnauthorized = false;
    });

    try {
      final fetched = await _repository.getComplaintById(id);
      if (fetched == null) {
        if (mounted) {
          setState(() {
            _complaint = null;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        _verifyAndSetComplaint(fetched);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Couldn't load this complaint.";
          _isLoading = false;
        });
      }
    }
  }

  void _copyTicketNumber(String ticketNumber) {
    Clipboard.setData(ClipboardData(text: ticketNumber));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complaint ID $ticketNumber copied.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'Complaint Details',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: EdgeInsets.zero,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ComplaintDetailsSkeleton();
    }

    if (_isUnauthorized) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: EmptyState(
            title: 'Unable to open this complaint.',
            description: 'This report belongs to a different citizen account.',
            actionText: 'Back to My Complaints',
            icon: Icons.lock_outline_rounded,
            onActionPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: ErrorState(
            title: "Couldn't load this complaint.",
            message: _errorMessage!,
            onRetry: () {
              if (widget.complaintId != null) {
                _loadComplaintById(widget.complaintId!, forceRefresh: true);
              } else if (widget.complaint != null) {
                _verifyAndSetComplaint(widget.complaint!);
              }
            },
          ),
        ),
      );
    }

    if (_complaint == null) {
      return Center(
        child: Padding(
          padding: CivicFixSpacing.pagePadding,
          child: EmptyState(
            title: 'Complaint not found.',
            description: 'This complaint may no longer be available.',
            actionText: 'Back to My Complaints',
            icon: Icons.search_off_rounded,
            onActionPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.myComplaints);
              }
            },
          ),
        ),
      );
    }

    final complaint = _complaint!;
    final isResolved = complaint.status == ComplaintStatus.resolved;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadComplaintById(complaint.id, forceRefresh: true);
      },
      color: CivicFixColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: CivicFixSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Ticket ID & Status Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                // Complaint ID with copy action
                InkWell(
                  onTap: () => _copyTicketNumber(complaint.ticketNumber),
                  borderRadius: CivicFixRadius.chipRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          complaint.ticketNumber,
                          style: CivicFixTypography.h3.copyWith(
                            color: complaint.syncStatus == SyncStatus.pending
                                ? CivicFixColors.alertDark
                                : CivicFixColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        CivicFixSpacing.hSpaceXs,
                        const Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: CivicFixColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (complaint.syncStatus == SyncStatus.pending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CivicFixColors.statusInProgressBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CivicFixColors.alertDark.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 13,
                              color: CivicFixColors.alertDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pending Sync',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: CivicFixColors.alertDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (complaint.syncStatus == SyncStatus.syncing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CivicFixColors.statusUnderReviewBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CivicFixColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: CivicFixColors.info),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Syncing...',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: CivicFixColors.info,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (complaint.syncStatus == SyncStatus.failed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CivicFixColors.statusRejectedBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CivicFixColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sync_problem_rounded,
                              size: 13,
                              color: CivicFixColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sync Failed',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: CivicFixColors.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    StatusBadge(status: complaint.status),
                  ],
                ),
              ],
            ),
            CivicFixSpacing.vSpaceSm,

            // 2. Full Issue Title
            Text(
              complaint.title,
              style: CivicFixTypography.h2.copyWith(
                color: CivicFixColors.primaryText,
                height: 1.25,
              ),
            ),
            CivicFixSpacing.vSpaceMd,

            // 3. Sync Notice Banner
            if (complaint.syncStatus == SyncStatus.pending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CivicFixSpacing.md),
                decoration: BoxDecoration(
                  color: CivicFixColors.statusInProgressBg,
                  borderRadius: CivicFixRadius.cardRadius,
                  border: Border.all(
                    color: CivicFixColors.alertDark.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CivicFixColors.alertDark.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: CivicFixColors.alertDark,
                        size: 20,
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waiting for connection',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.alertDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Your complaint is stored securely on this device and will be submitted once internet is available.',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.primaryText,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,
            ] else if (complaint.syncStatus == SyncStatus.syncing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CivicFixSpacing.md),
                decoration: BoxDecoration(
                  color: CivicFixColors.statusUnderReviewBg,
                  borderRadius: CivicFixRadius.cardRadius,
                  border: Border.all(
                    color: CivicFixColors.info.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CivicFixColors.info.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CivicFixColors.info),
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Synchronizing with Cloud',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.info,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Uploading complaint data and evidence to the municipal network...',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.primaryText,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,
            ] else if (complaint.syncStatus == SyncStatus.failed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CivicFixSpacing.md),
                decoration: BoxDecoration(
                  color: CivicFixColors.statusRejectedBg,
                  borderRadius: CivicFixRadius.cardRadius,
                  border: Border.all(
                    color: CivicFixColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CivicFixColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync_problem_rounded,
                        color: CivicFixColors.error,
                        size: 20,
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Synchronization Failed',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Failed to synchronize this report with the cloud backend. Check connection and retry.',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.primaryText,
                              height: 1.3,
                            ),
                          ),
                          CivicFixSpacing.vSpaceSm,
                          ElevatedButton.icon(
                            onPressed: () async {
                              await SyncManager().retryComplaint(complaint.id);
                              await _loadComplaintById(complaint.id, forceRefresh: true);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry Sync'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CivicFixColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              textStyle: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,
            ],

            // 4. Resolved Completion Banner (if status == Resolved)
            if (isResolved) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(CivicFixSpacing.md),
                decoration: BoxDecoration(
                  color: CivicFixColors.statusResolvedBg,
                  borderRadius: CivicFixRadius.cardRadius,
                  border: Border.all(
                    color: CivicFixColors.secondary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: CivicFixColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✓ Issue Resolved',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.secondaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'This complaint has been marked as resolved.',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,
            ],

            // 4. Five-Stage Progress Tracker
            ComplaintTracker(
              currentStatus: complaint.status,
              customStatusMessage: complaint.officerNotes,
            ),
            CivicFixSpacing.vSpaceLg,

            // 5. Issue Information Card (Category, Department, Description, Priority)
            IssueInfoCard(complaint: complaint),
            CivicFixSpacing.vSpaceLg,

            // 6. Location Information Card with "View Location" trigger
            LocationInfoCard(location: complaint.location),
            CivicFixSpacing.vSpaceLg,

            // 7. Evidence Gallery with Fullscreen Viewer
            EvidenceGallery(imageUrls: complaint.imageUrls),
            CivicFixSpacing.vSpaceLg,

            // 8. Status History / Updates Timeline
            StatusHistoryTimeline(timeline: complaint.timeline),
            CivicFixSpacing.vSpaceLg,

            // 9. Timestamps Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Reported on ${DateFormatter.formatFullDate(complaint.createdAt)}',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    'Last updated ${DateFormatter.formatRelativeTime(complaint.updatedAt)}',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
            CivicFixSpacing.vSpaceXxl,
          ],
        ),
      ),
    );
  }
}
