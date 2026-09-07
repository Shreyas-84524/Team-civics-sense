import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/civic_fix_text_field.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../services/govt_auth_service.dart';
import '../../theme/govt_theme_tokens.dart';

/// Government Portal Password Recovery / Reset Screen.
class GovtForgotPasswordScreen extends StatefulWidget {
  const GovtForgotPasswordScreen({super.key});

  @override
  State<GovtForgotPasswordScreen> createState() => _GovtForgotPasswordScreenState();
}

class _GovtForgotPasswordScreenState extends State<GovtForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'government@civicfix.test');
  final GovtAuthService _authService = MockGovtAuthService();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.requestPasswordReset(
      email: _emailController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      setState(() {
        _isSuccess = true;
        _successMessage = result.successMessage ??
            'A secure password recovery link has been dispatched to ${_emailController.text}.';
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Failed to process password recovery.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F263B), // Deep Navy backdrop
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Back to Login',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.govtLogin);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 520,
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.xl,
                vertical: CivicFixSpacing.xl,
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
                child: _isSuccess ? _buildSuccessView() : _buildFormView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge
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
                      Icons.lock_reset_rounded,
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
                    'OFFICER PASSWORD RECOVERY',
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
          CivicFixSpacing.vSpaceLg,

          Text(
            'Reset Municipal Access Passcode',
            style: CivicFixTypography.h3.copyWith(
              color: GovtThemeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          Text(
            'Enter your registered official government email. We will generate a secure reset token dispatched to your municipal mailbox.',
            style: CivicFixTypography.bodySmall.copyWith(
              color: GovtThemeTokens.textSecondary,
              height: 1.45,
            ),
          ),
          CivicFixSpacing.vSpaceLg,

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(CivicFixSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF5B7B7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: GovtThemeTokens.error, size: 18),
                  CivicFixSpacing.hSpaceSm,
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: GovtThemeTokens.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CivicFixSpacing.vSpaceMd,
          ],

          // Official Email
          Text(
            'Official Government Email',
            style: CivicFixTypography.bodySmallMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          CivicFixSpacing.vSpaceXs,
          CivicFixTextField(
            hintText: 'e.g. government@civicfix.test',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: (v) {
              final trimmed = v?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Please enter your official email.';
              }
              if (!trimmed.contains('@') || !trimmed.contains('.')) {
                return 'Please enter a valid email format.';
              }
              return null;
            },
          ),
          CivicFixSpacing.vSpaceXl,

          // Submit Button
          CivicFixButton(
            text: 'Send Recovery Instructions',
            icon: Icons.send_rounded,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleResetRequest,
          ),
          CivicFixSpacing.vSpaceLg,

          // Return to Login Link
          Center(
            child: TextButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.govtLogin);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Government Login'),
              style: TextButton.styleFrom(
                foregroundColor: GovtThemeTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F8F0),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 40,
              color: GovtThemeTokens.secondary,
            ),
          ),
        ),
        CivicFixSpacing.vSpaceLg,
        Text(
          'Recovery Token Dispatched',
          textAlign: TextAlign.center,
          style: CivicFixTypography.h2.copyWith(
            color: GovtThemeTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        CivicFixSpacing.vSpaceSm,
        Text(
          _successMessage ??
              'Password reset instructions and a verification token have been sent to your official municipal email.',
          textAlign: TextAlign.center,
          style: CivicFixTypography.bodySmall.copyWith(
            color: GovtThemeTokens.textSecondary,
            height: 1.5,
          ),
        ),
        CivicFixSpacing.vSpaceLg,
        Container(
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GovtThemeTokens.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: GovtThemeTokens.info, size: 20),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Text(
                  'Check your municipal intranet inbox or security filter for instructions from the administration gateway.',
                  style: CivicFixTypography.caption.copyWith(
                    color: GovtThemeTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        CivicFixSpacing.vSpaceXl,
        CivicFixButton(
          text: 'Return to Government Login',
          icon: Icons.login_rounded,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.govtLogin);
            }
          },
        ),
      ],
    );
  }
}
