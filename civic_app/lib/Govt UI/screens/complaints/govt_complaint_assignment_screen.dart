import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../models/department_model.dart';
import '../../services/govt_complaint_repository.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../widgets/common/govt_confirmation_dialog.dart';

/// Screen / Workflow for Assigning a Complaint to a Department Officer or Field Crew.
class GovtComplaintAssignmentScreen extends StatefulWidget {
  final ComplaintModel? complaint;
  final String? complaintId;

  const GovtComplaintAssignmentScreen({
    super.key,
    this.complaint,
    this.complaintId,
  });

  @override
  State<GovtComplaintAssignmentScreen> createState() => _GovtComplaintAssignmentScreenState();
}

class _GovtComplaintAssignmentScreenState extends State<GovtComplaintAssignmentScreen> {
  final GovtComplaintRepository _repository = MockGovtComplaintRepository();
  final _noteController = TextEditingController(text: 'Assigned for immediate field inspection and repair.');

  ComplaintModel? _complaint;
  String _selectedDeptId = 'dept_roads';
  String? _selectedOfficerId;
  List<GovtOfficerModel> _officers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      _complaint = widget.complaint;
      _initDepartmentForComplaint(_complaint!);
    } else if (widget.complaintId != null) {
      _loadComplaint(widget.complaintId!);
    }
    _loadOfficers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_complaint == null && widget.complaint == null && widget.complaintId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ComplaintModel) {
        setState(() {
          _complaint = args;
          _initDepartmentForComplaint(args);
        });
      } else if (args is String) {
        _loadComplaint(args);
      }
    }
  }

  void _initDepartmentForComplaint(ComplaintModel c) {
    final catId = c.category.id.toLowerCase();
    final matchingDept = GovtDepartmentModel.defaultDepartments.firstWhere(
      (d) => d.id.toLowerCase().contains(catId) || catId.contains(d.id.replaceAll('dept_', '')),
      orElse: () => GovtDepartmentModel.defaultDepartments.first,
    );
    _selectedDeptId = matchingDept.id;
    _loadOfficers();
  }

  Future<void> _loadComplaint(String id) async {
    setState(() => _isLoading = true);
    final c = await _repository.getComplaintById(id);
    if (mounted) {
      setState(() {
        _complaint = c;
        _isLoading = false;
        if (c != null) {
          _initDepartmentForComplaint(c);
        }
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadOfficers() async {
    final officers = await _repository.getOfficers(departmentId: _selectedDeptId);
    if (mounted) {
      setState(() {
        _officers = officers.isNotEmpty ? officers : GovtOfficerModel.defaultOfficers;
        if (_officers.isNotEmpty) {
          _selectedOfficerId = _officers.first.id;
        }
      });
    }
  }

  void _promptAssignConfirmation() {
    final c = _complaint;
    if (c == null || _selectedOfficerId == null) return;

    final selectedOfficer = _officers.firstWhere(
      (o) => o.id == _selectedOfficerId,
      orElse: () => _officers.first,
    );
    final dept = GovtDepartmentModel.defaultDepartments.firstWhere(
      (d) => d.id == _selectedDeptId,
      orElse: () => GovtDepartmentModel.defaultDepartments.first,
    );

    showDialog(
      context: context,
      builder: (ctx) => GovtConfirmationDialog(
        title: 'Confirm Crew Dispatch',
        message: 'Are you sure you want to assign grievance ${c.ticketNumber} to ${selectedOfficer.name} in ${dept.name}?',
        confirmLabel: 'Confirm & Dispatch',
        onConfirm: () => _executeAssign(selectedOfficer),
      ),
    );
  }

  Future<void> _executeAssign(GovtOfficerModel selectedOfficer) async {
    final c = _complaint;
    if (c == null) return;

    setState(() => _isLoading = true);

    await _repository.assignComplaint(
      complaintId: c.id,
      departmentId: _selectedDeptId,
      officerName: selectedOfficer.name,
      assignmentNote: _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assigned grievance ${c.ticketNumber} to ${selectedOfficer.name}.'),
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
        title: Text(c != null ? 'Assign Grievance ${c.ticketNumber}' : 'Assign Complaint'),
        backgroundColor: GovtThemeTokens.surface,
        foregroundColor: GovtThemeTokens.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 600,
            padding: const EdgeInsets.all(CivicFixSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(CivicFixSpacing.xl),
              decoration: BoxDecoration(
                color: GovtThemeTokens.surface,
                borderRadius: GovtThemeTokens.cardRadius,
                border: Border.all(color: GovtThemeTokens.border),
                boxShadow: GovtThemeTokens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.assignment_outlined, color: GovtThemeTokens.primary, size: 20),
                        ),
                        CivicFixSpacing.hSpaceMd,
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
                      ],
                    ),
                    CivicFixSpacing.vSpaceLg,
                    const Divider(color: GovtThemeTokens.border),
                    CivicFixSpacing.vSpaceMd,
                  ],

                  // Department Dropdown
                  Text(
                    'Select Municipal Department',
                    style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDeptId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: GovtThemeTokens.chipRadius,
                        borderSide: const BorderSide(color: GovtThemeTokens.border),
                      ),
                    ),
                    items: GovtDepartmentModel.defaultDepartments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept.id,
                        child: Text(dept.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.bodySmall),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDeptId = val);
                        _loadOfficers();
                      }
                    },
                  ),
                  CivicFixSpacing.vSpaceMd,

                  // Officer / Maintenance Crew Selection
                  Text(
                    'Designated Field Engineer / Crew',
                    style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOfficerId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: GovtThemeTokens.chipRadius,
                        borderSide: const BorderSide(color: GovtThemeTokens.border),
                      ),
                    ),
                    items: _officers.map((off) {
                      return DropdownMenuItem<String>(
                        value: off.id,
                        child: Text('${off.name} (${off.designation})', maxLines: 1, overflow: TextOverflow.ellipsis, style: CivicFixTypography.bodySmall),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedOfficerId = val);
                      }
                    },
                  ),
                  CivicFixSpacing.vSpaceMd,

                  // Dispatch / Assignment Notes
                  Text(
                    'Dispatch Instructions & Priority Notes',
                    style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  CivicFixSpacing.vSpaceXs,
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    style: CivicFixTypography.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Enter specific work orders or dispatch instructions...',
                      filled: true,
                      fillColor: GovtThemeTokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: GovtThemeTokens.chipRadius,
                        borderSide: const BorderSide(color: GovtThemeTokens.border),
                      ),
                    ),
                  ),
                  CivicFixSpacing.vSpaceXl,

                  // Actions
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
                        text: 'Confirm & Dispatch',
                        width: 200,
                        isLoading: _isLoading,
                        onPressed: _promptAssignConfirmation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
