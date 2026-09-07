import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/widgets/status_badge.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_confirmation_dialog.dart';

/// Screen / Workflow for transitioning grievance status across the canonical lifecycle.
class GovtStatusUpdateScreen extends StatefulWidget {
  final ComplaintModel? complaint;
  final String? complaintId;

  const GovtStatusUpdateScreen({
    super.key,
    this.complaint,
    this.complaintId,
  });

  @override
  State<GovtStatusUpdateScreen> createState() => _GovtStatusUpdateScreenState();
}

class _GovtStatusUpdateScreenState extends State<GovtStatusUpdateScreen> {
  final GovtComplaintRepository _repository = MockGovtComplaintRepository();
  final _messageController = TextEditingController();
  final _internalNotesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ComplaintModel? _complaint;
  ComplaintStatus _targetStatus = ComplaintStatus.inProgress;
  bool _isLoading = false;
  bool _allowAdminOverride = false;

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      _complaint = widget.complaint;
      _initStatusForComplaint(_complaint!);
    } else if (widget.complaintId != null) {
      _loadComplaint(widget.complaintId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_complaint == null && widget.complaint == null && widget.complaintId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ComplaintModel) {
        setState(() {
          _complaint = args;
          _initStatusForComplaint(args);
        });
      } else if (args is String) {
        _loadComplaint(args);
      }
    }
  }

  void _initStatusForComplaint(ComplaintModel c) {
    _targetStatus = _getNextDefaultStatus(c.status);
    _messageController.text = _getDefaultMessageForStatus(_targetStatus);
  }

  Future<void> _loadComplaint(String id) async {
    setState(() => _isLoading = true);
    final c = await _repository.getComplaintById(id);
    if (mounted) {
      setState(() {
        _complaint = c;
        _isLoading = false;
        if (c != null) {
          _initStatusForComplaint(c);
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _internalNotesController.dispose();
    super.dispose();
  }

  ComplaintStatus _getNextDefaultStatus(ComplaintStatus current) {
    switch (current) {
      case ComplaintStatus.reported:
        return ComplaintStatus.verified;
      case ComplaintStatus.verified:
        return ComplaintStatus.assigned;
      case ComplaintStatus.assigned:
        return ComplaintStatus.inProgress;
      case ComplaintStatus.inProgress:
        return ComplaintStatus.resolved;
      case ComplaintStatus.resolved:
      case ComplaintStatus.rejected:
        return ComplaintStatus.resolved;
    }
  }

  List<ComplaintStatus> _getAllowedStatuses(ComplaintStatus current) {
    if (_allowAdminOverride) {
      return [
        ComplaintStatus.reported,
        ComplaintStatus.verified,
        ComplaintStatus.assigned,
        ComplaintStatus.inProgress,
        ComplaintStatus.resolved,
        ComplaintStatus.rejected,
      ];
    }

    switch (current) {
      case ComplaintStatus.reported:
        return [ComplaintStatus.verified, ComplaintStatus.rejected];
      case ComplaintStatus.verified:
        return [ComplaintStatus.assigned, ComplaintStatus.inProgress, ComplaintStatus.rejected];
      case ComplaintStatus.assigned:
        return [ComplaintStatus.inProgress, ComplaintStatus.resolved, ComplaintStatus.rejected];
      case ComplaintStatus.inProgress:
        return [ComplaintStatus.resolved, ComplaintStatus.rejected];
      case ComplaintStatus.resolved:
        return [ComplaintStatus.resolved];
      case ComplaintStatus.rejected:
        return [ComplaintStatus.reported, ComplaintStatus.verified];
    }
  }

  String _getDefaultMessageForStatus(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.reported:
        return 'Grievance recorded in the municipal registry.';
      case ComplaintStatus.verified:
        return 'Field inspection verified. Issue confirmed for departmental triage.';
      case ComplaintStatus.assigned:
        return 'Work order assigned to maintenance squad.';
      case ComplaintStatus.inProgress:
        return 'Repair and maintenance work actively underway on site.';
      case ComplaintStatus.resolved:
        return 'Civic issue has been fully resolved and verified by ward engineer.';
      case ComplaintStatus.rejected:
        return 'Complaint closed / marked unactionable after inspection.';
    }
  }

  void _promptStatusConfirmation() {
    if (!_formKey.currentState!.validate()) return;
    final c = _complaint;
    if (c == null) return;

    final isResolving = _targetStatus == ComplaintStatus.resolved;

    showDialog(
      context: context,
      builder: (ctx) => GovtConfirmationDialog(
        title: isResolving ? 'Confirm Grievance Resolution' : 'Confirm Status Update',
        message: isResolving
            ? 'Are you sure you want to mark grievance ${c.ticketNumber} as RESOLVED? This will record the completion timestamp and notify the citizen.'
            : 'Update status of ${c.ticketNumber} from ${c.status.label} to ${_targetStatus.label}?',
        confirmLabel: isResolving ? 'Confirm & Resolve' : 'Confirm Update',
        isDestructive: _targetStatus == ComplaintStatus.rejected,
        onConfirm: _executeStatusUpdate,
      ),
    );
  }

  Future<void> _executeStatusUpdate() async {
    final c = _complaint;
    if (c == null) return;

    setState(() => _isLoading = true);

    final combinedMessage = _messageController.text.trim();

    await _repository.updateStatus(
      complaintId: c.id,
      nextStatus: _targetStatus,
      updateMessage: combinedMessage,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated ${c.ticketNumber} to ${_targetStatus.label}.'),
        backgroundColor: GovtThemeTokens.secondary,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = _complaint;

    return Scaffold(
      backgroundColor: GovtThemeTokens.background,
      appBar: AppBar(
        title: Text(c != null ? 'Update Status: ${c.ticketNumber}' : 'Update Status'),
        backgroundColor: GovtThemeTokens.surface,
        foregroundColor: GovtThemeTokens.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 580,
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              decoration: BoxDecoration(
                color: GovtThemeTokens.surface,
                borderRadius: GovtThemeTokens.cardRadius,
                border: Border.all(color: GovtThemeTokens.border),
                boxShadow: GovtThemeTokens.cardShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.ticketNumber,
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    color: GovtThemeTokens.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  c.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CivicFixTypography.h3.copyWith(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          CivicFixSpacing.hSpaceSm,
                          StatusBadge(status: c.status),
                        ],
                      ),
                      CivicFixSpacing.vSpaceLg,
                      const Divider(color: GovtThemeTokens.border),
                      CivicFixSpacing.vSpaceMd,
                    ],

                    // Transition Status Selector
                    Text(
                      'Select Next Lifecycle Status',
                      style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    DropdownButtonFormField<ComplaintStatus>(
                      initialValue: _targetStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: GovtThemeTokens.surface,
                        border: OutlineInputBorder(
                          borderRadius: GovtThemeTokens.chipRadius,
                          borderSide: const BorderSide(color: GovtThemeTokens.border),
                        ),
                      ),
                      items: (c != null ? _getAllowedStatuses(c.status) : ComplaintStatus.values).map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            '${status.label.toUpperCase()} — ${_getStatusDescription(status)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CivicFixTypography.bodySmall,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _targetStatus = val;
                            _messageController.text = _getDefaultMessageForStatus(val);
                          });
                        }
                      },
                    ),
                    CivicFixSpacing.vSpaceMd,

                    // Resolution Banner (when resolving)
                    if (_targetStatus == ComplaintStatus.resolved) ...[
                      Container(
                        padding: const EdgeInsets.all(CivicFixSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GovtThemeTokens.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: GovtThemeTokens.secondary, size: 20),
                            CivicFixSpacing.hSpaceSm,
                            Expanded(
                              child: Text(
                                'Resolution requires an explanatory note confirming how the issue was fixed.',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: GovtThemeTokens.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CivicFixSpacing.vSpaceMd,
                    ],

                    // Public Citizen Update Message
                    Text(
                      'Official Status Notes & Citizen Update Message *',
                      style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      style: CivicFixTypography.bodySmall,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide an update note for this status change.';
                        }
                        if (_targetStatus == ComplaintStatus.resolved && val.trim().length < 5) {
                          return 'Resolution requires a descriptive message (at least 5 characters).';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter official progress notes to display on the citizen complaint tracker...',
                        filled: true,
                        fillColor: GovtThemeTokens.surface,
                        border: OutlineInputBorder(
                          borderRadius: GovtThemeTokens.chipRadius,
                          borderSide: const BorderSide(color: GovtThemeTokens.border),
                        ),
                      ),
                    ),
                    CivicFixSpacing.vSpaceMd,

                    // Optional Internal Remarks
                    Text(
                      'Internal Municipal Remarks (Optional)',
                      style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    TextFormField(
                      controller: _internalNotesController,
                      maxLines: 2,
                      style: CivicFixTypography.bodySmall,
                      decoration: InputDecoration(
                        hintText: 'Internal departmental notes, team codes, or contractor references...',
                        filled: true,
                        fillColor: GovtThemeTokens.surface,
                        border: OutlineInputBorder(
                          borderRadius: GovtThemeTokens.chipRadius,
                          borderSide: const BorderSide(color: GovtThemeTokens.border),
                        ),
                      ),
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Admin override toggle for edge cases
                    Row(
                      children: [
                        Checkbox(
                          value: _allowAdminOverride,
                          activeColor: GovtThemeTokens.primary,
                          onChanged: (val) {
                            setState(() {
                              _allowAdminOverride = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Administrative override (allow non-sequential transition for corrections)',
                            style: CivicFixTypography.caption.copyWith(
                              color: GovtThemeTokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Cancel'),
                        ),
                        CivicFixSpacing.hSpaceMd,
                        CivicFixButton(
                          text: _targetStatus == ComplaintStatus.resolved
                              ? 'Confirm & Resolve'
                              : 'Update Grievance Status',
                          width: 220,
                          isLoading: _isLoading,
                          onPressed: _promptStatusConfirmation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusDescription(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.reported:
        return 'Queued for review';
      case ComplaintStatus.verified:
        return 'Site verified & confirmed';
      case ComplaintStatus.assigned:
        return 'Crew assigned';
      case ComplaintStatus.inProgress:
        return 'Work actively underway';
      case ComplaintStatus.resolved:
        return 'Issue fixed & confirmed';
      case ComplaintStatus.rejected:
        return 'Closed / unactionable';
    }
  }
}
