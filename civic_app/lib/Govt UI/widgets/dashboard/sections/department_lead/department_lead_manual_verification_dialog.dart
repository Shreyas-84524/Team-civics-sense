import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/civic_department_model.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Modal dialog for Ward Department Lead to make manual department verification decisions
/// when automated Gemini AI verification is temporarily unavailable.
class DepartmentLeadManualVerificationDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final String leadId;
  final List<CivicDepartment> allDepartments;
  final Future<void> Function({
    required bool belongsToCurrentDepartment,
    String? targetDepartmentId,
    required String remarks,
  }) onSubmitDecision;

  const DepartmentLeadManualVerificationDialog({
    super.key,
    required this.complaint,
    required this.leadId,
    required this.allDepartments,
    required this.onSubmitDecision,
  });

  @override
  State<DepartmentLeadManualVerificationDialog> createState() =>
      _DepartmentLeadManualVerificationDialogState();
}

class _DepartmentLeadManualVerificationDialogState
    extends State<DepartmentLeadManualVerificationDialog> {
  final _remarksController = TextEditingController();
  bool _belongsToCurrentDepartment = true;
  String? _selectedDepartmentId;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _remarksController.text = 'Department verified manually via AI fallback protocol.';
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final remarks = _remarksController.text.trim();
    if (remarks.isEmpty) {
      setState(() => _errorMessage = 'Please provide remarks / rationale for this decision.');
      return;
    }

    if (!_belongsToCurrentDepartment &&
        (_selectedDepartmentId == null || _selectedDepartmentId!.trim().isEmpty)) {
      setState(() => _errorMessage = 'Please select a target BMC department.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmitDecision(
        belongsToCurrentDepartment: _belongsToCurrentDepartment,
        targetDepartmentId: !_belongsToCurrentDepartment ? _selectedDepartmentId : null,
        remarks: remarks,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDeptName = widget.complaint.initialReviewDepartmentName ??
        widget.complaint.departmentName ??
        'Assigned Department';

    final availableTargetDepts = widget.allDepartments.where((d) {
      final currentId = widget.complaint.assignedDepartmentId ??
          widget.complaint.initialReviewDepartmentId;
      return d.departmentId != currentId;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: GovtThemeTokens.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 850),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFDE68A)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'AI Verification Fallback',
                              style: CivicFixTypography.h3.copyWith(
                                color: const Color(0xFF92400E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Text(
                                'AI Offline',
                                style: CivicFixTypography.caption.copyWith(
                                  color: const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Manual Department Triage for Ticket #${widget.complaint.ticketNumber}',
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: GovtThemeTokens.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Outage Diagnostics Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GovtThemeTokens.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                          CivicFixSpacing.hSpaceSm,
                          Expanded(
                            child: Text(
                              'Gemini automated verification encountered temporary infrastructure unavailability (${widget.complaint.lastAiFailureCode ?? "TRANSIENT_FAILURE"}). '
                              'SLA started at ${widget.complaint.slaStartedAt.toLocal().toString().substring(0, 16)} and remains unbroken.',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: GovtThemeTokens.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    CivicFixSpacing.vSpaceMd,

                    // Complaint Details Summary
                    Text(
                      'COMPLAINT DETAILS',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GovtThemeTokens.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.complaint.title,
                                  style: CivicFixTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: GovtThemeTokens.textPrimary,
                                  ),
                                ),
                              ),
                              CivicFixSpacing.hSpaceSm,
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: GovtThemeTokens.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Ward ${widget.complaint.wardId ?? "N/A"}',
                                  style: CivicFixTypography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          CivicFixSpacing.vSpaceSm,
                          Text(
                            widget.complaint.description,
                            style: CivicFixTypography.bodyMedium.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                          ),
                          CivicFixSpacing.vSpaceSm,
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: GovtThemeTokens.textMuted),
                              CivicFixSpacing.hSpaceXs,
                              Expanded(
                                child: Text(
                                  widget.complaint.location.address,
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    color: GovtThemeTokens.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Decision Radio Group
                    Text(
                      'DEPARTMENT JURISDICTION DECISION',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    CivicFixSpacing.vSpaceSm,

                    RadioGroup<bool>(
                      groupValue: _belongsToCurrentDepartment,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _belongsToCurrentDepartment = val;
                            if (val) {
                              _remarksController.text =
                                  'Confirmed as $currentDeptName. Auto-routed to least loaded Junior Engineer.';
                            } else {
                              _remarksController.text =
                                  'Misrouted to $currentDeptName. Transferred to correct department.';
                            }
                          });
                        }
                      },
                      child: Column(
                        children: [
                          // Option 1: Belongs to Current Department
                          InkWell(
                            onTap: () {
                              setState(() {
                                _belongsToCurrentDepartment = true;
                                _remarksController.text =
                                    'Confirmed as $currentDeptName. Auto-routed to least loaded Junior Engineer.';
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _belongsToCurrentDepartment
                                    ? const Color(0xFFF0FDF4)
                                    : GovtThemeTokens.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _belongsToCurrentDepartment
                                      ? const Color(0xFF22C55E)
                                      : GovtThemeTokens.border,
                                  width: _belongsToCurrentDepartment ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Radio<bool>(
                                    value: true,
                                    activeColor: Color(0xFF16A34A),
                                  ),
                                  CivicFixSpacing.hSpaceSm,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Complaint belongs to $currentDeptName',
                                          style: CivicFixTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: _belongsToCurrentDepartment
                                                ? const Color(0xFF15803D)
                                                : GovtThemeTokens.textPrimary,
                                          ),
                                        ),
                                        CivicFixSpacing.vSpaceXs,
                                        Text(
                                          'Will be immediately confirmed and auto-routed to the least-loaded Junior Engineer under your supervision in this ward.',
                                          style: CivicFixTypography.captionMedium.copyWith(
                                            color: GovtThemeTokens.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          CivicFixSpacing.vSpaceSm,

                          // Option 2: Belongs to Another Department
                          InkWell(
                            onTap: () {
                              setState(() {
                                _belongsToCurrentDepartment = false;
                                _remarksController.text =
                                    'Misrouted to $currentDeptName. Transferred to correct department.';
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: !_belongsToCurrentDepartment
                                    ? const Color(0xFFEFF6FF)
                                    : GovtThemeTokens.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !_belongsToCurrentDepartment
                                      ? const Color(0xFF3B82F6)
                                      : GovtThemeTokens.border,
                                  width: !_belongsToCurrentDepartment ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Radio<bool>(
                                        value: false,
                                        activeColor: Color(0xFF2563EB),
                                      ),
                                      CivicFixSpacing.hSpaceSm,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Transfer to Another BMC Department',
                                              style: CivicFixTypography.bodyLarge.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: !_belongsToCurrentDepartment
                                                    ? const Color(0xFF1D4ED8)
                                                    : GovtThemeTokens.textPrimary,
                                              ),
                                            ),
                                            CivicFixSpacing.vSpaceXs,
                                            Text(
                                              'Will be re-assigned to the selected canonical BMC department and auto-routed to their Junior Engineer in this ward.',
                                              style: CivicFixTypography.captionMedium.copyWith(
                                                color: GovtThemeTokens.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Department dropdown if transfer selected
                                  if (!_belongsToCurrentDepartment) ...[
                                    CivicFixSpacing.vSpaceMd,
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedDepartmentId,
                                      hint: const Text('Select Canonical BMC Department'),
                                      decoration: InputDecoration(
                                        labelText: 'Target Department *',
                                        filled: true,
                                        fillColor: GovtThemeTokens.surface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      items: availableTargetDepts.map((d) {
                                        return DropdownMenuItem<String>(
                                          value: d.departmentId,
                                          child: Text(d.displayName),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedDepartmentId = val;
                                          final dept = widget.allDepartments
                                              .firstWhere((d) => d.departmentId == val, orElse: () => availableTargetDepts.first);
                                          _remarksController.text =
                                              'Transferred to ${dept.displayName}. Not under $currentDeptName jurisdiction.';
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    CivicFixSpacing.vSpaceLg,

                    // Remarks / Decision Rationale
                    Text(
                      'DECISION REMARKS / RATIONALE *',
                      style: CivicFixTypography.caption.copyWith(
                        color: GovtThemeTokens.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    CivicFixSpacing.vSpaceSm,
                    TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter specific rationale for this departmental verification decision...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: GovtThemeTokens.surfaceMuted,
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      CivicFixSpacing.vSpaceMd,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                            CivicFixSpacing.hSpaceSm,
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: GovtThemeTokens.surfaceMuted,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: GovtThemeTokens.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        color: GovtThemeTokens.textMuted,
                      ),
                    ),
                  ),
                  CivicFixSpacing.hSpaceMd,
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleSubmit,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _belongsToCurrentDepartment
                                ? Icons.check_circle_outline
                                : Icons.swap_horiz,
                            size: 18,
                          ),
                    label: Text(
                      _isProcessing
                          ? 'Processing...'
                          : (_belongsToCurrentDepartment
                              ? 'Confirm & Auto-Route JE'
                              : 'Transfer Department'),
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _belongsToCurrentDepartment
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
