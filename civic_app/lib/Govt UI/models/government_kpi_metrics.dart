import '../../../core/models/complaint_model.dart';

/// Standardized canonical municipal KPI calculation and metrics representation across all roles.
class GovernmentKpiMetrics {
  final int totalComplaints;
  final int openComplaints;
  final int resolvedComplaints;
  final int resolvedToday;
  final int inProgressComplaints;
  final int criticalComplaints;
  final int slaBreachedCount;
  final int slaWarningCount;
  final int routingPendingCount;
  final double slaComplianceRate; // 0.0 to 1.0 (e.g. 0.94 -> 94%)
  final double avgResolutionHours;

  const GovernmentKpiMetrics({
    required this.totalComplaints,
    required this.openComplaints,
    required this.resolvedComplaints,
    required this.resolvedToday,
    required this.inProgressComplaints,
    required this.criticalComplaints,
    required this.slaBreachedCount,
    required this.slaWarningCount,
    required this.routingPendingCount,
    required this.slaComplianceRate,
    required this.avgResolutionHours,
  });

  /// Factory constructor to compute standardized KPIs from a list of complaints.
  factory GovernmentKpiMetrics.fromComplaints(
    List<ComplaintModel> complaints, {
    Duration targetSla = const Duration(hours: 48),
    Duration warningThreshold = const Duration(hours: 36),
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    int total = complaints.length;
    int open = 0;
    int resolved = 0;
    int resolvedTodayCount = 0;
    int inProgress = 0;
    int critical = 0;
    int breached = 0;
    int warning = 0;
    int routingPending = 0;

    double totalResolutionHours = 0;
    int compliantResolutions = 0;

    for (final c in complaints) {
      final isResolved = c.status == ComplaintStatus.resolved;
      final isRejected = c.status == ComplaintStatus.rejected;
      final slaDeadline = c.createdAt.add(targetSla);
      final warningDeadline = c.createdAt.add(warningThreshold);

      // Open Complaints definition: Not resolved and not rejected
      if (!isResolved && !isRejected) {
        open++;
      }

      // In Progress definition
      if (c.status == ComplaintStatus.inProgress ||
          c.status.label.toLowerCase().contains('progress')) {
        inProgress++;
      }

      // Critical Complaints definition: High or Emergency priority
      if (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) {
        critical++;
      }

      // Routing Pending status
      if (c.routingStatus == ComplaintRoutingStatus.reassignmentRequested) {
        routingPending++;
      }

      // SLA Evaluation
      if (isResolved) {
        resolved++;
        // Check if resolved today
        final resDate = c.updatedAt;
        if (resDate.year == now.year && resDate.month == now.month && resDate.day == now.day) {
          resolvedTodayCount++;
        }

        // Resolution Time
        final resDuration = resDate.difference(c.createdAt).inMinutes / 60.0;
        totalResolutionHours += resDuration > 0 ? resDuration : 0;

        if (resDate.isBefore(slaDeadline) || resDate.isAtSameMomentAs(slaDeadline)) {
          compliantResolutions++;
        } else {
          breached++;
        }
      } else if (!isRejected) {
        // Active complaint SLA check against now
        if (now.isAfter(slaDeadline)) {
          breached++;
        } else if (now.isAfter(warningDeadline)) {
          warning++;
        }
      }
    }

    final double avgHours = resolved > 0 ? (totalResolutionHours / resolved) : 0.0;
    final double compliance = resolved > 0
        ? (compliantResolutions / resolved)
        : (total > 0 && breached == 0 ? 1.0 : 0.0);

    return GovernmentKpiMetrics(
      totalComplaints: total,
      openComplaints: open,
      resolvedComplaints: resolved,
      resolvedToday: resolvedTodayCount,
      inProgressComplaints: inProgress,
      criticalComplaints: critical,
      slaBreachedCount: breached,
      slaWarningCount: warning,
      routingPendingCount: routingPending,
      slaComplianceRate: compliance,
      avgResolutionHours: avgHours,
    );
  }

  /// Formatted SLA compliance percentage string (e.g. '94.2%').
  String get formattedSlaCompliance => '${(slaComplianceRate * 100).toStringAsFixed(1)}%';

  /// Formatted average resolution time (e.g. '4.5 hrs' or '2.1 days').
  String get formattedAvgResolutionTime {
    if (avgResolutionHours <= 0) return '0 hrs';
    if (avgResolutionHours >= 24) {
      final days = (avgResolutionHours / 24).toStringAsFixed(1);
      return '$days days';
    }
    return '${avgResolutionHours.toStringAsFixed(1)} hrs';
  }
}
