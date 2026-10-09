import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/firebase/errors/firestore_exception.dart';
import '../../core/firebase/storage/storage_error_handler.dart';
import '../../core/location/location_model.dart';
import '../../core/repositories/repository_locator.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/civic_fix_outlined_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../models/complaint_draft.dart';
import '../services/evidence_service.dart';
import '../services/location_service.dart';
import '../services/mock_complaint_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/report_issue/complaint_review_card.dart';
import '../widgets/report_issue/discard_report_dialog.dart';
import '../widgets/report_issue/evidence_picker.dart';
import '../widgets/report_issue/issue_category_selector.dart';
import '../widgets/report_issue/location_selection_card.dart';
import '../widgets/report_issue/report_progress_indicator.dart';
import 'select_location_screen.dart';

/// Complete Citizen Report Issue Guided Flow (Steps 1 to 4).
class ReportIssueScreen extends StatefulWidget {
  final ComplaintDraft? initialDraft;
  final ComplaintService? complaintService;
  final EvidenceService? evidenceService;
  final LocationService? locationService;

  const ReportIssueScreen({
    super.key,
    this.initialDraft,
    this.complaintService,
    this.evidenceService,
    this.locationService,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  late final ComplaintService _complaintService;
  final _formKeyStep1 = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();

  late ComplaintDraft _draft;
  int _currentStep = 1; // 1: Information, 2: Evidence, 3: Location, 4: Review
  bool _isSubmitting = false;
  String? _categoryError;
  String? _locationError;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _complaintService = widget.complaintService ?? RepositoryLocator.complaintService;
    _draft = widget.initialDraft ?? ComplaintDraft.empty();
    if (_draft.title.isNotEmpty) {
      _titleController.text = _draft.title;
    }
    if (_draft.description.isNotEmpty) {
      _descriptionController.text = _draft.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _hasDraftData() {
    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _draft.category != null ||
        _draft.imageUrls.isNotEmpty ||
        _draft.location != null;
  }

  void _syncDraftInputs() {
    _draft = _draft.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );
  }

  Future<void> _handleBackNavigation() async {
    FocusScope.of(context).unfocus();

    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _submissionError = null;
      });
      _scrollToTop();
      return;
    }

    // Step 1: Check whether to show Discard confirmation dialog
    if (_hasDraftData()) {
      final shouldDiscard = await DiscardReportDialog.show(context);
      if (shouldDiscard && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _goToStep(int targetStep) {
    if (targetStep < _currentStep) {
      _syncDraftInputs();
      setState(() {
        _currentStep = targetStep;
      });
      _scrollToTop();
    }
  }

  void _handleStep1Next() {
    FocusScope.of(context).unfocus();

    setState(() {
      _categoryError = _draft.category == null ? (context.l10nOrNull?.pleaseSelectCategory ?? 'Please select an issue category.') : null;
    });

    if (!_formKeyStep1.currentState!.validate() || _draft.category == null) {
      return;
    }

    _syncDraftInputs();

    setState(() {
      _currentStep = 2;
    });
    _scrollToTop();
  }

  void _handleStep2Next() {
    setState(() {
      _currentStep = 3;
    });
    _scrollToTop();
  }

  void _handleStep3Next() {
    if (_draft.location == null) {
      setState(() {
        _locationError = context.l10nOrNull?.selectLocationError ?? 'Please select or detect the issue location.';
      });
      return;
    }

    setState(() {
      _locationError = null;
      _currentStep = 4;
    });
    _scrollToTop();
  }

  Future<void> _openMapPicker() async {
    final pickedLocation = await Navigator.push<CivicLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectLocationScreen(
          initialLocation: _draft.location,
          locationService: widget.locationService ?? RepositoryLocator.locationService,
        ),
      ),
    );

    if (pickedLocation != null && mounted) {
      setState(() {
        _draft = _draft.copyWith(location: pickedLocation);
        _locationError = null;
      });
    }
  }

