import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Govt UI/models/department_model.dart';
import '../../Govt UI/services/govt_complaint_repository.dart';
import '../firebase/firestore/firebase_complaint_data_source.dart';
import '../firebase/firestore/firebase_department_data_source.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import '../network/connectivity_service.dart';
import '../services/supabase_notification_service.dart';
import '../sync/models/sync_queue_item.dart';
import '../sync/sync_manager.dart';
import 'hive_complaint_repository.dart';

/// Production offline-first implementation of [GovtComplaintRepository] for municipal administrative workflows.
///
/// Coordinates:
/// - Local Hive cache & fallback for fast dashboard renders and offline triage.
/// - Remote Cloud Firestore data sources for live municipal triage and dispatching.
/// - SyncManager queue for offline administrative status changes and officer assignments.
class OfflineFirstGovtComplaintRepository implements GovtComplaintRepository {
  final HiveComplaintRepository _localRepo;
  final FirebaseComplaintDataSource _complaintDataSource;
  final FirebaseDepartmentDataSource _deptDataSource;
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;
  final SupabaseNotificationService _notificationService;

  OfflineFirstGovtComplaintRepository({
    HiveComplaintRepository? localRepository,
    FirebaseComplaintDataSource? complaintDataSource,
    FirebaseDepartmentDataSource? deptDataSource,
    SyncManager? syncManager,
    ConnectivityService? connectivity,
    SupabaseNotificationService? notificationService,
  })  : _localRepo = localRepository ?? HiveComplaintRepository(),
        _complaintDataSource = complaintDataSource ?? FirebaseComplaintDataSource(),
        _deptDataSource = deptDataSource ?? FirebaseDepartmentDataSource(),
        _syncManager = syncManager ?? SyncManager(),
        _connectivity = connectivity ?? AppConnectivityService(),
        _notificationService = notificationService ?? HttpSupabaseNotificationService();

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
    // 1. Fetch from local Hive cache first
    List<ComplaintModel> list = List<ComplaintModel>.from(await _localRepo.getComplaints());

    // 2. If online, fetch remote government snapshot & merge
    if (_connectivity.isOnline) {
      try {
        final remotePage = await _complaintDataSource.getGovernmentComplaints(
          departmentId: departmentId,
          status: status,
          priority: priority,
          limit: 100,
        );

        if (remotePage.items.isNotEmpty) {
          await _localRepo.cacheComplaints(remotePage.items);
          list = List<ComplaintModel>.from(await _localRepo.getComplaints());
        }
      } catch (e) {
        debugPrint('[OfflineFirstGovtComplaintRepository] Remote fetch failed (fallback to cache): $e');
      }
    }

