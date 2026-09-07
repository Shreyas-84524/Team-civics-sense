import 'package:flutter/material.dart';

/// 8-point spacing grid system constants for CivicFix.
class CivicFixSpacing {
  CivicFixSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;

  // Screen level paddings
  static const double screenPaddingMobile = 16.0;
  static const double screenPaddingWide = 20.0;

  // Touch target sizes
  static const double minTouchTarget = 48.0;

  // SizedBox vertical spacing helpers
  static const SizedBox vSpaceXs = SizedBox(height: xs);
  static const SizedBox vSpaceSm = SizedBox(height: sm);
  static const SizedBox vSpaceMd = SizedBox(height: md);
  static const SizedBox vSpaceLg = SizedBox(height: lg);
  static const SizedBox vSpaceXl = SizedBox(height: xl);
  static const SizedBox vSpaceXxl = SizedBox(height: xxl);
  static const SizedBox vSpaceXxxl = SizedBox(height: xxxl);
  static const SizedBox vSpaceHuge = SizedBox(height: huge);

  // SizedBox horizontal spacing helpers
  static const SizedBox hSpaceXs = SizedBox(width: xs);
  static const SizedBox hSpaceSm = SizedBox(width: sm);
  static const SizedBox hSpaceMd = SizedBox(width: md);
  static const SizedBox hSpaceLg = SizedBox(width: lg);
  static const SizedBox hSpaceXl = SizedBox(width: xl);
  static const SizedBox hSpaceXxl = SizedBox(width: xxl);

  // Insets helpers
  static const EdgeInsets pagePadding = EdgeInsets.all(screenPaddingMobile);
  static const EdgeInsets pagePaddingWide = EdgeInsets.all(screenPaddingWide);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xl);
}
