import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'auth_service_locator.dart';
import 'phone_normalizer.dart';
import 'phone_verification_service.dart';

/// Production implementation of [PhoneVerificationService] utilizing Supabase Edge Functions.
///
/// Features:
/// - Server-authoritative OTP generation and verification via Supabase Edge Functions (`send-otp`, `verify-otp`)
/// - Authenticated with Firebase ID tokens (`Authorization: Bearer <token>`)
/// - Dynamic cooldown tracking matching backend rate limit configurations (`resend_after`, `retry_after`)
/// - Standard E.164 phone normalization (`+91XXXXXXXXXX`)
/// - Automatic post-verification profile synchronization with [AuthService]
/// - Comprehensive 16-error-code mapping for clear citizen UI feedback
class SupabasePhoneVerificationService implements PhoneVerificationService {
  static const String defaultSendOtpEndpoint =
      'https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/send-otp';
  static const String defaultVerifyOtpEndpoint =
      'https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/verify-otp';

  static const int _defaultCooldownSeconds = 30;

  final String _sendOtpUrl;
  final String _verifyOtpUrl;
  final http.Client _client;
  final FirebaseAuth? _firebaseAuth;
  final AuthService? _authService;
  final Future<String?> Function()? _tokenProvider;

  DateTime? _lastSentTime;
  int _cooldownDurationSeconds = _defaultCooldownSeconds;

  SupabasePhoneVerificationService({
    String? sendOtpUrl,
    String? verifyOtpUrl,
    http.Client? client,
    FirebaseAuth? firebaseAuth,
    AuthService? authService,
    Future<String?> Function()? tokenProvider,
  })  : _sendOtpUrl = sendOtpUrl ?? defaultSendOtpEndpoint,
        _verifyOtpUrl = verifyOtpUrl ?? defaultVerifyOtpEndpoint,
        _client = client ?? http.Client(),
        _firebaseAuth = firebaseAuth,
        _authService = authService,
        _tokenProvider = tokenProvider;

  @override
  int get resendCooldownSeconds {
    if (_lastSentTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentTime!).inSeconds;
    return max(0, _cooldownDurationSeconds - elapsed);
  }

  @override
  bool get canResend => resendCooldownSeconds <= 0;

  Future<String?> _getAuthToken() async {
    if (_tokenProvider != null) {
      return await _tokenProvider();
    }
    try {
      final user = (_firebaseAuth ?? FirebaseAuth.instance).currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      debugPrint('[SupabasePhoneVerificationService] Token acquisition notice: $e');
    }
    return null;
  }

