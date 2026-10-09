import '../models/complaint_model.dart';


/// Helper for mapping statuses and presentation helpers.
class StatusHelper {
  StatusHelper._();

  static List<ComplaintStatus> get activeStatuses => [
        ComplaintStatus.underVerification,
        ComplaintStatus.reported,
        ComplaintStatus.verified,
        ComplaintStatus.assigned,
        ComplaintStatus.inProgress,
      ];

  static List<ComplaintStatus> get resolvedStatuses => [
        ComplaintStatus.resolved,
        ComplaintStatus.closed,
        ComplaintStatus.rejected,
      ];

  static int getStepIndex(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.underVerification:
        return 0;
      case ComplaintStatus.reported:
      case ComplaintStatus.verified:
        return 1;
      case ComplaintStatus.assigned:
        return 2;
      case ComplaintStatus.inProgress:
        return 3;
      case ComplaintStatus.resolved:
        return 4;
      case ComplaintStatus.closed:
        return 5;
      case ComplaintStatus.rejected:
        return 4;
    }
  }
}
