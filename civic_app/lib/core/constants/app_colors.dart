import 'package:flutter/material.dart';

/// Centralized color definitions and design tokens for CivicFix.
class CivicFixColors {
  CivicFixColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF12304A); // Deep Navy
  static const Color primaryLight = Color(0xFF1F4A70);
  static const Color primaryDark = Color(0xFF0C2032);

  // Secondary Brand Colors
  static const Color secondary = Color(0xFF2E8B57); // Civic Green (SeaGreen)
  static const Color secondaryLight = Color(0xFF3EA369);
  static const Color secondaryDark = Color(0xFF1E603B);

  // Accent & Highlight Colors
  static const Color accent = Color(0xFF7ED6A5); // Fresh Mint
  static const Color accentLight = Color(0xFFE8F8F0);

  // Background & Surface Colors
  static const Color background = Color(0xFFF7F9F7); // Off White
  static const Color surface = Color(0xFFFFFFFF); // Card / Sheet Surface
  static const Color surfaceMuted = Color(0xFFEFF3F0);

  // Alert & Feedback Colors
  static const Color alert = Color(0xFFF4B942); // Amber
  static const Color alertLight = Color(0xFFFEF8EC);
  static const Color alertDark = Color(0xFF9E6E06);

  static const Color error = Color(0xFFC62828); // Error Red
  static const Color errorLight = Color(0xFFFDE8E8);

  static const Color info = Color(0xFF2F6F95); // Info Blue
  static const Color infoLight = Color(0xFFE8F2F8);

  static const Color success = Color(0xFF2E8B57);
  static const Color successLight = Color(0xFFE8F8F0);

  // Supporting Typography & Line Colors
  static const Color primaryText = Color(0xFF17212B);
  static const Color secondaryText = Color(0xFF5F6B73);
  static const Color disabledText = Color(0xFF9AA3A8);
  static const Color border = Color(0xFFD9E0DC);
  static const Color borderLight = Color(0xFFE8EDE9);
  static const Color divider = Color(0xFFE5ECE7);

  // Status Tints (Background + Text pairings)
  static const Color statusSubmittedBg = Color(0xFFE8F2F8);
  static const Color statusSubmittedText = Color(0xFF2F6F95);

  static const Color statusUnderReviewBg = Color(0xFFFEF8EC);
  static const Color statusUnderReviewText = Color(0xFFB47C07);

  static const Color statusInProgressBg = Color(0xFFE6F3FB);
  static const Color statusInProgressText = Color(0xFF125688);

  static const Color statusResolvedBg = Color(0xFFE8F8F0);
  static const Color statusResolvedText = Color(0xFF236E44);

  static const Color statusRejectedBg = Color(0xFFFDE8E8);
  static const Color statusRejectedText = Color(0xFFC62828);
}
