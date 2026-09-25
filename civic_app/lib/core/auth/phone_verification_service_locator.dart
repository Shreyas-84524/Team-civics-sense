import 'mock_phone_verification_service.dart';
import 'msg91_phone_verification_service.dart';
import 'phone_verification_service.dart';

/// Centralized Service Locator for Citizen Phone Number Verification services.
///
/// Production runtime resolves to [Msg91PhoneVerificationService].
/// Tests can override with [MockPhoneVerificationService] via [useMockService].
class PhoneVerificationServiceLocator {
  PhoneVerificationServiceLocator._();

  static PhoneVerificationService? _instance;

  /// Active Phone Verification Service instance.
  ///
  /// Defaults to production [Msg91PhoneVerificationService].
  static PhoneVerificationService get instance {
    _instance ??= Msg91PhoneVerificationService();
    return _instance!;
  }

  /// Sets or overrides the active Phone Verification Service instance.
  static set instance(PhoneVerificationService service) {
    _instance = service;
  }

  /// Switches the verification provider to in-memory Mock implementation for tests.
  static MockPhoneVerificationService useMockService({
    String expectedOtp = '123456',
  }) {
    final mock = MockPhoneVerificationService(expectedOtp: expectedOtp);
    _instance = mock;
    return mock;
  }

  /// Switches back to production MSG91 implementation.
  static void useProductionService() {
    _instance = Msg91PhoneVerificationService();
  }

  /// Resets cached instance to default lazy production resolution.
  static void reset() {
    _instance = null;
  }
}
