import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

/// Government Portal Visual Design Tokens and Layout Metrics.
///
/// Embodies a civic command, operational, authoritative, data-focused,
/// clean, modern, and highly readable municipal design system.
class GovtThemeTokens {
  GovtThemeTokens._();

  // Primary Palette (Authoritative Navy)
  static const Color primary = CivicFixColors.primary; // Deep Navy #12304A
  static const Color primaryLight = CivicFixColors.primaryLight; // #1F4A70
  static const Color primaryDark = CivicFixColors.primaryDark; // #0C2032
  
  // Secondary Palette (Civic Green & Mint)
  static const Color secondary = CivicFixColors.secondary; // Civic Green #2E8B57
  static const Color secondaryLight = CivicFixColors.secondaryLight;
  static const Color secondaryDark = CivicFixColors.secondaryDark;
  static const Color accent = CivicFixColors.accent; // Fresh Mint #7ED6A5
  static const Color accentLight = CivicFixColors.accentLight;

  // Background & Surfaces
  static const Color background = CivicFixColors.background; // Off White #F7F9F7
  static const Color surface = CivicFixColors.surface; // Pure White #FFFFFF
  static const Color elevatedSurface = Color(0xFFFFFFFF); // Elevated White
  static const Color surfaceMuted = CivicFixColors.surfaceMuted; // #EFF3F0
  static const Color surfaceVariant = CivicFixColors.surfaceMuted; // #EFF3F0

  // Borders & Dividers
  static const Color border = CivicFixColors.border; // #D9E0DC
  static const Color borderLight = CivicFixColors.borderLight; // #E8EDE9
  static const Color divider = CivicFixColors.divider; // #E5ECE7

  // Typography Colors
  static const Color textPrimary = CivicFixColors.primaryText; // #17212B
  static const Color textSecondary = CivicFixColors.secondaryText; // #5F6B73
  static const Color textMuted = CivicFixColors.disabledText; // #9AA3A8
  static const Color textDisabled = CivicFixColors.disabledText; // #9AA3A8

  // Semantic Feedback & Alert Colors
  static const Color success = CivicFixColors.success; // #2E8B57
  static const Color successLight = CivicFixColors.successLight; // #E8F8F0
  static const Color warning = CivicFixColors.alert; // Amber #F4B942
  static const Color warningLight = CivicFixColors.alertLight; // #FEF8EC
  static const Color alert = CivicFixColors.alert;
  static const Color info = CivicFixColors.info; // Slate Blue #2F6F95
  static const Color infoLight = CivicFixColors.infoLight; // #E8F2F8
  static const Color error = CivicFixColors.error; // Crimson #C62828
  static const Color errorLight = CivicFixColors.errorLight; // #FDE8E8
  static const Color danger = CivicFixColors.error;
  static const Color dangerLight = CivicFixColors.errorLight;
  static const Color critical = Color(0xFFB71C1C); // Deep Red
  static const Color criticalLight = Color(0xFFFDE8E8);

  // Status Badges Colors
  static const Color statusReported = CivicFixColors.primary;
  static const Color statusVerified = CivicFixColors.secondary;
  static const Color statusAssigned = CivicFixColors.info;
  static const Color statusInProgress = Color(0xFFD97706); // Dark Amber
  static const Color statusAwaitingVerification = Color(0xFF7C3AED); // Purple
  static const Color statusResolved = CivicFixColors.secondary;
  static const Color statusRejected = CivicFixColors.error;

  // SLA Indicator Colors
  static const Color slaHealthy = Color(0xFF2E8B57); // Green
  static const Color slaHealthyBg = Color(0xFFE8F8F0);
  static const Color slaWarning = Color(0xFFD97706); // Amber
  static const Color slaWarningBg = Color(0xFFFEF8EC);
  static const Color slaBreached = Color(0xFFC62828); // Red
  static const Color slaBreachedBg = Color(0xFFFDE8E8);

  // Layout Dimensions
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double topBarHeight = 68.0;
  static const double maxContentWidth = 1440.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // Spacing Aliases
  static const double spacingXs = CivicFixSpacing.xs; // 4.0
  static const double spacingSm = CivicFixSpacing.sm; // 8.0
  static const double spacingMd = CivicFixSpacing.md; // 12.0
  static const double spacingLg = CivicFixSpacing.lg; // 16.0
  static const double spacingXl = CivicFixSpacing.xl; // 24.0
  static const double spacingXxl = CivicFixSpacing.xxl; // 32.0
  static const double spacingXxxl = CivicFixSpacing.xxxl; // 40.0

  // Responsive Breakpoints
  static const double mobileBreakpoint = 640.0;
  static const double tabletBreakpoint = 640.0; // Tablet starts at 640
  static const double desktopBreakpoint = 960.0; // Desktop starts at 960
  static const double largeDesktopBreakpoint = 1440.0; // Large Desktop at 1440

  // Radii
  static const double radiusSm = CivicFixRadius.chip; // 6.0
  static const double radiusMd = CivicFixRadius.card; // 12.0
  static const double radiusLg = CivicFixRadius.largeContainer; // 16.0
  static final BorderRadius cardRadius = CivicFixRadius.cardRadius;
  static final BorderRadius buttonRadius = CivicFixRadius.buttonRadius;
  static final BorderRadius chipRadius = CivicFixRadius.chipRadius;

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

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Borders
  static const Border sideBorder = Border(
    right: BorderSide(color: border, width: 1.0),
  );

  static const Border bottomBorder = Border(
    bottom: BorderSide(color: border, width: 1.0),
  );

  static const Border topBorder = Border(
    top: BorderSide(color: border, width: 1.0),
  );
}
