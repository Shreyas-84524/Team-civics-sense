import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import 'msg91_config.dart';
import 'phone_normalizer.dart';
import 'phone_verification_service.dart';

/// Production implementation of [PhoneVerificationService] utilizing MSG91 OTP Widget.
///
/// Features:
/// - Official MSG91 Flutter OTP SDK (`sendotp_flutter_sdk`)
/// - Client-side cooldown enforcement (30-second throttle)
/// - Normalization of Indian mobile numbers (`91XXXXXXXXXX`)
/// - Strict protection of backend credentials (zero Account AuthKey in client)
class Msg91PhoneVerificationService implements PhoneVerificationService {
  static const int _cooldownDurationSeconds = 30;

  DateTime? _lastSentTime;
  bool _initialized = false;

  Msg91PhoneVerificationService();

  void _ensureWidgetInitialized() {
    if (!_initialized && Msg91Config.isConfigured) {
      OTPWidget.initializeWidget(Msg91Config.widgetId, Msg91Config.tokenAuth);
      _initialized = true;
    }
  }

  @override
  int get resendCooldownSeconds {
    if (_lastSentTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentTime!).inSeconds;
    return max(0, _cooldownDurationSeconds - elapsed);
  }

  @override
  bool get canResend => resendCooldownSeconds <= 0;

