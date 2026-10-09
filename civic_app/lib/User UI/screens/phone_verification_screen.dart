import 'dart:async';
import 'dart:math';
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

import '../../core/auth/phone_verification_session.dart';
import '../../core/localization/app_localizations.dart';

/// Screen guiding citizens through SMS OTP Phone Verification.
///
/// Features:
/// - Pre-populates phone number from registration if available
/// - Validates Indian 10-digit mobile numbers (+91)
/// - Dispatches OTP via [PhoneVerificationService]
/// - Authoritative [PhoneVerificationSession] tracking with request generation race protection
/// - Live countdown cooldown timer synchronized with wall-clock time and app lifecycle
/// - Clears stale OTP input and timers upon resend or phone change
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

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> with WidgetsBindingObserver {
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
  PhoneVerificationSession? _session;

  int _otpRequestGeneration = 0;
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncCooldownTimer();
    }
  }

  void _syncCooldownTimer() {
    if (!mounted || !_isOtpSent) return;

    if (_session != null) {
      final remaining = _session!.secondsUntilResend;
      setState(() {
        _secondsRemaining = remaining;
      });
      if (remaining <= 0) {
        _cooldownTimer?.cancel();
      }
    } else {
      final remaining = _verificationService.resendCooldownSeconds;
      setState(() {
        _secondsRemaining = remaining;
      });
      if (remaining <= 0) {
        _cooldownTimer?.cancel();
      }
    }
  }

  void _startCooldownTimer({int? durationSeconds}) {
    _cooldownTimer?.cancel();
    final duration = durationSeconds ??
        (_session != null ? _session!.secondsUntilResend : _verificationService.resendCooldownSeconds);
    _secondsRemaining = duration > 0 ? duration : 30;

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
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    final generation = ++_otpRequestGeneration;
    setState(() => _isLoading = true);

    final rawPhone = _phoneController.text.trim();
    debugPrint('[PhoneVerificationScreen] Dispatching send-otp for gen=$generation, phone=${PhoneNormalizer.mask(rawPhone)}');

    final result = await _verificationService.sendOtp(rawPhone);

    if (!mounted || generation != _otpRequestGeneration) {
      debugPrint('[PhoneVerificationScreen] Discarding outdated send-otp response for gen=$generation (current gen=$_otpRequestGeneration)');
      return;
    }

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      final now = DateTime.now().toUtc();
      final cooldownSec = result.cooldownSeconds ?? _verificationService.resendCooldownSeconds;
      final effectiveCooldown = cooldownSec > 0 ? cooldownSec : 30;
      final expiresIn = result.expiresInSeconds ?? 300;
      final expiresAt = result.expiresAt ?? now.add(Duration(seconds: expiresIn));
      final resendAt = now.add(Duration(seconds: effectiveCooldown));

      final reqId = result.reqId ?? '';

      _session = PhoneVerificationSession(
        phoneNumber: PhoneNormalizer.toE164(rawPhone),
        challengeId: reqId,
        createdAt: now,
        expiresAt: expiresAt,
        resendAvailableAt: resendAt,
        generation: generation,
      );

      _otpController.clear();

      setState(() {
        _isOtpSent = true;
        _activeReqId = reqId;
        _successMessage = result.message ?? 'Verification code sent via SMS.';
      });

      _startCooldownTimer(durationSeconds: effectiveCooldown);
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Failed to send verification code.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_isLoading || _isResending) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    final challengeId = _session?.challengeId ?? _activeReqId;
    if (challengeId == null || challengeId.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid verification session. Please request a new verification code.';
      });
      return;
    }

    if (_session != null && _session!.isExpired) {
      setState(() {
        _errorMessage = 'The verification code has expired. Please tap Resend Code to request a new one.';
      });
      return;
    }

    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final currentGen = _otpRequestGeneration;

    debugPrint('[PhoneVerificationScreen] Verifying OTP for gen=$currentGen, challenge=${challengeId.length > 8 ? "${challengeId.substring(0, 8)}..." : challengeId}');

    final result = await _verificationService.verifyOtp(
      phoneNumber: phone,
      otp: otp,
      reqId: challengeId,
    );

    if (!mounted || currentGen != _otpRequestGeneration) {
      debugPrint('[PhoneVerificationScreen] Discarding outdated verify response');
      return;
    }

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
          _successMessage = context.l10nOrNull?.phoneVerifiedSuccess ?? 'Phone verified successfully! Redirecting...';
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
        _errorMessage = result.message ?? context.l10nOrNull?.invalidVerificationCode ?? 'Invalid verification code.';
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isResending || _isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isResending = true;
    });

    final generation = ++_otpRequestGeneration;
    final phone = _phoneController.text.trim();
    final previousReqId = _session?.challengeId ?? _activeReqId ?? '';

    debugPrint('[PhoneVerificationScreen] Resending OTP for gen=$generation, prevReq=${previousReqId.isNotEmpty ? "${previousReqId.substring(0, min(8, previousReqId.length))}..." : "none"}');

    final result = await _verificationService.resendOtp(
      phoneNumber: phone,
      reqId: previousReqId,
    );

    if (!mounted || generation != _otpRequestGeneration) {
      debugPrint('[PhoneVerificationScreen] Discarding outdated resend response for gen=$generation');
      return;
    }

    setState(() => _isResending = false);

    if (result.isSuccess) {
      final now = DateTime.now().toUtc();
      final cooldownSec = result.cooldownSeconds ?? _verificationService.resendCooldownSeconds;
      final effectiveCooldown = cooldownSec > 0 ? cooldownSec : 30;
      final expiresIn = result.expiresInSeconds ?? 300;
      final expiresAt = result.expiresAt ?? now.add(Duration(seconds: expiresIn));
      final resendAt = now.add(Duration(seconds: effectiveCooldown));

      final newReqId = (result.reqId != null && result.reqId!.isNotEmpty)
          ? result.reqId!
          : previousReqId;

      _session = PhoneVerificationSession(
        phoneNumber: PhoneNormalizer.toE164(phone),
        challengeId: newReqId,
        createdAt: now,
        expiresAt: expiresAt,
        resendAvailableAt: resendAt,
        generation: generation,
      );

      // Clean stale OTP digits from the input field
      _otpController.clear();

      setState(() {
        _activeReqId = newReqId;
        _successMessage = context.l10nOrNull?.codeSentViaSms ?? 'A new verification code has been dispatched.';
      });

      _startCooldownTimer(durationSeconds: effectiveCooldown);
    } else {
      setState(() {
        _errorMessage = result.message ?? context.l10nOrNull?.unableToResendCode ?? 'Unable to resend verification code.';
      });
    }
  }

  void _handleChangePhone() {
    _otpRequestGeneration++;
    _cooldownTimer?.cancel();
    setState(() {
      _isOtpSent = false;
      _isLoading = false;
      _isResending = false;
      _errorMessage = null;
      _successMessage = null;
      _activeReqId = null;
      _session = null;
      _otpController.clear();
      _secondsRemaining = 0;
    });
  }

  Future<void> _handleSignOut() async {
    _cooldownTimer?.cancel();
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
          tooltip: _isOtpSent
              ? (context.l10nOrNull?.changeNumber ?? 'Change number')
              : (context.l10nOrNull?.backToLogin ?? 'Back to login'),
        ),
        actions: [
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              context.l10nOrNull?.signOut ?? 'Sign Out',
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
                  AuthHeader(
                    title: context.l10nOrNull?.verifyYourPhone ?? 'Verify Your Phone',
                    subtitle: context.l10nOrNull?.verifyPhoneSubtitle ?? 'To prevent duplicate civic complaints and protect community authenticity, verify your mobile number via SMS.',
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
                            label: context.l10nOrNull?.mobileNumber ?? 'Mobile Number',
                            hintText: context.l10nOrNull?.mobileNumberHint ?? 'e.g. 9876543210',
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
                            text: context.l10nOrNull?.sendVerificationCode ?? 'Send Verification Code',
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
                            child: Text(context.l10nOrNull?.changeAction ?? 'Change'),
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
                            label: context.l10nOrNull?.verificationCode ?? 'Verification Code',
                            hintText: context.l10nOrNull?.verificationCodeHint ?? 'Enter 6-digit OTP',
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            enabled: !_isLoading,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return context.l10nOrNull?.pleaseEnterVerificationCode ?? 'Please enter the verification code.';
                              }
                              if (val.trim().length < 4) {
                                return context.l10nOrNull?.verificationCodeMinLength ?? 'Verification code must be at least 4 digits.';
                              }
                              return null;
                            },
                          ),
                          CivicFixSpacing.vSpaceLg,

                          CivicFixButton(
                            text: context.l10nOrNull?.verifyAndContinue ?? 'Verify & Continue',
                            onPressed: _handleVerifyOtp,
                            isLoading: _isLoading,
                          ),
                          CivicFixSpacing.vSpaceMd,

                          // Resend OTP Action & Cooldown
                          Center(
                            child: _secondsRemaining > 0
                                ? Text(
                                    context.l10nOrNull?.resendCodeInSeconds(_secondsRemaining) ??
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
                                        : Text(context.l10nOrNull?.resendVerificationCode ?? 'Resend Verification Code'),
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
