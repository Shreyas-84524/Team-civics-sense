import '../models/govt_user_model.dart';
import '../../core/models/government_role.dart';

/// Validation error categories for government accounts.
enum GovernmentValidationError {
  none,
  userNotFound,
  accountInactive,
  invalidRole,
  missingZone,
  missingWard,
  missingDepartment,
  missingSupervisor,
  incompleteJurisdiction,
}

/// The result of validating a government user profile.
class GovernmentValidationResult {
  final bool isValid;
  final GovernmentValidationError error;
  final String? message;

  const GovernmentValidationResult({
    required this.isValid,
    this.error = GovernmentValidationError.none,
    this.message,
  });

  const GovernmentValidationResult.valid()
      : isValid = true,
        error = GovernmentValidationError.none,
        message = null;

  const GovernmentValidationResult.invalid({
    required this.error,
    required this.message,
  }) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid ($error: $message)';
}

/// Validates government user accounts against canonical BMC governance requirements
/// before granting access or establishing an active government session.
class GovernmentAccountValidator {
  const GovernmentAccountValidator._();

  /// Validates a [GovtUserModel] against BMC government account integrity rules.
  static GovernmentValidationResult validate(GovtUserModel? user) {
    if (user == null) {
      return const GovernmentValidationResult.invalid(
        error: GovernmentValidationError.userNotFound,
        message: 'Government profile could not be found.',
      );
    }

    if (!user.active) {
      return const GovernmentValidationResult.invalid(
        error: GovernmentValidationError.accountInactive,
        message: 'Your government account is currently inactive.',
      );
    }

    switch (user.govtRole) {
      case GovernmentRole.governmentSuperAdmin:
        // Super Admin has citywide access; no specific ward or department required.
        return const GovernmentValidationResult.valid();

      case GovernmentRole.zonalDmc:
        if (user.zoneId == null || user.zoneId!.trim().isEmpty) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingZone,
            message:
                'Your account configuration is incomplete: Missing assigned Zone. Contact the system administrator.',
          );
        }
        return const GovernmentValidationResult.valid();

      case GovernmentRole.centralDepartmentHod:
        if (user.departmentId == null || user.departmentId!.trim().isEmpty) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingDepartment,
            message:
                'Your account configuration is incomplete: Missing assigned Department. Contact the system administrator.',
          );
        }
        return const GovernmentValidationResult.valid();

      case GovernmentRole.wardOfficer:
        if (user.wardId == null || user.wardId!.trim().isEmpty) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingWard,
            message:
                'Your account configuration is incomplete: Missing assigned Ward. Contact the system administrator.',
          );
        }
        return const GovernmentValidationResult.valid();

      case GovernmentRole.wardDepartmentLead:
        if (user.wardId == null || user.wardId!.trim().isEmpty) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingWard,
            message:
                'Your account configuration is incomplete: Missing assigned Ward. Contact the system administrator.',
          );
        }
        if (user.departmentId == null || user.departmentId!.trim().isEmpty) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingDepartment,
            message:
                'Your account configuration is incomplete: Missing assigned Department. Contact the system administrator.',
          );
        }
        return const GovernmentValidationResult.valid();

      case GovernmentRole.departmentCrew:
        if (user.wardId == null || user.wardId!.trim().isEmpty) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingWard,
            message:
                'Your account configuration is incomplete: Missing assigned Ward. Contact the system administrator.',
          );
        }
        if (user.departmentId == null || user.departmentId!.trim().isEmpty) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingDepartment,
            message:
                'Your account configuration is incomplete: Missing assigned Department. Contact the system administrator.',
          );
        }
        final hasSupervisor = (user.administrativeSupervisorId != null &&
                user.administrativeSupervisorId!.trim().isNotEmpty) ||
            (user.technicalSupervisorId != null &&
                user.technicalSupervisorId!.trim().isNotEmpty);
        if (!hasSupervisor) {
          return const GovernmentValidationResult.invalid(
            error: GovernmentValidationError.missingSupervisor,
            message:
                'Your account configuration is incomplete: Missing supervisor assignment. Contact the system administrator.',
          );
        }
        return const GovernmentValidationResult.valid();
    }
  }
}
