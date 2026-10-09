import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/models/complaint_model.dart';
import '../../../../models/govt_user_model.dart';

/// Lets the assigned Junior Engineer choose the separate officer who will do
/// the physical work. The service validates the same ward and department again.
class CrewFieldOfficerAssignmentDialog extends StatefulWidget {
  final ComplaintModel complaint;
  final List<GovtUserModel> officers;
  final Future<void> Function(String officerId, String? notes) onAssign;

  const CrewFieldOfficerAssignmentDialog({
    super.key,
    required this.complaint,
    required this.officers,
    required this.onAssign,
  });

  @override
  State<CrewFieldOfficerAssignmentDialog> createState() => _CrewFieldOfficerAssignmentDialogState();
}

class _CrewFieldOfficerAssignmentDialogState extends State<CrewFieldOfficerAssignmentDialog> {
  String? _selectedId;
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.complaint.assignedFieldOfficerId ??
        (widget.officers.isNotEmpty ? widget.officers.first.employeeId : null);
  }

  @override
  void dispose() { _notes.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_selectedId == null) { setState(() => _error = 'Select an execution officer.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      if (kDebugMode) {
        debugPrint(
          '[CrewFieldOfficerAssignmentDialog] Submitting assignment: '
          'complaintId=${widget.complaint.id}, serverId=${widget.complaint.serverId}, '
          'ticketNumber=${widget.complaint.ticketNumber}, officerId=$_selectedId',
        );
      }
      await widget.onAssign(_selectedId!, _notes.text.trim().isEmpty ? null : _notes.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrewFieldOfficerAssignmentDialog] Assignment failed: $e');
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
          _saving = false;
          _error = userFriendlyMsg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Execution Officer'),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose a field officer for ${widget.complaint.ticketNumber}. They will start the job and upload before/after photos.', style: CivicFixTypography.bodySmall),
          CivicFixSpacing.vSpaceMd,
          if (widget.officers.isEmpty)
            const Text('No eligible execution officers are available in this ward and department.')
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Execution officer', border: OutlineInputBorder()),
              items: widget.officers.map((o) => DropdownMenuItem(value: o.employeeId, child: Text('${o.fullName} · ${o.displayDesignation}'))).toList(),
              onChanged: _saving ? null : (id) => setState(() => _selectedId = id),
            ),
          CivicFixSpacing.vSpaceMd,
          TextField(controller: _notes, maxLines: 2, enabled: !_saving, decoration: const InputDecoration(labelText: 'Instructions (optional)', border: OutlineInputBorder())),
          if (_error != null) ...[CivicFixSpacing.vSpaceSm, Text(_error!, style: const TextStyle(color: Colors.red))],
        ]),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton.icon(onPressed: _saving || widget.officers.isEmpty ? null : _submit, icon: const Icon(Icons.person_add_alt_1), label: const Text('Assign officer')),
      ],
    );
  }
}
