import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../services/mock_auth_service.dart';

/// Temporary User Home placeholder strictly to verify post-authentication navigation.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockAuthService().currentUser;
    final userName = user?.fullName ?? 'Citizen';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: AppBar(
        title: const Text('CivicFix'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await MockAuthService().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: CivicFixSpacing.pagePadding,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: CivicFixColors.accentLight,
                    borderRadius: CivicFixRadius.largeContainerRadius,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: CivicFixColors.secondary,
                    size: 40,
                  ),
                ),
                CivicFixSpacing.vSpaceXl,
                Text(
                  'Welcome, $userName!',
                  textAlign: TextAlign.center,
                  style: CivicFixTypography.h2,
                ),
                if (userEmail.isNotEmpty) ...[
                  CivicFixSpacing.vSpaceXs,
                  Text(
                    userEmail,
                    style: CivicFixTypography.bodySmall,
                  ),
                ],
                CivicFixSpacing.vSpaceXl,
                CivicFixCard(
                  child: Column(
                    children: [
                      Text(
                        'CivicFix',
                        style: CivicFixTypography.h3.copyWith(color: CivicFixColors.primary),
                      ),
                      CivicFixSpacing.vSpaceSm,
                      Text(
                        'Home screen coming next.',
                        textAlign: TextAlign.center,
                        style: CivicFixTypography.bodySmall.copyWith(
                          color: CivicFixColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceXxl,
                CivicFixButton(
                  text: 'Sign Out',
                  icon: Icons.logout_rounded,
                  backgroundColor: CivicFixColors.primary,
                  onPressed: () async {
                    await MockAuthService().logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
