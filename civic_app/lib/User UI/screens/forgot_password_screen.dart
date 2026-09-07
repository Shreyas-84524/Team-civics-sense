import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/civic_fix_outlined_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/mock_auth_service.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_success_banner.dart';
import '../widgets/auth_text_field.dart';

/// Screen for citizen password recovery and reset link simulation.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = MockAuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  Future<void> _handleSendResetLink() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _successMessage = result.successMessage ?? 'Password reset instructions have been sent.';
      } else {
        _errorMessage = result.errorMessage ?? 'Unable to process reset request.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    title: 'Reset your password',
                    subtitle: 'Enter the email associated with your account to receive password reset instructions.',
                  ),
                  CivicFixSpacing.vSpaceXl,

                  // Error & Success Banners
                  if (_errorMessage != null)
                    AuthErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                  if (_successMessage != null)
                    AuthSuccessBanner(
                      message: _successMessage!,
                      onDismiss: () => setState(() => _successMessage = null),
                    ),

                  AuthTextField(
                    label: 'Email',
                    hintText: 'Enter your registered email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: CivicFixColors.secondaryText,
                      size: 20,
                    ),
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => _handleSendResetLink(),
                  ),
                  CivicFixSpacing.vSpaceXl,

                  CivicFixButton(
                    text: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleSendResetLink,
                  ),
                  CivicFixSpacing.vSpaceMd,

                  CivicFixOutlinedButton(
                    text: 'Back to Login',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
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
