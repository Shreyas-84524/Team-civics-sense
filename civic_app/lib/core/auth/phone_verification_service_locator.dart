import 'mock_phone_verification_service.dart';
import 'phone_verification_service.dart';
import 'supabase_phone_verification_service.dart';

/// Centralized Service Locator for Citizen Phone Number Verification services.
///
/// Production runtime resolves to [SupabasePhoneVerificationService].
/// Tests can override with [MockPhoneVerificationService] via [useMockService].
class PhoneVerificationServiceLocator {
  PhoneVerificationServiceLocator._();

  static PhoneVerificationService? _instance;

  /// Active Phone Verification Service instance.
  ///
  /// Defaults to production [SupabasePhoneVerificationService].
  static PhoneVerificationService get instance {
    _instance ??= SupabasePhoneVerificationService();
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

  /// Switches to production Supabase OTP implementation.
  static void useSupabaseService() {
    _instance = SupabasePhoneVerificationService();
  }

  /// Switches back to default production service (Supabase).
  static void useProductionService() {
    _instance = SupabasePhoneVerificationService();
  }

  /// Resets cached instance to default lazy production resolution.
  static void reset() {
    _instance = null;
  }
}