  Future<void> _handleSubmitIssue() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final createdComplaint = await _complaintService.submitComplaint(_draft);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.complaintSubmitted,
        arguments: createdComplaint,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submissionError = _mapSubmissionError(e);
      });
    }
  }

  String _mapSubmissionError(dynamic error) {
    if (error is FirestorePermissionDeniedException ||
        (error is FirestoreException && error.code == 'permission-denied')) {
      return 'CivicFix could not submit this complaint because of an authorization problem. Please try again shortly.';
    }
    if (error is StorageException) {
      if (error.code == 'unauthenticated') {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.code == 'unauthorized' || error.code == 'permission-denied') {
        return 'Photo upload could not be completed.';
      }
      if (error.code == 'bucket-not-configured' ||
          error.code == 'bucket-not-found' ||
          error.code == 'no-default-bucket' ||
          error.code == 'object-not-found' ||
          error.code == 'not-found' ||
          error.code == 'unknown') {
        return 'Evidence storage service is temporarily unavailable. Please try again or submit without photos.';
      }
      return error.userMessage.isNotEmpty
          ? error.userMessage
          : 'Photo upload could not be completed.';
    }
    if (error is FirebaseException) {
      if (error.plugin == 'firebase_storage' || error.code.startsWith('storage/')) {
        return 'Evidence storage service is temporarily unavailable. Please try again or submit without photos.';
      }
      if (error.code == 'permission-denied') {
        return 'CivicFix could not submit this complaint because of an authorization problem. Please try again shortly.';
      }
      if (error.code == 'unauthenticated') {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.code == 'not-found' || error.code == 'bucket-not-found' || error.code == 'unknown') {
        return 'CivicFix cloud services are temporarily unavailable. Please try again shortly.';
      }
    }
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('storage') || errStr.contains('bucket') || errStr.contains('firebasestorage')) {
      return 'Evidence storage service is temporarily unavailable. Please try again or submit without photos.';
    }
    if (errStr.contains('unauthenticated') || errStr.contains('sign in') || errStr.contains('please sign in')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (errStr.contains('permission-denied') || errStr.contains('permission denied')) {
      return 'CivicFix could not submit this complaint because of an authorization problem. Please try again shortly.';
    }
    if (errStr.contains('fill in all required') || errStr.contains('validation')) {
      return 'Please fill in all required fields before submitting.';
    }
    return 'Unable to submit your complaint right now. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: CivicFixColors.background,
        appBar: CivicFixAppBar(
          title: context.l10nOrNull?.reportAnIssue ?? 'Report an Issue',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: context.l10nOrNull?.back ?? 'Back',
            onPressed: _handleBackNavigation,
          ),
        ),
        body: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 600,
            padding: CivicFixSpacing.pagePadding,
            child: Column(
              children: [
                // 1. Wizard Progress Indicator
                ReportProgressIndicator(
                  currentStep: _currentStep,
                  onStepTap: _goToStep,
                ),
                CivicFixSpacing.vSpaceMd,

                // 2. Step Content Body
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStep == 1) _buildStep1Information(),
                        if (_currentStep == 2) _buildStep2Evidence(),
                        if (_currentStep == 3) _buildStep3Location(),
                        if (_currentStep == 4) _buildStep4Review(),
                        CivicFixSpacing.vSpaceXxl,
                      ],
                    ),
                  ),
                ),

                // 3. Persistent Bottom Navigation Action Bar
                _buildBottomActionBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: ISSUE INFORMATION
  // ==========================================
  Widget _buildStep1Information() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10nOrNull?.issueInformationTitle ?? 'Issue Information',
            style: CivicFixTypography.h2,
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            context.l10nOrNull?.issueInformationSubtitle ?? 'Help us understand the problem so it can reach the right team.',
            style: CivicFixTypography.caption.copyWith(
              color: CivicFixColors.secondaryText,
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          // Title Field
          AuthTextField(
            label: context.l10nOrNull?.issueTitleLabel ?? 'Issue Title',
            hintText: context.l10nOrNull?.issueTitleHint ?? 'e.g. Broken street light near the park',
            controller: _titleController,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.l10nOrNull?.pleaseEnterIssueTitle ?? 'Please enter a title for the issue.';
              }
              if (value.trim().length < 5) {
                return context.l10nOrNull?.issueTitleMinLength ?? 'Title must be at least 5 characters.';
              }
              return null;
            },
          ),
          CivicFixSpacing.vSpaceLg,

          // Category Selector
          IssueCategorySelector(
            selectedCategory: _draft.category,
            errorMessage: _categoryError,
            onCategorySelected: (category) {
              setState(() {
                _draft = _draft.copyWith(category: category);
                _categoryError = null;
              });
            },
          ),
          CivicFixSpacing.vSpaceLg,

          // Description Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      context.l10nOrNull?.describeTheIssue ?? 'Describe the issue',
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CivicFixColors.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    ' *',
                    style: CivicFixTypography.bodySmallMedium.copyWith(
                      color: CivicFixColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceXs,
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                minLines: 3,
                style: CivicFixTypography.bodySmall,
                decoration: InputDecoration(
                  hintText: context.l10nOrNull?.describeIssueHint ?? 'Tell us what happened and where you noticed the problem.',
                  hintStyle: CivicFixTypography.bodySmall.copyWith(
                    color: CivicFixColors.disabledText,
                  ),
                  filled: true,
                  fillColor: CivicFixColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: CivicFixRadius.buttonRadius,
                    borderSide: const BorderSide(color: CivicFixColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: CivicFixRadius.buttonRadius,
                    borderSide: const BorderSide(color: CivicFixColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: CivicFixRadius.buttonRadius,
                    borderSide: const BorderSide(
                      color: CivicFixColors.secondary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: CivicFixRadius.buttonRadius,
                    borderSide: const BorderSide(color: CivicFixColors.error),
                  ),
                  contentPadding: const EdgeInsets.all(CivicFixSpacing.md),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10nOrNull?.pleaseDescribeIssue ?? 'Please describe the issue.';
                  }
                  if (value.trim().length < 10) {
                    return context.l10nOrNull?.describeIssueMinLength ?? 'Description must be at least 10 characters.';
                  }
                  return null;
                },
              ),
              CivicFixSpacing.vSpaceXs,
              Text(
                context.l10nOrNull?.describeIssueHelper ?? 'Include useful details such as what is damaged, how long it has been happening, or how it affects the area.',
                style: CivicFixTypography.caption.copyWith(
                  color: CivicFixColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // Hazard Switch Toggle
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.md,
              vertical: CivicFixSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: CivicFixColors.surface,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: CivicFixColors.alertDark,
                  size: 22,
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10nOrNull?.immediateSafetyHazardTitle ?? 'Immediate Safety Hazard',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.l10nOrNull?.safetyHazardSubtitle ?? 'Check if this issue poses an immediate risk to citizens or traffic',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _draft.isHazard,
                  activeTrackColor: CivicFixColors.alertDark,
                  onChanged: (val) {
                    setState(() {
                      _draft = _draft.copyWith(isHazard: val);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: EVIDENCE (PHOTOS)
  // ==========================================
  Widget _buildStep2Evidence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10nOrNull?.addEvidenceTitle ?? 'Add Evidence',
          style: CivicFixTypography.h2,
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          context.l10nOrNull?.addEvidenceSubtitle ?? 'A photo can help the responsible team understand the issue.',
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        CivicFixSpacing.vSpaceLg,

        EvidencePicker(
          images: _draft.imageUrls,
          evidenceItems: _draft.evidence,
          evidenceService: widget.evidenceService ?? RepositoryLocator.evidenceService,
          onImagesChanged: (updatedImages) {
            setState(() {
              _draft = _draft.copyWith(imageUrls: updatedImages);
            });
          },
          onEvidenceItemsChanged: (updatedEvidence) {
            setState(() {
              _draft = _draft.copyWith(evidence: updatedEvidence);
            });
          },
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: LOCATION
  // ==========================================
  Widget _buildStep3Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10nOrNull?.whereIsTheIssue ?? 'Where is the issue?',
          style: CivicFixTypography.h2,
        ),
        CivicFixSpacing.vSpaceXs,
        Text(
          context.l10nOrNull?.addLocationSubtitle ?? 'Add the location so the responsible team can find it.',
          style: CivicFixTypography.caption.copyWith(
            color: CivicFixColors.secondaryText,
          ),
        ),
        CivicFixSpacing.vSpaceLg,

        LocationSelectionCard(
          selectedLocation: _draft.location,
          errorMessage: _locationError,
          locationService: widget.locationService ?? RepositoryLocator.locationService,
          onOpenMapPicker: _openMapPicker,
          onLocationSelected: (loc) {
            setState(() {
              _draft = _draft.copyWith(location: loc);
              _locationError = null;
            });
          },
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: REVIEW & SUBMISSION
  // ==========================================
  Widget _buildStep4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComplaintReviewCard(
          draft: _draft,
          onEditStep: (stepNumber) {
            setState(() {
              _currentStep = stepNumber;
              _submissionError = null;
            });
            _scrollToTop();
          },
        ),

        // Submission error banner
        if (_submissionError != null) ...[
          CivicFixSpacing.vSpaceMd,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: CivicFixColors.statusRejectedBg,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(color: CivicFixColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: CivicFixColors.error,
                  size: 20,
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Text(
                    _submissionError!,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: CivicFixColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.only(top: CivicFixSpacing.md),
      decoration: const BoxDecoration(
        color: CivicFixColors.background,
        border: Border(
          top: BorderSide(color: CivicFixColors.border),
        ),
      ),
      child: Row(
        children: [
          // Back button on steps 2, 3, 4
          if (_currentStep > 1) ...[
            Expanded(
              flex: 1,
              child: CivicFixOutlinedButton(
                text: context.l10nOrNull?.back ?? 'Back',
                onPressed: _isSubmitting ? null : _handleBackNavigation,
              ),
            ),
            CivicFixSpacing.hSpaceMd,
          ],

          // Next / Submit Action button
          Expanded(
            flex: 2,
            child: _buildPrimaryActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton() {
    switch (_currentStep) {
      case 1:
        return CivicFixButton(
          text: context.l10nOrNull?.nextAddEvidence ?? 'Next: Add Evidence',
          icon: Icons.arrow_forward_rounded,
          onPressed: _handleStep1Next,
        );

      case 2:
        return CivicFixButton(
          text: _draft.imageUrls.isEmpty
              ? (context.l10nOrNull?.skipAndContinue ?? 'Skip & Continue')
              : (context.l10nOrNull?.nextLocation ?? 'Next: Location'),
          icon: Icons.arrow_forward_rounded,
          onPressed: _handleStep2Next,
        );

      case 3:
        return CivicFixButton(
          text: context.l10nOrNull?.nextReview ?? 'Next: Review',
          icon: Icons.arrow_forward_rounded,
          onPressed: _handleStep3Next,
        );

      case 4:
      default:
        return CivicFixButton(
          text: context.l10nOrNull?.submitIssue ?? 'Submit Issue',
          icon: Icons.send_rounded,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmitIssue,
        );
    }
  }
}
