import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Reusable citizen profile header card with avatar, credentials, and edit trigger.
class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEditPressed;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Initials Fallback
              Semantics(
                label: 'Citizen profile avatar for ${user.fullName}',
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [CivicFixColors.primary, CivicFixColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CivicFixColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: CivicFixTypography.h2.copyWith(
                        color: Colors.white,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceMd,

              // User Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: CivicFixTypography.h3.copyWith(
                        color: CivicFixColors.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      user.email,
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: CivicFixColors.secondaryText,
                      ),
                    ),
                    if (user.phone.isNotEmpty) ...[
                      CivicFixSpacing.vSpaceXs,
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: CivicFixColors.disabledText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.phone,
                            style: CivicFixTypography.caption.copyWith(
                              color: CivicFixColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                    CivicFixSpacing.vSpaceSm,

                    // Jurisdiction & Language Badges
                    Wrap(
                      spacing: CivicFixSpacing.xs,
                      runSpacing: CivicFixSpacing.xs,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CivicFixColors.surfaceMuted,
                            borderRadius: CivicFixRadius.chipRadius,
                            border: Border.all(color: CivicFixColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: CivicFixColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.wardNumber,
                                style: CivicFixTypography.captionMedium.copyWith(
                                  color: CivicFixColors.primaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicFixSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CivicFixColors.accentLight,
                            borderRadius: CivicFixRadius.chipRadius,
                            border: Border.all(
                              color: CivicFixColors.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            user.languageName,
                            style: CivicFixTypography.captionMedium.copyWith(
                              color: CivicFixColors.secondaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceMd,
          const Divider(height: 1, color: CivicFixColors.border),
          CivicFixSpacing.vSpaceSm,

          // Edit Profile Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CivicFixColors.primary,
                side: const BorderSide(color: CivicFixColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: CivicFixRadius.buttonRadius,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
