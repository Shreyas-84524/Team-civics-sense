import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../../core/widgets/supabase_evidence_image.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Modal dialog for frontline crew to capture restoration evidence,
/// review before-and-after comparison in a read-only verification window,
/// and submit work completion.
class CrewEvidenceSubmissionDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final String crewId;
  final Future<void> Function({
    required String beforePhotoUrl,
    required String afterPhotoUrl,
    String? duringPhotoUrl,
    required String workRemarks,
  }) onSubmitCompletion;

  const CrewEvidenceSubmissionDialog({
    super.key,
    required this.complaint,
    required this.crewId,
    required this.onSubmitCompletion,
  });

  @override
  State<CrewEvidenceSubmissionDialog> createState() =>
      _CrewEvidenceSubmissionDialogState();
}

class _CrewEvidenceSubmissionDialogState
    extends State<CrewEvidenceSubmissionDialog> {
  final _workRemarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 0; // 0: Input Evidence & Remarks, 1: Before/After Verification Review

  late String _beforePhotoUrl;
  String _afterPhotoUrl = '';
  String? _duringPhotoUrl;

  bool _isProcessing = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Default initial before evidence from complaint if available
    if (widget.complaint.beforeWorkPhoto != null &&
        widget.complaint.beforeWorkPhoto!.isNotEmpty) {
      _beforePhotoUrl = widget.complaint.beforeWorkPhoto!;
    } else if (widget.complaint.imageUrls.isNotEmpty) {
      _beforePhotoUrl = widget.complaint.imageUrls.first;
    } else {
      _beforePhotoUrl = '';
    }

    if (widget.complaint.afterWorkPhoto != null &&
        widget.complaint.afterWorkPhoto!.isNotEmpty) {
      _afterPhotoUrl = widget.complaint.afterWorkPhoto!;
    }

    // Remarks field is completely empty by default
    _workRemarksController.text = '';
  }

  @override
  void dispose() {
    _workRemarksController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({
    required bool before,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final mime = photo.mimeType ?? 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        if (before) {
          _beforePhotoUrl = dataUri;
        } else {
          _afterPhotoUrl = dataUri;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  void _showImageSourceModal({required bool before}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF10B981)),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(before: before, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF10B981)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(before: before, source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToVerification() {
    if (_afterPhotoUrl.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Please submit or capture the restoration image (After Photo) before proceeding.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _step = 1;
    });
  }

  Future<void> _handleSubmit() async {
    if (_afterPhotoUrl.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide an After-restoration photo.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmitCompletion(
        beforePhotoUrl: _beforePhotoUrl.trim(),
        afterPhotoUrl: _afterPhotoUrl.trim(),
        duringPhotoUrl: _duringPhotoUrl?.trim(),
        workRemarks: _workRemarksController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 880),
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: _step == 0
                ? _buildEvidenceInputStep()
                : _buildVerificationReviewStep(),
          ),
        ),
      ),
    );
  }

  /// Step 0: Evidence Input & Remarks Form
  Widget _buildEvidenceInputStep() {
    final c = widget.complaint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUBMIT RESTORATION EVIDENCE',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Submit after-restoration image and remarks for verification',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceMd,
        const Divider(color: GovtThemeTokens.divider, height: 1),
        CivicFixSpacing.vSpaceMd,

        // Ticket Info Banner
        Container(
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GovtThemeTokens.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket #${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id} · ${c.category.name}',
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CivicFixSpacing.vSpaceLg,

        // 1. After-Restoration Photo Section
        Text(
          'IMAGE AFTER RESTORATION *',
          style: CivicFixTypography.captionMedium.copyWith(
            color: GovtThemeTokens.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        CivicFixSpacing.vSpaceSm,

        if (_afterPhotoUrl.isEmpty)
          GestureDetector(
            onTap: () => _showImageSourceModal(before: false),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: GovtThemeTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 32,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  CivicFixSpacing.vSpaceSm,
                  Text(
                    'Tap to capture or upload restoration photo',
                    style: CivicFixTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: GovtThemeTokens.textPrimary,
                    ),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded, size: 14),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _pickPhoto(
                            before: false, source: ImageSource.camera),
                      ),
                      CivicFixSpacing.hSpaceSm,
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_rounded, size: 14),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _pickPhoto(
                            before: false, source: ImageSource.gallery),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.sm),
            decoration: BoxDecoration(
              color: GovtThemeTokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    CivicFixSpacing.hSpaceXs,
                    Text(
                      'AFTER RESTORATION PHOTO',
                      style: CivicFixTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Change Photo'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        textStyle:
                            CivicFixTypography.caption.copyWith(fontSize: 11),
                      ),
                      onPressed: () => _showImageSourceModal(before: false),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceXs,
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SupabaseEvidenceImage(
                      imagePath: _afterPhotoUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
            ),
          ),

        CivicFixSpacing.vSpaceLg,

        // 2. Remarks Section (Completely empty and optional)
        Row(
          children: [
            Text(
              'REMARKS',
              style: CivicFixTypography.captionMedium.copyWith(
                color: GovtThemeTokens.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            CivicFixSpacing.hSpaceXs,
            Text(
              '(Optional)',
              style: CivicFixTypography.caption.copyWith(
                color: GovtThemeTokens.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceXs,
        TextFormField(
          controller: _workRemarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter any remarks about the restoration work (optional)...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        if (_errorMessage != null) ...[
          CivicFixSpacing.vSpaceMd,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.sm),
            decoration: BoxDecoration(
              color: GovtThemeTokens.alert.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: GovtThemeTokens.alert, size: 16),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.alert,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        CivicFixSpacing.vSpaceLg,
        const Divider(color: GovtThemeTokens.divider, height: 1),
        CivicFixSpacing.vSpaceMd,

        // Step 0 Dialog Actions
        Row(
          children: [
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Next: Review & Verify'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _proceedToVerification,
            ),
          ],
        ),
      ],
    );
  }

  /// Step 1: Before & After Verification Window (Non-editable comparison)
  Widget _buildVerificationReviewStep() {
    final remarksText = _workRemarksController.text.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            CivicFixSpacing.hSpaceMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BEFORE & AFTER VERIFICATION',
                    style: CivicFixTypography.h3.copyWith(
                      color: GovtThemeTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Review restoration photos and remarks before final submission',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
            ),
          ],
        ),
        CivicFixSpacing.vSpaceMd,
        const Divider(color: GovtThemeTokens.divider, height: 1),
        CivicFixSpacing.vSpaceMd,

        // Comparison Photos Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;

            final beforeCard = _buildReviewPhotoCard(
              title: 'BEFORE RESTORATION',
              url: _beforePhotoUrl,
              badgeColor: const Color(0xFFEF4444),
              fallbackMessage: 'No initial photo available',
            );

            final afterCard = _buildReviewPhotoCard(
              title: 'AFTER RESTORATION',
              url: _afterPhotoUrl,
              badgeColor: const Color(0xFF10B981),
              fallbackMessage: 'No restoration photo provided',
            );

            if (isNarrow) {
              return Column(
                children: [
                  beforeCard,
                  CivicFixSpacing.vSpaceMd,
                  afterCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: beforeCard),
                CivicFixSpacing.hSpaceMd,
                Expanded(child: afterCard),
              ],
            );
          },
        ),
        CivicFixSpacing.vSpaceLg,

        // Non-editable Remarks Display
        Text(
          'OFFICER REMARKS',
          style: CivicFixTypography.captionMedium.copyWith(
            color: GovtThemeTokens.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        CivicFixSpacing.vSpaceXs,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: GovtThemeTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GovtThemeTokens.borderLight),
          ),
          child: Text(
            remarksText.isNotEmpty ? remarksText : 'No remarks provided.',
            style: CivicFixTypography.bodySmall.copyWith(
              color: remarksText.isNotEmpty
                  ? GovtThemeTokens.textPrimary
                  : GovtThemeTokens.textMuted,
              fontStyle:
                  remarksText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),

        if (_errorMessage != null) ...[
          CivicFixSpacing.vSpaceMd,
          Container(
            padding: const EdgeInsets.all(CivicFixSpacing.sm),
            decoration: BoxDecoration(
              color: GovtThemeTokens.alert.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: GovtThemeTokens.alert, size: 16),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: GovtThemeTokens.alert,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        CivicFixSpacing.vSpaceLg,
        const Divider(color: GovtThemeTokens.divider, height: 1),
        CivicFixSpacing.vSpaceMd,

        // Step 1 Bottom Actions
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              onPressed:
                  _isProcessing ? null : () => setState(() => _step = 0),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isProcessing ? null : _handleSubmit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewPhotoCard({
    required String title,
    required String url,
    required Color badgeColor,
    required String fallbackMessage,
  }) {
    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.sm),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  title,
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GovtThemeTokens.borderLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: url.isNotEmpty
                  ? SupabaseEvidenceImage(
                      imagePath: url,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      placeholderBuilder: (ctx) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined,
                                size: 28, color: GovtThemeTokens.textMuted),
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              'Loading Photo...',
                              style: CivicFixTypography.caption.copyWith(
                                color: GovtThemeTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        fallbackMessage,
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
