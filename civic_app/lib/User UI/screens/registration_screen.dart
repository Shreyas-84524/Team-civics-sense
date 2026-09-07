import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/mock_auth_service.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_success_banner.dart';
import '../widgets/auth_text_field.dart';

/// Citizen Registration Screen with form validation, language selection, and mock account creation.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = MockAuthService();

  String _selectedLanguage = 'en';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final Map<String, String> _languages = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'mr': 'मराठी (Marathi)',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email.';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Please enter a valid phone number (at least 10 digits).';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      language: _selectedLanguage,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isLoading = false;
        _successMessage = result.successMessage ?? 'Account created successfully.';
      });

      // Brief pause to allow user to see success state, then navigate
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: '',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          padding: CivicFixSpacing.pagePadding,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthHeader(
                    title: 'Create your CivicFix account',
                    subtitle: 'Your civic participation starts here.',
                  ),
                  CivicFixSpacing.vSpaceXl,

                  // Error Banner
                  if (_errorMessage != null)
                    AuthErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),

                  // Success Banner
                  if (_successMessage != null)
                    AuthSuccessBanner(
                      message: _successMessage!,
                    ),

                  // Full Name
                  AuthTextField(
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    controller: _nameController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: CivicFixColors.secondaryText, size: 20),
                    validator: _validateName,
                  ),
                  CivicFixSpacing.vSpaceLg,

                  // Email
                  AuthTextField(
                    label: 'Email',
                    hintText: 'e.g. name@example.com',
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: CivicFixColors.secondaryText, size: 20),
                    validator: _validateEmail,
                  ),
                  CivicFixSpacing.vSpaceLg,

                  // Phone Number (Optional)
                  AuthTextField(
                    label: 'Phone Number (Optional)',
                    hintText: 'e.g. +91 98765 43210',
                    controller: _phoneController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.phone_outlined, color: CivicFixColors.secondaryText, size: 20),
                    validator: _validatePhone,
                  ),
                  CivicFixSpacing.vSpaceLg,

                  // Password
                  AuthTextField(
                    label: 'Password',
                    hintText: 'Minimum 8 characters',
                    controller: _passwordController,
                    enabled: !_isLoading,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: CivicFixColors.secondaryText, size: 20),
                    onTogglePasswordVisibility: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                    validator: _validatePassword,
                  ),
                  CivicFixSpacing.vSpaceLg,

                  // Confirm Password
                  AuthTextField(
                    label: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: CivicFixColors.secondaryText, size: 20),
                    onTogglePasswordVisibility: () {
                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                    },
                    validator: _validateConfirmPassword,
                    onFieldSubmitted: (_) => _isLoading ? null : _handleRegister(),
                  ),
                  CivicFixSpacing.vSpaceLg,

                  // Preferred Language Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Language',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          color: CivicFixColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CivicFixSpacing.vSpaceSm,
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: CivicFixColors.surface,
                          prefixIcon: const Icon(Icons.language_rounded, color: CivicFixColors.secondaryText, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.lg,
                            vertical: CivicFixSpacing.lg,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: CivicFixRadius.buttonRadius,
                            borderSide: const BorderSide(color: CivicFixColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: CivicFixRadius.buttonRadius,
                            borderSide: const BorderSide(color: CivicFixColors.border),
                          ),
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: CivicFixColors.primaryText),
                        items: _languages.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: CivicFixTypography.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _selectedLanguage = val);
                                }
                              },
                      ),
                    ],
                  ),
                  CivicFixSpacing.vSpaceXxl,

                  // Create Account Button
                  CivicFixButton(
                    text: 'Create Account',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleRegister,
                  ),
                  CivicFixSpacing.vSpaceXl,

                  // Login Link
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: CivicFixSpacing.xs,
                      children: [
                        Text(
                          'Already have an account?',
                          style: CivicFixTypography.bodySmall,
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.xs),
                            child: Text(
                              'Login',
                              style: CivicFixTypography.bodySmallMedium.copyWith(
                                color: CivicFixColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
