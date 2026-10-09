import 'package:flutter/material.dart';

/// Centralized, Authoritative Design Tokens for CivicFix.
///
/// Derived directly from `DESIGN.md` (Civic Precision â€” Editorial Minimalism).
///
/// Strict Architecture Rule:
/// - This is the SINGLE SOURCE OF TRUTH for all literal UI color values,
///   spacing scales, border radii, elevations, and typography tokens.
/// - Feature screens must never declare hardcoded literal color values.
///
/// Design Movement:
/// - Editorial Minimalism for civic infrastructure.
/// - Porcelain canvas surfaces, deep slate authoritative typography & structural frames,
///   restrained burnished gold accents, crisp 1px hairline framing, and minimal diffuse elevation.
class CivicFixColors {
  CivicFixColors._();

  // ===========================================================================
  // 1. SURFACES & CANVAS (Porcelain / Parchment Neutral System)
  // ===========================================================================

  /// Base Canvas / Neutral Background: #F8F9FF (Off-Porcelain)
  static const Color canvas = Color(0xFFF8F9FF);

  /// Default Surface: #F8F9FF
  static const Color surface = Color(0xFFF8F9FF);

  /// Dim Surface: #CCDBF4
  static const Color surfaceDim = Color(0xFFCCDBF4);

  /// Bright Surface: #F8F9FF
  static const Color surfaceBright = Color(0xFFF8F9FF);

  /// Pure Porcelain White (Base Elevated Card Layer): #FFFFFF
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Pure Porcelain White alias
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Transparent color token
  static const Color transparent = Color(0x00000000);