  @override
  Future<PhoneVerificationResult> sendOtp(String phoneNumber) async {
    // 1. Upfront phone number format validation
    final tenDigit = PhoneNormalizer.extract10Digit(phoneNumber);
    if (tenDigit == null) {
      return const PhoneVerificationResult.failure(
        message: 'Please enter a valid 10-digit Indian mobile number.',
        errorCode: 'INVALID_PHONE_NUMBER',
      );
    }

    final normalizedPhone = PhoneNormalizer.toE164(phoneNumber);

    // 2. Acquire active Firebase Auth session token
    final idToken = await _getAuthToken();

    if (idToken == null || idToken.isEmpty) {
      return const PhoneVerificationResult.failure(
        message: 'You must be signed in to verify your phone number.',
        errorCode: 'UNAUTHORIZED',
      );
    }

    // 3. Dispatch HTTP POST to send-otp Edge Function
    try {
      final response = await _client
          .post(
            Uri.parse(_sendOtpUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'phone': normalizedPhone}),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> jsonBody = {};
      try {
        jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          jsonBody['success'] == true) {
        _lastSentTime = DateTime.now().toUtc();
        final resendAfter = (jsonBody['resend_after'] as num?)?.toInt() ??
            (jsonBody['cooldown_seconds'] as num?)?.toInt() ??
            (jsonBody['cooldownSeconds'] as num?)?.toInt() ??
            _defaultCooldownSeconds;
        _cooldownDurationSeconds = resendAfter;

        final expiresIn = (jsonBody['expires_in'] as num?)?.toInt() ??
            (jsonBody['expiresIn'] as num?)?.toInt() ??
            300;

        final expiresAtRaw = jsonBody['expires_at']?.toString() ??
            jsonBody['expiresAt']?.toString();
        DateTime? parsedExpiresAt;
        if (expiresAtRaw != null && expiresAtRaw.isNotEmpty) {
          try {
            parsedExpiresAt = DateTime.parse(expiresAtRaw).toUtc();
          } catch (_) {}
        }
        parsedExpiresAt ??= DateTime.now().toUtc().add(Duration(seconds: expiresIn));

        final reqId = jsonBody['request_id']?.toString() ??
            jsonBody['requestId']?.toString() ??
            jsonBody['challenge_id']?.toString() ??
            (jsonBody['data'] is Map ? (jsonBody['data']['challenge_id']?.toString() ?? jsonBody['data']['request_id']?.toString()) : null) ??
            '';

        final maskedPhone = PhoneNormalizer.mask(normalizedPhone);
        final shortReqId = reqId.length > 8 ? '${reqId.substring(0, 8)}...' : reqId;
        debugPrint('[OTP_SEND] challenge=$shortReqId, phone=$maskedPhone, cooldown=${resendAfter}s, expires_in=${expiresIn}s');

        return PhoneVerificationResult.success(
          message: 'Verification code sent via SMS to ${PhoneNormalizer.toDisplay(phoneNumber)}.',
          reqId: reqId,
          cooldownSeconds: resendAfter,
          expiresInSeconds: expiresIn,
          expiresAt: parsedExpiresAt,
        );
      } else {
        final rawError = jsonBody['error'] is Map
            ? jsonBody['error']['code']?.toString()
            : jsonBody['error']?.toString();
        final rawMsg = jsonBody['error'] is Map
            ? jsonBody['error']['message']?.toString()
            : jsonBody['message']?.toString();
        final retryAfter = (jsonBody['retry_after'] as num?)?.toInt() ??
            (jsonBody['retryAfterSeconds'] as num?)?.toInt();
        if (retryAfter != null && retryAfter > 0) {
          _lastSentTime = DateTime.now().toUtc();
          _cooldownDurationSeconds = retryAfter;
        }

        final mappedCode = _mapStatusCodeToError(response.statusCode, rawError);
        final friendlyMsg = _mapErrorMessage(mappedCode, rawMsg, jsonBody);

        debugPrint('[OTP_SEND_FAILED] status=${response.statusCode}, code=$mappedCode, error=$rawError');

        return PhoneVerificationResult.failure(
          message: friendlyMsg,
          errorCode: mappedCode,
          cooldownSeconds: retryAfter,
        );
      }
    } on TimeoutException {
      debugPrint('[OTP_SEND_TIMEOUT] send-otp request timed out after 15s');
      return const PhoneVerificationResult.failure(
        message: 'Request timed out. Please check your connection and try again.',
        errorCode: 'NETWORK_TIMEOUT',
      );
    } catch (e) {
      debugPrint('[SupabasePhoneVerificationService] sendOtp error: $e');
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
    if (cleanOtp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanOtp)) {
      return PhoneVerificationResult.failure(
        message: 'Please enter a valid 6-digit verification code.',
        errorCode: 'INVALID_OTP',
        reqId: reqId,
      );
    }

    final tenDigit = PhoneNormalizer.extract10Digit(phoneNumber);
    if (tenDigit == null) {
      return PhoneVerificationResult.failure(
        message: 'Please enter a valid 10-digit Indian mobile number.',
        errorCode: 'INVALID_PHONE_NUMBER',
        reqId: reqId,
      );
    }
    final normalizedPhone = PhoneNormalizer.toE164(phoneNumber);
    final maskedPhone = PhoneNormalizer.mask(normalizedPhone);

    if (reqId.trim().isEmpty) {
      debugPrint('[OTP_VERIFY_REJECTED] Empty challenge ID provided for $maskedPhone');
      return const PhoneVerificationResult.failure(
        message: 'Invalid verification session. Please request a new code.',
        errorCode: 'INVALID_REQUEST_ID',
      );
    }

    // Acquire active Firebase Auth session token
    final idToken = await _getAuthToken();

    if (idToken == null || idToken.isEmpty) {
      debugPrint('[OTP_VERIFY_UNAUTHORIZED] Missing Firebase ID token for $maskedPhone');
      return PhoneVerificationResult.failure(
        message: 'You must be signed in to verify your phone number.',
        errorCode: 'UNAUTHORIZED',
        reqId: reqId,
      );
    }

    final shortReqId = reqId.length > 8 ? '${reqId.substring(0, 8)}...' : reqId;
    debugPrint('[OTP_VERIFY] challenge=$shortReqId, phone=$maskedPhone, otp_len=${cleanOtp.length}');

    // Dispatch HTTP POST to verify-otp Edge Function
    try {
      final response = await _client
          .post(
            Uri.parse(_verifyOtpUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'phone': normalizedPhone,
              'request_id': reqId.trim(),
              'requestId': reqId.trim(),
              'otp': cleanOtp,
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> jsonBody = {};
      try {
        jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (jsonBody['success'] == true || jsonBody['verified'] == true)) {
        debugPrint('[OTP_VERIFY_SUCCESS] challenge=$shortReqId, phone=$maskedPhone');

        // Proactively refresh authenticated citizen profile so route guards and in-memory user sync immediately
        try {
          final auth = _authService ?? AuthServiceLocator.citizenAuth;
          await auth.checkAuthState();
        } catch (e) {
          debugPrint('[SupabasePhoneVerificationService] Post-verification profile refresh notice: $e');
        }

        return PhoneVerificationResult.success(
          message: jsonBody['message']?.toString() ?? 'Phone number verified successfully.',
          reqId: reqId,
        );
      } else {
        final rawError = jsonBody['error'] is Map
            ? jsonBody['error']['code']?.toString()
            : jsonBody['error']?.toString();
        final rawMsg = jsonBody['error'] is Map
            ? jsonBody['error']['message']?.toString()
            : jsonBody['message']?.toString();
        final mappedCode = _mapStatusCodeToError(response.statusCode, rawError);
        final friendlyMsg = _mapErrorMessage(mappedCode, rawMsg, jsonBody);

        final remaining = (jsonBody['remaining_attempts'] as num?)?.toInt() ??
            (jsonBody['remainingAttempts'] as num?)?.toInt() ??
            (jsonBody['attempts_remaining'] as num?)?.toInt();

        debugPrint('[OTP_VERIFY_FAILED] challenge=$shortReqId, status=${response.statusCode}, code=$mappedCode, remaining=$remaining');

        return PhoneVerificationResult.failure(
          message: friendlyMsg,
          errorCode: mappedCode,
          reqId: reqId,
          remainingAttempts: remaining,
        );
      }
    } on TimeoutException {
      debugPrint('[OTP_VERIFY_TIMEOUT] verify-otp request timed out after 15s');
      return PhoneVerificationResult.failure(
        message: 'Verification timed out. Please check your connection and try again.',
        errorCode: 'NETWORK_TIMEOUT',
        reqId: reqId,
      );
    } catch (e) {
      debugPrint('[SupabasePhoneVerificationService] verifyOtp error: $e');
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
        cooldownSeconds: resendCooldownSeconds,
      );
    }

    return sendOtp(phoneNumber);
  }

  /// Maps HTTP status codes to standardized error codes if the server response lacks one.
  String _mapStatusCodeToError(int statusCode, String? errorField) {
    if (errorField != null && errorField.isNotEmpty) {
      return errorField;
    }
    switch (statusCode) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 404:
        return 'CHALLENGE_NOT_FOUND';
      case 409:
        return 'PHONE_ALREADY_IN_USE';
      case 410:
        return 'OTP_EXPIRED';
      case 429:
        return 'TOO_MANY_ATTEMPTS';
      case 500:
        return 'INTERNAL_ERROR';
      case 502:
      case 503:
      case 504:
        return 'SERVICE_UNAVAILABLE';
      default:
        return 'INTERNAL_ERROR';
    }
  }

