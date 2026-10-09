import 'package:flutter/material.dart';
import '../../../../User UI/widgets/auth_error_banner.dart';
import '../../../../User UI/widgets/auth_header.dart';
import '../../../../User UI/widgets/auth_text_field.dart';
import '../../../core/auth/auth_service_locator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../models/government_session.dart';
import '../../services/govt_auth_service.dart';

/// Official Government & Municipal Administration Login Portal.
///
/// Styled consistently with the citizen authentication layout for a unified brand experience,
/// while restricting authentication strictly to authorized Municipal Officers.
class GovtLoginScreen extends StatefulWidget {
  final GovtAuthService? authService;

  const GovtLoginScreen({super.key, this.authService});

  @override
  State<GovtLoginScreen> createState() => _GovtLoginScreenState();
}

class _GovtLoginScreenState extends State<GovtLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final GovtAuthService _authService;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthServiceLocator.govtAuth;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return l10n?.govEmployeeIdOrEmail ?? 'Please enter your government email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return l10n?.govPassword ?? 'Please enter your password.';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(
      emailOrEmployeeId: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      final user = result.user ?? _authService.currentUser;
      if (user != null) {
        final session = GovernmentSession.fromUser(user);
        Navigator.pushReplacementNamed(context, session.landingRoute);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.govtDashboard);
      }
    } else {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorMessage = result.errorMessage ?? l10n?.govInvalidCredentials ?? 'Invalid email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                      title: l10n?.govPortalTitle ?? 'CivicFix Government',
                      subtitle:
                          'Sign in to access your municipal department dashboard, review complaints, and update grievance status.',
                    ),
                    CivicFixSpacing.vSpaceSm,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: CivicFixColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CivicFixColors.border),
                      ),
                      child: Text(
                        l10n?.govMunicipalCorporation.toUpperCase() ?? 'MUNICIPAL OFFICER CONTROL DESK',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.secondaryText,
                          letterSpacing: 0.8,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Authentication Error State
                    if (_errorMessage != null)
                      AuthErrorBanner(
                        message: _errorMessage!,
                        onDismiss: () => setState(() => _errorMessage = null),
                      ),

                    // 1. Email Field
                    AuthTextField(
                      label: l10n?.govEmployeeIdOrEmail ?? 'Email',
                      hintText: 'e.g. officer@civicfix.dev',
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

                    // 2. Password Field
                    AuthTextField(
                      label: l10n?.govPassword ?? 'Password',
                      hintText: l10n?.govPassword ?? 'Enter password',
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
                                Navigator.pushNamed(context, AppRoutes.govtForgotPassword);
                              },
                        child: Text(
                          l10n?.govForgotPassword ?? 'Forgot Password?',
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            color: CivicFixColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    CivicFixSpacing.vSpaceMd,

                    // 3. Login Button
                    CivicFixButton(
                      text: l10n?.govSignInButton ?? 'Login',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleLogin,
                    ),
                    CivicFixSpacing.vSpaceLg,

                    const Divider(color: CivicFixColors.border, thickness: 1),
                    CivicFixSpacing.vSpaceMd,

                    // 4. Back to Citizen Login Button
                    Center(
                      child: OutlinedButton.icon(
                        key: const Key('back_to_citizen_login_button'),
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                                }
                              },
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: CivicFixColors.primary,
                        ),
                        label: Text(
                          'Back to Citizen Login',
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
