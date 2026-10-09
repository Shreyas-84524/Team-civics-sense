import 'package:flutter/material.dart';
import '../theme/civicfix_design_tokens.dart';

/// Standardized CivicFix loading state indicator.
///
/// Follows Design.md:
/// - 2.5px circular progress indicator in institutional gold or slate
/// - Inter typography for the status message
class LoadingState extends StatelessWidget {
  final String? message;
  final Color? color;
  final double strokeWidth;

  const LoadingState({
    super.key,
    this.message,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? CivicFixColors.primaryAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CivicFixSpacing.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                strokeWidth: strokeWidth,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: CivicFixSpacing.spaceMd),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: CivicFixTypographyTokens.bodySm.copyWith(
                  color: CivicFixColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard alias conforming to the CivicFix naming convention.
typedef CivicFixLoadingState = LoadingState;
