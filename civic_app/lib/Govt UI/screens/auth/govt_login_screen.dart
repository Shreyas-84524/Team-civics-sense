import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/civic_fix_text_field.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../models/department_model.dart';
import '../../services/govt_auth_service.dart';
import '../../theme/govt_theme_tokens.dart';

/// Official Government & Municipal Administration Login Portal.
class GovtLoginScreen extends StatefulWidget {
  const GovtLoginScreen({super.key});

  @override
  State<GovtLoginScreen> createState() => _GovtLoginScreenState();
}

class _GovtLoginScreenState extends State<GovtLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'government@civicfix.test');
  final _passwordController = TextEditingController(text: 'CivicFix123');
  final GovtAuthService _authService = MockGovtAuthService();

  String _selectedDepartmentId = 'dept_roads';
  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
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

    final result = await _authService.login(
      emailOrEmployeeId: _emailController.text,
      password: _passwordController.text,
      departmentId: _selectedDepartmentId,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, AppRoutes.govtDashboard);
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Authentication failed. Please verify credentials.';
      });
    }
  }

  void _fillMockCredentials() {
    setState(() {
      _emailController.text = 'government@civicfix.test';
      _passwordController.text = 'CivicFix123';
      _selectedDepartmentId = 'dept_roads';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F263B), // Deep Navy backdrop
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 520,
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
                              const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 20),
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

                      // Department Selection Dropdown
                      Text(
                        'Department / Wing',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDepartmentId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: GovtThemeTokens.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.md,
                            vertical: CivicFixSpacing.sm + 2,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: GovtThemeTokens.chipRadius,
                            borderSide: const BorderSide(color: GovtThemeTokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: GovtThemeTokens.chipRadius,
                            borderSide: const BorderSide(color: GovtThemeTokens.border),
                          ),
                        ),
                        items: GovtDepartmentModel.defaultDepartments.map((dept) {
                          return DropdownMenuItem<String>(
                            value: dept.id,
                            child: Row(
                              children: [
                                Icon(dept.icon, size: 16, color: GovtThemeTokens.primary),
                                CivicFixSpacing.hSpaceSm,
                                Expanded(
                                  child: Text(
                                    dept.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CivicFixTypography.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDepartmentId = val);
                          }
                        },
                      ),
                      CivicFixSpacing.vSpaceMd,

                      // Official Email / Employee ID
                      Text(
                        'Official Email / Employee ID',
                        style: CivicFixTypography.bodySmallMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CivicFixSpacing.vSpaceXs,
                      CivicFixTextField(
                        hintText: 'e.g. government@civicfix.test',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Please enter official ID or email.';
                          }
                          return null;
                        },
                      ),
                      CivicFixSpacing.vSpaceMd,

                      // Password
                      Text(
                        'Security Passcode',
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
                          hintText: 'Enter access passcode',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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
                        validator: (v) => v?.isEmpty == true ? 'Please enter your password.' : null,
                      ),
                      CivicFixSpacing.vSpaceSm,

                      // Remember Me & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () {
                                setState(() => _rememberMe = !_rememberMe);
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: GovtThemeTokens.primary,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (val) {
                                          setState(() => _rememberMe = val ?? false);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Remember session',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: CivicFixTypography.caption.copyWith(
                                          color: GovtThemeTokens.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          CivicFixSpacing.hSpaceSm,
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.govtForgotPassword);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: GovtThemeTokens.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      CivicFixSpacing.vSpaceXl,

                      // Login Button
                      CivicFixButton(
                        text: 'Enter Government Portal',
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                      ),
                      CivicFixSpacing.vSpaceLg,

                      // Quick Fill Test Credentials & Switch Portal
                      Center(
                        child: Column(
                          children: [
                            TextButton.icon(
                              onPressed: _isLoading ? null : _fillMockCredentials,
                              icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                              label: const Text('Fill Test Officer Credentials'),
                              style: TextButton.styleFrom(
                                foregroundColor: GovtThemeTokens.secondary,
                              ),
                            ),
                            CivicFixSpacing.vSpaceSm,
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, AppRoutes.login);
                              },
                              child: Text(
                                'Switch to Citizen App',
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: GovtThemeTokens.textSecondary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
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
