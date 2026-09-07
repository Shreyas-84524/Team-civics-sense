import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/civic_fix_app_bar.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_header.dart';

/// Screen communicating CivicFix privacy principles and public hazard map confidentiality safeguards.
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivicFixColors.background,
      appBar: const CivicFixAppBar(
        title: 'Privacy & Safety',
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: CivicFixSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Security Shield Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(CivicFixSpacing.lg),
                  decoration: BoxDecoration(
                    color: CivicFixColors.statusResolvedBg,
                    borderRadius: CivicFixRadius.cardRadius,
                    border: Border.all(
                      color: CivicFixColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: CivicFixColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      CivicFixSpacing.hSpaceMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Citizen Privacy Guaranteed',
                              style: CivicFixTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: CivicFixColors.secondaryDark,
                              ),
                            ),
                            CivicFixSpacing.vSpaceXs,
                            Text(
                              'Your personal details remain confidential at all stages of complaint resolution.',
                              style: CivicFixTypography.caption.copyWith(
                                color: CivicFixColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CivicFixSpacing.vSpaceXl,

                const SectionHeader(
                  title: 'Privacy Principles',
                  subtitle: 'How CivicFix handles citizen data',
                ),
                CivicFixSpacing.vSpaceSm,

                _buildPrivacyCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Personal Identity Confidentiality',
                  description:
                      'Your email, phone number, and full name are never exposed on public hazard map markers or public feeds. Only authorized municipal desk officers can view contact details to follow up.',
                ),
                CivicFixSpacing.vSpaceMd,

                _buildPrivacyCard(
                  icon: Icons.map_outlined,
                  title: 'Public Civic Issue Visibility',
                  description:
                      'To avoid duplicate reports and foster community collaboration, issue categories, descriptions, and geotagged map pins are shared publicly. No citizen identity is attached to public pins.',
                ),
                CivicFixSpacing.vSpaceMd,

                _buildPrivacyCard(
                  icon: Icons.location_searching_rounded,
                  title: 'Location Services & GPS Usage',
                  description:
                      'GPS coordinates are queried solely when you tap "Use My Location" during issue reporting or centering the Hazard Map. CivicFix does not track continuous background movement.',
                ),
                CivicFixSpacing.vSpaceMd,

                _buildPrivacyCard(
                  icon: Icons.camera_alt_outlined,
                  title: 'Evidence Photos & EXIF Stripping',
                  description:
                      'Uploaded evidence images are used solely for municipal inspection and verification. Private device metadata is sanitized during submission.',
                ),
                CivicFixSpacing.vSpaceXxl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CivicFixColors.surfaceMuted,
              borderRadius: CivicFixRadius.chipRadius,
              border: Border.all(color: CivicFixColors.border),
            ),
            child: Icon(icon, color: CivicFixColors.primary, size: 20),
          ),
          CivicFixSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CivicFixTypography.bodySmallMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CivicFixColors.primaryText,
                  ),
                ),
                CivicFixSpacing.vSpaceXs,
                Text(
                  description,
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
