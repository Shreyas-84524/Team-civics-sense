import 'package:flutter/material.dart';
import 'govt_theme_tokens.dart';

/// Supported responsive device classification for CivicFix Government Portal.
enum GovtDeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop;

  bool get isMobile => this == GovtDeviceType.mobile;
  bool get isTablet => this == GovtDeviceType.tablet;
  bool get isDesktop => this == GovtDeviceType.desktop;
  bool get isLargeDesktop => this == GovtDeviceType.largeDesktop;
  bool get isDesktopOrLarger => isDesktop || isLargeDesktop;
}

/// Centralized responsive layout utilities for municipal portal views.
class GovtResponsive {
  GovtResponsive._();

  /// Determines current device classification based on screen width.
  static GovtDeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= GovtThemeTokens.largeDesktopBreakpoint) {
      return GovtDeviceType.largeDesktop;
    } else if (width >= GovtThemeTokens.desktopBreakpoint) {
      return GovtDeviceType.desktop;
    } else if (width >= GovtThemeTokens.tabletBreakpoint) {
      return GovtDeviceType.tablet;
    }
    return GovtDeviceType.mobile;
  }

  /// True if current width is below tablet breakpoint (< 640px).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < GovtThemeTokens.tabletBreakpoint;

  /// True if current width is in tablet range (640px to 959px).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= GovtThemeTokens.tabletBreakpoint &&
        width < GovtThemeTokens.desktopBreakpoint;
  }

  /// True if current width is in desktop range (960px to 1439px).
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= GovtThemeTokens.desktopBreakpoint &&
        width < GovtThemeTokens.largeDesktopBreakpoint;
  }

  /// True if current width is at or above large desktop (>= 1440px).
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= GovtThemeTokens.largeDesktopBreakpoint;

  /// True if current width is desktop or large desktop (>= 960px).
  static bool isDesktopOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= GovtThemeTokens.desktopBreakpoint;

  /// Selects a responsive value according to current device category.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case GovtDeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case GovtDeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case GovtDeviceType.tablet:
        return tablet ?? mobile;
      case GovtDeviceType.mobile:
        return mobile;
    }
  }
}

/// Widget builder that adapts its subtree according to [GovtDeviceType].
class GovtResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, GovtDeviceType deviceType) builder;

  const GovtResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = GovtResponsive.getDeviceType(context);
    return builder(context, deviceType);
  }
}