    // 3. Apply in-memory filters for instant UI responsiveness
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      final d = departmentId.trim().toLowerCase();
      list = list.where((c) {
        return c.effectiveDepartment.toLowerCase().contains(d) ||
            c.category.id.toLowerCase() == d;
      }).toList();
    }

    if (categoryId != null && categoryId.trim().isNotEmpty && categoryId.toLowerCase() != 'all') {
      final cat = categoryId.trim().toLowerCase();
      list = list.where((c) =>
          c.category.id.toLowerCase() == cat ||
          c.category.name.toLowerCase() == cat).toList();
    }

    if (status != null) {
      list = list.where((c) => c.status == status).toList();
    }

    if (priority != null) {
      list = list.where((c) => c.priority == priority).toList();
    }

    if (isAssigned != null) {
      if (isAssigned) {
        list = list.where((c) => c.assignedTo != null && c.assignedTo!.trim().isNotEmpty).toList();
      } else {
        list = list.where((c) => c.assignedTo == null || c.assignedTo!.trim().isEmpty).toList();
      }
    }

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

    // 4. Apply Sorting
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
  Future<ComplaintModel?> getComplaintById(String id) async {
    final local = await _localRepo.getComplaintById(id);
    if (local != null) return local;

    if (_connectivity.isOnline) {
      try {
        final remote = await _complaintDataSource.getComplaintById(id);
        if (remote != null) {
          await _localRepo.cacheComplaints([remote]);
          return remote;
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<GovtDashboardMetrics> getDashboardMetrics({String? departmentId}) async {
    final list = await getComplaints(departmentId: departmentId);
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
    final list = await getComplaints();
    final total = list.isEmpty ? 1 : list.length;
    final Map<String, int> counts = {};

    for (final c in list) {
      counts[c.category.name.toLowerCase()] = (counts[c.category.name.toLowerCase()] ?? 0) + 1;
    }

    return CivicCategory.defaultCategories.map((cat) {
      final count = counts[cat.name.toLowerCase()] ??
          counts[cat.id.toLowerCase()] ??
          0;
      final percentage = list.isEmpty ? 0.0 : (count / total) * 100.0;
      return CategoryDistributionItem(
        category: cat,
        count: count,
        percentage: percentage,
      );
    }).toList();
  }

  @override
  Future<List<StatusDistributionItem>> getStatusDistribution() async {
    final list = await getComplaints();
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
      final percentage = list.isEmpty ? 0.0 : (entry.value / total) * 100.0;
      return StatusDistributionItem(
        status: entry.key,
        count: entry.value,
        percentage: percentage,
      );
    }).toList();
  }

  @override
  Future<List<ComplaintModel>> getAttentionRequiredComplaints({int limit = 5}) async {
    final list = await getComplaints();

    final attentionList = list.where((c) {
      final isUrgentPriority = c.priority == ComplaintPriority.emergency ||
          c.priority == ComplaintPriority.high;
      final isNewOrUnverified = c.status == ComplaintStatus.reported;
      final isUnassigned = c.assignedTo == null || c.assignedTo!.isEmpty;
      return (isUrgentPriority || isNewOrUnverified || isUnassigned) &&
          c.status != ComplaintStatus.resolved &&
          c.status != ComplaintStatus.rejected;
    }).toList();

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

  // ===========================================================================
  // GOVERNMENT WORKFLOW MUTATIONS (Status, Assign, Verify, Flag, Reject)
  // ===========================================================================

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
    final existing = await getComplaintById(complaintId);
    if (existing == null) return false;

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

    await _localRepo.cacheComplaints([updated]);

    if (_connectivity.isOnline) {
      try {
        final targetServerId = updated.serverId ?? updated.id;
        await _complaintDataSource.updateGovernmentWorkflow(
          targetServerId,
          officerNotes: reason,
        );
      } catch (e) {
        debugPrint('[OfflineFirstGovtComplaintRepository] Remote flag failed (cached locally): $e');
      }
    }

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
  Future<bool> updateStatus({
    required String complaintId,
    required ComplaintStatus nextStatus,
    required String updateMessage,
    String? officerName,
  }) async {
    final existing = await getComplaintById(complaintId);
    if (existing == null) return false;

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

    final newEvent = TimelineEvent(
      title: eventTitle,
      description: updateMessage.isNotEmpty
          ? updateMessage
          : 'Status transitioned to ${nextStatus.label}.',
      timestamp: DateTime.now(),
      status: nextStatus,
      updatedBy: officerName ?? 'Municipal Officer',
    );
    updatedTimeline.insert(0, newEvent);

    final updated = existing.copyWith(
      status: nextStatus,
      updatedAt: DateTime.now(),
      officerNotes: updateMessage.isNotEmpty ? updateMessage : existing.officerNotes,
      resolvedAt: nextStatus == ComplaintStatus.resolved ? DateTime.now() : existing.resolvedAt,
      timeline: updatedTimeline,
    );

    // 1. Update local cache
    await _localRepo.cacheComplaints([updated]);

    // 2. If online, sync directly to Firestore; otherwise enqueue in SyncManager
    if (_connectivity.isOnline) {
      try {
        final targetServerId = updated.serverId ?? updated.id;
        await _complaintDataSource.updateGovernmentWorkflow(
          targetServerId,
          status: nextStatus,
          officerNotes: updateMessage,
          resolvedAt: nextStatus == ComplaintStatus.resolved ? DateTime.now() : null,
        );
        await _complaintDataSource.addTimelineEvent(targetServerId, newEvent);

        // 3. Trigger secondary serverless notification asynchronously after Firestore update
        _triggerSupabaseNotification(
          complaint: updated,
          oldStatus: existing.status.name,
          newStatus: nextStatus.name,
          officerNotes: updateMessage,
        );
      } catch (e) {
        debugPrint('[OfflineFirstGovtComplaintRepository] Remote status update failed, will queue: $e');
        _queueWorkflowUpdate(updated, oldStatus: existing.status.name);
      }
    } else {
      _queueWorkflowUpdate(updated, oldStatus: existing.status.name);
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
    final existing = await getComplaintById(complaintId);
    if (existing == null) return false;

    final updatedTimeline = List<TimelineEvent>.from(existing.timeline);
    final assignEvent = TimelineEvent(
      title: 'Assigned to $officerName',
      description: assignmentNote ?? 'Department crew mobilized for field inspection.',
      timestamp: DateTime.now(),
      status: ComplaintStatus.assigned,
      updatedBy: 'Nodal Officer',
    );
    updatedTimeline.insert(0, assignEvent);

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

    // 1. Update local cache
    await _localRepo.cacheComplaints([updated]);

    // 2. If online, push to Firestore
    if (_connectivity.isOnline) {
      try {
        final targetServerId = updated.serverId ?? updated.id;
        await _complaintDataSource.updateGovernmentWorkflow(
          targetServerId,
          status: ComplaintStatus.assigned,
          assignedTo: officerName,
          departmentId: departmentId,
          departmentName: dept.name,
          officerNotes: assignmentNote,
        );
        await _complaintDataSource.addTimelineEvent(targetServerId, assignEvent);

        // 3. Trigger secondary serverless notification asynchronously after Firestore update
        _triggerSupabaseNotification(
          complaint: updated,
          oldStatus: existing.status.name,
          newStatus: ComplaintStatus.assigned.name,
          officerNotes: assignmentNote,
        );
      } catch (e) {
        debugPrint('[OfflineFirstGovtComplaintRepository] Remote assign failed, queued: $e');
        _queueWorkflowUpdate(updated, oldStatus: existing.status.name);
      }
    } else {
      _queueWorkflowUpdate(updated, oldStatus: existing.status.name);
    }

    return true;
  }

  void _triggerSupabaseNotification({
    required ComplaintModel complaint,
    required String oldStatus,
    required String newStatus,
    String? officerNotes,
  }) {
    // Non-blocking fire-and-forget; never rolls back Firestore status update
    unawaited(
      _notificationService
          .triggerStatusNotification(
            complaintId: complaint.serverId ?? complaint.id,
            citizenId: complaint.citizenId,
            oldStatus: oldStatus,
            newStatus: newStatus,
            ticketNumber: complaint.ticketNumber,
            title: complaint.title,
            departmentName: complaint.departmentName,
            officerNotes: officerNotes,
          )
          .catchError((e) {
            debugPrint('[OfflineFirstGovtComplaintRepository] Notification non-fatal error: $e');
            return NotificationDispatchResult.failure(message: e.toString());
          }),
    );
  }

  void _queueWorkflowUpdate(ComplaintModel complaint, {String? oldStatus}) {
    final item = SyncQueueItem(
      id: 'govt_update_${complaint.id}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: 'complaint',
      entityId: complaint.id,
      operation: SyncOperation.updateComplaint,
      payload: {
        'complaintId': complaint.id,
        'serverId': complaint.serverId,
        'citizenId': complaint.citizenId,
        'title': complaint.title,
        'ticketNumber': complaint.ticketNumber,
        'oldStatus': oldStatus ?? 'reported',
        'status': complaint.status.name,
        'assignedTo': complaint.assignedTo,
        'departmentName': complaint.departmentName,
        'officerNotes': complaint.officerNotes,
      },
      createdAt: DateTime.now(),
      status: SyncQueueStatus.pending,
    );
    _syncManager.queue.enqueue(item);
  }

  @override
  Future<List<GovtDepartmentModel>> getDepartments() async {
    if (_connectivity.isOnline) {
      try {
        final depts = await _deptDataSource.getDepartments();
        if (depts.isNotEmpty) return depts;
      } catch (_) {}
    }
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

  // ===========================================================================
  // REAL-TIME GOVERNMENT STREAMS (Prompt 8)
  // ===========================================================================

  @override
  Stream<List<ComplaintModel>> watchComplaints({
    String? departmentId,
    String? categoryId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    bool? isAssigned,
    String? searchQuery,
    GovtComplaintSort sortBy = GovtComplaintSort.newest,
  }) async* {
    // 1. Emit cached/merged first
    final initial = await getComplaints(
      departmentId: departmentId,
      categoryId: categoryId,
      status: status,
      priority: priority,
      isAssigned: isAssigned,
      searchQuery: searchQuery,
      sortBy: sortBy,
    );
    yield initial;

    if (!_connectivity.isOnline) return;

    // 2. Stream remote Firestore updates
    try {
      yield* _complaintDataSource
          .watchGovernmentComplaints(
            departmentId: departmentId,
            status: status,
            priority: priority,
            limit: 100,
          )
          .asyncMap((remoteList) async {
        if (remoteList.isNotEmpty) {
          await _localRepo.cacheComplaints(remoteList);
        }
        return getComplaints(
          departmentId: departmentId,
          categoryId: categoryId,
          status: status,
          priority: priority,
          isAssigned: isAssigned,
          searchQuery: searchQuery,
          sortBy: sortBy,
        );
      });
    } catch (e) {
      debugPrint('[OfflineFirstGovtComplaintRepository] watchComplaints fallback: $e');
    }
  }

  @override
  Stream<ComplaintModel?> watchComplaint(String id) async* {
    final local = await getComplaintById(id);
    if (local != null) yield local;

    if (!_connectivity.isOnline) return;

    final targetServerId = local?.serverId ?? id;
    try {
      yield* _complaintDataSource.watchComplaint(targetServerId).asyncMap((remote) async {
        if (remote != null) {
          await _localRepo.cacheComplaints([remote]);
          return getComplaintById(id);
        }
        return local;
      });
    } catch (e) {
      debugPrint('[OfflineFirstGovtComplaintRepository] watchComplaint fallback: $e');
    }
  }

  @override
  Stream<GovtDashboardMetrics> watchDashboardMetrics({String? departmentId}) async* {
    yield await getDashboardMetrics(departmentId: departmentId);

    yield* watchComplaints(departmentId: departmentId).asyncMap((list) {
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
    });
  }
}

