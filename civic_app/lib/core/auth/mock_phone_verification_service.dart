import 'dart:async';
import 'dart:math';
import 'phone_normalizer.dart';
import 'phone_verification_service.dart';

/// Test-isolated mock implementation of [PhoneVerificationService].
///
/// Enables complete, deterministic testing of phone OTP verification flows:
/// - Success scenarios with customizable test OTPs (e.g. '123456')
/// - Invalid OTP scenarios
/// - Expired OTP scenarios
/// - Cooldown throttle scenarios
/// - Network error simulation
class MockPhoneVerificationService implements PhoneVerificationService {
  String expectedOtp;
  bool shouldSucceed;
  String? simulatedError;
  Duration simulatedDelay;
  int cooldownDurationSeconds;

  String? lastSentPhone;
  String? lastReqId;
  int otpSendCount = 0;
  int resendCount = 0;
  DateTime? _lastSentTime;

  MockPhoneVerificationService({
    this.expectedOtp = '123456',
    this.shouldSucceed = true,
    this.simulatedError,
    this.simulatedDelay = Duration.zero,
    this.cooldownDurationSeconds = 30,
  });

  /// Resets mock state for clean test executions.
  void reset() {
    expectedOtp = '123456';
    shouldSucceed = true;
    simulatedError = null;
    simulatedDelay = Duration.zero;
    lastSentPhone = null;
    lastReqId = null;
    otpSendCount = 0;
    resendCount = 0;
    _lastSentTime = null;
  }

  /// Manually clears cooldown for rapid test assertions.
  void clearCooldown() {
    _lastSentTime = null;
  }

  @override
  int get resendCooldownSeconds {
    if (_lastSentTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentTime!).inSeconds;
    return max(0, cooldownDurationSeconds - elapsed);
  }

  @override
  bool get canResend => resendCooldownSeconds <= 0;

  @override
  Future<PhoneVerificationResult> sendOtp(String phoneNumber) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final tenDigit = PhoneNormalizer.extract10Digit(phoneNumber);
    if (tenDigit == null) {
      return const PhoneVerificationResult.failure(
        message: 'Please enter a valid 10-digit Indian mobile number.',
        errorCode: 'INVALID_PHONE_NUMBER',
      );
    }

    if (simulatedError != null) {
      return PhoneVerificationResult.failure(
        message: simulatedError!,
        errorCode: 'SIMULATED_ERROR',
      );
    }

    if (!shouldSucceed) {
      return const PhoneVerificationResult.failure(
        message: 'Failed to send OTP. Please try again.',
        errorCode: 'SEND_FAILED',
      );
    }

    otpSendCount++;
    lastSentPhone = phoneNumber;
    lastReqId = 'mock_req_${DateTime.now().millisecondsSinceEpoch}';
    _lastSentTime = DateTime.now();

    return PhoneVerificationResult.success(
      message: 'OTP sent successfully to ${PhoneNormalizer.toDisplay(phoneNumber)}.',
      reqId: lastReqId,
    );
  }

  @override
  Future<PhoneVerificationResult> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String reqId,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    if (simulatedError != null) {
      return PhoneVerificationResult.failure(
        message: simulatedError!,
        errorCode: 'SIMULATED_ERROR',
        reqId: reqId,
      );
    }

    if (!shouldSucceed) {
      return PhoneVerificationResult.failure(
        message: 'Verification failed. Please try again.',
        errorCode: 'VERIFICATION_FAILED',
        reqId: reqId,
      );
    }

    if (otp.trim() != expectedOtp) {
      return PhoneVerificationResult.failure(
        message: 'Incorrect verification code. Please check and try again.',
        errorCode: 'INVALID_OTP',
        reqId: reqId,
      );
    }

    return PhoneVerificationResult.success(
      message: 'Phone number verified successfully.',
      reqId: reqId,
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<PhoneVerificationResult> resendOtp({
    required String phoneNumber,
    required String reqId,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    if (!canResend) {
      return PhoneVerificationResult.failure(
        message: 'Please wait $resendCooldownSeconds seconds before requesting another code.',
        errorCode: 'COOLDOWN_ACTIVE',
        reqId: reqId,
      );
    }

    if (simulatedError != null) {
      return PhoneVerificationResult.failure(
        message: simulatedError!,
        errorCode: 'SIMULATED_ERROR',
        reqId: reqId,
      );
    }

    if (!shouldSucceed) {
      return PhoneVerificationResult.failure(
        message: 'Failed to resend code.',
        errorCode: 'RESEND_FAILED',
        reqId: reqId,
      );
    }

    resendCount++;
    _lastSentTime = DateTime.now();

    return PhoneVerificationResult.success(
      message: 'A new verification code has been sent.',
      reqId: reqId,
    );
  }
}
