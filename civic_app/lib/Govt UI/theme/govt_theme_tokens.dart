import 'package:flutter/material.dart';
import '../../core/theme/civicfix_design_tokens.dart';

/// Government Portal Visual Design Tokens Bridge.
///
/// Aliases the authoritative tokens from `civicfix_design_tokens.dart`
/// adhering to the "Civic Precision — Editorial Minimalism" design specification.
class GovtThemeTokens {
  GovtThemeTokens._();

  // Primary Palette (Institutional Gold / Amber & Slate)
  static const Color primary = CivicFixColors.primary;
  static const Color primaryLight = CivicFixColors.primaryAccent;
  static const Color primaryDark = CivicFixColors.secondaryAuthority;
  
  // Secondary Palette
  static const Color secondary = CivicFixColors.secondary;
  static const Color secondaryLight = CivicFixColors.secondaryContainer;
  static const Color secondaryDark = CivicFixColors.onSecondaryContainer;
  static const Color accent = CivicFixColors.primaryAccent;
  static const Color accentLight = CivicFixColors.primaryAccentSoft;

  // Background & Surfaces
  static const Color background = CivicFixColors.canvas;
  static const Color surface = CivicFixColors.surfaceContainerLowest;
  static const Color elevatedSurface = CivicFixColors.surfaceContainerLowest;
  static const Color surfaceMuted = CivicFixColors.surfaceContainerLow;
  static const Color surfaceVariant = CivicFixColors.surfaceContainer;

  // Borders & Dividers
  static const Color border = CivicFixColors.border;
  static const Color borderLight = CivicFixColors.borderLight;
  static const Color divider = CivicFixColors.divider;

  // Typography Colors
  static const Color textPrimary = CivicFixColors.textPrimary;
  static const Color textSecondary = CivicFixColors.textSecondary;
  static const Color textMuted = CivicFixColors.textMuted;
  static const Color textDisabled = CivicFixColors.textDisabled;

  // Semantic Feedback & Alert Colors
  static const Color success = CivicFixColors.success;
  static const Color successLight = CivicFixColors.successContainer;
  static const Color warning = CivicFixColors.warning;
  static const Color warningLight = CivicFixColors.warningContainer;
  static const Color alert = CivicFixColors.warning;
  static const Color info = CivicFixColors.info;
  static const Color infoLight = CivicFixColors.infoContainer;
  static const Color error = CivicFixColors.error;
  static const Color errorLight = CivicFixColors.errorContainer;
  static const Color danger = CivicFixColors.error;
  static const Color dangerLight = CivicFixColors.errorContainer;
  static const Color critical = CivicFixColors.onErrorContainer;
  static const Color criticalLight = CivicFixColors.errorContainer;

  // Status Badges Colors
  static const Color statusReported = CivicFixColors.info;
  static const Color statusVerified = CivicFixColors.warning;
  static const Color statusAssigned = CivicFixColors.secondary;
  static const Color statusInProgress = CivicFixColors.primaryAccent;
  static const Color statusAwaitingVerification = CivicFixColors.tertiary;
  static const Color statusResolved = CivicFixColors.success;
  static const Color statusRejected = CivicFixColors.error;

  // SLA Indicator Colors
  static const Color slaHealthy = CivicFixColors.slaHealthy;
  static const Color slaHealthyBg = CivicFixColors.slaHealthyBg;
  static const Color slaWarning = CivicFixColors.slaWarning;
  static const Color slaWarningBg = CivicFixColors.slaWarningBg;
  static const Color slaBreached = CivicFixColors.slaBreached;
  static const Color slaBreachedBg = CivicFixColors.slaBreachedBg;

  // Layout Dimensions
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double topBarHeight = 68.0;
  static const double maxContentWidth = 1440.0;

  // Icon Sizes
  static const double iconSm = CivicFixSpacing.iconSm;
  static const double iconMd = CivicFixSpacing.iconMd;
  static const double iconLg = CivicFixSpacing.iconLg;
  static const double iconXl = CivicFixSpacing.iconXl;

  // Spacing Aliases
  static const double spacingXs = CivicFixSpacing.xs;
  static const double spacingSm = CivicFixSpacing.sm;
  static const double spacingMd = CivicFixSpacing.md;
  static const double spacingLg = CivicFixSpacing.lg;
  static const double spacingXl = CivicFixSpacing.xl;
  static const double spacingXxl = CivicFixSpacing.xxl;
  static const double spacingXxxl = CivicFixSpacing.xxxl;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 640.0;
  static const double tabletBreakpoint = 640.0;
  static const double desktopBreakpoint = 960.0;
  static const double largeDesktopBreakpoint = 1440.0;

  // Radii
  static const double radiusSm = CivicFixRadius.sm;
  static const double radiusMd = CivicFixRadius.card;
  static const double radiusLg = CivicFixRadius.largeContainer;
  static const BorderRadius cardRadius = CivicFixRadius.cardRadius;
  static const BorderRadius buttonRadius = CivicFixRadius.buttonRadius;
  static const BorderRadius chipRadius = CivicFixRadius.chipRadius;

  // Elevation & Shadows
  static const List<BoxShadow> cardShadow = CivicFixElevation.subtle;
  static const List<BoxShadow> hoverShadow = CivicFixElevation.card;
  static const List<BoxShadow> elevatedShadow = CivicFixElevation.floating;

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
