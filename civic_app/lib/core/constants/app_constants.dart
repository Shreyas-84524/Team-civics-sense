/// Global App Constants for CivicFix
class AppConstants {
  AppConstants._();

  static const String appName = 'CivicFix';
  static const String appTagline = 'Empowering Citizens, Improving Communities';

  // Responsive Breakpoints
  static const double mobileMaxWidth = 600.0;
  static const double tabletMaxWidth = 900.0;
  static const double contentMaxConstraint = 680.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration defaultAnimation = Duration(milliseconds: 250);
  // Verification & Public Web Domain
  static const String publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://civicfix.vercel.app',
  );
}
