import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

/// Government Portal Visual Design Tokens and Layout Metrics.
class GovtThemeTokens {
  GovtThemeTokens._();

  // Primary Palette
  static const Color primary = CivicFixColors.primary; // Deep Navy #12304A
  static const Color primaryLight = CivicFixColors.primaryLight;
  static const Color primaryDark = CivicFixColors.primaryDark;
  
  static const Color secondary = CivicFixColors.secondary; // Civic Green #2E8B57
  static const Color accent = CivicFixColors.accent; // Fresh Mint #7ED6A5
  static const Color background = CivicFixColors.background; // Off White #F7F9F7
  static const Color alert = CivicFixColors.alert; // Amber #F4B942
  static const Color warning = CivicFixColors.alert;
  static const Color error = CivicFixColors.error; // Red #C62828
  static const Color info = CivicFixColors.info; // Blue #2F6F95
  static const Color success = CivicFixColors.success; // #2E8B57

  // Surfaces & Borders
  static const Color surface = CivicFixColors.surface; // #FFFFFF
  static const Color surfaceMuted = CivicFixColors.surfaceMuted; // #EFF3F0
  static const Color surfaceVariant = CivicFixColors.surfaceMuted; // #EFF3F0
  static const Color border = CivicFixColors.border; // #D9E0DC
  static const Color borderLight = CivicFixColors.borderLight; // #E8EDE9

  // Typography Colors
  static const Color textPrimary = CivicFixColors.primaryText; // #17212B
  static const Color textSecondary = CivicFixColors.secondaryText; // #5F6B73
  static const Color textDisabled = CivicFixColors.disabledText; // #9AA3A8

  // Layout Dimensions
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double topBarHeight = 68.0;

  // Responsive Breakpoints
  static const double desktopBreakpoint = 960.0;
  static const double tabletBreakpoint = 640.0;

  // Radius values
  static const double radiusSm = CivicFixRadius.chip;
  static const double radiusMd = CivicFixRadius.card;
  static const double radiusLg = CivicFixRadius.largeContainer;

  // Elevation & Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Card Borders & Radii
  static final BorderRadius cardRadius = CivicFixRadius.cardRadius;
  static final BorderRadius buttonRadius = CivicFixRadius.buttonRadius;
  static final BorderRadius chipRadius = CivicFixRadius.chipRadius;

  static const Border sideBorder = Border(
    right: BorderSide(color: border, width: 1.0),
  );

  static const Border bottomBorder = Border(
    bottom: BorderSide(color: border, width: 1.0),
  );
}
