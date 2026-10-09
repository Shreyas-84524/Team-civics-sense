import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

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
  bool _isGoogleLoading = false;
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
      return context.l10nOrNull?.pleaseEnterEmail ?? 'Please enter your email.';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return context.l10nOrNull?.pleaseEnterValidEmail ?? 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10nOrNull?.pleaseEnterPassword ?? 'Please enter your password.';
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
      if (result.user != null && !result.user!.phoneVerified) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.verifyPhone,
          arguments: result.user?.phone,
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? context.l10nOrNull?.incorrectEmailOrPassword ?? 'Incorrect email or password.';
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isGoogleLoading = false);

    if (result.isSuccess) {
      if (result.user != null && !result.user!.phoneVerified) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.verifyPhone,
          arguments: result.user?.phone,
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else if (result.isCancelled) {
      // User cancelled account selection - keep quiet without error banner
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? context.l10nOrNull?.googleSignInFailed ?? 'Google Sign-In failed. Please try again.';
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

                    AuthHeader(
                      title: context.l10nOrNull?.welcomeBack ?? 'Welcome back',
                      subtitle: context.l10nOrNull?.signInSubtitle ?? 'Sign in to report civic issues, track community fixes, and participate in your ward.',
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
                      label: context.l10nOrNull?.email ?? 'Email',
                      hintText: context.l10nOrNull?.emailHint ?? 'e.g. name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isLoading && !_isGoogleLoading,
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
                      label: context.l10nOrNull?.password ?? 'Password',
                      hintText: context.l10nOrNull?.passwordHint ?? 'Enter your password',
                      controller: _passwordController,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      enabled: !_isLoading && !_isGoogleLoading,
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
                      onFieldSubmitted: (_) => (_isLoading || _isGoogleLoading) ? null : _handleLogin(),
                    ),
                    CivicFixSpacing.vSpaceXs,

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : () {
                                Navigator.pushNamed(context, AppRoutes.forgotPassword);
                              },
                        child: Text(
                          context.l10nOrNull?.forgotPassword ?? 'Forgot Password?',
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
                      text: context.l10nOrNull?.login ?? 'Login',
                      isLoading: _isLoading,
                      onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Divider with "OR"
                    Row(
                      children: [
                        const Expanded(child: Divider(color: CivicFixColors.border, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.md),
                          child: Text(
                            context.l10nOrNull?.orDivider ?? 'OR',
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: CivicFixColors.border, thickness: 1)),
                      ],
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Continue with Google Button
                    GoogleSignInButton(
                      isLoading: _isGoogleLoading,
                      onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
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
                            context.l10nOrNull?.dontHaveAccount ?? "Don't have an account?",
                            style: CivicFixTypography.bodySmall,
                          ),
                          GestureDetector(
                            onTap: (_isLoading || _isGoogleLoading)
                                ? null
                                : () {
                                    Navigator.pushNamed(context, AppRoutes.registration);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.xs),
                              child: Text(
                                context.l10nOrNull?.createAccount ?? 'Create an account',
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

                    const Divider(color: CivicFixColors.border, thickness: 1),
                    CivicFixSpacing.vSpaceMd,

                    // Government Officer Portal Switch
                    Center(
                      child: OutlinedButton.icon(
                        key: const Key('govt_officer_login_button'),
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : () {
                                Navigator.pushNamed(context, AppRoutes.govtLogin);
                              },
                        icon: const Icon(
                          Icons.account_balance_rounded,
                          size: 18,
                          color: CivicFixColors.primary,
                        ),
                        label: Text(
                          context.l10nOrNull?.govtOfficerLogin ?? 'Government Officer Login',
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            color: CivicFixColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.lg,
                            vertical: CivicFixSpacing.sm + 2,
                          ),
                          side: const BorderSide(color: CivicFixColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