  /// Semantic Surface Raised (Elevated Card / Modal Fill): #FFFFFF
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Surface Container Low: #EFF4FF
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);

  /// Standard Surface Container: #E6EEFF
  static const Color surfaceContainer = Color(0xFFE6EEFF);

  /// Surface Container High: #DDE9FF
  static const Color surfaceContainerHigh = Color(0xFFDDE9FF);

  /// Surface Container Highest: #D5E3FD
  static const Color surfaceContainerHighest = Color(0xFFD5E3FD);

  /// Surface Variant: #D5E3FD
  static const Color surfaceVariant = Color(0xFFD5E3FD);

  /// Surface Tint (Gold): #805600
  static const Color surfaceTint = Color(0xFF805600);

  /// Inverse Surface (Dark Slate): #233144
  static const Color inverseSurface = Color(0xFF233144);

  /// Inverse On-Surface (Parchment Light): #EBF1FF
  static const Color inverseOnSurface = Color(0xFFEBF1FF);

  // ===========================================================================
  // 2. TYPOGRAPHY & ON-SURFACE COLORS (Deep Slate Hierarchy)
  // ===========================================================================

  /// Primary Slate Text (On-Surface): #0D1C2F
  static const Color textPrimary = Color(0xFF0D1C2F);

  /// Secondary Reading / Narrative Text (On-Surface Variant): #514535
  static const Color textSecondary = Color(0xFF514535);

  /// Accessible Continuous Reading Slate Text: #334155
  static const Color readingText = Color(0xFF334155);

  /// Muted / Placeholder Text: #837562
  static const Color textMuted = Color(0xFF837562);

  /// Disabled / Subtle Outline Text: #837562
  static const Color textDisabled = Color(0xFF837562);

  /// Secondary Dark Slate Text: #475569
  static const Color textSlateMedium = Color(0xFF475569);

  /// Deep Slate Header Text: #0F172A
  static const Color textSlateDeep = Color(0xFF0F172A);

  /// Pure White Text for Dark Backgrounds: #FFFFFF
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ===========================================================================
  // 3. BRAND & INSTITUTIONAL AUTHORITY
  // ===========================================================================

  /// Primary Brand Tone (Institutional Gold / Amber Foundation): #805600
  static const Color primary = Color(0xFF805600);

  /// On-Primary: #FFFFFF
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Primary Container (Luminous Amber / Burnished Gold): #CA8A04
  static const Color primaryContainer = Color(0xFFCA8A04);

  /// On-Primary Container: #422A00
  static const Color onPrimaryContainer = Color(0xFF422A00);

  /// Inverse Primary: #FFBA46
  static const Color inversePrimary = Color(0xFFFFBA46);

  /// Primary Fixed: #FFDDB0
  static const Color primaryFixed = Color(0xFFFFDDB0);

  /// Primary Fixed Dim: #FFBA46
  static const Color primaryFixedDim = Color(0xFFFFBA46);

  /// On-Primary Fixed: #281800
  static const Color onPrimaryFixed = Color(0xFF281800);

  /// On-Primary Fixed Variant: #614000
  static const Color onPrimaryFixedVariant = Color(0xFF614000);

  /// High-Prestige Gold Accent: #CA8A04
  static const Color primaryAccent = Color(0xFFCA8A04);

  /// Luminous Amber Accent: #EAB308
  static const Color primaryAccentLight = Color(0xFFEAB308);

  /// Pale Warm Gold Tint (Alert ribbons, soft badge fills): #FEF08A
  static const Color primaryAccentSoft = Color(0xFFFEF08A);

  // ===========================================================================
  // 4. SECONDARY AUTHORITY (Deep Charcoal Slate & Support)
  // ===========================================================================

  /// Secondary Tone (Slate): #565E74
  static const Color secondary = Color(0xFF565E74);

  /// On-Secondary: #FFFFFF
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Secondary Authority Slate (Primary button & structural frame anchor): #0F172A
  static const Color secondaryAuthority = Color(0xFF0F172A);

  /// Secondary Authority Dark Hover: #1E293B
  static const Color secondaryAuthorityDark = Color(0xFF1E293B);

  /// Secondary Container: #DAE2FD
  static const Color secondaryContainer = Color(0xFFDAE2FD);

  /// On-Secondary Container: #5C647A
  static const Color onSecondaryContainer = Color(0xFF5C647A);

  /// Secondary Fixed: #DAE2FD
  static const Color secondaryFixed = Color(0xFFDAE2FD);

  /// Secondary Fixed Dim: #BEC6E0
  static const Color secondaryFixedDim = Color(0xFFBEC6E0);

  /// On-Secondary Fixed: #131B2E
  static const Color onSecondaryFixed = Color(0xFF131B2E);

  /// On-Secondary Fixed Variant: #3F465C
  static const Color onSecondaryFixedVariant = Color(0xFF3F465C);

  // ===========================================================================
  // 5. TERTIARY ACCENTS & HIGHLIGHTS
  // ===========================================================================

  /// Tertiary Tone: #695F02
  static const Color tertiary = Color(0xFF695F02);

  /// On-Tertiary: #FFFFFF
  static const Color onTertiary = Color(0xFFFFFFFF);

  /// Tertiary Container: #B9AD4F
  static const Color tertiaryContainer = Color(0xFFB9AD4F);

  /// On-Tertiary Container: #474000
  static const Color onTertiaryContainer = Color(0xFF474000);

  /// Tertiary Fixed: #F2E580
  static const Color tertiaryFixed = Color(0xFFF2E580);

  /// Tertiary Fixed Dim: #D5C867
  static const Color tertiaryFixedDim = Color(0xFFD5C867);

  /// On-Tertiary Fixed: #201C00
  static const Color onTertiaryFixed = Color(0xFF201C00);

  /// On-Tertiary Fixed Variant: #4F4800
  static const Color onTertiaryFixedVariant = Color(0xFF4F4800);

  // ===========================================================================
  // 6. OUTLINES, BORDERS & DIVIDERS (Hairline 1px Precision)
  // ===========================================================================

  /// Architectural 1px Hairline Border: #E2E8F0
  static const Color border = Color(0xFFE2E8F0);

  /// Subtle Structural Divider / Sub-border: #F1F5F9
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Hover / Active Slate Border: #CBD5E1
  static const Color borderStrong = Color(0xFFCBD5E1);

  /// M3 Outline: #837562
  static const Color outline = Color(0xFF837562);

  /// M3 Outline Variant: #D5C4AE
  static const Color outlineVariant = Color(0xFFD5C4AE);

  /// Global Divider: #F1F5F9
  static const Color divider = Color(0xFFF1F5F9);

  // ===========================================================================
  // 7. SEMANTIC FEEDBACK & STATUS COLORS
  // ===========================================================================

  /// Error / Alert Red: #BA1A1A
  static const Color error = Color(0xFFBA1A1A);

  /// On-Error: #FFFFFF
  static const Color onError = Color(0xFFFFFFFF);

  /// Error Container Fill: #FFDAD6
  static const Color errorContainer = Color(0xFFFFDAD6);

  /// On-Error Container Text: #93000A
  static const Color onErrorContainer = Color(0xFF93000A);

  /// Active / Processing / Success Green: #065F46
  static const Color success = Color(0xFF065F46);

  /// Success Container Fill: #ECFDF5
  static const Color successContainer = Color(0xFFECFDF5);

  /// Success Border: #A7F3D0
  static const Color successBorder = Color(0xFFA7F3D0);

  /// Official / Verified Gold: #854D0E
  static const Color warning = Color(0xFF854D0E);

  /// Warning Container Fill: #FEF08A
  static const Color warningContainer = Color(0xFFFEF08A);

  /// Warning Border: #FACC15
  static const Color warningBorder = Color(0xFFFACC15);

  /// Informational / Neutral Tone: #334155
  static const Color info = Color(0xFF334155);

  /// Info Container Fill: #F1F5F9
  static const Color infoContainer = Color(0xFFF1F5F9);

  /// Info Border: #E2E8F0
  static const Color infoBorder = Color(0xFFE2E8F0);

  // ===========================================================================
  // 8. SLA STATUS INDICATORS (Municipal Governance)
  // ===========================================================================

  /// SLA Healthy Indicator: #065F46
  static const Color slaHealthy = Color(0xFF065F46);

  /// SLA Healthy Background: #ECFDF5
  static const Color slaHealthyBg = Color(0xFFECFDF5);

  /// SLA Warning Indicator: #854D0E
  static const Color slaWarning = Color(0xFF854D0E);

  /// SLA Warning Background: #FEF08A
  static const Color slaWarningBg = Color(0xFFFEF08A);

  /// SLA Breached Indicator: #BA1A1A
  static const Color slaBreached = Color(0xFFBA1A1A);

  /// SLA Breached Background: #FFDAD6
  static const Color slaBreachedBg = Color(0xFFFFDAD6);

  // ===========================================================================
  // 9. STATUS BADGE PAIRINGS (Pill Badges)
  // ===========================================================================

  /// Verified / Official Badge Fill: #FEF08A
  static const Color badgeVerifiedBg = Color(0xFFFEF08A);

  /// Verified / Official Badge Text: #854D0E
  static const Color badgeVerifiedText = Color(0xFF854D0E);

  /// Verified / Official Badge Border: #FACC15
  static const Color badgeVerifiedBorder = Color(0xFFFACC15);

  /// Neutral / Informational Badge Fill: #F1F5F9
  static const Color badgeNeutralBg = Color(0xFFF1F5F9);

  /// Neutral / Informational Badge Text: #334155
  static const Color badgeNeutralText = Color(0xFF334155);

  /// Neutral / Informational Badge Border: #E2E8F0
  static const Color badgeNeutralBorder = Color(0xFFE2E8F0);

  /// Active / Processing Badge Fill: #ECFDF5
  static const Color badgeProcessingBg = Color(0xFFECFDF5);

  /// Active / Processing Badge Text: #065F46
  static const Color badgeProcessingText = Color(0xFF065F46);

  /// Active / Processing Badge Border: #A7F3D0
  static const Color badgeProcessingBorder = Color(0xFFA7F3D0);

  // ===========================================================================
  // 10. COMPATIBILITY ALIASES (Clean Migration Bridges)
  // ===========================================================================

  static const Color background = canvas;
  static const Color surfaceMuted = surfaceContainer;
  static const Color primaryLight = primaryAccent;
  static const Color primaryDark = secondaryAuthority;
  static const Color secondaryLight = secondaryContainer;
  static const Color secondaryDark = onSecondaryContainer;
  static const Color accent = primaryAccent;
  static const Color accentLight = primaryAccentSoft;
  static const Color alert = warning;
  static const Color alertLight = warningContainer;
  static const Color alertDark = warning;
  static const Color errorLight = errorContainer;
  static const Color infoLight = infoContainer;
  static const Color successLight = successContainer;
  static const Color primaryText = textPrimary;
  static const Color secondaryText = textSecondary;
  static const Color disabledText = textDisabled;

  static const Color statusSubmittedBg = infoContainer;
  static const Color statusSubmittedText = info;
  static const Color statusUnderReviewBg = warningContainer;
  static const Color statusUnderReviewText = warning;
  static const Color statusInProgressBg = surfaceContainerHigh;
  static const Color statusInProgressText = primaryAccent;
  static const Color statusResolvedBg = successContainer;
  static const Color statusResolvedText = success;
  static const Color statusRejectedBg = errorContainer;
  static const Color statusRejectedText = error;

  // ===========================================================================
  // 11. GOVERNMENT PORTAL & DARK NAVIGATION TOKENS
  // ===========================================================================

  /// Sidebar Dark Surface Anchor: #0F172A
  static const Color sidebarBackground = secondaryAuthority;

  /// Sidebar Inner Container / User Badge Card: #1E293B
  static const Color sidebarSurface = Color(0xFF1E293B);

  /// Sidebar Hairline Divider / Border: 12% White
  static const Color sidebarDivider = Color(0x1FFFFFFF);

  /// Sidebar Border: 10% White
  static const Color sidebarBorder = Color(0x1AFFFFFF);

  /// Sidebar Active Item Background: 16% White
  static const Color sidebarItemActive = Color(0x28FFFFFF);

  /// Sidebar Hover Item Background: 8% White
  static const Color sidebarItemHover = Color(0x14FFFFFF);

  /// Sidebar Muted Text / Inactive Nav: #94A3B8 (Slate 400)
  static const Color sidebarTextMuted = Color(0xFF94A3B8);

  /// Sidebar Standard Nav Text: #CBD5E1 (Slate 300)
  static const Color sidebarText = Color(0xFFCBD5E1);

  /// Sidebar Active Nav Text: #FFFFFF
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  /// Sidebar Inactive Nav Icon: #94A3B8
  static const Color sidebarIcon = Color(0xFF94A3B8);

  /// Sidebar Active Nav Icon (Gold): #CA8A04
  static const Color sidebarIconActive = primaryAccent;

  /// Sidebar Sign-out / Danger Action: #F87171 (Red 400)
  static const Color sidebarDanger = Color(0xFFF87171);

  // ===========================================================================
  // 12. GOVERNMENT ADMINISTRATIVE ROLE & JURISDICTION PALETTES
  // ===========================================================================

  /// Super Admin (Municipal Commissioner) Purple: #6B21A8
  static const Color roleSuperAdmin = Color(0xFF6B21A8);
  static const Color roleSuperAdminBg = Color(0xFFF3E8FF);

  /// Zonal DMC Blue: #1E40AF
  static const Color roleZonalDmc = Color(0xFF1E40AF);
  static const Color roleZonalDmcBg = Color(0xFFDBEAFE);

  /// Central Department HOD Teal: #0F766E
  static const Color roleCentralHod = Color(0xFF0F766E);
  static const Color roleCentralHodBg = Color(0xFFCCFBF1);

  /// Ward Officer Slate Navy: #0F172A
  static const Color roleWardOfficer = secondaryAuthority;
  static const Color roleWardOfficerBg = Color(0xFFE2E8F0);

  /// Ward Department Lead Amber: #B45309
  static const Color roleWardLead = Color(0xFFB45309);
  static const Color roleWardLeadBg = Color(0xFFFEF3C7);

  /// Department Field Crew Emerald: #047857
  static const Color roleCrew = Color(0xFF047857);
  static const Color roleCrewBg = Color(0xFFD1FAE5);

  /// Jurisdiction - Zone Indigo: #4338CA
  static const Color jurisdictionZone = Color(0xFF4338CA);
  static const Color jurisdictionZoneBg = Color(0xFFEEF2FF);

  /// Jurisdiction - Ward Emerald: #047857
  static const Color jurisdictionWard = Color(0xFF047857);
  static const Color jurisdictionWardBg = Color(0xFFECFDF5);

  /// Jurisdiction - Department Royal Blue: #1D4ED8
  static const Color jurisdictionDept = Color(0xFF1D4ED8);
  static const Color jurisdictionDeptBg = Color(0xFFEFF6FF);
}

