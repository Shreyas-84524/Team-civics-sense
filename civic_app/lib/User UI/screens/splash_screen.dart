import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../services/mock_auth_service.dart';

/// Polished Splash Screen checking mock authentication state before routing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = MockAuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final stopwatch = Stopwatch()..start();
    final isAuthenticated = await _authService.checkAuthState();
    final elapsed = stopwatch.elapsedMilliseconds;

    // Minimum display duration to feel calm and avoid sudden flicker (approx 1200ms)
    final remaining = 1200 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
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
