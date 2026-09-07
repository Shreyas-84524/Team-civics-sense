import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';

/// Screen allowing citizen to update their profile name, phone, and preferred language.
class EditProfileScreen extends StatefulWidget {
  final UserRepository? repository;

  const EditProfileScreen({
    super.key,
    this.repository,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final UserRepository _userRepository;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String _selectedLanguage = 'en';
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.repository ?? MockUserRepository();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = await _userRepository.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.fullName;
        _phoneController.text = user.phone;
        _selectedLanguage = user.languageCode;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long.';
    }
    if (value.trim().length > 50) {
      return 'Name cannot exceed 50 characters.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Please enter a valid 10-digit phone number.';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userRepository.updateUserProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        languageCode: _selectedLanguage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: CivicFixColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'Edit Profile',
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: _currentUser == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: CivicFixSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Preview
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [CivicFixColors.primary, CivicFixColors.primaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CivicFixColors.primary.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _currentUser!.initials,
                                    style: CivicFixTypography.h1.copyWith(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: CivicFixColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CivicFixSpacing.vSpaceXl,

                        const SectionHeader(title: 'Personal Information'),
                        CivicFixSpacing.vSpaceSm,

                        // Full Name Input
                        Text(
                          'Full Name *',
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CivicFixColors.primaryText,
                          ),
                        ),
                        CivicFixSpacing.vSpaceXs,
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(
                              borderRadius: CivicFixRadius.inputRadius,
                              borderSide: const BorderSide(color: CivicFixColors.border),
                            ),
                          ),
                          validator: _validateName,
                          textCapitalization: TextCapitalization.words,
                        ),
                        CivicFixSpacing.vSpaceLg,

                        // Email (Read-only)
                        Text(
                          'Email Address',
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CivicFixColors.secondaryText,
                          ),
                        ),
                        CivicFixSpacing.vSpaceXs,
                        TextFormField(
                          initialValue: _currentUser!.email,
                          enabled: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined),
                            suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                            filled: true,
                            fillColor: CivicFixColors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: CivicFixRadius.inputRadius,
                              borderSide: const BorderSide(color: CivicFixColors.border),
                            ),
                            helperText: 'Email cannot be changed for citizen account.',
                            helperStyle: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.disabledText,
                            ),
                          ),
                        ),
                        CivicFixSpacing.vSpaceLg,

                        // Phone Input
                        Text(
                          'Phone Number',
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CivicFixColors.primaryText,
                          ),
                        ),
                        CivicFixSpacing.vSpaceXs,
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '+91 98765 43210',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: CivicFixRadius.inputRadius,
                              borderSide: const BorderSide(color: CivicFixColors.border),
                            ),
                            helperText: 'Used for SMS updates on urgent neighborhood alerts.',
                          ),
                          validator: _validatePhone,
                        ),
                        CivicFixSpacing.vSpaceLg,

                        // Preferred Language Selection
                        Text(
                          'Preferred Language',
                          style: CivicFixTypography.captionMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CivicFixColors.primaryText,
                          ),
                        ),
                        CivicFixSpacing.vSpaceXs,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: CivicFixColors.surface,
                            borderRadius: CivicFixRadius.inputRadius,
                            border: Border.all(color: CivicFixColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English')),
                                DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                                DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedLanguage = val);
                                }
                              },
                            ),
                          ),
                        ),
                        CivicFixSpacing.vSpaceLg,

                        // Jurisdiction / Ward & Role Info (Read-only)
                        Container(
                          padding: const EdgeInsets.all(CivicFixSpacing.md),
                          decoration: BoxDecoration(
                            color: CivicFixColors.surfaceMuted,
                            borderRadius: CivicFixRadius.cardRadius,
                            border: Border.all(color: CivicFixColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 20,
                                color: CivicFixColors.primary,
                              ),
                              CivicFixSpacing.hSpaceMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Registered Citizen Account',
                                      style: CivicFixTypography.bodySmallMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: CivicFixColors.primaryText,
                                      ),
                                    ),
                                    CivicFixSpacing.vSpaceXs,
                                    Text(
                                      '${_currentUser!.wardNumber} • Role: Citizen',
                                      style: CivicFixTypography.caption.copyWith(
                                        color: CivicFixColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        CivicFixSpacing.vSpaceXxl,

                        // Save Changes Button
                        CivicFixButton(
                          text: 'Save Changes',
                          isLoading: _isLoading,
                          onPressed: _saveProfile,
                        ),
                        CivicFixSpacing.vSpaceXxl,
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
