import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/civic_department_model.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Modal dialog for Ward Department Lead to raise a Wrong-Department / Reassignment ticket.
/// Submits ticket to Ward Officer review without mutating complaint lifecycle or SLA clock.
class DepartmentLeadRoutingDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final String sourceDepartmentId;
  final List<CivicDepartment> allDepartments;
  final Future<void> Function({
    required String suggestedDepartmentId,
    required String reason,
    String? remarks,
  }) onTicketSubmitted;

  const DepartmentLeadRoutingDialog({
    super.key,
    required this.complaint,
    required this.sourceDepartmentId,
    required this.allDepartments,
    required this.onTicketSubmitted,
  });

  @override
  State<DepartmentLeadRoutingDialog> createState() =>
      _DepartmentLeadRoutingDialogState();
}

class _DepartmentLeadRoutingDialogState
    extends State<DepartmentLeadRoutingDialog> {
  final _reasonController = TextEditingController();
  final _remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedSuggestedDepartmentId;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-select another department
    final otherDepts = widget.allDepartments
        .where((d) =>
            d.departmentId.toLowerCase() !=
            widget.sourceDepartmentId.toLowerCase())
        .toList();
    if (otherDepts.isNotEmpty) {
      _selectedSuggestedDepartmentId = otherDepts.first.departmentId;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSuggestedDepartmentId == null) {
      setState(() => _errorMessage = 'Please select a suggested department.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onTicketSubmitted(
        suggestedDepartmentId: _selectedSuggestedDepartmentId!,
        reason: _reasonController.text.trim(),
        remarks: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
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
    final otherDepts = widget.allDepartments
        .where((d) =>
            d.departmentId.toLowerCase() !=
            widget.sourceDepartmentId.toLowerCase())
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 580,
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
                        color: const Color(0xFFF97316).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFFF97316),
                        size: 22,
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REQUEST DEPARTMENT REASSIGNMENT',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Raise Wrong Department ticket for Ward Officer review',
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

                // Grievance Summary Box
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
                      Text(
                        'Grievance: ${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id} · ${c.title}',
                        style: CivicFixTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GovtThemeTokens.textPrimary,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      Text(
                        'Current Assigned Dept: ${c.departmentName ?? widget.sourceDepartmentId}',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                      ),
                      Text(
                        'Category: ${c.category.name} · Reported: ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                        style: CivicFixTypography.caption.copyWith(
                          color: GovtThemeTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceLg,

                // Suggested Department
                Text(
                  'SUGGESTED CORRECT DEPARTMENT *',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                DropdownButtonFormField<String>(
                  initialValue: _selectedSuggestedDepartmentId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: (otherDepts.isNotEmpty ? otherDepts : widget.allDepartments)
                      .map((d) => DropdownMenuItem<String>(
                            value: d.departmentId,
                            child: Text(d.displayName),
                          ))
                      .toList(),
                  onChanged: _isProcessing
                      ? null
                      : (val) {
                          setState(() => _selectedSuggestedDepartmentId = val);
                        },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                CivicFixSpacing.vSpaceMd,

                // Reason Field
                Text(
                  'REASON FOR REASSIGNMENT *',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Issue involves water mains leakage under road, requires Water Works wing.',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please provide a reason for reassignment.'
                      : null,
                ),
                CivicFixSpacing.vSpaceMd,

                // Remarks / Evidence description
                Text(
                  'ADDITIONAL TECHNICAL NOTES (OPTIONAL)',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _remarksController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Inspected on-site by JE, no road surface defect observed.',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),

                // Info Alert
                CivicFixSpacing.vSpaceMd,
                Container(
                  padding: const EdgeInsets.all(CivicFixSpacing.sm),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.infoLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: GovtThemeTokens.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: GovtThemeTokens.info, size: 16),
                      CivicFixSpacing.hSpaceSm,
                      Expanded(
                        child: Text(
                          'SLA Preservation: The original timestamp and SLA clock remain active and immutable while this ticket awaits Ward Officer approval.',
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Submit Reassignment Ticket'),
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
}