/// Centralized Spacing Primitives.
///
/// Follows Design.md 4px/8px modular base scale:
/// - space-xs: 0.25rem (4px)
/// - space-sm: 0.5rem (8px)
/// - space-md: 1rem (16px)
/// - space-lg: 1.5rem (24px)
/// - space-xl: 2.5rem (40px)
/// - margin / gutter scales: 16px (mobile) / 24px (desktop) / 48px (page margin)
class CivicFixSpacing {
  CivicFixSpacing._();

  // Design.md Modular Scale
  static const double spaceXs = 4.0; // 0.25rem
  static const double spaceSm = 8.0; // 0.5rem
  static const double spaceMd = 16.0; // 1.0rem
  static const double spaceLg = 24.0; // 1.5rem
  static const double spaceXl = 40.0; // 2.5rem

  // Base Scale Aliases
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0; // Legacy 12px step
  static const double lg = 16.0; // Legacy 16px step
  static const double xl = 24.0; // Legacy 24px step
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;

  // Responsive Gutters & Margins (Design.md)
  static const double gutterMobile = 16.0; // 1rem
  static const double gutter = 24.0; // 1.5rem
  static const double marginMobile = 16.0; // 1rem
  static const double margin = 48.0; // 3rem

  // Screen Padding
  static const double screenPaddingMobile = 16.0;
  static const double screenPaddingWide = 24.0;

