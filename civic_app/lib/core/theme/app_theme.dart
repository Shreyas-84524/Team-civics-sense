import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Centralized CivicFix Theme Configuration.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: CivicFixColors.primary,
      onPrimary: Colors.white,
      primaryContainer: CivicFixColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: CivicFixColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: CivicFixColors.accentLight,
      onSecondaryContainer: CivicFixColors.secondaryDark,
      tertiary: CivicFixColors.accent,
      onTertiary: CivicFixColors.primaryDark,
      error: CivicFixColors.error,
      onError: Colors.white,
      surface: CivicFixColors.surface,
      onSurface: CivicFixColors.primaryText,
      surfaceContainerHighest: CivicFixColors.surfaceMuted,
      outline: CivicFixColors.border,
      outlineVariant: CivicFixColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CivicFixColors.background,
      fontFamily: 'Roboto',
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: CivicFixColors.surface,
        foregroundColor: CivicFixColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: CivicFixColors.primaryText,
          size: 24,
        ),
        titleTextStyle: CivicFixTypography.h3,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: CivicFixColors.surface,
        elevation: 0.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: CivicFixRadius.cardRadius,
          side: const BorderSide(
            color: CivicFixColors.border,
            width: 1,
          ),
        ),
      ),

      // Elevated Button Theme (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CivicFixColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, CivicFixSpacing.huge),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.xl,
            vertical: CivicFixSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          elevation: 0,
          textStyle: CivicFixTypography.button,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CivicFixColors.primary,
          minimumSize: const Size(double.infinity, CivicFixSpacing.huge),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.xl,
            vertical: CivicFixSpacing.md,
          ),
          side: const BorderSide(
            color: CivicFixColors.border,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          textStyle: CivicFixTypography.button,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CivicFixColors.secondary,
          minimumSize: const Size(CivicFixSpacing.minTouchTarget, CivicFixSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.sm,
          ),
          textStyle: CivicFixTypography.bodyMedium.copyWith(
            color: CivicFixColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CivicFixColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.lg,
          vertical: CivicFixSpacing.lg,
        ),
        hintStyle: CivicFixTypography.body.copyWith(
          color: CivicFixColors.disabledText,
        ),
        labelStyle: CivicFixTypography.bodySmallMedium.copyWith(
          color: CivicFixColors.secondaryText,
        ),
        border: OutlineInputBorder(
          borderRadius: CivicFixRadius.buttonRadius,
          borderSide: const BorderSide(
            color: CivicFixColors.border,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.buttonRadius,
          borderSide: const BorderSide(
            color: CivicFixColors.border,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.buttonRadius,
          borderSide: const BorderSide(
            color: CivicFixColors.primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.buttonRadius,
          borderSide: const BorderSide(
            color: CivicFixColors.error,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.buttonRadius,
          borderSide: const BorderSide(
            color: CivicFixColors.error,
            width: 1.8,
          ),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CivicFixColors.surface,
        selectedItemColor: CivicFixColors.primary,
        unselectedItemColor: CivicFixColors.secondaryText,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CivicFixColors.secondary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: CivicFixColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
