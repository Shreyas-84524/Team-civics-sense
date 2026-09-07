import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Standard header with brand mark, page heading, and supporting message for Auth screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBrandMark;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBrandMark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBrandMark) ...[
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CivicFixColors.primary,
                  borderRadius: CivicFixRadius.largeContainerRadius,
                  boxShadow: [
                    BoxShadow(
                      color: CivicFixColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_city_rounded,
                    color: CivicFixColors.accent,
                    size: 26,
                  ),
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Text(
                'CivicFix',
                style: CivicFixTypography.h2.copyWith(
                  color: CivicFixColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceXl,
        ],
        Text(
          title,
          style: CivicFixTypography.h1,
        ),
        CivicFixSpacing.vSpaceSm,
        Text(
          subtitle,
          style: CivicFixTypography.bodySmall,
        ),
      ],
    );
  }
}