  // Interactive Target Metrics
  static const double minTouchTarget = 48.0;
  static const double inputHeight = 42.0;
  static const double searchBarHeight = 48.0;
  static const double buttonHeight = 48.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

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

  // Inset Helpers
  static const EdgeInsets pagePadding = EdgeInsets.all(screenPaddingMobile);
  static const EdgeInsets pagePaddingWide = EdgeInsets.all(screenPaddingWide);
  static const EdgeInsets cardPadding = EdgeInsets.all(
    spaceMd,
  ); // 16px Design.md card padding
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(
    spaceLg,
  ); // 24px Design.md section padding
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(
    spaceSm,
  ); // 8px compact grouping
  static const EdgeInsets dialogPadding = EdgeInsets.all(spaceLg); // 24px
  static const EdgeInsets formSectionPadding = EdgeInsets.symmetric(
    vertical: spaceMd,
  );
}

/// Centralized Responsive Breakpoint Tokens.
///
/// Follows Design.md standard responsive framework:
/// - Mobile: < 768px (4 columns, 16px margins/gutters)
/// - Tablet: 768px â€“ 1279px (8 columns, 24px margins, 20-24px gutters)
/// - Desktop: 1280px+ (12 columns, 48px margins, 24px gutters, max content 1280px)
class CivicFixBreakpoints {
  CivicFixBreakpoints._();

