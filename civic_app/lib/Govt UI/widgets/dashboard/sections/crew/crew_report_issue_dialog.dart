import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Modal dialog for reporting on-site field issues / operational blockages.
class CrewReportIssueDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final String crewId;
  final Future<void> Function({
    required String reasonCategory,
    required String details,
  }) onReportIssue;

  const CrewReportIssueDialog({
    super.key,
    required this.complaint,
    required this.crewId,
    required this.onReportIssue,
  });

  @override
  State<CrewReportIssueDialog> createState() => _CrewReportIssueDialogState();
}

class _CrewReportIssueDialogState extends State<CrewReportIssueDialog> {
  final _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedReason = 'Site Inaccessible / Road Blocked';
  bool _isProcessing = false;
  String? _errorMessage;

  final List<String> _reasons = const [
    'Site Inaccessible / Road Blocked',
    'Specialized Equipment Required',
    'Additional Squad Crew Required',
    'Severe Safety Hazard on Site',
    'Wrong Physical Location Reported',
    'Work Blocked by External Condition / Weather',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await widget.onReportIssue(
        reasonCategory: _selectedReason,
        details: _detailsController.text.trim(),
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
        width: 560,
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
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REPORT ON-SITE ISSUE',
                            style: CivicFixTypography.h3.copyWith(
                              color: GovtThemeTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Log field blockage or operational obstacle to supervisor',
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

                // Ticket Info
                Text(
                  'Ticket #${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id} — ${c.title}',
                  style: CivicFixTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GovtThemeTokens.textPrimary,
                  ),
                ),
                CivicFixSpacing.vSpaceLg,

                // Reason Category Dropdown
                Text(
                  'OBSTACLE CATEGORY *',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _reasons.map((r) {
                    return DropdownMenuItem<String>(
                      value: r,
                      child: Text(r, style: CivicFixTypography.bodySmall),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedReason = val);
                    }
                  },
                ),
                CivicFixSpacing.vSpaceLg,

                // Detailed Description
                Text(
                  'FIELD OBSERVATION & REMARKS *',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: GovtThemeTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _detailsController,
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide on-site details regarding the blockage.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Heavy commercial vehicle parked over trench; need traffic police assistance or heavy excavator.',
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

                // Actions
                Row(
                  children: [
                    TextButton(
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.report_problem_rounded, size: 18),
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
                          : const Text('Submit Field Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isProcessing ? null : _handleConfirm,
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
