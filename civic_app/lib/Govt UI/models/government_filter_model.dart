import 'package:flutter/material.dart';
import '../../../core/models/complaint_model.dart';
import '../widgets/common/govt_sla_badge.dart';

/// Supported sort fields for government complaint lists and tables.
enum GovtComplaintSortField {
  reportedAt,
  resolvedAt,
  priority,
  sla,
  status,
  ward,
  department,
}

/// Standardized cross-role filter and pagination model for Government Operations.
class GovernmentFilterModel {
  final String searchQuery;
  final DateTimeRange? dateRange;
  final ComplaintStatus? status;
  final String? statusString;
  final ComplaintPriority? priority;
  final GovtSlaStatus? slaStatus;
  final String? zoneId;
  final String? wardId;
  final String? departmentId;
  final String? crewId;
  final int page;
  final int pageSize;
  final GovtComplaintSortField sortBy;
  final bool sortAscending;

  const GovernmentFilterModel({
    this.searchQuery = '',
    this.dateRange,
    this.status,
    this.statusString,
    this.priority,
    this.slaStatus,
    this.zoneId,
    this.wardId,
    this.departmentId,
    this.crewId,
    this.page = 0,
    this.pageSize = 10,
    this.sortBy = GovtComplaintSortField.reportedAt,
    this.sortAscending = false,
  });

  /// Allowed page size options according to municipal design standards.
  static const List<int> allowedPageSizes = [10, 25, 50];

  /// Returns true if any active filter criteria is applied (excluding pagination & sorting).
  bool get isFiltered =>
      searchQuery.trim().isNotEmpty ||
      dateRange != null ||
      status != null ||
      statusString != null ||
      priority != null ||
      slaStatus != null ||
      zoneId != null ||
      wardId != null ||
      departmentId != null ||
      crewId != null;

  /// Returns the count of active filter criteria.
  int get activeFilterCount {
    int count = 0;
    if (searchQuery.trim().isNotEmpty) count++;
    if (dateRange != null) count++;
    if (status != null || statusString != null) count++;
    if (priority != null) count++;
    if (slaStatus != null) count++;
    if (zoneId != null) count++;
    if (wardId != null) count++;
    if (departmentId != null) count++;
    if (crewId != null) count++;
    return count;
  }