  static const double mobile = 768.0;
  static const double tablet = 1280.0;
  static const double desktop = 1280.0;
  static const double largeDesktop = 1440.0;

  // Maximum width constraints
  static const double maxContentWidth = 1280.0;
  static const double maxFormWidth = 680.0;
  static const double maxCardWidth = 480.0;
  static const double maxDashboardWidth = 1440.0;

  // Responsive helpers
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

/// Centralized Shape & Radius Primitives.
///
/// Follows Design.md Soft (Level 1) Geometry:
/// - sm: 0.125rem (2px)
/// - DEFAULT: 0.25rem (4px)
/// - md: 0.375rem (6px)
/// - lg: 0.5rem (8px)
/// - xl: 0.75rem (12px)
/// - full: 9999px (Pill / Status Badges)
class CivicFixRadius {
  CivicFixRadius._();

  // Core Radius Scales
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 2.0; // 0.125rem
  static const double base = 4.0; // 0.25rem (DEFAULT)
  static const double md = 6.0; // 0.375rem
  static const double lg = 8.0; // 0.5rem
  static const double xl = 12.0; // 0.75rem
  static const double sheet = 16.0; // Modal / Sheet Top
  static const double full = 9999.0; // 9999px (Pill)

  // Semantic Component Radii
  static const double button = base; // 4px sharp architectural
  static const double input = base; // 4px form controls
  static const double card = lg; // 8px structural card
  static const double largeContainer = xl; // 12px modal / dialog
  static const double chip = full; // 9999px status pill

