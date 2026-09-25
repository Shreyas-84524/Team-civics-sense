import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/auth/phone_normalizer.dart';
import '../../core/auth/phone_verification_service.dart';
import '../../core/auth/phone_verification_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

/// Screen guiding citizens through MSG91 SMS OTP Phone Verification.
///
/// Features:
/// - Pre-populates phone number from registration if available
/// - Validates Indian 10-digit mobile numbers (+91)
/// - Dispatches OTP via [PhoneVerificationService]
/// - Live countdown cooldown timer for OTP resends
/// - Verifies code and commits verified status to profile in [AuthService]
/// - Routes to [AppRoutes.home] upon successful completion
class PhoneVerificationScreen extends StatefulWidget {
  final AuthService? authService;
  final PhoneVerificationService? verificationService;
  final String? initialPhone;

  const PhoneVerificationScreen({
    super.key,
    this.authService,
    this.verificationService,
    this.initialPhone,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  late final AuthService _authService;
  late final PhoneVerificationService _verificationService;

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;
  String? _activeReqId;

  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthServiceLocator.citizenAuth;
    _verificationService = widget.verificationService ?? PhoneVerificationServiceLocator.instance;

    final initial = widget.initialPhone ?? _authService.currentUser?.phone;
    if (initial != null && initial.isNotEmpty) {
      final tenDigit = PhoneNormalizer.extract10Digit(initial);
      if (tenDigit != null) {
        _phoneController.text = tenDigit;
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _secondsRemaining = _verificationService.resendCooldownSeconds;
    if (_secondsRemaining <= 0) _secondsRemaining = 30;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final rawPhone = _phoneController.text.trim();
    final result = await _verificationService.sendOtp(rawPhone);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      setState(() {
        _isOtpSent = true;
        _activeReqId = result.reqId;
        _successMessage = result.message ?? 'Verification code sent via SMS.';
      });
      _startCooldownTimer();
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Failed to send verification code.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    if (_activeReqId == null || _activeReqId!.isEmpty) {
      setState(() {
        _errorMessage = 'Session expired. Please request a new verification code.';
      });
      return;
    }

    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    final result = await _verificationService.verifyOtp(
      phoneNumber: phone,
      otp: otp,
      reqId: _activeReqId!,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Mark phone verified on the citizen profile
      final authResult = await _authService.markPhoneVerified(
        phoneNumber: phone,
        accessToken: result.accessToken,
      );

      if (!mounted) return;

      if (authResult.isSuccess) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Phone verified successfully! Redirecting...';
        });

        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = authResult.errorMessage ?? 'Failed to update verified phone profile.';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.message ?? 'Invalid verification code.';
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isResending = true;
    });

    final phone = _phoneController.text.trim();
    final result = await _verificationService.resendOtp(
      phoneNumber: phone,
      reqId: _activeReqId ?? '',
    );

    if (!mounted) return;

    setState(() => _isResending = false);

    if (result.isSuccess) {
      setState(() {
        _activeReqId = result.reqId ?? _activeReqId;
        _successMessage = 'A new verification code has been dispatched.';
      });
      _startCooldownTimer();
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Unable to resend verification code.';
      });
    }
  }

  void _handleChangePhone() {
    setState(() {
      _isOtpSent = false;
      _errorMessage = null;
      _successMessage = null;
      _otpController.clear();
      _cooldownTimer?.cancel();
      _secondsRemaining = 0;
    });
  }

  Future<void> _handleSignOut() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isOtpSent) {
          _handleChangePhone();
        } else {
          _handleSignOut();
        }
      },
      child: Scaffold(
        backgroundColor: CivicFixColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CivicFixColors.primaryText),
          onPressed: () {
            if (_isOtpSent) {
              _handleChangePhone();
            } else {
              _handleSignOut();
            }
          },
          tooltip: _isOtpSent ? 'Change number' : 'Back to login',
        ),
        actions: [
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              'Sign Out',
              style: CivicFixTypography.bodySmallMedium.copyWith(
                color: CivicFixColors.secondaryText,
              ),
            ),
          ),
          CivicFixSpacing.hSpaceSm,
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          padding: CivicFixSpacing.pagePadding,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(
                    title: 'Verify Your Phone',
                    subtitle: 'To prevent duplicate civic complaints and protect community authenticity, verify your mobile number via SMS.',
                  ),
                  CivicFixSpacing.vSpaceXl,

                  // Feedback Messages
                  if (_errorMessage != null) ...[
                    AuthErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    CivicFixSpacing.vSpaceMd,
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: CivicFixColors.success.withValues(alpha: 0.1),
                        borderRadius: CivicFixRadius.cardRadius,
                        border: Border.all(color: CivicFixColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: CivicFixColors.success, size: 20),
                          CivicFixSpacing.hSpaceSm,
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: CivicFixTypography.bodySmall.copyWith(color: CivicFixColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceMd,
                  ],

                  // STEP 1: Phone Entry & Edit Card
                  if (!_isOtpSent) ...[
                    Form(
                      key: _phoneFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthTextField(
                            label: 'Mobile Number',
                            hintText: 'e.g. 9876543210',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              width: 60,
                              child: Text(
                                '+91',
                                style: CivicFixTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: CivicFixColors.primaryText,
                                ),
                              ),
                            ),
                            maxLength: 10,
                            enabled: !_isLoading,
                            validator: PhoneNormalizer.validate,
                          ),
                          CivicFixSpacing.vSpaceLg,

                          CivicFixButton(
                            text: 'Send Verification Code',
                            onPressed: _handleSendOtp,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Active Phone Badge with change action
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: CivicFixColors.surface,
                        borderRadius: CivicFixRadius.cardRadius,
                        border: Border.all(color: CivicFixColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_iphone, color: CivicFixColors.primary, size: 20),
                              CivicFixSpacing.hSpaceSm,
                              Text(
                                PhoneNormalizer.toDisplay(_phoneController.text),
                                style: CivicFixTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: CivicFixColors.primaryText,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _handleChangePhone,
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // STEP 2: OTP Input Form
                    Form(
                      key: _otpFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthTextField(
                            label: 'Verification Code',
                            hintText: 'Enter 6-digit OTP',
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            enabled: !_isLoading,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter the verification code.';
                              }
                              if (val.trim().length < 4) {
                                return 'Verification code must be at least 4 digits.';
                              }
                              return null;
                            },
                          ),
                          CivicFixSpacing.vSpaceLg,

                          CivicFixButton(
                            text: 'Verify & Continue',
                            onPressed: _handleVerifyOtp,
                            isLoading: _isLoading,
                          ),
                          CivicFixSpacing.vSpaceMd,

                          // Resend OTP Action & Cooldown
                          Center(
                            child: _secondsRemaining > 0
                                ? Text(
                                    'Resend code in ${_secondsRemaining}s',
                                    style: CivicFixTypography.bodySmall.copyWith(
                                      color: CivicFixColors.secondaryText,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: (_isLoading || _isResending) ? null : _handleResendOtp,
                                    child: _isResending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Resend Verification Code'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
