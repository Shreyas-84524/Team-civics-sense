import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../services/government_department_lead_dashboard_service.dart';
import '../../../../theme/govt_theme_tokens.dart';

/// Modal dialog for assigning or reassigning a complaint to one of the
/// Ward Department Lead's 5 authorized ground crew technicians.
class DepartmentLeadAssignDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final List<CrewWorkloadItem> crewWorkloads;
  final String leadId;
  final Future<void> Function(String crewMemberId) onAssignConfirmed;

  const DepartmentLeadAssignDialog({
    super.key,
    required this.complaint,
    required this.crewWorkloads,
    required this.leadId,
    required this.onAssignConfirmed,
  });

  @override
  State<DepartmentLeadAssignDialog> createState() =>
      _DepartmentLeadAssignDialogState();
}

class _DepartmentLeadAssignDialogState
    extends State<DepartmentLeadAssignDialog> {
  String? _selectedCrewId;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.complaint.assignedCrewMemberId != null &&
        widget.complaint.assignedCrewMemberId!.isNotEmpty) {
      _selectedCrewId = widget.complaint.assignedCrewMemberId;
    } else if (widget.crewWorkloads.isNotEmpty) {
      // Pick first available crew member
      _selectedCrewId = widget.crewWorkloads.first.employeeId;
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedCrewId == null) {
      setState(() => _errorMessage = 'Please select a crew technician to assign.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        debugPrint(
          '[DepartmentLeadAssignDialog] Confirming assignment: '
          'complaintId=${widget.complaint.id}, serverId=${widget.complaint.serverId}, '
          'ticketNumber=${widget.complaint.ticketNumber}, crewMemberId=$_selectedCrewId',
        );
      }
      await widget.onAssignConfirmed(_selectedCrewId!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DepartmentLeadAssignDialog] Assignment failed: $e');
      }
      if (mounted) {
        final errorString = e.toString();
        final userFriendlyMsg = errorString.contains('Complaint not found')
            ? 'Unable to load this complaint for assignment. Please refresh and try again.'
            : errorString
                .replaceFirst('Exception: ', '')
                .replaceFirst('ArgumentError: ', '')
                .replaceFirst('StateError: ', '');
        setState(() {
          _errorMessage = userFriendlyMsg;
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
        width: 620,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(CivicFixSpacing.lg),
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
                    color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: GovtThemeTokens.primary,
                    size: 22,
                  ),
                ),
                CivicFixSpacing.hSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGN FIELD CREW',
                        style: CivicFixTypography.h3.copyWith(
                          color: GovtThemeTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Grievance ${c.ticketNumber.isNotEmpty ? c.ticketNumber : c.id} · ${c.title}',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: GovtThemeTokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

            // Complaint Context Summary Box
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
                          'Category: ${c.category.name}',
                          style: CivicFixTypography.captionMedium.copyWith(
                            color: GovtThemeTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Location: ${c.location.address}',
                          style: CivicFixTypography.caption.copyWith(
                            color: GovtThemeTokens.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: c.priority.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CivicFixSpacing.vSpaceMd,

            Text(
              'AUTHORIZED UNIT CREW TECHNICIANS (${widget.crewWorkloads.length})',
              style: CivicFixTypography.captionMedium.copyWith(
                color: GovtThemeTokens.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            CivicFixSpacing.vSpaceSm,

            // Crew List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.crewWorkloads.length,
                separatorBuilder: (ctx, i) => CivicFixSpacing.vSpaceSm,
                itemBuilder: (ctx, i) {
                  final item = widget.crewWorkloads[i];
                  final isSelected = _selectedCrewId == item.employeeId ||
                      _selectedCrewId == item.id;

                  return InkWell(
                    onTap: _isProcessing
                        ? null
                        : () {
                            setState(() {
                              _selectedCrewId = item.employeeId;
                              _errorMessage = null;
                            });
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(CivicFixSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GovtThemeTokens.primary.withValues(alpha: 0.05)
                            : GovtThemeTokens.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? GovtThemeTokens.primary
                              : GovtThemeTokens.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? GovtThemeTokens.primary
                                    : GovtThemeTokens.textMuted,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: GovtThemeTokens.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          CivicFixSpacing.hSpaceSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.fullName,
                                      style:
                                          CivicFixTypography.bodySmall.copyWith(
                                        color: GovtThemeTokens.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    CivicFixSpacing.hSpaceSm,
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.availabilityColor
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.availabilityStatus,
                                        style: CivicFixTypography.caption
                                            .copyWith(
                                          color: item.availabilityColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                CivicFixSpacing.vSpaceXs,
                                Text(
                                  'ID: ${item.employeeId} · ${item.designation}',
                                  style: CivicFixTypography.caption.copyWith(
                                    color: GovtThemeTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.totalActiveJobs} Active Jobs',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: GovtThemeTokens.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'In Progress: ${item.inProgress} · Done: ${item.completedToday}',
                                style: CivicFixTypography.caption.copyWith(
                                  color: GovtThemeTokens.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                  onPressed: _isProcessing ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovtThemeTokens.primary,
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
                      : const Text('Confirm Crew Assignment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
