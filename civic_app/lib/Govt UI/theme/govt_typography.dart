import 'package:flutter/material.dart';
import 'govt_theme_tokens.dart';

/// Standardized typography hierarchy for the CivicFix Government Portal.
///
/// Designed for high readability, municipal operations software, data density,
/// and clear hierarchical scanning on desktop, tablet, and mobile views.
class GovtTypography {
  GovtTypography._();

  /// Large display titles for major dashboard banners or splash screens (32px).
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: GovtThemeTokens.textPrimary,
  );

  /// Primary page header title (24px).
  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    color: GovtThemeTokens.textPrimary,
  );

  /// Major section header title (18px).
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: GovtThemeTokens.textPrimary,
  );

  /// Card / widget container title (16px).
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: GovtThemeTokens.textPrimary,
  );

  /// Primary body copy for prominent readouts or introductions (16px).
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: GovtThemeTokens.textPrimary,
  );

  /// Standard operational body copy (14px).
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.45,
    color: GovtThemeTokens.textPrimary,
  );

  /// Secondary or dense tabular body copy (12px).
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
    color: GovtThemeTokens.textSecondary,
  );

  /// Field labels, table headers, and form inputs (12px, semi-bold).
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.3,
    color: GovtThemeTokens.textPrimary,
  );

  /// Metadata, timestamps, and subtle hints (11px).
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.3,
    color: GovtThemeTokens.textSecondary,
  );

  /// Large numerical metrics and primary KPI readouts (28px, tabular).
  static const TextStyle metricLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
    color: GovtThemeTokens.textPrimary,
  );

  /// Medium / standard numerical metrics and secondary KPI readouts (20px, tabular).
  static const TextStyle metricSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
    fontFeatures: [FontFeature.tabularFigures()],
    color: GovtThemeTokens.textPrimary,
  );
}