  // BorderRadius Objects
  static const BorderRadius xsBorder = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius baseRadius = BorderRadius.all(
    Radius.circular(base),
  );
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullRadius = BorderRadius.all(
    Radius.circular(full),
  );

  // Semantic BorderRadius Helpers
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius largeContainerRadius = BorderRadius.all(
    Radius.circular(largeContainer),
  );
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(chip),
  );
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Centralized Typography Tokens.
///
/// Follows Design.md specifications:
/// - Headings: Plus Jakarta Sans with subtle negative letter spacing
/// - Body & Transactional UI: Inter with high legibility and relaxed line height
class CivicFixTypographyTokens {
  CivicFixTypographyTokens._();

  static const String fontFamilyHeadings = 'Plus Jakarta Sans';
  static const String fontFamilyBody = 'Inter';

  static const List<String> fallbackSans = [
    'Inter',
    'Roboto',
    'Noto Sans Devanagari',
    'Nirmala UI',
    'Mangal',
    'Segoe UI',
    'Arial',
    'sans-serif',
  ];

  // ===========================================================================
  // HEADINGS (Plus Jakarta Sans)
  // ===========================================================================

  /// Headline XL (Desktop): 40px, Bold (w700), height 1.2, tracking -0.02em
  static const TextStyle headlineXl = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontFamilyFallback: fallbackSans,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 48 / 40,
    letterSpacing: -0.8,
    color: CivicFixColors.textPrimary,
  );

  /// Headline XL (Mobile): 30px, Bold (w700), height 1.267, tracking -0.015em
  static const TextStyle headlineXlMobile = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontFamilyFallback: fallbackSans,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 38 / 30,
    letterSpacing: -0.45,
    color: CivicFixColors.textPrimary,
  );

  /// Headline LG (Desktop): 32px, Bold (w700), height 1.25, tracking -0.015em
  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontFamilyFallback: fallbackSans,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.48,
    color: CivicFixColors.textPrimary,
  );

  /// Headline LG (Mobile): 24px, Bold (w700), height 1.333, tracking -0.01em
  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontFamilyFallback: fallbackSans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.24,
    color: CivicFixColors.textPrimary,
  );

  /// Headline MD: 24px, SemiBold (w600), height 1.333, tracking -0.01em
  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontFamilyFallback: fallbackSans,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.24,
    color: CivicFixColors.textPrimary,
  );

  /// Headline SM: 20px, SemiBold (w600), height 1.4, tracking -0.005em
  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontFamilyFallback: fallbackSans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.1,
    color: CivicFixColors.textPrimary,
  );

  /// Title MD: 16px, SemiBold (w600), height 1.5, tracking 0
  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamilyHeadings,
    fontFamilyFallback: fallbackSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0,
    color: CivicFixColors.textPrimary,
  );

  // ===========================================================================
  // BODY & TRANSACTIONAL UI (Inter)
  // ===========================================================================

  /// Body LG: 18px, Regular (w400), height 1.556, tracking -0.005em
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fallbackSans,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    letterSpacing: -0.09,
    color: CivicFixColors.readingText,
  );

  /// Body MD: 15px, Regular (w400), height 1.6, tracking 0
  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fallbackSans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 24 / 15,
    letterSpacing: 0,
    color: CivicFixColors.readingText,
  );

  /// Body SM: 13px, Regular (w400), height 1.538, tracking 0
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fallbackSans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 20 / 13,
    letterSpacing: 0,
    color: CivicFixColors.textSecondary,
  );

  /// Label MD: 12px, SemiBold (w600), height 1.333, tracking +0.04em (+0.48px)
  static const TextStyle labelMd = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fallbackSans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.48,
    color: CivicFixColors.textPrimary,
  );

  /// Label SM: 11px, SemiBold (w600), height 1.273, tracking +0.06em (+0.66px)
  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fallbackSans,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.66,
    color: CivicFixColors.textSecondary,
  );
}

