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
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthServiceLocator.citizenAuth;
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    bool isGovt = false;
    bool isVerifiedCitizen = false;
    bool isUnverifiedCitizen = false;

    // Check active Citizen / Firebase Auth session and resolve role
    final hasCitizenAuth = await _authService.checkAuthState();
    if (hasCitizenAuth) {
      final role = _authService.currentUser?.role;
      if (role == 'government' || role == 'admin') {
        isGovt = true;
      } else {
        final citizen = _authService.currentUser;
        if (citizen != null) {
          if (citizen.phoneVerified) {
            isVerifiedCitizen = true;
          } else {
            isUnverifiedCitizen = true;
          }
        }
      }
    } else {
      // Fallback check for separate Government Auth session
      final govtAuth = AuthServiceLocator.govtAuth;
      if (govtAuth.isAuthenticated || (await govtAuth.checkAuthState())) {
        final govtUser = await govtAuth.getCurrentUser();
        if (govtUser != null && (govtUser.role == 'government' || govtUser.role == 'admin')) {
          isGovt = true;
        }
      }
    }

    if (!mounted) return;

    final elapsed = stopwatch.elapsedMilliseconds;
    // Minimum display duration to feel calm and avoid sudden flicker (approx 1200ms)
    final remaining = 1200 - elapsed;
    if (remaining > 0) {
      final completer = Completer<void>();
      _splashTimer = Timer(Duration(milliseconds: remaining), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future;
    }

    if (!mounted) return;

    if (isGovt) {
      Navigator.pushReplacementNamed(context, AppRoutes.govtDashboard);
    } else if (isVerifiedCitizen) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (isUnverifiedCitizen) {
      Navigator.pushReplacementNamed(context, AppRoutes.verifyPhone);
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
