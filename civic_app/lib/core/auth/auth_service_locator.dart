import '../../Govt UI/services/govt_auth_service.dart';
import '../../User UI/services/mock_auth_service.dart';
import 'auth_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_govt_auth_service.dart';

/// Centralized Service Locator for Citizen and Government Authentication Services.
///
/// Production runtime strictly resolves to [FirebaseAuthService] and [FirebaseGovtAuthService].
/// Test environments can explicitly override or switch to mock providers via [useMockServices].
class AuthServiceLocator {
  AuthServiceLocator._();

  static AuthService? _citizenAuth;
  static GovtAuthService? _govtAuth;

  /// Active Citizen Authentication Service instance.
  ///
  /// Defaults to production [FirebaseAuthService].
  static AuthService get citizenAuth {
    _citizenAuth ??= FirebaseAuthService();
    return _citizenAuth!;
  }

  /// Sets or overrides the active Citizen Authentication Service (e.g. for testing).
  static set citizenAuth(AuthService service) {
    _citizenAuth = service;
  }

  /// Active Government Authentication Service instance.
  ///
  /// Defaults to production [FirebaseGovtAuthService].
  static GovtAuthService get govtAuth {
    _govtAuth ??= FirebaseGovtAuthService();
    return _govtAuth!;
  }

  /// Sets or overrides the active Government Authentication Service (e.g. for testing).
  static set govtAuth(GovtAuthService service) {
    _govtAuth = service;
  }

  /// Switches all authentication providers to in-memory Mock implementations (strictly for testing).
  static void useMockServices() {
    _citizenAuth = MockAuthService();
    _govtAuth = MockGovtAuthService();
  }

  /// Switches all authentication providers to Firebase backend implementations.
  static void useFirebaseServices() {
    _citizenAuth = FirebaseAuthService();
    _govtAuth = FirebaseGovtAuthService();
  }

  /// Resets cached instances to default lazy production resolution.
  static void reset() {
    _citizenAuth = null;
    _govtAuth = null;
  }
}
