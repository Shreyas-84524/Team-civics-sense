/// Result model representing the outcome of an OTP operation (send, verify, or retry).
class PhoneVerificationResult {
  final bool isSuccess;
  final String? message;
  final String? reqId;
  final String? accessToken;
  final String? errorCode;
  final int? cooldownSeconds;
  final int? expiresInSeconds;
  final DateTime? expiresAt;
  final int? remainingAttempts;

  const PhoneVerificationResult.success({
    this.message,
    this.reqId,
    this.accessToken,
    this.cooldownSeconds,
    this.expiresInSeconds,
    this.expiresAt,
    this.remainingAttempts,
  })  : isSuccess = true,
        errorCode = null;

  const PhoneVerificationResult.failure({
    required this.message,
    this.errorCode,
    this.reqId,
    this.cooldownSeconds,
    this.expiresInSeconds,
    this.expiresAt,
    this.remainingAttempts,
  })  : isSuccess = false,
        accessToken = null;

  @override
  String toString() =>
      'PhoneVerificationResult(isSuccess: $isSuccess, message: $message, reqId: $reqId, errorCode: $errorCode, cooldown: $cooldownSeconds, expiresAt: $expiresAt, remainingAttempts: $remainingAttempts)';
}

/// Abstract contract for Citizen Phone Number Verification services.
abstract class PhoneVerificationService {
  /// Sends an OTP to the specified phone number.
  ///
  /// The phone number is validated and normalized prior to dispatch.
  Future<PhoneVerificationResult> sendOtp(String phoneNumber);

  /// Verifies the OTP provided by the user.
  ///
  /// Takes the normalized phone number, user-entered [otp], and [reqId] from [sendOtp].
  Future<PhoneVerificationResult> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String reqId,
  });

  /// Resends or retries the OTP for the active session.
  ///
  /// Respects the resend cooldown timer.
  Future<PhoneVerificationResult> resendOtp({
    required String phoneNumber,
    required String reqId,
  });

  /// Remaining seconds before the client is permitted to trigger another OTP resend.
  int get resendCooldownSeconds;

  /// Whether the resend action is currently allowed (i.e. cooldown has expired).
  bool get canResend;
}
