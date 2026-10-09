import 'package:flutter/material.dart';
import '../../../core/auth/auth_service_locator.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/civic_fix_button.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../models/government_session.dart';
import '../../models/govt_user_model.dart';
import '../../services/government_jurisdiction_resolver.dart';
import '../../theme/govt_theme_tokens.dart';

/// Professional Government Access Denied / Restricted Screen.
///
/// Displayed when an authenticated government officer attempts to access
/// a route outside their permitted municipal role jurisdiction.
class GovernmentAccessDeniedScreen extends StatelessWidget {
  final GovtUserModel? user;

  const GovernmentAccessDeniedScreen({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeUser = user ?? AuthServiceLocator.govtAuth.currentUser;
    final landingRoute = activeUser != null
        ? GovernmentSession.getLandingRouteForRole(activeUser.govtRole)
        : AppRoutes.govtLogin;

    final roleLabel = activeUser != null
        ? (activeUser.displayDesignation.isNotEmpty
            ? activeUser.displayDesignation
            : localizedGovernmentRole(activeUser.govtRole, context: context))
        : null;

    final jurisdictionLabel = activeUser != null
        ? GovernmentJurisdictionResolver.resolveContextSummary(activeUser)
        : null;

    return Scaffold(
      backgroundColor: GovtThemeTokens.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 540,
              padding: const EdgeInsets.symmetric(
                horizontal: CivicFixSpacing.xl,
                vertical: CivicFixSpacing.xxl,
              ),
              child: Container(
                padding: const EdgeInsets.all(CivicFixSpacing.xxl),
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.border),
                  boxShadow: GovtThemeTokens.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning / Shield Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: GovtThemeTokens.errorLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: GovtThemeTokens.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.gpp_bad_rounded,
                          size: 36,
                          color: GovtThemeTokens.error,
                        ),
                      ),
                    ),
                    CivicFixSpacing.vSpaceLg,

                    // Headline
                    Text(
                      l10n?.govAccessDenied ?? 'Access Restricted',
                      style: CivicFixTypography.h2.copyWith(
                        color: GovtThemeTokens.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    CivicFixSpacing.vSpaceSm,

                    // Body
                    Text(
                      l10n?.govAccessDeniedDesc ??
                          'You do not have permission to access this government portal section.',
                      style: CivicFixTypography.bodySmall.copyWith(
                        color: GovtThemeTokens.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    CivicFixSpacing.vSpaceXl,

                    // Officer Context (Role & Jurisdiction)
                    if (activeUser != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(CivicFixSpacing.md),
                        decoration: BoxDecoration(
                          color: GovtThemeTokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GovtThemeTokens.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (roleLabel != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n?.govDesignation ?? "Active Role"}: ',
                                    style: CivicFixTypography.captionMedium.copyWith(
                                      color: GovtThemeTokens.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      roleLabel,
                                      style: CivicFixTypography.captionMedium.copyWith(
                                        color: GovtThemeTokens.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              CivicFixSpacing.vSpaceXs,
                            ],
                            if (jurisdictionLabel != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n?.govJurisdiction ?? "Jurisdiction"}: ',
                                    style: CivicFixTypography.captionMedium.copyWith(
                                      color: GovtThemeTokens.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      jurisdictionLabel,
                                      style: CivicFixTypography.captionMedium.copyWith(
                                        color: GovtThemeTokens.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      CivicFixSpacing.vSpaceXl,
                    ],

                    // Action Button: Return to Dashboard
                    SizedBox(
                      width: double.infinity,
                      child: CivicFixButton(
                        text: l10n?.govReturnToDashboard ?? 'Return to Dashboard',
                        icon: Icons.dashboard_rounded,
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, landingRoute);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
