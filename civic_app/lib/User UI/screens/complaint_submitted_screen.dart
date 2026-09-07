import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/complaint_model.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/civic_fix_button.dart';
import '../../core/widgets/civic_fix_card.dart';
import '../../core/widgets/civic_fix_outlined_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/status_badge.dart';

/// Screen displayed immediately upon successful civic issue submission.
class ComplaintSubmittedScreen extends StatelessWidget {
  final ComplaintModel? complaint;

  const ComplaintSubmittedScreen({super.key, this.complaint});

  @override
  Widget build(BuildContext context) {
    final ticketNumber = complaint?.ticketNumber ?? 'CF-2026-000024';

    return Scaffold(
      backgroundColor: CivicFixColors.background,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 500,
          padding: CivicFixSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Icon Circle
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: CivicFixColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: CivicFixColors.secondary,
                  size: 56,
                ),
              ),
              CivicFixSpacing.vSpaceXl,

              Text(
                'Issue Reported',
                textAlign: TextAlign.center,
                style: CivicFixTypography.h1,
              ),
              CivicFixSpacing.vSpaceSm,
              Text(
                'Your issue has been submitted successfully.',
                textAlign: TextAlign.center,
                style: CivicFixTypography.body.copyWith(
                  color: CivicFixColors.secondaryText,
                ),
              ),
              CivicFixSpacing.vSpaceXl,

              // Ticket Details Card
              CivicFixCard(
                padding: const EdgeInsets.all(CivicFixSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Complaint ID',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.secondaryText,
                          ),
                        ),
                        Text(
                          ticketNumber,
                          style: CivicFixTypography.bodySmallMedium.copyWith(
                            color: CivicFixColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    CivicFixSpacing.vSpaceSm,
                    const Divider(height: 1),
                    CivicFixSpacing.vSpaceSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.secondaryText,
                          ),
                        ),
                        const StatusBadge(status: ComplaintStatus.submitted),
                      ],
                    ),
                    CivicFixSpacing.vSpaceSm,
                    const Divider(height: 1),
                    CivicFixSpacing.vSpaceSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Civic Reward',
                          style: CivicFixTypography.caption.copyWith(
                            color: CivicFixColors.secondaryText,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: CivicFixColors.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+20 Points',
                              style: CivicFixTypography.captionMedium.copyWith(
                                color: CivicFixColors.secondaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CivicFixSpacing.vSpaceLg,

              Text(
                'You can track the progress of this issue from My Complaints.',
                textAlign: TextAlign.center,
                style: CivicFixTypography.caption.copyWith(
                  color: CivicFixColors.secondaryText,
                ),
              ),
              const Spacer(),

              // Primary Actions
              CivicFixButton(
                text: 'View Complaint',
                icon: Icons.description_outlined,
                onPressed: () {
                  if (complaint != null) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.complaintDetails,
                      arguments: complaint,
                    );
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  }
                },
              ),
              CivicFixSpacing.vSpaceMd,
              CivicFixOutlinedButton(
                text: 'Back to Home',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
                },
              ),
              CivicFixSpacing.vSpaceLg,
            ],
          ),
        ),
      ),
    );
  }
}