  /// Maps canonical backend error codes to clear, friendly citizen-facing text.
  String _mapErrorMessage(String errorCode, String? rawMessage, Map<String, dynamic> jsonBody) {
    switch (errorCode) {
      case 'INVALID_PHONE_NUMBER':
      case 'INVALID_PHONE':
        return 'Please enter a valid 10-digit Indian mobile number.';

      case 'INVALID_REQUEST_ID':
        return 'Invalid verification session. Please request a new code.';

      case 'INVALID_OTP':
      case 'INVALID_OTP_FORMAT':
        final remaining = (jsonBody['remaining_attempts'] as num?)?.toInt() ??
            (jsonBody['remainingAttempts'] as num?)?.toInt() ??
            (jsonBody['attempts_remaining'] as num?)?.toInt();
        if (remaining != null && remaining > 0) {
          return 'Incorrect verification code. $remaining attempt${remaining == 1 ? "" : "s"} remaining.';
        }
        return 'Incorrect verification code. Please check the code and try again.';

      case 'OTP_EXPIRED':
      case 'CHALLENGE_EXPIRED':
        return 'This verification code has expired. Please request a new code.';

      case 'OTP_ALREADY_USED':
      case 'ALREADY_CONSUMED':
        return 'This verification code has already been used. Please request a new code.';

      case 'TOO_MANY_ATTEMPTS':
      case 'MAX_ATTEMPTS_EXCEEDED':
        return 'Maximum verification attempts exceeded. Please request a new code.';

      case 'CHALLENGE_NOT_FOUND':
        return 'Verification session not found or expired. Please request a new code.';

      case 'PHONE_MISMATCH':
      case 'CHALLENGE_MISMATCH':
        return 'Phone number does not match verification session. Please request a new code.';

      case 'PHONE_ALREADY_IN_USE':
      case 'PHONE_ALREADY_REGISTERED':
      case 'PHONE_ALREADY_LINKED':
        return 'This phone number is already linked to another CivicFix account.';

      case 'RATE_LIMITED':
      case 'RATE_LIMIT_COOLDOWN':
      case 'COOLDOWN_ACTIVE':
        final retryAfter = (jsonBody['retry_after'] as num?)?.toInt() ??
            (jsonBody['retryAfterSeconds'] as num?)?.toInt();
        if (retryAfter != null && retryAfter > 0) {
          return 'Please wait $retryAfter seconds before requesting another code.';
        }
        return 'Please wait before requesting another verification code.';

      case 'RATE_LIMIT_HOURLY':
      case 'HOURLY_LIMIT_EXCEEDED':
        return 'Hourly verification limit reached. Please try again later.';

      case 'RATE_LIMIT_DAILY':
      case 'DAILY_LIMIT_EXCEEDED':
        return 'Daily verification limit reached. Please try again tomorrow.';

      case 'UNAUTHORIZED':
        return 'Your session has expired. Please sign in again.';

      case 'SMS_GATEWAY_NOT_CONFIGURED':
      case 'SERVICE_UNAVAILABLE':
      case 'BOOT_ERROR':
        return 'Verification service is temporarily unavailable. Please try again shortly.';

      case 'GATEWAY_DELIVERY_FAILED':
        return 'Unable to dispatch SMS to your number at this time. Please try again in a moment.';

      case 'IDENTITY_SYNC_FAILED':
        return 'Phone verified, but profile update failed. Please refresh or try again.';

      case 'INTERNAL_ERROR':
        return 'Unable to complete phone verification right now. Please try again.';

      default:
        return rawMessage ?? 'Unable to complete phone verification right now. Please try again.';
    }
  }

  /// Handles network and connectivity exception messaging cleanly, distinguishing
  /// genuine device offline / DNS issues from backend 5xx / boot / connection terminations.
  String _mapExceptionMessage(Object exception) {
    final str = exception.toString().toLowerCase();

    // 1. Backend 5xx, worker boot failure, or server-side connection drops
    if (str.contains('503') ||
        str.contains('502') ||
        str.contains('500') ||
        str.contains('504') ||
        str.contains('boot_error') ||
        str.contains('connection closed') ||
        str.contains('connection reset') ||
        str.contains('connection refused') ||
        str.contains('service unavailable')) {
      return 'Verification service is temporarily unavailable. Please try again shortly.';
    }

    // 2. Genuine client-side offline / DNS failure
    if (str.contains('failed host lookup') ||
        str.contains('no address associated') ||
        str.contains('network is unreachable') ||
        str.contains('socketexception') ||
        str.contains('no internet') ||
        str.contains('network_error')) {
      return 'No internet connection. Please check your connection and try again.';
    }

    // 3. Timeout
    if (str.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    return 'Unable to complete phone verification right now. Please try again.';
  }
}