/// Centralized Elevation & Depth System.
///
/// Follows Design.md:
/// - Visual hierarchy relies on crisp, architectural tonal layering and hairline outlines.
/// - Shadows are minimal, ultra-diffuse, and tinted with deep slate (`rgba(15, 23, 42, ...)`).
class CivicFixElevation {
  CivicFixElevation._();

  /// Flat / Zero Elevation
  static const List<BoxShadow> none = [];

  /// Subtle Elevation: Soft 1px shadow
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% deep slate
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  /// Card Elevation: Clean architectural card lift
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% deep slate
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Floating Elevation (Modals, Palettes, Floating Bars):
  /// Corresponds to: `0 10px 25px -5px rgba(15, 23, 42, 0.04), 0 8px 10px -6px rgba(15, 23, 42, 0.02)`
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x0A0F172A),
      offset: Offset(0, 10),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x050F172A),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  /// Hairline Border Side (1px solid #E2E8F0)
  static const BorderSide hairlineBorder = BorderSide(
    color: CivicFixColors.border,
    width: 1.0,
  );

  /// Active / Focus Border Side
  static const BorderSide activeBorder = BorderSide(
    color: CivicFixColors.secondaryAuthority,
    width: 1.0,
  );

  /// Gold Accent Border Side
  static const BorderSide goldBorder = BorderSide(
    color: CivicFixColors.primaryAccent,
    width: 1.0,
  );
}

/// Legacy Typography Bridge for CivicFix.
///
/// Aliases the authoritative [CivicFixTypographyTokens] for backward compatibility.
class CivicFixTypography {
  CivicFixTypography._();

  static const TextStyle display = CivicFixTypographyTokens.headlineLg;
  static const TextStyle h1 = CivicFixTypographyTokens.headlineLgMobile;
  static const TextStyle h2 = CivicFixTypographyTokens.headlineMd;
  static const TextStyle h3 = CivicFixTypographyTokens.headlineSm;
  static const TextStyle bodyLarge = CivicFixTypographyTokens.bodyLg;
  static const TextStyle bodyLargeMedium = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 28 / 18,
    letterSpacing: -0.09,
    color: CivicFixColors.readingText,
  );
  static const TextStyle body = CivicFixTypographyTokens.bodyMd;
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 24 / 15,
    letterSpacing: 0,
    color: CivicFixColors.readingText,
  );
  static const TextStyle bodySmall = CivicFixTypographyTokens.bodySm;
  static const TextStyle bodySmallMedium = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 20 / 13,
    letterSpacing: 0,
    color: CivicFixColors.textSecondary,
  );
  static const TextStyle caption = CivicFixTypographyTokens.labelSm;
  static const TextStyle captionMedium = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 14 / 11,
    letterSpacing: 0.66,
    color: CivicFixColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyHeadings,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0,
  );
  static const TextStyle statusBadge = CivicFixTypographyTokens.labelMd;
}
