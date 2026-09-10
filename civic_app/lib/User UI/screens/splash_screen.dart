import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_service_locator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';

/// Polished Splash Screen checking authentication state and resolving roles before routing.
class SplashScreen extends StatefulWidget {
  final AuthService? authService;

  const SplashScreen({super.key, this.authService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthServiceLocator.citizenAuth;
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    bool isGovt = false;

    // Check active Firebase Auth session and resolve role
    final hasAuth = await _authService.checkAuthState();
    if (hasAuth) {
      final role = _authService.currentUser?.role;
      if (role == 'government' || role == 'admin') {
        isGovt = true;
      }
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    // Minimum display duration to feel calm and avoid sudden flicker (approx 1200ms)
    final remaining = 1200 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    if (isGovt) {
      Navigator.pushReplacementNamed(context, AppRoutes.govtDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shape-based Brand Mark
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: CivicFixColors.surface,
                  borderRadius: CivicFixRadius.largeContainerRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 44,
                    color: CivicFixColors.primary,
                  ),
                ),
              ),
              CivicFixSpacing.vSpaceXl,

              // App Name
              Text(
                AppConstants.appName,
                style: CivicFixTypography.display.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              CivicFixSpacing.vSpaceSm,

              // Tagline
              Text(
                'Making civic action simple.',
                textAlign: TextAlign.center,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  color: CivicFixColors.accent,
                  letterSpacing: 0.1,
                ),
              ),
              CivicFixSpacing.vSpaceXxl,

              // Subtle Loading Indicator
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(CivicFixColors.accent),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