  /// Creates a copy with specified fields overridden.
  GovernmentFilterModel copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    ComplaintStatus? status,
    bool clearStatus = false,
    String? statusString,
    bool clearStatusString = false,
    ComplaintPriority? priority,
    bool clearPriority = false,
    GovtSlaStatus? slaStatus,
    bool clearSlaStatus = false,
    String? zoneId,
    bool clearZoneId = false,
    String? wardId,
    bool clearWardId = false,
    String? departmentId,
    bool clearDepartmentId = false,
    String? crewId,
    bool clearCrewId = false,
    int? page,
    int? pageSize,
    GovtComplaintSortField? sortBy,
    bool? sortAscending,
  }) {
    return GovernmentFilterModel(
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      status: clearStatus ? null : (status ?? this.status),
      statusString: clearStatusString ? null : (statusString ?? this.statusString),
      priority: clearPriority ? null : (priority ?? this.priority),
      slaStatus: clearSlaStatus ? null : (slaStatus ?? this.slaStatus),
      zoneId: clearZoneId ? null : (zoneId ?? this.zoneId),
      wardId: clearWardId ? null : (wardId ?? this.wardId),
      departmentId: clearDepartmentId ? null : (departmentId ?? this.departmentId),
      crewId: clearCrewId ? null : (crewId ?? this.crewId),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Resets all filter and pagination parameters to defaults while preserving page size.
  GovernmentFilterModel reset() {
    return GovernmentFilterModel(
      pageSize: pageSize,
      sortBy: GovtComplaintSortField.reportedAt,
      sortAscending: false,
    );
  }

  /// Evaluates whether a complaint matches the active filter criteria.
  bool matches(ComplaintModel complaint, {String? zoneName}) {
    // 1. Search Query Match
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      final idMatch = complaint.id.toLowerCase().contains(q);
      final tktMatch = complaint.ticketNumber.toLowerCase().contains(q);
      final titleMatch = complaint.title.toLowerCase().contains(q);
      final descMatch = complaint.description.toLowerCase().contains(q);
      final deptMatch = (complaint.departmentName ?? complaint.assignedDepartmentId ?? '').toLowerCase().contains(q);
      final wardMatch = (complaint.wardId ?? complaint.location.ward ?? '').toLowerCase().contains(q);
      final crewMatch = (complaint.assignedCrewMemberId ?? complaint.assignedTo ?? '').toLowerCase().contains(q);

      if (!idMatch && !tktMatch && !titleMatch && !descMatch && !deptMatch && !wardMatch && !crewMatch) {
        return false;
      }
    }

    // 2. Date Range Filter
    if (dateRange != null) {
      final start = dateRange!.start;
      final end = dateRange!.end.add(const Duration(days: 1));
      if (complaint.createdAt.isBefore(start) || complaint.createdAt.isAfter(end)) {
        return false;
      }
    }

    // 3. Status Filter
    if (status != null) {
      if (complaint.status != status) return false;
    } else if (statusString != null) {
      final current = complaint.status.label.toLowerCase().replaceAll(' ', '_');
      final target = statusString!.toLowerCase().replaceAll(' ', '_');
      if (current != target && complaint.status.name != target) return false;
    }

    // 4. Priority Filter
    if (priority != null) {
      if (complaint.priority != priority) return false;
    }

    // 5. SLA Filter
    if (slaStatus != null) {
      final isResolved = complaint.status == ComplaintStatus.resolved;
      final now = DateTime.now();
      final isBreached = complaint.createdAt.add(const Duration(hours: 48)).isBefore(
            isResolved ? (complaint.updatedAt) : now,
          );
      final isWarning = !isBreached &&
          !isResolved &&
          complaint.createdAt.add(const Duration(hours: 36)).isBefore(now);

      if (slaStatus == GovtSlaStatus.breached && !isBreached) return false;
      if (slaStatus == GovtSlaStatus.warning && !isWarning) return false;
      if (slaStatus == GovtSlaStatus.healthy && (isBreached || isWarning)) return false;
    }

    // 6. Zone Filter
    if (zoneId != null && zoneId!.isNotEmpty && zoneId != 'all') {
      if (zoneName != null && zoneName != zoneId) return false;
    }

    // 7. Ward Filter
    if (wardId != null && wardId!.isNotEmpty && wardId != 'all') {
      final ward = complaint.wardId ?? complaint.location.ward;
      if (ward != wardId) return false;
    }

    // 8. Department Filter
    if (departmentId != null && departmentId!.isNotEmpty && departmentId != 'all') {
      final dept = complaint.assignedDepartmentId ?? complaint.departmentName;
      if (dept != departmentId && complaint.assignedDepartmentId != departmentId) return false;
    }

    // 9. Crew Filter
    if (crewId != null && crewId!.isNotEmpty && crewId != 'all') {
      if (complaint.assignedCrewMemberId != crewId && complaint.assignedTo != crewId) return false;
    }

    return true;
  }

  /// Filters and sorts a full list of complaints according to this model.
  List<ComplaintModel> apply(
    List<ComplaintModel> source, {
    Map<String, String>? wardToZoneMap,
  }) {
    // 1. Predicate Filtering
    final filtered = source.where((c) {
      final ward = c.wardId ?? c.location.ward;
      final zone = ward != null && wardToZoneMap != null ? wardToZoneMap[ward] : null;
      return matches(c, zoneName: zone);
    }).toList();

    // 2. Sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (sortBy) {
        case GovtComplaintSortField.reportedAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case GovtComplaintSortField.resolvedAt:
          final aRes = a.status == ComplaintStatus.resolved ? a.updatedAt : DateTime(1970);
          final bRes = b.status == ComplaintStatus.resolved ? b.updatedAt : DateTime(1970);
          comparison = aRes.compareTo(bRes);
          break;
        case GovtComplaintSortField.priority:
          comparison = a.priority.index.compareTo(b.priority.index);
          break;
        case GovtComplaintSortField.sla:
          final aTarget = a.createdAt.add(const Duration(hours: 48));
          final bTarget = b.createdAt.add(const Duration(hours: 48));
          comparison = aTarget.compareTo(bTarget);
          break;
        case GovtComplaintSortField.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case GovtComplaintSortField.ward:
          final aWard = a.wardId ?? a.location.ward ?? '';
          final bWard = b.wardId ?? b.location.ward ?? '';
          comparison = aWard.compareTo(bWard);
          break;
        case GovtComplaintSortField.department:
          final aDept = a.departmentName ?? a.assignedDepartmentId ?? '';
          final bDept = b.departmentName ?? b.assignedDepartmentId ?? '';
          comparison = aDept.compareTo(bDept);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  /// Returns the current page of results.
  List<ComplaintModel> paginate(List<ComplaintModel> items) {
    if (items.isEmpty) return const [];
    final startIndex = page * pageSize;
    if (startIndex >= items.length) return const [];
    final endIndex = (startIndex + pageSize).clamp(0, items.length);
    return items.sublist(startIndex, endIndex);
  }

  /// Total number of pages for a given item count.
  int totalPages(int totalItemCount) {
    if (totalItemCount == 0 || pageSize <= 0) return 1;
    return (totalItemCount / pageSize).ceil();
  }
}
