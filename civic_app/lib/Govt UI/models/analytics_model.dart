import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/complaint_model.dart';

/// Available time range filters for government analytics aggregation.
enum DateRangeOption {
  last7Days('Last 7 Days', 7),
  last30Days('Last 30 Days', 30),
  last90Days('Last 90 Days', 90),
  allTime('All Time', null);

  final String label;
  final int? durationDays;

  const DateRangeOption(this.label, this.durationDays);
}

/// Multi-criteria filter options for querying municipal analytics.
class AnalyticsFilter {
  final DateRangeOption dateRange;
  final String? categoryId;
  final ComplaintStatus? status;
  final String? departmentId;
  final ComplaintPriority? priority;

  const AnalyticsFilter({
    this.dateRange = DateRangeOption.last30Days,
    this.categoryId,
    this.status,
    this.departmentId,
    this.priority,
  });

  bool get isFiltered =>
      dateRange != DateRangeOption.last30Days ||
      categoryId != null ||
      status != null ||
      departmentId != null ||
      priority != null;

  AnalyticsFilter copyWith({
    DateRangeOption? dateRange,
    String? categoryId,
    bool clearCategory = false,
    ComplaintStatus? status,
    bool clearStatus = false,
    String? departmentId,
    bool clearDepartment = false,
    ComplaintPriority? priority,
    bool clearPriority = false,
  }) {
    return AnalyticsFilter(
      dateRange: dateRange ?? this.dateRange,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      status: clearStatus ? null : (status ?? this.status),
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      priority: clearPriority ? null : (priority ?? this.priority),
    );
  }
}

/// Core high-level municipal KPI metrics.
class AnalyticsSummary {
  final int totalComplaints;
  final int resolvedComplaints;
  final int pendingComplaints; // Reported + Verified
  final int inProgressComplaints;
  final int assignedComplaints;
  final int highPriorityComplaints; // High + Emergency
  final int unassignedComplaints; // Reported/Verified without assigned squad
  final double resolutionRate; // 0.0 - 1.0
  final double avgResolutionHours;
  final double slaComplianceRate; // 0.0 - 1.0

  const AnalyticsSummary({
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.pendingComplaints,
    required this.inProgressComplaints,
    required this.assignedComplaints,
    required this.highPriorityComplaints,
    required this.unassignedComplaints,
    required this.resolutionRate,
    required this.avgResolutionHours,
    this.slaComplianceRate = 0.88,
  });

  String get formattedAvgResolutionTime {
    if (avgResolutionHours <= 0) return '0 hrs';
    if (avgResolutionHours >= 24) {
      final days = (avgResolutionHours / 24).toStringAsFixed(1);
      return '$days days';
    }
    return '${avgResolutionHours.toStringAsFixed(1)} hrs';
  }

  String get formattedResolutionPercentage {
    return '${(resolutionRate * 100).toStringAsFixed(1)}%';
  }
}

/// Point in time for chronological complaint trend visualization.
class TimeTrendPoint {
  final DateTime date;
  final String label; // e.g., "Mon", "Day 1", "01 Sep"
  final int reportedCount;
  final int resolvedCount;

  const TimeTrendPoint({
    required this.date,
    required this.label,
    required this.reportedCount,
    required this.resolvedCount,
  });
}

/// Aggregated workload and performance metrics for a specific municipal department.
class DepartmentAnalytics {
  final String departmentId;
  final String departmentName;
  final int total;
  final int pending;
  final int inProgress;
  final int resolved;
  final double resolutionRate;
  final double avgResolutionHours;

  const DepartmentAnalytics({
    required this.departmentId,
    required this.departmentName,
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.resolved,
    required this.resolutionRate,
    required this.avgResolutionHours,
  });

  String get formattedResolutionPercentage {
    return '${(resolutionRate * 100).toStringAsFixed(0)}%';
  }
}

/// Aggregated metrics for a single civic category.
class CategoryAnalytics {
  final CivicCategory category;
  final int count;
  final double percentage; // 0.0 - 1.0
  final Color color;

  const CategoryAnalytics({
    required this.category,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

/// Aggregated metrics for a single canonical lifecycle status.
class StatusAnalytics {
  final ComplaintStatus status;
  final int count;
  final double percentage; // 0.0 - 1.0
  final Color color;

  const StatusAnalytics({
    required this.status,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

/// Complete aggregated analytics payload returned by the analytics repository.
class AnalyticsData {
  final AnalyticsSummary summary;
  final List<TimeTrendPoint> timeTrends;
  final List<CategoryAnalytics> categoryBreakdowns;
  final List<StatusAnalytics> statusBreakdowns;
  final List<DepartmentAnalytics> departmentBreakdowns;
  final AnalyticsFilter activeFilter;

  const AnalyticsData({
    required this.summary,
    required this.timeTrends,
    required this.categoryBreakdowns,
    required this.statusBreakdowns,
    required this.departmentBreakdowns,
    required this.activeFilter,
  });
}
