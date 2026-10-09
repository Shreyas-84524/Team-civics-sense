import 'package:flutter/material.dart';
import 'civicfix_theme.dart';

export 'civicfix_design_tokens.dart';
export 'civicfix_theme.dart';

/// Legacy Theme Bridge for CivicFix.
///
/// Delegates directly to the authoritative [CivicFixTheme] defined in
/// `civicfix_theme.dart` which consumes `civicfix_design_tokens.dart`.
class AppTheme {
  AppTheme._();

  /// Returns the authoritative CivicFix light theme.
  static ThemeData get lightTheme => CivicFixTheme.lightTheme;
}
