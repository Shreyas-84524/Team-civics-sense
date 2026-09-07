import '../../core/local/mock_data_source.dart';
import '../../core/models/category_model.dart';
import '../../core/models/complaint_model.dart';
import '../models/department_model.dart';

/// Aggregated dashboard metric counts for government operations.
class GovtDashboardMetrics {
  final int totalComplaints;
  final int reportedCount;
  final int verifiedCount;
  final int assignedCount;
  final int inProgressCount;
  final int resolvedCount;
  final int criticalHazardsCount;

  const GovtDashboardMetrics({
    required this.totalComplaints,
    required this.reportedCount,
    required this.verifiedCount,
    required this.assignedCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.criticalHazardsCount,
  });
}

/// Category workload distribution model.
class CategoryDistributionItem {
  final CivicCategory category;
  final int count;
  final double percentage;

  const CategoryDistributionItem({
    required this.category,
    required this.count,
    required this.percentage,
  });
}

/// Status distribution item for status breakdown visualization.
class StatusDistributionItem {
  final ComplaintStatus status;
  final int count;
  final double percentage;

  const StatusDistributionItem({
    required this.status,
    required this.count,
    required this.percentage,
  });
}

/// Sorting options for government complaints.
enum GovtComplaintSort {
  newest,
  oldest,
  recentlyUpdated,
  highestPriority;

  String get label {
    switch (this) {
      case GovtComplaintSort.newest:
        return 'Newest First';
      case GovtComplaintSort.oldest:
        return 'Oldest First';
      case GovtComplaintSort.recentlyUpdated:
        return 'Recently Updated';
      case GovtComplaintSort.highestPriority:
        return 'Highest Priority';
    }
  }
}

/// Abstract contract for Government complaint management.
abstract class GovtComplaintRepository {
  Future<List<ComplaintModel>> getComplaints({
    String? departmentId,
    String? categoryId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    bool? isAssigned,
    String? searchQuery,
    GovtComplaintSort sortBy = GovtComplaintSort.newest,
  });

  Future<ComplaintModel?> getComplaintById(String id);

  Future<GovtDashboardMetrics> getDashboardMetrics({String? departmentId});

  Future<List<CategoryDistributionItem>> getCategoryDistribution();

  Future<List<StatusDistributionItem>> getStatusDistribution();

  Future<List<ComplaintModel>> getAttentionRequiredComplaints({int limit = 5});

  Future<bool> verifyComplaint({
    required String complaintId,
    required String notes,
    String? officerName,
  });

  Future<bool> flagComplaint({
    required String complaintId,
    required String reason,
    String? officerName,
  });

  Future<bool> rejectComplaint({
    required String complaintId,
    required String reason,
    String? officerName,
  });

  Future<bool> updateStatus({
    required String complaintId,
    required ComplaintStatus nextStatus,
    required String updateMessage,
    String? officerName,
  });

  Future<bool> assignComplaint({
    required String complaintId,
    required String departmentId,
    required String officerName,
    String? assignmentNote,
  });

  Future<List<GovtDepartmentModel>> getDepartments();
  Future<List<GovtOfficerModel>> getOfficers({String? departmentId});
}

/// In-memory mock implementation of GovtComplaintRepository.
class MockGovtComplaintRepository implements GovtComplaintRepository {
  static final MockGovtComplaintRepository _instance = MockGovtComplaintRepository._internal();
  factory MockGovtComplaintRepository() => _instance;
  MockGovtComplaintRepository._internal();

  final MockDataSource _dataSource = MockDataSource();

  @override
  Future<List<ComplaintModel>> getComplaints({
    String? departmentId,
    String? categoryId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    bool? isAssigned,
    String? searchQuery,
    GovtComplaintSort sortBy = GovtComplaintSort.newest,
  }) async {
    List<ComplaintModel> list = List.from(_dataSource.complaints);

    // Department Filter
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      final d = departmentId.trim().toLowerCase();
      list = list.where((c) {
        return c.effectiveDepartment.toLowerCase().contains(d) ||
            c.category.id.toLowerCase() == d;
      }).toList();
    }

