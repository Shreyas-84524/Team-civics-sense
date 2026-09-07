import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Step definition for Report Issue progress tracking.
class ReportStep {
  final int stepNumber;
  final String label;
  final IconData icon;

  const ReportStep({
    required this.stepNumber,
    required this.label,
    required this.icon,
  });
}

/// Accessible 4-step progress indicator for the Report Issue flow.
class ReportProgressIndicator extends StatelessWidget {
  final int currentStep; // 1-indexed (1 to 4)
  final Function(int)? onStepTap;

  static const List<ReportStep> steps = [
    ReportStep(stepNumber: 1, label: 'Information', icon: Icons.edit_note_rounded),
    ReportStep(stepNumber: 2, label: 'Evidence', icon: Icons.add_photo_alternate_outlined),
    ReportStep(stepNumber: 3, label: 'Location', icon: Icons.pin_drop_outlined),
    ReportStep(stepNumber: 4, label: 'Review', icon: Icons.fact_check_outlined),
  ];

  const ReportProgressIndicator({
    super.key,
    required this.currentStep,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $currentStep of 4: ${steps[currentStep - 1].label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md,
          vertical: CivicFixSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: CivicFixColors.surface,
          borderRadius: CivicFixRadius.cardRadius,
          border: Border.all(color: CivicFixColors.border),
        ),
        child: Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Expanded(
                child: _buildStepItem(context, steps[i]),
              ),
              if (i < steps.length - 1)
                Container(
                  width: 16,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: (i + 1) < currentStep
                      ? CivicFixColors.secondary
                      : CivicFixColors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, ReportStep step) {
    final isCompleted = step.stepNumber < currentStep;
    final isCurrent = step.stepNumber == currentStep;

    Color circleBg;
    Color iconOrTextColor;
    Border? border;

    if (isCompleted) {
      circleBg = CivicFixColors.secondary;
      iconOrTextColor = Colors.white;
      border = null;
    } else if (isCurrent) {
      circleBg = CivicFixColors.primary;
      iconOrTextColor = Colors.white;
      border = null;
    } else {
      circleBg = CivicFixColors.surfaceMuted;
      iconOrTextColor = CivicFixColors.disabledText;
      border = Border.all(color: CivicFixColors.border);
    }

    return InkWell(
      onTap: isCompleted && onStepTap != null ? () => onStepTap!(step.stepNumber) : null,
      borderRadius: CivicFixRadius.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CivicFixSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
                border: border,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '${step.stepNumber}',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: iconOrTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            CivicFixSpacing.vSpaceXs,
            Text(
              step.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CivicFixTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? CivicFixColors.primaryText
                    : isCompleted
                        ? CivicFixColors.secondaryDark
                        : CivicFixColors.disabledText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
