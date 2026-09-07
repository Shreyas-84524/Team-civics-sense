import 'package:flutter/material.dart';

/// Centralized border radius values for CivicFix.
class CivicFixRadius {
  CivicFixRadius._();

  static const double chip = 8.0;
  static const double button = 10.0;
  static const double input = 10.0;
  static const double card = 12.0;
  static const double largeContainer = 16.0;
  static const double sheet = 20.0;
  static const double bottomSheet = 20.0;
  static const double full = 999.0;

  // BorderRadius objects
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(input));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius largeContainerRadius = BorderRadius.all(Radius.circular(largeContainer));
  static const BorderRadius sheetRadius = BorderRadius.vertical(top: Radius.circular(sheet));
  static const BorderRadius fullRadius = BorderRadius.all(Radius.circular(full));
}