    // Category Filter
    if (categoryId != null && categoryId.trim().isNotEmpty && categoryId.toLowerCase() != 'all') {
      final cat = categoryId.trim().toLowerCase();
      list = list.where((c) =>
          c.category.id.toLowerCase() == cat ||
          c.category.name.toLowerCase() == cat).toList();
    }

    // Status Filter
    if (status != null) {
      list = list.where((c) => c.status == status).toList();
    }

    // Priority Filter
    if (priority != null) {
      list = list.where((c) => c.priority == priority).toList();
    }

    // Assignment Status Filter
    if (isAssigned != null) {
      if (isAssigned) {
        list = list.where((c) => c.assignedTo != null && c.assignedTo!.trim().isNotEmpty).toList();
      } else {
        list = list.where((c) => c.assignedTo == null || c.assignedTo!.trim().isEmpty).toList();
      }
    }

    // Search Query (ID, Title, Category, Location, Citizen Ref)
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((c) {
        return c.ticketNumber.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.category.name.toLowerCase().contains(q) ||
            c.location.address.toLowerCase().contains(q) ||
            c.location.ward?.toLowerCase().contains(q) == true ||
            c.citizenId.toLowerCase().contains(q);
      }).toList();
    }

    // Sorting
    list.sort((a, b) {
      switch (sortBy) {
        case GovtComplaintSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case GovtComplaintSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case GovtComplaintSort.recentlyUpdated:
          return b.updatedAt.compareTo(a.updatedAt);
        case GovtComplaintSort.highestPriority:
          int pScore(ComplaintPriority p) {
            switch (p) {
              case ComplaintPriority.emergency:
                return 4;
              case ComplaintPriority.high:
                return 3;
              case ComplaintPriority.medium:
                return 2;
              case ComplaintPriority.low:
                return 1;
            }
          }
          final comp = pScore(b.priority).compareTo(pScore(a.priority));
          if (comp != 0) return comp;
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  }

  @override
  Future<bool> verifyComplaint({
    required String complaintId,
    required String notes,
    String? officerName,
  }) async {
    return updateStatus(
      complaintId: complaintId,
      nextStatus: ComplaintStatus.verified,
      updateMessage: notes.isNotEmpty ? notes : 'Verified by Municipal Authority.',
      officerName: officerName ?? 'Municipal Verification Officer',
    );
  }

  @override
  Future<bool> flagComplaint({
    required String complaintId,
    required String reason,
    String? officerName,
  }) async {
    final index = _dataSource.complaints.indexWhere(
      (c) => c.id == complaintId || c.ticketNumber == complaintId,
    );

    if (index == -1) return false;

    final existing = _dataSource.complaints[index];
    final updatedTimeline = List<TimelineEvent>.from(existing.timeline);

    updatedTimeline.insert(
      0,
      TimelineEvent(
        title: 'Flagged for Review / Moderation',
        description: reason.isNotEmpty ? reason : 'Flagged by municipal authority for administrative review.',
        timestamp: DateTime.now(),
        status: existing.status,
        updatedBy: officerName ?? 'Municipal Triage Officer',
      ),
    );

    final updated = existing.copyWith(
      updatedAt: DateTime.now(),
      officerNotes: reason.isNotEmpty ? reason : existing.officerNotes,
      timeline: updatedTimeline,
    );

    _dataSource.complaints[index] = updated;
    return true;
  }

  @override
  Future<bool> rejectComplaint({
    required String complaintId,
    required String reason,
    String? officerName,
  }) async {
    return updateStatus(
      complaintId: complaintId,
      nextStatus: ComplaintStatus.rejected,
      updateMessage: reason.isNotEmpty ? reason : 'Complaint closed / marked unactionable after review.',
      officerName: officerName ?? 'Municipal Review Officer',
    );
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    try {
      return _dataSource.complaints.firstWhere(
        (c) => c.id == id || c.ticketNumber.toLowerCase() == id.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GovtDashboardMetrics> getDashboardMetrics({String? departmentId}) async {
    final list = _dataSource.complaints;
    int reported = 0;
    int verified = 0;
    int assigned = 0;
    int inProgress = 0;
    int resolved = 0;
    int critical = 0;

    for (final c in list) {
      switch (c.status) {
        case ComplaintStatus.reported:
          reported++;
          break;
        case ComplaintStatus.verified:
          verified++;
          break;
        case ComplaintStatus.assigned:
          assigned++;
          break;
        case ComplaintStatus.inProgress:
          inProgress++;
          break;
        case ComplaintStatus.resolved:
          resolved++;
          break;
        case ComplaintStatus.rejected:
          break;
      }

      if (c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high) {
        critical++;
      }
    }

    return GovtDashboardMetrics(
      totalComplaints: list.length,
      reportedCount: reported,
      verifiedCount: verified,
      assignedCount: assigned,
      inProgressCount: inProgress,
      resolvedCount: resolved,
      criticalHazardsCount: critical,
    );
  }

  @override
  Future<List<CategoryDistributionItem>> getCategoryDistribution() async {
    final list = _dataSource.complaints;
    final total = list.isEmpty ? 1 : list.length;
    final Map<String, int> counts = {};

    for (final c in list) {
      counts[c.category.name.toLowerCase()] = (counts[c.category.name.toLowerCase()] ?? 0) + 1;
    }

    return CivicCategory.defaultCategories.map((cat) {
      final count = counts[cat.name.toLowerCase()] ??
          counts[cat.id.toLowerCase()] ??
          (cat.id == 'roads' ? 2 : cat.id == 'water' ? 1 : 0);
      final percentage = (count / total) * 100.0;
      return CategoryDistributionItem(
        category: cat,
        count: count,
        percentage: percentage,
      );
    }).toList();
  }

  @override
  Future<List<StatusDistributionItem>> getStatusDistribution() async {
    final list = _dataSource.complaints;
    final total = list.isEmpty ? 1 : list.length;
    final Map<ComplaintStatus, int> counts = {
      ComplaintStatus.reported: 0,
      ComplaintStatus.verified: 0,
      ComplaintStatus.assigned: 0,
      ComplaintStatus.inProgress: 0,
      ComplaintStatus.resolved: 0,
    };

    for (final c in list) {
      if (counts.containsKey(c.status)) {
        counts[c.status] = counts[c.status]! + 1;
      }
    }

    return counts.entries.map((entry) {
      final percentage = (entry.value / total) * 100.0;
      return StatusDistributionItem(
        status: entry.key,
        count: entry.value,
        percentage: percentage,
      );
    }).toList();
  }

  @override
  Future<List<ComplaintModel>> getAttentionRequiredComplaints({int limit = 5}) async {
    final list = List<ComplaintModel>.from(_dataSource.complaints);

    // Filter complaints that require immediate municipal attention
    final attentionList = list.where((c) {
      final isUrgentPriority = c.priority == ComplaintPriority.emergency ||
          c.priority == ComplaintPriority.high;
      final isNewOrUnverified = c.status == ComplaintStatus.reported;
      final isUnassigned = c.assignedTo == null || c.assignedTo!.isEmpty;
      return (isUrgentPriority || isNewOrUnverified || isUnassigned) &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected;
    }).toList();

    // Sort: Emergency first, then High, then Newly reported
    attentionList.sort((a, b) {
      if (a.priority == ComplaintPriority.emergency && b.priority != ComplaintPriority.emergency) {
        return -1;
      }
      if (b.priority == ComplaintPriority.emergency && a.priority != ComplaintPriority.emergency) {
        return 1;
      }
      if (a.priority == ComplaintPriority.high && b.priority != ComplaintPriority.high) {
        return -1;
      }
      if (b.priority == ComplaintPriority.high && a.priority != ComplaintPriority.high) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return attentionList.take(limit).toList();
  }

  @override
  Future<bool> updateStatus({
    required String complaintId,
    required ComplaintStatus nextStatus,
    required String updateMessage,
    String? officerName,
  }) async {
    final index = _dataSource.complaints.indexWhere(
      (c) => c.id == complaintId || c.ticketNumber == complaintId,
    );

    if (index == -1) return false;

    final existing = _dataSource.complaints[index];
    final updatedTimeline = List<TimelineEvent>.from(existing.timeline);

    String eventTitle;
    switch (nextStatus) {
      case ComplaintStatus.reported:
        eventTitle = 'Reported';
        break;
      case ComplaintStatus.verified:
        eventTitle = 'Verified by Municipal Authority';
        break;
      case ComplaintStatus.assigned:
        eventTitle = 'Department Crew Assigned';
        break;
      case ComplaintStatus.inProgress:
        eventTitle = 'Work in Progress';
        break;
      case ComplaintStatus.resolved:
        eventTitle = 'Issue Resolved & Inspected';
        break;
      case ComplaintStatus.rejected:
        eventTitle = 'Complaint Closed / Unactionable';
        break;
    }

    updatedTimeline.insert(
      0,
      TimelineEvent(
        title: eventTitle,
        description: updateMessage.isNotEmpty
            ? updateMessage
            : 'Status transitioned to ${nextStatus.label}.',
        timestamp: DateTime.now(),
        status: nextStatus,
        updatedBy: officerName ?? 'Municipal Officer',
      ),
    );

    final updated = existing.copyWith(
      status: nextStatus,
      updatedAt: DateTime.now(),
      officerNotes: updateMessage.isNotEmpty ? updateMessage : existing.officerNotes,
      resolvedAt: nextStatus == ComplaintStatus.resolved ? DateTime.now() : existing.resolvedAt,
      timeline: updatedTimeline,
    );

    _dataSource.complaints[index] = updated;

    // Sync corresponding hazard if one exists
    final hazardIndex = _dataSource.hazards.indexWhere(
      (h) => h.complaintId == existing.id || (existing.ticketNumber.isNotEmpty && h.ticketNumber == existing.ticketNumber),
    );
    if (hazardIndex != -1) {
      _dataSource.hazards[hazardIndex] = _dataSource.hazards[hazardIndex].copyWith(
        status: nextStatus,
        updatedAt: DateTime.now(),
      );
    }

    return true;
  }

  @override
  Future<bool> assignComplaint({
    required String complaintId,
    required String departmentId,
    required String officerName,
    String? assignmentNote,
  }) async {
    final index = _dataSource.complaints.indexWhere(
      (c) => c.id == complaintId || c.ticketNumber == complaintId,
    );

    if (index == -1) return false;

    final existing = _dataSource.complaints[index];
    final updatedTimeline = List<TimelineEvent>.from(existing.timeline);

    updatedTimeline.insert(
      0,
      TimelineEvent(
        title: 'Assigned to $officerName',
        description: assignmentNote ?? 'Department crew mobilized for field inspection.',
        timestamp: DateTime.now(),
        status: ComplaintStatus.assigned,
        updatedBy: 'Nodal Officer',
      ),
    );

    final depts = GovtDepartmentModel.defaultDepartments;
    final dept = depts.firstWhere(
      (d) => d.id == departmentId || d.name.toLowerCase() == departmentId.toLowerCase(),
      orElse: () => depts.first,
    );

    final updated = existing.copyWith(
      status: ComplaintStatus.assigned,
      assignedTo: officerName,
      departmentName: dept.name,
      updatedAt: DateTime.now(),
      timeline: updatedTimeline,
    );

    _dataSource.complaints[index] = updated;

    // Sync corresponding hazard if one exists
    final hazardIndex = _dataSource.hazards.indexWhere(
      (h) => h.complaintId == existing.id || (existing.ticketNumber.isNotEmpty && h.ticketNumber == existing.ticketNumber),
    );
    if (hazardIndex != -1) {
      _dataSource.hazards[hazardIndex] = _dataSource.hazards[hazardIndex].copyWith(
        status: ComplaintStatus.assigned,
        updatedAt: DateTime.now(),
      );
    }

    return true;
  }

  @override
  Future<List<GovtDepartmentModel>> getDepartments() async {
    return GovtDepartmentModel.defaultDepartments;
  }

  @override
  Future<List<GovtOfficerModel>> getOfficers({String? departmentId}) async {
    if (departmentId == null || departmentId.isEmpty) {
      return GovtOfficerModel.defaultOfficers;
    }
    return GovtOfficerModel.defaultOfficers
        .where((o) => o.departmentId == departmentId)
        .toList();
  }
}
