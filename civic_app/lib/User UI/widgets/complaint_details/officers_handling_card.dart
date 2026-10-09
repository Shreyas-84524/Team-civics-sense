import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/civic_fix_card.dart';

/// Citizen-facing transparency card displaying assigned municipal personnel
/// (Supervising Junior Engineer and Field Execution Officer) with progressive lifecycle states.
class OfficersHandlingCard extends StatelessWidget {
  final ComplaintModel complaint;

  const OfficersHandlingCard({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    final jeName = complaint.assignedJuniorEngineerName;
    final jeDesignation = complaint.assignedJuniorEngineerDesignation;
    final isJeAssigned = complaint.isJuniorEngineerAssigned || (jeName != null && jeName.isNotEmpty);

    final foName = complaint.assignedFieldOfficerName;
    final foDesignation = complaint.assignedFieldOfficerDesignation;
    final isFoAssigned = complaint.isFieldOfficerAssigned;

    return CivicFixCard(
      padding: const EdgeInsets.all(CivicFixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CivicFixColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: CivicFixColors.primary,
                ),
              ),
              CivicFixSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10nOrNull?.assignedMunicipalTeam ??
                          'Assigned Municipal Team',
                      style: CivicFixTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CivicFixColors.primaryText,
                      ),
                    ),
                    Text(
                      context.l10nOrNull?.responsibleOfficersSubtitle ??
                          'Responsible officers managing and executing your grievance',
                      style: CivicFixTypography.caption.copyWith(
                        color: CivicFixColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceLg,

          // 1. Supervising Junior Engineer Card
          _buildJuniorEngineerSection(
            context,
            isAssigned: isJeAssigned,
            name: jeName,
            designation: jeDesignation,
          ),
          CivicFixSpacing.vSpaceMd,

          // 2. Field Execution Officer Card (Progressive States)
          _buildFieldOfficerSection(
            context,
            isAssigned: isFoAssigned,
            name: foName,
            designation: foDesignation,
          ),
        ],
      ),
    );
  }

  Widget _buildJuniorEngineerSection(
    BuildContext context, {
    required bool isAssigned,
    String? name,
    String? designation,
  }) {
    final displayName = isAssigned && name != null && name.isNotEmpty
        ? name
        : (context.l10nOrNull?.autoRoutingToWard ??
            'Auto-Routing to Ward Engineer...');
    final displayDesignation = isAssigned && designation != null && designation.isNotEmpty
        ? designation
        : '${context.l10nOrNull?.juniorEngineer ?? "Junior Engineer"} — ${complaint.effectiveDepartment}';
    final wardPrefix = context.l10nOrNull?.ward ?? 'Ward';
    final wardText =
        '$wardPrefix ${complaint.wardId ?? complaint.location.ward ?? "Central"} • ${complaint.effectiveDepartment}';

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: CivicFixRadius.cardRadius,
        border: Border.all(
          color: CivicFixColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Role Tag + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 16,
                      color: CivicFixColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.l10nOrNull?.supervisingJuniorEngineer ??
                            'Supervising Junior Engineer',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAssigned
                      ? CivicFixColors.info.withValues(alpha: 0.12)
                      : CivicFixColors.alertDark.withValues(alpha: 0.12),
                  borderRadius: CivicFixRadius.chipRadius,
                ),
                child: Text(
                  isAssigned
                      ? (context.l10nOrNull?.supervising ?? 'Supervising')
                      : (context.l10nOrNull?.routingStatus ?? 'Routing...'),
                  style: CivicFixTypography.captionMedium.copyWith(
                    color: isAssigned ? CivicFixColors.info : CivicFixColors.alertDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          // Name & Designation
          Text(
            displayName,
            style: CivicFixTypography.bodySmallMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: CivicFixColors.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayDesignation,
            style: CivicFixTypography.caption.copyWith(
              color: CivicFixColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          CivicFixSpacing.vSpaceXs,

          // Ward & Department Metadata
          Row(
            children: [
              const Icon(
                Icons.location_city_rounded,
                size: 12,
                color: CivicFixColors.disabledText,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  wardText,
                  style: CivicFixTypography.caption.copyWith(
                    color: CivicFixColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldOfficerSection(
    BuildContext context, {
    required bool isAssigned,
    String? name,
    String? designation,
  }) {
    final status = complaint.status;
    final isBlocked = complaint.isBlocked;
    final isResolved = status == ComplaintStatus.resolved;
    final isInProgress = status == ComplaintStatus.inProgress && !isBlocked;

    // Progressive State Determination
    String badgeLabel;
    Color badgeColor;
    IconData badgeIcon;
    String statusNote;

    final l10n = context.l10nOrNull;

    if (!isAssigned) {
      badgeLabel = l10n?.pendingFieldAllocation ?? 'Pending Field Allocation';
      badgeColor = CivicFixColors.alertDark;
      badgeIcon = Icons.hourglass_top_rounded;
      statusNote = l10n?.awaitingFieldOfficerAssignment ??
          'Awaiting field officer assignment by the Supervising Junior Engineer.';
    } else if (isBlocked) {
      badgeLabel = l10n?.temporarilyOnHold ?? 'Temporarily On Hold';
      badgeColor = CivicFixColors.error;
      badgeIcon = Icons.pause_circle_outline_rounded;
      statusNote = complaint.blockedReason != null && complaint.blockedReason!.isNotEmpty
          ? (l10n != null
              ? l10n.groundObstacle(complaint.blockedReason!)
              : 'Ground obstacle: ${complaint.blockedReason}')
          : (l10n?.groundWorkPaused ??
              'Ground work is temporarily paused due to site constraints.');
    } else if (isResolved) {
      badgeLabel = l10n?.workCompleted ?? 'Work Completed';
      badgeColor = CivicFixColors.secondary;
      badgeIcon = Icons.check_circle_rounded;
      statusNote = l10n?.groundRepairExecuted ??
          'Ground repair executed and verified successfully.';
    } else if (isInProgress) {
      badgeLabel = l10n?.workInProgress ?? 'Work In Progress';
      badgeColor = CivicFixColors.alertDark;
      badgeIcon = Icons.engineering_rounded;
      final startedTime = complaint.workStartedAt != null
          ? (l10n != null
              ? l10n.commencedTime(DateFormatter.formatRelativeTime(complaint.workStartedAt!))
              : 'Commenced ${DateFormatter.formatRelativeTime(complaint.workStartedAt!)}.')
          : (l10n?.executionUnderway ?? 'Execution currently underway on site.');
      statusNote = startedTime;
    } else {
      badgeLabel = l10n?.assignedForFieldWork ?? 'Assigned for Field Work';
      badgeColor = CivicFixColors.info;
      badgeIcon = Icons.person_pin_circle_rounded;
      statusNote = l10n?.fieldOfficerAllocatedNote ??
          'Field officer allocated. Ground operations scheduled.';
    }

    final displayName = isAssigned && name != null && name.isNotEmpty
        ? name
        : (l10n?.pendingAllocation ?? 'Pending Allocation');
    final displayDesignation = isAssigned && designation != null && designation.isNotEmpty
        ? designation
        : '${l10n?.fieldOfficer ?? "Field Officer"} — ${complaint.effectiveDepartment}';

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: CivicFixRadius.cardRadius,
        border: Border.all(
          color: CivicFixColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Role Tag + Live State Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.build_circle_outlined,
                      size: 16,
                      color: CivicFixColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.l10nOrNull?.fieldExecutionOfficer ??
                            'Field Execution Officer',
                        style: CivicFixTypography.captionMedium.copyWith(
                          color: CivicFixColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: CivicFixRadius.chipRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 11, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: CivicFixTypography.captionMedium.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CivicFixSpacing.vSpaceSm,

          if (isAssigned) ...[
            // Assigned Field Officer Name & Designation
            Text(
              displayName,
              style: CivicFixTypography.bodySmallMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: CivicFixColors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayDesignation,
              style: CivicFixTypography.caption.copyWith(
                color: CivicFixColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            CivicFixSpacing.vSpaceXs,
          ],

          // Contextual State Description / Notes
          Text(
            statusNote,
            style: CivicFixTypography.caption.copyWith(
              color: CivicFixColors.secondaryText,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
