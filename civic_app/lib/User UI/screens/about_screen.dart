import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';

/// Screen presenting CivicFix mission, app version, credits, and links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'About CivicFix',
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: CivicFixSpacing.pagePadding,
            child: Column(
              children: [
                CivicFixSpacing.vSpaceLg,

                // Branding Logo Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CivicFixColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CivicFixColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
                CivicFixSpacing.vSpaceMd,

                Text(
                  AppConstants.appName,
                  style: CivicFixTypography.h1.copyWith(
                    color: CivicFixColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  'Version 1.0.0 (Phase 1 Citizen UI)',
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: CivicFixColors.secondaryText,
                  ),
                ),
                CivicFixSpacing.vSpaceLg,

                // Mission Card
                CivicFixCard(
                  padding: const EdgeInsets.all(CivicFixSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        'Making civic issue reporting more transparent, accessible, and connected.',
                        style: CivicFixTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: CivicFixColors.primaryText,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      CivicFixSpacing.vSpaceMd,
                      Text(
                        'CivicFix bridges the gap between citizens and municipal municipal departments. By empowering citizens with geotagged reporting, transparent five-stage progress tracking, and neighborhood hazard maps, we create safer, cleaner, and better-maintained communities.',
                        style: CivicFixTypography.caption.copyWith(
                          color: CivicFixColors.secondaryText,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceXl,

                // Key Capabilities
                CivicFixCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildFeatureTile(
                        icon: Icons.timeline_rounded,
                        title: 'Five-Stage Lifecycle Tracking',
                        subtitle: 'Transparent accountability from Reported to Resolved',
                      ),
                      const Divider(height: 1),
                      _buildFeatureTile(
                        icon: Icons.map_rounded,
                        title: 'Interactive Hazard Map',
                        subtitle: 'Live geotagged awareness for road, water, and lighting safety',
                      ),
                      const Divider(height: 1),
                      _buildFeatureTile(
                        icon: Icons.stars_rounded,
                        title: 'Civic Recognition & Rewards',
                        subtitle: 'Incentivizing responsible community participation',
                      ),
                      const Divider(height: 1),
                      _buildFeatureTile(
                        icon: Icons.translate_rounded,
                        title: 'Multi-lingual Inclusivity',
                        subtitle: 'Supporting English, हिन्दी, and मराठी for citizen accessibility',
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceXl,

                // Legal and Terms Placeholders
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CivicFix Terms of Service (Standard Civic Engagement Agreement)')),
                        );
                      },
                      child: const Text('Terms of Service'),
                    ),
                    const Text('•', style: TextStyle(color: CivicFixColors.disabledText)),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CivicFix Privacy Policy (Strict Citizen Data Protection)')),
                        );
                      },
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
                CivicFixSpacing.vSpaceSm,

                Text(
                  '© 2026 CivicFix Engagement Platform. All rights reserved.',
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.disabledText,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                CivicFixSpacing.vSpaceXxl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CivicFixColors.surfaceMuted,
          borderRadius: CivicFixRadius.chipRadius,
        ),
        child: Icon(icon, color: CivicFixColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: CivicFixTypography.bodySmallMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: CivicFixTypography.caption.copyWith(color: CivicFixColors.secondaryText),
      ),
    );
  }
}
