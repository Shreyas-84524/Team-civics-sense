import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:civic_app/core/auth/auth_service.dart';
import 'package:civic_app/core/auth/supabase_phone_verification_service.dart';

void main() {
  const testPhone = '9876543210';
  const expectedE164 = '+919876543210';
  const testToken = 'mock_firebase_id_token_12345';
  const testReqId = 'req_mock_session_uuid_001';

  group('SupabasePhoneVerificationService - sendOtp Tests', () {
    test('Rejects invalid phone numbers without making HTTP request', () async {
      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final result = await service.sendOtp('12345');
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('INVALID_PHONE_NUMBER'));
      expect(result.message, equals('Please enter a valid 10-digit Indian mobile number.'));
      expect(requestMade, isFalse);
    });

    test('Fails with UNAUTHORIZED if no Firebase token is available', () async {
      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => null, // Unauthenticated
      );

      final result = await service.sendOtp(testPhone);
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('UNAUTHORIZED'));
      expect(result.message, contains('must be signed in'));
      expect(requestMade, isFalse);
    });

    test('Sends OTP successfully, parses response, and sets cooldown', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(
          request.url.toString(),
          equals(SupabasePhoneVerificationService.defaultSendOtpEndpoint),
        );
        expect(request.headers['Authorization'], equals('Bearer $testToken'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['phone'], equals(expectedE164));

        return http.Response(
          jsonEncode({
            'success': true,
            'request_id': testReqId,
            'expires_in': 300,
            'resend_after': 30,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      expect(service.canResend, isTrue);
      expect(service.resendCooldownSeconds, equals(0));

      final result = await service.sendOtp(testPhone);

      expect(result.isSuccess, isTrue);
      expect(result.reqId, equals(testReqId));
      expect(result.message, contains('Verification code sent'));
      expect(service.canResend, isFalse);
      expect(service.resendCooldownSeconds, inInclusiveRange(28, 30));
    });

    test('Handles 409 PHONE_ALREADY_REGISTERED error cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'PHONE_ALREADY_REGISTERED',
            'message': 'This phone number is already registered to another account.',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final result = await service.sendOtp(testPhone);
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('PHONE_ALREADY_REGISTERED'));
      expect(
        result.message,
        equals('This phone number is already associated with another CivicFix account.'),
      );
    });

    test('Handles 429 RATE_LIMIT_COOLDOWN and applies retry_after to cooldown', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'RATE_LIMIT_COOLDOWN',
            'message': 'Please wait before requesting another code.',
            'retry_after': 45,
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final result = await service.sendOtp(testPhone);
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('RATE_LIMIT_COOLDOWN'));
      expect(result.message, contains('wait 45 seconds'));
      expect(service.canResend, isFalse);
      expect(service.resendCooldownSeconds, inInclusiveRange(43, 45));
    });

    test('Handles 429 RATE_LIMIT_HOURLY and RATE_LIMIT_DAILY', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        final error = callCount == 1 ? 'RATE_LIMIT_HOURLY' : 'RATE_LIMIT_DAILY';
        return http.Response(
          jsonEncode({
            'success': false,
            'error': error,
            'message': 'Rate limit exceeded',
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final r1 = await service.sendOtp(testPhone);
      expect(r1.isSuccess, isFalse);
      expect(r1.errorCode, equals('RATE_LIMIT_HOURLY'));
      expect(r1.message, equals('Hourly verification limit reached. Please try again later.'));

      final r2 = await service.sendOtp(testPhone);
      expect(r2.isSuccess, isFalse);
      expect(r2.errorCode, equals('RATE_LIMIT_DAILY'));
      expect(r2.message, equals('Daily verification limit reached. Please try again tomorrow.'));
    });

    test('Handles 500 SMS_GATEWAY_NOT_CONFIGURED and 502 GATEWAY_DELIVERY_FAILED', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': 'SMS_GATEWAY_NOT_CONFIGURED',
              'message': 'Gateway not configured',
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': 'GATEWAY_DELIVERY_FAILED',
              'message': 'Gateway delivery failed',
            }),
            502,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final r1 = await service.sendOtp(testPhone);
      expect(r1.errorCode, equals('SMS_GATEWAY_NOT_CONFIGURED'));
      expect(r1.message, contains('SMS gateway service is temporarily unavailable'));

      final r2 = await service.sendOtp(testPhone);
      expect(r2.errorCode, equals('GATEWAY_DELIVERY_FAILED'));
      expect(r2.message, contains('Unable to dispatch SMS'));
    });

    test('Handles network connection errors and timeouts', () async {
      final timeoutClient = MockClient((request) async {
        throw TimeoutException('Simulated request timeout');
      });

      final service = SupabasePhoneVerificationService(
        client: timeoutClient,
        tokenProvider: () async => testToken,
      );

      final timeoutResult = await service.sendOtp(testPhone);
      expect(timeoutResult.isSuccess, isFalse);
      expect(timeoutResult.errorCode, equals('NETWORK_TIMEOUT'));
      expect(timeoutResult.message, contains('Request timed out'));

      final socketErrorClient = MockClient((request) async {
        throw http.ClientException('Failed host lookup');
      });

      final service2 = SupabasePhoneVerificationService(
        client: socketErrorClient,
        tokenProvider: () async => testToken,
      );

      final networkResult = await service2.sendOtp(testPhone);
      expect(networkResult.isSuccess, isFalse);
      expect(networkResult.errorCode, equals('NETWORK_ERROR'));
      expect(networkResult.message, contains('Network connection issue'));
    });
  });

  group('SupabasePhoneVerificationService - verifyOtp Tests', () {
    test('Rejects invalid OTP formats without making HTTP request', () async {
      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      // Short OTP
      final r1 = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '12345',
        reqId: testReqId,
      );
      expect(r1.isSuccess, isFalse);
      expect(r1.errorCode, equals('INVALID_OTP'));
      expect(r1.message, equals('Please enter a valid 6-digit verification code.'));

      // Non-digits
      final r2 = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '12345a',
        reqId: testReqId,
      );
      expect(r2.isSuccess, isFalse);
      expect(r2.errorCode, equals('INVALID_OTP'));

      // Empty reqId
      final r3 = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '123456',
        reqId: '',
      );
      expect(r3.isSuccess, isFalse);
      expect(r3.errorCode, equals('INVALID_REQUEST_ID'));

      expect(requestMade, isFalse);
    });

    test('Verifies OTP successfully, dispatches payload, and triggers auth sync', () async {
      var authSyncCalled = false;
      // Attach a listener/hook to checkAuthState
      final customAuth = _TestAuthService(onCheckAuthState: () {
        authSyncCalled = true;
      });

      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(
          request.url.toString(),
          equals(SupabasePhoneVerificationService.defaultVerifyOtpEndpoint),
        );
        expect(request.headers['Authorization'], equals('Bearer $testToken'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['phone'], equals(expectedE164));
        expect(body['request_id'], equals(testReqId));
        expect(body['otp'], equals('654321'));

        return http.Response(
          jsonEncode({
            'success': true,
            'phone': expectedE164,
            'phoneVerified': true,
            'message': 'Phone number verified successfully.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
        authService: customAuth,
      );

      final result = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '654321',
        reqId: testReqId,
      );

      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Phone number verified successfully.'));
      expect(result.reqId, equals(testReqId));
      expect(authSyncCalled, isTrue);
    });

    test('Handles INVALID_OTP with remaining attempts', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'INVALID_OTP',
            'message': 'Incorrect verification code.',
            'remaining_attempts': 2,
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final result = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '000000',
        reqId: testReqId,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, equals('INVALID_OTP'));
      expect(result.message, equals('Incorrect verification code. 2 attempts remaining.'));
      expect(result.reqId, equals(testReqId));
    });

    test('Handles OTP_EXPIRED, OTP_ALREADY_USED, and MAX_ATTEMPTS_EXCEEDED', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        final errors = ['OTP_EXPIRED', 'OTP_ALREADY_USED', 'MAX_ATTEMPTS_EXCEEDED'];
        return http.Response(
          jsonEncode({
            'success': false,
            'error': errors[callCount - 1],
            'message': 'Error',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final r1 = await service.verifyOtp(phoneNumber: testPhone, otp: '111111', reqId: testReqId);
      expect(r1.errorCode, equals('OTP_EXPIRED'));
      expect(r1.message, contains('expired'));

      final r2 = await service.verifyOtp(phoneNumber: testPhone, otp: '222222', reqId: testReqId);
      expect(r2.errorCode, equals('OTP_ALREADY_USED'));
      expect(r2.message, contains('already been used'));

      final r3 = await service.verifyOtp(phoneNumber: testPhone, otp: '333333', reqId: testReqId);
      expect(r3.errorCode, equals('MAX_ATTEMPTS_EXCEEDED'));
      expect(r3.message, contains('Maximum verification attempts exceeded'));
    });

    test('Handles 404 CHALLENGE_NOT_FOUND and 500 IDENTITY_SYNC_FAILED', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': 'CHALLENGE_NOT_FOUND',
              'message': 'Challenge not found',
            }),
            404,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': 'IDENTITY_SYNC_FAILED',
              'message': 'Identity sync failed',
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final r1 = await service.verifyOtp(phoneNumber: testPhone, otp: '111111', reqId: testReqId);
      expect(r1.errorCode, equals('CHALLENGE_NOT_FOUND'));
      expect(r1.message, contains('not found or expired'));

      final r2 = await service.verifyOtp(phoneNumber: testPhone, otp: '222222', reqId: testReqId);
      expect(r2.errorCode, equals('IDENTITY_SYNC_FAILED'));
      expect(r2.message, contains('Phone verified, but profile update failed'));
    });
  });

  group('SupabasePhoneVerificationService - resendOtp & Cooldown Tests', () {
    test('resendOtp enforces client cooldown timer', () async {
      var sendCalls = 0;
      final mockClient = MockClient((request) async {
        sendCalls++;
        return http.Response(
          jsonEncode({
            'success': true,
            'request_id': 'req_resend_$sendCalls',
            'expires_in': 300,
            'resend_after': 30,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      // First send
      final sendResult = await service.sendOtp(testPhone);
      expect(sendResult.isSuccess, isTrue);
      expect(sendCalls, equals(1));
      expect(service.canResend, isFalse);

      // Attempt immediate resend -> blocked by cooldown
      final blockedResult = await service.resendOtp(
        phoneNumber: testPhone,
        reqId: sendResult.reqId!,
      );
      expect(blockedResult.isSuccess, isFalse);
      expect(blockedResult.errorCode, equals('COOLDOWN_ACTIVE'));
      expect(blockedResult.message, contains('Please wait'));
      expect(sendCalls, equals(1)); // No second HTTP call made
    });
  });
}

class _TestAuthService implements AuthService {
  final void Function() onCheckAuthState;
  _TestAuthService({required this.onCheckAuthState});

  @override
  Future<bool> checkAuthState() async {
    onCheckAuthState();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
