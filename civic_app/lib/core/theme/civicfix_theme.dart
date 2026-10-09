import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'civicfix_design_tokens.dart';

/// Centralized CivicFix Material 3 Theme System.
///
/// Built on the authoritative tokens defined in `civicfix_design_tokens.dart`
/// adhering to the "Civic Precision — Editorial Minimalism" design specification.
class CivicFixTheme {
  CivicFixTheme._();

  /// Authoritative Material 3 ColorScheme derived from Design.md tokens.
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    // Primary Brand (Institutional Gold / Amber foundation)
    primary: CivicFixColors.primary,
    onPrimary: CivicFixColors.onPrimary,
    primaryContainer: CivicFixColors.primaryContainer,
    onPrimaryContainer: CivicFixColors.onPrimaryContainer,
    inversePrimary: CivicFixColors.inversePrimary,

    // Secondary Authority (Deep Slate)
    secondary: CivicFixColors.secondary,
    onSecondary: CivicFixColors.onSecondary,
    secondaryContainer: CivicFixColors.secondaryContainer,
    onSecondaryContainer: CivicFixColors.onSecondaryContainer,

    // Tertiary
    tertiary: CivicFixColors.tertiary,
    onTertiary: CivicFixColors.onTertiary,
    tertiaryContainer: CivicFixColors.tertiaryContainer,
    onTertiaryContainer: CivicFixColors.onTertiaryContainer,

    // Semantic Error
    error: CivicFixColors.error,
    onError: CivicFixColors.onError,
    errorContainer: CivicFixColors.errorContainer,
    onErrorContainer: CivicFixColors.onErrorContainer,

    // Surfaces & Canvas
    surface: CivicFixColors.surface,
    onSurface: CivicFixColors.textPrimary,
    onSurfaceVariant: CivicFixColors.textSecondary,
    surfaceContainerLowest: CivicFixColors.surfaceContainerLowest,
    surfaceContainerLow: CivicFixColors.surfaceContainerLow,
    surfaceContainer: CivicFixColors.surfaceContainer,
    surfaceContainerHigh: CivicFixColors.surfaceContainerHigh,
    surfaceContainerHighest: CivicFixColors.surfaceContainerHighest,
    inverseSurface: CivicFixColors.inverseSurface,
    onInverseSurface: CivicFixColors.inverseOnSurface,
    surfaceTint: CivicFixColors.surfaceTint,

    // Outlines & Borders
    outline: CivicFixColors.outline,
    outlineVariant: CivicFixColors.border,

