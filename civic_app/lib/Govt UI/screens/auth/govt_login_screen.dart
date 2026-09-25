import 'package:flutter/material.dart';
import '../../../core/auth/auth_service_locator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/civic_fix_text_field.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../services/govt_auth_service.dart';
import '../../theme/govt_theme_tokens.dart';

/// Official Government & Municipal Administration Login Portal.
///
/// Authentication is strictly restricted to authorized Municipal Officers
/// using their Government ID and Password.
class GovtLoginScreen extends StatefulWidget {
  final GovtAuthService? authService;

  const GovtLoginScreen({super.key, this.authService});

  @override
  State<GovtLoginScreen> createState() => _GovtLoginScreenState();
}

class _GovtLoginScreenState extends State<GovtLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _govtIdController = TextEditingController();
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
    _govtIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.loginWithGovernmentId(
      governmentId: _govtIdController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, AppRoutes.govtDashboard);
    } else {
      setState(() {
        _errorMessage = result.errorMessage ??
            'Invalid Government ID or password. Please verify your municipal credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F263B), // Deep Navy backdrop
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 480,
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.xl,
                vertical: CivicFixSpacing.xxl,
              ),
              child: Container(
                padding: const EdgeInsets.all(CivicFixSpacing.xxl),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Badge & Municipal Portal Seal
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F2F8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFB8D8EA)),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  size: 36,
                                  color: GovtThemeTokens.primary,
                                ),
                              ),
                            ),
                            CivicFixSpacing.vSpaceMd,
                            Text(
                              AppConstants.appName,
                              style: CivicFixTypography.h1.copyWith(
                                color: GovtThemeTokens.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXs,
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF3F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'MUNICIPAL OFFICER CONTROL DESK',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: GovtThemeTokens.textSecondary,
                                  letterSpacing: 0.8,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CivicFixSpacing.vSpaceXl,

                      // Authentication Error State
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(CivicFixSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF5B7B7)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: GovtThemeTokens.error,
                                size: 20,
                              ),
                              CivicFixSpacing.hSpaceSm,
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    color: GovtThemeTokens.error,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CivicFixSpacing.vSpaceMd,
                      ],

                      // 1. Government ID Field
                      Text(
                        'Government ID',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      CivicFixTextField(
                        hintText: 'e.g. MUMHQ00001',
                        controller: _govtIdController,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Please enter your Government ID.';
                          }
                          return null;
                        },
                      ),
                      CivicFixSpacing.vSpaceMd,

                      // 2. Password Field
                      Text(
                        'Password',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: CivicFixTypography.body,
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                            ),
                            tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
                            onPressed: () {
                              setState(() => _isPasswordVisible = !_isPasswordVisible);
                            },
                          ),
                          filled: true,
                          fillColor: GovtThemeTokens.surface,
                          border: OutlineInputBorder(
                            borderRadius: GovtThemeTokens.chipRadius,
                            borderSide: const BorderSide(color: GovtThemeTokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: GovtThemeTokens.chipRadius,
                            borderSide: const BorderSide(color: GovtThemeTokens.border),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password.';
                          }
                          return null;
                        },
                      ),
                      CivicFixSpacing.vSpaceXl,

                      // 3. Login Button
                      CivicFixButton(
                        text: 'Login',
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
