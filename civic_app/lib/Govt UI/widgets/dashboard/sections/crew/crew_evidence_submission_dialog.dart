import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Modal dialog for frontline crew to capture and submit completion evidence.
/// Requires:
/// - Before-work photo evidence
/// - After-work photo evidence
/// - Detailed work remarks ("Work Performed")
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

  // In a real device, these URLs are captured from Camera/Gallery.
  // We provide sensible defaults based on complaint category with options to edit/re-upload.
  late String _beforePhotoUrl;
  late String _afterPhotoUrl;
  String? _duringPhotoUrl;

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default initial evidence URLs
    if (widget.complaint.imageUrls.isNotEmpty) {
      _beforePhotoUrl = widget.complaint.imageUrls.first;
    } else {
      _beforePhotoUrl =
          'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=600';
    }

    if (widget.complaint.imageUrls.length > 1) {
      _afterPhotoUrl = widget.complaint.imageUrls[1];
    } else {
      _afterPhotoUrl =
          'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=600';
    }

    _workRemarksController.text =
        'Site rectified according to municipal standard operating procedures. Debris cleared and road restored.';
  }

  @override
  void dispose() {
    _workRemarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_beforePhotoUrl.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide a Before-work photo.');
      return;
    }

    if (_afterPhotoUrl.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide an After-work photo.');
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
    final c = widget.complaint;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 840),
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
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
                            'SUBMIT WORK COMPLETION',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Attach before & after evidence for Ward Department Lead review',
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
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

                // 1. Evidence Photos Section
                Text(
                  'PHOTOGRAPHIC EVIDENCE *',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                CivicFixSpacing.vSpaceSm,

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Before Photo
                    Expanded(
                      child: _buildPhotoBox(
                        title: '1. BEFORE PHOTO *',
                        url: _beforePhotoUrl,
                        color: const Color(0xFFEF4444),
                        onRetake: () {
                          setState(() {
                            _beforePhotoUrl =
                                'https://images.unsplash.com/photo-1584463623578-30112f5a0459?w=600';
                          });
                        },
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,

                    // After Photo
                    Expanded(
                      child: _buildPhotoBox(
                        title: '2. AFTER PHOTO *',
                        url: _afterPhotoUrl,
                        color: const Color(0xFF10B981),
                        onRetake: () {
                          setState(() {
                            _afterPhotoUrl =
                                'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=600';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceLg,

                // 2. Work Performed Remarks
                Text(
                  'WORK PERFORMED / REMARKS *',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _workRemarksController,
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please describe the repair/work executed on site.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Filled 2x1m pothole using hot-mix asphalt and compacted with roller.',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

                // Dialog Actions
                Row(
                  children: [
                    TextButton(
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 18),
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
                          : const Text('Submit for Verification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isProcessing ? null : _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoBox({
    required String title,
    required String url,
    required Color color,
    required VoidCallback onRetake,
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
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              CivicFixSpacing.hSpaceXs,
              Expanded(
                child: Text(
                  title,
                  style: CivicFixTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: GovtThemeTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GovtThemeTokens.borderLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 28, color: GovtThemeTokens.textMuted),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Photo Captured',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Change Photo'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: CivicFixTypography.caption.copyWith(fontSize: 11),
                ),
                onPressed: _isProcessing ? null : onRetake,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
