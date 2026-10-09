import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../../core/widgets/supabase_evidence_image.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Modal dialog for reviewing work completed by field crew.
/// Allows the Ward Department Lead to:
/// 1. Inspect original grievance evidence vs completed site evidence
/// 2. Finalize verification & administrative closure (VERIFY & RESOLVE)
/// 3. Return work with specific rejection reasons (RETURN FOR REWORK)
class DepartmentLeadVerificationDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final String leadId;
  final Future<void> Function({
    required String notes,
    bool returnForRework,
    String? reworkReason,
  }) onVerificationCompleted;

  const DepartmentLeadVerificationDialog({
    super.key,
    required this.complaint,
    required this.leadId,
    required this.onVerificationCompleted,
  });

  @override
  State<DepartmentLeadVerificationDialog> createState() =>
      _DepartmentLeadVerificationDialogState();
}

class _DepartmentLeadVerificationDialogState
    extends State<DepartmentLeadVerificationDialog> {
  final _verificationNotesController = TextEditingController(
      text: 'Field work inspected on site and certified satisfactorily completed.');
  final _reworkReasonController = TextEditingController();

  bool _isProcessing = false;
  bool _showReworkInput = false;
  String? _errorMessage;

  @override
  void dispose() {
    _verificationNotesController.dispose();
    _reworkReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyAndResolve() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onVerificationCompleted(
        notes: _verificationNotesController.text.trim(),
        returnForRework: false,
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

  Future<void> _handleReturnForRework() async {
    if (_reworkReasonController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please specify a rework reason.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onVerificationCompleted(
        notes: '',
        returnForRework: true,
        reworkReason: _reworkReasonController.text.trim(),
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
        width: 760,
        constraints: const BoxConstraints(maxHeight: 840),
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
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
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: Color(0xFF8B5CF6),
                      size: 22,
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETION WORK VERIFICATION',
                          style: CivicFixTypography.h3.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Review ground crew completion evidence and certify grievance resolution',
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

              // Grievance Information Box
              Container(
                padding: const EdgeInsets.all(CivicFixSpacing.md),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GovtThemeTokens.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Ticket #${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id}',
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.priority.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: c.priority.color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            c.priority.label,
                            style: CivicFixTypography.caption.copyWith(
                              color: c.priority.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      c.title,
                      style: CivicFixTypography.bodyMedium.copyWith(
                        color: GovtThemeTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      c.description,
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textSecondary,
                      ),
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: GovtThemeTokens.textMuted),
                        CivicFixSpacing.hSpaceXs,
                        Expanded(
                          child: Text(
                            '${c.location.address} (Ward ${c.location.ward})',
                            style: CivicFixTypography.caption.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CivicFixSpacing.hSpaceMd,
                        const Icon(Icons.engineering_outlined,
                            size: 14, color: GovtThemeTokens.textMuted),
                        CivicFixSpacing.hSpaceXs,
                        Text(
                          'Crew: ${c.assignedTo ?? c.assignedCrewMemberId ?? "Field Squad"}',
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,

              // Before & After Evidence Comparer
              Text(
                'WORK COMPLETION EVIDENCE AUDIT',
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
                  // Before Evidence
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(CivicFixSpacing.md),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              CivicFixSpacing.hSpaceXs,
                              Text(
                                'ORIGINAL CITIZEN EVIDENCE',
                                style: CivicFixTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: GovtThemeTokens.textPrimary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          CivicFixSpacing.vSpaceSm,
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: GovtThemeTokens.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: GovtThemeTokens.borderLight),
                            ),
                            child: (c.imageUrls.isNotEmpty || (c.beforeWorkPhoto != null && c.beforeWorkPhoto!.isNotEmpty))
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SupabaseEvidenceImage(
                                      imagePath: c.beforeWorkPhoto ?? c.imageUrls.first,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : _buildPlaceholder('Reported Issue Photo'),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Reported: ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year} ${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                            style: CivicFixTypography.caption.copyWith(
                              color: GovtThemeTokens.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,

                  // After Evidence
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(CivicFixSpacing.md),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              CivicFixSpacing.hSpaceXs,
                              Text(
                                'AFTER WORK COMPLETION PHOTO',
                                style: CivicFixTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: GovtThemeTokens.textPrimary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          CivicFixSpacing.vSpaceSm,
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                     .withValues(alpha: 0.3),
                              ),
                            ),
                            child: (c.afterWorkPhoto != null && c.afterWorkPhoto!.isNotEmpty) || c.imageUrls.length > 1
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SupabaseEvidenceImage(
                                      imagePath: c.afterWorkPhoto ?? (c.imageUrls.length > 1 ? c.imageUrls[1] : ''),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : _buildResolvedPlaceholder(),
                          ),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Completed: ${c.updatedAt.day}/${c.updatedAt.month}/${c.updatedAt.year} ${c.updatedAt.hour}:${c.updatedAt.minute.toString().padLeft(2, '0')}',
                            style: CivicFixTypography.caption.copyWith(
                              color: GovtThemeTokens.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              CivicFixSpacing.vSpaceMd,

              // Field Crew Remarks
              if (c.officerNotes != null && c.officerNotes!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GovtThemeTokens.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment_outlined,
                          size: 16, color: GovtThemeTokens.textSecondary),
                      CivicFixSpacing.hSpaceSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FIELD CREW REMARKS',
                              style: CivicFixTypography.caption.copyWith(
                                color: GovtThemeTokens.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              c.officerNotes!,
                              style: CivicFixTypography.bodySmall.copyWith(
                                color: GovtThemeTokens.textPrimary,
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

              // Lead Verification Notes / Decision
              if (!_showReworkInput) ...[
                Text(
                  'LEAD VERIFICATION CERTIFICATION NOTES',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _verificationNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter closure remarks for audit trail.',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.replay_rounded,
                              color: Color(0xFFEF4444), size: 18),
                          CivicFixSpacing.hSpaceSm,
                          Text(
                            'RETURN WORK FOR REWORK',
                            style: CivicFixTypography.bodySmall.copyWith(
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                setState(() => _showReworkInput = false),
                            child: const Text('Back to Resolution'),
                          ),
                        ],
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'REWORK INSTRUCTION / DEFECT REASON *',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      TextFormField(
                        controller: _reworkReasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Surface patch uneven, clear debris from roadside before certifying.',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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

              // Actions
              Row(
                children: [
                  if (!_showReworkInput) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.replay_rounded,
                          size: 16, color: Color(0xFFEF4444)),
                      label: const Text('Return for Rework'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => setState(() => _showReworkInput = true),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  if (!_showReworkInput)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified_rounded, size: 18),
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
                          : const Text('Verify & Resolve Grievance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isProcessing ? null : _handleVerifyAndResolve,
                    )
                  else
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
                          : const Text('Confirm Rework Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isProcessing ? null : _handleReturnForRework,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined,
              size: 32, color: GovtThemeTokens.textMuted),
          CivicFixSpacing.vSpaceXs,
          Text(
            label,
            style: CivicFixTypography.caption.copyWith(
              color: GovtThemeTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 32, color: Color(0xFF10B981)),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Site Rectification Certified',
            style: CivicFixTypography.captionMedium.copyWith(
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
