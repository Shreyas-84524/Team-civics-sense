import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/complaint_model.dart';
import '../../core/repositories/complaint_repository.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/routing/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/auth/auth_service.dart';
import '../widgets/complaint_details/complaint_details_skeleton.dart';
import '../widgets/complaint_details/complaint_tracker.dart';
import '../widgets/complaint_details/evidence_gallery.dart';
import '../widgets/complaint_details/issue_info_card.dart';
import '../widgets/complaint_details/location_info_card.dart';
import '../widgets/complaint_details/officers_handling_card.dart';
import '../widgets/complaint_details/resolution_evidence_card.dart';
import '../widgets/complaint_details/rework_status_card.dart';
import '../widgets/complaint_details/status_history_timeline.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/services/supabase_complaint_verification_service.dart';

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
  static final Set<String> _shownRejectionPopups = {};

  late final ComplaintRepository _repository;
  late final AuthService _authService;
  StreamSubscription<ComplaintModel?>? _complaintSubscription;

  ComplaintModel? _complaint;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUnauthorized = false;
  bool _isSubmittingSupport = false;
  bool _hasSupported = false;
  bool _isRetryingVerification = false;

  Future<void> _retryVerification(ComplaintModel complaint) async {
    setState(() => _isRetryingVerification = true);
    try {
      await SupabaseComplaintVerificationService.start(
        complaint.id,
        complaint.citizenId,
      );
      if (mounted) {
        await _loadComplaintById(complaint.id, forceRefresh: true);
      }
    } finally {
      if (mounted) setState(() => _isRetryingVerification = false);
    }
  }

  void _checkAndShowAiRejectionDialog(ComplaintModel complaint) {
    if (!complaint.isAiGeneratedEvidenceRejected) return;
    if (_shownRejectionPopups.contains(complaint.id)) return;
    _shownRejectionPopups.add(complaint.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: CivicFixRadius.cardRadius,
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CivicFixColors.statusRejectedBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: CivicFixColors.error,
              size: 32,
            ),
          ),
          title: Text(
            context.l10nOrNull?.complaintRejected ?? 'Complaint Rejected',
            textAlign: TextAlign.center,
            style: CivicFixTypography.h3.copyWith(
              color: CivicFixColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            context.l10nOrNull?.complaintRejectedAuthenticityBody ??
                'The evidence uploaded with this complaint did not pass CivicFix\'s authenticity verification and was identified as AI-generated or digitally manipulated.\n\nFor civic complaints, please upload a genuine photo of the issue captured from the actual location.',
            textAlign: TextAlign.center,
            style: CivicFixTypography.bodySmall.copyWith(
              color: CivicFixColors.secondaryText,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowButtonSpacing: 8,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Navigator.pushNamed(
                    context,
                    AppRoutes.reportIssue,
                    arguments: complaint,
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  context.l10nOrNull?.reportAgain ?? 'Report Again',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CivicFixColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: CivicFixRadius.buttonRadius,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: CivicFixColors.secondaryText,
                ),
                child: Text(
                  context.l10nOrNull?.close ?? 'Close',
                  style: CivicFixTypography.captionMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? RepositoryLocator.complaintRepository;
    _authService = widget.authService ?? AuthServiceLocator.citizenAuth;

    if (widget.complaint != null) {
      _verifyAndSetComplaint(widget.complaint!);
      _subscribeToRealtimeUpdates(widget.complaint!.id);
    } else if (widget.complaintId != null) {
      _loadComplaintById(widget.complaintId!);
      _subscribeToRealtimeUpdates(widget.complaintId!);
    } else {
      _isLoading = false;
      _errorMessage = 'No complaint specified.';
    }
  }

  @override
  void dispose() {
    _complaintSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToRealtimeUpdates(String id) {
    _complaintSubscription?.cancel();
    _complaintSubscription = _repository
        .watchComplaint(id)
        .listen(
          (updated) {
            if (mounted && updated != null) {
              _verifyAndSetComplaint(updated);
            }
          },
          onError: (e) {
            debugPrint('[ComplaintDetailsScreen] Real-time stream error: $e');
          },
        );
  }

  void _verifyAndSetComplaint(ComplaintModel complaint) {
    final currentUserId =
        _authService.currentUser?.id ??
        _authService.currentUid ??
        'user_citizen_001';
    final isUnauthorized =
        currentUserId.isNotEmpty &&
        complaint.citizenId.isNotEmpty &&
        complaint.citizenId != currentUserId &&
        !complaint.isHazard;

    if (isUnauthorized) {
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

    _checkAndShowAiRejectionDialog(complaint);
  }

  Future<void> _loadComplaintById(
    String id, {
    bool forceRefresh = false,
  }) async {
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
        _subscribeToRealtimeUpdates(fetched.id);
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
    final message = context.l10nOrNull != null
        ? context.l10n.complaintIdCopied(ticketNumber)
        : 'Complaint ID $ticketNumber copied.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: CivicFixAppBar(
        title: context.l10nOrNull?.complaintDetails ?? 'Complaint Details',
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
            title: context.l10nOrNull?.unableToOpenComplaint ??
                'Unable to open this complaint.',
            description: context.l10nOrNull?.complaintBelongsToOther ??
                'This report belongs to a different citizen account.',
            actionText: context.l10nOrNull?.backToMyComplaints ??
                'Back to My Complaints',
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
            title: context.l10nOrNull?.couldNotLoadComplaint ??
                "Couldn't load this complaint.",
            message: _errorMessage == "Couldn't load this complaint."
                ? (context.l10nOrNull?.couldNotLoadComplaint ?? _errorMessage!)
                : _errorMessage!,
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
            title: context.l10nOrNull?.complaintNotFound ??
                'Complaint not found.',
            description: context.l10nOrNull?.complaintNotFoundDesc ??
                'This complaint may no longer be available.',
            actionText: context.l10nOrNull?.backToMyComplaints ??
                'Back to My Complaints',
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: CivicFixColors.statusInProgressBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CivicFixColors.alertDark.withValues(
                              alpha: 0.3,
                            ),
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
                              context.l10nOrNull?.pendingSync ?? 'Pending Sync',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: CivicFixColors.info,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10nOrNull?.syncing ?? 'Syncing...',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                              context.l10nOrNull?.syncFailed ?? 'Sync Failed',
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

            // 2. Full Issue Title & Support Action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CivicFixTranslatedText(
                    originalText: complaint.title,
                    contentId: complaint.id,
                    fieldName: 'title',
                    contentCategory: 'complaint_title',
                    style: CivicFixTypography.h2.copyWith(
                      color: CivicFixColors.primaryText,
                      height: 1.25,
                    ),
                  ),
                ),
                CivicFixSpacing.hSpaceSm,
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmittingSupport || _hasSupported
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final l10n = context.l10nOrNull;
                            final supportedText =
                                l10n?.supportedComplaintSuccess ??
                                'Supported this complaint!';
                            final alreadySupportedText =
                                l10n?.alreadySupportedComplaint ??
                                'You already supported this complaint.';
                            final errorPrefix =
                                l10n?.somethingWentWrong ?? 'Failed to upvote';

                            setState(() => _isSubmittingSupport = true);
                            try {
                              final result = await _repository.upvoteComplaint(
                                complaint.id,
                              );
                              if (!mounted) return;
                              setState(() {
                                _isSubmittingSupport = false;
                                _hasSupported = true;
                                _complaint = (_complaint ?? complaint).copyWith(
                                  upvotes: result.upvotes,
                                );
                              });
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.added
                                        ? supportedText
                                        : alreadySupportedText,
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _isSubmittingSupport = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('$errorPrefix: $e')),
                              );
                            }
                          },
                    borderRadius: CivicFixRadius.chipRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: complaint.upvotes > 0
                            ? CivicFixColors.primary.withValues(alpha: 0.1)
                            : CivicFixColors.surfaceMuted,
                        borderRadius: CivicFixRadius.chipRadius,
                        border: Border.all(
                          color: complaint.upvotes > 0
                              ? CivicFixColors.primary.withValues(alpha: 0.3)
                              : CivicFixColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            complaint.upvotes > 0
                                ? Icons.thumb_up_alt_rounded
                                : Icons.thumb_up_alt_outlined,
                            size: 16,
                            color: complaint.upvotes > 0
                                ? CivicFixColors.primary
                                : CivicFixColors.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            complaint.upvotes > 0
                                ? '${complaint.upvotes}'
                                : (context.l10nOrNull?.support ?? 'Support'),
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: complaint.upvotes > 0
                                  ? CivicFixColors.primary
                                  : CivicFixColors.secondaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                            context.l10nOrNull?.waitingForConnection ??
                                'Waiting for connection',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.alertDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            context.l10nOrNull?.complaintStoredSecurelyOffline ??
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CivicFixColors.info,
                        ),
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10nOrNull?.synchronizingWithCloud ??
                                'Synchronizing with Cloud',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.info,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            context.l10nOrNull?.uploadingComplaintData ??
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
                            context.l10nOrNull?.synchronizationFailed ??
                                'Synchronization Failed',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            context.l10nOrNull?.failedToSyncWithCloud ??
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
                              await _loadComplaintById(
                                complaint.id,
                                forceRefresh: true,
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              context.l10nOrNull?.retrySync ?? 'Retry Sync',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CivicFixColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              textStyle: CivicFixTypography.captionMedium
                                  .copyWith(fontWeight: FontWeight.bold),
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
                            context.l10nOrNull?.issueResolvedBanner ??
                                '✓ Issue Resolved',
                            style: CivicFixTypography.bodySmallMedium.copyWith(
                              color: CivicFixColors.secondaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            context.l10nOrNull?.complaintMarkedResolved ??
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

            // Rework Alert Card (if reopened for quality rework)
            if (complaint.isReopened || (complaint.reopenCount > 0 && complaint.status != ComplaintStatus.resolved)) ...[
              ReworkStatusCard(complaint: complaint),
              CivicFixSpacing.vSpaceLg,
            ],

            // Rejection Banner (if rejected due to AI authenticity or evidence failure)
            if (complaint.isAiGeneratedEvidenceRejected ||
                (complaint.status == ComplaintStatus.rejected && complaint.isEvidenceRejected)) ...[
              _buildRejectionBanner(complaint),
              CivicFixSpacing.vSpaceLg,
            ],

            // 4. Five-Stage Progress Tracker
            ComplaintTracker(
              currentStatus: complaint.status,
              customStatusMessage: complaint.officerNotes,
              complaint: complaint,
            ),
            if (complaint.status == ComplaintStatus.underVerification &&
                !complaint.isAiGeneratedEvidenceRejected &&
                !complaint.isEvidenceRejected &&
                (complaint.evidenceVerificationStatus == 'temporarily_unavailable' ||
                    complaint.departmentVerificationStatus == 'temporarily_unavailable'))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isRetryingVerification
                          ? null
                          : () => _retryVerification(complaint),
                      icon: const Icon(Icons.refresh),
                      label: Text(_isRetryingVerification
                          ? 'Requesting verification…'
                          : 'Retry verification'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'The AI service is temporarily unavailable. No report data was lost; retry after the service recovers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            CivicFixSpacing.vSpaceLg,

            // 5. Assigned Municipal Team Card (Supervising JE & Ground FO)
            OfficersHandlingCard(complaint: complaint),
            CivicFixSpacing.vSpaceLg,

            // 6. Resolution & Work Verification Evidence Card (if resolved or evidence exists)
            if (isResolved || complaint.afterWorkPhoto != null || (complaint.resolutionRemarks != null && complaint.resolutionRemarks!.isNotEmpty)) ...[
              ResolutionEvidenceCard(complaint: complaint),
              CivicFixSpacing.vSpaceLg,
            ],

            // 7. Issue Information Card (Category, Department, Description, Priority)
            IssueInfoCard(complaint: complaint),
            CivicFixSpacing.vSpaceLg,

            // 8. Location Information Card with "View Location" trigger
            LocationInfoCard(location: complaint.location),
            CivicFixSpacing.vSpaceLg,

            // 9. Evidence Gallery with Fullscreen Viewer
            EvidenceGallery(imageUrls: complaint.imageUrls),
            CivicFixSpacing.vSpaceLg,

            // 10. Status History / Updates Timeline
            StatusHistoryTimeline(timeline: complaint.timeline),
            CivicFixSpacing.vSpaceLg,

            // 9. Timestamps Footer
            Center(
              child: Column(
                children: [
                  Text(
                    context.l10nOrNull != null
                        ? context.l10n.reportedOn(
                            DateFormatter.formatFullDate(complaint.createdAt),
                          )
                        : 'Reported on ${DateFormatter.formatFullDate(complaint.createdAt)}',
                    style: CivicFixTypography.caption.copyWith(
                      color: CivicFixColors.secondaryText,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    context.l10nOrNull != null
                        ? context.l10n.lastUpdatedTime(
                            DateFormatter.formatRelativeTime(complaint.updatedAt),
                          )
                        : 'Last updated ${DateFormatter.formatRelativeTime(complaint.updatedAt)}',
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

  Widget _buildRejectionBanner(ComplaintModel complaint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: CivicFixColors.statusRejectedBg,
        borderRadius: CivicFixRadius.cardRadius,
        border: Border.all(
          color: CivicFixColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CivicFixColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
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
                      context.l10nOrNull?.complaintRejected ?? 'Complaint Rejected',
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        color: CivicFixColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      complaint.isAiGeneratedEvidenceRejected
                          ? (context.l10nOrNull?.complaintRejectedAuthenticityBody ??
                              'The evidence uploaded with this complaint did not pass authenticity verification and was identified as AI-generated or digitally manipulated. Please upload a genuine photo from the actual site.')
                          : (complaint.verificationFailureReason ??
                              'This complaint did not pass verification and has been closed.'),
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.primaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.reportIssue,
                  arguments: complaint,
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(context.l10nOrNull?.reportAgain ?? 'Report Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CivicFixColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                textStyle: CivicFixTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: CivicFixRadius.buttonRadius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