    // Scrim & Shadow
    shadow: CivicFixColors.secondaryAuthority,
    scrim: CivicFixColors.secondaryAuthority,
  );

  /// Authoritative TextTheme combining Plus Jakarta Sans (Headings) and Inter (Body).
  static const TextTheme textTheme = TextTheme(
    displayLarge: CivicFixTypographyTokens.headlineXl,
    displayMedium: CivicFixTypographyTokens.headlineLg,
    displaySmall: CivicFixTypographyTokens.headlineMd,
    headlineLarge: CivicFixTypographyTokens.headlineLg,
    headlineMedium: CivicFixTypographyTokens.headlineMd,
    headlineSmall: CivicFixTypographyTokens.headlineSm,
    titleLarge: CivicFixTypographyTokens.headlineSm,
    titleMedium: CivicFixTypographyTokens.titleMd,
    titleSmall: CivicFixTypographyTokens.labelMd,
    bodyLarge: CivicFixTypographyTokens.bodyLg,
    bodyMedium: CivicFixTypographyTokens.bodyMd,
    bodySmall: CivicFixTypographyTokens.bodySm,
    labelLarge: CivicFixTypographyTokens.labelMd,
    labelMedium: CivicFixTypographyTokens.labelMd,
    labelSmall: CivicFixTypographyTokens.labelSm,
  );

  /// Builds the global CivicFix ThemeData.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: CivicFixColors.canvas,
      fontFamily: CivicFixTypographyTokens.fontFamilyBody,
      fontFamilyFallback: CivicFixTypographyTokens.fallbackSans,
      textTheme: textTheme,

      // 1. AppBar Theme — Clean porcelain bar with deep slate header
      appBarTheme: const AppBarTheme(
        backgroundColor: CivicFixColors.surface,
        foregroundColor: CivicFixColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: CivicFixColors.textPrimary,
          size: CivicFixSpacing.iconLg,
        ),
        actionsIconTheme: IconThemeData(
          color: CivicFixColors.textPrimary,
          size: CivicFixSpacing.iconLg,
        ),
        titleTextStyle: CivicFixTypographyTokens.titleMd,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // 2. Card Theme — Pure white elevated card with 1px hairline border and 8px radius
      cardTheme: CardThemeData(
        color: CivicFixColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: CivicFixRadius.cardRadius,
          side: CivicFixElevation.hairlineBorder,
        ),
      ),

      // 3. Primary Action Button Theme (Deep Charcoal Slate)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CivicFixColors.secondaryAuthority,
          foregroundColor: CivicFixColors.onSecondary,
          disabledBackgroundColor: CivicFixColors.border,
          disabledForegroundColor: CivicFixColors.textDisabled,
          minimumSize: const Size(CivicFixSpacing.minTouchTarget, CivicFixSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.spaceLg,
            vertical: CivicFixSpacing.spaceMd,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          elevation: 0,
          textStyle: CivicFixTypographyTokens.titleMd.copyWith(
            color: CivicFixColors.onSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 4. Filled Button Theme (High-Priority / Accent CTA — Burnished Gold)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CivicFixColors.primaryAccent,
          foregroundColor: CivicFixColors.onPrimary,
          disabledBackgroundColor: CivicFixColors.borderLight,
          disabledForegroundColor: CivicFixColors.textDisabled,
          minimumSize: const Size(CivicFixSpacing.minTouchTarget, CivicFixSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.spaceLg,
            vertical: CivicFixSpacing.spaceMd,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          elevation: 0,
          textStyle: CivicFixTypographyTokens.titleMd.copyWith(
            color: CivicFixColors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 5. Secondary (Prestige) Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: CivicFixColors.surfaceContainerLowest,
          foregroundColor: CivicFixColors.secondaryAuthority,
          disabledForegroundColor: CivicFixColors.textDisabled,
          minimumSize: const Size(CivicFixSpacing.minTouchTarget, CivicFixSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.spaceLg,
            vertical: CivicFixSpacing.spaceMd,
          ),
          side: CivicFixElevation.hairlineBorder,
          shape: const RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          elevation: 0,
          textStyle: CivicFixTypographyTokens.titleMd.copyWith(
            color: CivicFixColors.secondaryAuthority,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 6. Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CivicFixColors.secondaryAuthority,
          disabledForegroundColor: CivicFixColors.textDisabled,
          minimumSize: const Size(CivicFixSpacing.minTouchTarget, CivicFixSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.spaceMd,
            vertical: CivicFixSpacing.spaceSm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: CivicFixRadius.buttonRadius,
          ),
          textStyle: CivicFixTypographyTokens.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 7. Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: CivicFixColors.textPrimary,
          disabledForegroundColor: CivicFixColors.textDisabled,
          highlightColor: CivicFixColors.surfaceContainer,
          shape: const RoundedRectangleBorder(
            borderRadius: CivicFixRadius.baseRadius,
          ),
        ),
      ),

      // 8. Input Decoration Theme — 42px height, 1px solid #E2E8F0 on #FFFFFF, 4px radius
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: CivicFixColors.surfaceContainerLowest,
        contentPadding: EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceMd,
          vertical: CivicFixSpacing.spaceMd,
        ),
        hintStyle: CivicFixTypographyTokens.bodyMd,
        labelStyle: CivicFixTypographyTokens.labelMd,
        border: OutlineInputBorder(
          borderRadius: CivicFixRadius.inputRadius,
          borderSide: CivicFixElevation.hairlineBorder,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.inputRadius,
          borderSide: CivicFixElevation.hairlineBorder,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.inputRadius,
          borderSide: BorderSide(
            color: CivicFixColors.secondaryAuthority,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.inputRadius,
          borderSide: BorderSide(
            color: CivicFixColors.error,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: CivicFixRadius.inputRadius,
          borderSide: BorderSide(
            color: CivicFixColors.error,
            width: 1.5,
          ),
        ),
      ),

      // 9. SearchBar Theme — 48px height institutional search field
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll<double>(0),
        backgroundColor: const WidgetStatePropertyAll<Color>(CivicFixColors.surfaceContainerLowest),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: CivicFixRadius.baseRadius,
            side: CivicFixElevation.hairlineBorder,
          ),
        ),
        hintStyle: const WidgetStatePropertyAll<TextStyle>(CivicFixTypographyTokens.bodyMd),
        textStyle: const WidgetStatePropertyAll<TextStyle>(CivicFixTypographyTokens.bodyMd),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: CivicFixSpacing.spaceMd),
        ),
      ),

      // 10. SearchView Theme
      searchViewTheme: const SearchViewThemeData(
        backgroundColor: CivicFixColors.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // 11. Checkbox Theme — 18px square with 1.5px border, fills with #0F172A when active
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return CivicFixColors.secondaryAuthority;
          }
          if (states.contains(WidgetState.disabled)) {
            return CivicFixColors.borderLight;
          }
          return CivicFixColors.surfaceContainerLowest;
        }),
        checkColor: const WidgetStatePropertyAll<Color>(CivicFixColors.onSecondary),
        side: const BorderSide(color: CivicFixColors.textMuted, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: CivicFixRadius.smRadius),
      ),

      // 12. Radio Theme — Fills with #0F172A when active
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return CivicFixColors.secondaryAuthority;
          }
          if (states.contains(WidgetState.disabled)) {
            return CivicFixColors.textDisabled;
          }
          return CivicFixColors.textMuted;
        }),
      ),

      // 13. Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return CivicFixColors.surfaceContainerLowest;
          }
          return CivicFixColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return CivicFixColors.secondaryAuthority;
          }
          return CivicFixColors.border;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),

      // 14. Chip Theme — Pill badges with 1px border
      chipTheme: ChipThemeData(
        backgroundColor: CivicFixColors.badgeNeutralBg,
        disabledColor: CivicFixColors.borderLight,
        selectedColor: CivicFixColors.badgeVerifiedBg,
        secondarySelectedColor: CivicFixColors.badgeProcessingBg,
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceSm,
          vertical: CivicFixSpacing.spaceXs,
        ),
        labelStyle: CivicFixTypographyTokens.labelSm,
        shape: const RoundedRectangleBorder(
          borderRadius: CivicFixRadius.chipRadius,
          side: BorderSide(
            color: CivicFixColors.border,
            width: 1,
          ),
        ),
      ),

      // 15. Divider Theme — 1px #F1F5F9
      dividerTheme: const DividerThemeData(
        color: CivicFixColors.divider,
        thickness: 1,
        space: 1,
      ),

      // 16. Dialog Theme — 12px architectural modal
      dialogTheme: DialogThemeData(
        backgroundColor: CivicFixColors.surfaceContainerLowest,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: CivicFixRadius.largeContainerRadius,
          side: CivicFixElevation.hairlineBorder,
        ),
        titleTextStyle: CivicFixTypographyTokens.headlineSm,
        contentTextStyle: CivicFixTypographyTokens.bodyMd,
      ),

      // 17. Bottom Sheet Theme — 16px top radius, pure white surface
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CivicFixColors.surfaceContainerLowest,
        modalBackgroundColor: CivicFixColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CivicFixRadius.sheetRadius,
        ),
        dragHandleColor: CivicFixColors.borderStrong,
        showDragHandle: true,
      ),

      // 18. NavigationBar Theme (M3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CivicFixColors.surfaceContainerLowest,
        elevation: 0,
        indicatorColor: CivicFixColors.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return CivicFixTypographyTokens.labelSm.copyWith(
              color: CivicFixColors.primaryAccent,
              fontWeight: FontWeight.w600,
            );
          }
          return CivicFixTypographyTokens.labelSm.copyWith(
            color: CivicFixColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: CivicFixColors.primaryAccent,
              size: CivicFixSpacing.iconLg,
            );
          }
          return const IconThemeData(
            color: CivicFixColors.textMuted,
            size: CivicFixSpacing.iconLg,
          );
        }),
      ),

      // 19. NavigationRail Theme (Desktop / Tablet)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: CivicFixColors.surfaceContainerLowest,
        elevation: 0,
        indicatorColor: CivicFixColors.secondaryContainer,
        selectedLabelTextStyle: CivicFixTypographyTokens.labelSm.copyWith(
          color: CivicFixColors.primaryAccent,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: CivicFixTypographyTokens.labelSm.copyWith(
          color: CivicFixColors.textMuted,
        ),
        selectedIconTheme: const IconThemeData(
          color: CivicFixColors.primaryAccent,
          size: CivicFixSpacing.iconLg,
        ),
        unselectedIconTheme: const IconThemeData(
          color: CivicFixColors.textMuted,
          size: CivicFixSpacing.iconLg,
        ),
      ),

      // 20. Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: CivicFixColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: CivicFixColors.border, width: 1),
        ),
      ),

      // 21. ListTile Theme
      listTileTheme: ListTileThemeData(
        tileColor: CivicFixColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceMd,
          vertical: CivicFixSpacing.spaceXs,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: CivicFixRadius.baseRadius,
        ),
        titleTextStyle: CivicFixTypographyTokens.titleMd,
        subtitleTextStyle: CivicFixTypographyTokens.bodySm,
        leadingAndTrailingTextStyle: CivicFixTypographyTokens.labelSm,
        iconColor: CivicFixColors.secondaryAuthority,
      ),

      // 22. ProgressIndicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CivicFixColors.primaryAccent,
        circularTrackColor: CivicFixColors.surfaceContainerLow,
        linearTrackColor: CivicFixColors.surfaceContainerLow,
        linearMinHeight: 4,
      ),

      // 23. Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CivicFixColors.inverseSurface,
          borderRadius: CivicFixRadius.baseRadius,
        ),
        textStyle: CivicFixTypographyTokens.labelSm.copyWith(
          color: CivicFixColors.inverseOnSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.spaceSm,
          vertical: CivicFixSpacing.spaceXs,
        ),
      ),

      // 24. Bottom Navigation Bar Theme (Legacy fixed bar support)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CivicFixColors.surfaceContainerLowest,
        selectedItemColor: CivicFixColors.primaryAccent,
        unselectedItemColor: CivicFixColors.textMuted,
        selectedLabelStyle: CivicFixTypographyTokens.labelSm,
        unselectedLabelStyle: CivicFixTypographyTokens.labelSm,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // 25. Floating Action Button Theme (High-Priority Burnished Gold)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CivicFixColors.primaryAccent,
        foregroundColor: CivicFixColors.onPrimary,
        elevation: 2,
        focusElevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}
