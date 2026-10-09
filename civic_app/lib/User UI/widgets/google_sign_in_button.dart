import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

import '../../core/localization/app_localizations.dart';

/// Reusable "Continue with Google" action button with the official 4-color Google logo.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = text ?? context.l10nOrNull?.continueWithGoogle ?? 'Continue with Google';

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: CivicFixColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CivicFixRadius.buttonRadius.topLeft.x),
          ),
          padding: const EdgeInsets.symmetric(horizontal: CivicFixSpacing.lg),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(CivicFixColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogoIcon(),
                  const SizedBox(width: CivicFixSpacing.md),
                  Flexible(
                    child: Text(
                      displayText,
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CivicFixColors.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Official 4-color Google logo icon widget rendered with vector precision.
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // 1. Blue: Right bar & cross section
    final bluePath = Path()
      ..moveTo(23.745, 12.27)
      ..cubicTo(23.745, 11.48, 23.675, 10.73, 23.555, 10.01)
      ..lineTo(12.0, 10.01)
      ..lineTo(12.0, 14.73)
      ..lineTo(18.59, 14.73)
      ..cubicTo(18.3, 16.27, 17.43, 17.57, 16.12, 18.45)
      ..lineTo(16.12, 21.56)
      ..lineTo(20.08, 21.56)
      ..cubicTo(22.4, 19.42, 23.745, 16.14, 23.745, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green: Bottom curve
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 19.96, 21.08)
      ..lineTo(16.0, 18.01)
      ..cubicTo(14.9, 18.75, 13.51, 19.23, 12.0, 19.23)
      ..cubicTo(8.87, 19.23, 6.22, 17.12, 5.27, 14.28)
      ..lineTo(1.18, 14.28)
      ..lineTo(1.18, 17.45)
      ..cubicTo(3.2, 21.46, 7.28, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow: Left curve
    final yellowPath = Path()
      ..moveTo(5.27, 14.28)
      ..cubicTo(5.02, 13.54, 4.88, 12.75, 4.88, 11.93)
      ..cubicTo(4.88, 11.11, 5.02, 10.32, 5.26, 9.58)
      ..lineTo(5.26, 6.41)
      ..lineTo(1.18, 6.41)
      ..cubicTo(0.43, 7.91, 0.0, 9.87, 0.0, 11.93)
      ..cubicTo(0.0, 13.99, 0.43, 15.95, 1.18, 17.45)
      ..lineTo(5.27, 14.28)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red: Top curve
    final redPath = Path()
      ..moveTo(12.0, 4.63)
      ..cubicTo(13.76, 4.63, 15.34, 5.24, 16.59, 6.43)
      ..lineTo(20.05, 2.97)
      ..cubicTo(17.95, 1.01, 15.23, 0.0, 12.0, 0.0)
      ..cubicTo(7.28, 0.0, 3.2, 2.54, 1.18, 6.41)
      ..lineTo(5.26, 9.58)
      ..cubicTo(6.22, 6.74, 8.87, 4.63, 12.0, 4.63)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
