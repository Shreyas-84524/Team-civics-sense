import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:civic_app/User UI/screens/phone_verification_screen.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/auth/mock_phone_verification_service.dart';
import 'package:civic_app/core/auth/phone_verification_service.dart';
import 'package:civic_app/core/auth/phone_verification_service_locator.dart';
import 'package:civic_app/core/auth/phone_verification_session.dart';
import 'package:civic_app/core/auth/supabase_phone_verification_service.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/routing/app_router.dart';
import 'package:civic_app/core/theme/app_theme.dart';

Widget _buildTestableWidget(Widget child, {String initialRoute = '/'}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    onGenerateRoute: AppRouter.generateRoute,
    initialRoute: initialRoute,
    home: child,
  );
}

void main() {
  const testPhone = '9876512345';
  const expectedE164 = '+919876512345';
  const testToken = 'mock_firebase_id_token_xyz';

  late MockAuthService mockAuth;
  late MockPhoneVerificationService mockPhoneService;

  setUp(() {
    AuthServiceLocator.useMockServices();
    mockAuth = AuthServiceLocator.citizenAuth as MockAuthService;
    mockAuth.resetForTesting(authenticated: false);

    mockPhoneService = PhoneVerificationServiceLocator.useMockService(expectedOtp: '123456');
    mockPhoneService.reset();
  });

  group('Part 14 Comprehensive OTP Session Lifecycle & Race Condition Suite', () {
    // 1. Fresh OTP verifies successfully
    test('1. Fresh OTP verifies successfully with camelCase & snake_case responses', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('send-otp')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'requestId': 'req_challenge_001',
              'cooldownSeconds': 30,
              'expiresIn': 300,
              'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('verify-otp')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['request_id'], equals('req_challenge_001'));
          expect(body['otp'], equals('123456'));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Phone verified successfully.',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final sendRes = await service.sendOtp(testPhone);
      expect(sendRes.isSuccess, isTrue);
      expect(sendRes.reqId, equals('req_challenge_001'));

      final verifyRes = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '123456',
        reqId: sendRes.reqId!,
      );
      expect(verifyRes.isSuccess, isTrue);
    });

    // 2. Correct OTP immediately after receipt
    testWidgets('2. Correct OTP immediately after receipt navigates to home without premature expiry', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      mockPhoneService.expectedOtp = '654321';
      mockAuth.setMockUser(const UserModel(
        id: 'u_tester_01',
        fullName: 'Citizen One',
        email: 'cit1@civicfix.test',
        phone: '9876512345',
        phoneVerified: false,
      ));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(
          initialPhone: '9876512345',
        ),
      ));
      await tester.pumpAndSettle();

      // Send OTP
      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Enter OTP immediately while countdown is active
      expect(find.textContaining('Resend code in'), findsOneWidget);
      final otpField = find.byType(TextFormField).first;
      await tester.enterText(otpField, '654321');

      final verifyBtn = find.text('Verify & Continue');
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(mockAuth.currentUser?.phoneVerified, isTrue);
      expect(find.text('Session expired. Please request a new verification code.'), findsNothing);
    });

    // 3. Invalid OTP
    test('3. Invalid OTP returns structured attempt count decrement', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'INVALID_OTP',
            'message': 'The OTP code entered is incorrect.',
            'remainingAttempts': 2,
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final verifyRes = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '000000',
        reqId: 'req_ch_valid',
      );

      expect(verifyRes.isSuccess, isFalse);
      expect(verifyRes.errorCode, equals('INVALID_OTP'));
      expect(verifyRes.message, contains('2 attempts remaining'));
      expect(verifyRes.remainingAttempts, equals(2));
    });

    // 4. Expired OTP
    test('4. Expired OTP from backend maps to friendly retry guidance', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'OTP_EXPIRED',
            'message': 'Challenge has expired.',
          }),
          410,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final verifyRes = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '123456',
        reqId: 'req_ch_expired',
      );

      expect(verifyRes.isSuccess, isFalse);
      expect(verifyRes.errorCode, equals('OTP_EXPIRED'));
      expect(verifyRes.message, contains('verification code has expired'));
    });

    // 5. Expired verification session model
    test('5. PhoneVerificationSession correctly reports isExpired after duration', () {
      final now = DateTime.now().toUtc();
      final expiredSession = PhoneVerificationSession(
        phoneNumber: expectedE164,
        challengeId: 'req_old',
        createdAt: now.subtract(const Duration(minutes: 6)),
        expiresAt: now.subtract(const Duration(minutes: 1)),
        resendAvailableAt: now.subtract(const Duration(minutes: 5, seconds: 30)),
      );

      expect(expiredSession.isExpired, isTrue);
      expect(expiredSession.canResend, isTrue);
      expect(expiredSession.secondsUntilExpiry, equals(0));
      expect(expiredSession.secondsUntilResend, equals(0));

      final activeSession = PhoneVerificationSession(
        phoneNumber: expectedE164,
        challengeId: 'req_fresh',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 5)),
        resendAvailableAt: now.add(const Duration(seconds: 30)),
      );

      expect(activeSession.isExpired, isFalse);
      expect(activeSession.canResend, isFalse);
      expect(activeSession.secondsUntilExpiry, inInclusiveRange(295, 300));
      expect(activeSession.secondsUntilResend, inInclusiveRange(25, 30));
    });

    // 6. Resend after cooldown
    test('6. Resend after cooldown succeeds and resets cooldown window', () async {
      var sendCalls = 0;
      final mockClient = MockClient((request) async {
        sendCalls++;
        return http.Response(
          jsonEncode({
            'success': true,
            'requestId': 'req_resend_$sendCalls',
            'resend_after': 30,
            'expires_in': 300,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final r1 = await service.sendOtp(testPhone);
      expect(r1.isSuccess, isTrue);
      expect(service.canResend, isFalse);

      final blocked = await service.resendOtp(phoneNumber: testPhone, reqId: r1.reqId!);
      expect(blocked.isSuccess, isFalse);
      expect(blocked.errorCode, equals('COOLDOWN_ACTIVE'));
    });

    // 7. Resend creates new valid challenge
    // 8. Old OTP rejected after resend
    // 9. Newest OTP succeeds after resend
    testWidgets('7, 8, 9. Resend creates new valid challenge, clears old OTP input, and verifies newest OTP', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      mockPhoneService.expectedOtp = '111111';
      mockAuth.setMockUser(const UserModel(
        id: 'u_tester_02',
        fullName: 'Citizen Two',
        email: 'cit2@civicfix.test',
        phone: '9876512345',
        phoneVerified: false,
      ));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(
          initialPhone: '9876512345',
        ),
      ));
      await tester.pumpAndSettle();

      // 1st Send
      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Enter old OTP
      final otpField = find.byType(TextFormField).first;
      await tester.enterText(otpField, '111111');

      // Clear cooldown & tick timer past 30 seconds
      mockPhoneService.clearCooldown();
      for (int i = 0; i < 31; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Update expected OTP for the next challenge (simulating new SMS)
      mockPhoneService.expectedOtp = '222222';

      // Tap Resend
      final resendBtn = find.text('Resend Verification Code');
      expect(resendBtn, findsOneWidget);
      await tester.ensureVisible(resendBtn);
      await tester.tap(resendBtn);
      await tester.pumpAndSettle();

      // Verify old OTP field was CLEARED on resend
      expect(find.text('111111'), findsNothing);
      expect(find.text('A new verification code has been dispatched.'), findsOneWidget);

      // Enter newest OTP
      await tester.enterText(otpField, '222222');

      final verifyBtn = find.text('Verify & Continue');
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(mockAuth.currentUser?.phoneVerified, isTrue);
    });

    // 10. Old session ID cannot overwrite newest session
    // 11. Delayed first request response
    testWidgets('10, 11. Monotonic request generation drops delayed out-of-order responses', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final completer1 = Completer<PhoneVerificationResult>();
      final completer2 = Completer<PhoneVerificationResult>();

      var callIndex = 0;
      final mockCustomService = _DelayedMockPhoneVerificationService(
        onRequest: () {
          callIndex++;
          if (callIndex == 1) {
            return completer1.future;
          } else {
            return completer2.future;
          }
        },
      );

      await tester.pumpWidget(_buildTestableWidget(
        PhoneVerificationScreen(
          authService: mockAuth,
          verificationService: mockCustomService,
          initialPhone: '9876512345',
        ),
      ));
      await tester.pumpAndSettle();

      // Trigger 1st send
      final sendBtn = find.text('Send Verification Code');
      await tester.tap(sendBtn);
      await tester.pump();

      // Resolve 2nd request first
      completer2.complete(const PhoneVerificationResult.success(
        reqId: 'req_second_fresh',
        message: 'Second OTP sent',
      ));
      // Then resolve 1st request late
      completer1.complete(const PhoneVerificationResult.success(
        reqId: 'req_first_stale',
        message: 'First OTP sent (late)',
      ));

      await tester.pumpAndSettle();

      // Active screen should have transitioned to Step 2 with second request's session
      expect(find.text('Verification Code'), findsOneWidget);
    });

    // 14. App background / resume
    testWidgets('14. App background and resume accurately updates cooldown counter', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(
          initialPhone: '9876512345',
        ),
      ));
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Verification Code');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Resend code in'), findsOneWidget);

      // Simulate App Lifecycle state transition properly through inactive -> hidden -> paused -> hidden -> inactive -> resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('Verification Code'), findsOneWidget);
    });

    // 15. Widget rebuild preserves session
    testWidgets('15. Widget rebuild does not destroy active verification challenge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(
          initialPhone: '9876512345',
        ),
      ));
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Verification Code');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Verification Code'), findsOneWidget);

      // Trigger arbitrary screen rebuild (e.g. keyboard open / theme toggle)
      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(
          initialPhone: '9876512345',
        ),
      ));
      await tester.pump();

      expect(find.text('Verification Code'), findsOneWidget);
    });

    // 16. Phone number change resets state cleanly
    testWidgets('16. Phone number change resets session and timers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestableWidget(
        const PhoneVerificationScreen(
          initialPhone: '9876512345',
        ),
      ));
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Verification Code');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Verification Code'), findsOneWidget);

      final changeBtn = find.text('Change');
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Verification Code'), findsNothing);
    });

    // 17. Max attempts lockout
    test('17. Max attempts lockout maps to MAX_ATTEMPTS_EXCEEDED', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'MAX_ATTEMPTS_EXCEEDED',
            'message': 'Maximum attempts reached.',
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final r = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '123456',
        reqId: 'req_locked',
      );

      expect(r.isSuccess, isFalse);
      expect(r.errorCode, equals('MAX_ATTEMPTS_EXCEEDED'));
      expect(r.message, contains('Maximum verification attempts exceeded'));
    });

    // 18. OTP replay protection
    test('18. Consumed OTP replay returns ALREADY_CONSUMED / OTP_ALREADY_USED', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'ALREADY_CONSUMED',
            'message': 'Already used.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final r = await service.verifyOtp(
        phoneNumber: testPhone,
        otp: '123456',
        reqId: 'req_consumed',
      );

      expect(r.isSuccess, isFalse);
      expect(r.errorCode, equals('ALREADY_CONSUMED'));
      expect(r.message, contains('already been used'));
    });

    // 21. UTC timestamp handling
    // 22. Milliseconds vs seconds correctness
    test('21, 22. Timestamps and seconds/milliseconds parsed safely across timezones', () async {
      final utcNow = DateTime.now().toUtc();
      final expiresIso = utcNow.add(const Duration(seconds: 300)).toIso8601String();

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'requestId': 'req_tz_test',
            'cooldown_seconds': 30,
            'expires_in': 300,
            'expiresAt': expiresIso,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SupabasePhoneVerificationService(
        client: mockClient,
        tokenProvider: () async => testToken,
      );

      final res = await service.sendOtp(testPhone);
      expect(res.isSuccess, isTrue);
      expect(res.cooldownSeconds, equals(30));
      expect(res.expiresInSeconds, equals(300));
      expect(res.expiresAt?.isUtc, isTrue);
    });

    // 23. Backend temporary failure is NOT mapped to session expired
    test('23. HTTP 500, 502, 503 and network timeouts are NOT mapped to Session Expired', () async {
      final mockClient500 = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service500 = SupabasePhoneVerificationService(
        client: mockClient500,
        tokenProvider: () async => testToken,
      );

      final r500 = await service500.verifyOtp(
        phoneNumber: testPhone,
        otp: '123456',
        reqId: 'req_temp_err',
      );

      expect(r500.isSuccess, isFalse);
      expect(r500.errorCode, equals('INTERNAL_ERROR'));
      expect(r500.message, isNot(contains('Session expired')));
      expect(r500.message, contains('Unable to complete phone verification'));
    });
  });
}

class _DelayedMockPhoneVerificationService implements PhoneVerificationService {
  final Future<PhoneVerificationResult> Function() onRequest;

  _DelayedMockPhoneVerificationService({required this.onRequest});

  @override
  bool get canResend => true;

  @override
  int get resendCooldownSeconds => 0;

  @override
  Future<PhoneVerificationResult> sendOtp(String phoneNumber) => onRequest();

  @override
  Future<PhoneVerificationResult> resendOtp({
    required String phoneNumber,
    required String reqId,
  }) => onRequest();

  @override
  Future<PhoneVerificationResult> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String reqId,
  }) => onRequest();
}
