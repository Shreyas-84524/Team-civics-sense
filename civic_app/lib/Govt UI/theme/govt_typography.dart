import 'package:flutter/material.dart';
import '../../core/theme/civicfix_design_tokens.dart';
import 'govt_theme_tokens.dart';

/// Standardized typography hierarchy for the CivicFix Government Portal.
///
/// Anchored on Plus Jakarta Sans (Headings/Metrics) and Inter (Body/Labels)
/// derived from `civicfix_design_tokens.dart` and `DESIGN.md`.
class GovtTypography {
  GovtTypography._();

  /// Large display titles for major dashboard banners or splash screens (32px).
  static const TextStyle displayLarge = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyHeadings,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.48,
    height: 40 / 32,
    color: GovtThemeTokens.textPrimary,
  );

  /// Primary page header title (24px).
  static const TextStyle pageTitle = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyHeadings,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.24,
    height: 32 / 24,
    color: GovtThemeTokens.textPrimary,
  );

  /// Major section header title (18px).
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyHeadings,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 24 / 18,
    color: GovtThemeTokens.textPrimary,
  );

  /// Card / widget container title (16px).
  static const TextStyle cardTitle = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyHeadings,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 24 / 16,
    color: GovtThemeTokens.textPrimary,
  );

  /// Primary body copy for prominent readouts or introductions (16px).
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 24 / 16,
    color: GovtThemeTokens.textPrimary,
  );

  /// Standard operational body copy (14px).
  static const TextStyle body = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 20 / 14,
    color: GovtThemeTokens.textPrimary,
  );

  /// Secondary or dense tabular body copy (12px).
  static const TextStyle bodySmall = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 16 / 12,
    color: GovtThemeTokens.textSecondary,
  );

  /// Field labels, table headers, and form inputs (12px, semi-bold).
  static const TextStyle label = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.48,
    height: 16 / 12,
    color: GovtThemeTokens.textPrimary,
  );

  /// Metadata, timestamps, and subtle hints (11px).
  static const TextStyle caption = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyBody,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.66,
    height: 14 / 11,
    color: GovtThemeTokens.textSecondary,
  );

  /// Large numerical metrics and primary KPI readouts (28px, tabular).
  static const TextStyle metricLarge = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyHeadings,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 34 / 28,
    fontFeatures: [FontFeature.tabularFigures()],
    color: GovtThemeTokens.textPrimary,
  );

  /// Medium / standard numerical metrics and secondary KPI readouts (20px, tabular).
  static const TextStyle metricSmall = TextStyle(
    fontFamily: CivicFixTypographyTokens.fontFamilyHeadings,
    fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 26 / 20,
    fontFeatures: [FontFeature.tabularFigures()],
    color: GovtThemeTokens.textPrimary,
  );
}
