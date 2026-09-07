import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/widgets/civic_fix_card.dart';

enum TrackerStageState {
  completed,
  current,
  pending,
}

class TrackerStageInfo {
  final ComplaintStatus status;
  final String title;
  final String description;
  final String explanation;
  final IconData icon;

  const TrackerStageInfo({
    required this.status,
    required this.title,
    required this.description,
    required this.explanation,
    required this.icon,
  });
}

/// Reusable 5-stage progress tracker for CivicFix complaints.
class ComplaintTracker extends StatefulWidget {
  final ComplaintStatus currentStatus;
  final String? customStatusMessage;

  const ComplaintTracker({
    super.key,
    required this.currentStatus,
    this.customStatusMessage,
  });

  static const List<TrackerStageInfo> canonicalStages = [
    TrackerStageInfo(
      status: ComplaintStatus.reported,
      title: 'Reported',
      description: 'Submitted & queued for review',
      explanation: 'Your issue has been submitted and is awaiting review.',
      icon: Icons.assignment_outlined,
    ),
    TrackerStageInfo(
      status: ComplaintStatus.verified,
      title: 'Verified',
      description: 'Reviewed and confirmed by authority',
      explanation: 'The issue has been reviewed and verified.',
      icon: Icons.verified_outlined,
    ),
    TrackerStageInfo(
      status: ComplaintStatus.assigned,
      title: 'Assigned',
      description: 'Allocated to maintenance squad',
      explanation: 'The issue has been assigned to the responsible team.',
      icon: Icons.person_pin_circle_outlined,
    ),
    TrackerStageInfo(
      status: ComplaintStatus.inProgress,
      title: 'In Progress',
      description: 'Work is currently underway',
      explanation: 'The responsible team is currently working on the issue.',
      icon: Icons.engineering_rounded,
    ),
    TrackerStageInfo(
      status: ComplaintStatus.resolved,
      title: 'Resolved',
      description: 'Issue successfully fixed',
      explanation: 'The reported issue has been marked as resolved.',
      icon: Icons.check_circle_rounded,
    ),
  ];

  @override
  State<ComplaintTracker> createState() => _ComplaintTrackerState();
}

class _ComplaintTrackerState extends State<ComplaintTracker> {
  int? _expandedStageIndex;