  @override
  Future<PhoneVerificationResult> sendOtp(String phoneNumber) async {
    final tenDigit = PhoneNormalizer.extract10Digit(phoneNumber);
    if (tenDigit == null) {
      return const PhoneVerificationResult.failure(
        message: 'Please enter a valid 10-digit Indian mobile number.',
        errorCode: 'INVALID_PHONE_NUMBER',
      );
    }

    if (!Msg91Config.isConfigured) {
      debugPrint('[Msg91PhoneVerificationService] MSG91 is not configured. Missing MSG91_WIDGET_ID or MSG91_TOKEN_AUTH.');
      return const PhoneVerificationResult.failure(
        message: 'SMS verification service is currently unconfigured. Please contact support.',
        errorCode: 'SERVICE_UNCONFIGURED',
      );
    }

    _ensureWidgetInitialized();

    try {
      final identifier = PhoneNormalizer.toMsg91Identifier(phoneNumber);
      final response = await OTPWidget.sendOTP({'identifier': identifier});

      if (response == null) {
        return const PhoneVerificationResult.failure(
          message: 'Unable to dispatch OTP. No response received from server.',
          errorCode: 'NO_RESPONSE',
        );
      }

      final type = response['type']?.toString().toLowerCase();
      if (type == 'success') {
        _lastSentTime = DateTime.now();
        final reqId = response['message']?.toString() ??
            response['data']?['reqId']?.toString() ??
            response['reqId']?.toString() ??
            '';

        return PhoneVerificationResult.success(
          message: 'OTP sent successfully to ${PhoneNormalizer.toDisplay(phoneNumber)}.',
          reqId: reqId,
        );
      } else {
        final rawMsg = response['message']?.toString() ?? 'Failed to send OTP.';
        final friendlyMsg = _mapErrorMessage(rawMsg);
        return PhoneVerificationResult.failure(
          message: friendlyMsg,
          errorCode: type ?? 'SEND_FAILED',
        );
      }
    } catch (e) {
      debugPrint('[Msg91PhoneVerificationService] sendOtp error: $e');
      return PhoneVerificationResult.failure(
        message: _mapExceptionMessage(e),
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  @override
  Future<PhoneVerificationResult> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String reqId,
  }) async {
    final cleanOtp = otp.trim();
    if (cleanOtp.length < 4 || cleanOtp.length > 6) {
      return const PhoneVerificationResult.failure(
        message: 'Please enter a valid verification code.',
        errorCode: 'INVALID_CODE_FORMAT',
      );
    }

    if (!Msg91Config.isConfigured) {
      return const PhoneVerificationResult.failure(
        message: 'SMS verification service is currently unconfigured.',
        errorCode: 'SERVICE_UNCONFIGURED',
      );
    }

    _ensureWidgetInitialized();

    try {
      final response = await OTPWidget.verifyOTP({
        'reqId': reqId,
        'otp': cleanOtp,
      });

      if (response == null) {
        return const PhoneVerificationResult.failure(
          message: 'Verification failed. No response received.',
          errorCode: 'NO_RESPONSE',
        );
      }

      final type = response['type']?.toString().toLowerCase();
      if (type == 'success') {
        final accessToken = response['message']?.toString() ??
            response['data']?['accessToken']?.toString() ??
            '';

        return PhoneVerificationResult.success(
          message: 'Phone number verified successfully.',
          reqId: reqId,
          accessToken: accessToken,
        );
      } else {
        final rawMsg = response['message']?.toString() ?? 'Invalid verification code.';
        final friendlyMsg = _mapErrorMessage(rawMsg);
        return PhoneVerificationResult.failure(
          message: friendlyMsg,
          errorCode: 'INVALID_OTP',
          reqId: reqId,
        );
      }
    } catch (e) {
      debugPrint('[Msg91PhoneVerificationService] verifyOtp error: $e');
      return PhoneVerificationResult.failure(
        message: _mapExceptionMessage(e),
        errorCode: 'NETWORK_ERROR',
        reqId: reqId,
      );
    }
  }

  @override
  Future<PhoneVerificationResult> resendOtp({
    required String phoneNumber,
    required String reqId,
  }) async {
    if (!canResend) {
      return PhoneVerificationResult.failure(
        message: 'Please wait $resendCooldownSeconds seconds before requesting another code.',
        errorCode: 'COOLDOWN_ACTIVE',
        reqId: reqId,
      );
    }

    if (!Msg91Config.isConfigured) {
      return const PhoneVerificationResult.failure(
        message: 'SMS verification service is currently unconfigured.',
        errorCode: 'SERVICE_UNCONFIGURED',
      );
    }

    _ensureWidgetInitialized();

    try {
      // 11 is SMS channel in MSG91 OTP widget
      final response = await OTPWidget.retryOTP({
        'reqId': reqId,
        'retryChannel': 11,
      });

      if (response == null) {
        return PhoneVerificationResult.failure(
          message: 'Unable to resend OTP. No response received.',
          errorCode: 'NO_RESPONSE',
          reqId: reqId,
        );
      }

      final type = response['type']?.toString().toLowerCase();
      if (type == 'success') {
        _lastSentTime = DateTime.now();
        return PhoneVerificationResult.success(
          message: 'A new verification code has been sent.',
          reqId: reqId,
        );
      } else {
        final rawMsg = response['message']?.toString() ?? 'Failed to resend code.';
        return PhoneVerificationResult.failure(
          message: _mapErrorMessage(rawMsg),
          errorCode: type ?? 'RESEND_FAILED',
          reqId: reqId,
        );
      }
    } catch (e) {
      debugPrint('[Msg91PhoneVerificationService] resendOtp error: $e');
      return PhoneVerificationResult.failure(
        message: _mapExceptionMessage(e),
        errorCode: 'NETWORK_ERROR',
        reqId: reqId,
      );
    }
  }

  /// Maps raw vendor error messages into clear, friendly citizen-facing text.
  String _mapErrorMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('expire')) {
      return 'The verification code has expired. Please tap Resend Code.';
    }
    if (lower.contains('mismatch') || lower.contains('invalid') || lower.contains('wrong')) {
      return 'Incorrect verification code. Please check and try again.';
    }
    if (lower.contains('limit') || lower.contains('exceed') || lower.contains('throttle')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }
    if (lower.contains('mobile') || lower.contains('number')) {
      return 'Please enter a valid mobile number.';
    }
    return rawMessage;
  }

  /// Handles network and connectivity exception messaging cleanly.
  String _mapExceptionMessage(Object exception) {
    final str = exception.toString().toLowerCase();
    if (str.contains('socket') || str.contains('connection') || str.contains('network') || str.contains('timeout')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }
    return 'Unable to complete verification. Please try again.';
  }
}
