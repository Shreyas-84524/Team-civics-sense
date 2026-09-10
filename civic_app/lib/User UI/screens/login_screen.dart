import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

/// Citizen Login Screen with form validation, loading state, and Firebase authentication.
class LoginScreen extends StatefulWidget {
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthServiceLocator.citizenAuth;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Incorrect email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          padding: CivicFixSpacing.pagePadding,
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CivicFixSpacing.vSpaceLg,

                    const AuthHeader(
                      title: 'Welcome back',
                      subtitle: 'Sign in to report civic issues, track community fixes, and participate in your ward.',
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // Error Message Banner
                    if (_errorMessage != null)
                      AuthErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),

                    // Email Field
                    AuthTextField(
                      label: 'Email',
                      hintText: 'e.g. name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isLoading,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: CivicFixColors.secondaryText,
                        size: 20,
                      ),
                      validator: _validateEmail,
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Password Field
                    AuthTextField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      controller: _passwordController,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: CivicFixColors.secondaryText,
                        size: 20,
                      ),
                      onTogglePasswordVisibility: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                    ),
                    CivicFixSpacing.vSpaceXs,

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushNamed(context, AppRoutes.forgotPassword);
                              },
                        child: Text(
                          'Forgot Password?',
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            color: CivicFixColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    CivicFixSpacing.vSpaceMd,

                    // Primary Login CTA Button
                    CivicFixButton(
                      text: 'Login',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleLogin,
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // Registration Link
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: CivicFixSpacing.xs,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: CivicFixTypography.bodySmall,
                          ),
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(context, AppRoutes.registration);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.xs),
                              child: Text(
                                'Create an account',
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
                    CivicFixSpacing.vSpaceLg,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
