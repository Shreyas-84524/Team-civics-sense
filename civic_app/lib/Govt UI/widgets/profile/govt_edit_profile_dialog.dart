import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/govt_user_model.dart';
import '../../services/govt_user_repository.dart';
import '../../theme/govt_theme_tokens.dart';

/// Modal dialog for editing editable Government Officer profile fields.
class GovtEditProfileDialog extends StatefulWidget {
  final GovtUserModel user;
  final GovernmentUserRepository? userRepository;

  const GovtEditProfileDialog({
    super.key,
    required this.user,
    this.userRepository,
  });

  @override
  State<GovtEditProfileDialog> createState() => _GovtEditProfileDialogState();
}

class _GovtEditProfileDialogState extends State<GovtEditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _designationController;
  late final GovernmentUserRepository _userRepo;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userRepo = widget.userRepository ?? MockGovernmentUserRepository();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _designationController = TextEditingController(text: widget.user.designation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _userRepo.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        designation: _designationController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Officer profile updated successfully.'),
            backgroundColor: GovtThemeTokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GovtThemeTokens.cardRadius),
      backgroundColor: GovtThemeTokens.surface,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CivicFixSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: GovtThemeTokens.primary, size: 22),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Officer Profile', style: CivicFixTypography.h3),
                          CivicFixSpacing.vSpaceXs,
                          Text(
                            'Update contact information and operational designation',
                            style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: GovtThemeTokens.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceMd,
                const Divider(color: GovtThemeTokens.border),
                CivicFixSpacing.vSpaceMd,

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(CivicFixSpacing.md),
                    decoration: BoxDecoration(
                      color: GovtThemeTokens.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                      border: Border.all(color: GovtThemeTokens.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 18),
                        CivicFixSpacing.hSpaceSm,
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: CivicFixTypography.bodySmall.copyWith(color: GovtThemeTokens.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CivicFixSpacing.vSpaceMd,
                ],

                // Editable Full Name
                Text('Officer Full Name *', style: CivicFixTypography.captionMedium),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _nameController,
                  style: CivicFixTypography.body,
                  decoration: InputDecoration(
                    hintText: 'e.g. Shreyas S.',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: GovtThemeTokens.primary),
                    filled: true,
                    fillColor: GovtThemeTokens.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                      borderSide: const BorderSide(color: GovtThemeTokens.border),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter officer full name';
                    }
                    return null;
                  },
                ),
                CivicFixSpacing.vSpaceMd,

                // Editable Official Phone
                Text('Official Contact Phone *', style: CivicFixTypography.captionMedium),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _phoneController,
                  style: CivicFixTypography.body,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: GovtThemeTokens.primary),
                    filled: true,
                    fillColor: GovtThemeTokens.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                      borderSide: const BorderSide(color: GovtThemeTokens.border),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter official phone number';
                    }
                    return null;
                  },
                ),
                CivicFixSpacing.vSpaceMd,

                // Editable Designation
                Text('Operational Designation *', style: CivicFixTypography.captionMedium),
                CivicFixSpacing.vSpaceXs,
                TextFormField(
                  controller: _designationController,
                  style: CivicFixTypography.body,
                  decoration: InputDecoration(
                    hintText: 'e.g. Senior Municipal Nodal Officer',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: GovtThemeTokens.primary),
                    filled: true,
                    fillColor: GovtThemeTokens.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                      borderSide: const BorderSide(color: GovtThemeTokens.border),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter designation';
                    }
                    return null;
                  },
                ),
                CivicFixSpacing.vSpaceLg,

                // Non-Editable Security & Administrative Meta
                Container(
                  padding: const EdgeInsets.all(CivicFixSpacing.md),
                  decoration: BoxDecoration(
                    color: GovtThemeTokens.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(GovtThemeTokens.radiusSm),
                    border: Border.all(color: GovtThemeTokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 16, color: GovtThemeTokens.textSecondary),
                          CivicFixSpacing.hSpaceXs,
                          Text(
                            'System-Locked Administrative Identifiers',
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: GovtThemeTokens.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      CivicFixSpacing.vSpaceSm,
                      _buildLockedField('Account Role', '${widget.user.role.toUpperCase()} (Authorized Nodal Officer)'),
                      _buildLockedField('Official Email', widget.user.email),
                      _buildLockedField('Employee ID', widget.user.employeeId),
                      _buildLockedField('Organization', widget.user.organization),
                      _buildLockedField('Department', widget.user.departmentName),
                      _buildLockedField('Assigned Jurisdiction', widget.user.assignedWard),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceLg,
                const Divider(color: GovtThemeTokens.border),
                CivicFixSpacing.vSpaceMd,

                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.lg, vertical: CivicFixSpacing.md),
                      ),
                      child: const Text('Cancel'),
                    ),
                    CivicFixSpacing.hSpaceMd,
                    ElevatedButton.icon(
                      key: const Key('save_profile_button'),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_isSaving ? 'Saving Changes...' : 'Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GovtThemeTokens.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.xl, vertical: CivicFixSpacing.md),
                      ),
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

  Widget _buildLockedField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: CivicFixTypography.caption.copyWith(color: GovtThemeTokens.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: CivicFixTypography.captionMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
