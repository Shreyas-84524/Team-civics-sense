/// Secure runtime configuration for MSG91 OTP Widget.
///
/// Values are injected at compile/build time via `--dart-define`:
/// ```bash
/// flutter run --dart-define=MSG91_WIDGET_ID=your_widget_id --dart-define=MSG91_TOKEN_AUTH=your_token_auth
/// ```
///
/// SECURITY NOTICE:
/// The MSG91 Account Master AuthKey is NEVER embedded into the Flutter client code.
/// Only the public Widget ID and client Token Auth are utilized client-side.
class Msg91Config {
  Msg91Config._();

  /// MSG91 OTP Widget identifier.
  static const String widgetId = String.fromEnvironment(
    'MSG91_WIDGET_ID',
    defaultValue: '',
  );

  /// MSG91 OTP Widget token authentication.
  static const String tokenAuth = String.fromEnvironment(
    'MSG91_TOKEN_AUTH',
    defaultValue: '',
  );

  /// Whether the required MSG91 credentials have been provided.
  static bool get isConfigured =>
      widgetId.trim().isNotEmpty && tokenAuth.trim().isNotEmpty;
}