  int _getStageIndex(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.reported:
        return 0;
      case ComplaintStatus.verified:
        return 1;
      case ComplaintStatus.assigned:
        return 2;
      case ComplaintStatus.inProgress:
        return 3;
      case ComplaintStatus.resolved:
      case ComplaintStatus.rejected:
        return 4;
    }
  }

  TrackerStageState _getStageState(int stageIndex, int currentStageIndex) {
    if (widget.currentStatus == ComplaintStatus.resolved) {
      return TrackerStageState.completed;
    }
    if (stageIndex < currentStageIndex) {
      return TrackerStageState.completed;
    } else if (stageIndex == currentStageIndex) {
      return TrackerStageState.current;
    } else {
      return TrackerStageState.pending;
    }
  }

  String _getContextualStatusMessage(int currentStageIndex) {
    if (widget.customStatusMessage != null && widget.customStatusMessage!.isNotEmpty) {
      return widget.customStatusMessage!;
    }

    switch (widget.currentStatus) {
      case ComplaintStatus.reported:
        return 'Your report has been received and is queued for verification.';
      case ComplaintStatus.verified:
        return 'Your report has been verified by the responsible authority.';
      case ComplaintStatus.assigned:
        return 'Your issue has been assigned to the appropriate department.';
      case ComplaintStatus.inProgress:
        return 'The responsible team is currently working on this issue.';
      case ComplaintStatus.resolved:
        return 'This issue has been marked as resolved.';
      case ComplaintStatus.rejected:
        return 'This complaint has been reviewed and closed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStageIndex = _getStageIndex(widget.currentStatus);
    final contextualMessage = _getContextualStatusMessage(currentStageIndex);
    final isFullyResolved = widget.currentStatus == ComplaintStatus.resolved;

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Tracker',
                style: CivicFixTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: CivicFixColors.primaryText,
                ),
              ),
              Text(
                'Stage ${currentStageIndex + 1} of 5',
                style: CivicFixTypography.captionMedium.copyWith(
                  color: CivicFixColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // 5-Stage Vertical Timeline
          Column(
            children: List.generate(ComplaintTracker.canonicalStages.length, (index) {
              final stage = ComplaintTracker.canonicalStages[index];
              final stageState = _getStageState(index, currentStageIndex);
              final isLast = index == ComplaintTracker.canonicalStages.length - 1;
              final isExpanded = _expandedStageIndex == index;

              return _buildStageItem(
                index: index,
                stage: stage,
                stageState: stageState,
                isLast: isLast,
                isExpanded: isExpanded,
              );
            }),
          ),
          CivicFixSpacing.vSpaceMd,

          // Contextual Status Message Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(CivicFixSpacing.md),
            decoration: BoxDecoration(
              color: isFullyResolved
                  ? CivicFixColors.statusResolvedBg
                  : CivicFixColors.surfaceMuted,
              borderRadius: CivicFixRadius.cardRadius,
              border: Border.all(
                color: isFullyResolved
                    ? CivicFixColors.secondary.withValues(alpha: 0.3)
                    : CivicFixColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isFullyResolved
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: isFullyResolved
                      ? CivicFixColors.secondary
                      : CivicFixColors.info,
                ),
                CivicFixSpacing.hSpaceSm,
                Expanded(
                  child: Text(
                    contextualMessage,
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: isFullyResolved
                          ? CivicFixColors.secondaryDark
                          : CivicFixColors.primaryText,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageItem({
    required int index,
    required TrackerStageInfo stage,
    required TrackerStageState stageState,
    required bool isLast,
    required bool isExpanded,
  }) {
    Color indicatorBgColor;
    Color borderColor;
    Widget indicatorContent;
    String semanticStateText;

    switch (stageState) {
      case TrackerStageState.completed:
        indicatorBgColor = CivicFixColors.secondary;
        borderColor = CivicFixColors.secondary;
        indicatorContent = const Icon(Icons.check_rounded, size: 16, color: Colors.white);
        semanticStateText = '${stage.title}, completed';
        break;
      case TrackerStageState.current:
        indicatorBgColor = CivicFixColors.alertDark;
        borderColor = CivicFixColors.alertDark;
        indicatorContent = Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        );
        semanticStateText = '${stage.title}, current stage';
        break;
      case TrackerStageState.pending:
        indicatorBgColor = CivicFixColors.surface;
        borderColor = CivicFixColors.border;
        indicatorContent = Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: CivicFixColors.border,
            shape: BoxShape.circle,
          ),
        );
        semanticStateText = '${stage.title}, pending';
        break;
    }

    return Semantics(
      label: semanticStateText,
      button: true,
      hint: 'Tap to view stage explanation',
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedStageIndex = isExpanded ? null : index;
          });
        },
        borderRadius: CivicFixRadius.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicator Node & Connecting Line
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: indicatorBgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: stageState == TrackerStageState.current
                            ? [
                                BoxShadow(
                                  color: CivicFixColors.alertDark.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(child: indicatorContent),
                    ),
                    if (!isLast)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 2.5,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: stageState == TrackerStageState.completed
                              ? CivicFixColors.secondary
                              : CivicFixColors.border,
                        ),
                      ),
                  ],
                ),
                CivicFixSpacing.hSpaceMd,

                // Stage Info & Expandable Details
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? CivicFixSpacing.sm : CivicFixSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              stage.title,
                              style: CivicFixTypography.bodySmallMedium.copyWith(
                                fontWeight: stageState == TrackerStageState.current
                                    ? FontWeight.w800
                                    : (stageState == TrackerStageState.completed
                                        ? FontWeight.w700
                                        : FontWeight.w500),
                                color: stageState == TrackerStageState.pending
                                    ? CivicFixColors.disabledText
                                    : CivicFixColors.primaryText,
                              ),
                            ),
                            if (stageState == TrackerStageState.current) ...[
                              CivicFixSpacing.hSpaceSm,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CivicFixColors.statusInProgressBg,
                                  borderRadius: CivicFixRadius.chipRadius,
                                  border: Border.all(
                                    color: CivicFixColors.alertDark.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  'CURRENT',
                                  style: CivicFixTypography.captionMedium.copyWith(
                                    color: CivicFixColors.alertDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        CivicFixSpacing.vSpaceXs,
                        Text(
                          stage.description,
                          style: CivicFixTypography.caption.copyWith(
                            color: stageState == TrackerStageState.pending
                                ? CivicFixColors.disabledText
                                : CivicFixColors.secondaryText,
                          ),
                        ),

                        // Expandable Explanation Card on Tap
                        if (isExpanded) ...[
                          CivicFixSpacing.vSpaceSm,
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(CivicFixSpacing.sm + 2),
                            decoration: BoxDecoration(
                              color: CivicFixColors.surfaceMuted,
                              borderRadius: CivicFixRadius.chipRadius,
                              border: Border.all(color: CivicFixColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 14,
                                  color: CivicFixColors.primary,
                                ),
                                CivicFixSpacing.hSpaceSm,
                                Expanded(
                                  child: Text(
                                    stage.explanation,
                                    style: CivicFixTypography.caption.copyWith(
                                      color: CivicFixColors.primaryText,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
