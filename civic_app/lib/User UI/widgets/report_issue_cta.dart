import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';

/// Primary call-to-action button for reporting civic issues.
class ReportIssueCta extends StatelessWidget {
  final VoidCallback? onPressed;

  const ReportIssueCta({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Report a civic issue',
      button: true,
      child: Container(
        width: double.infinity,
        height: CivicFixSpacing.massive - 8, // 56px height for high touch prominence
        decoration: BoxDecoration(
          borderRadius: CivicFixRadius.buttonRadius,
          boxShadow: [
            BoxShadow(
              color: CivicFixColors.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed ??
              () {
                Navigator.pushNamed(context, AppRoutes.reportIssue);
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: CivicFixColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: CivicFixRadius.buttonRadius,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: CivicFixSpacing.lg,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Text(
                'Report an Issue',
                style: CivicFixTypography.button.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
