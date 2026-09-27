import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../theme/govt_theme_tokens.dart';

/// Clean, restrained Government Portal authentication & session resolution screen.
///
/// Displayed while verifying officer credentials, fetching backend profiles,
/// or resolving jurisdiction without leaking citizen UI.
class GovernmentAuthLoadingScreen extends StatelessWidget {
  final String message;

  const GovernmentAuthLoadingScreen({
    super.key,
    this.message = 'Verifying government credentials...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GovtThemeTokens.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(CivicFixSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Municipal seal container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: GovtThemeTokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GovtThemeTokens.border),
                  boxShadow: GovtThemeTokens.cardShadow,
                ),
                child: const Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 32,
                    color: GovtThemeTokens.primary,
                  ),
                ),
              ),
              CivicFixSpacing.vSpaceXl,

              // Portal title
              Text(
                'CivicFix Government Portal',
                style: CivicFixTypography.h3.copyWith(
                  color: GovtThemeTokens.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              CivicFixSpacing.vSpaceSm,

              // Subtitle status message
              Text(
                message,
                style: CivicFixTypography.bodySmallMedium.copyWith(
                  color: GovtThemeTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              CivicFixSpacing.vSpaceXl,

              // Restrained circular progress indicator
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(GovtThemeTokens.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
