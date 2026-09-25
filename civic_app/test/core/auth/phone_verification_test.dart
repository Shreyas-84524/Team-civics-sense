import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/auth/mock_phone_verification_service.dart';
import 'package:civic_app/core/auth/msg91_config.dart';
import 'package:civic_app/core/auth/msg91_phone_verification_service.dart';
import 'package:civic_app/core/auth/phone_normalizer.dart';
import 'package:civic_app/core/auth/phone_verification_service_locator.dart';
import 'package:civic_app/core/firebase/mappers/user_firestore_mapper.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneNormalizer Indian Mobile Utility Tests', () {
    test('Validates and extracts 10-digit Indian subscriber number', () {
      expect(PhoneNormalizer.extract10Digit('9876543210'), '9876543210');
      expect(PhoneNormalizer.extract10Digit('+91 98765 43210'), '9876543210');
      expect(PhoneNormalizer.extract10Digit('+91-98765-43210'), '9876543210');
      expect(PhoneNormalizer.extract10Digit('09876543210'), '9876543210');
      expect(PhoneNormalizer.extract10Digit('919876543210'), '9876543210');

      // Valid prefixes (6, 7, 8, 9)
      expect(PhoneNormalizer.isValidIndianMobile('6123456789'), isTrue);
      expect(PhoneNormalizer.isValidIndianMobile('7123456789'), isTrue);
      expect(PhoneNormalizer.isValidIndianMobile('8123456789'), isTrue);
      expect(PhoneNormalizer.isValidIndianMobile('9123456789'), isTrue);
    });

    test('Rejects invalid phone numbers and foreign/invalid prefixes', () {
      // Invalid start prefixes (1-5)
      expect(PhoneNormalizer.isValidIndianMobile('5123456789'), isFalse);
      expect(PhoneNormalizer.isValidIndianMobile('1234567890'), isFalse);
      expect(PhoneNormalizer.isValidIndianMobile('0123456789'), isFalse);

      // Invalid lengths
      expect(PhoneNormalizer.isValidIndianMobile('98765'), isFalse);
      expect(PhoneNormalizer.isValidIndianMobile('9876543210123'), isFalse);

      // Non-digits
      expect(PhoneNormalizer.isValidIndianMobile('98765abcde'), isFalse);
      expect(PhoneNormalizer.isValidIndianMobile(''), isFalse);
      expect(PhoneNormalizer.isValidIndianMobile('   '), isFalse);
    });

    test('Formats correctly for MSG91 (91XXXXXXXXXX) and E.164 (+91XXXXXXXXXX)', () {
      const raw = '9876543210';
      expect(PhoneNormalizer.toMsg91Identifier(raw), '919876543210');
      expect(PhoneNormalizer.toE164(raw), '+919876543210');
      expect(PhoneNormalizer.toDisplay(raw), '+91 98765 43210');

      expect(PhoneNormalizer.toMsg91Identifier('+91 98765 43210'), '919876543210');
      expect(PhoneNormalizer.toE164('+91 98765 43210'), '+919876543210');
      expect(PhoneNormalizer.toDisplay('09876543210'), '+91 98765 43210');
    });

    test('Throws FormatException on formatting invalid numbers', () {
      expect(() => PhoneNormalizer.toMsg91Identifier('12345'), throwsFormatException);
      expect(() => PhoneNormalizer.toE164('invalid'), throwsFormatException);
    });

    test('Validation method returns clear user-facing errors for UI forms', () {
      expect(PhoneNormalizer.validate(''), contains('Please enter'));
      expect(PhoneNormalizer.validate('   '), contains('Please enter'));
      expect(PhoneNormalizer.validate('98765'), contains('10 digits'));
      expect(PhoneNormalizer.validate('5123456789'), contains('6, 7, 8, or 9'));
      expect(PhoneNormalizer.validate('98765abcde'), contains('digits only'));
      expect(PhoneNormalizer.validate('9876543210'), isNull);
      expect(PhoneNormalizer.validate('+91 98765 43210'), isNull);
    });
  });

  group('Msg91Config Environment Safety Tests', () {
    test('Default values do not embed secrets and report unconfigured safely', () {
      // In testing without --dart-define, widgetId and tokenAuth are empty strings
      expect(Msg91Config.widgetId, isA<String>());
      expect(Msg91Config.tokenAuth, isA<String>());
      // Master AuthKey is intentionally absent from client codebase
    });
  });

  group('MockPhoneVerificationService Flow & Cooldown Tests', () {
    late MockPhoneVerificationService service;

    setUp(() {
      service = MockPhoneVerificationService(expectedOtp: '654321');
    });

    test('sendOtp rejects invalid phone numbers upfront', () async {
      final result = await service.sendOtp('12345');
      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'INVALID_PHONE_NUMBER');
      expect(result.message, contains('10-digit'));
    });

    test('sendOtp sends OTP, records session, and triggers cooldown', () async {
      final result = await service.sendOtp('9876543210');
      expect(result.isSuccess, isTrue);
      expect(result.reqId, isNotNull);
      expect(service.lastSentPhone, '9876543210');
      expect(service.otpSendCount, 1);
      expect(service.canResend, isFalse);
      expect(service.resendCooldownSeconds, greaterThan(0));
    });

    test('verifyOtp succeeds with matching OTP and fails with mismatched OTP', () async {
      final sendResult = await service.sendOtp('9876543210');

      // Invalid OTP
      final badResult = await service.verifyOtp(
        phoneNumber: '9876543210',
        otp: '000000',
        reqId: sendResult.reqId!,
      );
      expect(badResult.isSuccess, isFalse);
      expect(badResult.errorCode, 'INVALID_OTP');

      // Valid OTP
      final goodResult = await service.verifyOtp(
        phoneNumber: '9876543210',
        otp: '654321',
        reqId: sendResult.reqId!,
      );
      expect(goodResult.isSuccess, isTrue);
      expect(goodResult.accessToken, isNotNull);
      expect(goodResult.message, contains('verified successfully'));
    });

    test('resendOtp enforces client cooldown throttle', () async {
      final sendResult = await service.sendOtp('9876543210');

      // Immediate resend attempt should fail due to cooldown
      final throttledResult = await service.resendOtp(
        phoneNumber: '9876543210',
        reqId: sendResult.reqId!,
      );
      expect(throttledResult.isSuccess, isFalse);
      expect(throttledResult.errorCode, 'COOLDOWN_ACTIVE');

      // Clear cooldown manually to simulate timer expiry
      service.clearCooldown();
      expect(service.canResend, isTrue);

      final allowedResult = await service.resendOtp(
        phoneNumber: '9876543210',
        reqId: sendResult.reqId!,
      );
      expect(allowedResult.isSuccess, isTrue);
      expect(service.resendCount, 1);
    });

    test('Simulated errors and failure flags are respected', () async {
      service.shouldSucceed = false;
      final failSend = await service.sendOtp('9876543210');
      expect(failSend.isSuccess, isFalse);

      service.shouldSucceed = true;
      service.simulatedError = 'Simulated network outage';
      final failVerify = await service.verifyOtp(
        phoneNumber: '9876543210',
        otp: '654321',
        reqId: 'test_req',
      );
      expect(failVerify.isSuccess, isFalse);
      expect(failVerify.message, 'Simulated network outage');
    });
  });

  group('PhoneVerificationServiceLocator Tests', () {
    setUp(() {
      PhoneVerificationServiceLocator.reset();
    });

    tearDown(() {
      PhoneVerificationServiceLocator.reset();
    });

    test('Defaults to Msg91PhoneVerificationService in production', () {
      final service = PhoneVerificationServiceLocator.instance;
      expect(service, isA<Msg91PhoneVerificationService>());
    });

    test('useMockService switches to MockPhoneVerificationService', () {
      final mock = PhoneVerificationServiceLocator.useMockService(expectedOtp: '112233');
      expect(PhoneVerificationServiceLocator.instance, same(mock));
      expect(mock.expectedOtp, '112233');
    });

    test('reset clears cached service instance', () {
      PhoneVerificationServiceLocator.useMockService();
      PhoneVerificationServiceLocator.reset();
      expect(PhoneVerificationServiceLocator.instance, isA<Msg91PhoneVerificationService>());
    });
  });

  group('UserModel Phone Verification Model & Security Invariant Tests', () {
    test('Default UserModel has phoneVerified false and phoneVerifiedAt null', () {
      const citizen = UserModel(
        id: 'u1',
        fullName: 'Aarav Mehta',
        email: 'aarav@civicfix.test',
        phone: '+919876543210',
      );

      // Existing phone on profile does NOT imply phoneVerified == true
      expect(citizen.phoneVerified, isFalse);
      expect(citizen.phoneVerifiedAt, isNull);
    });

    test('copyWith updates phoneVerified and phoneVerifiedAt correctly', () {
      const citizen = UserModel(
        id: 'u1',
        fullName: 'Aarav Mehta',
        email: 'aarav@civicfix.test',
        phone: '',
      );

      final now = DateTime(2026, 9, 25, 12, 0);
      final verified = citizen.copyWith(
        phone: '+919876543210',
        phoneVerified: true,
        phoneVerifiedAt: now,
      );

      expect(verified.phone, '+919876543210');
      expect(verified.phoneVerified, isTrue);
      expect(verified.phoneVerifiedAt, now);
      // Preserves immutable citizen role
      expect(verified.role, 'citizen');
    });
  });

  group('UserFirestoreMapper Phone Verification Tests', () {
    test('Serializes phoneVerified and phoneVerifiedAt to Firestore map', () {
      final verifiedAt = DateTime(2026, 9, 25, 10, 0);
      final user = UserModel(
        id: 'u2',
        fullName: 'Divya Nair',
        email: 'divya@civicfix.test',
        phone: '+919876543210',
        phoneVerified: true,
        phoneVerifiedAt: verifiedAt,
      );

      final map = UserFirestoreMapper.citizenToFirestore(user);
      expect(map['phoneVerified'], isTrue);
      expect(map['phoneVerifiedAt'], isA<Timestamp>());
      expect((map['phoneVerifiedAt'] as Timestamp).toDate(), verifiedAt);
      expect(map['role'], 'citizen');
    });

    test('Deserializes phoneVerified and phoneVerifiedAt from Firestore map', () {
      final verifiedAt = DateTime(2026, 9, 25, 10, 0);
      final data = {
        'fullName': 'Divya Nair',
        'email': 'divya@civicfix.test',
        'phone': '+919876543210',
        'phoneVerified': true,
        'phoneVerifiedAt': Timestamp.fromDate(verifiedAt),
        'role': 'citizen',
      };

      final user = UserFirestoreMapper.citizenFromFirestore(
        documentId: 'u2',
        data: data,
      );

      expect(user.id, 'u2');
      expect(user.phoneVerified, isTrue);
      expect(user.phoneVerifiedAt, verifiedAt);
      expect(user.phone, '+919876543210');
    });

    test('Falls back safely when phoneVerified is absent from legacy documents', () {
      final legacyData = {
        'fullName': 'Legacy User',
        'email': 'legacy@civicfix.test',
        'phone': '9876543210',
        'role': 'citizen',
      };

      final user = UserFirestoreMapper.citizenFromFirestore(
        documentId: 'legacy_001',
        data: legacyData,
      );

      expect(user.phoneVerified, isFalse);
      expect(user.phoneVerifiedAt, isNull);
    });
  });

  group('MockAuthService Phone Verification Integration Tests', () {
    test('markPhoneVerified updates current user state and normalizes phone', () async {
      AuthServiceLocator.useMockServices();
      final mockAuth = AuthServiceLocator.citizenAuth;

      // Log in with default seed account
      await mockAuth.login(
        email: 'citizen@civicfix.test',
        password: 'CivicFix123',
      );

      expect(mockAuth.currentUser, isNotNull);

      // Verify phone
      final verifyResult = await mockAuth.markPhoneVerified(
        phoneNumber: '9876543210',
        accessToken: 'mock_token',
      );

      expect(verifyResult.isSuccess, isTrue);
      expect(verifyResult.user?.phoneVerified, isTrue);
      expect(verifyResult.user?.phone, '+919876543210');
      expect(verifyResult.user?.phoneVerifiedAt, isNotNull);
      expect(mockAuth.currentUser?.phoneVerified, isTrue);
    });
  });

  group('Phase 5: One Phone Number = One CivicFix Account Uniqueness Tests', () {
    late MockAuthService mockAuth;

    setUp(() {
      AuthServiceLocator.useMockServices();
      mockAuth = MockAuthService();
      mockAuth.resetForTesting();
    });

    test('Case A: User 1 successfully verifies phone number and claims index entry', () async {
      final user1 = const UserModel(
        id: 'uid_citizen_user_001',
        fullName: 'User One',
        email: 'user1@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(user1);

      final result = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(result.isSuccess, isTrue);
      expect(result.user?.phoneVerified, isTrue);
      expect(result.user?.phone, '+919123456789');
      expect(mockAuth.phoneIndex['+919123456789'], equals('uid_citizen_user_001'));
    });

    test('Case B: User 2 attempting to verify the same phone is rejected with collision error', () async {
      // User 1 verifies first
      final user1 = const UserModel(
        id: 'uid_citizen_user_001',
        fullName: 'User One',
        email: 'user1@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(user1);
      final r1 = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(r1.isSuccess, isTrue);

      // User 2 logs in and attempts to claim the exact same number
      final user2 = const UserModel(
        id: 'uid_citizen_user_002',
        fullName: 'User Two',
        email: 'user2@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(user2);

      final r2 = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(r2.isSuccess, isFalse);
      expect(
        r2.errorMessage,
        equals('This phone number is already associated with another CivicFix account.'),
      );
      // User 2 remains unverified
      expect(mockAuth.currentUser?.phoneVerified, isFalse);
      // Index still belongs strictly to User 1
      expect(mockAuth.phoneIndex['+919123456789'], equals('uid_citizen_user_001'));
    });

    test('Case C: User 1 re-verifying own phone number succeeds (idempotent)', () async {
      final user1 = const UserModel(
        id: 'uid_citizen_user_001',
        fullName: 'User One',
        email: 'user1@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(user1);

      final r1 = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(r1.isSuccess, isTrue);

      // Re-verification by the SAME user succeeds idempotently
      final r2 = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(r2.isSuccess, isTrue);
      expect(r2.user?.phoneVerified, isTrue);
      expect(mockAuth.phoneIndex['+919123456789'], equals('uid_citizen_user_001'));
    });

    test('Case D: Unverified account with phone typed in registration does NOT reserve phone', () async {
      mockAuth.defaultPhoneVerified = false;

      // User 1 registers with a phone number, but has NOT verified OTP yet
      final regResult = await mockAuth.register(
        fullName: 'Unverified User',
        email: 'unverified@civicfix.test',
        password: 'Password123',
        phone: '9876500000',
        language: 'en',
      );
      expect(regResult.isSuccess, isTrue);
      expect(regResult.user?.phoneVerified, isFalse);

      // Crucial security invariant: Unverified phone in registration MUST NOT be in phoneIndex
      expect(mockAuth.phoneIndex.containsKey('+919876500000'), isFalse);

      // User 2 can successfully verify that phone number because User 1 never claimed it
      final user2 = const UserModel(
        id: 'uid_legit_verifier',
        fullName: 'Legitimate Owner',
        email: 'legit@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(user2);

      final verifyResult = await mockAuth.markPhoneVerified(phoneNumber: '9876500000');
      expect(verifyResult.isSuccess, isTrue);
      expect(mockAuth.phoneIndex['+919876500000'], equals('uid_legit_verifier'));
    });

    test('Case E: Google Sign-In citizen account verifies phone and blocks collision', () async {
      // Citizen signs in via Google
      final googleResult = await mockAuth.signInWithGoogle();
      expect(googleResult.isSuccess, isTrue);

      // Unverified state for new Google citizen
      mockAuth.setMockUser(googleResult.user!.copyWith(phoneVerified: false, phone: ''));

      // Google user verifies their mobile number
      final verifyResult = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(verifyResult.isSuccess, isTrue);
      expect(mockAuth.phoneIndex['+919123456789'], equals(googleResult.user!.id));

      // Separate email/password user tries to claim the same phone
      final emailUser = const UserModel(
        id: 'uid_email_user_999',
        fullName: 'Email User',
        email: 'another@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(emailUser);

      final conflictResult = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(conflictResult.isSuccess, isFalse);
      expect(
        conflictResult.errorMessage,
        equals('This phone number is already associated with another CivicFix account.'),
      );
    });

    test('Case F: E.164 normalization checks prevent collision bypass via format variations', () async {
      final user1 = const UserModel(
        id: 'uid_user_alpha',
        fullName: 'Alpha User',
        email: 'alpha@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(user1);

      // User 1 verifies with standard 10 digits
      await mockAuth.markPhoneVerified(phoneNumber: '9123456789');

      final user2 = const UserModel(
        id: 'uid_user_beta',
        fullName: 'Beta User',
        email: 'beta@civicfix.test',
        phone: '',
        phoneVerified: false,
      );

      // Formats attempting to circumvent index:
      final variants = [
        '+91 91234 56789',
        '+91-91234-56789',
        '09123456789',
        '919123456789',
        '+919123456789',
      ];

      for (final variant in variants) {
        mockAuth.setMockUser(user2);
        final attempt = await mockAuth.markPhoneVerified(phoneNumber: variant);
        expect(
          attempt.isSuccess,
          isFalse,
          reason: 'Variant "$variant" should have collided with canonical +919123456789',
        );
        expect(
          attempt.errorMessage,
          equals('This phone number is already associated with another CivicFix account.'),
        );
      }
    });

    test('Case G: Offline/Hive cache tampering cannot bypass server-authoritative ownership', () async {
      // User 1 is legitimate owner
      final user1 = const UserModel(
        id: 'uid_legit_owner',
        fullName: 'Legit Owner',
        email: 'owner@civicfix.test',
        phone: '',
        phoneVerified: false,
      );
      mockAuth.setMockUser(user1);
      final claimResult = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(claimResult.isSuccess, isTrue);

      // User 2 has offline local cache asserting phoneVerified: true, but server index rejects it
      final user2 = const UserModel(
        id: 'uid_tampered_offline_user',
        fullName: 'Attacker User',
        email: 'attacker@civicfix.test',
        phone: '+919123456789',
        phoneVerified: true, // Tampered local cache
      );
      mockAuth.setMockUser(user2);

      // Attempting to re-verify/claim on server fails
      final attempt = await mockAuth.markPhoneVerified(phoneNumber: '9123456789');
      expect(attempt.isSuccess, isFalse);
      expect(
        attempt.errorMessage,
        equals('This phone number is already associated with another CivicFix account.'),
      );
      // Index still points strictly to User 1
      expect(mockAuth.phoneIndex['+919123456789'], equals('uid_legit_owner'));
    });
  });
}

