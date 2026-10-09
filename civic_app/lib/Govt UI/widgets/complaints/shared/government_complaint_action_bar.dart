import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../services/government_complaint_visibility_service.dart';
import '../../../theme/govt_theme_tokens.dart';

/// Reusable, Role-Aware Action Bar for the Shared Complaint Detail Screen.
class GovernmentComplaintActionBar extends StatelessWidget {
  final Set<GovernmentComplaintAction> permittedActions;
  final VoidCallback? onVerify;
  final VoidCallback? onFlag;
  final VoidCallback? onAssignCrew;
  final VoidCallback? onReassignCrew;
  final VoidCallback? onAssignFieldOfficer;
  final VoidCallback? onRaiseWrongDepartment;
  final VoidCallback? onApproveRouting;
  final VoidCallback? onRejectRouting;
  final VoidCallback? onStartWork;
  final VoidCallback? onSubmitCompletion;
  final VoidCallback? onVerifyCompletion;
  final VoidCallback? onReturnForRework;
  final VoidCallback? onEscalate;
  final VoidCallback? onUpdateStatus;
  final bool isReopen;

  const GovernmentComplaintActionBar({
    super.key,
    required this.permittedActions,
    this.onVerify,
    this.onFlag,
    this.onAssignCrew,
    this.onReassignCrew,
    this.onAssignFieldOfficer,
    this.onRaiseWrongDepartment,
    this.onApproveRouting,
    this.onRejectRouting,
    this.onStartWork,
    this.onSubmitCompletion,
    this.onVerifyCompletion,
    this.onReturnForRework,
    this.onEscalate,
    this.onUpdateStatus,
    this.isReopen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (permittedActions.isEmpty ||
        (permittedActions.length == 1 &&
            permittedActions.contains(GovernmentComplaintAction.viewOnly))) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicFixSpacing.md,
          vertical: CivicFixSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: GovtThemeTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GovtThemeTokens.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: GovtThemeTokens.textMuted),
            CivicFixSpacing.hSpaceSm,
            const Text(
              'Read-Only Access — No administrative actions currently required for your role/scope.',
              style: TextStyle(fontSize: 12, color: GovtThemeTokens.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(CivicFixSpacing.md),
      decoration: BoxDecoration(
        color: GovtThemeTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovtThemeTokens.border),
        boxShadow: GovtThemeTokens.cardShadow,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 0. Verify (for reported status)
          if (permittedActions.contains(GovernmentComplaintAction.verify) && onVerify != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text('Verify'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GovtThemeTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: onVerify,
            ),

          // 0b. Flag / Review (for reported status)
          if (permittedActions.contains(GovernmentComplaintAction.flag) && onFlag != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Flag / Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GovtThemeTokens.alert,
                side: const BorderSide(color: GovtThemeTokens.alert),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onFlag,
            ),
          // 1. Crew Start Work
          if (permittedActions.contains(GovernmentComplaintAction.startWork) &&
              onStartWork != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Start Work'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: onStartWork,
            ),

          // 2. Crew Submit Completion
          if (permittedActions.contains(GovernmentComplaintAction.submitCompletion) &&
              onSubmitCompletion != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Solved'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: onSubmitCompletion,
            ),

          // 3. Lead / Admin Assign Crew
          if (permittedActions.contains(GovernmentComplaintAction.assignCrew) &&
              onAssignCrew != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Assign Crew'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GovtThemeTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: onAssignCrew,
            ),

          // 4. Lead / Admin Reassign Crew
          if (permittedActions.contains(GovernmentComplaintAction.reassignCrew) &&
              onReassignCrew != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Reassign Crew'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GovtThemeTokens.primary,
                side: const BorderSide(color: GovtThemeTokens.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onReassignCrew,
            ),

          if (permittedActions.contains(GovernmentComplaintAction.assignFieldOfficer) &&
              onAssignFieldOfficer != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.engineering_outlined, size: 18),
              label: const Text('Assign Execution Officer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GovtThemeTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: onAssignFieldOfficer,
            ),

          // 5. Lead Raise Wrong Department
          if (permittedActions.contains(GovernmentComplaintAction.raiseWrongDepartment) &&
              onRaiseWrongDepartment != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.move_up_rounded, size: 18),
              label: const Text('Report Wrong Dept'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF97316),
                side: const BorderSide(color: Color(0xFFF97316)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onRaiseWrongDepartment,
            ),

          // 6. Ward Officer Approve Routing Ticket
          if (permittedActions.contains(GovernmentComplaintAction.approveRouting) &&
              onApproveRouting != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Approve Reassignment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: onApproveRouting,
            ),

          // 7. Ward Officer Reject Routing Ticket
          if (permittedActions.contains(GovernmentComplaintAction.rejectRouting) &&
              onRejectRouting != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Reject Reassignment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onRejectRouting,
            ),

          // 8. Lead / Officer Return for Rework / Reopen Complaint
          if (permittedActions.contains(GovernmentComplaintAction.returnForRework) &&
              onReturnForRework != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(isReopen ? 'Reopen Complaint' : 'Return for Rework'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onReturnForRework,
            ),

          // 9. Lead / Officer Verify & Close
          if (permittedActions.contains(GovernmentComplaintAction.verifyCompletion) &&
              onVerifyCompletion != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: const Text('Verify & Close Grievance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: onVerifyCompletion,
            ),

          // 10. Escalate SLA
          if (permittedActions.contains(GovernmentComplaintAction.escalate) &&
              onEscalate != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.priority_high_rounded, size: 18),
              label: const Text('Escalate Priority'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GovtThemeTokens.alert,
                side: const BorderSide(color: GovtThemeTokens.alert),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onEscalate,
            ),

          // 11. General Update Status
          if (onUpdateStatus != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Update Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GovtThemeTokens.primary,
                side: const BorderSide(color: GovtThemeTokens.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onUpdateStatus,
            ),
        ],
      ),
    );
  }
}
